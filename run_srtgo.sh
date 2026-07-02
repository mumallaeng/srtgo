#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

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

if [[ ! -f "$ACTIVATE_PATH" || ! -x "$VENV_PYTHON" ]]; then
    select_python
    echo "Creating virtual environment: $VENV_DIR"
    "${PY_CMD[@]}" -m venv "$VENV_DIR"
    install_package
fi

source "$ACTIVATE_PATH"

if ! command -v srtgo >/dev/null 2>&1; then
    install_package
fi

srtgo "$@"
