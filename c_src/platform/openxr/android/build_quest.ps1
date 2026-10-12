# build_quest.ps1 - Star Wars for the headset itself: c_src\StarWarsQuest.apk
#
#   -Sdk      an Android SDK with: platform-tools, platforms;android-34,
#             build-tools;34.0.0, ndk;26.3.11579264, cmake;3.22.1
#   -OpenXR   the unpacked org.khronos.openxr:openxr_loader_for_android .aar
#   -Keystore the key the .apk is signed with (made here if it is not there;
#             an update must be signed with the same one)
#
# A JDK (17) must be on JAVA_HOME or the PATH.  Then, with the headset on USB:
#   adb install -r c_src\StarWarsQuest.apk
param(
    [string]$Sdk = 'C:\SW3D\android-sdk',
    [string]$OpenXR = "$Sdk\openxr-loader",
    [string]$Keystore = "$Sdk\starwars-debug.keystore"
)
$ErrorActionPreference = 'Stop'
$src   = (Resolve-Path "$PSScriptRoot\..\..\..").Path             # c_src
$build = "$src\build-quest"
$ndk   = (Get-ChildItem "$Sdk\ndk" -Directory | Sort-Object Name | Select-Object -Last 1).FullName
$bt    = (Get-ChildItem "$Sdk\build-tools" -Directory | Sort-Object Name | Select-Object -Last 1).FullName
$plat  = (Get-ChildItem "$Sdk\platforms" -Directory | Sort-Object Name | Select-Object -Last 1).FullName
$cm    = (Get-ChildItem "$Sdk\cmake" -Directory | Sort-Object Name | Select-Object -Last 1).FullName
if (-not $env:JAVA_HOME) {
    $j = Get-ChildItem 'C:\Program Files\Microsoft' -Directory -Filter 'jdk-*' -ErrorAction SilentlyContinue | Select-Object -Last 1
    if ($j) { $env:JAVA_HOME = $j.FullName }
}
$abi = 'arm64-v8a'

function Run([string]$exe, [string[]]$a) {
    & $exe @a
    if ($LASTEXITCODE -ne 0) { throw "$exe failed ($LASTEXITCODE)" }
}

# ---- libstarwars.so ---------------------------------------------------------
Run "$cm\bin\cmake.exe" @('-S', $src, '-B', $build, '-G', 'Ninja', "-DCMAKE_MAKE_PROGRAM=$cm\bin\ninja.exe",
    "-DCMAKE_TOOLCHAIN_FILE=$ndk\build\cmake\android.toolchain.cmake", "-DANDROID_ABI=$abi", '-DANDROID_PLATFORM=android-29',
    '-DCMAKE_BUILD_TYPE=Release', "-DOPENXR_ANDROID=$OpenXR")
Run "$cm\bin\cmake.exe" @('--build', $build)

# ---- the .apk: the manifest, the two libraries, aligned and signed ----------
$stage = "$build\apk"
if (Test-Path $stage) { [IO.Directory]::Delete($stage, $true) }
New-Item -ItemType Directory -Force "$stage\lib\$abi" | Out-Null
Copy-Item "$build\libstarwars.so" "$stage\lib\$abi\"
Copy-Item "$OpenXR\prefab\modules\openxr_loader\libs\android.$abi\libopenxr_loader.so" "$stage\lib\$abi\"
Run "$ndk\toolchains\llvm\prebuilt\windows-x86_64\bin\llvm-strip.exe" @('--strip-unneeded', "$stage\lib\$abi\libstarwars.so")

$raw = "$build\starwars-raw.apk"; $aligned = "$build\starwars-aligned.apk"; $apk = "$src\StarWarsQuest.apk"
$res = "$build\res.zip"                                            # the name and the icon
Run "$bt\aapt2.exe" @('compile', '--dir', "$PSScriptRoot\res", '-o', $res)
Run "$bt\aapt2.exe" @('link', '-o', $raw, '--manifest', "$PSScriptRoot\AndroidManifest.xml", '-I', "$plat\android.jar", $res)
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open($raw, 'Update')
foreach ($f in Get-ChildItem "$stage\lib\$abi") {
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, "lib/$abi/$($f.Name)", 'Optimal') | Out-Null
}
$zip.Dispose()
Run "$bt\zipalign.exe" @('-f', '4', $raw, $aligned)

$keytool = if ($env:JAVA_HOME) { "$env:JAVA_HOME\bin\keytool.exe" } else { 'keytool' }
if (-not (Test-Path $Keystore)) {
    Run $keytool @('-genkeypair', '-keystore', $Keystore, '-storepass', 'android', '-keypass', 'android', '-alias', 'androiddebugkey',
        '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000', '-dname', 'CN=Android Debug,O=Android,C=US')
}
Run "$bt\apksigner.bat" @('sign', '--ks', $Keystore, '--ks-pass', 'pass:android', '--key-pass', 'pass:android', '--out', $apk, $aligned)
"{0}  {1:N0} bytes" -f $apk, (Get-Item $apk).Length
