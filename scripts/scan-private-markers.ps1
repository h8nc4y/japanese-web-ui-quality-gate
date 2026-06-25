param(
    [string]$Path = ".",
    [string[]]$AllowedGitHubRepositories = @("h8nc4y/japanese-web-ui-quality-gate"),
    # When set, force the filesystem walk even inside a git working tree.
    # Mainly for tests; production/CI should keep the default (git-tracked when available).
    [switch]$NoGit
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path -LiteralPath $Path
$rootPath = $root.Path
$scriptPath = $MyInvocation.MyCommand.Path

function Get-PathRelativeToScanRoot {
    param([string]$TargetPath)

    $resolvedTargetPath = (Resolve-Path -LiteralPath $TargetPath).Path
    $basePath = $rootPath
    $directorySeparator = [System.IO.Path]::DirectorySeparatorChar
    $alternateSeparator = [System.IO.Path]::AltDirectorySeparatorChar

    if (-not $basePath.EndsWith($directorySeparator) -and -not $basePath.EndsWith($alternateSeparator)) {
        $basePath = $basePath + $directorySeparator
    }

    $baseUri = [System.Uri]$basePath
    $targetUri = [System.Uri]$resolvedTargetPath
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace("/", $directorySeparator)
}

# Secret/private-marker patterns. Prefixes are split across string concatenation so the
# scanner file itself does not carry a literal secret prefix (no blanket self-exemption).
# Best-effort heuristics only: this list does not guarantee detection of every secret form.
$patterns = @(
    @{ Name = "OpenAI-style token"; Pattern = "(?<![A-Za-z0-9_-])" + "s" + "k-[A-Za-z0-9_-]{10,}" },
    @{ Name = "GitHub classic token"; Pattern = "gh" + "p_[A-Za-z0-9_]{10,}" },
    @{ Name = "GitHub fine-grained token"; Pattern = "github" + "_pat_[A-Za-z0-9_]{10,}" },
    @{ Name = "Slack token"; Pattern = "xo" + "x[pabr]-[A-Za-z0-9-]{10,}" },
    @{ Name = "Slack app-level token"; Pattern = "xa" + "pp-[A-Za-z0-9-]{10,}" },
    @{ Name = "AWS access key id"; Pattern = "AK" + "IA[0-9A-Z]{16}" },
    @{ Name = "Google API key"; Pattern = "AI" + "za[0-9A-Za-z_\-]{35}" },
    @{ Name = "Stripe live secret key"; Pattern = "(s" + "k|rk)_live_[0-9A-Za-z]{16,}" },
    @{ Name = "Authorization token header"; Pattern = "Bear" + "er\s+[A-Za-z0-9._~+/-]{8,}=*" },
    @{ Name = "Private key block"; Pattern = "BEGIN" + " (RSA |EC |OPENSSH |ENCRYPTED |DSA |)?PRIVATE KEY" },
    @{ Name = "Windows user absolute path"; Pattern = "[A-Za-z]:\\Users\\" },
    @{ Name = "Windows absolute path"; Pattern = "[A-Za-z]:\\[A-Za-z0-9_. -]+\\[A-Za-z0-9_. -]+" },
    @{ Name = "Unix home absolute path"; Pattern = "/(Users|home)/[^/\s]+" },
    @{ Name = "Email address"; Pattern = "\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b" }
)

# Email domains/addresses treated as documentation placeholders (not real PII).
# example.* are reserved by RFC 2606; noreply@ and npm-scope-style handles are common in docs.
$emailMarkerName = "Email address"
$emailAllowlistPatterns = @(
    "@example\.(com|org|net)$",
    "^noreply@",
    "@users\.noreply\.github\.com$"
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

# Directory exclusions used only by the filesystem-walk fallback. When git-tracked
# enumeration is used these are redundant (git already excludes ignored paths), but they
# keep the fallback aligned with .gitignore intent (docs/.claude/.codex are untracked work
# areas that must not trip the scan when git is unavailable).
$excludedDirectories = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(".git", ".test-tmp", "node_modules", "vendor", "dist", "build", ".claude", ".codex", "docs") | ForEach-Object { [void]$excludedDirectories.Add($_) }

# Restrict scanning to text-like files. Binary assets (images/fonts/archives) are skipped to
# avoid byte-noise false positives and wasted IO. Unknown/no-extension files fall through to
# a NUL-byte binary check below.
$binaryExtensions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico", ".webp", ".tif", ".tiff",
    ".pdf", ".zip", ".gz", ".tar", ".7z", ".rar",
    ".woff", ".woff2", ".ttf", ".otf", ".eot",
    ".mp3", ".mp4", ".mov", ".avi", ".wav", ".webm",
    ".exe", ".dll", ".so", ".dylib", ".bin", ".class", ".o",
    ".db", ".sqlite", ".sqlite3"
) | ForEach-Object { [void]$binaryExtensions.Add($_) }

function Test-LooksBinary {
    param([string]$FullPath)

    try {
        $stream = [System.IO.File]::OpenRead($FullPath)
        try {
            $buffer = New-Object byte[] 8000
            $read = $stream.Read($buffer, 0, $buffer.Length)
            for ($i = 0; $i -lt $read; $i++) {
                if ($buffer[$i] -eq 0) { return $true }
            }
        }
        finally {
            $stream.Dispose()
        }
    }
    catch {
        return $false
    }
    return $false
}

# Enumerate scan targets. Prefer git-tracked files so the scan matches what CI actually
# checks out (resolves the "working-tree vs CI checkout" drift): untracked docs/ or .claude/
# private paths no longer fail the scan, but anything someone `git add`s is detected.
function Get-ScanTargetFiles {
    $useGit = $false
    if (-not $NoGit) {
        $gitCommand = Get-Command git -ErrorAction SilentlyContinue
        if ($gitCommand) {
            $previousErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            try {
                $insideWorkTree = (& git -C $rootPath rev-parse --is-inside-work-tree 2>$null)
            }
            catch {
                $insideWorkTree = $null
            }
            finally {
                $ErrorActionPreference = $previousErrorActionPreference
            }
            if ($LASTEXITCODE -eq 0 -and $insideWorkTree -is [string] -and $insideWorkTree.Trim() -eq "true") {
                $useGit = $true
            }
        }
    }

    if ($useGit) {
        $script:ScanMode = "git-tracked"
        # -z = NUL-delimited to survive unusual filenames; tracked files only.
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $rawList = & git -C $rootPath ls-files -z 2>$null
        $ErrorActionPreference = $previousErrorActionPreference
        $relativePaths = ($rawList -join "") -split "`0" | Where-Object { $_ -ne "" }
        $result = foreach ($rel in $relativePaths) {
            $full = Join-Path $rootPath $rel
            if (Test-Path -LiteralPath $full -PathType Leaf) {
                Get-Item -LiteralPath $full
            }
        }
        return @($result)
    }

    $script:ScanMode = "working-tree"
    return @(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
        $relative = Get-PathRelativeToScanRoot -TargetPath $_.FullName
        $parts = $relative -split "[\\/]+"
        foreach ($part in $parts) {
            if ($excludedDirectories.Contains($part)) { return $false }
        }
        return $true
    })
}

$script:ScanMode = "working-tree"
$candidateFiles = Get-ScanTargetFiles

$files = $candidateFiles | Where-Object {
    # Always skip the scanner file itself (its concatenated prefixes are not secrets).
    if ($scriptPath -and ((Resolve-Path -LiteralPath $_.FullName).Path -eq (Resolve-Path -LiteralPath $scriptPath).Path)) {
        return $false
    }
    if ($binaryExtensions.Contains($_.Extension)) { return $false }
    if (Test-LooksBinary -FullPath $_.FullName) { return $false }
    return $true
}

function Test-EmailAllowlisted {
    param([string]$Value)
    foreach ($allow in $emailAllowlistPatterns) {
        if ([regex]::IsMatch($Value, $allow, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            return $true
        }
    }
    return $false
}

$hits = @()

foreach ($file in $files) {
    # Read line-by-line (not -Raw) so we can report line numbers and a redacted excerpt,
    # cutting the cost of triaging a hit.
    $lines = Get-Content -LiteralPath $file.FullName -ErrorAction SilentlyContinue
    if ($null -eq $lines) { continue }

    $relativeFile = Get-PathRelativeToScanRoot -TargetPath $file.FullName
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        foreach ($entry in $patterns) {
            foreach ($match in [regex]::Matches($line, $entry.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                # Email allowlist: documentation placeholders are not flagged.
                if ($entry.Name -eq $emailMarkerName -and (Test-EmailAllowlisted -Value $match.Value)) {
                    continue
                }
                $hits += [pscustomobject]@{
                    File = $relativeFile
                    Line = $lineNumber
                    Marker = $entry.Name
                }
            }
        }

        foreach ($match in [regex]::Matches($line, $githubRepositoryUrlPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $owner = $match.Groups[1].Value
            $repositoryName = $match.Groups[2].Value
            $repositoryName = $repositoryName.TrimEnd(">", ".", ",", ":", ";", ")", "]")
            if ($repositoryName.EndsWith(".git", [System.StringComparison]::OrdinalIgnoreCase)) {
                $repositoryName = $repositoryName.Substring(0, $repositoryName.Length - 4)
            }
            $repositorySlug = "$owner/$repositoryName"
            if (-not $allowedGitHubRepositorySet.Contains($repositorySlug)) {
                $hits += [pscustomobject]@{
                    File = $relativeFile
                    Line = $lineNumber
                    Marker = "Non-allowlisted GitHub repository URL: $repositorySlug"
                }
            }
        }
    }
}

Write-Host "Scan mode: $($script:ScanMode) (git-tracked = only files committed/staged in this repo)."

if ($hits.Count -gt 0) {
    $hits | Sort-Object File, Line, Marker | Format-Table -AutoSize File, Line, Marker
    Write-Error "Potential private or secret markers found. Review and remove or explicitly justify each hit before publishing."
    exit 1
}

Write-Host "No private or secret markers found."
