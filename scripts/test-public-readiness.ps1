param(
    [string]$Path = "."
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath $Path).Path
$failures = [System.Collections.Generic.List[string]]::new()
$unsupportedChecklistStructureError = "Unsupported checklist Markdown structure; use top-level headings and checklist items."

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
Assert-ChecklistAxisParser
Assert-ChecklistItemParser
Assert-UnsupportedChecklistParser
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
