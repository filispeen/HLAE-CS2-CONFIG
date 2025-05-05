@echo off
setlocal enableextensions enabledelayedexpansion
set "version=1.1.0"
set "ffmpeg_path=none"
set "winget_path=none"
set "check_updates=none"

if exist vars (
  set line=1
  for /f "delims=" %%L in (vars) do (
    if "!line!"=="1" set "check_updates=%%L"
    if "!line!"=="2" set "ffmpeg_path=%%L"
    set /a line+=1
  )
if not exist !ffmpeg_path! ( 
  set "ffmpeg_OLD_path=!ffmpeg_path!" 
  set "ffmpeg_path=none" 
  )
)


REM Update checker
if "!check_updates!"=="none" (
  powershell -c "(New-Object Media.SoundPlayer '%windir%\Media\Windows Foreground.wav').PlaySync()"
  set /p "check_updates=Do you need automated updates? (Y/N) (default: Y): "
  if /i "!check_updates!"=="" set "check_updates=Y"
  if /i "!check_updates!"=="Y" ( set "check_updates=Y" )
  if /i "!check_updates!"=="N" ( set "check_updates=N" )
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
if "!ffmpeg_path!"=="none" (
  if exist "%ProgramFiles(x86)%\HLAE FFMPEG\ffmpeg\bin\ffmpeg.exe" (
    set "ffmpeg_path=%ProgramFiles(x86)%\HLAE FFMPEG\ffmpeg\bin\ffmpeg.exe"
  )
  
  if "!ffmpeg_path!"=="none" if exist "%ProgramFiles%\HLAE FFMPEG\ffmpeg\bin\ffmpeg.exe" (
    set "ffmpeg_path=%ProgramFiles%\HLAE FFMPEG\ffmpeg\bin\ffmpeg.exe"
  )

  if "!ffmpeg_path!"=="none" ( for /f "delims=" %%A in ('where ffmpeg') do ( set "ffmpeg_path=%%A" ) )

  if "!ffmpeg_path!"=="none" (
    powershell -c "(New-Object Media.SoundPlayer '%windir%\Media\Windows Foreground.wav').PlaySync()"
    set /p "QA=Ffmpeg not found. Have you installed ffmpeg in HLAE installer? (Y/N) (default: Y): "
    if /i "!QA!"=="" set "QA=Y"
    if /i "!QA!"=="Y" (
      set /p "QA=Have you installed ffmpeg in custom path? (Y/N) (default: Y): "
      if /i "!QA!"=="" set "QA=Y"
      if /i "!QA!"=="Y" (
        echo Please enter path to ffmpeg.exe or folder with ffmpeg.exe in it:
        set /p "ffmpeg_path=:"
        if not exist "!ffmpeg_path!" (
          if not exist "!ffmpeg_path!\ffmpeg.exe" (
            if not exist "!ffmpeg_path!\bin\ffmpeg.exe" (
              echo ffmpeg not found. Please install ffmpeg and add it to your PATH.
              echo Press any button to exit.
              pause > nul
              exit
              ) else ( set "ffmpeg_path=!ffmpeg_path!\bin\ffmpeg.exe" )
            ) else ( set "ffmpeg_path=!ffmpeg_path!\ffmpeg.exe" ) )
        ) else (
            set /p "QA=Do you want to auto install ffmpeg? (Y/N) (default: Y): "
            if /i "!QA!"=="" set "QA=Y"
            if /i "!QA!"=="Y" (
              for /f "delims=" %%A in ('where winget') do ( set "winget_path=%%A" )
              if "!winget_path!"=="none" (
                curl -L -s -o winget.msixbundle https://aka.ms/getwinget
                powershell -ExecutionPolicy Bypass -c "Add-AppxPackage winget.msixbundle"
                del winget.msixbundle
                start cmd /k "!winget_path! install ffmpeg --silent --accept-source-agreements --accept-package-agreements --id GyanDude.FFmpeg --source winget"
                echo ffmpeg installed. Restarting script to start encoding.
                timeout /t 1 > nul
                start cmd /k merge.bat %*
              ) else (
                echo Installing ffmpeg...
                start cmd /k "!winget_path! install ffmpeg --silent --accept-source-agreements --accept-package-agreements --id GyanDude.FFmpeg --source winget"
                echo ffmpeg installed. Restarting script to start encoding.
                timeout /t 1 > nul
                start cmd /k merge.bat %*
              )
            )
          )
      if /i "!QA!"=="N" (
        set /p "QA=Do you want to auto install ffmpeg? (Y/N) (default: Y): "
        if /i "!QA!"=="" set "QA=Y"
        if /i "!QA!"=="Y" (
          for /f "delims=" %%A in ('where winget') do ( set "winget_path=%%A")
          if "!winget_path!"=="none" (
            curl -L -s -o winget.msixbundle https://aka.ms/getwinget
            powershell -ExecutionPolicy Bypass -c "Add-AppxPackage winget.msixbundle"
            del winget.msixbundle
            start cmd /k "!winget_path! install ffmpeg --silent --accept-source-agreements --accept-package-agreements --id GyanDude.FFmpeg --source winget"
            echo ffmpeg installed. Restarting script to start encoding.
            timeout /t 1 > nul
            start cmd /k merge.bat %*
          ) else (
            echo Installing ffmpeg...
            start cmd /k "!winget_path! install ffmpeg --silent --accept-source-agreements --accept-package-agreements --id GyanDude.FFmpeg --source winget"
            echo ffmpeg installed. Restarting script to start encoding.
            timeout /t 1 > nul
            start cmd /k merge.bat %*
          )
        )
        if /i "!QA!"=="N" (
          echo Then go and install ffmpeg all by yourself. I will not help you.
          echo Or install ffmpeg using HLAE installer, and run script again.
          echo Press any button to exit.
          pause > nul
          exit
        )
      )
    if /i "!QA!"=="N" (
      set /p "QA=Do you want to auto install ffmpeg? (Y/N) (default: Y): "
        if /i "!QA!"=="" set "QA=Y"
        if /i "!QA!"=="Y" (
          for /f "delims=" %%A in ('where winget') do ( set "winget_path=%%A")
          if "!winget_path!"=="none" (
            curl -L -s -o winget.msixbundle https://aka.ms/getwinget
            powershell -ExecutionPolicy Bypass -c "Add-AppxPackage winget.msixbundle"
            del winget.msixbundle
            start cmd /k "!winget_path! install ffmpeg --silent --accept-source-agreements --accept-package-agreements --id GyanDude.FFmpeg --source winget"
            echo ffmpeg installed. Restarting script to start encoding.
            timeout /t 1 > nul
            start cmd /k merge.bat %*
          ) else (
            echo Installing ffmpeg...
            start cmd /k "!winget_path! install ffmpeg --silent --accept-source-agreements --accept-package-agreements --id GyanDude.FFmpeg --source winget"
            echo ffmpeg installed. Restarting script to start encoding.
            timeout /t 1 > nul
            start cmd /k merge.bat %*
          )
        )
        if /i "!QA!"=="N" (
          echo Then go and install ffmpeg all by yourself. I will not help you.
          echo Or install ffmpeg using HLAE installer, and run script again.
          echo Press any button to exit.
          pause > nul
          exit
        )
    )
    )
  )
)

if "!ffmpeg_path!" NEQ "!ffmpeg_OLD_path!" ( del vars )
echo %check_updates% >> vars
echo %ffmpeg_path% >> vars

cls
REM Video and audio merger
if "%~1"=="" (
  echo You NEED to drag and drop folder with your video and audio files into batch file. Press any button to exit.
  powershell -c "(New-Object Media.SoundPlayer '%windir%\Media\Windows Foreground.wav').PlaySync()"
  pause > nul
  exit /b
)
for %%F in (%*) do ( echo Encoding: %%F
  rem Check if %%F is actually a folder
  rem if not exist "%%F\" (
  rem   echo You are supposed to drag and drop a folder, not files like video.mp4 or audio.wav.
  rem   timeout /t 1 > nul
  rem )
  rem rem Check if required files exist
  rem if not exist "%%F\video.mp4" (
  rem   echo Video file not found in %%F. Skipping folder.
  rem   timeout /t 1 > nul
  rem )
  rem if not exist "%%F\audio.wav" (
  rem   echo Audio file not found in %%F. Skipping folder.
  rem   timeout /t 1 > nul
  rem )
  "%ffmpeg_path%" -y -hide_banner -hwaccel cuda -i "%%F\video.mp4" -i "%%F\audio.wav" -vcodec hevc_nvenc -map 0:v:0 -map 1:a:0 -b:a 192k -preset p5 -rc cbr -b:v 80M -maxrate 80M -minrate 70M -bufsize 80M -pix_fmt yuv444p "%%F\merged.mp4"
  for %%A in ("%%F") do (
    set "foldername=%%~nxA"
    rem set "folderpath=%%~dpA"
    set "suffix=!foldername:~-7!"
    if /I not "!suffix!"=="_merged" (
      set "newname=!foldername!_merged"
      ren "%%F" "!newname!"
    )
  )
)
endlocal
echo Everything encoded! Press any button.
powershell -c "(New-Object Media.SoundPlayer '%windir%\Media\Windows Notify System Generic.wav').PlaySync()"
pause > nul
exit
