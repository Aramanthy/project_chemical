# Runs the headless GDScript test suite.
# Usage:  .\tools\run_tests.ps1
# Set $env:GODOT_BIN to override the Godot executable path.
#
# Note: Godot exits with code 0 even when the -s entry script fails to parse,
# so success is determined by the runner's summary line, not the exit code alone.

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent $PSScriptRoot

$godot = $env:GODOT_BIN
if (-not $godot) {
    $godot = "$env:USERPROFILE\Desktop\Godot_v4.7.2-stable_win64.exe"
}
if (-not (Test-Path $godot)) {
    Write-Host "Godot executable not found at '$godot'. Set `$env:GODOT_BIN."
    exit 2
}

# Refresh the global class_name cache so newly added scripts are resolvable.
& $godot --headless --path $projectRoot --import 2>&1 | Out-Null

# Piping forces the GUI build of Godot to emit stdout to this console.
$output = & $godot --headless --path $projectRoot -s res://src/tests/run_tests.gd 2>&1 | Out-String
$godotExit = $LASTEXITCODE
Write-Host $output

$summaryOk = $output -match '(\d+) tests, \d+ passed, 0 failed'
$scriptErrors = $output -match 'SCRIPT ERROR|Parse Error'

if ($godotExit -ne 0 -or -not $summaryOk -or $scriptErrors) {
    Write-Host "TESTS FAILED" -ForegroundColor Red
    exit 1
}
Write-Host "ALL TESTS PASSED" -ForegroundColor Green
exit 0
