@echo off

rem compile.bat

TITLE Compile Gamemode
COLOR 07


:begin

"..\pawno\pawncc.exe" "greekroleplay.pwn"

echo Finished

rem pause

rem timeout 3

set /p DUMMY=Hit ENTER to continue...
CLS
goto begin
