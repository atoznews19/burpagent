@echo off
setlocal enabledelayedexpansion

REM ====================================================================
REM  BurpAgent - build without Gradle (uses javac directly)
REM  Downloads Montoya API + Gson, compiles, packages a loadable .jar
REM ====================================================================

set LIB=lib
set BUILD=build
set CLASSES=%BUILD%\classes
set JAR=%BUILD%\burpagent.jar
set MONTOYA=montoya-api-2025.5.jar
set GSON=gson-2.11.0.jar

REM --- Download dependencies if missing ---
if not exist %LIB% mkdir %LIB%

if not exist %LIB%\%MONTOYA% (
    echo Downloading Montoya API...
    powershell -Command "Invoke-WebRequest -Uri 'https://repo1.maven.org/maven2/net/portswigger/burp/extensions/montoya-api/2025.5/%MONTOYA%' -OutFile '%LIB%\%MONTOYA%'"
)

if not exist %LIB%\%GSON% (
    echo Downloading Gson...
    powershell -Command "Invoke-WebRequest -Uri 'https://repo1.maven.org/maven2/com/google/code/gson/gson/2.11.0/%GSON%' -OutFile '%LIB%\%GSON%'"
)

REM --- Clean ---
if exist %BUILD% rmdir /s /q %BUILD%
mkdir %CLASSES%

REM --- Collect source files ---
set SOURCES=
for /r src %%f in (*.java) do set SOURCES=!SOURCES! %%f

REM --- Compile ---
echo Compiling...
javac -cp "%LIB%\%MONTOYA%;%LIB%\%GSON%" -d %CLASSES% %SOURCES%
if errorlevel 1 (
    echo Compilation failed.
    exit /b 1
)

REM --- Bundle Gson into the jar (Montoya is provided by Burp at runtime) ---
echo Packaging...
pushd %CLASSES%
jar xf ..\..\%LIB%\%GSON%
jar cf ..\burpagent.jar .
popd

echo.
echo Build complete: %JAR%
echo Load it via Burp -^> Extensions -^> Installed -^> Add -^> select %JAR%
