setlocal enableextensions enabledelayedexpansion
set project_dir=%~f1
set test_dir=%~f2
set output_dir=%~f3
set version=%4

echo Assembling jar in post build step...
echo The project directory is "%project_dir%"
echo The test directory is "%test_dir%"
echo The output directory is "%output_dir%"
echo The version directory is "%version%"

cd "%project_dir%"
rem: TODO: add check whether javac/jar exist.
echo Building java.

if not exist "%project_dir%com\microsoft\CNTK\lib\windows" mkdir "%project_dir%com\microsoft\CNTK\lib\windows"

for %%x in (libiomp5md.dll mkl_cntk_p.dll Cntk.Math-%version%.dll Cntk.PerformanceProfiler-%version%.dll Cntk.Core-%version%.dll Cntk.Core.JavaBinding-%version%.dll) do (
  copy "%output_dir%/%%x" ".\com\microsoft\CNTK\lib\windows\%%x" 
  echo %%x>> .\com\microsoft\CNTK\lib\windows\NATIVE_MANIFEST
  echo %%x>> .\com\microsoft\CNTK\lib\windows\NATIVE_LOAD_MANIFEST
)

copy .\CNTK.java .\com\microsoft\CNTK\CNTK.java
copy .\CNTKNativeUtils.java .\com\microsoft\CNTK\CNTKNativeUtils.java

"%JAVA_HOME%\bin\javac" .\com\microsoft\CNTK\*.java || (
  echo Building Java binding failed!
  exit /B 1
)
"%JAVA_HOME%\bin\jar" -cvf cntk.jar .\com\microsoft\CNTK\* || (
  echo Creating cntk.jar failed!
  exit /B 1
)

rd com /q /s || (
  echo Deleting com directory failed!
  exit /B 1
)

rem build test projects
cd "%test_dir%JavaEvalTest"
echo Building java test projects.

"%JAVA_HOME%\bin\javac" -cp "%project_dir%cntk.jar" src\Main.java || (
  echo Building Java test project failed!
  exit /B 1
)

rem Copy java classes to output directory
echo Copy Java classes to "%output_dir%java"
if not exist "%output_dir%" (
  echo The output directory "%output_dir%" does not exist!
  exit /B 1
)
if not exist "%output_dir%java" (
  mkdir "%output_dir%java" || (
    echo Creating directory "%output_dir%java" failed!
    exit /B 1
  )
)
xcopy /Y "%project_dir%cntk.jar" "%output_dir%java\" || (
  echo Copying "%project_dir%cntk.jar" to "%output_dir%java" failed!
  exit /B 1)
xcopy /Y "%test_dir%JavaEvalTest\src\Main.class" "%output_dir%java\" || (
  echo Copying "%test_dir%JavaEvalTest\src\Main.class" to "%output_dir%java" failed!
  exit /B 1
)