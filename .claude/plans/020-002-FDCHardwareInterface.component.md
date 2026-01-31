# FDC Hardware Interface Component

## Overview
Implement machine-specific I/O register handlers to support both WD2797 (Dragon DOS) and WD2793 (CoCo) floppy disk controllers with correct address mapping, bit encoding, and side selection.

## Current State Analysis

### Existing Implementation
The current code in `arm9/source/disk.c`:
- **Line 73**: Hardcodes `WD2793` controller type
- **Lines 92-106**: Implements `io_handler_wd2797()` for registers at $FF48-$FF4B (Dragon addresses)
- **Lines 109-142**: Implements `io_handler_drive_ctrl()` for control register at $FF40 (CoCo address)
- **Problem**: Address mapping and bit decoding are NOT machine-specific

### Critical Issues
1. **Controller Type**: Always uses WD2793, doesn't select WD2797 for Dragon
2. **Address Confusion**: Dragon FDC registers should be at $FF40-$FF43, control at $FF48
3. **Register Handler**: CoCo control at $FF40, Dragon FDC at $FF40-$FF43 - address conflict!
4. **Bit Decoding**: Control register handler doesn't differentiate Dragon vs CoCo encoding
5. **Side Select**: Not implemented differently for Dragon (SIDE pin) vs CoCo (latch bit)

## Hardware Requirements Summary

### Dragon DOS (WD2797)
- **FDC Registers**: $FF40-$FF43 (Status, Track, Sector, Data)
- **Control Latch**: $FF48
  - Bits 0-1: Binary drive select
  - Bit 2: Motor enable
  - Bit 3: Density (INVERTED: 1=SD, 0=DD)
  - Bit 4: Write precomp
  - Bit 5: NMI enable
- **Side Select**: Via WD2797 command register SIDE pin

### CoCo DOS (WD2793)
- **Control Latch**: $FF40
  - Bits 0-2: One-hot drive select (001, 010, 100)
  - Bit 3: Motor enable
  - Bit 4: Write precomp
  - Bit 5: Density (NORMAL: 1=DD, 0=SD)
  - Bit 6: Side select
  - Bit 7: Halt/Wait enable
- **FDC Registers**: $FF48-$FF4B (Status, Track, Sector, Data)

## Required Changes

### Change 1: Controller Type Selection
**File**: `arm9/source/disk.c` (line 73)

**Current Code**:
```c
fdc_init(WD2793, 1, 1, (last_file_size >= (180*1024) ? 40:35), 18, 256, 0, TapeCartDiskBuffer, NULL);
```

**New Code**:
```c
// Select controller type based on machine
u8 controller = (myConfig.machine == 0) ? WD1770 : WD2793;  // WD1770 constant for WD2797
fdc_init(controller, 1, 1, (last_file_size >= (180*1024) ? 40:35), 18, 256, 0, TapeCartDiskBuffer, NULL);
```

**Rationale**: WD2797 and WD1770 are compatible; use WD1770 constant from fdc.h

---

### Change 2: Machine-Specific I/O Handler Registration
**File**: `arm9/source/disk.c` (lines 77-88)

**Current Code**:
```c
mem_define_io(0xFF, 0x48, 0xFF, 0x4B, NULL, io_handler_wd2797);
mem_define_io(0xFF, 0x40, 0xFF, 0x40, NULL, io_handler_drive_ctrl);
```

**New Code**:
```c
if (myConfig.machine == 0) {
    // Dragon DOS: FDC at $FF40-$FF43, Control at $FF48
    mem_define_io(0xFF, 0x40, 0xFF, 0x43, NULL, io_handler_dragon_fdc);
    mem_define_io(0xFF, 0x48, 0xFF, 0x48, NULL, io_handler_dragon_ctrl);
} else {
    // CoCo: Control at $FF40, FDC at $FF48-$FF4B
    mem_define_io(0xFF, 0x40, 0xFF, 0x40, NULL, io_handler_coco_ctrl);
    mem_define_io(0xFF, 0x48, 0xFF, 0x4B, NULL, io_handler_coco_fdc);
}
```

**Rationale**: Correct address mapping per hardware specifications

---

### Change 3: Rename and Update FDC Register Handlers
**File**: `arm9/source/disk.c`

**Current Function**: `io_handler_wd2797()` (lines 92-106)

**Rename to**: `io_handler_dragon_fdc()` and `io_handler_coco_fdc()`

Both functions remain largely unchanged - they simply pass through to the FDC emulation core:
```c
void io_handler_dragon_fdc(u8 addr, u8 write, u8 *data) {
    // Dragon: $FF40-$FF43 map to FDC registers
    if (write) fdc_write(addr - 0x40, *data);
    else *data = fdc_read(addr - 0x40);
}

void io_handler_coco_fdc(u8 addr, u8 write, u8 *data) {
    // CoCo: $FF48-$FF4B map to FDC registers
    if (write) fdc_write(addr - 0x48, *data);
    else *data = fdc_read(addr - 0x48);
}
```

---

### Change 4: Implement Dragon Control Register Handler
**File**: `arm9/source/disk.c`

**New Function**: `io_handler_dragon_ctrl()`

```c
// Dragon DOS control register at $FF48
void io_handler_dragon_ctrl(u8 addr, u8 write, u8 *data) {
    static u8 control_latch = 0;

    if (write) {
        control_latch = *data;

        // Decode Dragon control bits
        u8 drive = control_latch & 0x03;           // Bits 0-1: Binary drive select
        u8 motor = (control_latch >> 2) & 0x01;    // Bit 2: Motor
        u8 density = !((control_latch >> 3) & 0x01); // Bit 3: Density INVERTED (1=SD, 0=DD)
        u8 precomp = (control_latch >> 4) & 0x01;  // Bit 4: Write precomp
        u8 nmi_enable = (control_latch >> 5) & 0x01; // Bit 5: NMI enable

        // Apply to FDC
        fdc_setDrive(drive);
        fdc_setMotor(motor);
        fdc_setDensity(density);
        // TODO: Apply precomp and NMI enable settings

    } else {
        *data = control_latch;  // Read back latch value
    }
}
```

**Rationale**: Dragon uses binary drive select and inverted density logic

---

### Change 5: Update CoCo Control Register Handler
**File**: `arm9/source/disk.c`

**Current Function**: `io_handler_drive_ctrl()` (lines 109-142)

**Rename to**: `io_handler_coco_ctrl()`

**Update Implementation**:
```c
// CoCo control register at $FF40
void io_handler_coco_ctrl(u8 addr, u8 write, u8 *data) {
    static u8 control_latch = 0;

    if (write) {
        control_latch = *data;

        // Decode CoCo control bits
        u8 drive = 0;
        if (control_latch & 0x01) drive = 0;      // Bit 0: DS0
        else if (control_latch & 0x02) drive = 1; // Bit 1: DS1
        else if (control_latch & 0x04) drive = 2; // Bit 2: DS2

        u8 motor = (control_latch >> 3) & 0x01;   // Bit 3: Motor
        u8 precomp = (control_latch >> 4) & 0x01; // Bit 4: Write precomp
        u8 density = (control_latch >> 5) & 0x01; // Bit 5: Density NORMAL (1=DD, 0=SD)
        u8 side = (control_latch >> 6) & 0x01;    // Bit 6: Side select
        u8 halt = (control_latch >> 7) & 0x01;    // Bit 7: Halt enable

        // Apply to FDC
        fdc_setDrive(drive);
        fdc_setMotor(motor);
        fdc_setDensity(density);
        fdc_setSide(side);  // CoCo uses latch bit for side
        // TODO: Apply precomp and halt settings

    } else {
        *data = control_latch;  // Read back latch value
    }
}
```

**Rationale**: CoCo uses one-hot drive select and normal density logic, latch-based side select

---

### Change 6: Side Select Method
**File**: `arm9/source/fdc.c`

**Function to Review**: `fdc_setSide()`

**Expected Behavior**:
- **CoCo**: Side set via latch bit 6 (handled in `io_handler_coco_ctrl()`)
- **Dragon**: Side set via FDC command register SIDE bit

The existing `fdc_setSide()` likely already handles this correctly through the FDC command mechanism. The key difference is:
- CoCo: Calls `fdc_setSide()` from control register handler
- Dragon: Side managed internally by FDC commands, not external latch

**No code changes required** - just ensure CoCo calls `fdc_setSide()` and Dragon doesn't.

## Implementation Steps

### Step 1: Update Controller Selection
**Estimated Complexity**: Low
1. Modify `disk_init()` line 73 to select WD1770 vs WD2793 based on machine type
2. Verify WD1770 constant exists in `fdc.h` (should be value 0)
3. Test both machine types initialize correctly

### Step 2: Update I/O Handler Registration
**Estimated Complexity**: Low
1. Modify `disk_init()` lines 77-88 with conditional registration
2. Ensure address ranges match hardware specs
3. Verify no address conflicts between Dragon and CoCo modes

### Step 3: Implement Dragon FDC Handler
**Estimated Complexity**: Low
1. Rename `io_handler_wd2797()` to `io_handler_dragon_fdc()`
2. Update address offset calculation ($FF40-$FF43 → register 0-3)
3. Test FDC register access works

### Step 4: Implement Dragon Control Handler
**Estimated Complexity**: Medium
1. Create new `io_handler_dragon_ctrl()` function
2. Implement binary drive select decoding
3. Implement inverted density logic
4. Handle NMI enable bit
5. Test all control bits decode correctly

### Step 5: Implement CoCo FDC Handler
**Estimated Complexity**: Low
1. Create `io_handler_coco_fdc()` function
2. Update address offset calculation ($FF48-$FF4B → register 0-3)
3. Test FDC register access works

### Step 6: Update CoCo Control Handler
**Estimated Complexity**: Medium
1. Rename `io_handler_drive_ctrl()` to `io_handler_coco_ctrl()`
2. Implement one-hot drive select decoding
3. Add side select handling via `fdc_setSide()`
4. Add halt enable handling
5. Test all control bits decode correctly

### Step 7: Verify Side Select
**Estimated Complexity**: Low
1. Verify CoCo side select works via latch bit 6
2. Verify Dragon side select works via FDC commands
3. Test multi-sided disk operations on both platforms

## Testing Strategy

### Unit Testing
1. **Controller Selection**
   - Dragon mode → verify WD1770 initialized
   - CoCo mode → verify WD2793 initialized

2. **Dragon Control Register ($FF48)**
   - Write $00 → DS0, motor off, DD, no NMI
   - Write $03 → DS3, motor off, DD, no NMI
   - Write $04 → DS0, motor on, DD, no NMI
   - Write $08 → DS0, motor off, SD, no NMI (inverted!)
   - Write $20 → DS0, motor off, DD, NMI enabled

3. **CoCo Control Register ($FF40)**
   - Write $01 → DS0, motor off, SD
   - Write $02 → DS1, motor off, SD
   - Write $04 → DS2, motor off, SD
   - Write $08 → motor on
   - Write $20 → DD enabled
   - Write $40 → side 1 selected

4. **FDC Register Access**
   - Dragon: $FF40-$FF43 → registers 0-3
   - CoCo: $FF48-$FF4B → registers 0-3

### Integration Testing
1. Load Dragon DOS disk image → verify boots correctly
2. Load CoCo DOS disk image → verify boots correctly
3. Test directory reads on both platforms
4. Test file reads/writes on both platforms
5. Test multi-sided disks on both platforms

### Regression Testing
1. Verify existing CoCo disk operations still work
2. Verify no breakage in tape/cartridge loading
3. Test machine type switching at runtime

## Files Modified
1. **arm9/source/disk.c**
   - Line 73: Controller type selection
   - Lines 77-88: Conditional I/O handler registration
   - Lines 92-106: Rename and split FDC handlers
   - Lines 109-142: Update CoCo control handler
   - New function: Dragon control handler

2. **arm9/source/disk.h**
   - Add function declarations for new handlers (if needed)

## Dependencies
- `020-002-FDCHardwareInterface.techrequirements.md` - Hardware specifications
- `arm9/source/fdc.c` - FDC emulation core
- `arm9/source/fdc.h` - Controller type constants
- `arm9/source/mem.c` - I/O handler registration
- `myConfig.machine` - Machine type configuration variable

## Risk Assessment
- **Low Risk**: Controller type selection (straightforward conditional)
- **Medium Risk**: I/O address mapping (potential conflicts if wrong)
- **Medium Risk**: Bit decoding logic (easy to get backwards)
- **High Risk**: Density inversion (Dragon vs CoCo opposite logic)
- **Medium Risk**: Side select differences (subtle but critical)

## Success Criteria
- [ ] WD1770 controller selected for Dragon DOS (machine == 0)
- [ ] WD2793 controller selected for CoCo (machine != 0)
- [ ] Dragon FDC registers accessible at $FF40-$FF43
- [ ] Dragon control register accessible at $FF48
- [ ] CoCo control register accessible at $FF40
- [ ] CoCo FDC registers accessible at $FF48-$FF4B
- [ ] Dragon drive select uses binary encoding
- [ ] CoCo drive select uses one-hot encoding
- [ ] Dragon density logic inverted (1=SD, 0=DD)
- [ ] CoCo density logic normal (1=DD, 0=SD)
- [ ] CoCo side select via latch bit 6 works
- [ ] Dragon side select via FDC commands works
- [ ] Dragon DOS boots and operates correctly
- [ ] CoCo DOS continues to work correctly
- [ ] No regressions in existing functionality

## Related Documents
- `020-002-FDCHardwareInterface.techrequirements.md` - Hardware specifications reference
- `020-000-DragonDiskSupport.feature.md` - Parent feature plan
- `020-003-ByteTransferStateMachine.component.md` - Related byte transfer changes
- [DRAGONDOS-differences.md](../../DRAGONDOS-differences.md) - Hardware reference documentation
