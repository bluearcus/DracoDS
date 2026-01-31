# Dragon Disk Support Implementation Plan for DracoDS

## Overview
This plan outlines the implementation of full Dragon DOS support in DracoDS, enhancing the existing Dragon 32 emulation with proper disk operating system functionality. The implementation is broken down into component features, each with detailed sub-plans.

## Feature Summary

### 1. [MachineTypeConfiguration.md](./MachineTypeConfiguration.md)
**Status**: Planning
**Description**: Expand machine type configuration to support Dragon DOS independently of media type selection.

**Key Changes**:
- Remove forced CoCo mode when loading disk files
- Add DragonDOS DOS type to machine type selection
- Update BIOS loading logic based on machine + media combination

**Files Modified**:
- `arm9/source/DracoUtils.c` - Remove machine type lock line 770
- `arm9/source/dragon.c` - Update ROM selection logic

---

### 2. [FDC-Hardware.md](./FDC-Hardware.md)
**Status**: Planning
**Description**: Implement complete FDC hardware differences between WD2797 (Dragon) and WD2793 (CoCo) controllers.

**Key Changes**:
- Controller selection based on machine type
- Control register bit mapping differences ($FF48 vs $FF40)
- Side select handling (WD2797 pin vs CoCo latch bit)
- Density control logic (inverted for Dragon)

**Files Modified**:
- `arm9/source/fdc.c` - Add controller type selection
- `arm9/source/disk.c` - Control register handlers

---

### 3. [ByteTransferStateMachine.md](./ByteTransferStateMachine.md)
**Status**: Planning
**Description**: Implement dual data transfer modes - SYNC'd byte access (Dragon) vs polled byte access (CoCo).

**Key Changes**:
- Dragon: Use existing PIA CART line FIRQ mechanism for SYNC'd transfers
- CoCo: Maintain current polled implementation
- Comprehensive state machine with proper timing delays
- CPU SYNC instruction falls through on all interrupt types

**Files Modified**:
- `arm9/source/fdc.c` - Add Dragon DOS state machine
- No changes needed to `pia.c` (existing mechanism works)

---

### 4. [BIOS-Management.md](./BIOS-Management.md)
**Status**: Planning
**Description**: Implement automatic BIOS selection based on machine type and media format.

**Key Changes**:
- Dragon DOS: Load `dragonDos.rom` for disk operations
- Tandy CoCo: Load existing `disk11.rom`
- Dragon BASIC for non-disk files in Dragon mode
- Fallback handling for missing ROM files

**Files Modified**:
- `arm9/source/dragon.c` - Update ROM loading logic
- Add support for `dragonDos.rom` file

---

### 5. [Configuration-Persistence.md](./Configuration-Persistence.md)
**Status**: Planning
**Description**: Ensure machine type selection persists and maintains backward compatibility.

**Key Changes**:
- Verify config format compatibility
- Error handling for missing Dragon DOS ROM
- Graceful degradation to Dragon BASIC

**Files Modified**:
- `arm9/source/DracoUtils.c` - Configuration handling

---

## Implementation Phases

### Phase 1: Core Architecture Changes
1. Remove machine type lock in DracoUtils.c
2. Update machine type selection UI
3. Expand configuration structure if needed

### Phase 2: Hardware Implementation
1. Implement FDC controller selection
2. Add proper control register handling
3. Implement automatic disk system selection

### Phase 3: Advanced Features
1. Implement dual byte transfer modes
2. Update BIOS loading logic
3. Add ROM file search enhancements

### Phase 4: Testing and Validation
1. Hardware-specific validation tests
2. Integration testing across modes
3. Performance and compatibility verification

## Current State Analysis
- Dragon DOS references already exist in `disk.c` and `pia.c`
- WD2797 controller is emulated but currently only used when `myConfig.machine = 0` (Dragon mode)
- The system forces `myConfig.machine = 1` in disk mode, preventing Dragon DOS from working
- Configuration system supports machine type selection but lacks DOS-specific options
- ROM loading infrastructure exists but needs DOS ROM support
- PIA CART line FIRQ mechanism already exists for autostart cartridges
- CPU SYNC instruction correctly falls through on all interrupt types (already implemented)

## Detailed Implementation Plans

### Phase 1: Core Architecture Changes
See: [MachineTypeConfiguration.md](./MachineTypeConfiguration.md)

### Phase 2: Hardware Implementation
See: [FDC-Hardware.md](./FDC-Hardware.md)

### Phase 3: Advanced Features
See: [ByteTransferStateMachine.md](./ByteTransferStateMachine.md)
See: [BIOS-Management.md](./BIOS-Management.md)

### Phase 4: Testing and Validation
See: [Configuration-Persistence.md](./Configuration-Persistence.md)

## Additional Supporting Documents
- [DRAGONDOS-differences.md](./../DRAGONDOS-differences.md) - Hardware specifications

## Risk Assessment

### High Risk Items
- **Dual data transfer modes** (SYNC'd with FIRQ vs polled byte access)
- **FDC controller differences** (WD2797 vs WD2793)
- **Control register interpretation** (different bit mappings)
- **Side select implementation** (WD2797 pin vs latch bit)
- **Integration testing** of both systems in one codebase

### Medium Risk Items
- **ROM loading logic enhancement** (existing pattern)
- **Error handling for missing Dragon DOS ROM**
- **Backward compatibility with existing configurations**

### Low Risk Items
- **Machine type selection UI** (no changes needed)
- **Configuration persistence** (no format changes)
- **Disk file format compatibility** (same .dsk structure)

## Timeline Estimate

- Phase 1: 1-2 days (Remove machine type lock)
- Phase 2: 4-5 days (Implement complete Dragon DOS hardware support + dual transfer modes)
- Phase 3: 2-3 days (BIOS loading and ROM management)
- Phase 4: 1-2 days (Configuration and error handling)
- Phase 5: 3-4 days (Comprehensive hardware testing)
- **Total**: 11-16 days

## Critical Dependencies

- **Dragon DOS ROM image** (`dragonDos.rom`) - 8KB BIOS file
- **Hardware specifications** (DRAGONDOS-differences.md)
- **Testing disk images** for both Dragon DOS and CoCo systems
- **Existing FDC implementation** that supports both WD2793 and WD2797
- **Current devkitPro environment** with libnds 1.8.2-1
- **Integration with existing PIA CART line mechanism** (no changes needed)

## Verification Steps

1. **Compile Test**: Build project with new changes
2. **ROM Loading**: Verify Dragon DOS ROM loads correctly
3. **Disk Operations**: Test basic disk read/write
4. **Machine Selection**: Test switching between Dragon 32, CoCo, and DOS
5. **UI Integration**: Verify new options appear in menus
6. **Configuration**: Save/load settings with new fields
7. **Performance**: Ensure no performance degradation