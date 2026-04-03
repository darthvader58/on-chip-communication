# I2C Protocol Folder

## Purpose

This folder contains a simple I2C write-only master, a Nexys A7 wrapper, a Vivado-friendly testbench, and a protocol-specific XDC file.

The implementation performs one write transaction consisting of:

- `7`-bit slave address
- write bit
- register address byte
- data byte
- ACK checking after each byte

The code is written in Verilog-2001 for AMD Vivado synthesis and simulation.

## Files

- `i2c_master_write.v`
  I2C write controller. It generates start, byte transfer, ACK sampling, and stop conditions.
- `i2c_top.v`
  Nexys A7 wrapper. `sw[7:0]` is the data byte sent to a fixed register address.
- `i2c_tb.v`
  Simulation testbench. It models a simple ACK-capable slave and checks that the transmitted bitstream is correct.
- `i2c_nexys_a7.xdc`
  Constraint file for the I2C example.

## Hardware Connections

The top-level module in this folder is:

- `i2c_top`

Board-level intent:

- `clk100`
  100 MHz board clock
- `sw[7:0]`
  data byte written to the target register
- `sw[15]`
  rising-edge start pulse
- `i2c_scl`
  I2C clock line
- `i2c_sda`
  I2C data line
- `led[7:0]`
  mirrors the requested write data
- `led[8]`
  master busy
- `led[9]`
  transaction complete pulse
- `led[10]`
  ACK error indication

The XDC enables pull-ups on `i2c_scl` and `i2c_sda` because I2C uses open-drain signaling.

## Protocol Summary

I2C is a two-wire serial bus based on:

- open-drain `SCL`
- open-drain `SDA`
- start condition
- byte transfers with ACK/NACK
- stop condition

This design demonstrates a deterministic write transaction rather than a full programmable controller.

## Verilog Structure

The master uses:

- a multi-state FSM
- separate low-drive controls for `SCL` and `SDA`
- a divider counter to set the I2C bit timing
- explicit ACK sampling after every byte

The `inout` ports are coded in a synthesis-safe Verilog style:

- drive low with `1'b0`
- release the line with `1'bz`

## Testbench Notes

The testbench:

- generates a free-running system clock
- issues one start pulse
- emulates a slave that acknowledges each byte
- records the transmitted address and data stream
- checks the final 24-bit payload value

This is compatible with Vivado Simulator.

## Vivado Use

For simulation, add:

- `i2c_tb.v`
- `i2c_master_write.v`

For synthesis and implementation, add:

- `i2c_top.v`
- `i2c_master_write.v`
- `i2c_nexys_a7.xdc`
