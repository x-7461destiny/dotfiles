[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$dotfiles = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$failures = 0
$warnings = 0

function Write-Ok([string]$Message) { Write-Output "[OK]   $Message" }
function Write-Warn([string]$Message) { $script:warnings++; Write-Output "[WARN] $Message" }
function Write-Fail([string]$Message) { $script:failures++; Write-Output "[FAIL] $Message" }
function Write-Info([string]$Message) { Write-Output "[INFO] $Message" }

function Test-RequiredCommand([string]$Name) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { Write-Ok "$Name`: $($command.Source)" } else { Write-Fail "$Name is required but was not found" }
}

function Test-OptionalCommand([string]$Name) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { Write-Ok "$Name`: $($command.Source)" } else { Write-Warn "$Name is not installed; its configuration will remain unused" }
}

function Get-LinkTargetPath($Item, [string]$Parent) {
    if (-not $Item.LinkType -or -not $Item.Target) { return $null }
    $target = [string]($Item.Target | Select-Object -First 1)
    if (-not [System.IO.Path]::IsPathRooted($target)) { $target = Join-Path $Parent $target }
    return [System.IO.Path]::GetFullPath($target).TrimEnd('\')
}

function Test-ConfigLink([string]$Name, [string]$Source, [string]$Target) {
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if (-not $item) { Write-Info "$Name is not deployed yet: $Target"; return }
    $actual = Get-LinkTargetPath $item (Split-Path -Parent $Target)
    if ($actual -and $actual -ieq $Source.TrimEnd('\')) {
        Write-Ok "$Name link: $Target"
    } elseif ($item.LinkType) {
        Write-Warn "$Name points somewhere else: $Target -> $actual"
    } else {
        Write-Warn "$Name target already exists and is not a symbolic link: $Target"
    }
}

Write-Output "Dotfiles doctor (Windows)"
Write-Output "Repository: $dotfiles`n"

foreach ($path in @("nvim", "tmux", "wezterm", "yazi", "install")) {
    if (Get-Item -LiteralPath (Join-Path $dotfiles $path) -Force -ErrorAction SilentlyContinue) {
        Write-Ok "repository path: $path"
    } else {
        Write-Fail "missing repository path: $path"
    }
}

Write-Output "`nInstaller requirements"
Test-RequiredCommand "powershell"
Test-RequiredCommand "git"

Write-Output "`nConfigured applications"
foreach ($command in @("pwsh", "nvim", "wezterm", "yazi")) { Test-OptionalCommand $command }
foreach ($command in @("rg", "fd", "fzf", "ssh", "wsl", "nc")) { Test-OptionalCommand $command }

Write-Output "`nSymbolic-link capability"
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$developerModeSettings = Get-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue
$developerMode = if ($developerModeSettings) { $developerModeSettings.AllowDevelopmentWithoutDevLicense } else { 0 }
if ($isAdmin) {
    Write-Ok "current PowerShell process is elevated"
} elseif ($developerMode -eq 1) {
    Write-Ok "Windows Developer Mode allows non-elevated symbolic links"
} else {
    Write-Warn "symbolic-link creation may require an elevated shell or Windows Developer Mode"
}

Write-Output "`nFonts"
$fontNames = @()
foreach ($key in @("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts", "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts")) {
    $properties = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
    if ($properties) { $fontNames += $properties.PSObject.Properties.Name }
}
if ($fontNames -match "JetBrains Mono|Nerd Font") {
    Write-Ok "JetBrains Mono or a Nerd Font was detected"
} else {
    Write-Warn "JetBrains Mono/Nerd Font was not detected; terminal icons may be missing"
}

Write-Output "`nMachine-specific configuration"
$machineLocal = Join-Path $dotfiles "wezterm\config\machine_local.lua"
if (Get-Item -LiteralPath $machineLocal -Force -ErrorAction SilentlyContinue) {
    Write-Ok "wezterm/config/machine_local.lua exists and is Git-ignored"
} else {
    Write-Info "No machine_local.lua; portable defaults will be used"
    Write-Info "Copy machine.example.lua to machine_local.lua to customize this machine"
}

Write-Output "`nDeployment status"
Test-ConfigLink "Neovim" (Join-Path $dotfiles "nvim") (Join-Path $env:LOCALAPPDATA "nvim")
Test-ConfigLink "WezTerm" (Join-Path $dotfiles "wezterm") (Join-Path $HOME ".config\wezterm")
Test-ConfigLink "Yazi" (Join-Path $dotfiles "yazi\config") (Join-Path $env:APPDATA "yazi\config")

Write-Output "`nSummary: $failures failure(s), $warnings warning(s)"
if ($failures -gt 0) { exit 1 }
