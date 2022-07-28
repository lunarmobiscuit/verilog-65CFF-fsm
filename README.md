# verilog-65C2FF-fsm
A verilog model of the mythical 65CFF CPU, a 65C02 with fewer capabilties.  Here the FF is the two's compliment of 1, thus making this a play on the 65-1 (65 minus 1).

## Design goals
The main design was inspired by the 6507, the CPU in the Atari 2600 that had only 13-bits of address bus (8K), and no interrupts.  What else can you take away from a 6502 and still have a useful chip?

The Verilog lets you mix and match the features you keep and throw away.

**-D AB13** shrinks the address bus and PC to 13 bits, matching the 6507, addressing 8K ($0000-$1FFF).
**-D AB14** shrinks the address bus and PC to 14 bits, addressing 16K ($0000-$3FFF).
The default address bus is unchanged at 16 bits.

**-D STACK** includes the stack instructions and the S register.
Without the stack, PHx, PLx, and TSX are NOP, JSR is just JMP, and RTS is an invalid instruction.

**-D IRQ** includes interrupts.
Arlet's underlying design doesn't have interrupts, but without this CLI and STI are NOP, there is no logic to set the I flag, and RTI is an invalid instruction.

**-D DECIMAL** includes BCD mode.
Arlet's underlying design doesn't include BCD in the ALU, but without this without this CLD and STD are NOP, and there is no logic to set the D flag.


## Changes from the original

Nothing has been added to Arlet's 65C02 design.  The main.v and ram.v testbed files are in this repository.  With that **-D SIM** runs a local simulation.  Beyond that, there are a lot of **`ifdef**'s added to turn off the various features mentioned above.


## The hypothetical use case

The Atari 2600 used the 6507 because dropping three address pins, IRQ, and NMI allowed for a smaller package and a lower price.  But inside that package was a 16-bit address CPU with all the logic for interrupts.  The topmost metal layer was modified to tie IRQ and NMI hight, and the three "extra" address pins were not connected to any pins.  Thus the chip itself was no smaller or less expensive than a 6502.

Back in my alternative timeline, if MOS had the resources to iterate on the 6502 and a push from Apple, Atari, and/or Commodore for a lower-price ship, the potential use case for a 65FF (back in the NMOS days) would be as offboard controller for I/O.  Put a 65FF on the Disk ][ controller and an Apple ][ wouldn't have to tie up the main CPU to read/write from the floppy disk.  Most everyone else included a complete second 6502, which carries along a lot of extra opcodes and logic than is needed for that simple task.

As chip layout was 100% manual back in the late 1970s, this idea of an even simpler design only makes sense at huge quantities.  If only Atari knew they'd be selling tens of millions of devices, they might have paid $1 million to save $10 million.


## Building with and without the testbed

main.v, ram.v, ram.hex, and vec.hex are the testbed, using the SIM macro to enable simulations.
E.g. iverilog -D SIM -o test *.v; vvp test

ram.hex is 64K, loaded from $0000-$ffff.
vec.hex are the NMI, RST, and IRQ vectors, always loaded at the last 8 bytes of RAM, no matter whether you generate the 13-bit, 14-bit, or 16-bit address bus.  If you include an address outside the bounds of the address bus, the topmost bits are ignored.  E.g. JMP $8000 on either the smaller address buses will jump to $0000.

Use **-D ONEXIT** to dump the contents of RAM 16-bytes prior to the RST vector and 16-bites starting
at the RST vector before and after running the simulation.  16-bytes so that you can use those
bytes as storage in your test to check the results.

The opcode HLT (#$db) will end the simulation.


# Based on Arlet Ottens's verilog-65C02-fsm
## (Arlet's notes follow)
# verilog-65C02-fsm
A verilog model of the 65C02 CPU. The code is rewritten from scratch.

* Assumes synchronous memory
* Uses finite state machine rather than microcode for control
* Designed for simplicity, size and speed
* Reduced cycle count eliminates all unnecessary cycles

## Design goals
The main design goal is to provide an easy understand implementation that has good performance

## Code
Code is far from complete.  Right now it's in a 'proof of concept' stage where the address
generation and ALU are done in a quick and dirty fashion to test some new ideas. Once I'm happy
with the overall design, I can do some optimizations. 

* cpu.v module is the top level. 

Code has been tested with Verilator. 

## Status

* All CMOS/NMOS 6502 instructions added (except for NOPs as undefined, Rockwell/WDC extensions)
* Model passes Klaus Dormann's test suite for 6502 (with BCD *disabled*)
* BCD not yet supported
* SYNC, RST supported
* IRQ, RDY, NMI not yet supported

### Cycle counts
For purpose of minimizing design and performance improvement, I did not keep the original cycle
count. All of the so-called dead cycles have been removed.

| Instruction type | Cycles |
| :--------------: | :----: |
| Implied PHx/PLx  |   2    |
| RTS              |   4    |
| RTI              |   5    |
| BRK              |   7    |
| Other implied    |   1    |
| JMP Absolute     |   3    |
| JMP (Indirect)   |   5    |
| JSR Absolute     |   5    |
| branch           |   2    |
| Immediate        |   2    |
| Zero page        |   3    |
| Zero page, X     |   3    |
| Zero page, Y     |   3    |
| Absolute         |   4    |
| Absolute, X      |   4    |
| Absolute, Y      |   4    |
| (Zero page)      |   5    |
| (Zero page), Y   |   5    |
| (Zero page, X)   |   5    |

Add 1 cycle for any read-modify-write. There is no extra cycle for taken branches, page overflows, or for X/Y offset calculations.

Have fun. 
