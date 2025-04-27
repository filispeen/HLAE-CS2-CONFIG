@echo off
setlocal enabledelayedexpansion

for %%F in (%*) do (
    echo Encoding: %%F
    ffmpeg -y -hwaccel cuda -i "%%F\video.mp4" -i "%%F\audio.wav" -vcodec hevc_nvenc -map 0:v:0 -map 1:a:0 -b:a 192k -preset p5 -rc cbr -b:v 80M -maxrate 80M -minrate 80M -bufsize 80M -pix_fmt yuv444p "%%F\merged.mp4"
)

powershell -c (New-Object Media.SoundPlayer '"%windir%\Media\Windows Notify System Generic.wav"').PlaySync();
echo Everything encoded! Press any button.
pause > nul
