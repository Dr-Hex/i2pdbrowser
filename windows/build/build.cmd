@echo off

REM Copyright (c) 2013-2026, The PurpleI2P Project
REM This file is part of Purple i2pd project and licensed under BSD3
REM See full license text in LICENSE file at top of project tree

setlocal enableextensions

set CURL=%~dp0curl.exe
set FFversion=115.20.0esr
set I2Pdversion=2.59.0

call :GET_ARGS %*
call :GET_LOCALE
call :GET_PROXY
call :GET_ARCH

if "%locale%"=="ru" (
	echo Сборка I2Pd Browser Portable
	echo Язык браузера: %locale%, архитектура: %xOS%
) else (
	echo Building I2Pd Browser Portable
	echo Browser locale: %locale%, architecture: %xOS%
)
echo.

if exist ..\Firefox (
	if "%locale%"=="ru" (
		echo Firefox уже скачан. Пропускаю.
	) else (
		echo Firefox already downloaded. Skip.
	)
	goto GET_I2PD
)

if "%locale%"=="ru" (
	echo Загрузка установщика Firefox ESR
) else (
	echo Downloading Firefox ESR installer
)
call :DOWNLOAD firefox.exe https://ftp.mozilla.org/pub/firefox/releases/%FFversion%/%xOS%/%locale%/Firefox%%%%20Setup%%%%20%FFversion%.exe

echo.
if "%locale%"=="ru" (
	echo Распаковка установщика и удаление не нужных файлов
) else (
	echo Unpacking the installer and deleting unnecessary files
)

7z x -y -o..\Firefox\App firefox.exe > nul
del /Q firefox.exe
ren ..\Firefox\App\core Firefox
del /Q ..\Firefox\App\setup.exe
del /Q ..\Firefox\App\Firefox\browser\crashreporter-override.ini
rmdir /S /Q ..\Firefox\App\Firefox\browser\features
rmdir /S /Q ..\Firefox\App\Firefox\gmp-clearkey
rmdir /S /Q ..\Firefox\App\Firefox\uninstall
del /Q ..\Firefox\App\Firefox\Accessible*.*
del /Q ..\Firefox\App\Firefox\application.ini
del /Q ..\Firefox\App\Firefox\crashreporter.*
del /Q ..\Firefox\App\Firefox\*.sig
del /Q ..\Firefox\App\Firefox\maintenanceservice*.*
del /Q ..\Firefox\App\Firefox\minidump-analyzer.exe
del /Q ..\Firefox\App\Firefox\precomplete
del /Q ..\Firefox\App\Firefox\removed-files
del /Q ..\Firefox\App\Firefox\ucrtbase.dll
del /Q ..\Firefox\App\Firefox\update*.*

mkdir ..\Firefox\App\Firefox\browser\extensions > nul
echo OK!

echo.
if "%locale%"=="ru" (
	echo Патчим внутренние файлы браузера для отключения навязчивых запросов
) else (
	echo Patching browser internal files to disable annoying external requests
)

7z -bso0 -y x ..\Firefox\App\Firefox\omni.ja -o..\Firefox\App\tmp > nul 2>&1

REM Patching them
sed -i "s/https\:\/\/firefox\.settings\.services\.mozilla\.com\/v1/http\:\/\/127\.0\.0\.1/" ..\Firefox\App\tmp\modules\SearchUtils.sys.mjs
if errorlevel 1 ( echo ERROR:%ErrorLevel% && pause && exit ) else (echo Patched 1/2)
sed -i "s/\"https\:\/\/firefox\.settings\.services\.mozilla\.com\/v1\",$/\"\",/" ..\Firefox\App\tmp\modules\AppConstants.sys.mjs
if errorlevel 1 ( echo ERROR:%ErrorLevel% && pause && exit ) else (echo Patched 2/2)

REM Backing up old omni.ja
ren ..\Firefox\App\Firefox\omni.ja omni.ja.bak

REM Repacking patched files
7z a -mx0 -tzip ..\Firefox\App\Firefox\omni.ja -r ..\Firefox\App\tmp\* > nul

REM Removing temporary files
rmdir /S /Q ..\Firefox\App\tmp
del ..\Firefox\App\Firefox\omni.ja.bak
echo OK!

echo.
if "%locale%"=="ru" (
	echo Загрузка языковых пакетов
) else (
	echo Downloading language packs
)
call :DOWNLOAD ..\Firefox\App\Firefox\browser\extensions\langpack-ru@firefox.mozilla.org.xpi https://addons.mozilla.org/firefox/downloads/file/4144376/russian_ru_language_pack-115.0.20230726.201356.xpi
call :DOWNLOAD ..\Firefox\App\Firefox\browser\extensions\ruspell-wiktionary@addons.mozilla.org.xpi https://addons.mozilla.org/firefox/downloads/file/4215701/2696307-1.77.xpi
call :DOWNLOAD ..\Firefox\App\Firefox\browser\extensions\langpack-en-US@firefox.mozilla.org.xpi https://addons.mozilla.org/firefox/downloads/file/4144407/english_us_language_pack-115.0.20230726.201356.xpi
call :DOWNLOAD ..\Firefox\App\Firefox\browser\extensions\en-US@dictionaries.addons.mozilla.org.xpi https://addons.mozilla.org/firefox/downloads/file/4175230/us_english_dictionary-115.0.xpi

echo.
if "%locale%"=="ru" (
	echo Загрузка дополнения NoScript
) else (
	echo Downloading NoScript extension
)
call :DOWNLOAD ..\Firefox\App\Firefox\browser\extensions\{73a6fe31-595d-460b-a920-fcc0f8843232}.xpi https://addons.mozilla.org/firefox/downloads/file/4411102/noscript-12.1.1.xpi

echo.
if "%locale%"=="ru" (
	echo Копирование файлов настроек в папку Firefox
) else (
	echo Copying Firefox launcher and settings
)
mkdir ..\Firefox\App\DefaultData\profile\ > nul
xcopy /E /Y profile\* ..\Firefox\App\DefaultData\profile\ > nul
if "%locale%"=="ru" (
	copy /Y profile-ru\* ..\Firefox\App\DefaultData\profile\ > nul
) else (
	copy /Y profile-en\* ..\Firefox\App\DefaultData\profile\ > nul
)
copy /Y firefox-portable\* ..\Firefox\ > nul
xcopy /E /Y preferences\* ..\Firefox\App\Firefox\ > nul
echo OK!

:GET_I2PD
echo.
mkdir "..\i2pd" 2>nul
for %%i in ("%cd%\..\i2pd") do set i2pd_path=%%~fi\i2pd.exe

if "%locale%"=="ru" (
	echo Загрузка I2Pd
) else (
	echo Downloading I2Pd
)
call :DOWNLOAD i2pd_%I2Pdversion%_%xOS%_mingw.zip https://github.com/PurpleI2P/i2pd/releases/download/%I2Pdversion%/i2pd_%I2Pdversion%_%xOS%_mingw.zip
7z x -y -o..\i2pd i2pd_%I2Pdversion%_%xOS%_mingw.zip i2pd.exe > nul || (
	echo ERROR:%ErrorLevel%
	if "%locale%"=="ru" (
		echo Пожалуйста, нажмите ДА в окнах UAC чтобы добавить i2pd в иключения Защитника Windows
	) else (
		echo Please, press YES in UAC windows to add i2pd in Windows Defender exclusion
	)
	call :ADD_DEFENDER_EXCLUSION "%cd%\i2pd_%I2Pdversion%_%xOS%_mingw.zip"
	call :ADD_DEFENDER_EXCLUSION "%i2pd_path%"
	call :WARN_ANTIVIRUS
	%$pause% 5
	goto GET_I2PD
)
del /Q i2pd_%I2Pdversion%_%xOS%_mingw.zip

xcopy /E /I /Y i2pd ..\i2pd > nul

echo.
if "%locale%"=="ru" (
	echo I2Pd Browser Portable готов к запуску!
) else (
	echo I2Pd Browser Portable is ready to start!
)
if not defined arg_skipwait pause
exit /b

:GET_LOCALE
for /f "tokens=3" %%a in ('reg query "HKEY_USERS\.DEFAULT\Keyboard Layout\Preload"^|find "REG_SZ"') do (
	if %%a==00000419 (set locale=ru) else (set locale=en-US)
	goto :eof
)
goto :eof

:GET_PROXY
set $X=&set $R=HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings
for /F "Tokens=1,3" %%i in ('reg query "%$R%"^|find "Proxy"') do set %%i=%%j
if %ProxyEnable%==0x1 set $X=-x %ProxyServer%
goto :eof

:GET_ARCH
set xOS=win32
if defined PROCESSOR_ARCHITEW6432 (set xOS=win64) else if "%PROCESSOR_ARCHITECTURE%" neq "x86" (set xOS=win64)
goto :eof

:GET_ARGS
set arg_skipwait=
for %%a in (%*) do (
	if "%%a"=="--skipwait" set arg_skipwait=yes
)
goto :eof

rem Процедура скачивания файла с бесконечным повтором в случае неудачи
rem %1 : путь к файлу для сохранения
rem %2 : URL адрес 
:DOWNLOAD
if "%locale%"=="ru" (
	echo Загружаю URL: %2
) else (
	echo Downloading URL: %2
)
"%CURL%" -k -L -f -# -o "%1" "%2" %$X% || (
	echo ERROR:%ErrorLevel%
	if "%locale%"=="ru" (
		echo Попытка повторного скачивания
	) else (
		echo Attempt downloading again
	)
	%$pause% 5
	goto DOWNLOAD
)
echo OK!
goto :eof

rem Предупреждает о возможном вмешательстве антивируса
rem Предлагает его отключить, открыв окно настроек Windows Defender
:WARN_ANTIVIRUS
if "%locale%"=="ru" (
	echo Ошибка распаковки i2pd. Убедитесь, что Windows Defender отключен.
) else (
	echo Error unpacking i2pd. Make sure Windows Defender is disabled.
)
explorer.exe "WindowsDefender://ThreatSettings"
goto :eof

rem Добавляет в исключения WD переданный аргументом объект (вызывает окно UAC)
rem %1 : файл для добавления в исключения Защитника Windows
:ADD_DEFENDER_EXCLUSION
powershell start -verb runas powershell -ArgumentList 'Add-MpPreference -Force -ExclusionPath "%~1"'
goto :eof

:eof
