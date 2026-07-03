# AtlasRV Project Specification

## 1. Project Objective

AtlasRV is a synthesizable, single-issue, in-order, 5-stage pipelined RV32I processor implemented in SystemVerilog.

The project is intended to demonstrate professional RTL design, verification discipline, synthesis readiness, static timing awareness, functional gate-level simulation, and ASIC physical implementation.

AtlasRV prioritizes correctness, clean architecture, verification quality, timing awareness, and documentation over feature count.

## 2. Processor Class

AtlasRV is an embedded-class RISC-V processor.

It is:

- Single-issue
- In-order
- 32-bit
- RV32I-based
- Harvard-style
- ASIC-oriented

AtlasRV v1 is not intended to support operating systems, privilege modes, interrupts, caches, or complex SoC interfaces.

## 3. ISA Scope

AtlasRV v1 supports the RV32I base integer instruction set.

Supported instruction groups:

### R-Type ALU

- ADD
- SUB
- SLL
- SLT
- SLTU
- XOR
- SRL
- SRA
- OR
- AND

### I-Type ALU

- ADDI
- SLTI
- SLTIU
- XORI
- ORI
- ANDI
- SLLI
- SRLI
- SRAI

### Loads

- LB
- LH
- LW
- LBU
- LHU

### Stores

- SB
- SH
- SW

### Branches

- BEQ
- BNE
- BLT
- BGE
- BLTU
- BGEU

### Jumps

- JAL
- JALR

### Upper Immediate

- LUI
- AUIPC

## 4. Explicitly Excluded From v1

The following are excluded from AtlasRV v1:

- Compressed instructions
- CSR instructions
- Privilege modes
- Exceptions
- Interrupts
- Branch prediction
- Caches
- MMU
- AXI
- APB
- PCIe
- DDR
- Ethernet
- Linux support

These are future extensions only.

## 5. Word Size

AtlasRV uses a 32-bit datapath.

This matches RV32I, which defines:

- 32-bit architectural registers
- 32-bit integer operations
- 32-bit instruction words
- 32-bit program counter and address values in this implementation

## 6. Pipeline Architecture

AtlasRV uses a classic 5-stage in-order pipeline:

```text
IF  - Instruction Fetch
ID  - Instruction Decode / Register Read
EX  - Execute / Branch Resolution
MEM - Data Memory Access
WB  - Register Writeback
