@echo off
setlocal enableextensions enabledelayedexpansion
chcp 866>nul
set imf=W10_install.esd
set dir=%~d0
set ssd=Samsung
for %%i in (%imf%) do set sz=%%~zi
set sz=%sz:~5% & call :sz
for /F "Tokens=*" %%a In ('wmic.exe diskdrive where "MediaType='Fixed hard disk media' and DeviceID='\\\\.\\PHYSICALDRIVE0'" get Caption^| find /i "%ssd%" 2^> nul') Do (set mod=%%a)
set /P m=Якщо бажаєте перевiрити MD5 файлу %imf%, введiть "yes":
if /i "%m%" equ "yes" (echo.&call :md5)
:ok
Echo.&echo Для видалення всiх роздiлiв та розмiтки всього диска в GPT, натиснiть "1"
Echo Для переiнсталяцiї ProCash4 на ProCash4 (форматується тiльки диск С:), натиснiть "5"
set /P q=Ваш вибiр:
set ind=1&echo.
if "%q%"=="1" (goto one)
if "%q%"=="5" (goto five) else (goto ex)
exit
:one
for /f "usebackq delims=  tokens=*" %%i in (`@echo List Disk ^| diskpart.exe ^|findstr /r /c:"Disk"`) do (
for /f "usebackq tokens=2 delims= " %%a in (`@echo %%i ^|findstr /r /i /c:"\<0"`) do (call :p "%%a")
)
pause
Dism /apply-image /imagefile:%imf% /index:%ind% /ApplyDir:W:\ /EA /CheckIntegrity
md w:\CCF\CONF >nul
cd W:\&echo.
BCDBOOT W:\Windows /s S: /f ALL
::bcdedit /set {current} recoveryenabled no
endlocal &pause&exit
:five
if %dir:~0,1% NEQ D echo УВАГА, на диску %drv%: знайдено фотоматерiали &echo Перемiстiть %imf% i %~n0.bat на диск D: та повторно запустiть %~n0.bat & pause & exit
format c: /fs:NTFS /x /v:Windows /q /y >nul
Dism /apply-image /imagefile:%imf% /index:1 /ApplyDir:C:\ /EA /CheckIntegrity
for /f "tokens=*" %%i in ('echo list volume ^| diskpart ^| findstr /i FAT32') do (set vol=%%i)
(echo select %vol:~0,8%
echo assign letter S:) | diskpart >nul
cd /d s:\EFI\Microsoft\Boot\
del BCD
cd C:\ &echo.
BCDBOOT C:\Windows /s S: /f ALL
::bcdedit /set {current} recoveryenabled no
md C:\CCF\CONF >nul
(echo select disk 0&echo List partition)>partition.log
for /f "usebackq tokens=*" %%i in (`diskpart /s partition.log ^| findstr /i unknown`) do (set par=%%i)
del partition.log
echo Не забудьте зайти в BIOS та в пунктi Boot BBS Priorities вибрати завантаження з Samsung
if not defined par (goto ex)
(echo select disk 0&echo select %par:~0,11%&echo delete partition)|diskpart
endlocal &pause&exit
:ex
echo Exit...
endlocal &pause&exit
:sz
if %sz% neq 04980 (echo Ви використовуєте пошкоджений файл %imf% & pause & exit)
exit /b
:p
if %~1 == 0 (
(
echo select disk %~1
echo clean
echo convert gpt
echo create partition efi size=100
echo format quick fs=fat32 label="System"
echo assign letter="S"
echo create partition msr size=16
echo create partition primary size=103000
echo format quick fs=ntfs label="Windows"
echo assign letter="W"
echo create partition primary
echo shrink minimum=500
echo format quick fs=ntfs label="video"
echo assign letter="Z"
echo create partition primary size=500
echo format quick fs=ntfs label="Recovery tools"
echo assign letter="R"
echo set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
echo gpt attributes=0x8000000000000001
echo list volume
echo list par
     ) | diskpart>nul)
if defined mod ((
echo select disk %~1
echo select volume Z
echo delete volume
echo select volume W
echo extend) | diskpart)
endlocal & exit /b
:md5
echo Перевiрка %imf%... Зачекайте кiлька хвилин...
set mc=ef 0d
for /f "usebackq tokens=* eol=(" %%i in (`certutil -hashfile %imf% md5`) do (set md=%%i)
if "%mc%" EQU "%md:~0,5%" (echo.&echo Контрольна сума У ПОРЯДКУ&echo.& goto ok)
echo %md%
echo Контрольна сума не спiвпадає... ВИХIД...
pause
exit