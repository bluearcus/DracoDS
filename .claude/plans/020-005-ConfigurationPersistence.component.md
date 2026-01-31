# Configuration and Persistence Implementation

## Overview
This component ensures that machine type selection persists across save/load cycles and maintains backward compatibility with existing configurations.

## Current Configuration System

### Configuration Structure
```c


// In DracoUtils.h
struct Config_t {
    u32 game_crc;
    u8  keymap[12];
    u8  machine;              // 0 = Dragon 32, 1 = Tandy CoCo
    u8  autoLoad;
    u8  gameSpeed;
    // ... other fields
};
```

### Current Machine Type Handling
- Machine type is stored as a single byte
- 0 = Dragon 32
- 1 = Tandy CoCo
- No disk system specific fields needed

## Changes Required

### 1. Verify Configuration Compatibility
**File**: `arm9/source/DracoUtils.c`

**Current Save/Load Logic**: Already handles machine type byte correctly.

**Verification Needed**:
- Machine type is properly saved to configuration
- Machine type is properly loaded from configuration
- No changes needed to save/load format

### 2. Configuration Validation
```c
// Add configuration validation
void validate_config(void) {
    // Ensure machine type is valid
    if (myConfig.machine > 1) {
        debug_printf("Invalid machine type %d, defaulting to Dragon 32\n", myConfig.machine);
        myConfig.machine = 0; // Default to Dragon 32
    }

    // Ensure autoLoad is valid
    if (myConfig.autoLoad > 1) {
        debug_printf("Invalid autoLoad value %d, defaulting to 1\n", myConfig.autoLoad);
        myConfig.autoLoad = 1;
    }

    // ... other validation ...
}
```

### 3. Error Handling for Missing ROMs
**File**: `arm9/source/dragon.c`

**Enhanced Error Handling**:
```c
int load_system_bios(void) {
    int result = 0;

    if (myConfig.machine == 0) { // Dragon 32
        if (draco_mode == MODE_DSK) {
            // Try to load Dragon DOS
            if (!load_dragon_dos_rom()) {
                debug_printf("Dragon DOS ROM not available\n");
                // Fallback to Dragon BASIC
                if (!load_dragon_basic_rom()) {
                    debug_printf("ERROR: Dragon BASIC ROM not available\n");
                    return 0;
                }
                debug_printf("Using Dragon BASIC as fallback\n");
            }
            result = 1;
        } else {
            // Load Dragon BASIC
            if (!load_dragon_basic_rom()) {
                debug_printf("ERROR: Dragon BASIC ROM not available\n");
                return 0;
            }
            result = 1;
        }
    } else { // Tandy CoCo
        // Existing CoCo loading logic
        result = load_coco_bios();
    }

    return result;
}
```

## Implementation Steps

### Step 1: Configuration Format Verification
1. Examine current save/load implementation
2. Verify machine type is properly serialized/deserialized
3. Check for any version compatibility issues

### Step 2: Add Configuration Validation
1. Add validate_config() function
2. Call validation after loading configuration
3. Ensure invalid values are corrected with appropriate warnings

### Step 3: Enhanced Error Handling
1. Add ROM availability checking
2. Implement fallback logic with proper error messages
3. Ensure graceful degradation when ROMs are missing

### Step 4: Testing
1. Test configuration save/load cycles
2. Test with invalid configuration files
3. Test missing ROM scenarios

## Testing Scenarios

### 1. Configuration Persistence
- Select Dragon 32, save configuration
- Exit and reload, verify machine type persists
- Select Tandy CoCo, save configuration
- Exit and reload, verify machine type persists

### 2. Configuration Validation
- Test with invalid machine type values
- Test with corrupted configuration files
- Test with missing configuration file (create default)

### 3. Error Handling
- Test with missing Dragon DOS ROM
- Test with missing Dragon BASIC ROM
- Test with missing CoCo ROM
- Verify appropriate error messages are displayed

## Files Modified
- `arm9/source/DracoUtils.c` - Configuration validation
- `arm9/source/dragon.c` - Enhanced error handling
- `arm9/source/saveload.c` - Verify save/load compatibility

## Configuration File Format

### Current Format (Binary)
```c
// Configuration structure is saved directly as binary
// All fields are in little-endian format
struct Config_t {
    u32 game_crc;     // Game CRC for auto-detection
    u8  keymap[12];   // Key mapping configuration
    u8  machine;      // Machine type (0=Dragon, 1=CoCo)
    u8  autoLoad;     // Auto-load enabled (0/1)
    u8  gameSpeed;    // Game speed setting
    // ... other fields
};
```

### Version Compatibility
- Current version: 1 (existing format)
- New version: 1 (no changes needed)
- Backward compatibility: Maintained
- Forward compatibility: Maintained

## Risk Assessment
- **Low Risk**: Configuration system is already established
- **Medium Risk**: Need to ensure compatibility across versions
- **Low Risk**: Error handling follows existing patterns

## Backward Compatibility Considerations

### Existing Configurations
- All existing configurations will work unchanged
- Machine type field is already properly handled
- No format changes required

### Default Values
- New installations default to Dragon 32
- Existing installations retain their machine type setting
- Invalid values are corrected with warnings

## Migration Strategy

### Automatic Migration
- No migration needed - format is compatible
- Invalid values are corrected at runtime
- Missing ROMs trigger fallback with user notification

### User Notification
- When Dragon DOS ROM is missing, user is notified of fallback
- When configuration is corrected, warning is displayed
- Error messages are clear and actionable

## Dependencies
- Existing save/load system
- Debug logging infrastructure
- ROM loading functions

## Performance Considerations
- Configuration validation adds minimal overhead
- Error handling only triggered on actual errors
- Debug logging can be disabled in release builds

## Related Components
- 020-004-BiosManagement.component.md - ROM loading that configuration depends on
- 030-000-VersionIdentification.feature.md - Version display system (separate feature)
```