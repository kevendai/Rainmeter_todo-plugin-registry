param([string]$OutputDirectory = (Join-Path $PSScriptRoot 'dist'))
$ErrorActionPreference = 'Stop'
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'plugin.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$project = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'src') -Filter '*.csproj' | Select-Object -First 1
if (-not $project) { throw 'Plugin project was not found.' }
$msbuild = Join-Path ([Environment]::GetFolderPath('Windows')) 'Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe'
if (-not (Test-Path -LiteralPath $msbuild)) { $msbuild = Join-Path ([Environment]::GetFolderPath('Windows')) 'Microsoft.NET\Framework\v4.0.30319\MSBuild.exe' }
if (-not (Test-Path -LiteralPath $msbuild)) { throw '.NET Framework 4 MSBuild was not found.' }
$stage = Join-Path ([IO.Path]::GetTempPath()) ('rwplugin-' + [guid]::NewGuid().ToString('N'))
# Keep the intermediate output OUTSIDE $stage: everything in $stage gets zipped into the
# .rwplugin, so an obj/ directory placed inside it would ship MSBuild caches with the package.
$obj = $stage + '-obj'
try {
    $bin = Join-Path $stage 'bin'
    New-Item -ItemType Directory -Path $bin -Force | Out-Null
    & $msbuild $project.FullName /nologo /verbosity:minimal /target:Build /property:Configuration=Release "/property:OutputPath=$bin\" "/property:IntermediateOutputPath=$obj\"
    if ($LASTEXITCODE -ne 0) { throw 'Plugin build failed.' }
    foreach ($name in @('plugin.json','settings.schema.json','README.md','THIRD-PARTY-NOTICES.md','icon.png')) {
        $source = Join-Path $PSScriptRoot $name
        if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $stage }
    }
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $slug = $manifest.id -replace '^io\.github\.kevendai\.', ''
    $baseName = $slug + '-' + $manifest.version
    $zip = Join-Path $OutputDirectory ($baseName + '.zip')
    $package = Join-Path $OutputDirectory ($baseName + '.rwplugin')
    Remove-Item -LiteralPath $zip,$package -Force -ErrorAction SilentlyContinue
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal
    Move-Item -LiteralPath $zip -Destination $package
    $sha = (Get-FileHash -LiteralPath $package -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -LiteralPath ($package + '.sha256') -Value ($sha + '  ' + [IO.Path]::GetFileName($package)) -Encoding ascii
    Write-Host "Created $package"
}
finally {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $obj -Recurse -Force -ErrorAction SilentlyContinue
}
