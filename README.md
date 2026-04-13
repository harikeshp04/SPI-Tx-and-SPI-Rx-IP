# SPI Tx/Rx IP Core — RTL to GDSII on SkyWater 130nm

> **VLSI Minor Degree Project** | IIIT Dharwad, AY 2025–2026  
> Students: **Harikesh P** (22BEC016) · **Sameera T N** (22BEC047)  
> Supervisor: **Dr. Jagadish D N**, Dept. of ECE

---

## Overview

A complete, signoff-ready **SPI (Serial Peripheral Interface) Master–Slave IP Core** implemented in Verilog and taken through the full ASIC design flow — from RTL to GDSII — using an open-source toolchain on the **SkyWater 130nm** PDK.

The core targets **SPI Mode 0** (CPOL=0, CPHA=0), supporting **8-bit full-duplex transfers** with a `start`/`done` handshake interface.

---

## Features

- **SPI Mode 0** only (CPOL=0, CPHA=0) — optimized for speed and simplicity
- **8-bit full-duplex** data exchange (MOSI + MISO simultaneously)
- `start` / `done` handshake — easy to integrate into any SoC
- **MSB-first** transmission with correct setup/sample edge alignment
- Compact implementation: **~243 cells**, **~2703 µm²**
- Verified at **100 MHz**; post-layout max frequency **≥ 200 MHz**
- **Zero DRC / LVS violations** after physical design signoff

---

## Design Specs

| Parameter         | Value                          |
|-------------------|--------------------------------|
| Technology        | SkyWater 130nm (`sky130_fd_sc_hd`) |
| SPI Mode          | Mode 0 (CPOL=0, CPHA=0)       |
| Data Width        | 8-bit                          |
| Target Frequency  | 100 MHz                        |
| Standard Cells    | 243                            |
| Flip-Flops        | 43                             |
| Core Area         | 2703.84 µm²                   |
| Core Utilization  | ~68%                           |
| Estimated Power   | ~0.7 mW @ 100 MHz             |

---

## Architecture

```
         ┌─────────────────┐         ┌──────────────────┐
clk ────►│                 │         │                  │
rst ────►│   SPI MASTER    │◄───────►│    SPI SLAVE     │
start ──►│   (FSM-based)   │  mosi   │  (sclk-driven)   │
data_in ►│                 │─────────►                  │
         │                 │  miso   │                  │
         │                 │◄─────────                  │
         │                 │  sclk   │                  │
         │                 │─────────►                  │
         │                 │   cs    │                  │
         │                 │─────────►                  │
         │    data_out     │         │    data_out      │
         │    done         │         │                  │
         └─────────────────┘         └──────────────────┘
```

### Master FSM States

```
IDLE ──(start)──► LOAD ──► TRANSFER ──(8 bits done)──► DONE ──► IDLE
```

| State      | Behaviour                                                      |
|------------|----------------------------------------------------------------|
| `IDLE`     | `cs=1`, `sclk=0`, waiting for `start` pulse                   |
| `LOAD`     | Assert `cs=0`, preload shift registers, output MSB on `mosi`  |
| `TRANSFER` | Toggle `sclk`; shift out `mosi` on falling, sample `miso` on rising |
| `DONE`     | Deassert `cs`, latch `data_out`, pulse `done=1`, return to `IDLE` |

---

## Signal Interface

### SPI Master

| Signal       | Direction | Width | Description                        |
|--------------|-----------|-------|------------------------------------|
| `clk`        | Input     | 1     | System clock                       |
| `rst`        | Input     | 1     | Synchronous active-high reset      |
| `start`      | Input     | 1     | Pulse to initiate transfer         |
| `data_in`    | Input     | 8     | Byte to transmit on MOSI           |
| `miso`       | Input     | 1     | Serial data from slave             |
| `sclk`       | Output    | 1     | SPI clock                          |
| `mosi`       | Output    | 1     | Serial data to slave               |
| `cs`         | Output    | 1     | Chip select (active low)           |
| `done`       | Output    | 1     | High for 1 cycle when transfer done|
| `data_out`   | Output    | 8     | Received byte from slave           |

### SPI Slave

| Signal       | Direction | Width | Description                        |
|--------------|-----------|-------|------------------------------------|
| `sclk`       | Input     | 1     | SPI clock from master              |
| `cs`         | Input     | 1     | Chip select (active low)           |
| `mosi`       | Input     | 1     | Serial data from master            |
| `data_in`    | Input     | 8     | Byte to send back on MISO          |
| `miso`       | Output    | 1     | Serial data to master              |
| `data_out`   | Output    | 8     | Received byte from master          |

---

## File Structure

```
spi_ip_core/
├── rtl/
│   ├── spi_master.v       # Master FSM (IDLE → LOAD → TRANSFER → DONE)
│   ├── spi_slave.v        # Slave shift register (posedge sclk)
│   └── spi_top.v          # Top-level loopback instantiation (optional)
├── tb/
│   ├── spi_tb.v           # Testbench with 5 test scenarios
│   └── waveform.vcd       # Generated waveform (post-simulation)
├── syn/
│   └── (Yosys synthesis scripts & reports)
├── pnr/
│   └── (OpenROAD place-and-route scripts & reports)
├── signoff/
│   ├── drc.rpt            # DRC report (0 violations)
│   └── lvs.rpt            # LVS report (0 mismatches)
└── README.md
```

---

## Toolchain

| Tool            | Purpose                          |
|-----------------|----------------------------------|
| **Icarus Verilog** | RTL simulation                |
| **GTKWave**     | Waveform viewing                 |
| **Yosys**       | Synthesis (sky130_fd_sc_hd)      |
| **OpenROAD**    | Floorplan, placement, CTS, routing, signoff |

All tools are **open-source** — no proprietary EDA licenses required.

---

## Simulation

### Compile & Run

```bash
# Compile
iverilog -o spi.out tb/spi_tb.v rtl/spi_master.v rtl/spi_slave.v rtl/spi_top.v

# Run simulation
vvp spi.out

# View waveform
gtkwave waveform.vcd
```

### Test Cases

| Test | Master TX | Slave TX | Expected Master RX | Description              |
|------|-----------|----------|--------------------|--------------------------|
| 1    | `0xA5`    | `0x3C`   | `0x3C`             | Single 8-bit transfer    |
| 2    | `0x5A→0xC3` | `0xC3→0x5A` | `0xC3, 0x5A`  | Back-to-back transfers   |
| 3    | —         | —        | —                  | Reset during idle        |
| 4    | `0xFF`    | `0x00`   | `0x00`             | Slave echo test          |
| 5    | `0x12, 0x34` | `0xAB, 0xCD` | `0xAB, 0xCD` | Random data sequence  |

All 5 test cases **pass** with zero errors.

---

## Synthesis Results

```
Yosys — sky130_fd_sc_hd — 100 MHz target

Standard Cells : 243
Flip-Flops     : 43
Total Area     : 2703.84 µm²
Worst Setup Slack (pre-route) : +6.69 ns
Worst Hold Slack  (pre-route) : +0.16 ns
TNS / WNS      : 0.00 / 0.00  (no violations)
```

---

## Physical Design Results

```
OpenROAD — Post-layout signoff

Core Utilization   : ~68%
Worst Setup Slack  : +6.77 ns
Worst Hold Slack   : +0.32 ns
Post-route Slack   : +1.2 ns
Max Frequency      : ≥ 200 MHz
Estimated Power    : ~0.7 mW @ 100 MHz
DRC Violations     : 0
LVS Mismatches     : 0
```

---

## SPI Mode 0 Timing

```
         ___     ___     ___     ___     ___     ___     ___     ___
sclk  __|   |___|   |___|   |___|   |___|   |___|   |___|   |___|   |___

cs    ‾‾|_____________________________________________________________|‾‾

mosi  --< B7 >---< B6 >---< B5 >---< B4 >---< B3 >---< B2 >---< B1 >---< B0 >--
             ↑       ↑       ↑       ↑       ↑       ↑       ↑       ↑
miso  -------< B7 >---< B6 >---< B5 >---< B4 >---< B3 >---< B2 >---< B1 >---< B0 >

done  ___________________________________________________________________|‾|___
```

- `sclk` idles **low** (CPOL=0)
- Data driven on **falling** edge, sampled on **rising** edge (CPHA=0)
- `done` pulses high for **exactly one** `clk` cycle after the 8th bit

---

## Future Work

- [ ] Multi-mode support (Modes 1–3: CPOL/CPHA combinations)
- [ ] 16-bit or configurable data width
- [ ] FIFO/DMA buffering for continuous streaming
- [ ] Multi-slave support (multiple CS lines)
- [ ] Formal verification (property checking)

---

## References

1. [Serial Peripheral Interface — Wikipedia](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface)
2. [I²C vs SPI — Total Phase Blog](https://www.totalphase.com/blog/2021/07/i2c-vs-spi-protocol-analyzers-differences-and-similarities/)
3. [Advanced Digital Systems Design Flow — P. Schaumont, WPI ECE574](https://schaumont.dyn.wpi.edu/ece574f24/06designflow.html)
4. Motorola SPI Block Guide v03.06

---

## License

This project is submitted as an academic minor degree project at **IIIT Dharwad** under the guidance of Dr. Jagadish D N. All RTL and scripts are original work by the authors.

---

*Implemented with open-source tools (Icarus Verilog · Yosys · OpenROAD) on SkyWater 130nm PDK.*
