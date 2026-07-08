# AtlasRV: A 5-Stage Pipelined RV32I Processor ASIC

**Status: Ongoing**

AtlasRV is an ongoing SystemVerilog project building toward a 32-bit RV32I processor suitable for a future ASIC implementation flow. The near-term focus is clean RTL architecture, instruction-level datapath correctness, directed verification, and disciplined documentation before expanding into synthesis, STA, and physical design work.

This repository currently contains RV32I front-end and datapath building blocks, directed module-level testbenches, and an in-progress single-cycle reference path used to validate control and datapath behavior while the final 5-stage pipeline is developed.

## Project Overview

The project goal is to develop an RV32I processor from RTL through verification and, later, ASIC implementation steps. AtlasRV is intended to grow into a classic in-order 5-stage pipeline:

```text
IF  - Instruction Fetch
ID  - Instruction Decode / Register Read
EX  - Execute / Branch Resolution
MEM - Data Memory Access
WB  - Register Writeback
```

The current codebase should be treated as an active development snapshot, not a completed pipelined CPU.

## Current Status

- Implemented initial RV32I RTL modules for arithmetic, register access, immediate generation, decode/control, branching, and load/store data handling.
- Added directed SystemVerilog testbenches for the implemented standalone modules.
- Added an in-progress single-cycle reference core under `rtl_single_cycle/` to exercise instruction fetch, decode, execute, and writeback behavior before full pipeline integration.
- Documented the intended RV32I scope and 5-stage pipeline direction in `docs/specification.md`.

## Architecture Goal

AtlasRV targets a single-issue, in-order RV32I processor with separate instruction and data memory interfaces. The planned pipelined implementation will include stage registers, forwarding, hazard detection, load-use stall handling, and branch/jump flush logic.

The project intentionally excludes compressed instructions, privilege modes, CSRs, interrupts, caches, MMU support, and complex SoC buses from the initial version.

## Implemented Modules

Current RTL includes:

- `rtl/rv32i_pkg.sv` - RV32I package definitions, opcodes, ALU operation enums, branch operation enums, load/store operation enums, and control structures.
- `rtl/alu.sv` - RV32I ALU operations for arithmetic, logic, comparison, and shifts.
- `rtl/regfile.sv` - 32-entry register file with x0 hardwired to zero.
- `rtl/imm_gen.sv` - Immediate generation for RV32I instruction formats.
- `rtl/decoder.sv` - RV32I decode and control generation for implemented instruction classes.
- `rtl/branch_unit.sv` - Branch comparison and branch-taken decision logic.
- `rtl/load_store_unit.sv` - Load/store byte-enable, write-data alignment, and load-data extension logic.
- `rtl_single_cycle/rv32i_single_cycle_core.sv` - In-progress single-cycle reference core path used during bring-up.

## Verification Status

Directed testbenches are provided under `tb/` for:

- ALU
- Register file
- Immediate generator
- Decoder
- Branch unit
- Load/store unit

These tests are intended for simulation-driven debugging of the implemented blocks. Full pipeline verification, assertions, coverage, constrained-random testing, and gate-level simulation are future work.

## Roadmap

- Complete and harden the single-cycle reference path.
- Add instruction/data memory models and assembly-level smoke tests.
- Build 5-stage pipeline registers for IF, ID, EX, MEM, and WB.
- Implement forwarding and hazard detection.
- Add load-use stall and branch/jump flush handling.
- Expand SystemVerilog verification with assertions and coverage.
- Add regression scripting for module and core-level tests.
- Prepare synthesis scripts, SDC constraints, STA checks, and future physical-design flow.

## Repository Structure

```text
.
|-- docs/              Project specification and design notes
|-- rtl/               Core RV32I RTL building blocks
|-- rtl_single_cycle/  In-progress single-cycle reference core
|-- tb/                Directed SystemVerilog testbenches
|-- asm/               Assembly test area
|-- scripts/           Automation scripts area
|-- sdc/               Timing constraint area
|-- uvm/               Future UVM verification area
```

Several implementation-flow directories are reserved for future synthesis, STA, gate-level simulation, OpenLane, and GDS artifacts. Generated outputs are intentionally excluded from version control.

## Tools Used

- SystemVerilog
- Icarus Verilog / `vvp`
- GTKWave
- Git / GitHub

## Learning / Engineering Focus

AtlasRV is being developed as a hands-on processor and ASIC learning project. The main engineering focus areas are RTL design discipline, RV32I instruction decoding, datapath/control partitioning, simulation-driven debugging, microarchitecture planning, and building toward a realistic ASIC implementation flow without overstating the current state of completion.
