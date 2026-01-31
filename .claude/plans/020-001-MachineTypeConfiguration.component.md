# Machine Type Configuration Implementation

## Overview
This component handles the core architecture changes needed to support Dragon DOS independently of media file selection.

## Key Changes

### 1. Remove Machine Type Lock
**File**: `arm9/source/DracoUtils.c`

**Current Code (line 770)**:
```c
myConfig.machine = 1; // CoCo only - REMOVE THIS
```

**Action**: Remove this line entirely to allow Dragon 32 machine type with disk files.

### 2. Update Machine Type Selection UI
**File**: `arm9/source/DracoUtils.c`

**Current Code**:
```c
{"MACHINE TYPE", {"DRAGON 32", "TANDY COCO"}, &myConfig.machine, 2}
```

**Action**: Keep this as-is - it already supports Dragon 32 selection.

### 3. Update BIOS Loading Logic
**File**: `arm9/source/dragon.c`

**New Logic**:
```c
// For Dragon machine type with disks, automatically use Dragon DOS
if (myConfig.machine == 0 && draco_mode == MODE_DSK) {
    // Load Dragon DOS ROM for disk files
    mem_load_rom(DRAGON_ROM_START, DragonDOS, sizeof(DragonDOS));
} else if (myConfig.machine == 0) {
    // Load Dragon BASIC for non-disk files
    mem_load_rom(DRAGON_ROM_START, DragonBASIC, sizeof(DragonBASIC));
} else {
    // Tandy CoCo - use existing logic
    mem_load_rom(DRAGON_ROM_START, CoCoBASIC, sizeof(CoCoBASIC));
}
```

## Implementation Steps

### Step 1: Remove Machine Type Lock
1. Open `arm9/source/DracoUtils.c`
2. Find line 770 with `myConfig.machine = 1;`
3. Remove this line completely
4. Test that Dragon 32 can now be selected with disk files

### Step 2: Update BIOS Loading Logic
1. Open `arm9/source/dragon.c`
2. Find ROM loading section (around line 895)
3. Implement conditional loading based on machine + media type
4. Test all combinations:
   - Dragon + disk → Dragon DOS
   - Dragon + cassette → Dragon BASIC
   - Dragon + cartridge → Dragon BASIC
   - CoCo + disk → DECB
   - CoCo + cassette → CoCo BASIC
   - CoCo + cartridge → CoCo BASIC

## Testing Scenarios

### 1. Machine Type Persistence
- Select Dragon 32, load disk file → verify stays Dragon 32
- Select Tandy CoCo, load disk file → verify stays Tandy CoCo
- Save/load configuration → verify machine type persists

### 2. BIOS Loading
- Dragon 32 + disk.rom → should load Dragon DOS
- Dragon 32 + cas.file → should load Dragon BASIC
- Tandy CoCo + disk.rom → should load DECB
- Tandy CoCo + cas.file → should load CoCo BASIC

### 3. Error Handling
- Missing Dragon DOS ROM → should fallback to Dragon BASIC
- Missing CoCo ROM → should show appropriate error

## Files Modified
- `arm9/source/DracoUtils.c` - Remove machine type lock
- `arm9/source/dragon.c` - Update ROM loading logic

## Dependencies
- Dragon DOS ROM image (`dragonDos.rom`)
- Existing ROM loading infrastructure

## Risk Assessment
- **Low Risk**: Simple configuration changes
- **Medium Risk**: BIOS loading logic changes need thorough testing
- **Backward Compatibility**: Should maintain existing CoCo behavior