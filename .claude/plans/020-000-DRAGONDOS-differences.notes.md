## **1. CoCo Floppy Control Latch (`$FF40`)**

| **Bit** | **Function**                 | **Details**                                             |
| ------- | ---------------------------- | ------------------------------------------------------- |
| **0**   | Drive Select 0 (DS0)         | One-hot selection                                       |
| **1**   | Drive Select 1 (DS1)         | One-hot selection                                       |
| **2**   | Drive Select 2 (DS2)         | One-hot selection                                       |
| **3**   | Motor Enable                 | 1 = Motor(s) on                                         |
| **4**   | Write Pre-comp Enable        | High track compensation                                 |
| **5**   | Density Select               | 0 = Single Density, 1 = Double Density                  |
| **6**   | Drive Select 3 / Side Select | DS3 in 4-drive systems, side select under OS-9/NitrOS-9 |
| **7**   | Halt/Wait Enable             | Synchronises CPU for data transfers                     |

---

## **2. DragonDOS Floppy Control Latch (`$FF48`)**

| **Bit** | **Function**               | **Details**                                         |
| ------- | -------------------------- | --------------------------------------------------- |
| **0–1** | Drive Select (binary code) | 00=DS0, 01=DS1, 10=DS2, 11=DS3 (demuxed externally) |
| **2**   | Motor Enable               | 1 = Motor(s) on                                     |
| **3**   | Density Select             | 1 = Single Density, 0 = Double Density              |
| **4**   | Write Pre-comp Enable      | For Single Density operation only                   |
| **5**   | NMI Enable                 | 1 = WD2797 INTRQ triggers NMI, 0 = NMI masked       |
| **6**   | Not Used                   | —                                                   |
| **7**   | Not Used                   | —                                                   |

> **Note:** Side select on DragonDOS is **not controlled by the `$FF48` latch**. It uses the **WD2797 SIDE pin**, which is toggled via the command register.

---

## **3. Side-by-Side Comparison**

| **Function**       | **CoCo (`$FF40`)**                                | **DragonDOS (`$FF48`)**                                   |
| ------------------ | ------------------------------------------------- | --------------------------------------------------------- |
| **Drive Select**   | Bits **0–2** (one-hot DS0–DS2), Bit **6** for DS3 | Bits **0–1** binary, decoded externally to DS0–DS3        |
| **Motor Control**  | Bit **3**                                         | Bit **2**                                                 |
| **Density Select** | Bit **5** (1=DD)                                  | Bit **3** (0=DD, 1=SD) *(inverted logic)*                 |
| **Write Pre-comp** | Bit **4**                                         | Bit **4** (SD only)                                       |
| **Side Select**    | Bit **6** (OS-9/NitrOS-9 configs)                 | Controlled via **WD2797 command register**, not the latch |
| **Halt/Wait**      | Bit **7**                                         | Not supported                                             |
| **NMI Enable**     | Not supported                                     | Bit **5** enables/disables NMI from INTRQ                 |
| **Latch Address**  | `$FF40`                                           | `$FF48`                                                   |

---

## **Key Takeaways**

1. **Drive select schemes differ**
   
   - CoCo uses one-hot bits; Dragon uses binary with external demux.

2. **Side select handling is different**
   
   - CoCo uses the latch for side selection.
   
   - Dragon uses the WD2797 controller directly.

3. **Density control logic is inverted**
   
   - CoCo: `1 = Double Density`.
   
   - Dragon: `0 = Double Density`.

4. **Extra features differ**
   
   - CoCo supports CPU halt data ready sync; Dragon supports SYNC on masked FIRQ via a PIA line for data ready triggering. Both use NMI to exit sector read/write loops.
