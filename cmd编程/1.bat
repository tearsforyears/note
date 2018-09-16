@echo off
echo hello world
title test_title
::call:sum 1000 ::求前1000个数的和
::call :fab 10
pause>nul

:fab
set a=1
for /l %%i in (1,1,%1) do (
set /a a*=%%i
)
echo %a%
exit /b 0::return

:sum
set a=0
for /l %%i in (1,1,%1) do (
set /a a+=%%i
)
echo %a%
exit /b 0::return

:fun1
echo this is a plus function
set /a c=%1+%2
echo %c%
exit /b 0::return

:sleep
ping -n %1 127.0.0.1>nul
exit /b 0::return

::Danger code
::shutdown
::0%|%0
::exit /b 0