{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Python
    python312
    uv
    ruff
    basedpyright
    mypy

    # Lua
    lua
    lua-language-server
    stylua

    # C / C++
    clang-tools
    cmake
    ninja
    lldb

    # Documents
    typst
    tinymist
    pandoc
    gnuplot
    tectonic
    typstyle
    poppler-utils

    # Git / dev utilities
    gh
    yt-dlp

    # Mobile / embedded
    android-tools

    # Quantum SDKs: install per-project via `uv pip install qiskit pennylane cirq`
  ];
}
