# SPI Protocol Folder

## Purpose

This folder contains a simple SPI master, a Nexys A7 top-level wrapper, a Vivado-friendly testbench, and a protocol-specific XDC file.

The implementation models a single-byte SPI transfer using:

- one master
- one slave-select line
- `8` serial clock cycles
- simultaneous MOSI transmit and MISO receive

The code is written in plain Verilog-2001 for Vivado synthesis and XSIM simulation.

## Files

- `spi_master.v`
  SPI master controller. It generates `sclk`, drives `mosi`, samples `miso`, and asserts `done` after one byte transfer.
- `spi_top.v`
  Nexys A7 wrapper. `sw[7:0]` is the transmit byte and `sw[15]` starts the transfer.
- `spi_tb.v`
  Simulation testbench. It includes a simple slave-side shift model that returns a known byte on `miso`.
- `spi_nexys_a7.xdc`
  Constraint file for this SPI example.

## Hardware Connections

The top-level module in this folder is:

- `spi_top`

Board-level intent:

- `clk100`
  100 MHz board clock
- `sw[7:0]`
  transmit byte for MOSI
- `sw[15]`
  rising-edge transfer trigger
- `spi_miso`
  serial input from slave
- `spi_mosi`
  serial output to slave
- `spi_sclk`
  serial clock output
- `spi_cs_n`
  active-low slave select
- `led[7:0]`
  received byte sampled on MISO
- `led[8]`
  controller busy
- `led[9]`
  transfer complete pulse

## Protocol Summary

SPI is a synchronous serial protocol. In this design:

- the master owns the serial clock
- chip select goes low during a transfer
- MOSI is driven from the transmit shift register
- MISO is captured into the receive shift register

The design is intentionally compact and suitable for learning and small FPGA demos.

## Verilog Structure

The code uses:

- a single clocked always block
- explicit shift registers
- an edge counter for the serial clock
- a clock-divider counter to derive the SPI bit rate from the 100 MHz input

## FSM and ASM Summary

`spi_master.v` is implemented as a compact sequential controller rather than a separately named state machine. Functionally, it still behaves like a two-phase transfer FSM:

- `IDLE`
  Wait for `start`, load the transmit byte, drive `cs_n` low.
- `TRANSFER`
  Toggle `sclk`, shift out MOSI, sample MISO, count `8` bits.
- `DONE`
  Release `cs_n`, pulse `done`, return to idle behavior.

ASM-style flow for `spi_master.v`:

```text
IDLE -> TRANSFER -> DONE -> IDLE
          |
          +-- repeat clock edges until 8 bits complete
```

So, while the source uses counters and conditional sequencing instead of a separate `state` register, the hardware operation is still naturally described with this ASM chart.

## Testbench Notes

The testbench:

- generates the system clock
- applies reset and start pulses
- models a slave returning `8'h3C`
- checks that the SPI master receives the expected value

It is compatible with Vivado Simulator.

## Vivado Use

For simulation, add:

- `spi_tb.v`
- `spi_master.v`

For synthesis and implementation, add:

- `spi_top.v`
- `spi_master.v`
- `spi_nexys_a7.xdc`
