# UART Transceiver — Verilog on Xilinx Vivado

A fully functional UART transceiver implemented in Verilog, simulated on Xilinx Vivado. Transmits and receives 8-bit data at 9600 baud from a 100 MHz system clock, with even parity and end-to-end loopback verification.

This came out of a digital lab where I built UART hardware physically using an IC-74165 PISO shift register. I wanted to go one level deeper and implement the full protocol in RTL — not just use a chip that does it for you.

---

## What's in here

```
uart-transceiver-verilog/
├── src/
│   ├── baud_gen.v        — baud rate generator, 16x oversampling
│   ├── uart_tx.v         — transmitter state machine
│   ├── uart_rx.v         — receiver with mid-bit sampling
│   └── uart_top.v        — top level, wires everything together
├── sim/
│   ├── tb_baud_gen.v     — baud gen testbench
│   ├── tb_uart_tx.v      — TX testbench
│   ├── tb_uart_rx.v      — RX testbench with loopback
│   └── tb_uart_top.v     — end-to-end testbench, 5 test vectors
├── sim_results/
│   └── *.png             — waveform screenshots from Vivado
└── README.md
```

---

## Protocol parameters

| Parameter | Value |
|-----------|-------|
| Baud rate | 9600 bps |
| Data bits | 8 |
| Parity | Even |
| Stop bits | 1 |
| System clock | 100 MHz |
| Oversampling | 16x |

Frame structure on the wire:

```
IDLE  START  D0  D1  D2  D3  D4  D5  D6  D7  PARITY  STOP  IDLE
  1     0    .   .   .   .   .   .   .   .     .       1     1
            LSB                             MSB
```

---

## Architecture

### baud_gen.v

The baud generator runs at 16x the target baud rate rather than exactly at 9600 Hz. This gives the receiver 16 sample points per bit instead of one, and it samples at the 8th — dead centre of the bit period where noise is lowest.

```
CLKS_PER_TICK = 100_000_000 / (9600 x 16) = 651
```

651 clock cycles per oversample tick. 16 ticks = one bit period = 104,160 ns. The ideal is 104,167 ns, so the error is 0.007% — well within UART's ±2% tolerance.

The output `baud_tick` is a single clock-wide pulse, not a toggle. Both TX and RX receive the same tick from one shared instance.

### uart_tx.v

Five-state FSM: `IDLE → START → DATA → PARITY → STOP`

Each state holds for 16 baud_ticks. A 4-bit `tick_count` handles this (0→15), and a 3-bit `bit_index` steps through the 8 data bits. Data is captured into a shift register the moment `tx_start` fires — the input `data_in` can change after that without affecting the current frame.

Bits go out LSB first. Even parity is computed as `^data_in` at the time of capture.

### uart_rx.v

Same five states on the receive side, but the timing logic is different from TX.

On detecting the falling edge of `rx` in IDLE, the receiver enters START and waits 8 ticks — half a bit period — to land at the centre of the start bit. It then checks whether `rx` is still 0 (confirms it was a real start bit, not a glitch). From that point forward it samples every 16 ticks, which keeps hitting the centre of each subsequent bit automatically.

`rx_valid` pulses high for exactly one clock cycle when a complete frame has been received and the stop bit is confirmed as 1. `parity_err` is set if `^data_out` doesn't match the received parity bit.

### uart_top.v

Purely structural — no logic, just instantiation and wiring. One `baud_gen`, one `uart_tx`, one `uart_rx`. The TX output is wired directly to RX input for loopback testing.

---

## Simulation results

Tested with 5 vectors:

| # | Sent | Received | Parity |
|---|------|----------|--------|
| 0 | 0x41 (`A`) | 0x41 | OK |
| 1 | 0x55 (`01010101`) | 0x55 | OK |
| 2 | 0xFF (`11111111`) | 0xFF | OK |
| 3 | 0x00 (`00000000`) | 0x00 | OK |
| 4 | 0xA5 (`10100101`) | 0xA5 | OK |

`0x55` and `0xA5` are useful test vectors because they alternate bits — they stress the timing more than all-zeros or all-ones.

Tcl console output:
```
PASS [0] — sent 0x41  received 0x41  parity OK
PASS [1] — sent 0x55  received 0x55  parity OK
PASS [2] — sent 0xff  received 0xff  parity OK
PASS [3] — sent 0x0   received 0x0   parity OK
PASS [4] — sent 0xa5  received 0xa5  parity OK
─────────────────────────────
RESULTS: 5 PASS  0 FAIL
```

---

## How to simulate in Vivado

1. Create a new RTL project (any Artix-7 part works — this is simulation only)
2. Add all files from `src/` as Design Sources
3. Add the relevant testbench from `sim/` as a Simulation Source
4. Right-click the testbench → Set as Top
5. Run Simulation → Run Behavioral Simulation
6. In the Tcl console: `run 20ms`

---

## Background

Built this after a digital electronics lab at IIT Kharagpur where we implemented UART hardware on a breadboard using the IC-74165 PISO shift register running at 9600 baud. The hardware side made the protocol click — start bit detection, shift register clocking, framing — so moving to RTL felt like a natural next step. Writing the RX mid-bit sampling logic especially made more sense once I'd seen the signal on an oscilloscope.

---

**Sashinth M K**  
2nd year B.Tech, Electrical Engineering  
IIT Kharagpur
