@echo off
cd android\app\src\main\res

for %%d in (mdpi xhdpi xxhdpi xxxhdpi) do (
    if exist mipmap-%%d\Milk_app_adaptive_back.png (
        move mipmap-%%d\Milk_app_adaptive_back.png mipmap-%%d\ic_launcher_background.png
    )
    if exist mipmap-%%d\Milk_app_adaptive_fore.png (
        move mipmap-%%d\Milk_app_adaptive_fore.png mipmap-%%d\ic_launcher_foreground.png
    )
)

echo Icon renaming completed!
