@echo off
setlocal enabledelayedexpansion

:: Assumption Android Studio is installed for current user only:
if not defined ANDROID_HOME (
	if exist "%USERPROFILE%\AppData\Local\Android\Sdk" (
        set ANDROID_HOME=%USERPROFILE%\AppData\Local\Android\Sdk
	)
)

if not defined ANDROID_HOME (
	echo Install Android Studio or Android SDK
	exit /b 1
)

:: Java JDR/JRE is expected here:
:: C:\Program Files\Android\Android Studio\jbr\bin
:: C:\Program Files\Java\jdk-21\bin

if not defined JAVA_HOME (
    if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\javac.exe" (
        set JAVA_HOME=%ProgramFiles%\Android\Android Studio\jbr
	)
)

if not defined JAVA_HOME (
    if exist "%ProgramFiles%\Java\jdk-21\bin\javac.exe" (
        set JAVA_HOME=%ProgramFiles%\Java\jdk-21
	)
)

if not defined JAVA_HOME (
	echo "Install JDK-21"
	echo "https://www.oracle.com/java/technologies/downloads/#jdk21-windows"
	echo "or https://jdk.java.net/21/"
	exit /b 1
)

:: change next line to reflect where Android SDK is installed.
:: IMPORTANT: both ":" and "\" must be escaped with "\"
:: expected content of local.properties file is:
:: sdk.dir=C\:\\Users\\%username%\\AppData\\Local\\Android\\Sdk
if not exist local.properties (
    set ANDROID_HOME_ESCAPED=!ANDROID_HOME:\=\\!
    set ANDROID_HOME_ESCAPED=!ANDROID_HOME_ESCAPED::=\:!
    > local.properties echo sdk.dir=!ANDROID_HOME_ESCAPED!
)

:: Could not compile settings file settings.gradle
:: Unsupported class file major version 65
::
:: https://stackoverflow.com/questions/67079327/how-can-i-fix-unsupported-class-file-major-version-60-in-intellij-idea
::
:: Java SE 22 = 66,
:: Java SE 21 = 65,
:: Java SE 20 = 64,
:: ..
:: Java SE 9 = 53,
:: Java SE 8 = 52,
::
:: see:
:: https://services.gradle.org/distributions/

:: **project array declaration (no true arrays in batch)**
set projects=native-activity other-builds\ndkbuild\bitmap-plasma other-builds\ndkbuild\gles3jni other-builds\ndkbuild\hello-gl2

:: **array of APK paths**
set apks=native-activity\app\build\outputs\apk\debug\app-debug.apk other-builds\ndkbuild\bitmap-plasma\app\build\outputs\apk\debug\app-debug.apk other-builds\ndkbuild\gles3jni\app\build\outputs\apk\debug\app-debug.apk other-builds\ndkbuild\hello-gl2\app\build\outputs\apk\debug\app-debug.apk

:: **Set temp file names**
set LINT_FAILURES=%TEMP%\lint_failures.txt
set BUILD_FAILURES=%TEMP%\build_failures.txt
set APK_FAILURES=%TEMP%\apk_failures.txt

:: **Mimic verbosity checking** 
if defined RUNNER_DEBUG (
    set VERBOSITY=--info
) else (
    set VERBOSITY=--quiet
)

:: Copy local.properties to each project directory
for %%d in (%projects%) do (
    if not exist "%%dd\local.properties" (
	    @copy /Y local.properties %%d > nul
	)
)

:: **Iteration and building logic**
for %%d in (%projects%) do (
    pushd %%d >nul
    echo Building %%d
    if errorlevel 1 (
       set SAMPLE_CI_RESULT=1
       echo %%d >> %LINT_FAILURES% 
    )
    call gradlew %VERBOSITY% assembleDebug
    if errorlevel 1 (
       set SAMPLE_CI_RESULT=1
       echo %%d >> %BUILD_FAILURES%
    )
    popd >nul
)

:: **Checking which APKs built correctly**
for %%a in (%apks%) do (
    if not exist %%a (
        set SAMPLE_CI_RESULT=1
        echo %%a >> %APK_FAILURES%
    )
)

:: **Error Reporting**
if exist %LINT_FAILURES% (
    echo
    echo ******* Lint failures ********
    type %LINT_FAILURES%
)

if exist %BUILD_FAILURES% (
    echo 
    echo ******* Build failures ********
    type %BUILD_FAILURES%
)

if exist %APK_FAILURES% (
    echo
    echo ******* Missing APKs ********
    type %APK_FAILURES%
)

:: **Success/Cleanup**
if not exist %LINT_FAILURES% if not exist %BUILD_FAILURES% if not exist %APK_FAILURES% (
    echo 
    echo ======= BUILD SUCCESS ======
)
del %LINT_FAILURES% %BUILD_FAILURES% %APK_FAILURES%

