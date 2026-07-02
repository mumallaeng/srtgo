param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $SrtgoArgs
)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RootDir

$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"
try {
    [Console]::InputEncoding = New-Object System.Text.UTF8Encoding $false
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false
} catch {
    # Some redirected/non-interactive shells do not expose console encoding.
}

$VenvDir = if ($env:VENV_DIR) { $env:VENV_DIR } else { ".venv-win" }
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
$VenvSrtgo = Join-Path $VenvDir "Scripts\srtgo.exe"

function Test-Python310 {
    param(
        [Parameter(Mandatory = $true)][string] $Command,
        [string[]] $Arguments = @()
    )

    $CheckArgs = @($Arguments + @("-c", "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)"))
    try {
        & $Command @CheckArgs > $null 2> $null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Get-PythonCommand {
    $Candidates = @(
        @{ Command = "py"; Arguments = @("-3") },
        @{ Command = "python"; Arguments = @() },
        @{ Command = "python3"; Arguments = @() }
    )

    foreach ($Candidate in $Candidates) {
        $Command = $Candidate["Command"]
        $Arguments = $Candidate["Arguments"]
        if ((Get-Command $Command -ErrorAction SilentlyContinue) -and
            (Test-Python310 -Command $Command -Arguments $Arguments)) {
            return $Candidate
        }
    }

    throw "Python 3.10 or newer is required. Install Python for Windows, then rerun .\run_srtgo.ps1."
}

function Invoke-Python {
    param(
        [Parameter(Mandatory = $true)][hashtable] $Python,
        [Parameter(Mandatory = $true)][string[]] $Arguments
    )

    $Command = $Python["Command"]
    $AllArguments = @($Python["Arguments"] + $Arguments)
    & $Command @AllArguments
}

function Install-Srtgo {
    & $VenvPython -m pip install -e .
}

if (!(Test-Path -LiteralPath $VenvPython)) {
    $Python = Get-PythonCommand

    if (Test-Path -LiteralPath $VenvDir) {
        Write-Host "Removing incomplete Windows virtual environment: $VenvDir"
        Remove-Item -LiteralPath $VenvDir -Recurse -Force
    }

    Write-Host "Creating Windows virtual environment: $VenvDir"
    Invoke-Python -Python $Python -Arguments @("-m", "venv", $VenvDir)
    Install-Srtgo
}

if (!(Test-Path -LiteralPath $VenvSrtgo)) {
    Install-Srtgo
}

& $VenvSrtgo @SrtgoArgs
