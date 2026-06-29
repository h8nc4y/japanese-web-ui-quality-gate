param(
    [string]$Path = "."
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath $Path).Path
$scannerPath = Join-Path $repoRoot "scripts/scan-private-markers.ps1"
$scratchRoot = Join-Path $repoRoot ".test-tmp/scan-private-markers"
$failures = [System.Collections.Generic.List[string]]::new()
$cleanupWarningWritten = $false

function Add-Failure {
    param([string]$Message)
    [void]$failures.Add($Message)
}

function Invoke-Scanner {
    param(
        [Parameter(Mandatory = $true)][string]$ScanPath,
        [string[]]$AllowedGitHubRepositories = @("h8nc4y/japanese-web-ui-quality-gate"),
        # Synthetic fixtures live under .test-tmp (untracked); force the filesystem walk so
        # they are actually read instead of being skipped by git-tracked enumeration.
        [switch]$NoGit
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $scannerPath, "-Path", $ScanPath, "-AllowedGitHubRepositories")
        $arguments += $AllowedGitHubRepositories
        if ($NoGit) { $arguments += "-NoGit" }
        $output = & pwsh @arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = ($output | Out-String)
    }
}

function Assert-ExitCode {
    param(
        [object]$Result,
        [int]$Expected,
        [string]$Description
    )

    if ($Result.ExitCode -ne $Expected) {
        Add-Failure "$Description expected exit code $Expected, got $($Result.ExitCode). Output: $($Result.Output)"
    }
}

function Assert-OutputContains {
    param(
        [object]$Result,
        [string]$Pattern,
        [string]$Description
    )

    if (-not [regex]::IsMatch($Result.Output, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        Add-Failure "$Description did not contain expected pattern '$Pattern'. Output: $($Result.Output)"
    }
}

function New-TestDirectory {
    New-Item -ItemType Directory -Force -Path $scratchRoot | Out-Null
    $directory = Join-Path $scratchRoot ([guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    return $directory
}

function Remove-TestDirectory {
    param([string]$Directory)

    if (-not (Test-Path -LiteralPath $Directory)) {
        return
    }

    $resolvedDirectory = (Resolve-Path -LiteralPath $Directory).Path
    $resolvedScratch = (Resolve-Path -LiteralPath $scratchRoot).Path
    if (-not $resolvedDirectory.StartsWith($resolvedScratch, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove directory outside scratch root: $resolvedDirectory"
    }

    $lastError = $null
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        try {
            Remove-Item -LiteralPath $resolvedDirectory -Recurse -Force -ErrorAction Stop
            return
        }
        catch {
            $lastError = $_
            Start-Sleep -Milliseconds (100 * $attempt)
        }
    }

    # Cleanup failures should not hide scanner assertion results; the scratch root is gitignored.
    if (-not $script:cleanupWarningWritten) {
        Write-Warning "Could not remove one or more test scratch directories after retries; leaving gitignored scratch for later cleanup."
        $script:cleanupWarningWritten = $true
    }
}

$cleanRepoResult = Invoke-Scanner -ScanPath $repoRoot
Assert-ExitCode -Result $cleanRepoResult -Expected 0 -Description "repository scan"
Assert-OutputContains -Result $cleanRepoResult -Pattern "No private or secret markers found" -Description "repository scan"

$ignoredScratchDirectory = New-TestDirectory
try {
    $syntheticToken = ("s" + "k-" + "ignoredScratchMarker1234567890")
    Set-Content -LiteralPath (Join-Path $ignoredScratchDirectory "notes.md") -Value "Token: $syntheticToken" -Encoding UTF8
    $ignoredScratchResult = Invoke-Scanner -ScanPath $repoRoot
    Assert-ExitCode -Result $ignoredScratchResult -Expected 0 -Description "ignored .test-tmp scratch directory"
}
finally {
    Remove-TestDirectory -Directory $ignoredScratchDirectory
}

$allowedRepositoryDirectory = New-TestDirectory
try {
    $allowedUrl = "https://github.com/" + "h8nc4y/japanese-web-ui-quality-gate"
    Set-Content -LiteralPath (Join-Path $allowedRepositoryDirectory "README.md") -Value "Repository: $allowedUrl" -Encoding UTF8
    $allowedRepositoryResult = Invoke-Scanner -ScanPath $allowedRepositoryDirectory -NoGit
    Assert-ExitCode -Result $allowedRepositoryResult -Expected 0 -Description "allowlisted GitHub repository"
}
finally {
    Remove-TestDirectory -Directory $allowedRepositoryDirectory
}

$secretDirectory = New-TestDirectory
try {
    $syntheticToken = ("s" + "k-" + "testSyntheticMarker1234567890")
    Set-Content -LiteralPath (Join-Path $secretDirectory "notes.md") -Value "Token: $syntheticToken" -Encoding UTF8
    $secretResult = Invoke-Scanner -ScanPath $secretDirectory -NoGit
    Assert-ExitCode -Result $secretResult -Expected 1 -Description "synthetic OpenAI-style token"
    Assert-OutputContains -Result $secretResult -Pattern "OpenAI-style token" -Description "synthetic OpenAI-style token"
}
finally {
    Remove-TestDirectory -Directory $secretDirectory
}

$nonAllowlistedRepositoryDirectory = New-TestDirectory
try {
    $nonAllowlistedUrl = "https://github.com/" + "example/private-repo"
    Set-Content -LiteralPath (Join-Path $nonAllowlistedRepositoryDirectory "notes.md") -Value "Repository: $nonAllowlistedUrl" -Encoding UTF8
    $nonAllowlistedRepositoryResult = Invoke-Scanner -ScanPath $nonAllowlistedRepositoryDirectory -NoGit
    Assert-ExitCode -Result $nonAllowlistedRepositoryResult -Expected 1 -Description "non-allowlisted GitHub repository"
    Assert-OutputContains -Result $nonAllowlistedRepositoryResult -Pattern "Non-allowlisted GitHub repository URL" -Description "non-allowlisted GitHub repository"
}
finally {
    Remove-TestDirectory -Directory $nonAllowlistedRepositoryDirectory
}

# --- New secret prefix coverage (新H-B): each must be detected; values stay redacted in
#     output because the scanner reports marker name + line number only, never the value. ---
$secretPrefixCases = @(
    @{ Description = "AWS access key id"; Marker = "AWS access key id"; Value = ("AK" + "IA" + "ABCDEFGHIJKLMNOP") },
    @{ Description = "Google API key"; Marker = "Google API key"; Value = ("AI" + "za" + ("a" * 35)) },
    @{ Description = "Slack user token"; Marker = "Slack token"; Value = ("xo" + "xp-" + "0123456789abcdef") },
    @{ Description = "Slack app-level token"; Marker = "Slack app-level token"; Value = ("xa" + "pp-" + "0123456789abcdef") },
    @{ Description = "Stripe live secret key"; Marker = "Stripe live secret key"; Value = ("s" + "k" + "_live_" + "0123456789abcdef0123") },
    @{ Description = "PEM RSA private key"; Marker = "Private key block"; Value = ("-----BEGIN" + " RSA PRIVATE KEY-----") },
    @{ Description = "PEM OPENSSH private key"; Marker = "Private key block"; Value = ("-----BEGIN" + " OPENSSH PRIVATE KEY-----") }
)

foreach ($case in $secretPrefixCases) {
    $caseDirectory = New-TestDirectory
    try {
        Set-Content -LiteralPath (Join-Path $caseDirectory "secret.txt") -Value ("Value: " + $case.Value) -Encoding UTF8
        $caseResult = Invoke-Scanner -ScanPath $caseDirectory -NoGit
        Assert-ExitCode -Result $caseResult -Expected 1 -Description $case.Description
        Assert-OutputContains -Result $caseResult -Pattern ([regex]::Escape($case.Marker)) -Description $case.Description
        # Redaction guarantee: the raw secret value must never appear in scanner output.
        if ([regex]::IsMatch($caseResult.Output, [regex]::Escape($case.Value))) {
            Add-Failure "$($case.Description) leaked the raw secret value into scanner output."
        }
    }
    finally {
        Remove-TestDirectory -Directory $caseDirectory
    }
}

# --- False-positive suppression: placeholder emails must NOT trip the scan. ---
$emailAllowlistCases = @("user@example.com", "noreply@anywhere.test", "octocat@users.noreply.github.com")
foreach ($placeholder in $emailAllowlistCases) {
    $emailDirectory = New-TestDirectory
    try {
        Set-Content -LiteralPath (Join-Path $emailDirectory "doc.md") -Value ("Contact: " + $placeholder) -Encoding UTF8
        $emailResult = Invoke-Scanner -ScanPath $emailDirectory -NoGit
        Assert-ExitCode -Result $emailResult -Expected 0 -Description "allowlisted placeholder email $placeholder"
    }
    finally {
        Remove-TestDirectory -Directory $emailDirectory
    }
}

# A real-looking (non-placeholder) email must still be flagged. The address is assembled
# at runtime so this test file itself does not carry a literal email that the repo scan
# would flag.
$realEmailDirectory = New-TestDirectory
try {
    $realEmail = "someone" + "@" + "privatecorp.co.jp"
    Set-Content -LiteralPath (Join-Path $realEmailDirectory "doc.md") -Value ("Contact: " + $realEmail) -Encoding UTF8
    $realEmailResult = Invoke-Scanner -ScanPath $realEmailDirectory -NoGit
    Assert-ExitCode -Result $realEmailResult -Expected 1 -Description "non-placeholder email"
    Assert-OutputContains -Result $realEmailResult -Pattern "Email address" -Description "non-placeholder email"
}
finally {
    Remove-TestDirectory -Directory $realEmailDirectory
}

# --- A bare "Bearer" word with no token value must not trip. The fixture text is assembled
#     at runtime so the word followed by >= 8 chars does not appear literally in this file. ---
$bareBearerDirectory = New-TestDirectory
try {
    $bareBearerText = "The " + "Bear" + "er of this note is trusted."
    Set-Content -LiteralPath (Join-Path $bareBearerDirectory "doc.md") -Value $bareBearerText -Encoding UTF8
    $bareBearerResult = Invoke-Scanner -ScanPath $bareBearerDirectory -NoGit
    Assert-ExitCode -Result $bareBearerResult -Expected 0 -Description "bare Bearer word (no token value)"
}
finally {
    Remove-TestDirectory -Directory $bareBearerDirectory
}

# --- False-positive suppression: ordinary hyphenated documentation slugs such as
#     "task-scanner" must not be interpreted as an OpenAI-style token. ---
$openAiBoundaryDirectory = New-TestDirectory
try {
    $benignSlug = "codex-ta" + "s" + "k-scanner-hardening.md"
    Set-Content -LiteralPath (Join-Path $openAiBoundaryDirectory "doc.md") -Value ("See " + $benignSlug) -Encoding UTF8
    $openAiBoundaryResult = Invoke-Scanner -ScanPath $openAiBoundaryDirectory -NoGit
    Assert-ExitCode -Result $openAiBoundaryResult -Expected 0 -Description "OpenAI token boundary ignores hyphenated documentation slug"
}
finally {
    Remove-TestDirectory -Directory $openAiBoundaryDirectory
}

# --- Binary files are skipped (NUL-byte detection): a synthetic token inside a binary blob
#     must not be read/flagged. ---
$binaryDirectory = New-TestDirectory
try {
    $binaryPath = Join-Path $binaryDirectory "asset.bin"
    $tokenBytes = [System.Text.Encoding]::ASCII.GetBytes("s" + "k-" + "binaryEmbeddedMarker1234567890")
    $blob = New-Object System.Collections.Generic.List[byte]
    $blob.Add([byte]0)
    $blob.AddRange($tokenBytes)
    $blob.Add([byte]0)
    [System.IO.File]::WriteAllBytes($binaryPath, $blob.ToArray())
    $binaryResult = Invoke-Scanner -ScanPath $binaryDirectory -NoGit
    Assert-ExitCode -Result $binaryResult -Expected 0 -Description "binary file with embedded token is skipped"
}
finally {
    Remove-TestDirectory -Directory $binaryDirectory
}

# --- Line numbers are emitted on a hit (M2: triage cost). ---
$lineNumberDirectory = New-TestDirectory
try {
    $lines = @("line one", "line two", ("Token: " + ("s" + "k-" + "lineNumberMarker1234567890")))
    Set-Content -LiteralPath (Join-Path $lineNumberDirectory "notes.md") -Value $lines -Encoding UTF8
    $lineNumberResult = Invoke-Scanner -ScanPath $lineNumberDirectory -NoGit
    Assert-ExitCode -Result $lineNumberResult -Expected 1 -Description "line-numbered output"
    Assert-OutputContains -Result $lineNumberResult -Pattern "\b3\b" -Description "line-numbered output (line 3)"
}
finally {
    Remove-TestDirectory -Directory $lineNumberDirectory
}

# --- 新H-A: git-tracked enumeration. An untracked file with a private marker must NOT fail
#     the scan (matches CI checkout), but the same file once tracked must be detected. This
#     test only runs when git is available; otherwise it is skipped (reported as such). ---
$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($gitCommand) {
    $gitFixtureRoot = Join-Path $scratchRoot ("git-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $gitFixtureRoot | Out-Null
    try {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        & git -C $gitFixtureRoot init -q 2>&1 | Out-Null
        & git -C $gitFixtureRoot config user.email "test@example.com" 2>&1 | Out-Null
        & git -C $gitFixtureRoot config user.name "test" 2>&1 | Out-Null
        $ErrorActionPreference = $previousErrorActionPreference

        $secretValue = ("s" + "k-" + "gitTrackedMarker1234567890")
        Set-Content -LiteralPath (Join-Path $gitFixtureRoot "untracked.md") -Value ("Token: " + $secretValue) -Encoding UTF8

        # Untracked: git-tracked enumeration finds nothing -> exit 0.
        $untrackedResult = Invoke-Scanner -ScanPath $gitFixtureRoot
        Assert-ExitCode -Result $untrackedResult -Expected 0 -Description "git-tracked scan ignores untracked private marker"
        Assert-OutputContains -Result $untrackedResult -Pattern "git-tracked" -Description "git-tracked scan reports its mode"

        # Now track it: must be detected.
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        & git -C $gitFixtureRoot add untracked.md 2>&1 | Out-Null
        $gitAddExitCode = $LASTEXITCODE
        $trackedFiles = & git -C $gitFixtureRoot ls-files -- untracked.md 2>$null
        $ErrorActionPreference = $previousErrorActionPreference

        if ($gitAddExitCode -ne 0 -or [string]::IsNullOrWhiteSpace(($trackedFiles -join ""))) {
            Add-Failure "git-tracked fixture could not stage tracked marker; tracked-marker detection was not verified"
        }
        else {
            $trackedResult = Invoke-Scanner -ScanPath $gitFixtureRoot
            Assert-ExitCode -Result $trackedResult -Expected 1 -Description "git-tracked scan detects tracked private marker"
            Assert-OutputContains -Result $trackedResult -Pattern "OpenAI-style token" -Description "git-tracked scan detects tracked private marker"
        }
    }
    finally {
        Remove-TestDirectory -Directory $gitFixtureRoot
    }
}
else {
    Write-Host "git not available; skipping git-tracked enumeration test (未確認)."
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    Write-Error "$($failures.Count) scanner tests failed."
    exit 1
}

Write-Host "Private marker scanner tests passed."
exit 0
