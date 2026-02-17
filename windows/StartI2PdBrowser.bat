@ECHO OFF
REM Copyright (c) 2013-2026, The PurpleI2P Project
REM This file is part of Purple i2pd project and licensed under BSD3
REM See full license text in LICENSE file at top of project tree

title Starting I2Pd Browser
setlocal enableextensions

set $pause=ping.exe 0.0.0.0 -n
ver| find "6." >nul && set $pause=timeout.exe /t
ver| find "10.">nul && set $pause=timeout.exe /t
set $cd=%~dp0
set CURL=%~dp0build\curl.exe
set fire=firefox.exe
set port=FirefoxPortable.exe
set i2pd=i2pd.exe

:building
cd /d "%$cd%"
call :check_requirements || (
	echo Start building...
	pushd build
	call build.cmd --skipwait
	popd
)

taskList|find /i "%port%">nul&&(taskkill /im "%port%" /t>nul)&&(%$pause% 2 >nul)
REM taskList|find /i "%fire%">nul&&(taskkill /im "%fire%" >nul)
taskList|find /i "%i2pd%">nul&&(goto runfox)||(goto starti2p)

:starti2p
cd i2pd
start "" "%i2pd%"

echo i2pd Router starting
echo Please wait
echo -------------------------------------
set watchdog=0
:wait_i2pd
rem Checking for code 200 HTTP/OK
"%CURL%" -s -x http://127.0.0.1:4444 -w "%%{http_code}\n" -o nul http://i2pd.i2p/ | find "200" || (
	if not exist i2pd.exe (
		if "%locale%"=="ru" (
			echo Пожалуйста, нажмите ДА в окнах UAC чтобы добавить i2pd в иключения Защитника Windows
		) else (
			echo Please, press YES in UAC windows to add i2pd in Windows Defender exclusion
		)
		call :ADD_DEFENDER_EXCLUSION "%~dp0i2pd\i2pd.exe"
		call :WARN_ANTIVIRUS
		%$pause% 5
		rem We need download i2pd again
		goto building
	)
	call :EchoWithoutCrLf "." && %$pause% 1 >nul
	set /a watchdog+=1
	rem Maximum 5 minutes wait time
	if %watchdog% lss 300 goto wait_i2pd
)
echo .
echo -------------------------------------
echo Welcome to I2P Network
cd %$cd%

:runfox
cd Firefox
start "" "%port%"
cd %$cd%
%$pause% 5
exit /b 0

:check_requirements
	if not exist Firefox ( echo Firefox not found... && exit /b 1 )
	if not exist i2pd\i2pd.exe ( echo i2pd not found... && exit /b 1 )
exit /b 0

rem Предупреждает о возможном вмешательстве антивируса
rem Предлагает его отключить, открыв окно настроек Windows Defender
:WARN_ANTIVIRUS
if "%locale%"=="ru" (
	echo Ошибка запуска i2pd. Убедитесь, что Windows Defender отключен.
) else (
	echo Error running i2pd. Make sure Windows Defender is disabled.
)
explorer.exe "WindowsDefender://ThreatSettings"
goto :eof

rem Добавляет в исключения WD переданный аргументом объект (вызывает окно UAC)
rem %1 : файл для добавления в исключения Защитника Windows
:ADD_DEFENDER_EXCLUSION
powershell start -verb runas powershell -ArgumentList 'Add-MpPreference -Force -ExclusionPath "%~1"'
goto :eof

rem Процедура EchoWithoutCrLf
rem %1 : текст для вывода.
:EchoWithoutCrLf
<nul set /p strTemp=%~1
exit /b 0
