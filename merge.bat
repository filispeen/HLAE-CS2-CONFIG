@echo off
setlocal enabledelayedexpansion
set "version=1.0.0"

if "%~1"=="" (
    echo You need to drag and drop folder with your video and audio files into batch file. Press any button to exit.
    powershell -c "(New-Object Media.SoundPlayer '%windir%\Media\Windows Foreground.wav').PlaySync()"
    pause > nul
    exit
)
for %%F in (%*) do (
    echo Encoding: %%F
    ffmpeg -y -hide_banner -hwaccel cuda -i "%%F\video.mp4" -i "%%F\audio.wav" -vcodec hevc_nvenc -map 0:v:0 -map 1:a:0 -b:a 192k -preset p5 -rc cbr -b:v 80M -maxrate 80M -minrate 70M -bufsize 80M -pix_fmt yuv444p "%%F\merged.mp4"

    for %%A in ("%%F") do (
        set "foldername=%%~nxA"
        set "folderpath=%%~dpA"
        
        REM Check if foldername ends with _merged
        set "suffix=!foldername:~-7!"
        if /I not "!suffix!"=="_merged" (
            set "newname=!foldername!_merged"
            echo Renaming "!foldername!" to "!newname!"
            ren "%%F" "!newname!"
        )
    )
)
endlocal

echo Everything encoded! Press any button.
powershell -c "(New-Object Media.SoundPlayer '%windir%\Media\Windows Notify System Generic.wav').PlaySync()"
pause > nul
