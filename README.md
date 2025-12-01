# NO LONGER NEEDED

Stremio officially released v5 for MacOS on 27th November 2025 here: https://blog.stremio.com/stremio-v5-macos-release!-(with-arm-support)/


# 
# Stremio-shell-ng-MacOs
## Overview

Stremio-shell-ng-MacOs is a web wrapper for the Stremio application on macOS. This was made due to lack of support of Stremio v5 on MacOs and I couldn't really find much differences between v5 and the web version.

NOTE: Only M1 macs are supported, Intel versions need a custom electron binary to play all videos which itself needs an intel mac, 150GB free space and 3 days of time.

## Build Instructions

To build Stremio-shell-ng-MacOs, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/Shockshwat/Stremio-shell-ng-MacOs.git
   ```
2. Navigate to the project directory:
   ```bash
   cd Stremio-shell-ng-MacOs
   ```
3. Run the build Script:
   ```bash
   ./build_macos.sh
   ```

## Usage

Get the Application from [Releases](https://github.com/Shockshwat/Stremio-shell-ng-MacOs/releases) and move it to the Applications Folder If you want it to appear on the Launchpad.

## Troubleshooting

There is a slight chance that you might get an error "This app is damaged and cannot be run" and in that case just open terminal and run this command :

```bash
xattr -dr com.apple.quarantine (Path/To/App)
```

This can be because of signing issues and I am not really in a place to buy a developer account to sign my apps. Please open an issue if there is a workaround.

## Contributing

I welcome contributions to the project!

## Contact

For any questions or support, please open an issue on the [GitHub repository](https://github.com/Shockshwat/Stremio-shell-ng-MacOs/issues).
