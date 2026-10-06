<#
    Empacota o projeto em dist/game.love (um .love e so um .zip renomeado
    contendo conf.lua/main.lua na raiz). Rode a partir da raiz do projeto:

        .\build.ps1
#>

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$dist = Join-Path $root "dist"
$output = Join-Path $dist "game.love"

$exclude = @(".git", ".vscode", "dist", "docs", "*.md", ".luarc.json", ".luacheckrc", ".editorconfig", "stylua.toml", "build.ps1")

New-Item -ItemType Directory -Force -Path $dist | Out-Null
if (Test-Path $output) { Remove-Item $output -Force }

$staging = Join-Path $dist "_staging"
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Force -Path $staging | Out-Null

Get-ChildItem -Path $root -Force | Where-Object {
    $name = $_.Name
    -not ($exclude | Where-Object { $name -like $_ })
} | ForEach-Object {
    Copy-Item $_.FullName -Destination $staging -Recurse -Force
}

Compress-Archive -Path "$staging\*" -DestinationPath $output -CompressionLevel Optimal
Remove-Item $staging -Recurse -Force

Write-Host "Gerado: $output"
