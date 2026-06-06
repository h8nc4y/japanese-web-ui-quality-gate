param(
    [string]$Path = "."
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath $Path).Path
$scannerPath = Join-Path $repoRoot "scripts/scan-private-markers.ps1"
$scratchRoot = Join-Path $repoRoot ".test-tmp/scan-private-markers"
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    [void]$failures.Add($Message)
}

function Invoke-Scanner {
    param(
        [Parameter(Mandatory = $true)][string]$ScanPath,
        [string[]]$AllowedGitHubRepositories = @("h8nc4y/japanese-web-ui-quality-gate")
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $scannerPath -Path $ScanPath -AllowedGitHubRepositories $AllowedGitHubRepositories 2>&1
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

    Remove-Item -LiteralPath $resolvedDirectory -Recurse -Force
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
    $allowedRepositoryResult = Invoke-Scanner -ScanPath $allowedRepositoryDirectory
    Assert-ExitCode -Result $allowedRepositoryResult -Expected 0 -Description "allowlisted GitHub repository"
}
finally {
    Remove-TestDirectory -Directory $allowedRepositoryDirectory
}

$secretDirectory = New-TestDirectory
try {
    $syntheticToken = ("s" + "k-" + "testSyntheticMarker1234567890")
    Set-Content -LiteralPath (Join-Path $secretDirectory "notes.md") -Value "Token: $syntheticToken" -Encoding UTF8
    $secretResult = Invoke-Scanner -ScanPath $secretDirectory
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
    $nonAllowlistedRepositoryResult = Invoke-Scanner -ScanPath $nonAllowlistedRepositoryDirectory
    Assert-ExitCode -Result $nonAllowlistedRepositoryResult -Expected 1 -Description "non-allowlisted GitHub repository"
    Assert-OutputContains -Result $nonAllowlistedRepositoryResult -Pattern "Non-allowlisted GitHub repository URL" -Description "non-allowlisted GitHub repository"
}
finally {
    Remove-TestDirectory -Directory $nonAllowlistedRepositoryDirectory
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    Write-Error "$($failures.Count) scanner tests failed."
    exit 1
}

Write-Host "Private marker scanner tests passed."
exit 0
