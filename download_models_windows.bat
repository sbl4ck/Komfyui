@echo off
rem Downloads the models used by the Anima and NetaYume Lumina text to image workflows.
rem Run install_windows_amd.bat first so the venv exists.
setlocal
cd /d "%~dp0"

if not exist venv\Scripts\python.exe (
    echo venv not found. Run install_windows_amd.bat first.
    exit /b 1
)
if not exist venv\Scripts\hf.exe (
    venv\Scripts\python.exe -m pip install -U "huggingface_hub[hf_xet]" || exit /b 1
)

set HF_XET_HIGH_PERFORMANCE=1
set TMP_DIR=models\.hf_download

rem Anima
call :get circlestone-labs/Anima split_files/diffusion_models/anima-base-v1.0.safetensors diffusion_models || exit /b 1
call :get circlestone-labs/Anima split_files/text_encoders/qwen_3_06b_base.safetensors text_encoders || exit /b 1
call :get circlestone-labs/Anima split_files/vae/qwen_image_vae.safetensors vae || exit /b 1

rem NetaYume Lumina
call :get duongve/NetaYume-Lumina-Image-2.0 NetaYumev35_pretrained_all_in_one.safetensors checkpoints || exit /b 1

if exist %TMP_DIR% rmdir /s /q %TMP_DIR%
echo.
echo All models downloaded.
endlocal
exit /b 0

rem :get <repo> <file in repo> <models subfolder>
:get
set "SRC=%TMP_DIR%\%~2"
set "SRC=%SRC:/=\%"
for %%F in ("%SRC%") do set "NAME=%%~nxF"
if exist "models\%~3\%NAME%" (
    echo Skipping %NAME%, already in models\%~3
    exit /b 0
)
echo Downloading %NAME% to models\%~3
venv\Scripts\hf.exe download %~1 %~2 --local-dir %TMP_DIR% || exit /b 1
if not exist "models\%~3" mkdir "models\%~3"
move /y "%SRC%" "models\%~3\%NAME%" >nul || exit /b 1
exit /b 0
