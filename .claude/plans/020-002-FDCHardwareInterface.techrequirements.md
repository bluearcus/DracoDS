# FDC Hardware Interface Technical Requirements

## Hardware Specifications

### WD2797 (Dragon DOS)
- **Controller Type**: WD2797
- **Control Register Address**: $FF48
- **Drive Select**: Bits 0-1 (binary encoding)
  - 00 = DS0 (Drive 0)
  - 01 = DS1 (Drive 1)
  - 10 = DS2 (Drive 2)
  - 11 = DS3 (Drive 3)
- **Motor Enable**: Bit 2
- **Density Select**: Bit 3 (INVERTED LOGIC)
  - 0 = Double Density
  - 1 = Single Density
- **NMI Enable**: Bit 5
- **Side Select**: Through WD2797 SIDE pin (NOT via latch bit)

### WD2793 (Tandy CoCo)
- **Controller Type**: WD2793
- **Control Register Address**: $FF40
- **Drive Select**: Bits 0-2 (one-hot encoding)
  - 001 = DS0 (Drive 0)
  - 010 = DS1 (Drive 1)
  - 100 = DS2 (Drive 2)
  - 111 = DS3 (Drive 3)
- **Motor Enable**: Bit 3
- **Density Select**: Bit 5 (NORMAL LOGIC)
  - 0 = Single Density
  - 1 = Double Density
- **Side Select**: Bit 6 (latch-based)
- **Halt/Wait**: Bit 7 (CPU synchronization)

## Critical Differences

### 1. Control Latch Address
- Dragon: $FF48
- CoCo: $FF40

### 2. FDC Base and Address range
- Dragon: $FF40-FF43
- CoCo: $FF48-FF4B
### 3. Drive Select Encoding in Control Latch
- Dragon: Binary encoding in bits 0-1
- CoCo: One-hot encoding in bits 0-2

### 3. Motor Enable Bit Position in Control Latch
- Dragon: Bit 2
- CoCo: Bit 3

### 4. Density Select Logic in Control Latch
- Dragon: Bit 3, INVERTED (0=DD, 1=SD)
- CoCo: Bit 5, NORMAL (0=SD, 1=DD)

### 5. Side Select Method
- Dragon: Via WD2797 SIDE pin (command-based)
- CoCo: Via latch bit 6 (register-based, but note sides must also be set correctly in commands, to ensure sectors are matched correctly. The FDC simply does not have enough pins to output a side signal, so it must be externally generated)

### 6. Additional Features
- Dragon: NMI Enable (bit 5)
- CoCo: Halt/Wait and NMI Enable (bit 7)

## Reference Documentation
- WD2797 Datasheet
- WD2793 Datasheet
- Dragon DOS Technical Manual
- CoCo DOS Technical Reference
