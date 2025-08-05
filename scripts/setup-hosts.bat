@echo off
:: YTEmpire Hosts File Setup Script
:: Run as Administrator

echo Setting up YTEmpire local domains...

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: Backup hosts file
echo Backing up hosts file...
copy %WINDIR%\System32\drivers\etc\hosts %WINDIR%\System32\drivers\etc\hosts.backup.%date:~-4,4%%date:~-10,2%%date:~-7,2%

:: Add YTEmpire entries
echo.
echo Adding YTEmpire domains to hosts file...

:: Check if entries already exist
findstr /C:"ytempire.local" %WINDIR%\System32\drivers\etc\hosts >nul
if %errorlevel% equ 0 (
    echo YTEmpire entries already exist in hosts file.
) else (
    echo. >> %WINDIR%\System32\drivers\etc\hosts
    echo # YTEmpire Local Development >> %WINDIR%\System32\drivers\etc\hosts
    echo 127.0.0.1    ytempire.local >> %WINDIR%\System32\drivers\etc\hosts
    echo 127.0.0.1    api.ytempire.local >> %WINDIR%\System32\drivers\etc\hosts
    echo 127.0.0.1    pgadmin.ytempire.local >> %WINDIR%\System32\drivers\etc\hosts
    echo 127.0.0.1    mailhog.ytempire.local >> %WINDIR%\System32\drivers\etc\hosts
    echo # End YTEmpire >> %WINDIR%\System32\drivers\etc\hosts
    echo Entries added successfully!
)

:: Flush DNS cache
echo.
echo Flushing DNS cache...
ipconfig /flushdns

echo.
echo Setup complete! You can now access:
echo   - Application: http://ytempire.local
echo   - API: http://api.ytempire.local
echo   - pgAdmin: http://pgadmin.ytempire.local
echo   - MailHog: http://mailhog.ytempire.local
echo.
pause