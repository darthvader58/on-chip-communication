# On-Chip Communication Protocol Designs

## Overview

This repository contains educational Verilog implementations of common on-chip and board-level communication protocols:

- UART
- SPI
- I2C
- CAN

Each protocol folder includes:

- synthesizable Verilog source files
- a Vivado-friendly simulation testbench
- a protocol-specific Nexys A7 constraint file
- a folder README explaining the hardware interface and verification flow

The code is written in a direct Verilog-2001 style so it can be used comfortably in AMD Vivado for both simulation and synthesis.

## Why On-Chip Communication Design Matters

Modern digital systems are not built from isolated logic blocks. They are built from processing elements, memories, peripherals, sensors, controllers, and external interfaces that must exchange data correctly and predictably.

Communication logic matters because it determines:

- how data moves between modules
- how fast transfers complete
- how errors are detected
- how timing is coordinated
- how systems scale from one block to many interacting blocks

Even when a final product uses a more complex bus fabric, understanding smaller protocols is fundamental. These designs teach the practical ideas behind:

- serial framing
- finite-state-machine control
- timing generation from a board clock
- handshaking
- bus ownership
- error detection
- simulation before hardware deployment

## Why Simulation Is Important

Simulation is the first place where protocol bugs should be found.

For communication hardware, simulation is essential because it lets you verify:

- bit ordering
- state transitions
- byte and frame timing
- start and stop behavior
- ACK and handshake behavior
- CRC or frame checks
- arbitration and bus contention behavior

Protocol designs often look small in source code but fail in subtle ways if just one timing point or bit position is wrong. A clean testbench catches those issues before synthesis, implementation, and board debug.

## Why Synthesis Is Important

Simulation alone is not enough. HDL must also map cleanly into real FPGA hardware.

Synthesis matters because it confirms that:

- the code is implementable with flip-flops and logic
- tri-state and `inout` usage are written in a synthesis-safe style
- counters, FSMs, and datapaths are structurally correct
- the module interfaces match the target board constraints

The designs in this repository are written so they can be added directly to an AMD Vivado project for synthesis on the Nexys A7 platform.

