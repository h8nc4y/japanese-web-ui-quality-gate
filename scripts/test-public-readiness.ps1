param(
    [string]$Path = "."
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath $Path).Path
$failures = [System.Collections.Generic.List[string]]::new()
$unsupportedChecklistStructureError = "Unsupported checklist Markdown structure; use top-level headings and checklist items."
$expectedCheckAllCommands = @(
    "pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-public-readiness.ps1",
    "pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-scan-private-markers.ps1",
    "pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-private-markers.ps1"
)
$expectedReadmeCheckAllHeading = "## Validation"
$expectedAgentsCheckAllHeading = '## §7. 検証 ＝ `check:all` の定義と合格基準'
$expectedAgentsLiveStateHeading = "## §3. 現況の取得契約"
$expectedAgentsBacklogHeading = "## §5. タスク選定の指針（バックログが空のときの動き方）"
$expectedAgentsBacklogOpening = "着手時の live 実測で未完了バックログが空なら、スコープを膨らませず、本リポジトリの価値（移植性・公開安全・検証の正直さ）を高める方向で **小さく確実な改善** を自分で選びます。"
$expectedAgentsLiveStateBodyLines = @(
    '> Git / GitHub の現況は変動するため、このファイルへスナップショットを固定しない。**食い違いがあれば「着手時の live 実測 > このファイル > 他の文書」の順で実測を正とする。**',
    '- default branch の current SHA、local / remote branch の一覧、open issue / open PR、doing、tag、GitHub Release、CI の結果、TODO / FIXME の有無は、いずれも時点依存のためここへ現在値を書かない。',
    '- 着手時に `git status --short`、`git log --oneline -5`、`git remote -v`、`git worktree list --porcelain`、`git stash list`、`git branch --all`、`git ls-remote origin HEAD`、`git ls-remote --heads origin`、`git tag --list`、`git ls-remote --tags origin`、`gh pr list`、`gh issue list`、`gh run list`、`gh release list` を再実測する。列挙した各 worktree でも `git status --short` を確認し、`TASKS_BACKLOG.md` の doing と `rg -n ''TODO|FIXME''` の結果も確認する。remote 同期が必要な場合は、既存 WIP を確認・保全してから安全に更新する。',
    '- 完了済みタスクと過去の検証証跡は `TASKS_BACKLOG.md` / `HANDOFF.md` に履歴として残すが、現在も同じ状態だとはみなさない。',
    '- 変動しない運用規約は各節に置く。ビルド/検証コマンドは §7、owner gate は §6 を正本とする。'
)
$expectedValidationTimeoutMinutes = "10"
$expectedCheckoutUses = "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1"
$expectedCheckoutPersistCredentials = "false"
$expectedWorkflowTopLevelContractLines = @(
    "name: Validation",
    "on:",
    "  pull_request:",
    "  push:",
    "    branches:",
    "      - main",
    "permissions:",
    "  contents: read",
    "jobs:"
)
$expectedWorkflowSteps = @(
    [ordered]@{ Name = "Check out repository"; Uses = $expectedCheckoutUses; Shell = $null; Run = $null },
    [ordered]@{ Name = "Run public readiness checks"; Uses = $null; Shell = "pwsh"; Run = "./scripts/test-public-readiness.ps1" },
    [ordered]@{ Name = "Run private marker scanner tests"; Uses = $null; Shell = "pwsh"; Run = "./scripts/test-scan-private-markers.ps1" },
    [ordered]@{ Name = "Run private marker scan"; Uses = $null; Shell = "pwsh"; Run = "./scripts/scan-private-markers.ps1" }
)
$expectedSkillName = "japanese-web-ui-quality-gate"
$expectedSkillDescription = "Use this as a pass/fail quality gate (not a generation guide) before shipping or reviewing Japanese web UI - pages, apps, React/Next.js, forms, dashboards, admin tools - when the task needs Japanese-first copy review, Japanese text rendering/layout checks, Japanese form input handling (postal code, phone, furigana), accessibility essentials, or responsive/rendered browser verification. Do not use this for generating visual design from scratch, building a design system, or producing a WCAG/JIS conformance certification."
$expectedSkillAxisHeadings = @(
    "1. UI Language",
    "2. Japanese Text Rendering",
    "3. Japanese Form Input",
    "4. Accessibility Essentials",
    "5. Rendered Verification",
    "6. Honest Reporting",
    "7. Stop Conditions"
)

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

    # PS 5.1 の既定 ANSI 読みで、日本語を含む公開文書の判定が runtime 間でずれないよう UTF-8 を固定する。
    $content = Get-Content -LiteralPath $file -Raw -Encoding UTF8
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

    # 禁止表現の検査も同じ decoding 契約へ揃え、文字コード差による見逃しを防ぐ。
    $content = Get-Content -LiteralPath $file -Raw -Encoding UTF8
    if ([regex]::IsMatch($content, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        Add-Failure "$RelativePath contains disallowed content: $Description"
    }
}

function Get-VisibleMarkdownH2SectionBodies {
    param(
        [string]$Content,
        [string]$ExpectedHeading
    )

    $sectionBodies = [System.Collections.Generic.List[string]]::new()
    $currentSection = $null
    $inComment = $false
    $inHtmlBlock = $false
    $inFence = $false
    $fenceCharacter = [char]0
    $fenceLength = 0

    foreach ($rawLine in @($Content -split '\r?\n')) {
        $line = $rawLine

        # fenced code 内の見出しやsnapshot例は、実際の運用契約として扱わない。
        if ($inFence) {
            $closePattern = '^[ ]{0,3}' + [regex]::Escape([string]$fenceCharacter) + '{' + $fenceLength + ',}[ \t]*$'
            if ([regex]::IsMatch($line, $closePattern)) { $inFence = $false }
            continue
        }

        # HTML comment 内のdecoyを除き、同じ行でcomment後に戻るvisible textは保持する。
        if ($inComment -or $line.Contains("<!--")) {
            $visibleLine = [System.Text.StringBuilder]::new()
            $cursor = 0
            while ($cursor -lt $line.Length) {
                if ($inComment) {
                    $commentEnd = $line.IndexOf("-->", $cursor, [System.StringComparison]::Ordinal)
                    if ($commentEnd -lt 0) { $cursor = $line.Length; break }
                    $inComment = $false
                    $cursor = $commentEnd + 3
                    continue
                }
                $commentStart = $line.IndexOf("<!--", $cursor, [System.StringComparison]::Ordinal)
                if ($commentStart -lt 0) {
                    [void]$visibleLine.Append($line.Substring($cursor))
                    break
                }
                [void]$visibleLine.Append($line.Substring($cursor, $commentStart - $cursor))
                $inComment = $true
                $cursor = $commentStart + 4
            }
            $line = $visibleLine.ToString()
        }

        if ($inHtmlBlock) {
            if ([string]::IsNullOrWhiteSpace($line)) { $inHtmlBlock = $false }
            continue
        }
        # raw HTML block風の範囲もvisible Markdown契約から除外する。
        if ([regex]::IsMatch($line, '^[ ]{0,3}<(?:/?[A-Za-z]|![A-Z]|!\[|\?)')) {
            $inHtmlBlock = $true
            continue
        }

        $fenceOpen = [regex]::Match($line, '^[ ]{0,3}(?<fence>`{3,}|~{3,}).*$')
        if ($fenceOpen.Success) {
            $fenceToken = $fenceOpen.Groups["fence"].Value
            $inFence = $true
            $fenceCharacter = $fenceToken[0]
            $fenceLength = $fenceToken.Length
            continue
        }

        # 次のvisible H2でsectionを閉じ、同名sectionが複数ならすべて返してfail closedにする。
        if ([regex]::IsMatch($line, '^##(?:[ \t]+|$)')) {
            if ($null -ne $currentSection) {
                [void]$sectionBodies.Add(($currentSection -join "`n"))
                $currentSection = $null
            }
            if ($line -ceq $ExpectedHeading) {
                $currentSection = [System.Collections.Generic.List[string]]::new()
            }
            continue
        }

        if ($null -ne $currentSection) { [void]$currentSection.Add($line) }
    }

    if ($null -ne $currentSection) { [void]$sectionBodies.Add(($currentSection -join "`n")) }
    return $sectionBodies.ToArray()
}

function Get-AgentsLiveStateContractFailures {
    param([string]$Content)

    $sections = @(Get-VisibleMarkdownH2SectionBodies $Content $expectedAgentsLiveStateHeading)
    if ($sections.Count -ne 1) {
        return "AGENTS.md does not contain exactly one visible canonical section 3 live-state contract."
    }

    $body = $sections[0]
    # blank lineとthematic breakだけを正規化し、visibleな契約行は順序・余分な行を含めてexactに固定する。
    $visibleContractLines = @($body -split '\r?\n' | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_) -and $_ -cne '---'
    })
    if (($visibleContractLines -join "`n") -cne ($expectedAgentsLiveStateBodyLines -join "`n")) {
        "AGENTS.md section 3 does not match the exact live-state contract."
    }

    # current version/SHA/count/branch/release/CI断定をsection内だけで拒否し、履歴節の正当な証跡は妨げない。
    $pointInTimePatterns = @(
        '(?i)\bv\d+\.\d+\.\d+\b',
        '(?i)\b[0-9a-f]{7,40}\b',
        '(?im)^(?!.*現在値を書かない).*(?:open issue|open PR|doing).*\b\d+\s*件.*$',
        '(?im)^.*(?:branch|ブランチ).*(?:最新|のみ).*$' ,
        '(?im)^.*(?:CI|検証).*(?:緑|success).*$' ,
        '(?im)^\s*-\s*(?:open issue|open PR|doing(?: タスク)?|tag|GitHub Release|リリース|release)(?:\s|:|：).*$'
    )
    foreach ($pattern in $pointInTimePatterns) {
        if ([regex]::IsMatch($body, $pattern)) {
            "AGENTS.md section 3 contains a point-in-time snapshot claim."
        }
    }
}

function Assert-AgentsLiveStateContractParser {
    $canonical = (@("# Example", "", $expectedAgentsLiveStateHeading, "") +
        $expectedAgentsLiveStateBodyLines + @("", "---", "", "## §4. Next")) -join "`n"
    # double-quoted stringではbacktickがescapeになるため、fence token自体はsingle-quoted literalで保持する。
    $fence3 = '```'
    $fence4 = '````'
    $cases = @(
        @{ Label = "canonical"; Content = $canonical; ExpectedFailure = $null },
        @{ Label = "missing heading"; Content = $canonical.Replace($expectedAgentsLiveStateHeading, "## §3. Other"); ExpectedFailure = "exactly one visible" },
        @{ Label = "duplicate heading"; Content = "$canonical`n`n$canonical"; ExpectedFailure = "exactly one visible" },
        @{ Label = "contract moved outside section"; Content = $canonical.Replace($expectedAgentsLiveStateHeading, "## §4. Moved") + "`n`n$expectedAgentsLiveStateHeading`n`n---"; ExpectedFailure = "does not match the exact live-state contract" },
        @{ Label = "fenced heading decoy"; Content = "${fence4}markdown`n$canonical`n${fence4}"; ExpectedFailure = "exactly one visible" },
        @{ Label = "point-in-time counts"; Content = $canonical.Replace("`n---", "`n- open issue / open PR: 0 件。doing: 0 件。`n---"); ExpectedFailure = "point-in-time snapshot claim" },
        @{ Label = "point-in-time version"; Content = $canonical.Replace("`n---", "`n- current version: v9.9.9。`n---"); ExpectedFailure = "point-in-time snapshot claim" },
        @{ Label = "point-in-time SHA"; Content = $canonical.Replace("`n---", "`n- current SHA: deadbeef。`n---"); ExpectedFailure = "point-in-time snapshot claim" },
        @{ Label = "point-in-time branch"; Content = $canonical.Replace("`n---", "`n- remote branch は main のみ。`n---"); ExpectedFailure = "point-in-time snapshot claim" },
        @{ Label = "point-in-time CI"; Content = $canonical.Replace("`n---", "`n- ローカル検証と CI は success / 緑。`n---"); ExpectedFailure = "point-in-time snapshot claim" },
        @{ Label = "point-in-time release"; Content = $canonical.Replace("`n---", "`n- リリース: stable（タグ済み）。`n---"); ExpectedFailure = "point-in-time snapshot claim" },
        @{ Label = "point-in-time empty items"; Content = $canonical.Replace("`n---", "`n- open issue / open PR: なし。`n---"); ExpectedFailure = "point-in-time snapshot claim" },
        @{ Label = "point-in-time empty doing"; Content = $canonical.Replace("`n---", "`n- doing: なし。`n---"); ExpectedFailure = "point-in-time snapshot claim" },
        @{ Label = "point-in-time tag"; Content = $canonical.Replace("`n---", "`n- tag: latest。`n---"); ExpectedFailure = "point-in-time snapshot claim" },
        @{ Label = "point-in-time GitHub Release"; Content = $canonical.Replace("`n---", "`n- GitHub Release: stable。`n---"); ExpectedFailure = "point-in-time snapshot claim" },
        @{ Label = "comment decoy ignored"; Content = $canonical.Replace("`n---", "`n<!-- - open issue / open PR: 0 件。 -->`n---"); ExpectedFailure = $null },
        @{ Label = "fence decoy ignored"; Content = $canonical.Replace("`n---", "`n${fence3}text`n- CI は緑。`n${fence3}`n---"); ExpectedFailure = $null }
    )

    foreach ($case in $cases) {
        $caseFailures = @(Get-AgentsLiveStateContractFailures $case.Content)
        if ($null -eq $case.ExpectedFailure) {
            if ($caseFailures.Count -ne 0) {
                Add-Failure "Internal live-state contract case '$($case.Label)' failed unexpectedly."
            }
            continue
        }
        if ($caseFailures.Count -eq 0 -or
            -not ($caseFailures | Where-Object { $_.Contains($case.ExpectedFailure) })) {
            Add-Failure "Internal live-state contract case '$($case.Label)' did not fail closed."
        }
    }
}

function Assert-AgentsLiveStateContract {
    $file = Get-RepoFile "AGENTS.md"
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        Add-Failure "Cannot check missing file: AGENTS.md"
        return
    }
    $content = Get-Content -LiteralPath $file -Raw -Encoding UTF8
    @(Get-AgentsLiveStateContractFailures $content) | ForEach-Object { Add-Failure $_ }
}

function Get-AgentsBacklogGuidanceFailures {
    param([string]$Content)

    $sections = @(Get-VisibleMarkdownH2SectionBodies $Content $expectedAgentsBacklogHeading)
    if ($sections.Count -ne 1) {
        return "AGENTS.md does not contain exactly one visible canonical section 5 backlog guidance."
    }

    $body = $sections[0]
    $visibleLines = @($body -split '\r?\n' | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_) -and $_ -cne '---'
    })
    if ($visibleLines.Count -eq 0 -or $visibleLines[0] -cne $expectedAgentsBacklogOpening) {
        "AGENTS.md section 5 does not start with the evergreen backlog guidance."
    }
    if ($body.Contains("v0.1.0 後でバックログは空です")) {
        "AGENTS.md section 5 contains stale release-specific backlog guidance."
    }
}

function Assert-AgentsBacklogGuidanceParser {
    $canonical = @("# Example", "", $expectedAgentsBacklogHeading, "", $expectedAgentsBacklogOpening, "", "## §6. Gate") -join "`n"
    $cases = @(
        @{ Label = "canonical"; Content = $canonical; ExpectedFailure = $null },
        @{ Label = "missing heading"; Content = $canonical.Replace($expectedAgentsBacklogHeading, "## §5. Other"); ExpectedFailure = "exactly one visible" },
        @{ Label = "duplicate heading"; Content = "$canonical`n`n$canonical"; ExpectedFailure = "exactly one visible" },
        @{ Label = "opening moved after next H2"; Content = "$expectedAgentsBacklogHeading`n`n## §6. Gate`n`n$expectedAgentsBacklogOpening"; ExpectedFailure = "does not start with the evergreen" },
        @{ Label = "stale release opening"; Content = $canonical.Replace($expectedAgentsBacklogOpening, "v0.1.0 後でバックログは空です。"); ExpectedFailure = "stale release-specific" }
    )

    foreach ($case in $cases) {
        $caseFailures = @(Get-AgentsBacklogGuidanceFailures $case.Content)
        if ($null -eq $case.ExpectedFailure) {
            if ($caseFailures.Count -ne 0) {
                Add-Failure "Internal backlog guidance case '$($case.Label)' failed unexpectedly."
            }
            continue
        }
        if ($caseFailures.Count -eq 0 -or
            -not ($caseFailures | Where-Object { $_.Contains($case.ExpectedFailure) })) {
            Add-Failure "Internal backlog guidance case '$($case.Label)' did not fail closed."
        }
    }
}

function Assert-AgentsBacklogGuidance {
    $file = Get-RepoFile "AGENTS.md"
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        Add-Failure "Cannot check missing file: AGENTS.md"
        return
    }
    $content = Get-Content -LiteralPath $file -Raw -Encoding UTF8
    @(Get-AgentsBacklogGuidanceFailures $content) | ForEach-Object { Add-Failure $_ }
}

function Get-VisibleNumberedH2Headings {
    param([string]$Content)

    $headings = [System.Collections.Generic.List[string]]::new()
    $inComment = $false
    $inHtmlCommentBlock = $false
    $inFence = $false
    $fenceCharacter = [char]0
    $fenceLength = 0

    foreach ($rawLine in @($Content -split '\r?\n')) {
        $line = $rawLine

        # code fence内の見出し風テキストは、公開されるaxis構造へ数えない。
        if ($inFence) {
            $closePattern = '^[ ]{0,3}' + [regex]::Escape([string]$fenceCharacter) + '{' + $fenceLength + ',}[ \t]*$'
            if ([regex]::IsMatch($line, $closePattern)) { $inFence = $false }
            continue
        }

        # 行頭commentはCommonMark Type 2 blockとして扱い、終端markerを含む行全体を除外する。
        # suffixをinline Markdownへ戻すと偽axisを数えるため、inline comment stateと分離する。
        if ($inHtmlCommentBlock) {
            if ($line.Contains("-->")) { $inHtmlCommentBlock = $false }
            continue
        }
        if ([regex]::IsMatch($line, '^[ ]{0,3}<!--')) {
            if (-not $line.Contains("-->")) { $inHtmlCommentBlock = $true }
            continue
        }

        # 行途中commentが改行をまたぐ場合、closing suffixを新しい行頭Markdownへ
        # 昇格させず固定sentinelへ倒す。終端行も全体を除外する。
        if ($inComment) {
            if ($line.Contains("-->")) { $inComment = $false }
            continue
        }

        # 単一行inline commentだけは除去し、同じ行に残るvisible textを評価する。
        if ($line.Contains("<!--")) {
            $visibleLine = [System.Text.StringBuilder]::new()
            $cursor = 0
            while ($cursor -lt $line.Length) {
                $commentStart = $line.IndexOf("<!--", $cursor, [System.StringComparison]::Ordinal)
                if ($commentStart -lt 0) {
                    [void]$visibleLine.Append($line.Substring($cursor))
                    break
                }
                [void]$visibleLine.Append($line.Substring($cursor, $commentStart - $cursor))
                $commentEnd = $line.IndexOf("-->", $commentStart + 4, [System.StringComparison]::Ordinal)
                if ($commentEnd -lt 0) {
                    [void]$headings.Add('__UNSUPPORTED_MULTILINE_INLINE_COMMENT__')
                    $inComment = $true
                    $cursor = $line.Length
                    break
                }
                $cursor = $commentEnd + 3
            }
            $line = $visibleLine.ToString()
        }

        # 軸の正本はcanonical Markdownだけを許可する。comment以外のraw HTMLは
        # CommonMark 7種を不完全に再実装せず、固定sentinelで必ずaxis不一致へ倒す。
        if ([regex]::IsMatch($line, '^[ ]{0,3}<(?:\?|!\[CDATA\[|![A-Za-z]|/?[A-Za-z])')) {
            [void]$headings.Add('__UNSUPPORTED_RAW_HTML__')
            continue
        }

        $fenceOpen = [regex]::Match($line, '^[ ]{0,3}(?<fence>`{3,}|~{3,})(?<suffix>.*)$')
        if ($fenceOpen.Success) {
            $fenceToken = $fenceOpen.Groups["fence"].Value
            $fenceSuffix = $fenceOpen.Groups["suffix"].Value
            # CommonMarkではbacktick fenceのinfo stringにbacktickを含められない。
            # 不正openerをfence扱いすると、後続の追加axisをdecoyとして隠せるため拒否側へ流す。
            $isInvalidBacktickFenceOpener = (
                ($fenceToken[0] -eq [char]'`') -and
                $fenceSuffix.Contains('`')
            )
            if (-not $isInvalidBacktickFenceOpener) {
                $inFence = $true
                $fenceCharacter = $fenceToken[0]
                $fenceLength = $fenceToken.Length
                continue
            }
        }

        # 中核契約はcopy-paste可能なcanonical H2だけを受理し、別表記は意図的な更新として扱う。
        $headingMatch = [regex]::Match($line, '^## (?<heading>[1-9][0-9]*\. [^\r\n]+)$')
        if ($headingMatch.Success) {
            [void]$headings.Add($headingMatch.Groups["heading"].Value)
        }
    }

    return $headings.ToArray()
}

function Get-SkillContractFailures {
    param(
        [string]$SkillContent,
        [string]$ChecklistContent
    )

    # 外部YAML parserへ依存せず、公開契約で採用している単行scalarだけを限定的に解釈する。
    $skillLines = @($SkillContent -split '\r?\n')
    $frontmatterEnd = -1
    if ($skillLines.Count -eq 0 -or $skillLines[0] -cne '---') {
        "SKILL.md frontmatter must start on the first line."
    }
    else {
        for ($index = 1; $index -lt $skillLines.Count; $index++) {
            if ($skillLines[$index] -ceq '---') {
                $frontmatterEnd = $index
                break
            }
        }
        if ($frontmatterEnd -lt 0) {
            "SKILL.md frontmatter is not terminated."
        }
    }

    if ($frontmatterEnd -ge 0) {
        $nameValues = [System.Collections.Generic.List[string]]::new()
        $descriptionValues = [System.Collections.Generic.List[string]]::new()
        $frontmatterHasUnsupportedLine = $false

        for ($index = 1; $index -lt $frontmatterEnd; $index++) {
            $metadataMatch = [regex]::Match($skillLines[$index], '^(?<key>[A-Za-z][A-Za-z0-9_-]*): (?<value>.+)$')
            if (-not $metadataMatch.Success) {
                $frontmatterHasUnsupportedLine = $true
                continue
            }
            switch -CaseSensitive ($metadataMatch.Groups["key"].Value) {
                "name" { [void]$nameValues.Add($metadataMatch.Groups["value"].Value) }
                "description" { [void]$descriptionValues.Add($metadataMatch.Groups["value"].Value) }
                default { $frontmatterHasUnsupportedLine = $true }
            }
        }

        if ($frontmatterHasUnsupportedLine) {
            "SKILL.md frontmatter contains an unsupported or malformed line."
        }
        if ($nameValues.Count -ne 1 -or $nameValues[0] -cne $expectedSkillName) {
            "SKILL.md name must appear exactly once and match the canonical skill name."
        }
        if ($descriptionValues.Count -ne 1) {
            "SKILL.md description must appear exactly once as a single-line scalar."
        }
        else {
            $description = $descriptionValues[0]
            # 必須語の単純包含では否定語だけを反転した意味driftを見逃す。
            # triggerと除外を一体のcanonical scalarとして固定し、極性も含めて比較する。
            if ($description -cne $expectedSkillDescription) {
                "SKILL.md description must exactly match the canonical trigger and exclusion contract."
            }
        }

        # closing delimiter直後に別のfrontmatter blockが続く形は、metadataの正本を二重化するため拒否する。
        $bodyStart = $frontmatterEnd + 1
        while ($bodyStart -lt $skillLines.Count -and [string]::IsNullOrWhiteSpace($skillLines[$bodyStart])) {
            $bodyStart++
        }
        if ($bodyStart -lt $skillLines.Count -and $skillLines[$bodyStart] -ceq '---') {
            "SKILL.md must not contain duplicate frontmatter blocks."
        }
    }

    # product要件に属する7軸は固定し、SKILLと詳細checklistを同じ順序で同期させる。
    $skillHeadings = @(Get-VisibleNumberedH2Headings $SkillContent)
    $checklistHeadings = @(Get-VisibleNumberedH2Headings $ChecklistContent)
    $expectedHeadingsText = $expectedSkillAxisHeadings -join "`n"
    if (($skillHeadings -join "`n") -cne $expectedHeadingsText) {
        "SKILL.md axis headings do not match the canonical ordered seven-axis contract."
    }
    if (($checklistHeadings -join "`n") -cne $expectedHeadingsText) {
        "references/checklist.md axis headings do not match the canonical ordered seven-axis contract."
    }
}

function Assert-SkillContractParser {
    $frontmatter = @(
        "---",
        "name: $expectedSkillName",
        "description: $expectedSkillDescription",
        "---"
    ) -join "`n"
    $skillAxes = @($expectedSkillAxisHeadings | ForEach-Object { "## $_`n`n- Contract item." }) -join "`n`n"
    $checklistAxes = @($expectedSkillAxisHeadings | ForEach-Object { "## $_`n`n- [ ] Checklist item." }) -join "`n`n"
    $canonicalSkill = "$frontmatter`n`n# Japanese Web UI Quality Gate`n`n$skillAxes"
    $canonicalChecklist = "# Detailed Checklist`n`n$checklistAxes"
    $fence = '```'
    $invalidBacktickFence = $fence + "markdown" + [char]'`'
    $sameLineProcessingBlock = "<?done?>"
    $sameLineRawBlock = "<script></script>"
    $typeSevenInsideParagraph = "Text`n<span>"
    $blockCommentWithClosingSuffix = "<!--`n## 8. Decoy`n-->## 8. Decoy"
    $multilineInlineCommentAxis = "Text <!--`n-->## 1. UI Language"

    $reorderedSkill = $canonicalSkill.Replace(
        "## 1. UI Language",
        "## TEMP. Axis"
    ).Replace(
        "## 2. Japanese Text Rendering",
        "## 1. UI Language"
    ).Replace(
        "## TEMP. Axis",
        "## 2. Japanese Text Rendering"
    )

    $cases = @(
        @{ Label = "canonical"; Skill = $canonicalSkill; Checklist = $canonicalChecklist; ExpectedFailure = $null },
        @{ Label = "canonical CRLF"; Skill = $canonicalSkill.Replace("`n", "`r`n"); Checklist = $canonicalChecklist.Replace("`n", "`r`n"); ExpectedFailure = $null },
        @{ Label = "missing frontmatter"; Skill = $canonicalSkill.Substring($canonicalSkill.IndexOf("`n") + 1); Checklist = $canonicalChecklist; ExpectedFailure = "frontmatter" },
        @{ Label = "unterminated frontmatter"; Skill = $canonicalSkill.Replace("description: $expectedSkillDescription`n---", "description: $expectedSkillDescription"); Checklist = $canonicalChecklist; ExpectedFailure = "frontmatter" },
        @{ Label = "duplicate frontmatter"; Skill = "$frontmatter`n`n$canonicalSkill"; Checklist = $canonicalChecklist; ExpectedFailure = "frontmatter" },
        @{ Label = "missing name"; Skill = $canonicalSkill.Replace("name: $expectedSkillName`n", ""); Checklist = $canonicalChecklist; ExpectedFailure = "name" },
        @{ Label = "duplicate name"; Skill = $canonicalSkill.Replace("name: $expectedSkillName", "name: $expectedSkillName`nname: $expectedSkillName"); Checklist = $canonicalChecklist; ExpectedFailure = "name" },
        @{ Label = "missing description"; Skill = $canonicalSkill.Replace("description: $expectedSkillDescription`n", ""); Checklist = $canonicalChecklist; ExpectedFailure = "description" },
        @{ Label = "duplicate description"; Skill = $canonicalSkill.Replace("description: $expectedSkillDescription", "description: $expectedSkillDescription`ndescription: $expectedSkillDescription"); Checklist = $canonicalChecklist; ExpectedFailure = "description" },
        @{ Label = "unknown frontmatter field"; Skill = $canonicalSkill.Replace("name: $expectedSkillName", "name: $expectedSkillName`nversion: 1"); Checklist = $canonicalChecklist; ExpectedFailure = "frontmatter" },
        @{ Label = "multiline description"; Skill = $canonicalSkill.Replace("description: $expectedSkillDescription", "description: >`n  $expectedSkillDescription"); Checklist = $canonicalChecklist; ExpectedFailure = "frontmatter" },
        @{ Label = "wrong name"; Skill = $canonicalSkill.Replace("name: $expectedSkillName", "name: another-skill"); Checklist = $canonicalChecklist; ExpectedFailure = "name" },
        @{ Label = "missing pass fail purpose"; Skill = $canonicalSkill.Replace("pass/fail quality gate", "review guide"); Checklist = $canonicalChecklist; ExpectedFailure = "description" },
        @{ Label = "missing Japanese UI target"; Skill = $canonicalSkill.Replace("Japanese web UI", "web content"); Checklist = $canonicalChecklist; ExpectedFailure = "description" },
        @{ Label = "missing generation exclusion"; Skill = $canonicalSkill.Replace("not a generation guide", "review helper"); Checklist = $canonicalChecklist; ExpectedFailure = "description" },
        @{ Label = "missing visual design exclusion"; Skill = $canonicalSkill.Replace("generating visual design from scratch", "generating examples"); Checklist = $canonicalChecklist; ExpectedFailure = "description" },
        @{ Label = "missing design system exclusion"; Skill = $canonicalSkill.Replace("building a design system", "building a sample"); Checklist = $canonicalChecklist; ExpectedFailure = "description" },
        @{ Label = "missing conformance exclusion"; Skill = $canonicalSkill.Replace("WCAG/JIS conformance certification", "a report"); Checklist = $canonicalChecklist; ExpectedFailure = "description" },
        @{ Label = "reversed exclusion polarity"; Skill = $canonicalSkill.Replace("Do not use this for", "Use this for"); Checklist = $canonicalChecklist; ExpectedFailure = "description" },
        @{ Label = "missing axis"; Skill = $canonicalSkill.Replace("## 7. Stop Conditions", "### 7. Stop Conditions"); Checklist = $canonicalChecklist; ExpectedFailure = "axis" },
        @{ Label = "renamed axis"; Skill = $canonicalSkill.Replace("## 3. Japanese Form Input", "## 3. Form Input"); Checklist = $canonicalChecklist; ExpectedFailure = "axis" },
        @{ Label = "reordered axes"; Skill = $reorderedSkill; Checklist = $canonicalChecklist; ExpectedFailure = "axis" },
        @{ Label = "extra axis"; Skill = "$canonicalSkill`n`n## 8. Extra Axis`n`n- Extra."; Checklist = $canonicalChecklist; ExpectedFailure = "axis" },
        @{ Label = "checklist drift"; Skill = $canonicalSkill; Checklist = $canonicalChecklist.Replace("## 4. Accessibility Essentials", "## 4. Accessibility"); ExpectedFailure = "axis" },
        @{ Label = "paired axis drift"; Skill = $canonicalSkill.Replace("## 6. Honest Reporting", "## 6. Reporting"); Checklist = $canonicalChecklist.Replace("## 6. Honest Reporting", "## 6. Reporting"); ExpectedFailure = "axis" },
        @{ Label = "fenced axis decoy ignored"; Skill = "$canonicalSkill`n`n${fence}markdown`n## 8. Decoy`n${fence}"; Checklist = $canonicalChecklist; ExpectedFailure = $null },
        @{ Label = "comment axis decoy ignored"; Skill = "$canonicalSkill`n`n<!--`n## 8. Decoy`n-->"; Checklist = $canonicalChecklist; ExpectedFailure = $null },
        @{ Label = "invalid backtick fence cannot hide skill axis"; Skill = "$canonicalSkill`n`n$invalidBacktickFence`n## 8. Extra Axis`n${fence}"; Checklist = $canonicalChecklist; ExpectedFailure = "axis" },
        @{ Label = "same-line processing block cannot hide skill axis"; Skill = "$canonicalSkill`n`n$sameLineProcessingBlock`n## 8. Extra Axis"; Checklist = $canonicalChecklist; ExpectedFailure = "axis" },
        @{ Label = "same-line raw block cannot hide skill axis"; Skill = "$canonicalSkill`n`n$sameLineRawBlock`n## 8. Extra Axis"; Checklist = $canonicalChecklist; ExpectedFailure = "axis" },
        @{ Label = "type seven tag in paragraph cannot hide skill axis"; Skill = "$canonicalSkill`n`n$typeSevenInsideParagraph`n## 8. Extra Axis"; Checklist = $canonicalChecklist; ExpectedFailure = "axis" },
        @{ Label = "block comment closing suffix ignored for skill"; Skill = "$canonicalSkill`n`n$blockCommentWithClosingSuffix"; Checklist = $canonicalChecklist; ExpectedFailure = $null },
        @{ Label = "multiline inline comment cannot synthesize skill axis"; Skill = $canonicalSkill.Replace("## 1. UI Language", $multilineInlineCommentAxis); Checklist = $canonicalChecklist; ExpectedFailure = "axis" },
        @{ Label = "checklist fenced decoy ignored"; Skill = $canonicalSkill; Checklist = "$canonicalChecklist`n`n${fence}markdown`n## 8. Decoy`n${fence}"; ExpectedFailure = $null },
        @{ Label = "checklist comment decoy ignored"; Skill = $canonicalSkill; Checklist = "$canonicalChecklist`n`n<!--`n## 8. Decoy`n-->"; ExpectedFailure = $null },
        @{ Label = "invalid backtick fence cannot hide checklist axis"; Skill = $canonicalSkill; Checklist = "$canonicalChecklist`n`n$invalidBacktickFence`n## 8. Extra Axis`n${fence}"; ExpectedFailure = "axis" },
        @{ Label = "same-line processing block cannot hide checklist axis"; Skill = $canonicalSkill; Checklist = "$canonicalChecklist`n`n$sameLineProcessingBlock`n## 8. Extra Axis"; ExpectedFailure = "axis" },
        @{ Label = "same-line raw block cannot hide checklist axis"; Skill = $canonicalSkill; Checklist = "$canonicalChecklist`n`n$sameLineRawBlock`n## 8. Extra Axis"; ExpectedFailure = "axis" },
        @{ Label = "type seven tag in paragraph cannot hide checklist axis"; Skill = $canonicalSkill; Checklist = "$canonicalChecklist`n`n$typeSevenInsideParagraph`n## 8. Extra Axis"; ExpectedFailure = "axis" },
        @{ Label = "block comment closing suffix ignored for checklist"; Skill = $canonicalSkill; Checklist = "$canonicalChecklist`n`n$blockCommentWithClosingSuffix"; ExpectedFailure = $null },
        @{ Label = "multiline inline comment cannot synthesize checklist axis"; Skill = $canonicalSkill; Checklist = $canonicalChecklist.Replace("## 1. UI Language", $multilineInlineCommentAxis); ExpectedFailure = "axis" }
    )

    foreach ($case in $cases) {
        $caseFailures = @(Get-SkillContractFailures $case.Skill $case.Checklist)
        if ($null -eq $case.ExpectedFailure) {
            if ($caseFailures.Count -ne 0) {
                Add-Failure "Internal SKILL contract case '$($case.Label)' failed unexpectedly."
            }
            continue
        }
        if ($caseFailures.Count -eq 0 -or
            -not ($caseFailures | Where-Object { $_.Contains($case.ExpectedFailure) })) {
            Add-Failure "Internal SKILL contract case '$($case.Label)' did not fail closed."
        }
    }
}

function Assert-SkillContract {
    $skillFile = Get-RepoFile "SKILL.md"
    $checklistFile = Get-RepoFile "references/checklist.md"
    foreach ($requiredFile in @($skillFile, $checklistFile)) {
        if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
            Add-Failure "Cannot compare missing SKILL contract file."
            return
        }
    }

    $skillContent = Get-Content -LiteralPath $skillFile -Raw -Encoding UTF8
    $checklistContent = Get-Content -LiteralPath $checklistFile -Raw -Encoding UTF8
    @(Get-SkillContractFailures $skillContent $checklistContent) | ForEach-Object { Add-Failure $_ }
}

function Get-LeadingIndentColumns {
    param([string]$Line)

    # CommonMarkのtab stopは4列単位。blockの所属判定でも文字数ではなく
    # 表示列を使い、space+TAB境界で親list itemを誤って抜けないようにする。
    $column = 0
    foreach ($character in $Line.ToCharArray()) {
        if ($character -eq [char]' ') {
            $column++
            continue
        }
        if ($character -eq [char]9) {
            $column += 4 - ($column % 4)
            continue
        }
        break
    }

    return $column
}

function Get-ChecklistItemLineInfo {
    param([string]$Line)

    # 現行contractはhyphen list itemだけを対象とし、marker自体のindentは
    # CommonMarkで許容されるASCII space 0–3へ限定する。
    $markerMatch = [regex]::Match($Line, '^(?<leading> {0,3})-')
    if (-not $markerMatch.Success) {
        return $null
    }

    # marker後のspace/tabを4-column tab stopで列幅へ変換する。
    # 1–4列なら通常content、5列以上ならindented codeなので項目へ数えない。
    $characterIndex = $markerMatch.Length
    $contentStartColumn = $characterIndex
    $column = $contentStartColumn
    $hasIndent = $false
    while ($characterIndex -lt $Line.Length) {
        $character = $Line[$characterIndex]
        if ($character -eq [char]' ') {
            $column++
            $characterIndex++
            $hasIndent = $true
            continue
        }
        if ($character -eq [char]9) {
            $column += 4 - ($column % 4)
            $characterIndex++
            $hasIndent = $true
            continue
        }
        break
    }

    $indentColumns = $column - $contentStartColumn
    if ((-not $hasIndent) -or ($indentColumns -lt 1) -or ($indentColumns -gt 4)) {
        return $null
    }

    $content = $Line.Substring($characterIndex)
    if (-not [regex]::IsMatch($content, '^\[ \][ \t]+\S')) {
        return $null
    }

    return [pscustomobject]@{
        MarkerIndentColumns = $markerMatch.Groups['leading'].Value.Length
        ContentColumn = $column
        PostMarkerIndentColumns = $indentColumns
    }
}

function Get-ChecklistSummary {
    param([string]$Content)

    # 軸数と項目数を同じMarkdown状態機械から導出し、fence解釈の
    # 片側だけが変わってREADME件数比較にdriftが生じるのを防ぐ。
    $axisHeadingPattern = '^[ ]{0,3}##[ \t]+[0-9]+\.[ \t]+\S'
    $sectionBoundaryPattern = '^[ ]{0,3}#{1,2}(?:[ \t]+|$)'
    $atxHeadingPattern = '^[ ]{0,3}#{1,6}(?:[ \t]+|$)'
    $fencePattern = '^[ ]{0,3}(?<marker>`{3,}|~{3,})(?<suffix>.*)$'
    $rawHtmlTagPattern = '^[ ]{0,3}<(?:script|pre|style|textarea)(?:[ \t]|>|$)'
    $rawHtmlEndPattern = '</(?:pre|script|style|textarea)>'
    $blankTerminatedHtmlTagPattern = '^[ ]{0,3}</?(?:address|article|aside|base|basefont|blockquote|body|caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|nav|noframes|ol|optgroup|option|p|param|search|section|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul)(?:[ \t]|/?>|$)'
    $completeHtmlOpenTagPattern = '^[ ]{0,3}<[A-Za-z][A-Za-z0-9-]*(?:[ \t]+[A-Za-z_:][A-Za-z0-9_.:-]*(?:[ \t]*=[ \t]*(?:[^ \t"''=<>`]+|''[^'']*''|"[^"]*"))?)*[ \t]*/?>[ \t]*$'
    $completeHtmlClosingTagPattern = '^[ ]{0,3}</[A-Za-z][A-Za-z0-9-]*[ \t]*>[ \t]*$'
    $ambiguousIndentedFenceOrHtmlPattern = '^(?: {4,}| {0,3}\t)(?:(?:`{3,}|~{3,})|<(?:!--|\?|!\[CDATA\[|![A-Za-z]|/?[A-Za-z]))'
    $indentedCodePattern = '^(?: {4,}| {0,3}\t)'
    $thematicBreakPattern = '^[ ]{0,3}(?:(?:\*[ \t]*){3,}|(?:_[ \t]*){3,}|(?:-[ \t]*){3,})$'
    $thematicOrSetextPattern = '^[ ]{0,3}(?:(?:\*[ \t]*){3,}|(?:_[ \t]*){3,}|(?:-[ \t]*){1,}|(?:=[ \t]*){1,})$'
    $setextUnderlinePattern = '^[ ]{0,3}(?<marker>=+|-+)[ \t]*$'
    $genericContainerMarkerPattern = '^[ ]{0,3}(?:>|[-+*](?:[ \t]+|$)|[0-9]{1,9}[.)](?:[ \t]+|$))'
    $linkReferenceDefinitionPrefixPattern = '^[ ]{0,3}\[(?:[^\[\]]|\\.)+\][ \t]*:'
    # CommonMark のリンクラベルは最大999文字なので、安全と証明できる単行サブセットも同じ上限に揃える。
    $completeSingleLineLinkReferencePattern = '^[ ]{0,3}\[[A-Za-z0-9][A-Za-z0-9 _.-]{0,998}\][ \t]*:[ \t]+[A-Za-z0-9._~:/?#@!$&*+,;=%-]+[ \t]*$'
    $axisCount = 0
    $itemCount = 0
    $insideNumberedAxis = $false
    $insideParagraph = $false
    $paragraphIsProvenTopLevel = $false
    $paragraphIsWithinChecklistItem = $false
    $hasSetextCandidateParagraph = $false
    $hasAmbiguousSetextCandidate = $false
    $activeTopLevelChecklistContentColumn = $null
    $unsafeLeafBlockBeforeTypeSeven = $false
    $activeFenceCharacter = $null
    $activeFenceLength = 0
    $activeHtmlEndPattern = $null
    $activeHtmlEndsOnBlankLine = $false
    $parseErrors = [System.Collections.Generic.List[string]]::new()

    foreach ($line in ($Content -split '\r?\n')) {
        # 開いているfence内ではHTMLらしい行もただのコードなので、
        # fence終端だけを先に評価し、その他のMarkdown判定へ流さない。
        $fenceMatch = [regex]::Match($line, $fencePattern)
        if ($null -ne $activeFenceCharacter) {
            if ($fenceMatch.Success) {
                $marker = $fenceMatch.Groups['marker'].Value
                $suffix = $fenceMatch.Groups['suffix'].Value
                if (
                    ($marker[0] -eq $activeFenceCharacter) -and
                    ($marker.Length -ge $activeFenceLength) -and
                    [regex]::IsMatch($suffix, '^[ \t]*$')
                ) {
                    $activeFenceCharacter = $null
                    $activeFenceLength = 0
                }
            }
            continue
        }

        # CommonMarkのraw HTML block内に書かれた疑似見出し・疑似項目は、
        # 描画されるchecklist構造ではない。終端markerまたは空行まで除外する。
        if ($null -ne $activeHtmlEndPattern) {
            if ([regex]::IsMatch($line, $activeHtmlEndPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                $activeHtmlEndPattern = $null
            }
            continue
        }
        if ($activeHtmlEndsOnBlankLine) {
            if ([regex]::IsMatch($line, '^[ \t]*$')) {
                $activeHtmlEndsOnBlankLine = $false
            }
            continue
        }

        # 番号付き軸内で許可するcontainer markerは、canonicalな未チェック
        # checklist itemだけ。その他のlist/blockquoteはleaf種類を推測せずfail closedする。
        $lineIndentColumns = Get-LeadingIndentColumns -Line $line
        $checklistItemInfo = Get-ChecklistItemLineInfo -Line $line
        $isChecklistItem = $null -ne $checklistItemInfo
        $isThematicBreakLine = [regex]::IsMatch($line, $thematicBreakPattern)
        $lineIsIndentedWithinActiveChecklist = (
            ($null -ne $activeTopLevelChecklistContentColumn) -and
            ($lineIndentColumns -ge $activeTopLevelChecklistContentColumn)
        )
        $hasUnsupportedContainer = (
            $insideNumberedAxis -and
            [regex]::IsMatch($line, $genericContainerMarkerPattern) -and
            (-not $isChecklistItem) -and
            # `- - -` / `* * *` はlist marker風でもCommonMark thematic break。
            # 通常の非canonical containerだけをfail closed対象に残す。
            (-not $isThematicBreakLine)
        )

        # 4列以上またはTAB開始のfence/HTMLはindented codeとの境界を簡易parserで
        # 確定しない。active axis内だけ固定エラーへ倒し、軸外の正当なblockは妨げない。
        if (
            (
                $insideNumberedAxis -and
                [regex]::IsMatch($line, $ambiguousIndentedFenceOrHtmlPattern)
            ) -or
            $hasUnsupportedContainer
        ) {
            if (-not $parseErrors.Contains($unsupportedChecklistStructureError)) {
                [void]$parseErrors.Add($unsupportedChecklistStructureError)
            }
            $unsafeLeafBlockBeforeTypeSeven = $false
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }

        # CommonMarkのblank lineはASCII space/tabだけで構成される。
        # NBSPなどUnicode空白をblock終端へ昇格させず、paragraph状態だけを明示的に戻す。
        if ([regex]::IsMatch($line, '^[ \t]*$')) {
            $unsafeLeafBlockBeforeTypeSeven = $false
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }

        # コード例に含まれる見出し風・項目風テキストは、実際の
        # checklist構造ではないため、fenceを閉じるまで両方から除外する。
        if ($fenceMatch.Success) {
            $marker = $fenceMatch.Groups['marker'].Value
            $suffix = $fenceMatch.Groups['suffix'].Value

            # CommonMarkではbacktickを含むinfo stringはopenerにならないため、
            # fence状態へ入れず、後段のparagraph処理へ流す。
            $isInvalidBacktickFenceOpener = (
                ($marker[0] -eq [char]'`') -and
                $suffix.Contains('`')
            )
            if (-not $isInvalidBacktickFenceOpener) {
                $activeFenceCharacter = $marker[0]
                $activeFenceLength = $marker.Length
                if (-not $lineIsIndentedWithinActiveChecklist) {
                    $activeTopLevelChecklistContentColumn = $null
                }
                $unsafeLeafBlockBeforeTypeSeven = $false
                $hasSetextCandidateParagraph = $false
                $hasAmbiguousSetextCandidate = $false
                $insideParagraph = $false
                $paragraphIsProvenTopLevel = $false
                $paragraphIsWithinChecklistItem = $false
                continue
            }
        }

        # 終端markerを持つHTML blockは、同一行で閉じる場合もその行全体を
        # Markdown構造から除外する。tag名は限定済みcaptureから組み立てる。
        $htmlEndPattern = $null
        if ([regex]::IsMatch($line, '^[ ]{0,3}<!--')) {
            $htmlEndPattern = '-->'
        }
        elseif ([regex]::IsMatch($line, '^[ ]{0,3}<\?')) {
            $htmlEndPattern = '\?>'
        }
        elseif ([regex]::IsMatch($line, '^[ ]{0,3}<!\[CDATA\[')) {
            $htmlEndPattern = '\]\]>'
        }
        # Type 4 declarationの先頭は大小を問わないASCII letterであり、`<!doctype`もblock開始になる。
        elseif ([regex]::IsMatch($line, '^[ ]{0,3}<![A-Za-z]')) {
            $htmlEndPattern = '>'
        }
        elseif (
            [regex]::IsMatch(
                $line,
                $rawHtmlTagPattern,
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            )
        ) {
            # Type 1の終端はopener名と対応付けず、4種いずれかのexact closing tagで成立する。
            $htmlEndPattern = $rawHtmlEndPattern
        }
        if ($null -ne $htmlEndPattern) {
            if (-not [regex]::IsMatch($line, $htmlEndPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                $activeHtmlEndPattern = $htmlEndPattern
            }
            if (-not $lineIsIndentedWithinActiveChecklist) {
                $activeTopLevelChecklistContentColumn = $null
            }
            $unsafeLeafBlockBeforeTypeSeven = $false
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }

        # Type 6のblock tagはparagraphを中断でき、空行までraw HTMLとして扱う。
        if ([regex]::IsMatch(
            $line,
            $blankTerminatedHtmlTagPattern,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )) {
            $activeHtmlEndsOnBlankLine = $true
            if (-not $lineIsIndentedWithinActiveChecklist) {
                $activeTopLevelChecklistContentColumn = $null
            }
            $unsafeLeafBlockBeforeTypeSeven = $false
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }

        # Type 7は属性文法を満たすcomplete tagだけを認識し、quoted value内の
        # angle bracketを許容する一方、進行中paragraphを中断させない。
        $isCompleteHtmlTag = (
            [regex]::IsMatch($line, $completeHtmlOpenTagPattern) -or
            [regex]::IsMatch($line, $completeHtmlClosingTagPattern)
        )
        if ($insideNumberedAxis -and $unsafeLeafBlockBeforeTypeSeven -and $isCompleteHtmlTag) {
            if (-not $parseErrors.Contains($unsupportedChecklistStructureError)) {
                [void]$parseErrors.Add($unsupportedChecklistStructureError)
            }
            $unsafeLeafBlockBeforeTypeSeven = $false
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }
        if ((-not $insideParagraph) -and $isCompleteHtmlTag) {
            $activeHtmlEndsOnBlankLine = $true
            if (-not $lineIsIndentedWithinActiveChecklist) {
                $activeTopLevelChecklistContentColumn = $null
            }
            $unsafeLeafBlockBeforeTypeSeven = $false
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }

        # ATX headingはactive checklist itemのcontent indent以上ならnested block。
        # top-levelと確定したH2だけを軸開始・終了へ使い、nested headingを誤算入しない。
        $isAxisHeading = [regex]::IsMatch($line, $axisHeadingPattern)
        $isSectionBoundary = [regex]::IsMatch($line, $sectionBoundaryPattern)
        $isAtxHeading = [regex]::IsMatch($line, $atxHeadingPattern)
        if ($isAtxHeading) {
            if (-not $lineIsIndentedWithinActiveChecklist) {
                $activeTopLevelChecklistContentColumn = $null
                if ($isAxisHeading) {
                    $axisCount++
                    $insideNumberedAxis = $true
                }
                elseif ($isSectionBoundary) {
                    $insideNumberedAxis = $false
                }
            }
            $unsafeLeafBlockBeforeTypeSeven = $false
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }

        # paragraph textに続くSetext underlineはH1/H2 section boundaryであり、
        # 直前の番号付き軸scopeを終了する。単独のthematic breakとは区別する。
        $setextMatch = [regex]::Match($line, $setextUnderlinePattern)
        if ($hasAmbiguousSetextCandidate -and $setextMatch.Success) {
            if (-not $parseErrors.Contains($unsupportedChecklistStructureError)) {
                [void]$parseErrors.Add($unsupportedChecklistStructureError)
            }
            $unsafeLeafBlockBeforeTypeSeven = $false
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }
        if (
            $paragraphIsWithinChecklistItem -and
            $setextMatch.Success -and
            $lineIsIndentedWithinActiveChecklist
        ) {
            # content indentを満たすunderlineはlist item内のSetext heading。
            # top-level axis scopeは閉じず、親list contextだけを保持する。
            $unsafeLeafBlockBeforeTypeSeven = $false
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }
        if ($hasSetextCandidateParagraph -and $setextMatch.Success) {
            $insideNumberedAxis = $false
            $activeTopLevelChecklistContentColumn = $null
            # top-level headingでscopeは確実に閉じる。後続Type 7は軸外blockとして通常処理する。
            $unsafeLeafBlockBeforeTypeSeven = $false
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }

        # 現行checklistの公開契約であるhyphen形式の未チェック項目だけを
        # 数える。親itemのcontent indent以上にある同形項目はnestedなので除外する。
        if ($isChecklistItem) {
            $isNestedChecklistItem = (
                ($null -ne $activeTopLevelChecklistContentColumn) -and
                ($checklistItemInfo.MarkerIndentColumns -ge $activeTopLevelChecklistContentColumn)
            )
            if ($insideNumberedAxis -and (-not $isNestedChecklistItem)) {
                $itemCount++
            }
            if (-not $isNestedChecklistItem) {
                $activeTopLevelChecklistContentColumn = $checklistItemInfo.ContentColumn
            }
            $unsafeLeafBlockBeforeTypeSeven = $false
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $true
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $true
            continue
        }

        # indented code、thematic break、Setext underlineの直後は、Type 7が
        # paragraph内か新規blockかを簡易状態だけで安全に決められない。
        # TABは次の4-column stopへ進むため、先行space 0–3もindentへ含める。
        $isIndentedCodeLine = [regex]::IsMatch($line, $indentedCodePattern)
        $isThematicOrSetextLine = [regex]::IsMatch($line, $thematicOrSetextPattern)
        if ($isIndentedCodeLine -or $isThematicOrSetextLine) {
            if (
                ($null -ne $activeTopLevelChecklistContentColumn) -and
                (-not $lineIsIndentedWithinActiveChecklist)
            ) {
                $activeTopLevelChecklistContentColumn = $null
            }
            $unsafeLeafBlockBeforeTypeSeven = $true
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $false
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }

        # paragraph外の単行link referenceは構造が確定するため受理する。
        # destinationが次行へ続く形だけを、active axis内で固定エラーへ倒す。
        $isLinkReferenceDefinition = [regex]::IsMatch($line, $linkReferenceDefinitionPrefixPattern)
        if ($isLinkReferenceDefinition -and (-not $insideParagraph)) {
            $isCompleteSingleLineLinkReference = [regex]::IsMatch(
                $line,
                $completeSingleLineLinkReferencePattern
            )
            if (
                $insideNumberedAxis -and
                (-not $isCompleteSingleLineLinkReference) -and
                (-not $parseErrors.Contains($unsupportedChecklistStructureError))
            ) {
                [void]$parseErrors.Add($unsupportedChecklistStructureError)
            }
            if (-not $lineIsIndentedWithinActiveChecklist) {
                $activeTopLevelChecklistContentColumn = $null
            }
            $unsafeLeafBlockBeforeTypeSeven = (
                $insideNumberedAxis -and
                (-not $isCompleteSingleLineLinkReference)
            )
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = (
                $insideNumberedAxis -and
                (-not $isCompleteSingleLineLinkReference)
            )
            $insideParagraph = $false
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $false
            continue
        }

        # 残る非blank行はparagraphを開始・継続する。親itemのcontent indentを
        # 満たす行はlist内と確定し、indentなしの継続だけを曖昧なlazy扱いにする。
        $continuesChecklistParagraphLazily = (
            $insideParagraph -and
            $paragraphIsWithinChecklistItem -and
            (-not $lineIsIndentedWithinActiveChecklist)
        )
        $belongsToActiveChecklistParagraph = (
            ($null -ne $activeTopLevelChecklistContentColumn) -and
            (
                $lineIsIndentedWithinActiveChecklist -or
                ($insideParagraph -and $paragraphIsWithinChecklistItem)
            )
        )
        if ($belongsToActiveChecklistParagraph) {
            $paragraphIsProvenTopLevel = $false
            $paragraphIsWithinChecklistItem = $true
            $hasSetextCandidateParagraph = $false
            $hasAmbiguousSetextCandidate = $continuesChecklistParagraphLazily
        }
        else {
            $activeTopLevelChecklistContentColumn = $null
            $paragraphIsProvenTopLevel = $true
            $paragraphIsWithinChecklistItem = $false
            $hasSetextCandidateParagraph = $true
            $hasAmbiguousSetextCandidate = $false
        }
        $unsafeLeafBlockBeforeTypeSeven = $false
        $insideParagraph = $true
    }

    # unsupported構造を検出した結果に部分的な件数を残さず、呼び出し側が
    # 誤って利用しても成功値として扱えないzero-count contractへ固定する。
    if ($parseErrors.Count -gt 0) {
        $axisCount = 0
        $itemCount = 0
    }

    return [pscustomobject]@{
        AxisCount = $axisCount
        ItemCount = $itemCount
        Errors = $parseErrors.ToArray()
    }
}

function Assert-ChecklistAxisParser {
    # fence種別の誤り同士が期待値を相殺しないよう、構造契約を独立fixtureで固定する。
    $cases = @(
        [pscustomobject]@{
            Label = 'axis-shape'
            ExpectedCount = 3
            Content = @(
                '# Synthetic checklist',
                '## 1. First Axis',
                '## Notes',
                '## 1) Parenthesis Style',
                '## １. Full-width Digit',
                '##　3. Full-width Space',
                '    ## 4. Indented Code Block',
                '  ## 2. Second Axis ###',
                '## 3. Third Axis'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'spaced-thematic-breaks'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- - -',
                '* * *',
                '## 2. Second Axis'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'backtick-fence'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '```markdown',
                '## 99. Backtick-fenced Decoy',
                '```',
                '## 2. Second Axis'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'tilde-fence'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '~~~text',
                '## 99. Tilde-fenced Decoy',
                '~~~~',
                '## 2. Second Axis'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'invalid-backtick-info'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '```bad`info',
                '## 2. Second Axis'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'html-comment'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '<!--',
                '## 99. Commented Decoy',
                '-->',
                '## 2. Second Axis'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'raw-html-marker-block'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '<script>',
                '## 99. Raw-script Decoy',
                '</script>',
                '## 2. Second Axis'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'raw-html-blank-block'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '<div>',
                '## 99. Raw-div Decoy',
                '',
                '## 2. Second Axis'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'unclosed-fence'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '```markdown',
                '## 99. Fenced Decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'nested-axis-heading-is-not-top-level'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '- [ ] Parent item',
                '  ## 99. Nested heading',
                '  - [ ] Nested item',
                '- [ ] Sibling item'
            ) -join "`n"
        }
    )

    foreach ($case in $cases) {
        $summary = Get-ChecklistSummary -Content $case.Content
        $parseErrors = @($summary.Errors)
        if ($parseErrors.Count -ne 0) {
            Add-Failure "Internal checklist axis parser case '$($case.Label)' unexpectedly returned an unsupported-structure error."
            continue
        }
        $actualCount = $summary.AxisCount
        if ($actualCount -ne $case.ExpectedCount) {
            Add-Failure "Internal checklist axis parser case '$($case.Label)' expected $($case.ExpectedCount) numbered axes but found $actualCount."
        }
    }
}

function Assert-ChecklistItemParser {
    # 除外漏れと正規項目の取りこぼしが同数で相殺されないよう、軸scope、
    # fence種別、HTML block、項目shapeを独立fixtureとして判定する。
    $cases = @(
        [pscustomobject]@{
            Label = 'axis-scope'
            ExpectedCount = 3
            Content = @(
                '# Synthetic checklist',
                '- [ ] Preamble decoy',
                '## 1. First Axis',
                '- [ ] First item',
                '### Subsection',
                '  - [ ] Second item',
                '## Notes',
                '- [ ] Supplemental decoy',
                '## 2. Second Axis',
                '   - [ ] Third item',
                '## 1) Not an axis',
                '- [ ] Invalid-axis decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'hyphen-thematic-break-with-spaces'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                '- - -',
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'asterisk-thematic-break-with-spaces'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                '* * *',
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'thematic-break-tabs-and-leading-indent'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                ([string]::Concat('   -', [char]9, '-', [char]9, '-')),
                ([string]::Concat('*', [char]9, '*', [char]9, '*')),
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'backtick-fence'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                '```markdown',
                '- [ ] Backtick-fenced decoy',
                '```',
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'tilde-fence'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                '~~~text',
                '- [ ] Tilde-fenced decoy',
                '~~~~',
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'invalid-backtick-info'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                '```bad`info',
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'html-comment'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                '<!--',
                '- [ ] Multiline-comment decoy',
                '-->',
                '<!-- - [ ] Single-line-comment decoy -->',
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'raw-html-marker-block'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                '<script>',
                '- [ ] Raw-script decoy',
                '</script>',
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'raw-html-blank-block'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                '<div>',
                '- [ ] Raw-div decoy',
                '',
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'type7-quoted-angle'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '<custom-element data-label="a > b">',
                '- [ ] Raw-custom-element decoy',
                '',
                '- [ ] Visible item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'type7-invalid-tag'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '<custom-element =bad>',
                '- [ ] Visible item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'type7-unquoted-attribute-tab'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                ([string]::Concat('<custom-element data-label=alpha', [char]9, '1bad>')),
                '- [ ] Visible item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'type7-paragraph-context'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                'Paragraph before an inline tag.',
                '<custom-element>',
                '- [ ] Visible item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'type7-canonical-checklist-lazy-paragraph-context'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                'lazy continuation',
                '<custom-element>',
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'type7-indented-checklist-paragraph-context'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                '  item paragraph continuation',
                '  <custom-element>',
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'type1-mismatched-end-tag'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '<script>',
                '- [ ] Raw-script decoy',
                '</pre>',
                '- [ ] Visible item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'type1-spaced-end-tag'
            ExpectedCount = 0
            Content = @(
                '## 1. First Axis',
                '<script>',
                '- [ ] First raw-script decoy',
                '</script >',
                '- [ ] Second raw-script decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'type4-uppercase-declaration'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '<!DOCTYPE html',
                '- [ ] Declaration decoy',
                '>',
                '- [ ] Visible item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'type4-lowercase-declaration'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '<!doctype html',
                '- [ ] Declaration decoy',
                'end >',
                '- [ ] Visible item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'fence-nbsp-close'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '- [ ] Visible item',
                '```markdown',
                '- [ ] First fenced decoy',
                ([string]::Concat('```', [char]0x00A0)),
                '- [ ] Second fenced decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'html-nbsp-blank'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '- [ ] Visible item',
                '<div>',
                '- [ ] First raw-div decoy',
                ([char]0x00A0).ToString(),
                '- [ ] Second raw-div decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'post-marker-one-to-four-column-indent'
            ExpectedCount = 4
            Content = @(
                '## 1. First Axis',
                '- [ ] Valid one-column item',
                '-  [ ] Valid two-column item',
                '-   [ ] Valid three-column item',
                '-    [ ] Valid four-column item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'post-marker-tab-stop-indent'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                ([string]::Concat('-', [char]9, '[ ] Valid tab-stop item'))
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'post-marker-leading-spaces-tab-boundary'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                ([string]::Concat('   -', [char]9, '[ ] Valid four-column tab-stop item'))
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'setext-h2-ends-axis-scope'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '- [ ] Visible item',
                '',
                'Supplemental section',
                '---',
                '- [ ] Outside-axis decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'blank-contained-setext-keeps-axis-scope'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] Parent item',
                '',
                '  list paragraph',
                '  ---',
                '- [ ] Sibling item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'nested-canonical-checklist-top-level-only'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] Parent item',
                '  - [ ] Nested item',
                '- [ ] Sibling item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'nested-heading-and-checkbox-top-level-only'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] Parent item',
                '  ## 99. Nested heading',
                '  - [ ] Nested item',
                '- [ ] Sibling item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'same-indent-top-level-checklist-items'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '  - [ ] First item',
                '  - [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'post-marker-padding-prevents-false-nesting'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '-  [ ] First item',
                '  - [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'single-line-link-reference-before-thematic-break'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '[ref]: /target',
                '---',
                '- [ ] Visible item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'maximum-length-single-line-link-reference-label'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                ([string]::Concat('[', (('a' * 999) -join ''), ']: /target')),
                '---',
                '- [ ] Visible item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'setext-heading-before-type7-outside-axis'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '- [ ] Visible item',
                '',
                'Supplemental section',
                '---',
                '<custom-element>',
                '- [ ] Outside-axis decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'outside-axis-three-space-fence'
            ExpectedCount = 1
            Content = @(
                '## Notes',
                '   ```markdown',
                '## 99. Fenced decoy',
                '- [ ] Fenced decoy',
                '   ```',
                '## 1. First Axis',
                '- [ ] Visible item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'thematic-break-keeps-axis-scope'
            ExpectedCount = 2
            Content = @(
                '## 1. First Axis',
                '- [ ] First item',
                '',
                '---',
                '- [ ] Second item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'item-shape'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '- [ ] Valid item',
                '    - [ ] Indented code block'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'unclosed-fence'
            ExpectedCount = 1
            Content = @(
                '## 1. First Axis',
                '- [ ] Visible item',
                '```markdown',
                '- [ ] Fenced decoy',
                '## 2. Fenced heading',
                '- [ ] Another fenced decoy'
            ) -join "`n"
        }
    )

    foreach ($case in $cases) {
        $summary = Get-ChecklistSummary -Content $case.Content
        $parseErrors = @($summary.Errors)
        if ($parseErrors.Count -ne 0) {
            Add-Failure "Internal checklist item parser case '$($case.Label)' unexpectedly returned an unsupported-structure error."
            continue
        }
        $actualCount = $summary.ItemCount
        if ($actualCount -ne $case.ExpectedCount) {
            Add-Failure "Internal checklist item parser case '$($case.Label)' expected $($case.ExpectedCount) axis items but found $actualCount."
        }
    }
}

function Assert-UnsupportedChecklistParser {
    # container幅とleaf block遷移を完全なCommonMark parserなしで推測せず、
    # canonical top-level契約外は同じ固定エラーへfail closedする。
    $cases = @(
        [pscustomobject]@{
            Label = 'tab-indented-fence'
            Content = @(
                '## 1. First Axis',
                ([string]::Concat([char]9, '```markdown')),
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'indented-code-before-type7'
            Content = @(
                '## 1. First Axis',
                '    indented code',
                '<custom-element>',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'indented-code-one-space-tab-before-type7'
            Content = @(
                '## 1. First Axis',
                ([string]::Concat(' ', [char]9, 'indented code')),
                '<custom-element>',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'indented-code-two-space-tab-before-type7'
            Content = @(
                '## 1. First Axis',
                ([string]::Concat('  ', [char]9, 'indented code')),
                '<custom-element>',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'indented-code-three-space-tab-before-type7'
            Content = @(
                '## 1. First Axis',
                ([string]::Concat('   ', [char]9, 'indented code')),
                '<custom-element>',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'thematic-break-before-type7'
            Content = @(
                '## 1. First Axis',
                '***',
                '<custom-element>',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'hyphen-thematic-break-too-short'
            Content = @(
                '## 1. First Axis',
                '- -',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'asterisk-thematic-break-trailing-content'
            Content = @(
                '## 1. First Axis',
                '* * * trailing content',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'list-container-unclosed-fence'
            Content = @(
                '## 1. First Axis',
                '- Container item',
                '  ```markdown',
                '  nested code',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'container-atx-heading-before-type7'
            Content = @(
                '## 1. First Axis',
                '- # Nested heading',
                '<custom-element>',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'blockquote-thematic-before-type7'
            Content = @(
                '## 1. First Axis',
                '> ---',
                '<custom-element>',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'container-indented-code-before-type7'
            Content = @(
                '## 1. First Axis',
                '-     indented code',
                '<custom-element>',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'container-lazy-continuation-before-type7'
            Content = @(
                '## 1. First Axis',
                '- Container paragraph',
                'lazy continuation',
                '<custom-element>',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'canonical-checklist-lazy-continuation-before-dash-underline'
            Content = @(
                '## 1. First Axis',
                '- [ ] Container paragraph',
                'lazy continuation',
                '---',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'canonical-checklist-lazy-continuation-before-equals-underline'
            Content = @(
                '## 1. First Axis',
                '- [ ] Container paragraph',
                'lazy continuation',
                '===',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'multiline-link-reference-before-setext'
            Content = @(
                '## 1. First Axis',
                '[reference]:',
                '  /relative-target',
                '---',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'overlong-single-line-link-reference-label'
            Content = @(
                '## 1. First Axis',
                ([string]::Concat('[', (('a' * 1000) -join ''), ']: /target')),
                '---',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'post-marker-five-space-code'
            Content = @(
                '## 1. First Axis',
                '-     [ ] Indented-code decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'post-marker-three-space-tab-code'
            Content = @(
                '## 1. First Axis',
                ([string]::Concat('-   ', [char]9, '[ ] Indented-code decoy'))
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'post-marker-two-tabs-code'
            Content = @(
                '## 1. First Axis',
                ([string]::Concat('-', [char]9, [char]9, '[ ] Indented-code decoy'))
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'noncanonical-checklist-markers'
            Content = @(
                '## 1. First Axis',
                '- [x] Checked item',
                '- [X] Uppercase checked item',
                '- [ ] ',
                '* [ ] Asterisk item',
                '+ [ ] Plus item',
                '- [  ] Extra bracket space',
                '- [ ]Missing separator'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'list-container-same-line-unclosed-fence'
            Content = @(
                '## 1. First Axis',
                '- ```markdown',
                '  - [ ] Nested decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'list-container-same-line-type6-html'
            Content = @(
                '## 1. First Axis',
                '- <div>',
                '  - [ ] Nested decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'blockquote-container-same-line-fence'
            Content = @(
                '## 1. First Axis',
                '> ```markdown',
                '> - [ ] Nested decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'blockquote-container-same-line-html'
            Content = @(
                '## 1. First Axis',
                '> <div>',
                '> - [ ] Nested decoy'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'list-container-type6-html'
            Content = @(
                '## 1. First Axis',
                '- Container item',
                '  <div>',
                '  nested HTML',
                '- [ ] Ambiguous item'
            ) -join "`n"
        },
        [pscustomobject]@{
            Label = 'list-container-type7-html'
            Content = @(
                '## 1. First Axis',
                '- Container item',
                '  <custom-element>',
                '  nested HTML',
                '- [ ] Ambiguous item'
            ) -join "`n"
        }
    )

    foreach ($case in $cases) {
        $summary = Get-ChecklistSummary -Content $case.Content
        $errors = @($summary.Errors)
        if (
            ($errors.Count -ne 1) -or
            ($errors[0] -ne $unsupportedChecklistStructureError) -or
            ($summary.AxisCount -ne 0) -or
            ($summary.ItemCount -ne 0)
        ) {
            Add-Failure "Internal checklist parser case '$($case.Label)' did not fail closed with the fixed unsupported-structure error and zero counts."
        }
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

    # Derive both counts from one structural parse so this test does not need fixed expected numbers.
    $checklistContent = Get-Content -LiteralPath $checklistFile -Raw -Encoding UTF8
    $checklistSummary = Get-ChecklistSummary -Content $checklistContent
    $parseErrors = @($checklistSummary.Errors)
    if ($parseErrors.Count -gt 0) {
        # parserが安全に扱えない構造では、README件数の一致を成功扱いにしない。
        $parseErrors | ForEach-Object { Add-Failure $_ }
        return
    }
    $checkCount = $checklistSummary.ItemCount
    $axisCount = $checklistSummary.AxisCount

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

function Test-VisibleMarkdownCheckAllContract {
    param(
        [string]$Content,
        [string]$ExpectedHeading
    )

    $headingCount = 0
    $matchingFenceCount = 0
    $firstTargetFenceIsCanonical = $false
    $targetFenceSeen = $false
    $insideTargetSection = $false
    $inComment = $false
    $inHtmlBlock = $false
    $inFence = $false
    $fenceCharacter = [char]0
    $fenceLength = 0
    $captureFence = $false
    $capturingFirstTargetFence = $false
    $fenceBody = [System.Collections.Generic.List[string]]::new()

    foreach ($line in @($Content -split '\r?\n')) {
        if ($inFence) {
            $closePattern = '^[ ]{0,3}' + [regex]::Escape([string]$fenceCharacter) + '{' + $fenceLength + ',}[ \t]*$'
            if ([regex]::IsMatch($line, $closePattern)) {
                $isCanonicalFence = $captureFence -and $line -ceq '```' -and
                    ($fenceBody -join "`n") -ceq ($expectedCheckAllCommands -join "`n")
                if ($isCanonicalFence) {
                    $matchingFenceCount++
                }
                if ($capturingFirstTargetFence) { $firstTargetFenceIsCanonical = $isCanonicalFence }
                $inFence = $false
                $captureFence = $false
                $capturingFirstTargetFence = $false
                continue
            }
            if ($captureFence) { [void]$fenceBody.Add($line) }
            continue
        }

        # fence外ではHTML commentを左から除き、inline/multiline decoyをvisible Markdownとして数えない。
        if ($inComment -or $line.Contains("<!--")) {
            $visibleLine = [System.Text.StringBuilder]::new()
            $cursor = 0
            while ($cursor -lt $line.Length) {
                if ($inComment) {
                    $commentEnd = $line.IndexOf("-->", $cursor, [System.StringComparison]::Ordinal)
                    if ($commentEnd -lt 0) { $cursor = $line.Length; break }
                    $inComment = $false
                    $cursor = $commentEnd + 3
                    continue
                }
                $commentStart = $line.IndexOf("<!--", $cursor, [System.StringComparison]::Ordinal)
                if ($commentStart -lt 0) {
                    [void]$visibleLine.Append($line.Substring($cursor))
                    break
                }
                [void]$visibleLine.Append($line.Substring($cursor, $commentStart - $cursor))
                $inComment = $true
                $cursor = $commentStart + 4
            }
            $line = $visibleLine.ToString()
        }
        if ($inHtmlBlock) {
            if ([string]::IsNullOrWhiteSpace($line)) { $inHtmlBlock = $false }
            continue
        }
        # Validation decoyを閉じる最小deny: raw HTML block風の開始から空行まではvisible Markdownとして数えない。
        if ([regex]::IsMatch($line, '^[ ]{0,3}<(?:/?[A-Za-z]|![A-Z]|!\[|\?)')) {
            $inHtmlBlock = $true
            continue
        }

        $fenceOpen = [regex]::Match($line, '^[ ]{0,3}(?<fence>`{3,}|~{3,}).*$')
        if ($fenceOpen.Success) {
            $fenceToken = $fenceOpen.Groups["fence"].Value
            $inFence = $true
            $fenceCharacter = $fenceToken[0]
            $fenceLength = $fenceToken.Length
            $isPowerShellLikeFence = $insideTargetSection -and
                [regex]::IsMatch($line, '^(?i:[ ]{0,3}`{3,}[ \t]*powershell[ \t]*)$')
            $captureFence = $insideTargetSection -and $line -ceq '```powershell'
            $capturingFirstTargetFence = $isPowerShellLikeFence -and -not $targetFenceSeen
            if ($isPowerShellLikeFence) { $targetFenceSeen = $true }
            $fenceBody.Clear()
            continue
        }

        if ([regex]::IsMatch($line, '^##(?:[ \t]+|$)')) {
            $insideTargetSection = $line -ceq $ExpectedHeading
            if ($insideTargetSection) { $headingCount++ }
        }
    }

    return $headingCount -eq 1 -and $matchingFenceCount -eq 1 -and $firstTargetFenceIsCanonical
}

function Test-ValidationWorkflowContract {
    param([string]$Content)

    $expectedStepNames = @($expectedWorkflowSteps | ForEach-Object { $_["Name"] })
    $stepNames = [System.Collections.Generic.List[string]]::new()
    $runs = @{}
    $shells = @{}
    $uses = @{}
    $jobsCount = 0
    $validateCount = 0
    $jobNameCount = 0
    $runsOnCount = 0
    $timeoutMinutesCount = 0
    $stepsCount = 0
    $runKeyCount = 0
    $checkoutWithCount = 0
    $persistCredentialsCount = 0
    $workflowTopLevelContractLines = [System.Collections.Generic.List[string]]::new()
    $workflowTopLevelContractComplete = $false
    $insideJobs = $false
    $currentJob = $null
    $currentStep = $null
    $insideCheckoutWith = $false
    $invalid = $false

    foreach ($line in @($Content -split '\r?\n')) {
        if ([string]::IsNullOrWhiteSpace($line) -or [regex]::IsMatch($line, '^[ ]*#')) { continue }
        $lineMatch = [regex]::Match($line, '^(?<indent> *)(?<text>.*)$')
        if (-not $lineMatch.Success -or $line.StartsWith("`t")) { $invalid = $true; continue }
        $indent = $lineMatch.Groups["indent"].Value.Length
        $text = $lineMatch.Groups["text"].Value

        # Capture the enabled events and read-only permission boundary before jobs.
        if (-not $workflowTopLevelContractComplete) {
            [void]$workflowTopLevelContractLines.Add($line)
            if ($indent -eq 0 -and $text -ceq "jobs:") {
                $workflowTopLevelContractComplete = $true
            }
        }

        # checkout の with 配下は直前の with: に属する10-space入力だけを受理する。
        if ($indent -le 8) { $insideCheckoutWith = $false }

        # workflow全体のrun keyを数え、対象step以外・block scalar・追加runをすべて拒否する。
        $runMatch = [regex]::Match($text, '^run:[ \t]+(?<value>.+)$')
        if ($runMatch.Success) {
            $runKeyCount++
            $runValue = $runMatch.Groups["value"].Value
            if ($currentJob -cne "validate" -or $indent -ne 8 -or $null -eq $currentStep -or
                $runs.ContainsKey($currentStep) -or [regex]::IsMatch($runValue, '^[|>]')) {
                $invalid = $true
            }
            else { $runs[$currentStep] = $runValue }
            continue
        }

        if ($indent -eq 0 -and [regex]::IsMatch($text, '^(?:"jobs"|''jobs''|jobs)[ \t]*:')) {
            $insideJobs = $text -ceq "jobs:"
            if ($insideJobs) { $jobsCount++ } else { $invalid = $true }
            $currentJob = $null
            $currentStep = $null
            $insideCheckoutWith = $false
            continue
        }
        if ($indent -eq 0) {
            if ($workflowTopLevelContractComplete) { $invalid = $true }
            $insideJobs = $false
            $currentJob = $null
            $currentStep = $null
            $insideCheckoutWith = $false
            continue
        }

        if (-not $insideJobs) { continue }
        if ($indent -eq 2 -and $text -match '^(?<job>[^:]+):$') {
            $currentJob = $Matches["job"]
            $currentStep = $null
            $insideCheckoutWith = $false
            if ($currentJob -ceq "validate") { $validateCount++ } else { $invalid = $true }
            continue
        }

        if ($currentJob -cne "validate") { continue }
        if ($indent -ge 4 -and $text -match '^(?:if|continue-on-error):') { $invalid = $true; continue }

        if ($indent -eq 4) {
            $currentStep = $null
            switch -CaseSensitive ($text) {
                "name: Public readiness and marker scan" { $jobNameCount++ }
                "runs-on: windows-latest" { $runsOnCount++ }
                "timeout-minutes: $expectedValidationTimeoutMinutes" { $timeoutMinutesCount++ }
                "steps:" { $stepsCount++ }
                default { $invalid = $true }
            }
            continue
        }

        if ($indent -eq 6 -and $text -match '^- name: (?<name>.+)$') {
            $currentStep = $Matches["name"]
            [void]$stepNames.Add($currentStep)
            if ($expectedStepNames -cnotcontains $currentStep) { $invalid = $true }
            continue
        }

        if ($indent -eq 8 -and $null -ne $currentStep) {
            # checkout だけに単一の credentials 無効化ブロックを許可する。
            if ($text -ceq "with:") {
                if ($currentStep -cne "Check out repository") { $invalid = $true; continue }
                $checkoutWithCount++
                $insideCheckoutWith = $true
                continue
            }

            $property = [regex]::Match($text, '^(?<key>uses|shell): (?<value>.+)$')
            if (-not $property.Success) { $invalid = $true; continue }
            $table = if ($property.Groups["key"].Value -ceq "uses") { $uses } else { $shells }
            if ($table.ContainsKey($currentStep)) { $invalid = $true }
            $table[$currentStep] = $property.Groups["value"].Value
            continue
        }

        # checkout credentials の入力名・値・字下げを exact contract として固定する。
        if ($indent -eq 10 -and $currentStep -ceq "Check out repository" -and $insideCheckoutWith) {
            if ($text -cne "persist-credentials: $expectedCheckoutPersistCredentials") {
                $invalid = $true
                continue
            }
            $persistCredentialsCount++
            continue
        }
        $invalid = $true
    }

    if ($jobsCount -ne 1 -or $validateCount -ne 1 -or $jobNameCount -ne 1 -or $runsOnCount -ne 1 -or
        $timeoutMinutesCount -ne 1 -or $stepsCount -ne 1 -or $runKeyCount -ne 3 -or
        ($workflowTopLevelContractLines -join "`n") -cne ($expectedWorkflowTopLevelContractLines -join "`n") -or
        ($stepNames -join "`n") -cne ($expectedStepNames -join "`n") -or
        $uses.Count -ne 1 -or $uses["Check out repository"] -cne $expectedCheckoutUses -or
        $checkoutWithCount -ne 1 -or $persistCredentialsCount -ne 1 -or
        $shells.Count -ne 3 -or $runs.Count -ne 3) {
        $invalid = $true
    }
    for ($index = 1; $index -lt $expectedWorkflowSteps.Count; $index++) {
        $step = $expectedWorkflowSteps[$index]
        if ($shells[$step["Name"]] -cne $step["Shell"] -or $runs[$step["Name"]] -cne $step["Run"]) { $invalid = $true }
    }
    return -not $invalid
}

function Get-CheckAllContractFailures {
    param(
        [string]$ReadmeContent,
        [string]$AgentsContent,
        [string]$WorkflowContent
    )

    if (-not (Test-VisibleMarkdownCheckAllContract $ReadmeContent $expectedReadmeCheckAllHeading)) {
        "README.md does not contain exactly one visible canonical Validation section and exact check:all fence/body."
    }
    if (-not (Test-VisibleMarkdownCheckAllContract $AgentsContent $expectedAgentsCheckAllHeading)) {
        "AGENTS.md does not contain exactly one visible canonical section 7 and exact check:all fence/body."
    }

    if (-not (Test-ValidationWorkflowContract $WorkflowContent)) {
        "Validation workflow does not match the exact enabled check:all job and step contract."
    }
}

function Assert-ReadmeCheckAllContractParser {
    $canonicalFence = (@('```powershell') + $expectedCheckAllCommands + @('```')) -join "`n"
    $canonicalReadme = @("# Example", "", $expectedReadmeCheckAllHeading, "", "Run the local checks:", "", $canonicalFence, "", "## Next") -join "`n"
    $canonicalAgents = @("# Agent contract", "", $expectedAgentsCheckAllHeading, "", $canonicalFence, "", "## §8. Next") -join "`n"
    $canonicalWorkflow = @'
name: Validation

on:
  pull_request:
  push:
    branches:
      - main

permissions:
  contents: read

jobs:
  validate:
    name: Public readiness and marker scan
    runs-on: windows-latest
    timeout-minutes: 10

    steps:
      - name: Check out repository
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false

      - name: Run public readiness checks
        shell: pwsh
        run: ./scripts/test-public-readiness.ps1

      - name: Run private marker scanner tests
        shell: pwsh
        run: ./scripts/test-scan-private-markers.ps1

      - name: Run private marker scan
        shell: pwsh
        run: ./scripts/scan-private-markers.ps1
'@
    # checkoutのEOL変換に左右されないよう、負例生成前のin-memory fixtureをLFへ正規化する。
    $canonicalWorkflow = $canonicalWorkflow -replace "`r`n", "`n"
    $commentDecoy = @("<!--", $expectedReadmeCheckAllHeading, '```powershell', "decoy", '```', "-->") -join "`n"
    $inlineCommentDecoy = @("visible prefix <!--", $expectedReadmeCheckAllHeading, '```powershell', "decoy", '```', "-->") -join "`n"
    $htmlDecoy = @("<div>", $expectedReadmeCheckAllHeading, '```powershell', "decoy", '```', "</div>", "") -join "`n"
    $fenceDecoy = @("~~~text", $expectedReadmeCheckAllHeading, "decoy", "~~~") -join "`n"
    $duplicateSection = @($expectedReadmeCheckAllHeading, "", $canonicalFence) -join "`n"
    $longFence = (@('````powershell') + $expectedCheckAllCommands + @('````')) -join "`n"
    $caseFence = $canonicalFence.Replace('```powershell', '```PowerShell')
    $wrongFirstFence = @('```powershell', "wrong command", '```') -join "`n"

    $cases = @(
        [pscustomobject]@{ Label = "canonical"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow; ExpectedFailure = $null },
        [pscustomobject]@{ Label = "canonical CRLF"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("`n", "`r`n"); ExpectedFailure = $null },
        [pscustomobject]@{ Label = "HTML comment decoy"; Readme = $commentDecoy + "`n" + $canonicalReadme; Workflow = $canonicalWorkflow; ExpectedFailure = $null },
        [pscustomobject]@{ Label = "inline HTML comment decoy"; Readme = $inlineCommentDecoy + "`n" + $canonicalReadme; Workflow = $canonicalWorkflow; ExpectedFailure = $null },
        [pscustomobject]@{ Label = "raw HTML decoy"; Readme = $htmlDecoy + $canonicalReadme; Workflow = $canonicalWorkflow; ExpectedFailure = $null },
        [pscustomobject]@{ Label = "fenced H2 decoy"; Readme = $fenceDecoy + "`n" + $canonicalReadme; Workflow = $canonicalWorkflow; ExpectedFailure = $null },
        [pscustomobject]@{ Label = "duplicate visible H2"; Readme = $canonicalReadme + "`n" + $duplicateSection; Workflow = $canonicalWorkflow; ExpectedFailure = "README.md" },
        [pscustomobject]@{ Label = "case variant H2"; Readme = $canonicalReadme.Replace("## Validation", "## validation"); Workflow = $canonicalWorkflow; ExpectedFailure = "README.md" },
        [pscustomobject]@{ Label = "long target fence"; Readme = $canonicalReadme.Replace($canonicalFence, $longFence); Workflow = $canonicalWorkflow; ExpectedFailure = "README.md" },
        [pscustomobject]@{ Label = "wrong first target fence"; Readme = $canonicalReadme.Replace($canonicalFence, $wrongFirstFence + "`n`n" + $canonicalFence); Workflow = $canonicalWorkflow; ExpectedFailure = "README.md" },
        [pscustomobject]@{ Label = "case fence before canonical"; Readme = $canonicalReadme.Replace($canonicalFence, $caseFence + "`n`n" + $canonicalFence); Workflow = $canonicalWorkflow; ExpectedFailure = "README.md" },
        [pscustomobject]@{ Label = "long fence before canonical"; Readme = $canonicalReadme.Replace($canonicalFence, $longFence + "`n`n" + $canonicalFence); Workflow = $canonicalWorkflow; ExpectedFailure = "README.md" },
        [pscustomobject]@{ Label = "missing workflow name"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("name: Validation`n`n", ""); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "wrong workflow name"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("name: Validation", "name: Other"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "missing event map"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("on:`n  pull_request:`n  push:`n    branches:`n      - main`n`n", ""); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "missing pull request event"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("  pull_request:`n", ""); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "missing push event"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("  push:`n    branches:`n      - main`n", ""); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "workflow dispatch event"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("  pull_request:", "  workflow_dispatch:`n  pull_request:"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "scheduled event"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("  pull_request:", "  schedule:`n    - cron: '0 0 * * *'`n  pull_request:"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "additional push branch"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("      - main", "      - main`n      - develop"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "push tag filter"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("      - main", "      - main`n    tags:`n      - 'v*'"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "missing permissions"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("permissions:`n  contents: read`n`n", ""); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "contents write permission"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("  contents: read", "  contents: write"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "additional permission"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("  contents: read", "  contents: read`n  issues: read"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "duplicate permissions key"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("permissions:`n  contents: read", "permissions:`n  contents: read`n`npermissions:`n  contents: read"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "disabled job"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("    steps:", "    if: false`n    steps:"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "continue on error"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("        shell: pwsh", "        continue-on-error: true`n        shell: pwsh"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "extra run"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("        uses: $expectedCheckoutUses", "        uses: $expectedCheckoutUses`n        run: ./scripts/test-public-readiness.ps1"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "block scalar run"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("        run: ./scripts/test-public-readiness.ps1", "        run: |`n          ./scripts/test-public-readiness.ps1"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "quoted run"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("run: ./scripts/test-public-readiness.ps1", 'run: "./scripts/test-public-readiness.ps1"'); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "mutable checkout ref"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace($expectedCheckoutUses, "actions/checkout@v7"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "stale Node 20 checkout pin"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace($expectedCheckoutUses, "actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "wrong checkout SHA"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace($expectedCheckoutUses, "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b2 # v7.0.1"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "missing checkout version comment"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace($expectedCheckoutUses, "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "missing timeout"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("    timeout-minutes: 10`n`n", ""); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "wrong timeout"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("    timeout-minutes: 10", "    timeout-minutes: 15"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "duplicate timeout"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("    timeout-minutes: 10", "    timeout-minutes: 10`n    timeout-minutes: 10"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "missing checkout credentials block"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("        with:`n          persist-credentials: false`n", ""); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "missing persist credentials"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("          persist-credentials: false", ""); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "persist credentials enabled"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("          persist-credentials: false", "          persist-credentials: true"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "duplicate persist credentials"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("          persist-credentials: false", "          persist-credentials: false`n          persist-credentials: false"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "extra checkout input"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("          persist-credentials: false", "          persist-credentials: false`n          fetch-depth: 1"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "with on run step"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow.Replace("        shell: pwsh", "        with:`n          persist-credentials: false`n        shell: pwsh"); ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "duplicate exact jobs"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow + "`njobs:"; ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "quoted jobs"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow + "`n`"jobs`":"; ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "spaced jobs"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow + "`njobs :"; ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "flow jobs"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow + "`njobs: {}"; ExpectedFailure = "Validation workflow" },
        [pscustomobject]@{ Label = "other job"; Readme = $canonicalReadme; Workflow = $canonicalWorkflow + "`n  decoy:`n    runs-on: windows-latest`n    steps:`n      - name: Decoy`n        shell: pwsh`n        run: ./scripts/test-public-readiness.ps1"; ExpectedFailure = "Validation workflow" }
    )

    foreach ($case in $cases) {
        $caseFailures = @(Get-CheckAllContractFailures $case.Readme $canonicalAgents $case.Workflow)
        if ($null -eq $case.ExpectedFailure) {
            if ($caseFailures.Count -ne 0) {
                Add-Failure "Internal check:all contract case '$($case.Label)' unexpectedly failed."
            }
            continue
        }

        if ($caseFailures.Count -eq 0 -or
            -not ($caseFailures | Where-Object { $_.Contains($case.ExpectedFailure) })) {
            Add-Failure "Internal check:all contract case '$($case.Label)' did not fail closed."
        }
    }
}

function Assert-ReadmeCheckAllContract {
    $readmeFile = Get-RepoFile "README.md"
    $agentsFile = Get-RepoFile "AGENTS.md"
    $workflowFile = Get-RepoFile ".github/workflows/validation.yml"

    foreach ($requiredFile in @($readmeFile, $agentsFile, $workflowFile)) {
        if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
            Add-Failure "Cannot compare missing check:all contract file."
            return
        }
    }

    $readmeContent = Get-Content -LiteralPath $readmeFile -Raw -Encoding UTF8
    $agentsContent = Get-Content -LiteralPath $agentsFile -Raw -Encoding UTF8
    $workflowContent = Get-Content -LiteralPath $workflowFile -Raw -Encoding UTF8
    @(Get-CheckAllContractFailures $readmeContent $agentsContent $workflowContent) |
        ForEach-Object { Add-Failure $_ }
}

@(
    "AGENTS.md",
    "CODEX_START_HERE.md",
    "HANDOFF.md",
    "README.md",
    "LICENSE",
    "SKILL.md",
    "TASKS_BACKLOG.md",
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "CHANGELOG.md",
    "docs/CODEX_PROMPT_2026-07-12.md",
    "docs/requirements-redefinition-2026-07.md",
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
Assert-Contains "CODEX_START_HERE.md" '(?ms)^## 読み順（唯一の正本）\s*$.*?^1\. `AGENTS\.md`.*?^2\. `HANDOFF\.md`.*?^3\. `TASKS_BACKLOG\.md`.*?^4\. `README\.md`.*?^5\. `SKILL\.md`.*?^6\. `docs/requirements-redefinition-2026-07\.md`' "canonical document reading order"
Assert-Contains "AGENTS.md" '`CODEX_START_HERE\.md` の「読み順（唯一の正本）」' "agent contract refers to canonical reading order"
# AGENTS 自体が陳腐化する現況値を正本化しないよう、visible §3だけをscopeにcontractと禁止snapshotを検査する。
Assert-AgentsLiveStateContractParser
Assert-AgentsLiveStateContract
Assert-AgentsBacklogGuidanceParser
Assert-AgentsBacklogGuidance
Assert-Contains "HANDOFF.md" '資料読み順の唯一の正本は \[`CODEX_START_HERE\.md`\]\(CODEX_START_HERE\.md\)' "handoff refers to canonical reading order"
Assert-Contains "docs/CODEX_PROMPT_2026-07-12.md" '`CODEX_START_HERE\.md` の「読み順（唯一の正本）」' "dated prompt refers to canonical reading order"
Assert-Contains "README.md" "## License" "license section"
Assert-Contains "README.md" "MIT License" "MIT license is declared"
Assert-Contains "README.md" "## Contributing" "contribution path"
Assert-Contains "README.md" "## Security" "security reporting path"
Assert-Contains "README.md" "## Updating an Existing Install" "existing install update path"
Assert-Contains "README.md" "Compare-Object" "installed skill comparison guidance"
Assert-Contains "README.md" "Copy-Item" "installed skill update command"
Assert-NotContains "README.md" "license draft|before public release" "stale draft-release language"
Assert-SkillContractParser
Assert-SkillContract
Assert-ChecklistAxisParser
Assert-ChecklistItemParser
Assert-UnsupportedChecklistParser
Assert-ChecklistSummaryMatchesReadme "references/checklist.md" "README.md"
Assert-ReadmeCheckAllContractParser
Assert-ReadmeCheckAllContract

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
