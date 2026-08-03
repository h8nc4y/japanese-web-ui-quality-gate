param(
    [string]$Path = "."
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath $Path).Path
$scannerPath = Join-Path $repoRoot "scripts/scan-private-markers.ps1"
$scratchRoot = Join-Path $repoRoot ".test-tmp/scan-private-markers"
$powerShellExecutable = (Get-Process -Id $PID).Path
$isWindowsHost = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
$failures = [System.Collections.Generic.List[string]]::new()
$cleanupWarningWritten = $false

function Add-Failure {
    param([string]$Message)
    [void]$failures.Add($Message)
}

function Invoke-Scanner {
    param(
        [Parameter(Mandatory = $true)][string]$ScanPath,
        [string]$ScannerScriptPath = $scannerPath,
        [string[]]$AllowedGitHubRepositories = @("h8nc4y/japanese-web-ui-quality-gate"),
        # Synthetic fixtures live under .test-tmp (untracked); force the filesystem walk so
        # they are actually read instead of being skipped by git-tracked enumeration.
        [switch]$NoGit
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScannerScriptPath, "-Path", $ScanPath, "-AllowedGitHubRepositories")
        $arguments += $AllowedGitHubRepositories
        if ($NoGit) { $arguments += "-NoGit" }
        # Reuse the current host executable so a Windows PowerShell 5.1 test does
        # not silently delegate the scanner invocation to PowerShell 7.
        $output = & $powerShellExecutable @arguments 2>&1
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

function Assert-OutputNotContains {
    param(
        [object]$Result,
        [string]$Pattern,
        [string]$Description
    )

    if ([regex]::IsMatch($Result.Output, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        Add-Failure "$Description unexpectedly contained pattern '$Pattern'. Output: $($Result.Output)"
    }
}

function Assert-OutputMatchCount {
    param(
        [object]$Result,
        [string]$Pattern,
        [int]$Expected,
        [string]$Description
    )

    $actual = [regex]::Matches($Result.Output, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Count
    if ($actual -ne $Expected) {
        Add-Failure "$Description expected $Expected matches, got $actual. Output: $($Result.Output)"
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

# --- The scanner source is a published scan target too. A copied scanner carrying a
#     runtime-assembled marker must fail closed without reflecting the marker value. ---
$scannerSelfScanDirectory = New-TestDirectory
try {
    $scannerSelfScanPath = Join-Path $scannerSelfScanDirectory "scan-private-markers.ps1"
    Copy-Item -LiteralPath $scannerPath -Destination $scannerSelfScanPath
    $scannerSelfScanToken = ("s" + "k-" + "scannerSelfScanMarker1234567890")
    $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::AppendAllText(
        $scannerSelfScanPath,
        ("`n# Synthetic self-scan fixture: " + $scannerSelfScanToken + "`n"),
        $utf8WithoutBom
    )

    $scannerSelfScanResult = Invoke-Scanner -ScannerScriptPath $scannerSelfScanPath -ScanPath $scannerSelfScanDirectory -NoGit
    Assert-ExitCode -Result $scannerSelfScanResult -Expected 1 -Description "scanner source is not blanket-exempt"
    Assert-OutputContains -Result $scannerSelfScanResult -Pattern "OpenAI-style token" -Description "scanner source marker detection"
    if ([regex]::IsMatch($scannerSelfScanResult.Output, [regex]::Escape($scannerSelfScanToken))) {
        Add-Failure "scanner source marker detection leaked the raw synthetic marker into scanner output."
    }
}
finally {
    Remove-TestDirectory -Directory $scannerSelfScanDirectory
}

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

# --- Double-hit suppression: a (drive letter + Users) path must be reported once by the
#     dedicated "Windows user absolute path" rule only, not also by the generic
#     "Windows absolute path" rule. The fixture path is assembled at runtime so this test
#     file itself does not carry a literal Windows absolute path that the repo scan would flag. ---
$windowsUserPathDirectory = New-TestDirectory
try {
    $windowsUserPath = "C:" + "\" + "Users" + "\" + "someone" + "\" + "notes.txt"
    Set-Content -LiteralPath (Join-Path $windowsUserPathDirectory "doc.md") -Value ("Path: " + $windowsUserPath) -Encoding UTF8
    $windowsUserPathResult = Invoke-Scanner -ScanPath $windowsUserPathDirectory -NoGit
    Assert-ExitCode -Result $windowsUserPathResult -Expected 1 -Description "Windows user absolute path"
    Assert-OutputContains -Result $windowsUserPathResult -Pattern "Windows user absolute path" -Description "Windows user absolute path"
    # Single-rule guarantee: the generic marker name must not appear for the same path.
    # ("Windows absolute path" is not a substring of "Windows user absolute path".)
    if ([regex]::IsMatch($windowsUserPathResult.Output, "Windows absolute path", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        Add-Failure "Windows user absolute path was double-reported by the generic Windows absolute path rule."
    }
}
finally {
    Remove-TestDirectory -Directory $windowsUserPathDirectory
}

# --- Generic Windows absolute path rule still fires for non-Users paths (the Users
#     exclusion must not silence unrelated absolute paths). ---
$windowsGenericPathDirectory = New-TestDirectory
try {
    $windowsGenericPath = "D:" + "\" + "Work" + "\" + "notes.txt"
    Set-Content -LiteralPath (Join-Path $windowsGenericPathDirectory "doc.md") -Value ("Path: " + $windowsGenericPath) -Encoding UTF8
    $windowsGenericPathResult = Invoke-Scanner -ScanPath $windowsGenericPathDirectory -NoGit
    Assert-ExitCode -Result $windowsGenericPathResult -Expected 1 -Description "generic Windows absolute path"
    Assert-OutputContains -Result $windowsGenericPathResult -Pattern "Windows absolute path" -Description "generic Windows absolute path"
}
finally {
    Remove-TestDirectory -Directory $windowsGenericPathDirectory
}

# --- Fallback walk scans docs/: docs is tracked content in this repository, so a private
#     marker under docs/ must be detected even in walk (-NoGit) mode. ---
$docsWalkDirectory = New-TestDirectory
try {
    $docsSubdirectory = Join-Path $docsWalkDirectory "docs"
    New-Item -ItemType Directory -Force -Path $docsSubdirectory | Out-Null
    $docsToken = ("s" + "k-" + "docsWalkMarker1234567890")
    Set-Content -LiteralPath (Join-Path $docsSubdirectory "note.md") -Value ("Token: " + $docsToken) -Encoding UTF8
    $docsWalkResult = Invoke-Scanner -ScanPath $docsWalkDirectory -NoGit
    Assert-ExitCode -Result $docsWalkResult -Expected 1 -Description "walk mode scans docs directory"
    Assert-OutputContains -Result $docsWalkResult -Pattern "OpenAI-style token" -Description "walk mode scans docs directory"
}
finally {
    Remove-TestDirectory -Directory $docsWalkDirectory
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

            # Keep the marker in the index, but overwrite only the working-tree copy with
            # benign text. A pre-publish scan must still inspect the staged blob instead of
            # trusting the newer working-tree bytes.
            Set-Content -LiteralPath (Join-Path $gitFixtureRoot "untracked.md") -Value "benign working-tree text" -Encoding UTF8
            $divergedResult = Invoke-Scanner -ScanPath $gitFixtureRoot
            Assert-ExitCode -Result $divergedResult -Expected 1 -Description "git-tracked scan detects marker retained only in the index"
            Assert-OutputContains -Result $divergedResult -Pattern "OpenAI-style token" -Description "git-tracked index scan reports the marker type"
            Assert-OutputNotContains -Result $divergedResult -Pattern ([regex]::Escape($secretValue)) -Description "git-tracked index scan redacts the marker value"
            Assert-OutputNotContains -Result $divergedResult -Pattern ([regex]::Escape($gitFixtureRoot)) -Description "git-tracked index scan does not expose the fixture root"

            # Preserve the complementary boundary: an unstaged marker in an already tracked
            # worktree file remains in scope even when the staged blob is benign.
            Set-Content -LiteralPath (Join-Path $gitFixtureRoot "untracked.md") -Value "benign staged text" -Encoding UTF8
            & git -C $gitFixtureRoot add untracked.md 2>&1 | Out-Null
            $stageBenignExitCode = $LASTEXITCODE
            Set-Content -LiteralPath (Join-Path $gitFixtureRoot "untracked.md") -Value ("Token: " + $secretValue) -Encoding UTF8
            if ($stageBenignExitCode -ne 0) {
                Add-Failure "git-tracked fixture could not stage benign content; worktree-only marker detection was not verified"
            }
            else {
                $worktreeOnlyResult = Invoke-Scanner -ScanPath $gitFixtureRoot
                Assert-ExitCode -Result $worktreeOnlyResult -Expected 1 -Description "git-tracked scan detects marker retained only in the worktree"
                Assert-OutputContains -Result $worktreeOnlyResult -Pattern "OpenAI-style token" -Description "git-tracked worktree scan reports the marker type"
                Assert-OutputNotContains -Result $worktreeOnlyResult -Pattern ([regex]::Escape($secretValue)) -Description "git-tracked worktree scan redacts the marker value"
            }

            # Identical staged/worktree bytes are scanned once so the same finding is not
            # duplicated merely because two publication views exist.
            & git -C $gitFixtureRoot add untracked.md 2>&1 | Out-Null
            $stageMarkerExitCode = $LASTEXITCODE
            if ($stageMarkerExitCode -ne 0) {
                Add-Failure "git-tracked fixture could not restage the marker; duplicate suppression was not verified"
            }
            else {
                $sameViewResult = Invoke-Scanner -ScanPath $gitFixtureRoot
                Assert-ExitCode -Result $sameViewResult -Expected 1 -Description "git-tracked identical index and worktree marker"
                Assert-OutputMatchCount -Result $sameViewResult -Pattern "OpenAI-style token" -Expected 1 -Description "git-tracked identical views report one marker row"
            }

            # Keep the index entry but remove only the working-tree file. The scanner must
            # not silently turn an uninspected tracked target into a successful empty scan.
            Remove-Item -LiteralPath (Join-Path $gitFixtureRoot "untracked.md") -Force
            $missingTrackedResult = Invoke-Scanner -ScanPath $gitFixtureRoot
            Assert-ExitCode -Result $missingTrackedResult -Expected 1 -Description "missing git-tracked scan target"
            Assert-OutputContains -Result $missingTrackedResult -Pattern "A git-tracked scan target is missing; scan aborted" -Description "missing git-tracked scan target"
            Assert-OutputNotContains -Result $missingTrackedResult -Pattern "untracked\.md" -Description "missing git-tracked scan target redacts the path"
        }
    }
    finally {
        Remove-TestDirectory -Directory $gitFixtureRoot
    }
}
else {
    Write-Host "git not available; skipping git-tracked enumeration test (未確認)."
}

# --- Intent-to-add entries have no complete staged content and must fail closed. ---
if ($gitCommand) {
    $intentFixtureRoot = Join-Path $scratchRoot ("git-intent-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $intentFixtureRoot | Out-Null
    try {
        & git -C $intentFixtureRoot init -q 2>&1 | Out-Null
        Set-Content -LiteralPath (Join-Path $intentFixtureRoot "intent.md") -Value "benign intent fixture" -Encoding UTF8
        & git -C $intentFixtureRoot add -N -- intent.md 2>&1 | Out-Null
        $intentAddExitCode = $LASTEXITCODE
        if ($intentAddExitCode -ne 0) {
            Add-Failure "intent-to-add fixture setup failed; fail-closed behavior was not verified"
        }
        else {
            $intentResult = Invoke-Scanner -ScanPath $intentFixtureRoot
            Assert-ExitCode -Result $intentResult -Expected 1 -Description "intent-to-add git index entry"
            Assert-OutputContains -Result $intentResult -Pattern "Intent-to-add git index entry; scan aborted" -Description "intent-to-add git index entry"
            Assert-OutputNotContains -Result $intentResult -Pattern "intent\.md" -Description "intent-to-add diagnostic redacts the path"
        }
    }
    finally {
        Remove-TestDirectory -Directory $intentFixtureRoot
    }
}

# --- Symlink/gitlink and other non-regular index modes are not safe text targets. ---
if ($gitCommand) {
    $modeFixtureRoot = Join-Path $scratchRoot ("git-mode-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $modeFixtureRoot | Out-Null
    try {
        & git -C $modeFixtureRoot init -q 2>&1 | Out-Null
        Set-Content -LiteralPath (Join-Path $modeFixtureRoot "blob-source.txt") -Value "benign blob" -Encoding UTF8
        $blobId = ((& git -C $modeFixtureRoot hash-object -w -- blob-source.txt 2>$null) | Select-Object -First 1)
        $hashExitCode = $LASTEXITCODE
        if ($hashExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($blobId)) {
            $cacheInfo = "120000,$($blobId.Trim()),unsafe-link"
            & git -C $modeFixtureRoot update-index --add --cacheinfo $cacheInfo 2>&1 | Out-Null
        }
        $modeSetupExitCode = $LASTEXITCODE
        if ($hashExitCode -ne 0 -or $modeSetupExitCode -ne 0) {
            Add-Failure "unsupported-mode fixture setup failed; fail-closed behavior was not verified"
        }
        else {
            $modeResult = Invoke-Scanner -ScanPath $modeFixtureRoot
            Assert-ExitCode -Result $modeResult -Expected 1 -Description "unsupported git index mode"
            Assert-OutputContains -Result $modeResult -Pattern "Unsupported git index entry; scan aborted" -Description "unsupported git index mode"
            Assert-OutputNotContains -Result $modeResult -Pattern "unsafe-link" -Description "unsupported-mode diagnostic redacts the path"
        }
    }
    finally {
        Remove-TestDirectory -Directory $modeFixtureRoot
    }
}

# --- A dirty worktree file can change bytes without changing its porcelain XY status. ---
if ($gitCommand) {
    $raceFixtureRoot = Join-Path $scratchRoot ("git-race-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $raceFixtureRoot | Out-Null
    $raceTargetPath = Join-Path $raceFixtureRoot "race.md"
    try {
        & git -C $raceFixtureRoot init -q 2>&1 | Out-Null
        Set-Content -LiteralPath $raceTargetPath -Value "benign staged race fixture" -Encoding UTF8
        & git -C $raceFixtureRoot add -- race.md 2>&1 | Out-Null
        $raceAddExitCode = $LASTEXITCODE
        Set-Content -LiteralPath $raceTargetPath -Value "different benign worktree fixture" -Encoding UTF8

        # Instrument only a scratch copy: mutate the already-dirty file after its first read,
        # immediately before production revalidation. The public scanner API remains unchanged.
        $instrumentedScannerPath = Join-Path $raceFixtureRoot "instrumented-scanner.ps1"
        $scannerSource = [System.IO.File]::ReadAllText($scannerPath, [System.Text.Encoding]::UTF8)
        $raceHookAnchor = "# A success result is valid only for the index/status snapshot that was actually scanned."
        $raceHook = @(
            '$raceFixtureValue = ("s" + "k-" + "worktreeRaceMarker1234567890")',
            '$raceFixtureEncoding = [System.Text.UTF8Encoding]::new($false)',
            '[System.IO.File]::WriteAllText((Join-Path $rootPath "race.md"), ("Token: " + $raceFixtureValue), $raceFixtureEncoding)'
        ) -join [System.Environment]::NewLine
        $instrumentedSource = $scannerSource.Replace($raceHookAnchor, ($raceHook + [System.Environment]::NewLine + $raceHookAnchor))
        [System.IO.File]::WriteAllText($instrumentedScannerPath, $instrumentedSource, [System.Text.UTF8Encoding]::new($false))

        if ($raceAddExitCode -ne 0 -or $instrumentedSource -eq $scannerSource) {
            Add-Failure "worktree-race fixture setup failed; final byte revalidation was not verified"
        }
        else {
            $raceResult = Invoke-Scanner -ScanPath $raceFixtureRoot -ScannerScriptPath $instrumentedScannerPath
            Assert-ExitCode -Result $raceResult -Expected 1 -Description "tracked worktree bytes change during inspection"
            Assert-OutputContains -Result $raceResult -Pattern "A tracked working-tree target changed during inspection; scan aborted" -Description "tracked worktree bytes change during inspection"
            Assert-OutputNotContains -Result $raceResult -Pattern "worktreeRaceMarker1234567890" -Description "worktree-race diagnostic redacts the marker value"
            Assert-OutputNotContains -Result $raceResult -Pattern "race\.md" -Description "worktree-race diagnostic redacts the path"
        }
    }
    finally {
        # Remove even the synthetic marker before cleanup so a cleanup warning cannot leave a
        # secret-shaped fixture behind in the ignored scratch directory.
        if (Test-Path -LiteralPath $raceTargetPath -PathType Leaf) {
            Set-Content -LiteralPath $raceTargetPath -Value "benign cleanup content" -Encoding UTF8
        }
        Remove-TestDirectory -Directory $raceFixtureRoot
    }
}

# --- The index can change while exact worktree bytes are being revalidated. ---
if ($gitCommand) {
    $indexRaceFixtureRoot = Join-Path $scratchRoot ("git-index-race-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $indexRaceFixtureRoot | Out-Null
    $indexRaceTargetPath = Join-Path $indexRaceFixtureRoot "race.md"
    try {
        & git -C $indexRaceFixtureRoot init -q 2>&1 | Out-Null
        Set-Content -LiteralPath $indexRaceTargetPath -Value "benign index-race fixture" -Encoding UTF8
        & git -C $indexRaceFixtureRoot add -- race.md 2>&1 | Out-Null
        $indexRaceAddExitCode = $LASTEXITCODE

        # Inject an index-only mutation immediately after production worktree revalidation,
        # then restore the worktree bytes so only the final Git snapshot can detect it.
        $indexRaceScannerPath = Join-Path $indexRaceFixtureRoot "instrumented-index-scanner.ps1"
        $indexRaceScannerSource = [System.IO.File]::ReadAllText($scannerPath, [System.Text.Encoding]::UTF8)
        $indexRaceHookAnchor = "# Recheck Git after the worktree pass as well. This catches an index-only update that"
        $indexRaceHook = @(
            '$indexRaceTarget = Join-Path $rootPath "race.md"',
            '$indexRaceOriginal = [System.IO.File]::ReadAllBytes($indexRaceTarget)',
            '$indexRaceValue = ("s" + "k-" + "indexRaceMarker1234567890")',
            '$indexRaceEncoding = [System.Text.UTF8Encoding]::new($false)',
            '[System.IO.File]::WriteAllText($indexRaceTarget, ("Token: " + $indexRaceValue), $indexRaceEncoding)',
            '& git -C $rootPath add -- race.md 2>$null | Out-Null',
            '[System.IO.File]::WriteAllBytes($indexRaceTarget, $indexRaceOriginal)'
        ) -join [System.Environment]::NewLine
        $instrumentedIndexSource = $indexRaceScannerSource.Replace($indexRaceHookAnchor, ($indexRaceHook + [System.Environment]::NewLine + $indexRaceHookAnchor))
        [System.IO.File]::WriteAllText($indexRaceScannerPath, $instrumentedIndexSource, [System.Text.UTF8Encoding]::new($false))

        if ($indexRaceAddExitCode -ne 0 -or $instrumentedIndexSource -eq $indexRaceScannerSource) {
            Add-Failure "index-race fixture setup failed; post-worktree Git revalidation was not verified"
        }
        else {
            $indexRaceResult = Invoke-Scanner -ScanPath $indexRaceFixtureRoot -ScannerScriptPath $indexRaceScannerPath
            Assert-ExitCode -Result $indexRaceResult -Expected 1 -Description "git index changes after worktree revalidation"
            Assert-OutputContains -Result $indexRaceResult -Pattern "Git scan state changed during inspection; scan aborted" -Description "git index changes after worktree revalidation"
            Assert-OutputNotContains -Result $indexRaceResult -Pattern "indexRaceMarker1234567890" -Description "index-race diagnostic redacts the marker value"
            Assert-OutputNotContains -Result $indexRaceResult -Pattern "race\.md" -Description "index-race diagnostic redacts the path"
        }
    }
    finally {
        # Restore benign index/worktree state before bounded scratch cleanup.
        if (Test-Path -LiteralPath $indexRaceTargetPath -PathType Leaf) {
            Set-Content -LiteralPath $indexRaceTargetPath -Value "benign cleanup content" -Encoding UTF8
            & git -C $indexRaceFixtureRoot add -- race.md 2>&1 | Out-Null
        }
        Remove-TestDirectory -Directory $indexRaceFixtureRoot
    }
}

# --- A tracked-file enumeration failure must not become a successful zero-file scan. ---
$gitFailureDirectory = New-TestDirectory
try {
    $fakeGitBin = Join-Path $gitFailureDirectory "fake-git-bin"
    New-Item -ItemType Directory -Force -Path $fakeGitBin | Out-Null
    if ($isWindowsHost) {
        $fakeGitPath = Join-Path $fakeGitBin "git.cmd"
        @(
            '@echo off',
            'if "%~3"=="rev-parse" (',
            '  echo true',
            '  exit /b 0',
            ')',
            'echo synthetic git enumeration failure 1>&2',
            'exit /b 42'
        ) | Set-Content -LiteralPath $fakeGitPath -Encoding ASCII
    }
    else {
        $fakeGitPath = Join-Path $fakeGitBin "git"
        @(
            '#!/bin/sh',
            'if [ "$3" = "rev-parse" ]; then',
            '  echo true',
            '  exit 0',
            'fi',
            'echo synthetic git enumeration failure >&2',
            'exit 42'
        ) | Set-Content -LiteralPath $fakeGitPath -Encoding ASCII
        & chmod +x -- $fakeGitPath
        if ($LASTEXITCODE -ne 0) {
            throw "Could not make the fake git fixture executable."
        }
    }

    $previousPath = $env:PATH
    try {
        # Only the child scanner resolves fake git first; earlier real-git fixtures stay isolated.
        $env:PATH = $fakeGitBin + [System.IO.Path]::PathSeparator + $previousPath
        $gitFailureResult = Invoke-Scanner -ScanPath $gitFailureDirectory
    }
    finally {
        $env:PATH = $previousPath
    }

    Assert-ExitCode -Result $gitFailureResult -Expected 1 -Description "git tracked-file enumeration failure"
    Assert-OutputContains -Result $gitFailureResult -Pattern "Failed to enumerate git-tracked scan targets" -Description "git tracked-file enumeration failure"
    Assert-OutputNotContains -Result $gitFailureResult -Pattern "synthetic git enumeration failure" -Description "git tracked-file enumeration failure redacts native stderr"
}
finally {
    Remove-TestDirectory -Directory $gitFailureDirectory
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    Write-Error "$($failures.Count) scanner tests failed."
    exit 1
}

Write-Host "Private marker scanner tests passed."
exit 0
