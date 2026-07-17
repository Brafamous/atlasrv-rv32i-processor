# AtlasRV Bug Log

## BUG-001: V1 single-cycle core hangs on same-register source/destination instructions

**Status:** Fixed
**Found:** AtlasRV V2 Phase 7, initial constrained-random differential regression (V1 vs V2)
**Severity:** Critical — affected an extremely common instruction pattern (`rd == rs1`, e.g. `x = x + 1`)

### Symptom

Simulation of `rv32i_single_cycle_core` hangs indefinitely (never advances past a clock edge) when executing any instruction where the destination register equals a source register, e.g.:

```asm
addi x3, x3, -14
```

No error, no `$fatal`, no `$error` — the simulator simply never reaches the next scheduled event. Observed via `vvp` timing out.

### Minimal reproducer

Single instruction, executed from reset, with no other instructions in memory:

```asm
addi x3, x3, -14   ; 0xff218193
```

Confirmed via isolated testbench (`rv32i_single_cycle_core` + `instruction_memory_model` + `data_memory_model` only, no pipeline core present) that this reproduces standalone. Confirmed via a second isolated test that the same immediate with `rd != rs1` (`addi x4,x3,-14`) does **not** hang — isolating the cause to the register self-reference, not the immediate value.

### Root cause

`rtl/regfile.sv` is shared between the Version 1 single-cycle core and the Version 2 pipeline core's `id_stage`. In AtlasRV V2 Phase 4, a same-cycle WB→ID bypass was added to `regfile.sv` to fix a genuine pipeline correctness bug (a producer exactly 3 instructions ahead of a consumer, where the producer's WB coincides with the consumer's ID, read a stale value with no bypass).

That bypass is correct and necessary for the pipeline, where the read (ID stage) and write (WB stage) in a coinciding cycle belong to two **different** instructions, separated by three pipeline registers — no combinational path connects them.

The single-cycle core's read and write in any given cycle belong to the **same** instruction. When that instruction has `rd == rs1` (or `rd == rs2`), the bypass creates a real combinational feedback loop:rs1_data_o -> ALU operand -> ALU result -> writeback_data -> rd_data_i -> (bypass mux) -> rs1_data_o

This is not a simulation artifact — the same loop would exist in synthesized hardware. Icarus's event-driven simulator manifests it as the process never settling within the current time step, which appears as a hang.

### Why directed tests missed it

Every directed test written for V1 (Phases 1–8 of its own bring-up) and for V2 (Phases 1–7) used distinct destination and source registers by construction — none of the hand-written directed programs happened to write an instruction with `rd == rs1`. The bug was invisible to every test written before random generation, since nothing deliberately avoided the pattern; it simply never came up. Random instruction generation, drawing `rd`/`rs1`/`rs2` independently from a small register pool, produced this collision on its first attempt.

### Fix

Created `rtl_single_cycle/regfile_v1.sv`: a dedicated register file for the single-cycle core, restoring the original, correct, bypass-free behavior V1 always required (synchronous write, purely combinational read directly from the stored array, no same-cycle bypass). `rv32i_single_cycle_core.sv` now instantiates `regfile_v1` instead of the shared `regfile`.

`rtl/regfile.sv` (with the WB→ID bypass) is unchanged and continues to be used exclusively by Version 2's `id_stage`.

This is not logic duplication that risks future drift — `regfile_v1` and `regfile` implement two genuinely different requirements (same-instruction read/write vs. different-instruction read/write across pipeline stages), not two implementations of the same requirement. They are expected to diverge and should not be merged.

### Verification after fix

- Minimal reproducer (single self-referencing `addi`) completes without hanging.
- Full V1 bring-up regression (`tb/rv32i_single_cycle_core_tb.sv`, unmodified): 25/25 PASS, unchanged from before the fix.
- Full Phase 7 dual-core random regression: 10/10 runs, 0 register mismatches, including runs whose randomly generated programs contain `rd == rs1` instructions.

### Follow-up (tracked separately)

- The self-referencing-register case should be added as a permanent directed test in both V1's and V2's regression suites, not left to random generation alone to catch a regression.
- Random regression to date (10 fixed-length ALU-only runs) is an initial smoke test, not broad coverage. See stabilization backlog for planned expansion (seeded/replayable runs, branches/loads/stores in the random generator, memory-state comparison, larger run counts).
