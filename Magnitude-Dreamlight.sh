#!/usr/bin/env bash
set -euo pipefail

SHADERCROSS="utils/shadercross"
SHADER_DIR="shaders"
OUT_DIR="shaders/compiled"
UTILS_DIR="$(cd "$(dirname "$0")/utils" && pwd)"

ODIN_MAIN="./"
ODIN_EXE="app"

mkdir -p "$OUT_DIR/direct3d12"
mkdir -p "$OUT_DIR/vulkan"
mkdir -p "$OUT_DIR/metal"

BUILD_FAILED=0
REBUILT_COUNT=0

echo ""
echo "============================="
echo "SHADER BUILD"
echo "============================="

compile_shader() {
    local SRC="$1"
    local NAME="$2"
    local TARGET="$3"
    local OUTFILE="$4"

    # Skip recompile if output is newer than source
    if [[ -f "$OUTFILE" && "$OUTFILE" -nt "$SRC" ]]; then
        return 0
    fi

    "$SHADERCROSS" "$SRC" -o "$OUTFILE"

    if [[ $? -ne 0 ]]; then
        echo "[ERROR] $NAME $TARGET"
        BUILD_FAILED=1
        return 1
    fi

    REBUILT_COUNT=$((REBUILT_COUNT + 1))
}

for SRC in "$SHADER_DIR"/*.hlsl; do
    [[ -f "$SRC" ]] || continue

    NAME=$(basename "$SRC" .hlsl)
    STAGE=""

    [[ "$SRC" == *.vert.* ]] && STAGE="vertex"
    [[ "$SRC" == *.frag.* ]] && STAGE="fragment"

    if [[ -n "$STAGE" ]]; then
        compile_shader "$SRC" "$NAME" spirv  "$OUT_DIR/vulkan/$NAME.spv"
        compile_shader "$SRC" "$NAME" dxil   "$OUT_DIR/direct3d12/$NAME.dxil"
        compile_shader "$SRC" "$NAME" metal  "$OUT_DIR/metal/$NAME.msl"
    else
        echo "[SKIP] $SRC stage non riconosciuto"
    fi
done

echo ""
echo "Shader rebuilt: $REBUILT_COUNT"

if [[ $BUILD_FAILED -eq 1 ]]; then
    echo "BUILD SHADER FALLITA"
    exit 1
fi

echo ""
# =============================
# ODIN BUILD
# =============================

odin build "$ODIN_MAIN" -out:"$ODIN_EXE" \
    -extra-linker-flags:"-L$UTILS_DIR -rpath $UTILS_DIR"
if [[ $? -ne 0 ]]; then
    echo "Odin build failed"
    exit 1
fi

./"$ODIN_EXE"