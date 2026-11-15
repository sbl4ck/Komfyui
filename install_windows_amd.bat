@echo off
rem ComfyUI install for Windows 11 with an AMD GPU (ROCm 10.0, PyTorch 2.13).
rem Needs a current AMD graphics driver and 64-bit Python 3.13 (py launcher).
rem Set DEVICE to your GPU's target, or device-all for every supported GPU.
rem   RX 9070 / XT: device-gfx1201    RX 9060 / XT: device-gfx1200
rem   RX 7900 XT / XTX: device-gfx1100    RX 7700 XT / 7800 XT: device-gfx1101
setlocal
cd /d "%~dp0"

set DEVICE=device-gfx1201
set ROCM_INDEX=https://stable.repo.amd.com/rocm/whl-next/

py -3.13 --version >nul 2>&1
if errorlevel 1 (
    echo 64-bit Python 3.13 not found. Install it from python.org and run this again.
    exit /b 1
)

if not exist venv (
    py -3.13 -m venv venv || exit /b 1
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
