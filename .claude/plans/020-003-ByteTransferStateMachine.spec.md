# Dragon DOS Byte Transfer Implementation Plan

## Overview
This plan outlines the simplified implementation of Dragon DOS byte transfer, which routes FDC DRQ signals through the existing PIA1 CB1 (CART line) FIRQ mechanism. No state machine or delays are needed due to level-triggered interrupt behavior.

## Key Insight: Level-Triggered FIRQ Eliminates Timing Issues

The Dragon DOS byte transfer does NOT require a state machine or timing delays because:

1. **Level-triggered FIRQ**: PIA1 CB1 triggers FIRQ based on signal LEVEL, not edges
2. **SYNC instruction behavior**: Falls through when ANY interrupt level is active (NMI, FIRQ, IRQ)
3. **DRQ persistence**: FDC DRQ signal stays HIGH until byte is read/written
4. **Auto-clearing**: PIA status register read clears FIRQ when DRQ goes LOW
5. **No race condition possible**: FIRQ stays asserted until CPU services it

### Why No Delay Is Needed:
- If DRQ asserts BEFORE SYNC: FIRQ is already active, SYNC falls through immediately
- If DRQ asserts DURING SYNC: FIRQ becomes active, SYNC falls through on next cycle check
- If DRQ asserts AFTER SYNC but during masked section: FIRQ level stays HIGH, next SYNC will see it
- Reading FDC data register clears DRQ
- Reading PIA status register (when DRQ is LOW) clears FIRQ

## Current Understanding

### Key Requirements:
1. **Use existing PIA CART mechanism**: Same FIRQ CART line logic as autostart cartridges
2. **Route DRQ through PIA**: Connect FDC DRQ to PIA1 CB1 (CART line)
3. **Level-triggered interrupt**: FIRQ stays active until serviced
4. **SYNC instruction behavior**: Falls through on interrupt LEVEL (NMI, FIRQ, IRQ)
5. **Auto-clearing**: PIA read clears FIRQ when DRQ is LOW

## Implementation Plan

### Existing PIA CART Line Mechanism (Already Implemented)

The cartridge autostart feature already provides the exact FIRQ mechanism we need:

**From arm9/source/pia.c:**
```c

// Line 86: Global flag for CART line interrupt enable
uint8_t pia1_cb1_int_enabled = 0;  // CART FIRQ

// Line 392: Existing CART FIRQ mechanism
void pia_cart_firq(void) {
    memory_IO[PIA1_CRB] |= PIA_CR_IRQ_STAT;
    if (pia1_cb1_int_enabled) {
        cpu_firq(INT_FIRQ);
    }
}

// Line 801: Auto-clears on PIA register read when signal is LOW
memory_IO[PIA1_CRB] &= ~PIA_CR_IRQ_STAT;
cpu_firq(0);
```

### Simple Implementation: Route DRQ Through Existing Mechanism

**Files to modify:**
- `arm9/source/fdc.c` - Add DRQ routing for Dragon mode (~10 lines total)

**Complete Implementation:**
```c
// Add external declaration at top of fdc.c
extern void pia_cart_firq(void);

// In fdc_state_machine(), when data becomes ready for READ:
case 0x80: // Read Sector (single)
case 0x90: // Read Sector (multiple)
    if (FDC.wait_for_read == 0) {
        FDC.status |= 0x03;  // Set DRQ + BUSY
        FDC.data = FDC.track_buffer[FDC.track_buffer_idx++];
        FDC.wait_for_read = 1;

        // NEW: Dragon DOS - trigger FIRQ via PIA CART line
        if (Geom.fdc_type == WD1770) {  // WD2797 for Dragon
            pia_cart_firq();
        }
    }
    break;

// In fdc_state_machine(), when ready for WRITE data:
case 0xA0: // Write Sector (single)
case 0xB0: // Write Sector (multiple)
    if (FDC.wait_for_write == 0) {
        FDC.status |= 0x03;  // Set DRQ + BUSY
        FDC.wait_for_write = 1;

        // NEW: Dragon DOS - trigger FIRQ via PIA CART line
        if (Geom.fdc_type == WD1770) {  // WD2797 for Dragon
            pia_cart_firq();
        }
    }
    break;

// In fdc_read_reg(), when CPU reads data register:
case 3: // Data register
    FDC.status &= ~0x02;  // Clear DRQ
    FDC.wait_for_read = 0;
    // DRQ going LOW will allow PIA read to clear FIRQ
    return FDC.data;

// In fdc_write_reg(), when CPU writes data register:
case 3: // Data register
    FDC.status &= ~0x02;  // Clear DRQ
    FDC.wait_for_write = 0;
    FDC.track_buffer[FDC.track_buffer_idx++] = data;
    // DRQ going LOW will allow PIA read to clear FIRQ
    break;
```

### How It Works (No State Machine Needed)

1. **FDC has byte ready**: Call `pia_cart_firq()` to assert FIRQ level
2. **CPU executes SYNC**: Falls through because FIRQ level is active
3. **CPU reads FDC data**: Clears DRQ (FDC status bit)
4. **CPU reads PIA status**: Clears FIRQ (because DRQ is now LOW)
5. **CPU loops to SYNC**: No active interrupt, waits for next byte
6. **Repeat**: Next byte ready, FDC asserts DRQ, FIRQ triggers again

**Total code added**: ~10 lines (1 extern declaration + 2 function calls)

### Testing

**Test 1: FIRQ Trigger Verification**
- Load Dragon DOS
- Start sector read
- Verify `pia_cart_firq()` is called when byte ready
- Verify FIRQ level set in PIA1 CRB

**Test 2: SYNC Behavior**
- Verify SYNC instruction falls through when FIRQ active
- Verify SYNC waits when no interrupt active

**Test 3: Complete Transfer**
- Read full sector (256 bytes)
- Verify all bytes transferred correctly
- Verify FIRQ clears between bytes

**Test 4: CoCo Compatibility**
- Ensure CoCo mode unaffected
- Verify no performance regression

## Critical Implementation Details

### Key Integration Points:
1. **PIA CART Line**: Reuses existing `pia_cart_firq()` mechanism (already works for autostart)
2. **Level-Triggered FIRQ**: No timing delays needed - interrupt stays active until serviced
3. **FDC DRQ Routing**: Just call `pia_cart_firq()` when byte ready (Dragon mode only)
4. **Auto-Clearing**: PIA read clears FIRQ when DRQ is LOW (already implemented)

### Why This Works:
- **No race conditions**: Level-triggered FIRQ can't be missed
- **No state machine**: FDC already has implicit state (wait_for_read/write flags)
- **No delays**: SYNC instruction checks interrupt level continuously
- **Minimal code**: Only ~10 lines added to existing FDC implementation

### Files Modified:
- `arm9/source/fdc.c` - Add 2 calls to `pia_cart_firq()` for Dragon mode (~10 lines total)

## Risk Assessment

### Low Risk:
1. **Uses existing mechanism**: PIA CART FIRQ already tested with autostart cartridges
2. **Minimal code changes**: Only 2 function calls added
3. **No CoCo impact**: Dragon-specific code only executes when `fdc_type == WD1770`
4. **Level-triggered safety**: Can't miss interrupt due to timing

### Success Criteria:
1. Dragon DOS sector reads complete successfully
2. Dragon DOS sector writes complete successfully
3. CoCo mode unaffected (no code changes to CoCo path)
4. No performance regression

## Dependencies

- **Existing PIA CART mechanism**: `pia_cart_firq()` in `arm9/source/pia.c`
- **Existing FDC state machine**: `fdc_state_machine()` in `arm9/source/fdc.c`
- **CPU SYNC behavior**: Must fall through on FIRQ level (already implemented)

## Verification Steps

1. **Compile Test**: Build with new calls to `pia_cart_firq()`
2. **Dragon DOS Boot**: Load Dragon DOS and verify no crashes
3. **Sector Read Test**: Read file from disk, verify data integrity
4. **Sector Write Test**: Write file to disk, verify data persists
5. **CoCo Test**: Switch to CoCo mode, verify disk operations unchanged
```