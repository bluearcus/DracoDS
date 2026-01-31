# Plan Naming Scheme Guide

## Overview
This document defines the standardized naming convention for all plan files in the DracoDS project. Following this scheme ensures consistency, easy navigation, and clear relationships between plans.

## Naming Convention

### Format
```
NNN-NNN-PlanName.type.md
```

**Components:**
- `NNN-NNN` - Two-part numeric identifier with 3 digits each, separated by dash
  - First part (000-999): Major category/feature
  - Second part (000-999): Sub-component or sequence within category
- `PlanName` - PascalCase descriptive name
- `type` - Lowercase file type suffix
- `.md` - Markdown extension

### Examples
```
000-000-PlanNamingScheme.guide.md
020-000-DragonDiskSupport.feature.md
020-001-MachineTypeConfiguration.component.md
020-002-FdcHardware.component.md
040-000-SaveStateSystem.feature.md
060-000-PerformanceOptimization.phase.md
```

## Numbering System

### First Part: Major Categories (000-999)
The first three-digit number identifies the major category or feature area.

- **000-009**: Meta documentation and guides
  - `000-000-PlanNamingScheme.guide.md` (this file)
  - `001-000-ProjectRoadmap.guide.md`
  - `002-000-ArchitectureOverview.guide.md`

- **010-019**: Core emulation features
  - `010-000-CpuEmulation.feature.md`
  - `011-000-VideoDisplayGenerator.feature.md`
  - `012-000-AudioSystem.feature.md`

- **020-029**: Disk and storage systems
  - `020-000-DragonDiskSupport.feature.md`
  - `021-000-VirtualFloppySystem.feature.md`

- **030-039**: Input and control systems
  - `030-000-JoystickSupport.feature.md`
  - `031-000-KeyboardMapping.feature.md`

- **040-049**: Save/load and persistence
  - `040-000-SaveStateSystem.feature.md`
  - `041-000-ConfigurationManagement.feature.md`

- **050-059**: UI and user experience
  - `050-000-MenuSystem.feature.md`
  - `051-000-TouchScreenInterface.feature.md`

- **060-069**: Performance and optimization
  - `060-000-PerformanceOptimization.phase.md`
  - `061-000-MemoryManagement.phase.md`

- **070-079**: Testing and quality assurance
  - `070-000-TestingStrategy.phase.md`
  - `071-000-IntegrationTests.phase.md`

- **080-089**: Documentation and guides
  - `080-000-UserGuide.doc.md`
  - `081-000-DeveloperGuide.doc.md`

- **090-099**: Miscellaneous and future features
  - `090-000-NetworkPlay.future.md`
  - `091-000-Debugger.future.md`

### Second Part: Sub-Components (000-999)
The second three-digit number identifies sub-components or sequences within a category.
- **000**: Top-level or parent plan for the category
- **001-999**: Sub-components, phases, or related plans

### Hierarchical Organization
For sub-components, use the same first number with incrementing second numbers:

```
020-000-DragonDiskSupport.feature.md               # Parent plan
├── 020-001-MachineTypeConfiguration.component.md
├── 020-002-FdcHardware.component.md
├── 020-003-ByteTransferStateMachine.component.md
├── 020-004-BiosManagement.component.md
└── 020-005-ConfigurationPersistence.component.md
```

## File Type Suffixes

### Primary Types

| Type | Description | Example |
|------|-------------|---------|
| `.feature` | Complete feature implementation plan | `DragonDiskSupport.feature.md` |
| `.component` | Sub-component of a larger feature | `FdcHardware.component.md` |
| `.phase` | Development phase or milestone | `Testing.phase.md` |
| `.guide` | Documentation or guidance document | `PlanNamingScheme.guide.md` |
| `.doc` | User or developer documentation | `UserGuide.doc.md` |
| `.spec` | Technical specification | `FdcProtocol.spec.md` |
| `.future` | Future enhancement or idea | `NetworkPlay.future.md` |
| `.archive` | Completed or deprecated plan | `OldImplementation.archive.md` |

### Type Usage Guidelines

**`.feature`** - Use for:
- Complete feature implementations
- Major system additions
- Self-contained enhancements
- Top-level implementation plans

**`.component`** - Use for:
- Sub-parts of a feature
- Individual modules or subsystems
- Detailed implementation plans for specific aspects
- Components that are part of a larger whole

**`.phase`** - Use for:
- Development phases (Phase 1, Phase 2, etc.)
- Major milestones
- Cross-cutting concerns (testing, optimization)
- Time-based or stage-based plans

**`.guide`** - Use for:
- Meta-documentation about the project
- Process guides
- Naming conventions and standards
- How-to documents for developers

**`.spec`** - Use for:
- Technical specifications
- Protocol definitions
- Hardware interface specifications
- API documentation

**`.future`** - Use for:
- Ideas for future development
- Not-yet-started features
- Research topics
- Enhancement proposals

**`.archive`** - Use for:
- Completed plans
- Deprecated approaches
- Historical reference
- No longer active plans

## PascalCase Naming Guidelines

### General Rules
- Capitalize the first letter of each word
- No spaces, underscores, or hyphens within the name
- Use full words when possible, abbreviations only when common
- Keep names concise but descriptive (2-5 words ideal)

### Good Examples
```
DragonDiskSupport.feature.md
MachineTypeConfiguration.component.md
ByteTransferStateMachine.component.md
FdcHardware.component.md
SaveStateSystem.feature.md
PerformanceOptimization.phase.md
```

### Avoid
```
dragon-disk-support.feature.md      (kebab-case)
machine_type_config.component.md    (snake_case)
FDCHARDWARE.component.md            (all caps)
fdchardware.component.md            (no capitals)
FDCHWSupport.component.md           (too abbreviated)
```

### Common Abbreviations
When abbreviations are well-known, use them:
- `Fdc` - Floppy Disk Controller
- `Pio` - Parallel Input/Output
- `Cpu` - Central Processing Unit
- `Vdg` - Video Display Generator
- `Bios` - Basic Input/Output System
- `Rom` - Read-Only Memory
- `Ram` - Random Access Memory
- `Ui` - User Interface
- `Api` - Application Programming Interface

## Organizing Hierarchical Plans

### Parent-Child Relationship
The numbering system creates a clear hierarchy using matching first numbers:

```
020-000-DragonDiskSupport.feature.md               # Parent plan (020-000)
├── 020-001-MachineTypeConfiguration.component.md
├── 020-002-FdcHardware.component.md
├── 020-003-ByteTransferStateMachine.component.md
├── 020-004-BiosManagement.component.md
└── 020-005-ConfigurationPersistence.component.md
```

### Cross-Referencing
In parent plans, reference sub-plans using relative links:

```markdown
### Component Plans

1. [Machine Type Configuration](./020-001-MachineTypeConfiguration.component.md)
2. [FDC Hardware](./020-002-FdcHardware.component.md)
3. [Byte Transfer State Machine](./020-003-ByteTransferStateMachine.component.md)
```

### Linking Between Plans
Use relative paths for all internal links:

```markdown
See also: [Save State System](./040-000-SaveStateSystem.feature.md)
Related: [Configuration Management](./041-000-ConfigurationManagement.feature.md)
Depends on: [FDC Hardware](./020-002-FdcHardware.component.md)
```

## Migration Plan

### Converting Existing Plans

Current plans should be renamed to follow the new scheme:

| Old Name | New Name |
|----------|----------|
| `DragonDiskSupport.md` | `020-000-DragonDiskSupport.feature.md` |
| `MachineTypeConfiguration.md` | `020-001-MachineTypeConfiguration.component.md` |
| `FDC-Hardware.md` | `020-002-FdcHardware.component.md` |
| `ByteTransferStateMachine.md` | `020-003-ByteTransferStateMachine.component.md` |
| `BIOS-Management.md` | `020-004-BiosManagement.component.md` |
| `Configuration-Persistence.md` | `020-005-ConfigurationPersistence.component.md` |
| `dragon-dos-byte-transfer-state-machine.md` | `020-003-ByteTransferStateMachine.spec.md` |

### Migration Steps

1. **Backup**: Create backup of current plans directory
2. **Rename**: Rename files according to new scheme
3. **Update Links**: Update all cross-references in plan documents
4. **Validate**: Verify all links still work
5. **Document**: Update any external documentation referencing old names

### Git Commands for Migration

```bash
# Example rename commands
cd .claude/plans
git mv DragonDiskSupport.md 020-000-DragonDiskSupport.feature.md
git mv MachineTypeConfiguration.md 020-001-MachineTypeConfiguration.component.md
git mv FDC-Hardware.md 020-002-FdcHardware.component.md
# ... etc
```

## Template Structure

### Feature Template
```markdown
# Feature Name

## Overview
Brief description of the feature and its purpose.

## Component Plans
List of sub-components with links to their detailed plans.

## Implementation Phases
High-level phases of implementation.

## Dependencies
Other features or systems this depends on.

## Risk Assessment
Potential risks and mitigation strategies.

## Testing Strategy
How this feature will be tested.
```

### Component Template
```markdown
# Component Name

## Overview
What this component does within the larger feature.

## Implementation Details
Detailed technical implementation.

## Files Modified
List of files that will be changed.

## Testing
Component-specific testing approach.

## Dependencies
Related components or systems.
```

## Best Practices

### DO
- Use descriptive, clear names that convey purpose
- Follow the numbering scheme consistently
- Keep hierarchies shallow (2-3 levels max)
- Update this guide when adding new categories
- Link related plans together
- Use appropriate type suffixes

### DON'T
- Use inconsistent capitalization
- Create deeply nested hierarchies (more than 3 levels)
- Use vague or generic names
- Mix naming conventions
- Create orphaned plans without parent references
- Skip numbering or use inconsistent numbers

## Future Enhancements

### Potential Additions
- Status indicators in filenames (e.g., `.wip`, `.review`, `.approved`)
- Version numbers for major plan revisions
- Author or owner tags
- Priority indicators

### Under Consideration
```
NNN-NNN-PlanName.type.status.md
020-000-DragonDiskSupport.feature.approved.md
021-000-VirtualFloppy.feature.wip.md
```

## Questions or Changes

If you have questions about naming a plan or want to propose changes to this scheme:
1. Document the question or proposal
2. Discuss with project maintainer
3. Update this guide with decisions
4. Communicate changes to team

---

**Document Version**: 1.0
**Last Updated**: 2026-01-27
**Maintainer**: Project Lead
