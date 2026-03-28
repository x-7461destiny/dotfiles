$dotfiles = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Link {
    param($source, $target)

    if (Test-Path $target) {
        Write-Output "Removing existing: $target"
        Remove-Item -Recurse -Force $target
    }

    $item = Get-Item $source
    if ($item.PSIsContainer) {
        cmd /c mklink /D "$target" "$source" | Out-Null
    } else {
        cmd /c mklink "$target" "$source" | Out-Null
    }
    Write-Output "Linked $target -> $source"
}

Write-Output "==> Linking Neovim"
Link "$dotfiles\nvim" "$env:LOCALAPPDATA\nvim"

Write-Output "==> Linking WezTerm"
Link "$dotfiles\wezterm\wezterm.lua" "$HOME\.wezterm.lua"

Write-Output "All done 🎉"

