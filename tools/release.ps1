# Arma el AAB firmado para subir a Google Play (P-07).
# Pasos: corre los tests, sube version/code en export_presets.cfg (y copia el nombre a project.godot), instala la plantilla de Gradle
# si falta y exporta el preset "Android Play (AAB)" a build/retro-pinball.aab.
#
# La clave de subida NUNCA va al repo. Se toma de estas variables de entorno (las lee Godot):
#   GODOT_ANDROID_KEYSTORE_RELEASE_PATH      ruta al .jks (por defecto ~\.keystores\retropinball-upload.jks)
#   GODOT_ANDROID_KEYSTORE_RELEASE_USER      alias de la clave (por defecto "upload")
#   GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD  contraseña (si falta, se pide al correr el script)
#
# Uso: .\tools\release.ps1                  -> tests + versión siguiente + AAB
#      .\tools\release.ps1 -NoBump          -> reexporta con el mismo version/code
#      .\tools\release.ps1 -VersionName 0.9.1
#      .\tools\release.ps1 -SkipTests
param(
	[switch]$NoBump,
	[switch]$SkipTests,
	[string]$VersionName = ""
)
$ErrorActionPreference = "Stop"
$godot = "C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe"
$root = Split-Path -Parent $PSScriptRoot
$presets = Join-Path $root "export_presets.cfg"
$preset = "Android Play (AAB)"
$output = Join-Path $root "build\retro-pinball.aab"
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Step([string]$text) { Write-Host "`n== $text" -ForegroundColor Cyan }

# 1. Clave de subida
if (-not $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH) {
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = Join-Path $HOME ".keystores\retropinball-upload.jks"
}
if (-not $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER) { $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = "upload" }
if (-not (Test-Path $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH)) {
	Write-Host "No encuentro la clave de subida en $($env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH)." -ForegroundColor Red
	Write-Host "Creala una vez con keytool (ver docs/PLAY_STORE.md, paso 1) o apuntá GODOT_ANDROID_KEYSTORE_RELEASE_PATH al .jks."
	exit 1
}
if (-not $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD) {
	$secure = Read-Host "Contraseña de la clave de subida" -AsSecureString
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
		[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
}

# 2. Tests
if (-not $SkipTests) {
	Write-Step "Tests"
	& (Join-Path $PSScriptRoot "test.ps1")
	if ($LASTEXITCODE -ne 0) {
		Write-Host "Los tests fallan: no se arma el AAB." -ForegroundColor Red
		exit 1
	}
}

# 3. Versión: Play rechaza un version/code que ya se subió, así que se suma uno en los dos presets.
$text = [IO.File]::ReadAllText($presets, $utf8)
$code = [int]([regex]::Match($text, 'version/code=(\d+)').Groups[1].Value)
if (-not $NoBump) {
	$code += 1
	$text = [regex]::Replace($text, 'version/code=\d+', "version/code=$code")
}
if ($VersionName -ne "") {
	$text = [regex]::Replace($text, 'version/name="[^"]*"', "version/name=`"$VersionName`"")
}
[IO.File]::WriteAllText($presets, $text, $utf8)
$name = [regex]::Match($text, 'version/name="([^"]*)"').Groups[1].Value
# La pantalla Acerca de lee la versión de project.godot: se mantiene igual al preset.
$project = Join-Path $root "project.godot"
$projectText = [IO.File]::ReadAllText($project, $utf8)
if ($projectText -match 'config/version="[^"]*"') {
	$projectText = [regex]::Replace($projectText, 'config/version="[^"]*"', "config/version=`"$name`"")
} else {
	$projectText = [regex]::Replace($projectText, '(config/description="[^"]*"\r?\n)', "`$1config/version=`"$name`"`n", 1)
}
[IO.File]::WriteAllText($project, $projectText, $utf8)
Write-Step "Versión $name (code $code)"

# 4. Exportar. La plantilla de Gradle (android/, ignorada por git) se instala junto con la exportación
#    la primera vez en cada checkout: Godot solo acepta el flag acompañando a --export-release.
Write-Step "Exportando $preset"
New-Item -ItemType Directory -Force (Split-Path $output) | Out-Null
if (Test-Path $output) { Remove-Item $output -Force }
$arguments = @('--headless', '--path', $root)
if (-not (Test-Path (Join-Path $root "android\build\build.gradle"))) {
	Write-Host "Instalando la plantilla de Gradle de Android (primera vez)."
	$arguments += '--install-android-build-template'
}
$arguments += @('--export-release', $preset, $output)
# Sin daemon: en Windows el daemon de Gradle queda vivo con la salida de Godot abierta y la
# exportación no termina nunca aunque el AAB ya esté escrito.
if (-not $env:GRADLE_OPTS) { $env:GRADLE_OPTS = "-Dorg.gradle.daemon=false" }
& $godot @arguments | Out-Host
if (-not (Test-Path $output)) {
	Write-Host "La exportación no generó $output. Revisá el log de arriba." -ForegroundColor Red
	exit 1
}
$size = [math]::Round((Get-Item $output).Length / 1MB, 1)
Write-Host "`nListo: $output ($size MB, versión $name, code $code)" -ForegroundColor Green
Write-Host "Subilo en Play Console > Pruebas > (pista) > Crear versión."
if (-not $NoBump -or $VersionName -ne "") {
	Write-Host "Acordate de commitear export_presets.cfg y project.godot con la versión nueva."
}
