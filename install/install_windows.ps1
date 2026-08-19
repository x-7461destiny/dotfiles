[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
    [switch]$BackupExisting
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dotfiles = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$backupStamp = Get-Date -Format "yyyyMMdd-HHmmss"

function Get-LinkTargetPath {
    param(
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][string]$Parent
    )

    if (-not $Item.LinkType -or -not $Item.Target) {
        return $null
    }

    $linkTarget = [string]($Item.Target | Select-Object -First 1)
    if (-not [System.IO.Path]::IsPathRooted($linkTarget)) {
        $linkTarget = Join-Path $Parent $linkTarget
    }
    return [System.IO.Path]::GetFullPath($linkTarget).TrimEnd('\')
}

function Test-SameLink {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )

    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if (-not $item) {
        return $false
    }

    $actual = Get-LinkTargetPath -Item $item -Parent (Split-Path -Parent $Target)
    return $actual -and ($actual -ieq $Source.TrimEnd('\'))
}

function Assert-Linkable {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )

    $resolvedSource = (Resolve-Path -LiteralPath $Source).Path
    $existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if (-not $existing -or (Test-SameLink -Source $resolvedSource -Target $Target)) {
        return
    }

    if (-not $BackupExisting) {
        throw "Target already exists: $Target. Re-run with -BackupExisting to move it aside safely."
    }

    $backup = "$Target.dotfiles-backup-$backupStamp"
    if (Get-Item -LiteralPath $backup -Force -ErrorAction SilentlyContinue) {
        throw "Backup target already exists: $backup"
    }
}

function Link-Config {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )

    $resolvedSource = (Resolve-Path -LiteralPath $Source).Path
    if (Test-SameLink -Source $resolvedSource -Target $Target) {
        Write-Output "Already linked: $Target -> $resolvedSource"
        return
    }

    $parent = Split-Path -Parent $Target
    $parentItem = Get-Item -LiteralPath $parent -Force -ErrorAction SilentlyContinue
    if (-not $parentItem) {
        if ($PSCmdlet.ShouldProcess($parent, "Create parent directory")) {
            New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
        }
    }

    $existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($existing) {
        $backup = "$Target.dotfiles-backup-$backupStamp"
        if ($PSCmdlet.ShouldProcess($Target, "Move existing configuration to $backup")) {
            Move-Item -LiteralPath $Target -Destination $backup -ErrorAction Stop
            Write-Output "Backed up: $Target -> $backup"
        }
    }

    if ($PSCmdlet.ShouldProcess($Target, "Create symbolic link to $resolvedSource")) {
        New-Item -ItemType SymbolicLink -Path $Target -Target $resolvedSource -ErrorAction Stop | Out-Null
        if (-not (Test-SameLink -Source $resolvedSource -Target $Target)) {
            throw "Symbolic link verification failed: $Target"
        }
        Write-Output "Linked: $Target -> $resolvedSource"
    }
}

$links = @(
    @{ Name = "Neovim"; Source = (Join-Path $dotfiles "nvim"); Target = (Join-Path $env:LOCALAPPDATA "nvim") },
    @{ Name = "WezTerm"; Source = (Join-Path $dotfiles "wezterm"); Target = (Join-Path $HOME ".config\wezterm") },
    @{ Name = "Yazi"; Source = (Join-Path $dotfiles "yazi\config"); Target = (Join-Path $env:APPDATA "yazi\config") }
)

foreach ($command in @("git", "nvim", "wezterm", "yazi")) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        Write-Warning "Command not found: $command"
    }
}

# Preflight every target before changing anything.
foreach ($link in $links) {
    Assert-Linkable -Source $link.Source -Target $link.Target
}

foreach ($link in $links) {
    Write-Output "==> Linking $($link.Name)"
    Link-Config -Source $link.Source -Target $link.Target
}

if ($WhatIfPreference) {
    Write-Output "Preview complete; no files were changed."
} else {
    Write-Output "All done."
}

