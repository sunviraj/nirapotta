@echo off
echo Initializing Flutter platform files...
call flutter create .

echo.
echo Installing dependencies...
call flutter pub get

echo.
echo Setup complete!
echo You can now run the app using: flutter run
pause
