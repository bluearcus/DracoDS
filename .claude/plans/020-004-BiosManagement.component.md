# BIOS and ROM Management Implementation

## Overview
This component implements automatic BIOS selection based on machine type and media format, ensuring the correct ROM set is visible for each configuration.

## Current Limitation
**CoCo COLOR BASIC-only mode is NOT currently supported.** The existing code (DracoDS.c:1476-1486) requires Extended BASIC to be present:
- If extbas11.rom is found, it loads both extbas11.rom + bas12.rom
- If extbas11.rom is NOT found, no BASIC ROM is loaded at all
- There's no fallback to load just bas12.rom (COLOR BASIC only)

This needs to be fixed to support CoCo machines without Extended BASIC ROM fitted.

## BIOS Selection Logic

### Current BIOS Loading
The system currently loads BIOS based on machine type into a single ROM area.

### Required Enhancement: Two-Stage ROM Loading

The correct logic separates BASIC ROM from Disk Interface ROM:

1. **BASIC ROM at $8000**: Always load appropriate BASIC based on machine type
2. **Disk Interface ROM at $C000**: Only load if disk media is specified

```c

// Enhanced BIOS selection logic - Two-stage loading

// Stage 1: Load BASIC ROM at $8000 based on machine type
if (myConfig.machine == 0) { // Dragon 32
    // Always load Dragon BASIC at $8000
    mem_load_rom(0x8000, DragonBASIC, sizeof(DragonBASIC));
} else { // Tandy CoCo
    // Always load CoCo BASIC at $8000
    mem_load_rom(0x8000, CoCoBASIC, sizeof(CoCoBASIC));
}

// Stage 2: Load Disk Interface ROM at $C000 if disk media specified
if (disk_media_loaded) {  // Check if .dsk file was specified
    if (myConfig.machine == 0) { // Dragon 32
        // Load Dragon DOS disk interface at $C000
        if (load_rom("dragonDos.rom", 0xC000)) {
            // Successfully loaded Dragon DOS interface
        } else {
            debug_printf("Warning: Dragon DOS ROM not found\n");
            // No fallback - disk operations will fail
        }
    } else { // Tandy CoCo
        // Load CoCo Disk Extended BASIC interface at $C000
        mem_load_rom(0xC000, DiskROM, sizeof(DiskROM));
    }
}
```

## ROM Memory Map

### Dragon 32 Mode
- **$8000-$BFFF**: Dragon BASIC ROM (always loaded)
- **$C000-$DFFF**: Dragon DOS disk interface ROM (only if .dsk media loaded)

### Tandy CoCo Mode
CoCo has two possible BASIC configurations:

**COLOR BASIC (CoCo 1/2 base model)**:
- **$A000-$BFFF**: COLOR BASIC ROM (8KB)
- **$8000-$9FFF**: Unmapped (or RAM)
- **$C000-$DFFF**: Disk Extended BASIC ROM (only if .dsk media loaded)

**EXTENDED BASIC (CoCo 1/2 with Extended BASIC)**:
- **$8000-$9FFF**: Extended BASIC ROM (8KB)
- **$A000-$BFFF**: COLOR BASIC ROM (8KB)
- **$C000-$DFFF**: Disk Extended BASIC ROM (only if .dsk media loaded)

## ROM File Requirements

### Dragon 32 Mode
1. **BASIC ROM (always needed)**:
   - `dragonBasic.rom` - embedded in emulator
   - Loaded at $8000 regardless of media type

2. **Disk Interface ROM (only for .dsk files)**:
   - `dragonDos.rom` - must be provided by user
   - Search locations:
     - User ROM directory
     - System ROM directory
   - Loaded at $C000 when disk media present

### Tandy CoCo Mode
1. **BASIC ROM (always needed)** - Three possible configurations:

   **Option A: Monolithic 16KB ROM** (current default):
   - `coco.rom` or `coco2.rom` - 16KB file
   - Loaded into CoCoBASIC[0x4000] buffer
   - Contains Extended BASIC at $8000 + COLOR BASIC at $A000

   **Option B: Split Extended BASIC** (current fallback):
   - `extbas11.rom` - 8KB Extended BASIC loaded at CoCoBASIC+0x0000 ($8000)
   - `bas12.rom` - 8KB COLOR BASIC loaded at CoCoBASIC+0x2000 ($A000)

   **Option C: COLOR BASIC only** (NOT currently supported):
   - `bas12.rom` - 8KB COLOR BASIC loaded at $A000
   - $8000-$9FFF unmapped or RAM

2. **Disk Interface ROM (only for .dsk files)**:
   - `disk11.rom` - 8KB Disk Extended BASIC
   - Loaded at $C000 when disk media present
   - Provides disk I/O routines

## Implementation Details

### 1. Two-Stage ROM Loading Function
```c
// Two-stage ROM loading: BASIC at $8000, Disk interface at $C000
int load_bios_roms(void) {
    // Stage 1: Load BASIC ROM at $8000 based on machine type
    if (myConfig.machine == 0) { // Dragon 32
        mem_load_rom(0x8000, DragonBASIC, sizeof(DragonBASIC));
    } else { // Tandy CoCo
        mem_load_rom(0x8000, CoCoBASIC, sizeof(CoCoBASIC));
    }

    // Stage 2: Load Disk Interface ROM at $C000 if disk media present
    if (disk_media_loaded) {  // Check if .dsk file specified
        if (myConfig.machine == 0) { // Dragon 32
            // Load Dragon DOS disk interface
            if (!load_rom("dragonDos.rom", 0xC000)) {
                debug_printf("ERROR: Dragon DOS ROM required for disk operations\n");
                return 0; // Disk operations will fail
            }
        } else { // Tandy CoCo
            // Load CoCo disk interface
            mem_load_rom(0xC000, DiskROM, sizeof(DiskROM));
        }
    }

    return 1; // Success
}
```

### 2. ROM File Search Helper
```c
// Helper function to search for ROM files in multiple locations
int find_and_load_rom(const char* filename, uint32_t address) {
    // Search order:
    // 1. ROM directory (user-provided)
    // 2. System ROM directory
    // 3. Embedded ROMs (if available)

    char path[256];

    // Try user ROM directory first
    snprintf(path, sizeof(path), "%s/%s", ROM_DIR, filename);
    if (file_exists(path)) {
        return load_rom_file(path, address);
    }

    // Try system ROM directory
    snprintf(path, sizeof(path), "%s/%s", SYS_ROM_DIR, filename);
    if (file_exists(path)) {
        return load_rom_file(path, address);
    }

    return 0; // Not found
}
```

### 3. Error Handling and Logging
```c
// Enhanced error handling with debug output
void handle_bios_load_error(const char* bios_type, const char* filename) {
    debug_printf("ERROR: Could not load %s BIOS: %s\n", bios_type, filename);

    // Attempt fallback
    if (strcmp(bios_type, "Dragon DOS") == 0) {
        debug_printf("Attempting fallback to Dragon BASIC...\n");
        mem_load_rom(DRAGON_ROM_START, DragonBASIC, sizeof(DragonBASIC));
    } else if (strcmp(bios_type, "CoCo Disk") == 0) {
        debug_printf("Attempting fallback to CoCo BASIC...\n");
        mem_load_rom(DRAGON_ROM_START, CoCoBASIC, sizeof(CoCoBASIC));
    } else {
        debug_printf("No fallback available for %s\n", bios_type);
    }
}
```

## Implementation Steps

### Step 1: Update BIOS Loading Logic
1. Locate current BIOS loading code in `dragon.c`
2. Replace with two-stage loading:
   - Stage 1: BASIC ROM at $8000 (always)
   - Stage 2: Disk interface ROM at $C000 (if disk present)
3. Remove old combined ROM loading logic

### Step 2: Implement Disk Media Detection
1. Add flag to track if disk media (.dsk file) was loaded
2. Set flag when disk file is successfully opened
3. Use flag to determine if disk interface ROM is needed

### Step 3: Implement ROM Search for Dragon DOS
1. Add ROM file search helper function for `dragonDos.rom`
2. Search user ROM directory and system ROM directory
3. Add error logging if not found

### Step 4: Update Memory Mapping
1. Ensure $8000-$BFFF is mapped to BASIC ROM
2. Ensure $C000-$DFFF is mapped to disk interface ROM (when loaded)
3. Verify ROM regions don't conflict with RAM or other devices

### Step 5: Testing
1. Test Dragon 32 with no disk (BASIC only at $8000)
2. Test Dragon 32 with disk (BASIC at $8000 + Dragon DOS at $C000)
3. Test CoCo with no disk (BASIC only at $8000)
4. Test CoCo with disk (BASIC at $8000 + Disk Extended BASIC at $C000)
5. Verify error handling when dragonDos.rom is missing

## Testing Scenarios

### 1. Two-Stage Loading Tests
- **Dragon 32 + no disk**:
  - BASIC at $8000 ✓
  - No ROM at $C000 ✓

- **Dragon 32 + .dsk file**:
  - Dragon BASIC at $8000 ✓
  - Dragon DOS at $C000 ✓

- **Tandy CoCo + no disk**:
  - CoCo BASIC at $8000 ✓
  - No ROM at $C000 ✓

- **Tandy CoCo + .dsk file**:
  - CoCo BASIC at $8000 ✓
  - Disk Extended BASIC at $C000 ✓

### 2. Error Handling Tests
- **Missing dragonDos.rom**: Display error, disk operations fail
- **Invalid ROM file**: Handle gracefully with error message
- **ROM file size mismatch**: Validate and report error

### 3. Memory Map Verification
- Verify $8000-$BFFF contains BASIC ROM
- Verify $C000-$DFFF contains disk ROM (when loaded)
- Verify no overlap with RAM or I/O regions

## Files Modified
- `arm9/source/dragon.c` - Update to two-stage ROM loading
- Add disk media detection flag
- Add Dragon DOS ROM loading at $C000

## ROM Memory Layout Summary

### Dragon 32 Configuration
```
$8000-$BFFF: Dragon BASIC ROM (embedded, always loaded)
$C000-$DFFF: Dragon DOS ROM (external file, only if .dsk loaded)
```

### Tandy CoCo Configuration

**Current Implementation (Extended BASIC only)**:
```
$8000-$9FFF: Extended BASIC ROM (8KB) - from extbas11.rom or coco.rom[0:8K]
$A000-$BFFF: COLOR BASIC ROM (8KB) - from bas12.rom or coco.rom[8K:16K]
$C000-$DFFF: Disk Extended BASIC ROM (8KB) - from disk11.rom (only if .dsk loaded)
```

**Missing: COLOR BASIC-only mode**:
```
$8000-$9FFF: Unmapped or RAM
$A000-$BFFF: COLOR BASIC ROM (8KB) - from bas12.rom
$C000-$DFFF: Disk Extended BASIC ROM (8KB) - from disk11.rom (only if .dsk loaded)
```

### Key ROM Files
- `dragonDos.rom` - Dragon DOS disk interface (8KB at $C000)
  - Must be provided by user in ROM directory
  - Only loaded when .dsk file is specified
  - Required for Dragon 32 disk operations

## Dependencies
- File system access for ROM loading
- Debug logging infrastructure
- Existing ROM loading functions

## Risk Assessment
- **Medium Risk**: ROM file management complexity
- **Low Risk**: Most functionality is based on existing patterns
- **Backward Compatibility**: Should maintain existing CoCo behavior

## Performance Considerations
- ROM file search should be cached
- Minimal overhead during initialization
- Debug logging should be disabled in release builds
```