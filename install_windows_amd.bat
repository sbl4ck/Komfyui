@echo off
rem ComfyUI install for Windows 11 with an AMD GPU (ROCm 10.0, PyTorch 2.13).
rem Needs a current AMD graphics driver. Installs 64-bit Python 3.13 with winget if missing.
rem Set DEVICE to your GPU's target, or device-all for every supported GPU.
rem   RX 9070 / XT: device-gfx1201    RX 9060 / XT: device-gfx1200
rem   RX 7900 XT / XTX: device-gfx1100    RX 7700 XT / 7800 XT: device-gfx1101
setlocal
cd /d "%~dp0"

set DEVICE=device-gfx1201
set ROCM_INDEX=https://stable.repo.amd.com/rocm/whl-next/

reg query "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled 2>nul | find "0x1" >nul
if errorlevel 1 (
    echo Windows long path support is off and the ROCm packages need it. In an admin PowerShell run:
    echo   New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name LongPathsEnabled -Value 1 -PropertyType DWORD -Force
    echo Then run this script again.
    exit /b 1
)

call :find_python
if not defined PYTHON (
    echo 64-bit Python 3.13 not found, installing it with winget...
    winget install -e --id Python.Python.3.13 --architecture x64 --source winget --accept-package-agreements --accept-source-agreements || exit /b 1
    call :find_python
)
if not defined PYTHON (
    echo Python 3.13 was installed but could not be found. Open a new terminal and run this again.
    exit /b 1
)

if not exist venv (
    %PYTHON% -m venv venv || exit /b 1
)
call venv\Scripts\activate.bat || exit /b 1

python -m pip install --upgrade pip || exit /b 1
python -m pip install --index-url %ROCM_INDEX% "torch[%DEVICE%]==2.13.0+rocm10.0.0" "torchvision[%DEVICE%]==0.28.0+rocm10.0.0" "torchaudio==2.11.0.2+rocm10.0.0" || exit /b 1
python -m pip install -r requirements.txt || exit /b 1

if not exist models\checkpoints mkdir models\checkpoints
if not exist models\vae mkdir models\vae

python -c "import torch; print('torch', torch.__version__, '| GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'not detected')"

echo.
echo Put SD checkpoints in models\checkpoints and VAEs in models\vae.
echo Start ComfyUI with: venv\Scripts\python.exe main.py
endlocal
exit /b 0

:find_python
py -3.13-64 --version >nul 2>&1
if not errorlevel 1 (
    set PYTHON=py -3.13-64
    exit /b 0
)
for %%P in ("%LOCALAPPDATA%\Programs\Python\Python313\python.exe" "%ProgramFiles%\Python313\python.exe") do (
    if exist %%P (
        set PYTHON=%%P
        exit /b 0
    )
)
exit /b 0
