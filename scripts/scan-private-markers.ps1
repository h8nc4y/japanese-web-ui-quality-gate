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
    # The generic rule excludes user-profile paths so the dedicated rule above reports each
    # one only once (matching is IgnoreCase, so differently cased directory names are covered).
    @{ Name = "Windows absolute path"; Pattern = "[A-Za-z]:\\(?!Users\\)[A-Za-z0-9_. -]+\\[A-Za-z0-9_. -]+" },
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
# keep the fallback aligned with .gitignore intent (.claude/.codex are untracked work
# areas that must not trip the scan when git is unavailable). docs/ is tracked content in
# this repository, so the fallback walk must scan it like any other published directory.
$excludedDirectories = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(".git", ".test-tmp", "node_modules", "vendor", "dist", "build", ".claude", ".codex") | ForEach-Object { [void]$excludedDirectories.Add($_) }

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

function Test-BytesLookBinary {
    param([byte[]]$Bytes)

    $limit = [Math]::Min(8000, $Bytes.Length)
    for ($i = 0; $i -lt $limit; $i++) {
        if ($Bytes[$i] -eq 0) { return $true }
    }
    return $false
}

function Test-ByteArraysEqual {
    param(
        [byte[]]$Left,
        [byte[]]$Right
    )

    if ($Left.Length -ne $Right.Length) { return $false }
    for ($i = 0; $i -lt $Left.Length; $i++) {
        if ($Left[$i] -ne $Right[$i]) { return $false }
    }
    return $true
}

function Invoke-GitRaw {
    param([string]$Arguments)

    # Native PowerShell output capture is line- and encoding-oriented. Use redirected raw
    # bytes so NUL-delimited Git records and UTF-8 paths survive on both PS 5.1 and PS 7.
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        return [pscustomobject]@{ Success = $false; Bytes = [byte[]]@() }
    }

    $executablePath = $gitCommand.Source
    if ([string]::IsNullOrWhiteSpace($executablePath)) {
        $executablePath = $gitCommand.Path
    }
    if ([string]::IsNullOrWhiteSpace($executablePath)) {
        return [pscustomobject]@{ Success = $false; Bytes = [byte[]]@() }
    }

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $executablePath
    $startInfo.WorkingDirectory = $rootPath
    # Callers pass only fixed Git subcommands or a validated hexadecimal object id. Keeping
    # the argument surface closed avoids shell interpolation while remaining PS 5.1-compatible.
    $startInfo.Arguments = $Arguments
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $stdout = [System.IO.MemoryStream]::new()
    $success = $false
    $capturedBytes = [byte[]]@()

    try {
        if (-not $process.Start()) {
            return [pscustomobject]@{ Success = $false; Bytes = [byte[]]@() }
        }

        # Drain both pipes concurrently; a large tracked-file list must not deadlock while
        # the process waits for either redirected stream to be consumed.
        $stdoutTask = $process.StandardOutput.BaseStream.CopyToAsync($stdout)
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(30000)) {
            try { $process.Kill() } catch { }
        }
        [void]($stdoutTask.GetAwaiter().GetResult())
        [void]($stderrTask.GetAwaiter().GetResult())

        if ($process.HasExited -and $process.ExitCode -eq 0) {
            $capturedBytes = $stdout.ToArray()
            $success = $true
        }
    }
    catch {
        $success = $false
        $capturedBytes = [byte[]]@()
    }
    finally {
        $stdout.Dispose()
        $process.Dispose()
    }

    return [pscustomobject]@{ Success = $success; Bytes = $capturedBytes }
}

function ConvertFrom-StrictUtf8Bytes {
    param(
        [byte[]]$Bytes,
        [string]$FailureMessage
    )

    try {
        $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
        return $utf8.GetString($Bytes)
    }
    catch {
        Write-Host $FailureMessage
        exit 1
    }
}

function Split-NulTerminatedGitRecords {
    param(
        [byte[]]$Bytes,
        [string]$FailureMessage
    )

    if ($Bytes.Length -eq 0) { return @() }
    if ($Bytes[$Bytes.Length - 1] -ne 0) {
        Write-Host $FailureMessage
        exit 1
    }

    $text = ConvertFrom-StrictUtf8Bytes -Bytes $Bytes -FailureMessage $FailureMessage
    $splitRecords = @($text.Split([char[]]@([char]0), [System.StringSplitOptions]::None))
    $records = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt ($splitRecords.Count - 1); $i++) {
        if ($splitRecords[$i] -eq "") {
            Write-Host $FailureMessage
            exit 1
        }
        [void]$records.Add($splitRecords[$i])
    }
    return @($records)
}

function Get-GitIndexState {
    $indexResult = Invoke-GitRaw -Arguments "ls-files --stage -z"
    if (-not $indexResult.Success) {
        Write-Host "Failed to enumerate git-tracked scan targets; scan aborted."
        exit 1
    }

    $statusResult = Invoke-GitRaw -Arguments "status --porcelain=v2 -z --untracked-files=no"
    if (-not $statusResult.Success) {
        Write-Host "Failed to inspect git index state; scan aborted."
        exit 1
    }

    # Force array shape even when Git returns exactly one record; otherwise PowerShell scalar
    # unrolling makes index access return a character instead of the record string.
    $indexRecords = @(Split-NulTerminatedGitRecords -Bytes $indexResult.Bytes -FailureMessage "Malformed git index data; scan aborted.")
    $statusRecords = @(Split-NulTerminatedGitRecords -Bytes $statusResult.Bytes -FailureMessage "Malformed git status data; scan aborted.")
    $entries = [System.Collections.Generic.List[object]]::new()
    $seenPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

    foreach ($record in $indexRecords) {
        $match = [regex]::Match($record, "\A(?<mode>[0-9]{6}) (?<oid>[0-9a-fA-F]{40}|[0-9a-fA-F]{64}) (?<stage>[0-3])\t(?<path>[\s\S]+)\z")
        if (-not $match.Success) {
            Write-Host "Malformed git index entry; scan aborted."
            exit 1
        }

        $mode = $match.Groups["mode"].Value
        $objectId = $match.Groups["oid"].Value.ToLowerInvariant()
        $stage = $match.Groups["stage"].Value
        $relativePath = $match.Groups["path"].Value

        if ($stage -ne "0") {
            Write-Host "Unmerged git index entry; scan aborted."
            exit 1
        }
        if ($mode -ne "100644" -and $mode -ne "100755") {
            Write-Host "Unsupported git index entry; scan aborted."
            exit 1
        }
        if ($objectId -match "\A0+\z") {
            Write-Host "Unmaterialized git index entry; scan aborted."
            exit 1
        }
        if (-not $seenPaths.Add($relativePath)) {
            Write-Host "Duplicate git index entry; scan aborted."
            exit 1
        }

        [void]$entries.Add([pscustomobject]@{
            Mode = $mode
            ObjectId = $objectId
            RelativePath = $relativePath
        })
    }

    # Porcelain v2 reports intent-to-add as a normal record whose working-tree status is A.
    # Parse only documented record shapes and account for the extra original-path record used
    # by rename/copy entries under -z.
    $intentToAddPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    for ($i = 0; $i -lt $statusRecords.Count; $i++) {
        $record = $statusRecords[$i]
        if ($record.StartsWith("1 ", [System.StringComparison]::Ordinal)) {
            $parts = @($record -split " ", 9)
            if ($parts.Count -ne 9 -or $parts[1].Length -ne 2) {
                Write-Host "Malformed git status entry; scan aborted."
                exit 1
            }
            if ($parts[1][1] -eq "A") {
                [void]$intentToAddPaths.Add($parts[8])
            }
            continue
        }
        if ($record.StartsWith("2 ", [System.StringComparison]::Ordinal)) {
            $parts = @($record -split " ", 10)
            if ($parts.Count -ne 10 -or $parts[1].Length -ne 2 -or ($i + 1) -ge $statusRecords.Count) {
                Write-Host "Malformed git status entry; scan aborted."
                exit 1
            }
            $i++
            continue
        }
        if ($record.StartsWith("u ", [System.StringComparison]::Ordinal)) {
            Write-Host "Unmerged git index entry; scan aborted."
            exit 1
        }

        Write-Host "Unsupported git status entry; scan aborted."
        exit 1
    }

    return [pscustomobject]@{
        Entries = @($entries)
        IntentToAddPaths = $intentToAddPaths
        IndexSnapshot = $indexResult.Bytes
        StatusSnapshot = $statusResult.Bytes
    }
}

function Test-PathChainSafe {
    param([System.IO.FileInfo]$TargetFile)

    # An index entry may be regular while a local path is replaced by a symlink/junction.
    # Walk back to the already-resolved scan root and refuse every reparse-point hop.
    $current = [System.IO.FileSystemInfo]$TargetFile
    while ($null -ne $current) {
        if (($current.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            return $false
        }
        if ($current.FullName.Equals($rootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
        if ($current -is [System.IO.FileInfo]) {
            $current = $current.Directory
        }
        else {
            $current = $current.Parent
        }
    }
    return $false
}

# Enumerate scan targets. In git mode, bind each tracked path to its staged blob while also
# retaining the worktree file. This covers both publication views without scanning untracked
# private work areas.
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
        $indexState = Get-GitIndexState
        $script:InitialGitIndexSnapshot = $indexState.IndexSnapshot
        $script:InitialGitStatusSnapshot = $indexState.StatusSnapshot
        $result = foreach ($entry in $indexState.Entries) {
            if ($indexState.IntentToAddPaths.Contains($entry.RelativePath)) {
                Write-Host "Intent-to-add git index entry; scan aborted."
                exit 1
            }

            try {
                $full = [System.IO.Path]::GetFullPath((Join-Path $rootPath $entry.RelativePath))
            }
            catch {
                Write-Host "A git-tracked scan target has an invalid path; scan aborted."
                exit 1
            }
            $rootPrefix = $rootPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            $comparison = [System.StringComparison]::Ordinal
            if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
                $comparison = [System.StringComparison]::OrdinalIgnoreCase
            }
            if (-not $full.StartsWith($rootPrefix, $comparison)) {
                Write-Host "A git-tracked scan target escapes the scan root; scan aborted."
                exit 1
            }

            $targetFile = $null
            try {
                if (Test-Path -LiteralPath $full -PathType Leaf) {
                    $targetFile = Get-Item -LiteralPath $full -ErrorAction Stop
                }
            }
            catch {
                $targetFile = $null
            }
            if ($null -eq $targetFile) {
                Write-Host "A git-tracked scan target is missing; scan aborted."
                exit 1
            }
            $pathChainIsSafe = $false
            try {
                $pathChainIsSafe = Test-PathChainSafe -TargetFile $targetFile
            }
            catch {
                $pathChainIsSafe = $false
            }
            if (-not $pathChainIsSafe) {
                Write-Host "A git-tracked scan target uses an unsafe path; scan aborted."
                exit 1
            }

            [pscustomobject]@{
                RelativePath = $entry.RelativePath
                FullName = $targetFile.FullName
                Extension = [System.IO.Path]::GetExtension($entry.RelativePath)
                IndexObjectId = $entry.ObjectId
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
    } | ForEach-Object {
        [pscustomobject]@{
            RelativePath = Get-PathRelativeToScanRoot -TargetPath $_.FullName
            FullName = $_.FullName
            Extension = $_.Extension
            IndexObjectId = $null
        }
    })
}

$script:ScanMode = "working-tree"
$script:InitialGitIndexSnapshot = $null
$script:InitialGitStatusSnapshot = $null
$script:WorktreeSnapshots = [System.Collections.Generic.List[object]]::new()
$candidateFiles = Get-ScanTargetFiles

function Test-EmailAllowlisted {
    param([string]$Value)
    foreach ($allow in $emailAllowlistPatterns) {
        if ([regex]::IsMatch($Value, $allow, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            return $true
        }
    }
    return $false
}

$script:hits = [System.Collections.Generic.List[object]]::new()
$script:hitKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

function Add-ScanHit {
    param(
        [string]$RelativeFile,
        [int]$LineNumber,
        [string]$Marker
    )

    # The same marker may exist in identical index/worktree views. Keep one stable report row.
    $key = $RelativeFile + [char]0 + $LineNumber + [char]0 + $Marker
    if ($script:hitKeys.Add($key)) {
        [void]$script:hits.Add([pscustomobject]@{
            File = $RelativeFile
            Line = $LineNumber
            Marker = $Marker
        })
    }
}

function Scan-ByteView {
    param(
        [string]$RelativeFile,
        [byte[]]$Bytes
    )

    if (Test-BytesLookBinary -Bytes $Bytes) { return }

    # Decode every publication view strictly. Invalid text must not silently disappear from
    # the scan merely because one PowerShell host replaced undecodable bytes differently.
    $text = ConvertFrom-StrictUtf8Bytes -Bytes $Bytes -FailureMessage "A text-like scan target is not valid UTF-8; scan aborted."
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) {
        $text = $text.Substring(1)
    }
    $lines = @($text -split "\r\n|\n|\r")
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        foreach ($entry in $patterns) {
            foreach ($match in [regex]::Matches($line, $entry.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                # Email allowlist: documentation placeholders are not flagged.
                if ($entry.Name -eq $emailMarkerName -and (Test-EmailAllowlisted -Value $match.Value)) {
                    continue
                }
                Add-ScanHit -RelativeFile $RelativeFile -LineNumber $lineNumber -Marker $entry.Name
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
                Add-ScanHit -RelativeFile $RelativeFile -LineNumber $lineNumber -Marker "Non-allowlisted GitHub repository URL: $repositorySlug"
            }
        }
    }
}

foreach ($file in $candidateFiles) {
    if ($binaryExtensions.Contains($file.Extension)) { continue }

    try {
        $worktreeBytes = [System.IO.File]::ReadAllBytes($file.FullName)
    }
    catch {
        Write-Host "Failed to read a tracked working-tree target; scan aborted."
        exit 1
    }

    if ($null -ne $file.IndexObjectId) {
        [void]$script:WorktreeSnapshots.Add([pscustomobject]@{
            FullName = $file.FullName
            Bytes = $worktreeBytes
        })
    }

    if ($null -ne $file.IndexObjectId) {
        $blobResult = Invoke-GitRaw -Arguments ("cat-file blob " + $file.IndexObjectId)
        if (-not $blobResult.Success) {
            Write-Host "Failed to read a staged git blob; scan aborted."
            exit 1
        }

        Scan-ByteView -RelativeFile $file.RelativePath -Bytes $blobResult.Bytes
        if (-not (Test-ByteArraysEqual -Left $blobResult.Bytes -Right $worktreeBytes)) {
            Scan-ByteView -RelativeFile $file.RelativePath -Bytes $worktreeBytes
        }
    }
    else {
        Scan-ByteView -RelativeFile $file.RelativePath -Bytes $worktreeBytes
    }
}

# A success result is valid only for the index/status snapshot that was actually scanned.
# Re-read both NUL-safe records to catch a concurrent stage operation before reporting green.
if ($script:ScanMode -eq "git-tracked" -and $script:hits.Count -eq 0) {
    $finalIndex = Invoke-GitRaw -Arguments "ls-files --stage -z"
    $finalStatus = Invoke-GitRaw -Arguments "status --porcelain=v2 -z --untracked-files=no"
    if (-not $finalIndex.Success -or -not $finalStatus.Success) {
        Write-Host "Failed to revalidate git scan state; scan aborted."
        exit 1
    }
    if (-not (Test-ByteArraysEqual -Left $script:InitialGitIndexSnapshot -Right $finalIndex.Bytes) -or
        -not (Test-ByteArraysEqual -Left $script:InitialGitStatusSnapshot -Right $finalStatus.Bytes)) {
        Write-Host "Git scan state changed during inspection; scan aborted."
        exit 1
    }

    # Porcelain status does not hash dirty worktree content. Re-read each scanned target and
    # compare exact bytes so a concurrent edit cannot retain the same XY status and go green.
    foreach ($snapshot in $script:WorktreeSnapshots) {
        $finalFile = $null
        try {
            if (Test-Path -LiteralPath $snapshot.FullName -PathType Leaf) {
                $finalFile = Get-Item -LiteralPath $snapshot.FullName -ErrorAction Stop
            }
        }
        catch {
            $finalFile = $null
        }
        if ($null -eq $finalFile) {
            Write-Host "A tracked working-tree target changed during inspection; scan aborted."
            exit 1
        }

        $finalPathIsSafe = $false
        try {
            $finalPathIsSafe = Test-PathChainSafe -TargetFile $finalFile
            $finalWorktreeBytes = [System.IO.File]::ReadAllBytes($finalFile.FullName)
        }
        catch {
            $finalPathIsSafe = $false
            $finalWorktreeBytes = [byte[]]@()
        }
        if (-not $finalPathIsSafe -or
            -not (Test-ByteArraysEqual -Left $snapshot.Bytes -Right $finalWorktreeBytes)) {
            Write-Host "A tracked working-tree target changed during inspection; scan aborted."
            exit 1
        }
    }

    # Recheck Git after the worktree pass as well. This catches an index-only update that
    # lands while exact working-tree bytes are being revalidated.
    $postWorktreeIndex = Invoke-GitRaw -Arguments "ls-files --stage -z"
    $postWorktreeStatus = Invoke-GitRaw -Arguments "status --porcelain=v2 -z --untracked-files=no"
    if (-not $postWorktreeIndex.Success -or -not $postWorktreeStatus.Success) {
        Write-Host "Failed to revalidate git scan state; scan aborted."
        exit 1
    }
    if (-not (Test-ByteArraysEqual -Left $script:InitialGitIndexSnapshot -Right $postWorktreeIndex.Bytes) -or
        -not (Test-ByteArraysEqual -Left $script:InitialGitStatusSnapshot -Right $postWorktreeStatus.Bytes)) {
        Write-Host "Git scan state changed during inspection; scan aborted."
        exit 1
    }
}

Write-Host "Scan mode: $($script:ScanMode) (git-tracked = staged index plus tracked working-tree files)."

if ($script:hits.Count -gt 0) {
    $script:hits | Sort-Object File, Line, Marker | Format-Table -AutoSize File, Line, Marker
    # Under ErrorActionPreference=Stop, Write-Error would become terminating and never
    # reach `exit 1`; report via Write-Host and exit explicitly for a stable exit code.
    Write-Host "Potential private or secret markers found. Review and remove or explicitly justify each hit before publishing."
    exit 1
}

Write-Host "No private or secret markers found."
