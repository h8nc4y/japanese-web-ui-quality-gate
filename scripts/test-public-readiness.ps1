param(
    [string]$Path = "."
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath $Path).Path
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    [void]$failures.Add($Message)
}

function Get-RepoFile {
    param([string]$RelativePath)
    return Join-Path $repoRoot $RelativePath
}

function Assert-FileExists {
    param([string]$RelativePath)
    if (-not (Test-Path -LiteralPath (Get-RepoFile $RelativePath) -PathType Leaf)) {
        Add-Failure "Missing file: $RelativePath"
    }
}

function Assert-DirectoryExists {
    param([string]$RelativePath)
    if (-not (Test-Path -LiteralPath (Get-RepoFile $RelativePath) -PathType Container)) {
        Add-Failure "Missing directory: $RelativePath"
    }
}

function Assert-Contains {
    param(
        [string]$RelativePath,
        [string]$Pattern,
        [string]$Description
    )

    $file = Get-RepoFile $RelativePath
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        Add-Failure "Cannot check missing file: $RelativePath"
        return
    }

    $content = Get-Content -LiteralPath $file -Raw
    if (-not [regex]::IsMatch($content, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        Add-Failure "$RelativePath does not contain expected content: $Description"
    }
}

function Assert-NotContains {
    param(
        [string]$RelativePath,
        [string]$Pattern,
        [string]$Description
    )

    $file = Get-RepoFile $RelativePath
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        return
    }

    $content = Get-Content -LiteralPath $file -Raw
    if ([regex]::IsMatch($content, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        Add-Failure "$RelativePath contains disallowed content: $Description"
    }
}

function Assert-ChecklistSummaryMatchesReadme {
    param(
        [string]$ChecklistPath,
        [string]$ReadmePath
    )

    $checklistFile = Get-RepoFile $ChecklistPath
    $readmeFile = Get-RepoFile $ReadmePath

    # Missing files are also reported by the required-file checks; stop this comparison safely.
    if (-not (Test-Path -LiteralPath $checklistFile -PathType Leaf)) {
        Add-Failure "Cannot count missing file: $ChecklistPath"
        return
    }
    if (-not (Test-Path -LiteralPath $readmeFile -PathType Leaf)) {
        Add-Failure "Cannot compare missing file: $ReadmePath"
        return
    }

    # Derive both counts from the checklist so this test does not need fixed expected numbers.
    $checklistContent = Get-Content -LiteralPath $checklistFile -Raw -Encoding UTF8
    $checkCount = [regex]::Matches($checklistContent, '(?m)^- \[ \] ').Count
    $axisCount = [regex]::Matches($checklistContent, '(?m)^##\s+').Count

    if ($checkCount -eq 0) {
        Add-Failure "$ChecklistPath contains no unchecked checklist items."
    }
    if ($axisCount -eq 0) {
        Add-Failure "$ChecklistPath contains no level-two axis sections."
    }

    # Compare every related numeric README claim so a partially stale summary also fails.
    $readmeContent = Get-Content -LiteralPath $readmeFile -Raw -Encoding UTF8
    $readmeCheckClaimPattern = '\b(?<count>\d+)(?:\s+detailed\s+checks\b|\s+checks\s+total\b|-item\s+checklist\b)'
    $readmeAxisClaimPattern = '\b(?:(?<count>\d+)(?:\s+evidence-based)?\s+evaluation\s+axes|all\s+(?<count>\d+)\s+axes)\b'
    $checkClaims = [regex]::Matches($readmeContent, $readmeCheckClaimPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $axisClaims = [regex]::Matches($readmeContent, $readmeAxisClaimPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    if ($checkClaims.Count -eq 0) {
        Add-Failure "$ReadmePath does not contain a numeric checklist count claim."
    }
    foreach ($claim in $checkClaims) {
        $claimedCount = [int]$claim.Groups['count'].Value
        if ($claimedCount -ne $checkCount) {
            Add-Failure "$ReadmePath checklist count claim ($claimedCount) does not match $ChecklistPath ($checkCount)."
        }
    }

    if ($axisClaims.Count -eq 0) {
        Add-Failure "$ReadmePath does not contain a numeric axis count claim."
    }
    foreach ($claim in $axisClaims) {
        $claimedCount = [int]$claim.Groups['count'].Value
        if ($claimedCount -ne $axisCount) {
            Add-Failure "$ReadmePath axis count claim ($claimedCount) does not match $ChecklistPath ($axisCount)."
        }
    }
}

@(
    "README.md",
    "LICENSE",
    "SKILL.md",
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "CHANGELOG.md",
    "references/checklist.md",
    ".github/workflows/validation.yml",
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/ISSUE_TEMPLATE/config.yml",
    ".github/ISSUE_TEMPLATE/quality-gate-review.md",
    ".github/ISSUE_TEMPLATE/docs-improvement.md"
) | ForEach-Object { Assert-FileExists $_ }

Assert-DirectoryExists ".github"
Assert-DirectoryExists ".github/workflows"
Assert-DirectoryExists ".github/ISSUE_TEMPLATE"

Assert-Contains ".gitignore" "(^|`n)\.test-tmp/" ".test-tmp/ is ignored"
Assert-Contains "README.md" "## License" "license section"
Assert-Contains "README.md" "MIT License" "MIT license is declared"
Assert-Contains "README.md" "## Contributing" "contribution path"
Assert-Contains "README.md" "## Security" "security reporting path"
Assert-Contains "README.md" "## Updating an Existing Install" "existing install update path"
Assert-Contains "README.md" "Compare-Object" "installed skill comparison guidance"
Assert-Contains "README.md" "Copy-Item" "installed skill update command"
Assert-NotContains "README.md" "license draft|before public release" "stale draft-release language"
Assert-ChecklistSummaryMatchesReadme "references/checklist.md" "README.md"

Assert-Contains "CODE_OF_CONDUCT.md" "harassment" "conduct expectations"
Assert-Contains "CONTRIBUTING.md" "scripts/scan-private-markers\.ps1" "private marker scan command"
Assert-Contains "CONTRIBUTING.md" "scripts/test-scan-private-markers\.ps1" "scanner test command"
Assert-Contains "CONTRIBUTING.md" "scripts/test-public-readiness\.ps1" "public readiness test command"
Assert-Contains "SECURITY.md" "Do not report secrets in public issues" "safe secret-reporting warning"
Assert-Contains "CHANGELOG.md" "## \[Unreleased\]" "unreleased changelog section"

Assert-Contains ".github/workflows/validation.yml" "scripts/scan-private-markers\.ps1" "CI runs marker scan"
Assert-Contains ".github/workflows/validation.yml" "scripts/test-scan-private-markers\.ps1" "CI runs scanner tests"
Assert-Contains ".github/workflows/validation.yml" "scripts/test-public-readiness\.ps1" "CI runs public readiness tests"
Assert-Contains ".github/PULL_REQUEST_TEMPLATE.md" "Tests / 検証" "PRs include verification section"
Assert-Contains ".github/ISSUE_TEMPLATE/quality-gate-review.md" "viewport" "UI review issue captures viewport evidence"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    Write-Error "$($failures.Count) public readiness checks failed."
    exit 1
}

Write-Host "Public readiness checks passed."
exit 0
