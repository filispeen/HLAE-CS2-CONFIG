@echo off
setlocal enableextensions enabledelayedexpansion
set "version=1.2.2"
set "check_updates=none"
set "codec=none"
set "RGB_RANGE=none"
set "ffmpeg_path=none"
set "inputs=none"
set "bitrate_params=-b:v 80M -maxrate 81M -minrate 79M -bufsize 80M"

if exist vars.cfg (
  set line=1
  for /f "delims=" %%L in (vars.cfg) do (
    if "!line!"=="1" set "check_updates=%%L"
    if "!line!"=="2" set "codec=%%L"
    if "!line!"=="3" set "RGB_RANGE=%%L"
    set /a line+=1
  )
) else (
  if exist vars (
    set line=1
    for /f "delims=" %%L in (vars.cfg) do (
      if "!line!"=="1" set "check_updates=%%L"
      if "!line!"=="2" set "codec=%%L"
      if "!line!"=="3" set "RGB_RANGE=%%L"
      set /a line+=1
    )
    del vars
  )
)

REM Update checker
if "!check_updates!"=="none" (
  set /p "check_updates=Do you need automated updates? (Y/N) (default: Y): "
  if /i "!check_updates!"=="" set "check_updates=Y"
  if /i "!check_updates!"=="Y" ( set "check_updates=Y" )
  if /i "!check_updates!"=="N" ( set "check_updates=N" )
  if /i "!check_updates!"=="y" ( set "check_updates=Y" )
  if /i "!check_updates!"=="n" ( set "check_updates=N" )
)

if "!check_updates!"=="Y" (
  for /f "delims=" %%A in ('curl -s https://raw.githubusercontent.com/filispeen/HLAE-CS2-CONFIG/refs/heads/main/merge.bat ^| findstr /n "^" ^| findstr "^3:"') do ( set "line=%%A" )
  for /f "tokens=2 delims==" %%A in ("!line!") do (
    set "remote_version=%%~A"
    set "remote_version=!remote_version:~0,-1!"
  )
  if "!remote_version!" NEQ "" (
    if "!version!"=="!remote_version!" (
      echo You are using the latest version !version! of script.
    ) else (
      echo A new version of script is available: !remote_version!
      echo Current version: !version!
      echo Downloading new version...
      curl -o merge.bat https://raw.githubusercontent.com/filispeen/HLAE-CS2-CONFIG/refs/heads/main/merge.bat
      cls
      echo Update complete. Restarting the script to start encoding.
      timeout /t 1 > nul
      start cmd /k merge.bat %*
      exit /b
    )
  )
)

rem Check if ffmpeg is installed
if "%ffmpeg_path%"=="none" (
  if exist "%ProgramFiles(x86)%\HLAE FFMPEG\ffmpeg\bin\ffmpeg.exe" (
    set ffmpeg_path=%ProgramFiles(x86)%
    echo Found ffmpeg at: %ffmpeg_path%
  )
  if "%ffmpeg_path%"=="none" if exist "%ProgramFiles%\HLAE FFMPEG\ffmpeg\bin\ffmpeg.exe" (
    set ffmpeg_path=%ProgramFiles%
    echo Found ffmpeg at: %ffmpeg_path%
  )
  if "%ffmpeg_path%"=="none" (
    for /f "delims=" %%A in ('where ffmpeg 2^>nul') do (
      set ffmpeg_path=%%A
      echo Found ffmpeg in PATH at: %ffmpeg_path%
    )
  )
  if "%ffmpeg_path%"=="none" (
    echo FFMPEG not found! Please install FFMPEG to merge.
    echo You can download FFMPEG from https://ffmpeg.org/download.html or use HLAE FFMPEG installer.
    echo Press any button to exit.
    powershell -c "(New-Object Media.SoundPlayer '%windir%\Media\Windows Foreground.wav').PlaySync()"
    pause > nul
    exit /b
  )
)

cls
rem first codec setup
if "!codec!"=="none" (
  echo One time quick setup:
  echo Which codec do you want to use?
  echo 1. hevc // recommended and default
  echo 2. h264 // not that eficient like hevc and av1, but compatible with everything, but doesn't matter if upload video to youtube just use hevc
  echo 3. av1 // recommended if you have a 40 or above series GPU and don't recommended on CPU
  set /p "codec=:"
  if "!codec!"=="" set "codec=hevc" 
  if "!codec!"=="1" ( set "codec=hevc" )
  if "!codec!"=="2" ( set "codec=h264" )
  if "!codec!"=="3" ( set "codec=av1" )
  echo Which GPU company are you using?
  echo 1. NVIDIA // nvenc codec
  echo 2. AMD // amf codec
  echo 3. Intel // qsv codec
  echo 4. don't have a GPU // cpu codec, default
  set /p "HW=:"
  if /i "!HW!"=="" set "HW=4"
  if "!HW!"=="1" ( set "HW=nvenc" )
  if "!HW!"=="2" ( set "HW=amf" )
  if "!HW!"=="3" ( set "HW=qsv" )
  if "!HW!" NEQ "4" ( set "codec=!codec!_!HW!" )
)
cls
if "!RGB_RANGE!"=="none" (
  echo "Do you want to use FULL RGB RANGE(yuv444p)? (Y/N) (default: Y):
  set /p "RGB_RANGE=:"
  if /i "!RGB_RANGE!"=="" set "RGB_RANGE=Y"
  if /i "!RGB_RANGE!"=="Y" ( set "RGB_RANGE=yuv444p" )
  if /i "!RGB_RANGE!"=="N" ( set "RGB_RANGE=yuv420p" )
  if /i "!RGB_RANGE!"=="y" ( set "RGB_RANGE=yuv444p" )
  if /i "!RGB_RANGE!"=="n" ( set "RGB_RANGE=yuv420p" )
)

if not exist vars.cfg ( 
echo %check_updates% >> vars.cfg
echo %codec% >> vars.cfg
echo %RGB_RANGE% >> vars.cfg
)

if not exist merged_movies mkdir merged_movies
cls

REM Video and audio merger
if "%*"=="" (
  echo You NEED to drag and drop folder with your video and audio files into batch file. Press any button to exit.
  powershell -c "(New-Object Media.SoundPlayer '%windir%\Media\Windows Foreground.wav').PlaySync()"
  pause > nul
  exit /b
)
for %%F in (%*) do ( echo Encoding: %%F
  if "%codec%"=="hevc_nvenc" ( 
    set "inputs=-hwaccel cuda -i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset p5" 
  ) 
  if "%codec%"=="h264_nvenc" ( 
    set "inputs=-hwaccel cuda -i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset p5" 
  )
  if "%codec%"=="hevc_amf" ( 
    set "inputs=-i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset 5" 
  )
  if "%codec%"=="h264_amf" ( 
    set "inputs=-i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset 5" 
  )
  if "%codec%"=="hevc_qsv" ( 
    set "inputs=-i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset 4" 
  ) 
  if "%codec%"=="h264_qsv" ( 
    set "inputs=-i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset 4" 
  )
  if "%codec%"=="hevc" ( 
    set "inputs=-i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset 5" 
  )
  if "%codec%"=="h264" ( 
    set "inputs=-i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset 5" 
  )
  if "%codec%"=="libsvtav1" ( 
    set "inputs=-i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset 6" 
    set "bitrate_params=-b:v 10M -maxrate 10M -bufsize 10M" 
  )
  if "%codec%"=="av1_nvenc" ( 
    set "inputs=-i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset 6" 
    set "bitrate_params=-b:v 10M -maxrate 10M -bufsize 10M" 
  )
  if "%codec%"=="av1_amf" ( 
    set "inputs=-i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset 6" 
    set "bitrate_params=-b:v 10M -maxrate 10M -bufsize 10M" 
  )
  if "%codec%"=="av1_qsv" ( 
    set "inputs=-i "%%F\video.mp4" -i "%%F\audio.wav" -c:v %codec% -preset 6" 
    set "bitrate_params=-b:v 10M -maxrate 10M -bufsize 10M" 
  )
  echo Inputs: %inputs%
  for %%A in ("%%F") do ( set "foldername=%%~nxA" )
  for %%B in ("%ffmpeg_path%") do ( 
    if "%%~nxB"=="ffmpeg.exe" ( "%ffmpeg_path%" -y -hide_banner !inputs! -map 0:v:0 -map 1:a:0 -b:a 192k %bitrate_params% -pix_fmt %RGB_RANGE% "%%F\..\merged_movies\!foldername!.mp4"
    ) else ( "%ffmpeg_path%)\HLAE FFMPEG\ffmpeg\bin\ffmpeg.exe" -y -hide_banner !inputs! -map 0:v:0 -map 1:a:0 -b:a 192k %bitrate_params% -pix_fmt %RGB_RANGE% "%%F\..\merged_movies\!foldername!.mp4"
    )
  )
)
endlocal
echo Everything encoded! Press any button.
powershell -c "(New-Object Media.SoundPlayer '%windir%\Media\Windows Notify System Generic.wav').PlaySync()"
pause > nul
exit