param(
  [string]$AvdName,
  [string]$DeviceId,
  [switch]$Release,
  [string]$Flavor
)
$ErrorActionPreference = "Stop"
function Fail($msg) { Write-Error $msg; exit 1 }
$Sdk = $Env:ANDROID_HOME; if (-not $Sdk -and $Env:ANDROID_SDK_ROOT) { $Sdk = $Env:ANDROID_SDK_ROOT }
if (-not $Sdk) { Fail "ANDROID_HOME/ANDROID_SDK_ROOT не установлены." }
$Emu = Join-Path $Sdk "emulator\emulator.exe"
$Adb = Join-Path $Sdk "platform-tools\adb.exe"
if (-not (Test-Path $Emu)) { Fail "Не найден emulator.exe: $Emu" }
if (-not (Test-Path $Adb)) { Fail "Не найден adb.exe: $Adb" }
$Avds = & $Emu -list-avds
if (-not $Avds -or $Avds.Count -eq 0) { Fail "AVD не найден. Создай устройство в Android Studio." }
if (-not $AvdName -or ($Avds -notcontains $AvdName)) { $AvdName = $Avds[0] }
$Devices = & $Adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
$RunningEmu = ($Devices | ForEach-Object { ($_ -split "`t")[0] }) | Where-Object { $_ -match "^emulator-" }
$StartedNew = $false
if (-not $DeviceId -and -not $RunningEmu) {
  $args = @("-avd", $AvdName, "-netdelay", "none", "-netspeed", "full", "-no-boot-anim")
  Start-Process -FilePath $Emu -ArgumentList $args | Out-Null
  $StartedNew = $true
}
& $Adb wait-for-device
if ($StartedNew) {
  do {
    Start-Sleep -Seconds 2
    $res = & $Adb shell getprop sys.boot_completed 2>$null
  } until ($res -match "1")
}
if (-not $DeviceId) {
  $Devices = & $Adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" }
  $DeviceId = ($Devices | ForEach-Object { ($_ -split "`t")[0] } | Where-Object { $_ -match "^emulator-" } | Select-Object -First 1)
  if (-not $DeviceId) { Fail "Не удалось определить ID эмулятора." }
}
$runArgs = @("-d", $DeviceId)
if ($Release) { $runArgs += "--release" }
if ($Flavor)  { $runArgs += @("--flavor", $Flavor) }
flutter pub get
flutter devices
flutter run @runArgs
