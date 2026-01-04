@echo off
cd android\app\src\main\res

for %%d in (mdpi xhdpi xxhdpi xxxhdpi) do (
    if exist mipmap-%%d\Milk_app.png (
        del mipmap-%%d\ic_launcher.png
        move mipmap-%%d\Milk_app.png mipmap-%%d\ic_launcher.png
    )
)

echo Icon renaming completed!
