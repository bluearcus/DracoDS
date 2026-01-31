# Byte Transfer State Machine Component

## Overview
Implement Dragon DOS byte transfer by routing FDC DRQ through PIA1 CB1 to generate level-triggered FIRQ. No timing delays needed - the existing level-triggered interrupt mechanism handles SYNC timing correctly.

## Key Insight
**No delay state machine needed!** Dragon DOS works with existing code if:
1. DRQ routes through PIA1 CB1 (like cartridge autostart)
2. FIRQ is level-triggered (already is)
3. SYNC checks FIRQ level (already does)
4. Reading PIA status clears FIRQ when DRQ is low (already implemented)

## Hardware Flow (Dragon DOS)

```
1. FDC: DRQ high (byte ready)
2. PIA1 CB1: Sees DRQ, sets FIRQ level (if pia1_cb1_int_enabled)
3. CPU: At SYNC, checks FIRQ level → falls through
4. CPU: LDA $FF40 (reads FDC data) → DRQ goes low
5. CPU: LDA $FF03 (reads PIA1 CRB) → FIRQ clears (DRQ now low)
6. CPU: SYNC (waits for next FIRQ)
7. (Loop back to step 1)
```

**Critical**: Level-triggered interrupts mean FIRQ stays asserted as long as DRQ is high. SYNC will always fall through when checked - no timing window issues!

## Existing Infrastructure

### PIA1 CB1 CART Line (Already Implemented)
**File**: `arm9/source/pia.c`

```c
// Line 86: Global flag
uint8_t pia1_cb1_int_enabled = 0;  // CART FIRQ

// Line 392: Trigger FIRQ (already implemented for cartridge autostart)
void pia_cart_firq(void) {
    memory_IO[PIA1_CRB] |= PIA_CR_IRQ_STAT;  // Set IRQ status bit
    if (pia1_cb1_int_enabled) {
        cpu_firq(INT_FIRQ);  // Assert level-triggered FIRQ
    }
}

// Line 801: Clear FIRQ on PIA1 PB read (already implemented)
memory_IO[PIA1_CRB] &= ~PIA_CR_IRQ_STAT;  // Clear status bit
cpu_firq(0);  // De-assert FIRQ
```

### FDC DRQ Status (Implicit in Current Code)
**File**: `arm9/source/fdc.c`

```c
// Line 190: DRQ implicitly set when data ready
FDC.status |= 0x03;  // Data Ready bit (bit 1 = DRQ)

// Line 280: DRQ implicitly cleared when data read
FDC.status &= ~0x02;  // Clear Data Available flag
```

## Required Changes

### Change 1: Route FDC DRQ to PIA1 CB1
**File**: `arm9/source/fdc.c`

**In Read Sector** (after line 190, when data becomes ready):
```c
case 0x80: // Read Sector (single)
case 0x90: // Read Sector (multiple)
    if (FDC.wait_for_read == 0) {
        FDC.status |= 0x03;  // Data ready, DRQ high
        FDC.data = FDC.track_buffer[FDC.track_buffer_idx++];
        FDC.wait_for_read = 1;

        // Dragon DOS: Route DRQ through PIA1 CB1 FIRQ
        if (Geom.fdc_type == WD1770) {  // Dragon (WD2797)
            pia_cart_firq();  // Trigger level FIRQ via existing mechanism
        }

        // ... rest of sector handling ...
    }
    break;
```

**In Write Sector** (after line 228, when ready for next byte):
```c
case 0xA0: // Write Sector (single)
case 0xB0: // Write Sector (multiple)
    if (FDC.wait_for_write == 0) {
        FDC.track_buffer[FDC.track_buffer_idx++] = FDC.data;

        if (FDC.track_buffer_idx < FDC.track_buffer_end) {
            FDC.status |= 0x03;  // Data request, DRQ high
            FDC.wait_for_write = 1;

            // Dragon DOS: Route DRQ through PIA1 CB1 FIRQ
            if (Geom.fdc_type == WD1770) {  // Dragon (WD2797)
                pia_cart_firq();  // Trigger level FIRQ via existing mechanism
            }

            // ... rest of sector handling ...
        }
    }
    break;
```

---

### Change 2: Clear DRQ-triggered FIRQ on Data Access
**File**: `arm9/source/fdc.c`

**In fdc_read()** (after line 280, when CPU reads data):
```c
case 3:  // Data register
    FDC.status &= ~0x02;  // Clear DRQ
    FDC.wait_for_read = 0;

    // Dragon DOS: DRQ now low, FIRQ will clear on next PIA read
    // (PIA already handles this in io_handler_pia1_pb line 801)

    return FDC.data;
```

**In fdc_write()** (after line 314, when CPU writes data):
```c
case 3:  // Data register
    FDC.data = data;
    FDC.status &= ~0x02;  // Clear DRQ
    FDC.wait_for_write = 0;

    // Dragon DOS: DRQ now low, FIRQ will clear on next PIA read
    // (PIA already handles this in io_handler_pia1_pb line 801)

    break;
```

---

### Change 3: Declare External Function
**File**: `arm9/source/fdc.c`

Add at top of file (around line 36):
```c
extern void pia_cart_firq(void);  // PIA1 CB1 CART line FIRQ trigger
```

---

### Change 4: Export PIA Function (if needed)
**File**: `arm9/source/pia.h`

Verify function is declared:
```c
extern void pia_cart_firq(void);
```

If not present, add it.

## Why No Delay Is Needed

### Level-Triggered Interrupt Behavior
```c
// In cpu.c (existing SYNC implementation)
if (cpu.cpu_state == CPU_SYNC) {
    if (intr_latch & (INT_NMI | INT_FIRQ | INT_IRQ)) {  // Checks LEVEL
        cpu.cpu_state = CPU_EXEC;  // Falls through immediately
    }
}
```

**Key**: SYNC checks the current interrupt LEVEL, not edges. As long as DRQ is high:
- FIRQ stays asserted (level-triggered)
- SYNC will fall through whenever checked
- No race condition possible

### Timing Sequence
```
Cycle 0:   FDC sets DRQ high
Cycle 1:   pia_cart_firq() sets FIRQ level
Cycle 2:   CPU at SYNC instruction
Cycle 3:   SYNC checks FIRQ level → HIGH → fall through
Cycle 4:   CPU reads $FF40 (FDC data) → DRQ goes low
Cycle 5:   FIRQ still set (status bit latched in PIA)
Cycle 6:   CPU reads $FF03 (PIA1 CRB) → clears FIRQ (DRQ now low)
Cycle 7:   CPU executes SYNC again
Cycle 8:   SYNC checks FIRQ level → LOW → waits
```

**No timing window**: FIRQ level persists from cycle 1 until cycle 6, giving SYNC plenty of time to detect it.

## Implementation Steps

### Step 1: Add External Declaration
1. Add `extern void pia_cart_firq(void);` to top of `fdc.c`
2. Verify `pia_cart_firq()` is declared in `pia.h`
3. Test compilation

### Step 2: Route DRQ in Read Sector
1. Add `pia_cart_firq()` call in read sector when data ready (Dragon only)
2. Test Dragon DOS read operations
3. Verify CoCo reads still work (no pia_cart_firq call)

### Step 3: Route DRQ in Write Sector
1. Add `pia_cart_firq()` call in write sector when ready for data (Dragon only)
2. Test Dragon DOS write operations
3. Verify CoCo writes still work (no pia_cart_firq call)

### Step 4: Integration Testing
1. Test complete Dragon DOS disk operations
2. Verify SYNC timing works correctly
3. Verify no regressions in CoCo mode
4. Test mode switching

## Testing Strategy

### Unit Tests
1. **FIRQ Triggering**: Verify `pia_cart_firq()` called when DRQ high (Dragon only)
2. **FIRQ Clearing**: Verify FIRQ clears after PIA read and DRQ low
3. **Level Persistence**: Verify FIRQ level persists until PIA read
4. **CoCo Bypass**: Verify CoCo doesn't call `pia_cart_firq()`

### Integration Tests
1. **Dragon DOS Read**: Load sector, verify SYNC-based transfer works
2. **Dragon DOS Write**: Write sector, verify SYNC-based transfer works
3. **CoCo Read**: Verify polled transfer still works (no regression)
4. **CoCo Write**: Verify polled transfer still works (no regression)

### Timing Tests
1. **SYNC Behavior**: Verify SYNC falls through on FIRQ level
2. **No Race Conditions**: Verify level-triggered behavior eliminates timing issues
3. **PIA Read Clears**: Verify reading PIA1 CRB clears FIRQ when DRQ low

## Files Modified
1. **arm9/source/fdc.c**
   - Add external declaration for `pia_cart_firq()`
   - Call `pia_cart_firq()` in read sector when data ready (Dragon only)
   - Call `pia_cart_firq()` in write sector when ready for data (Dragon only)

2. **arm9/source/pia.h** (possibly)
   - Verify `pia_cart_firq()` is declared

## Dependencies
- `020-002-FDCHardwareInterface.component.md` - Controller type selection (WD1770 vs WD2793)
- Existing PIA1 CB1 FIRQ mechanism (`pia_cart_firq()` in `pia.c`)
- Existing CPU SYNC implementation (level-triggered interrupt checking)
- `Geom.fdc_type` variable for platform detection

## Risk Assessment
- **Very Low Risk**: Uses existing, tested PIA CART FIRQ mechanism
- **Very Low Risk**: Level-triggered interrupts eliminate timing issues
- **Very Low Risk**: CoCo code path completely unchanged
- **Low Risk**: Only adds 2 function calls in Dragon-specific code paths

## Success Criteria
- [ ] `pia_cart_firq()` declared as external in fdc.c
- [ ] Read sector calls `pia_cart_firq()` when data ready (Dragon only)
- [ ] Write sector calls `pia_cart_firq()` when ready for data (Dragon only)
- [ ] CoCo operations work without regression
- [ ] Dragon DOS sector reads work with SYNC-based transfer
- [ ] Dragon DOS sector writes work with SYNC-based transfer
- [ ] FIRQ correctly triggers and clears via PIA mechanism
- [ ] No timing issues or race conditions

## Why This Is Simpler

**Previous approach**: Complex state machine with delay counters, state transitions, timing tuning.

**This approach**:
- Add 2 function calls: `pia_cart_firq()`
- Use existing PIA CART line mechanism
- Level-triggered interrupts handle all timing automatically
- No state machine, no delays, no tuning needed

**Code changes**: ~10 lines added vs. ~200 lines in state machine approach.

## Related Documents
- `020-002-FDCHardwareInterface.component.md` - Controller selection
- `020-000-DragonDiskSupport.feature.md` - Parent feature
- [DRAGONDOS-differences.md](../../DRAGONDOS-differences.md) - Hardware reference
