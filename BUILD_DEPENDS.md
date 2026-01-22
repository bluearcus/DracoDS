# Build Dependencies for DracoDS

This document outlines the required library versions and build dependencies for compiling DracoDS. These specific versions are required for compatibility with libnds 1.8.2-1.

## Required Library Versions

The following library versions are required and must be installed manually from the historical archive, as they are no longer available through the standard devkitPro pacman repository:

### Core Libraries

| Library | Version | Source | Notes |
|---------|---------|--------|-------|
| **libnds** | 1.8.2-1 | [Archive Link](https://wii.leseratte10.de/devkitPro/libnds/libnds_1.8.2%20%282022%29/) | Required version as specified in README.md |
| **libfat-nds** | 1.1.5-1 | [Archive Link](https://wii.leseratte10.de/devkitPro/libfat/libfat_1.1.5%20%282020-04-18%29/) | Compatible with libnds 1.8.2, does not require calico |
| **maxmod-nds** | 1.0.13-1 | [Archive Link](https://wii.leseratte10.de/devkitPro/maxmod/maxmod-1.0.13%20%282020-05-10%29/) | Compatible with libnds 1.8.2, does not require calico |

### Additional Tools

| Tool | Version | Installation |
|------|---------|--------------|
| **dswifi** | 2.0.2-3 | `sudo dkp-pacman -S dswifi` |
| **grit** | 0.9.2-1 | `sudo dkp-pacman -S grit` |
| **mmutil** | 1.10.1-1 | `sudo dkp-pacman -S mmutil` |

## Installation Instructions

### Step 1: Install Standard Tools

Install the tools that are available from the standard devkitPro repository:

```bash
sudo dkp-pacman -S dswifi grit mmutil --noconfirm
```

### Step 2: Download Historical Library Versions

Download the required library packages from the historical archive:

```bash
cd /tmp

# Download libnds 1.8.2-1
wget "https://wii.leseratte10.de/devkitPro/libnds/libnds_1.8.2%20%282022%29/libnds-1.8.2-1-any.pkg.tar.xz"

# Download libfat-nds 1.1.5-1
wget "https://wii.leseratte10.de/devkitPro/libfat/libfat_1.1.5%20%282020-04-18%29/libfat-nds-1.1.5-1-any.pkg.tar.xz"

# Download maxmod-nds 1.0.13-1
wget "https://wii.leseratte10.de/devkitPro/maxmod/maxmod-1.0.13%20%282020-05-10%29/maxmod-nds-1.0.13-1-any.pkg.tar.xz"
```

### Step 3: Install Historical Libraries

Install the downloaded packages using pacman:

```bash
sudo dkp-pacman -U /tmp/libnds-1.8.2-1-any.pkg.tar.xz --noconfirm
sudo dkp-pacman -U /tmp/libfat-nds-1.1.5-1-any.pkg.tar.xz --noconfirm
sudo dkp-pacman -U /tmp/maxmod-nds-1.0.13-1-any.pkg.tar.xz --noconfirm
```

### Step 4: Verify Installation

Verify that the correct versions are installed:

```bash
dkp-pacman -Q | grep -E "libnds|libfat|maxmod"
```

Expected output:
```
libfat-nds 1.1.5-1
libnds 1.8.2-1
maxmod-nds 1.0.13-1
```

## Important Notes

### Why These Specific Versions?

- **libnds 1.8.2-1**: This is the version specified in the project README.md as the tested/required version.
- **libfat-nds 1.1.5-1**: This version (from 2020) is compatible with libnds 1.8.2 and does not require the calico library, which conflicts with libnds 1.8.2.
- **maxmod-nds 1.0.13-1**: This version (from 2020) is compatible with libnds 1.8.2 and does not require calico.

### Calico Compatibility Issue

**DO NOT** install calico or newer versions of libfat/maxmod that require it. The calico library (1.1.0+) conflicts with libnds 1.8.2 due to duplicate symbol definitions (`__syscall_gettod_r`, `__syscall_exit`). The older library versions (1.1.5 and 1.0.13 respectively) work correctly without calico.

## Build System Modifications

### Debug Keyboard Graphic (debug_kbd.png)

The build system has been modified to make `debug_kbd.png` optional:

- **Location**: `arm9/gfx_data/debug_kbd.png`
- **Status**: Optional - if missing, the debugger will use the normal Dragon/Tandy keyboard graphics
- **Implementation**: The Makefile conditionally includes `debug_kbd.o` only if the PNG file exists
- **Code**: `DracoDS.c` uses `#ifdef DEBUG_KBD_AVAILABLE` to conditionally use debug keyboard graphics, with fallback to normal keyboard

**Note**: The debugger feature will function correctly even without `debug_kbd.png` - it will simply display the standard keyboard graphic instead of a debug-specific one.

### Sound Bank Files

The build system excludes `.h` files from the binary data directory:

- **Location**: `arm9/data/soundbank.h`
- **Change**: The Makefile now filters out `.h` files from `BINFILES` to prevent them from being treated as binary data
- **Reason**: `soundbank.h` is a header file, not binary data, and should not be compiled as an object file

### dswifi Compatibility

A minimal `dswifi7.h` compatibility header has been created:

- **Location**: `/opt/devkitpro/libnds/include/dswifi7.h`
- **Purpose**: Provides stub functions for dswifi7 since wifi functionality is not used in this project
- **Note**: The arm7 Makefile no longer links against `libdswifi7` since wifi is not used

## Building the Project

Once all dependencies are installed, build the project:

```bash
cd /path/to/DracoDS
make clean
make
```

The output will be `DracoDS.nds` in the project root directory.

## Archive Source

All historical library versions are available from the community-maintained archive:

**Main Archive**: https://wii.leseratte10.de/devkitPro/

This archive preserves historical devkitPro releases that are no longer available through official channels. The archive maintainer notes that these old versions should not be used for compiling new, maintained projects, but are necessary for compiling legacy projects like DracoDS that require specific library versions.

## Troubleshooting

### Build fails with "cannot find -lfat"

- Ensure libfat-nds 1.1.5-1 is installed (not a newer version)
- Verify with: `dkp-pacman -Q libfat-nds`

### Build fails with calico conflicts

- Remove calico: `sudo dkp-pacman -R calico`
- Ensure you're using libfat-nds 1.1.5-1 and maxmod-nds 1.0.13-1 (not newer versions)

### Build fails with "debug_kbd.png not found"

- This is expected if the file doesn't exist
- The build will succeed and the debugger will use normal keyboard graphics
- To add the debug keyboard graphic, place `debug_kbd.png` in `arm9/gfx_data/`

### Build fails with "soundbank.h.o" error

- This should be fixed in the current Makefile
- Ensure `.h` files are excluded from BINFILES in `arm9/Makefile`

## Version Compatibility Matrix

| libnds | libfat-nds | maxmod-nds | calico | Status |
|--------|------------|------------|--------|--------|
| 1.8.2-1 | 1.1.5-1 | 1.0.13-1 | Not required | ✅ Compatible |
| 1.8.2-1 | 2.0.2-1 | 2.1.0-1 | 1.1.0-1 | ❌ Conflicts |

## References

- [devkitPro Archive](https://wii.leseratte10.de/devkitPro/)
- [devkitPro Official Website](https://devkitpro.org/)
- [Project README](README.md)
