# RISC-V Single-Cycle Core (RV32I)

A structurally complete, synthesizable **Single-Cycle RISC-V Processor** implemented in Verilog HDL. This core processes an instruction per clock cycle ($CPI = 1$) by executing all pipeline phases within one global clock period.

---

## 🗺️ System Architecture & Datapath

The processor features a classic Harvard architecture layout with separate instruction and data memory paths.

```
+---------+     +--------------------+     +---------------+     +-----+     +-------------+
|   PC    | --> | Instruction Memory | --> | Register File | --> | ALU | --> | Data Memory |
+---------+     +--------------------+     +---------------+     +-----+     +-------------+
     ^                                             |                |               |
     |                                             v                v               v
     +----------------------------------------- [ Mux / Control Logic Block ] ------+

```

### Core Execution Flow

1. **Instruction Fetch (IF):** The `program_counter` module holds the current address. `Instruction_Memory` fetches the 32-bit instruction using word-aligned mapping (`read_address >> 2`).
2. **Instruction Decode (ID):** The `main_control_unit` reads the opcode to generate routing signals, while the `immediate_generator` extracts signal constants.
3. **Execution (EX):** The `ALU` processes operations using inputs from the `Register_File` or sign-extended immediates based on the `ALUSrc` multiplexer flag.
4. **Memory (MEM):** The `Data_Memory` block performs asynchronous reads or synchronous writes based on `MemRead` and `MemWrite` flags.
5. **Write Back (WB):** A final multiplexer directs either the ALU result or memory output back into the destination register (`Rd`). Register `x0` is hardwired to `0` to meet RISC-V design rules.

---

## 🕹️ Control Logic & Operations

### Main Control Matrix

The `main_control_unit` decodes instruction types directly from the 7-bit opcode field:

| Opcode | Instruction Class | ALUSrc | MemToReg | RegWrite | MemRead | MemWrite | Branch | ALUOp |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `0110011` | **R-Type** (Arithmetic) | `0` | `0` | `1` | `0` | `0` | `0` | `10` |
| `0010011` | **I-Type** (Imm Logic) | `1` | `0` | `1` | `0` | `0` | `0` | `10` |
| `0000011` | **Load** (Data Read) | `1` | `1` | `1` | `1` | `0` | `0` | `00` |
| `0100011` | **Store** (Data Write) | `1` | `0` | `0` | `0` | `1` | `0` | `00` |
| `1100011` | **Branch** (Conditional) | `0` | `0` | `0` | `0` | `0` | `1` | `11` |
| `1101111` | **Jump** (Unconditional) | `0` | `0` | `1` | `0` | `0` | `0` | `10` |

### Supported Instructions

* **Computational:** `add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt` (and their respective immediate configurations like `addi`).
* **Memory & Control:** `lw`, `lh`, `lb`, `sw`, `sh`, `sb`, `beq`, `bne`, `jal`, `lui`, `auipc`.

---

## 🛠️ Verification & Design Decisions

### Simulation Methodology

Verification is driven through behavioral simulation patterns. Preloaded register values and instruction memory sets track flag changes across execution cycles. System states update reliably on the positive clock edge (`posedge clk`), while reset sequences explicitly scrub dynamic states back to zero.

### Design Trade-offs

* **Simplicity vs. Clock Speed:** Executing instructions in one cycle eliminates complex pipeline hazard logic. However, the total clock speed is bounded by the slowest path (fetching instruction through writing back to memory).
* **Race-Condition Prevention:** All sequential logic transitions utilize non-blocking assignments (`<=`) to mirror physical hardware synthesis accurately.

---

## 🚀 Future Roadmap

* Upgrade to a **5-Stage Pipelined** architecture (Fetch, Decode, Execute, Memory, Write-Back).
* Integrate data forwarding lanes and hazard detection units.
* Implement the **RV32M** extension multiplier extension kit.
