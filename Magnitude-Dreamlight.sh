#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================
# Note: Ensure the shadercross binary is the macOS version and has execute permissions (chmod +x)
SHADERCROSS="utils/shadercross"
export DYLD_LIBRARY_PATH="$(pwd)/utils:$DYLD_LIBRARY_PATH"
SHADER_DIR="shaders"
OUT_DIR="shaders/compiled"

ODIN_MAIN="main.odin"
ODIN_EXE="app" # Removed .exe for macOS

# Create directories (-p creates them only if they don't exist, suppressing errors)
mkdir -p "$OUT_DIR/dx12"
mkdir -p "$OUT_DIR/vulkan"
mkdir -p "$OUT_DIR/metal"

BUILD_FAILED=0
REBUILT_COUNT=0

echo ""
echo "============================="
echo "SHADER BUILD"
echo "============================="

# ==========================================
# FUNCTION DEFINITION
# ==========================================
compile_shader() {
    local SRC="$1"
    local NAME="$2"
    local TARGET="$3"
    local OUTFILE="$4"

    # Run the compilation
    # "$SHADERCROSS" "$SRC" -o "$OUTFILE"
    # Note: Depending on your SDL_shadercross version, you might need specific flags for targets
    # Assuming standard CLI usage matches your batch file:
    "$SHADERCROSS" "$SRC" -o "$OUTFILE"

    if [ $? -ne 0 ]; then
        echo "[ERROR] $NAME $TARGET"
        BUILD_FAILED=1
        return 1
    fi

    ((REBUILT_COUNT++))
}

# ==========================================
# MAIN LOOP
# ==========================================
# Loop through all .hlsl files
for f in "$SHADER_DIR"/*.hlsl; do
    # Check if file exists to avoid errors if directory is empty
    [ -e "$f" ] || continue

    FILENAME=$(basename -- "$f")
    NAME="${FILENAME%.*}" # Remove extension
    STAGE=""

    # Check for .vert. or .frag. in the filename
    if [[ "$f" == *".vert."* ]]; then
        STAGE="vertex"
    elif [[ "$f" == *".frag."* ]]; then
        STAGE="fragment"
    fi

    if [ -n "$STAGE" ]; then
        # Call the compile function for each backend
        compile_shader "$f" "$NAME" "spirv" "$OUT_DIR/vulkan/$NAME.spv"
        compile_shader "$f" "$NAME" "dxil"  "$OUT_DIR/dx12/$NAME.dxil"
        compile_shader "$f" "$NAME" "metal" "$OUT_DIR/metal/$NAME.msl"
    else
        echo "[SKIP] $FILENAME stage not recognized"
    fi
done

echo ""
echo "Shader rebuilt: $REBUILT_COUNT"

if [ $BUILD_FAILED -eq 1 ]; then
    echo "BUILD SHADER FAILED"
    exit 1
fi

echo ""
echo "============================="
echo "ODIN BUILD"
echo "============================="

# Build Odin project
odin build "$ODIN_MAIN" -out:"$ODIN_EXE" -file

if [ $? -ne 0 ]; then
    echo "Odin build failed"
    exit 1
fi

# Run the app
echo "Running $ODIN_EXE..."
./"$ODIN_EXE"