#!/usr/bin/env bash
# Cloud Agent install for 봉쇄구역: 제로 (infection-clearance), a Godot 4.7 GDScript project.
# Idempotent: installs the Godot 4.7 editor binary plus the runtime libraries it needs
# to run headless and windowed, then warms the import cache when the project is present.
# Safe on branches that only contain docs (no project.godot).
set -euo pipefail

GODOT_VERSION="4.7.2-stable"
GODOT_ZIP="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${GODOT_ZIP}"
GODOT_BIN="/usr/local/bin/godot"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

echo "[install] Installing runtime libraries for Godot ${GODOT_VERSION}"
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -y
# Runtime deps for the Godot binary (windowed + headless), audio, and fonts (Korean UI).
$SUDO apt-get install -y --no-install-recommends \
  ca-certificates curl unzip \
  libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libxext6 libxrender1 \
  libgl1 libglu1-mesa libglx-mesa0 libegl1 \
  libasound2t64 libpulse0 \
  libfontconfig1 libfreetype6 fonts-noto-cjk \
  xvfb x11-utils

install_godot() {
  echo "[install] Downloading Godot ${GODOT_VERSION}"
  local tmp
  tmp="$(mktemp -d)"
  curl -fL --retry 4 --retry-delay 4 -o "${tmp}/${GODOT_ZIP}" "${GODOT_URL}"
  unzip -o -q "${tmp}/${GODOT_ZIP}" -d "${tmp}"
  local extracted
  extracted="$(find "${tmp}" -maxdepth 1 -name 'Godot_v*_linux.x86_64' -type f | head -n1)"
  $SUDO install -m 0755 "${extracted}" "${GODOT_BIN}"
  rm -rf "${tmp}"
}

if [ -x "${GODOT_BIN}" ] && "${GODOT_BIN}" --version 2>/dev/null | grep -q "^4.7.2"; then
  echo "[install] Godot ${GODOT_VERSION} already installed: $(${GODOT_BIN} --version)"
else
  install_godot
  echo "[install] Installed: $(${GODOT_BIN} --version)"
fi

# Warm the import/.godot cache when the Godot project is checked out (skipped on docs-only branches).
if [ -f "project.godot" ]; then
  echo "[install] project.godot found; importing resources (headless)"
  # --import populates res://.godot; it can exit non-zero on transient warnings, so don't fail install.
  "${GODOT_BIN}" --headless --path . --import 2>&1 | tail -n 20 || true
else
  echo "[install] No project.godot on this branch; skipping resource import"
fi

echo "[install] Done"
