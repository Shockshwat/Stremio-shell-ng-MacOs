#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.

# --- Configuration ---
ELECTRON_VERSION="29.1.4" # Specify the Electron version you want to use
APP_NAME="Stremio"
APP_ICON_SOURCE="img/stremio.icns" # Path to your app icon
OUTPUT_DIR="dist_manual"          # Directory to put the packaged app

# Determine architecture
ARCH=$(uname -m)
ELECTRON_ARCH=""
RUST_TARGET=""

if [ "$ARCH" == "x86_64" ]; then
  ELECTRON_ARCH="x64"
  RUST_TARGET="x86_64-apple-darwin"
elif [ "$ARCH" == "arm64" ]; then
  ELECTRON_ARCH="arm64"
  RUST_TARGET="aarch64-apple-darwin"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

echo "--- Configuration ---"
echo "Electron Version: $ELECTRON_VERSION"
echo "App Name: $APP_NAME"
echo "Architecture: $ARCH (Electron: $ELECTRON_ARCH, Rust: $RUST_TARGET)"
echo "Output Directory: $OUTPUT_DIR"
echo "App Icon: $APP_ICON_SOURCE"
echo "Stremio Service Path: stremio-service"
echo "---------------------"

# --- Cleanup ---
echo "[1/7] Cleaning up previous build..."
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"
cd "${OUTPUT_DIR}"

# --- Download and Unzip Electron ---
echo "[2/7] Downloading Electron v${ELECTRON_VERSION} for darwin-${ELECTRON_ARCH}..."
ELECTRON_DOWNLOAD_URL="https://github.com/Shockshwat/electron-dist/releases/download/29.1.4/electron-v29.1.4-darwin-arm64.zip"
curl -LO "${ELECTRON_DOWNLOAD_URL}"
echo "Unzipping Electron..."
unzip -q "electron-v${ELECTRON_VERSION}-darwin-${ELECTRON_ARCH}.zip"
rm "electron-v${ELECTRON_VERSION}-darwin-${ELECTRON_ARCH}.zip"

# --- Prepare App Bundle ---
echo "[3/7] Preparing ${APP_NAME}.app bundle..."
mv "Electron.app" "${APP_NAME}.app"
APP_BUNDLE_PATH="${APP_NAME}.app"
RESOURCES_PATH="${APP_BUNDLE_PATH}/Contents/Resources"
MACOS_PATH="${APP_BUNDLE_PATH}/Contents/MacOS"

# Update Icon
if [ -f "../${APP_ICON_SOURCE}" ]; then
  echo "Updating app icon..."
  cp "../${APP_ICON_SOURCE}" "${RESOURCES_PATH}/electron.icns" # Electron default icon name
else
  echo "Warning: App icon not found at ../${APP_ICON_SOURCE}"
fi

echo "Updating Info.plist..."
plutil -replace CFBundleName -string "${APP_NAME}" "${APP_BUNDLE_PATH}/Contents/Info.plist"
plutil -replace CFBundleDisplayName -string "${APP_NAME}" "${APP_BUNDLE_PATH}/Contents/Info.plist"
plutil -replace CFBundleIconFile -string "electron.icns" "${APP_BUNDLE_PATH}/Contents/Info.plist" # Assuming icon is named electron.icns

cd .. # Back to project root

# --- Prepare App Contents (Resources/app) ---
echo "[4/7] Preparing app contents (Stremio.app/Contents/Resources/app)..."
APP_CONTENTS_PATH="${OUTPUT_DIR}/${APP_BUNDLE_PATH}/Contents/Resources/app"
mkdir -p "${APP_CONTENTS_PATH}"

# Copy essential files
echo "Copying main.js, preload.js..."
cp main.js "${APP_CONTENTS_PATH}/"
cp preload.js "${APP_CONTENTS_PATH}/"

# Create a minimal package.json for the app
echo "Creating minimal package.json for the app..."
# Extract production dependencies from root package.json
# This is a simplified way; a more robust way would parse JSON properly.
PROD_DEPS=$(jq -r '.dependencies' package.json)
APP_NAME_LOWERCASE=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')

cat > "${APP_CONTENTS_PATH}/package.json" <<EOL
{
  "name": "${APP_NAME_LOWERCASE}-packaged",
  "version": "$(jq -r '.version' package.json)",
  "main": "main.js",
  "dependencies": ${PROD_DEPS}
}
EOL

# Install production node_modules
echo "Installing production Node.js dependencies..."
(cd "${APP_CONTENTS_PATH}" && npm install --production)

# --- Compile Stremio Service ---
echo "[5/7] Compiling stremio-service for ${RUST_TARGET}..."
git submodule update --init --recursive 
if [ -d "stremio-service" ]; then
  (cd stremio-service && cargo build --release --target "${RUST_TARGET}")
else
  echo "Error: stremio-service directory not found."
  exit 1
fi

# --- Copy Stremio Service Binary ---
echo "[6/7] Copying stremio-service binary..."
STREMIO_SERVICE_BINARY_SOURCE="stremio-service/target/${RUST_TARGET}/release/stremio-service"
STREMIO_SERVICE_BINARY_DEST="${OUTPUT_DIR}/${RESOURCES_PATH}/stremio-service"

if [ -f "${STREMIO_SERVICE_BINARY_SOURCE}" ]; then
  cp "${STREMIO_SERVICE_BINARY_SOURCE}" "${STREMIO_SERVICE_BINARY_DEST}"
  chmod +x "${STREMIO_SERVICE_BINARY_DEST}"
else
  echo "Error: Compiled stremio-service binary not found at ${STREMIO_SERVICE_BINARY_SOURCE}"
  exit 1
fi

# --- Finalizing ---
echo "[7/7] Packaging complete!"
echo "${APP_NAME}.app created in ${OUTPUT_DIR}/ directory."


exit 0
