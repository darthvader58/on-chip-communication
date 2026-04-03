# CAN Protocol Folder

## Purpose

This folder contains a more protocol-complete educational CAN controller example than the original simple serializer version. It now includes:

- standard `11`-bit CAN identifier support
- one data byte payload
- CRC-15 generation and checking
- bit stuffing in the transmitter
- bit unstuffing in the receiver
- ACK slot behavior
- basic arbitration-loss detection in the transmitter
- form checks on ACK delimiter, EOF, and intermission

The code is still intentionally small enough to study in a digital design course and is written in Verilog-2001 for Vivado synthesis and XSIM simulation.

## Files

- `can_tx.v`
  Standard CAN frame transmitter. It builds the core frame, inserts stuff bits, checks the bus during arbitration, and samples the ACK slot.
- `can_rx.v`
  Standard CAN frame receiver. It removes stuff bits, checks CRC, asserts ACK for good frames, and checks delimiter/EOF/intermission format rules.
- `can_top.v`
  Nexys A7 wrapper. `sw[7:0]` is the transmitted data byte and `sw[15]` triggers a frame request.
- `can_tb.v`
  Simulation testbench. It verifies a good frame transfer and also verifies arbitration-loss detection.
- `can_nexys_a7.xdc`
  Constraint file for a simple board-level demonstration.

## Hardware Connections

The top-level module in this folder is:

- `can_top`

Board-level intent:

- `clk100`
  100 MHz board clock
- `sw[7:0]`
  payload byte sent in the CAN data field
- `sw[15]`
  rising-edge transmit request
- `can_tx`
  logic-level transmit signal to a CAN transceiver input
- `can_rx`
  logic-level receive signal from a CAN transceiver output
- `led[7:0]`
  last valid received data byte
- `led[8]`
  receiver frame valid pulse
- `led[9]`
  transmitter busy
- `led[10]`
  transmit complete pulse
- `led[11]`
  missing ACK indication
- `led[12]`
  arbitration-lost indication
- `led[13]`
  CRC error indication
- `led[14]`
  stuff error indication
- `led[15]`
  form error indication

Important hardware note:

- This design expects an external CAN transceiver for a real bus.
- The FPGA pins in the XDC are only logic-side `TXD` and `RXD` style signals, not direct CANH/CANL differential bus pins.

## Protocol Summary

CAN is a robust multi-master bus designed for reliable message transfer in electrically noisy environments. The key concepts demonstrated here are:

- dominant `0` and recessive `1`
- arbitration by monitoring the bus while transmitting the identifier
- CRC-protected frame transfer
- mandatory bit stuffing during the frame core
- ACK from a receiver after a valid frame

This example implements a standard data frame with a fixed DLC of `1`. It is a good intermediate teaching model between a pure bit serializer and a production CAN controller.

## Verilog Structure

The transmitter uses:

- a frame-core bit generator
- CRC generation
- a stuffing counter
- arbitration monitoring against `can_rx`
- separate states for ACK, EOF, and intermission

The receiver uses:

- SOF detection
- timed bit sampling
- bit unstuffing
- CRC validation
- ACK generation
- delimiter and EOF checks

## Testbench Notes

The testbench uses a wired-AND style logical bus:

- the transmitter drives the bus
- the receiver can force a dominant ACK bit
- an extra testbench driver can force a dominant bit to simulate arbitration loss

Two checks are performed:

- successful frame transfer with valid ACK
- arbitration loss during a later transmission

This is compatible with Vivado Simulator.

## Vivado Use

For simulation, add:

- `can_tb.v`
- `can_tx.v`
- `can_rx.v`

For synthesis and implementation, add:

- `can_top.v`
- `can_tx.v`
- `can_rx.v`
- `can_nexys_a7.xdc`
