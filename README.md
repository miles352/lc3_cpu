# A WIP [LC3](https://en.wikipedia.org/wiki/Little_Computer_3) CPU in Verilog

Can be simulated using Verilator:
```
verilator --binary --timing --trace --top-module test test.tb.v control_unit.v alu.v memory.v register_file.v

./obj_dir/VTest
```
A waveform will be generated which can be opened with gtkwave.