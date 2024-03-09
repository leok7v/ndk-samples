@echo off

:: Could not compile settings file settings.gradle
:: Unsupported class file major version 65
::
:: https://stackoverflow.com/questions/67079327/how-can-i-fix-unsupported-class-file-major-version-60-in-intellij-idea
::
:: Java SE 22 = 66,
:: Java SE 21 = 65,
:: Java SE 20 = 64,
:: Java SE 19 = 63,
:: Java SE 18 = 62,
:: Java SE 17 = 61,
:: Java SE 16 = 60, 
:: Java SE 15 = 59,
:: Java SE 14 = 58,
:: Java SE 13 = 57,
:: Java SE 12 = 56,
:: Java SE 11 = 55,
:: Java SE 10 = 54,
:: Java SE 9 = 53,
:: Java SE 8 = 52,
:: Java SE 7 = 51,
:: Java SE 6.0 = 50,
:: Java SE 5.0 = 49,
:: JDK 1.4 = 48,
:: JDK 1.3 = 47,
:: JDK 1.2 = 46,
:: JDK 1.1 = 45
::
:: see:
:: https://services.gradle.org/distributions/

:: **Mimic project array declaration (no true arrays in batch)**
set projects=native-activity other-builds\ndkbuild\bitmap-plasma other-builds\ndkbuild\gles3jni other-builds\ndkbuild\hello-gl2

:: **Mimic array of APK paths**
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

:: **Iteration and building logic**
for %%d in (%projects%) do (
    pushd %%d >nul
    echo Building %%d

    :: Note: TERM=dumb might not have a direct equivalent
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
