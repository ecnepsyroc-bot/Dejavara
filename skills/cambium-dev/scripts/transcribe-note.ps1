<#
.SYNOPSIS
    Voice note categorization and filing.

.DESCRIPTION
    Categorizes transcribed voice notes and saves them to appropriate locations.
    If OpenClaw provides the transcript, uses that. Otherwise falls back to Whisper API.

.PARAMETER Transcript
    Pre-transcribed text (if OpenClaw already transcribed the voice message).

.PARAMETER AudioFile
    Path to audio file (.ogg, .mp3, .wav) - used if no transcript provided.

.PARAMETER OutputDir
    Base output directory. Default is Google Drive Phone-Inbox.

.PARAMETER ProjectFolder
    Optional project folder for job notes (e.g., "X:\Projects\2024-0123").

.EXAMPLE
    .\transcribe-note.ps1 -Transcript "Remind me to check the shop drawing for unit 17 tomorrow"
    .\transcribe-note.ps1 -AudioFile "C:\temp\voice.ogg"
#>

param(
    [string]$Transcript,
    [string]$AudioFile,
    [string]$OutputDir = 'G:\My Drive\Phone-Inbox',
    [string]$ProjectFolder
)

$ErrorActionPreference = 'Stop'

# Category patterns
$categories = @{
    'TaskReminder' = @{
        Patterns = @('remind', 'todo', 'to-do', 'need to', "don't forget", 'remember to', 'task', 'deadline', 'due', 'by tomorrow', 'by friday', 'next week')
        Destination = $OutputDir
        FilePrefix = 'task'
    }
    'JobNote' = @{
        Patterns = @('job', 'unit', 'project', 'shop drawing', 'cut list', 'millwork', 'cabinet', 'laminate', 'drawing', 'submittal', 'rfq')
        Destination = if ($ProjectFolder) { $ProjectFolder } else { $OutputDir }
        FilePrefix = 'job-note'
    }
    'BrainDump' = @{
        Patterns = @()  # Default category
        Destination = $OutputDir
        FilePrefix = 'note'
    }
}

function Get-Category {
    param([string]$Text)

    $lowerText = $Text.ToLower()

    # Check TaskReminder first (higher priority)
    foreach ($pattern in $categories['TaskReminder'].Patterns) {
        if ($lowerText -like "*$pattern*") {
            return 'TaskReminder'
        }
    }

    # Check JobNote
    foreach ($pattern in $categories['JobNote'].Patterns) {
        if ($lowerText -like "*$pattern*") {
            return 'JobNote'
        }
    }

    # Check for project number patterns (e.g., 2024-0123, #123)
    if ($lowerText -match '\d{4}-\d{3,4}' -or $lowerText -match '#\d{3,}') {
        return 'JobNote'
    }

    return 'BrainDump'
}

function Get-TranscriptFromWhisper {
    param([string]$FilePath)

    $apiKey = $env:OPENAI_API_KEY
    if (-not $apiKey) {
        Write-Host "Warning: OPENAI_API_KEY not set. Cannot transcribe audio." -ForegroundColor Yellow
        return $null
    }

    Write-Host "Transcribing audio via Whisper API..." -ForegroundColor Cyan

    try {
        $response = curl.exe -s -X POST "https://api.openai.com/v1/audio/transcriptions" `
            -H "Authorization: Bearer $apiKey" `
            -F "file=@$FilePath" `
            -F "model=whisper-1" `
            -F "response_format=text"

        return $response
    } catch {
        Write-Host "Whisper API error: $_" -ForegroundColor Red
        return $null
    }
}

function Format-TaskItem {
    param([string]$Text)

    # Extract date references
    $dateRef = ""
    if ($Text -match 'tomorrow') { $dateRef = (Get-Date).AddDays(1).ToString('yyyy-MM-dd') }
    elseif ($Text -match 'next week') { $dateRef = (Get-Date).AddDays(7).ToString('yyyy-MM-dd') }
    elseif ($Text -match 'friday') {
        $daysUntilFriday = (5 - [int](Get-Date).DayOfWeek + 7) % 7
        if ($daysUntilFriday -eq 0) { $daysUntilFriday = 7 }
        $dateRef = (Get-Date).AddDays($daysUntilFriday).ToString('yyyy-MM-dd')
    }

    $content = @"
# Task

- [ ] $Text

"@
    if ($dateRef) {
        $content += "Due: $dateRef`n"
    }

    $content += "`nCaptured: $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n"
    return $content
}

function Format-JobNote {
    param([string]$Text)

    # Try to extract project number
    $projectNum = ""
    if ($Text -match '(\d{4}-\d{3,4})') {
        $projectNum = $Matches[1]
    }

    $content = @"
# Job Note

$Text

"@
    if ($projectNum) {
        $content += "Project: $projectNum`n"
    }

    $content += "Captured: $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n"
    return $content
}

function Format-BrainDump {
    param([string]$Text)

    return @"
# Note

$Text

Captured: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
"@
}

# Main logic
Write-Host "=== Voice Note Processing ===" -ForegroundColor Cyan

# Get transcript
$text = $Transcript
if (-not $text -and $AudioFile) {
    if (-not (Test-Path $AudioFile)) {
        Write-Host "Audio file not found: $AudioFile" -ForegroundColor Red
        exit 1
    }
    $text = Get-TranscriptFromWhisper -FilePath $AudioFile
}

if (-not $text) {
    Write-Host "No transcript available. Provide -Transcript or -AudioFile with OPENAI_API_KEY set." -ForegroundColor Red
    exit 1
}

Write-Host "Transcript: $text`n"

# Categorize
$category = Get-Category -Text $text
$catInfo = $categories[$category]

Write-Host "Category: $category" -ForegroundColor Cyan

# Format content based on category
$content = switch ($category) {
    'TaskReminder' { Format-TaskItem -Text $text }
    'JobNote' { Format-JobNote -Text $text }
    'BrainDump' { Format-BrainDump -Text $text }
}

# Generate filename
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$filename = "$($catInfo.FilePrefix)-$timestamp.md"
$destination = Join-Path $catInfo.Destination $filename

# Ensure directory exists
$destDir = Split-Path $destination
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

# Save file
$content | Out-File -FilePath $destination -Encoding utf8

Write-Host "`n=== Saved ===" -ForegroundColor Green
Write-Host "Category: $category"
Write-Host "File: $filename"
Write-Host "Location: $destination"

# Telegram summary
Write-Host "`n--- Telegram ---"
$emoji = switch ($category) {
    'TaskReminder' { ([char]0x2705) }  # ✅
    'JobNote' { ([char]0x1F4CB) }      # 📋
    'BrainDump' { ([char]0x1F4DD) }    # 📝
}
Write-Host "$emoji Captured as $category"
Write-Host "Saved to: $($catInfo.Destination | Split-Path -Leaf)"
