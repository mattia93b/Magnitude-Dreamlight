#!/usr/bin/env python3
# 
# THE SOURCE SCRIPT IS GENTLY PROVIDED BY trojanfoe ... A SPECIAL THANKS
# YOU CAN FIND THE ORIGINAL SCRIPT HERE
# https://gist.github.com/trojanfoe/aae4fe796c7bb8a58fd53d6562b4400d
# 

import os
import shutil
import subprocess
import sys

platform = sys.platform

if platform == "darwin" or platform == "linux":
    WORKING_DIR = os.path.abspath("./")
    BIN_INSTALL_DIR = os.path.abspath("./")
    LIB_INSTALL_DIR = os.path.abspath("./")
elif platform == "win32":
    WORKING_DIR = os.path.abspath("./")
    BIN_INSTALL_DIR = os.path.abspath("./")
    LIB_INSTALL_DIR = BIN_INSTALL_DIR
else:
    raise RuntimeError("Unsupported platform")


def main():
    if platform == "win32":
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print("If you get the error:")
        print("    No CMAKE_C_COMPILER could be found.")
        print("then you need to run this script from a Developer Command Prompt for Visual Studio.")
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

    os.makedirs(WORKING_DIR, exist_ok=True)

    if not os.path.exists(BIN_INSTALL_DIR):
        raise RuntimeError(f"Install directory {BIN_INSTALL_DIR} does not exist")

    if not os.path.exists(LIB_INSTALL_DIR):
        raise RuntimeError(f"Install directory {LIB_INSTALL_DIR} does not exist")

    build_sdl()

    build_shadercross()

    if platform == "darwin":
        install_binaries_macos()
    elif platform == "win32":
        install_binaries_windows()
    elif platform == "linux":
        install_binaries_linux()
    else:
        raise RuntimeError("Unsupported platform")

    cleanup()


def build_sdl():
    sdl_dir = os.path.join(WORKING_DIR, "SDL")
    
    build_dir = os.path.join(sdl_dir, "build")
    if os.path.exists(build_dir):
        shutil.rmtree(build_dir)

    run(
        "Configuring SDL",
        ["cmake", "-Bbuild", "-S.", "-GNinja", "-DCMAKE_BUILD_TYPE=Release"],
        cwd=sdl_dir,
    )
    run("Building SDL", ["cmake", "--build", "build"], cwd=sdl_dir)


def build_shadercross():
    shadercross_dir = os.path.join(WORKING_DIR, "SDLShaderCross")

    build_dir = os.path.join(shadercross_dir, "build")
    if os.path.exists(build_dir):
        shutil.rmtree(build_dir)

    run(
        "Configuring shadercross",
        [
            "cmake",
            "-Bbuild",
            "-S.",
            "-GNinja",
            "-DCMAKE_BUILD_TYPE=Release",
            "-DSDLSHADERCROSS_DXC=ON",
            "-DSDLSHADERCROSS_VENDORED=ON",
            "-DSDL3_DIR=../SDL/build",
        ],
        cwd=shadercross_dir,
    )
    run("Building shadercross", ["cmake", "--build", "build"], cwd=shadercross_dir)


def install_binaries_macos():
    print(f"Installing binaries to {BIN_INSTALL_DIR} and libraries to {LIB_INSTALL_DIR}")

    shadercross_build_dir = os.path.join(WORKING_DIR, "SDLShaderCross", "build")

    shutil.copy(os.path.join(shadercross_build_dir, "shadercross"), BIN_INSTALL_DIR)

    spirv_cross_build_dir = os.path.join(shadercross_build_dir, "external", "SPIRV-Cross")

    shutil.copy(os.path.join(spirv_cross_build_dir, "libspirv-cross-c-shared.0.dylib"), LIB_INSTALL_DIR)

    directx_shader_compiler_build_dir = os.path.join(
        shadercross_build_dir, "external", "DirectXShaderCompiler", "lib"
    )

    shutil.copy(os.path.join(directx_shader_compiler_build_dir, "libdxcompiler.dylib"), LIB_INSTALL_DIR)

    sdl_build_dir = os.path.join(WORKING_DIR, "SDL", "build")

    shutil.copy(os.path.join(sdl_build_dir, "libSDL3.0.dylib"), LIB_INSTALL_DIR)

    shadercross_bin = os.path.join(BIN_INSTALL_DIR, "shadercross")

    run(
        "Fixing shadercross rpath #1",
        ["install_name_tool", "-delete_rpath", sdl_build_dir, shadercross_bin],
    )

    run(
        "Fixing shadercross rpath #2",
        ["install_name_tool", "-delete_rpath", spirv_cross_build_dir, shadercross_bin],
    )

    run(
        "Fixing shadercross rpath #3",
        [
            "install_name_tool",
            "-rpath",
            directx_shader_compiler_build_dir,
            LIB_INSTALL_DIR,
            shadercross_bin,
        ],
    )


def install_binaries_windows():
    print(f"Installing binaries to {BIN_INSTALL_DIR} and libraries to {LIB_INSTALL_DIR}")

    shadercross_build_dir = os.path.join(WORKING_DIR, "SDLShaderCross", "build")

    shutil.copy(os.path.join(shadercross_build_dir, "shadercross.exe"), BIN_INSTALL_DIR)

    spirv_cross_build_dir = os.path.join(shadercross_build_dir, "external", "SPIRV-Cross")

    shutil.copy(os.path.join(spirv_cross_build_dir, "spirv-cross-c-shared.dll"), LIB_INSTALL_DIR)

    directx_shader_compiler_build_dir = os.path.join(
        shadercross_build_dir, "external", "DirectXShaderCompiler", "bin"
    )

    shutil.copy(os.path.join(directx_shader_compiler_build_dir, "dxcompiler.dll"), LIB_INSTALL_DIR)

    sdl_build_dir = os.path.join(WORKING_DIR, "SDL", "build")

    shutil.copy(os.path.join(sdl_build_dir, "SDL3.dll"), LIB_INSTALL_DIR)


def install_binaries_linux():
    print(f"Installing binaries to {BIN_INSTALL_DIR} and libraries to {LIB_INSTALL_DIR}")

    shadercross_build_dir = os.path.join(WORKING_DIR, "SDLShaderCross", "build")

    shutil.copy(os.path.join(shadercross_build_dir, "shadercross"), BIN_INSTALL_DIR)

    spirv_cross_build_dir = os.path.join(shadercross_build_dir, "external", "SPIRV-Cross")

    shutil.copy(os.path.join(spirv_cross_build_dir, "libspirv-cross-c-shared.so.0"), LIB_INSTALL_DIR)

    directx_shader_compiler_build_dir = os.path.join(
        shadercross_build_dir, "external", "DirectXShaderCompiler", "lib"
    )

    shutil.copy(os.path.join(directx_shader_compiler_build_dir, "libdxcompiler.so"), LIB_INSTALL_DIR)

    sdl_build_dir = os.path.join(WORKING_DIR, "SDL", "build")

    shutil.copy(os.path.join(sdl_build_dir, "libSDL3.so.0"), LIB_INSTALL_DIR)

    shadercross_bin = os.path.join(BIN_INSTALL_DIR, "shadercross")

    run("Fixing shadercross rpath", ["patchelf", "--set-rpath", LIB_INSTALL_DIR, shadercross_bin])


def cleanup():
    print("Cleaning-up")
    shutil.rmtree(os.path.join(WORKING_DIR, "SDL", "build"))
    shutil.rmtree(os.path.join(WORKING_DIR, "SDLShaderCross", "build"))


def run(purpose, cmd_line, cwd=None):
    print("{}: {}".format(purpose, " ".join(cmd_line)))
    subprocess.run(cmd_line, check=True, encoding="utf-8", cwd=cwd)


if __name__ == "__main__":
    main()