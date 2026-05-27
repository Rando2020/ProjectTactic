<#
.SYNOPSIS
  Audits and safely organizes a local ProjectTactic workspace.

.DESCRIPTION
  This script is intentionally conservative.
  By default it only writes audit reports under _workspace-audit and prints a move plan.
  It does not move files unless you pass -Apply.

.EXAMPLE
  pwsh -ExecutionPolicy Bypass -File .\tools\organize-projecttactic-workspace.ps1

.EXAMPLE
  pwsh -ExecutionPolicy Bypass -File .\tools\organize-projecttactic-workspace.ps1 -Apply
#>

param(
  [string]$Root = "C:\Users\jojo3\Coding\ProjectTactic",
  [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section {
  param([string]$Text)
  Write-Host ""
  Write-Host "==== $Text ===="
}

function Ensure-Directory {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    if ($Apply) {
      New-Item -ItemType Directory -Path $Path -Force | Out-Null
      return "created"
    }
    return "missing"
  }
  return "exists"
}

function Get-SafeDestination {
  param(
    [string]$DestinationDirectory,
    [string]$FileName
  )

  $candidate = Join-Path $DestinationDirectory $FileName
  if (-not (Test-Path -LiteralPath $candidate)) {
    return $candidate
  }

  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
  $extension = [System.IO.Path]::GetExtension($FileName)
  $counter = 1

  do {
    $candidateName = "{0}-{1}{2}" -f $baseName, $counter, $extension
    $candidate = Join-Path $DestinationDirectory $candidateName
    $counter++
  } while (Test-Path -LiteralPath $candidate)

  return $candidate
}

function Get-TargetDirectoryForFile {
  param([System.IO.FileInfo]$File)

  $extension = $File.Extension.ToLowerInvariant()

  switch ($extension) {
    ".png"  { return "godot/assets/_inbox/images" }
    ".jpg"  { return "godot/assets/_inbox/images" }
    ".jpeg" { return "godot/assets/_inbox/images" }
    ".webp" { return "godot/assets/_inbox/images" }
    ".gif"  { return "godot/assets/_inbox/images" }
    ".svg"  { return "godot/assets/_inbox/images" }

    ".wav"  { return "godot/assets/_inbox/audio" }
    ".mp3"  { return "godot/assets/_inbox/audio" }
    ".ogg"  { return "godot/assets/_inbox/audio" }
    ".flac" { return "godot/assets/_inbox/audio" }

    ".glb"  { return "godot/assets/_inbox/models" }
    ".gltf" { return "godot/assets/_inbox/models" }
    ".fbx"  { return "godot/assets/_inbox/models" }
    ".obj"  { return "godot/assets/_inbox/models" }
    ".blend" { return "godot/assets/_inbox/models" }

    ".md"   { return "docs/_inbox" }
    ".txt"  { return "docs/_inbox" }
    ".docx" { return "docs/_inbox" }
    ".pdf"  { return "docs/_inbox" }

    ".json" { return "data/_inbox" }
    ".csv"  { return "data/_inbox" }
    ".yaml" { return "data/_inbox" }
    ".yml"  { return "data/_inbox" }

    ".ps1"  { return "tools/_inbox" }
    ".bat"  { return "tools/_inbox" }
    ".cmd"  { return "tools/_inbox" }
    ".sh"   { return "tools/_inbox" }

    default { return "_inbox" }
  }
}

if (-not (Test-Path -LiteralPath $Root)) {
  throw "Root path not found: $Root"
}

$gitDir = Join-Path $Root ".git"
if (-not (Test-Path -LiteralPath $gitDir)) {
  throw "This does not look like a Git repo because .git was not found under $Root"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$auditDir = Join-Path $Root ("_workspace-audit\" + $timestamp)
New-Item -ItemType Directory -Path $auditDir -Force | Out-Null

Write-Section "ProjectTactic workspace audit"
Write-Host "Root: $Root"
Write-Host "Mode: $(if ($Apply) { 'APPLY changes' } else { 'DRY RUN, no moves' })"
Write-Host "Audit folder: $auditDir"

Push-Location $Root
try {
  Write-Section "Git status"
  git branch --show-current | Tee-Object -FilePath (Join-Path $auditDir "git-branch.txt")
  git status --short | Tee-Object -FilePath (Join-Path $auditDir "git-status-short.txt")
  git remote -v | Out-File -FilePath (Join-Path $auditDir "git-remotes.txt") -Encoding utf8
}
finally {
  Pop-Location
}

$expectedDirectories = @(
  "godot",
  "godot/assets",
  "godot/assets/audio",
  "godot/assets/music",
  "godot/assets/ui",
  "godot/assets/tiles",
  "godot/assets/characters",
  "godot/assets/environments",
  "godot/assets/vfx",
  "godot/assets/portraits",
  "godot/assets/icons",
  "godot/assets/_inbox/images",
  "godot/assets/_inbox/audio",
  "godot/assets/_inbox/models",
  "godot/scenes",
  "godot/scripts",
  "docs",
  "docs/architecture",
  "docs/design",
  "docs/systems",
  "docs/production",
  "docs/_inbox",
  "data",
  "data/jobs",
  "data/classes",
  "data/story",
  "data/towns",
  "data/items",
  "data/maps",
  "data/_inbox",
  "tools",
  "tools/_inbox",
  "_inbox"
)

Write-Section "Expected directory check"
$directoryReport = foreach ($relativePath in $expectedDirectories) {
  $absolutePath = Join-Path $Root $relativePath
  $status = Ensure-Directory -Path $absolutePath
  [pscustomobject]@{
    RelativePath = $relativePath
    Status = $status
  }
}
$directoryReport | Format-Table -AutoSize
$directoryReport | Export-Csv -Path (Join-Path $auditDir "directory-check.csv") -NoTypeInformation

Write-Section "Inventory"
$excludedPathPattern = "\\\.git\\|\\node_modules\\|\\\.godot\\|\\_workspace-audit\\|\\dist\\"
$allFiles = Get-ChildItem -LiteralPath $Root -File -Recurse -Force |
  Where-Object { $_.FullName -notmatch $excludedPathPattern }

$fileInventory = $allFiles | ForEach-Object {
  [pscustomobject]@{
    RelativePath = Resolve-Path -LiteralPath $_.FullName -Relative
    Extension = $_.Extension.ToLowerInvariant()
    SizeKB = [math]::Round($_.Length / 1KB, 2)
    LastWriteTime = $_.LastWriteTime
  }
}
$fileInventory | Export-Csv -Path (Join-Path $auditDir "file-inventory.csv") -NoTypeInformation

$largeFiles = $fileInventory | Where-Object { $_.SizeKB -ge 10240 } | Sort-Object SizeKB -Descending
$largeFiles | Export-Csv -Path (Join-Path $auditDir "large-files-over-10mb.csv") -NoTypeInformation
Write-Host "Files scanned: $($fileInventory.Count)"
Write-Host "Large files over 10 MB: $($largeFiles.Count)"

Write-Section "Loose root file move plan"
$protectedRootFiles = @(
  ".gitignore",
  ".gitattributes",
  "AGENTS.md",
  "AI_TASK_PACKETS.md",
  "ARCHITECTURE.md",
  "CLAUDE.md",
  "LICENSE",
  "README.md",
  "SKILL.md",
  "index.html",
  "package.json",
  "package-lock.json",
  "pnpm-lock.yaml",
  "vite.config.js",
  "vite.config.ts"
)

$rootFiles = Get-ChildItem -LiteralPath $Root -File -Force |
  Where-Object { $protectedRootFiles -notcontains $_.Name }

$movePlan = foreach ($file in $rootFiles) {
  $targetRelativeDirectory = Get-TargetDirectoryForFile -File $file
  $targetAbsoluteDirectory = Join-Path $Root $targetRelativeDirectory
  $targetAbsolutePath = Get-SafeDestination -DestinationDirectory $targetAbsoluteDirectory -FileName $file.Name

  [pscustomobject]@{
    Source = $file.FullName
    Destination = $targetAbsolutePath
    Reason = "Loose root file grouped by extension. Review before committing."
    WillMove = [bool]$Apply
  }
}

$movePlan | Export-Csv -Path (Join-Path $auditDir "loose-root-file-move-plan.csv") -NoTypeInformation

if ($movePlan.Count -eq 0) {
  Write-Host "No loose root files found outside the protected list."
} else {
  $movePlan | Format-Table Source, Destination, WillMove -AutoSize
}

if ($Apply -and $movePlan.Count -gt 0) {
  foreach ($entry in $movePlan) {
    $destinationDirectory = Split-Path -Parent $entry.Destination
    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
      New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    }
    Move-Item -LiteralPath $entry.Source -Destination $entry.Destination
  }
  Write-Host "Applied move plan. Review git status before committing."
} else {
  Write-Host "Dry run complete. Review loose-root-file-move-plan.csv before running with -Apply."
}

Write-Section "Next command"
Write-Host "git status --short"
