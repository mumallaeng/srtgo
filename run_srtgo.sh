#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

export PYTHONUTF8="${PYTHONUTF8:-1}"
export PYTHONIOENCODING="${PYTHONIOENCODING:-utf-8}"

VENV_DIR="${VENV_DIR:-.venv}"

case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*)
        ACTIVATE_PATH="$VENV_DIR/Scripts/activate"
        VENV_PYTHON="$VENV_DIR/Scripts/python.exe"
        ;;
    *)
        ACTIVATE_PATH="$VENV_DIR/bin/activate"
        VENV_PYTHON="$VENV_DIR/bin/python"
        ;;
esac

PY_CMD=()

select_python() {
    local candidate
    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1 &&
            "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1; then
            PY_CMD=("$candidate")
            return
        fi
    done

    if command -v py >/dev/null 2>&1 &&
        py -3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1; then
        PY_CMD=(py -3)
        return
    fi

    echo "Python 3.10 or newer is required." >&2
    exit 1
}

install_package() {
    "$VENV_PYTHON" -m pip install -e .
}

create_venv() {
    if "${PY_CMD[@]}" -m venv "$VENV_DIR"; then
        return
    fi

    case "$(uname -r 2>/dev/null | tr '[:upper:]' '[:lower:]')" in
        *microsoft*|*wsl*)
            echo "Failed to create venv in WSL. On Debian/Ubuntu WSL, install python3-venv first:" >&2
            echo "  sudo apt install python3-venv" >&2
            ;;
        *)
            echo "Failed to create virtual environment: $VENV_DIR" >&2
            ;;
    esac
    exit 1
}

if [[ ! -f "$ACTIVATE_PATH" || ! -x "$VENV_PYTHON" ]]; then
    select_python
    echo "Creating virtual environment: $VENV_DIR"
    create_venv
    install_package
fi

# shellcheck disable=SC1090
source "$ACTIVATE_PATH"

if ! command -v srtgo >/dev/null 2>&1; then
    install_package
fi

srtgo "$@"
