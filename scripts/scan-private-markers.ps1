param(
    [string]$Path = ".",
    [string[]]$AllowedGitHubRepositories = @("h8nc4y/japanese-web-ui-quality-gate")
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path -LiteralPath $Path
$scriptPath = $MyInvocation.MyCommand.Path

$patterns = @(
    @{ Name = "OpenAI-style token"; Pattern = "s" + "k-[A-Za-z0-9_-]{10,}" },
    @{ Name = "GitHub classic token"; Pattern = "gh" + "p_[A-Za-z0-9_]{10,}" },
    @{ Name = "GitHub fine-grained token"; Pattern = "github" + "_pat_[A-Za-z0-9_]{10,}" },
    @{ Name = "Slack bot token"; Pattern = "xo" + "xb-[A-Za-z0-9-]{10,}" },
    @{ Name = "Authorization token header"; Pattern = "Bear" + "er\s+[A-Za-z0-9._~+/-]+=*" },
    @{ Name = "Private key block"; Pattern = "BEGIN" + " (RSA |EC |OPENSSH |)?PRIVATE KEY" },
    @{ Name = "Windows user absolute path"; Pattern = "[A-Za-z]:\\Users\\" },
    @{ Name = "Windows absolute path"; Pattern = "[A-Za-z]:\\[A-Za-z0-9_. -]+\\[A-Za-z0-9_. -]+" },
    @{ Name = "Unix home absolute path"; Pattern = "/(Users|home)/[^/\s]+" },
    @{ Name = "Email address"; Pattern = "[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}" }
)

$allowedGitHubRepositorySet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($repository in $AllowedGitHubRepositories) {
    $normalizedRepository = $repository.Trim().Trim("/")
    if ($normalizedRepository.StartsWith("https://github.com/", [System.StringComparison]::OrdinalIgnoreCase)) {
        $normalizedRepository = $normalizedRepository.Substring("https://github.com/".Length)
    }
    if ($normalizedRepository.EndsWith(".git", [System.StringComparison]::OrdinalIgnoreCase)) {
        $normalizedRepository = $normalizedRepository.Substring(0, $normalizedRepository.Length - 4)
    }
    [void]$allowedGitHubRepositorySet.Add($normalizedRepository)
}

$githubRepositoryUrlPattern = "https?://github\.com/([^/\s?#]+)/([^/\s?#]+)"

$excludedDirectories = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(".git", "node_modules", "vendor", "dist", "build") | ForEach-Object { [void]$excludedDirectories.Add($_) }

$files = Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
    $relative = Resolve-Path -LiteralPath $_.FullName -Relative
    $parts = $relative -split "[\\/]+"
    foreach ($part in $parts) {
        if ($excludedDirectories.Contains($part)) { return $false }
    }
    if ($scriptPath -and ((Resolve-Path -LiteralPath $_.FullName).Path -eq (Resolve-Path -LiteralPath $scriptPath).Path)) {
        return $false
    }
    return $true
}

$hits = @()

foreach ($file in $files) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { continue }

    foreach ($entry in $patterns) {
        if ([regex]::IsMatch($content, $entry.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $hits += [pscustomobject]@{
                File = Resolve-Path -LiteralPath $file.FullName -Relative
                Marker = $entry.Name
            }
        }
    }

    foreach ($match in [regex]::Matches($content, $githubRepositoryUrlPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        $owner = $match.Groups[1].Value
        $repositoryName = $match.Groups[2].Value
        if ($repositoryName.EndsWith(".git", [System.StringComparison]::OrdinalIgnoreCase)) {
            $repositoryName = $repositoryName.Substring(0, $repositoryName.Length - 4)
        }
        $repositorySlug = "$owner/$repositoryName"
        if (-not $allowedGitHubRepositorySet.Contains($repositorySlug)) {
            $hits += [pscustomobject]@{
                File = Resolve-Path -LiteralPath $file.FullName -Relative
                Marker = "Non-allowlisted GitHub repository URL: $repositorySlug"
            }
        }
    }
}

if ($hits.Count -gt 0) {
    $hits | Sort-Object File, Marker | Format-Table -AutoSize
    Write-Error "Potential private or secret markers found. Review and remove or explicitly justify each hit before publishing."
    exit 1
}

Write-Host "No private or secret markers found."
