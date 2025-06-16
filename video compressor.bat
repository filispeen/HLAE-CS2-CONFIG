@echo off
setlocal enabledelayedexpansion

set "input_file=%~1"
for %%F in ("%input_file%") do (
    set "file_name=%%~nxF"
    set "folder_path=%%~dpF"
)
set "output_file=!folder_path!compressed_!file_name!"

echo "Enter target size in Megabytes"
set /p "target_size_mb=: "
set /a maxrate_mb=!target_size_mb!

set "codec=hevc_nvenc"

set /a target_size_mb-=2
set /a maxrate_mb-=1

for /f "tokens=*" %%A in ('ffprobe -v error -show_entries format^=duration -of default^=noprint_wrappers^=1:nokey^=1 "%input_file%"') do set "duration=%%A"

for /f "tokens=*" %%B in ('ffprobe -v error -select_streams v:0 -show_entries stream^=bit_rate -of default^=noprint_wrappers^=1:nokey^=1 "%input_file%"') do set "orig_bitrate=%%B"

if "!duration!"=="" (
    echo [ERROR] Unable to identify file duration
    pause
    exit /b
)

if "!orig_bitrate!"=="" (
    echo [ERROR] Unable to identify original bitrate
    pause
    exit /b
)


set /a "target_bitrate=(target_size_mb * 8000000) / duration"

echo === Duration: !duration! seconds
echo === Original bitrate: !orig_bitrate! bit/s
echo === Target bitrate: !target_bitrate! bit/s

set "audio_bitrate=128k"

ffmpeg -y -i "%input_file%" -c:v !codec! -b:v !target_bitrate! -maxrate !maxrate_mb!MB -bufsize !maxrate_mb!MB -pass 1 -an -f mp4 -pix_fmt yuv420p NUL
ffmpeg -y -i "%input_file%" -c:v !codec! -b:v !target_bitrate! -maxrate !maxrate_mb!MB -bufsize !maxrate_mb!MB -pass 2 -c:a aac -b:a %audio_bitrate% "%output_file%"

del ffmpeg2pass-0.log >nul 2>&1
del ffmpeg2pass-0.log.mbtree >nul 2>&1
powershell -c "(New-Object Media.SoundPlayer '%windir%\Media\Windows Notify System Generic.wav').PlaySync()"