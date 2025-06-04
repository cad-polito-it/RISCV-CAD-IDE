# Changelog

## [1.0.0] - 2025-04-30

### Modified

Changes made in the most recent core-v-verify version until today:

- core-v-verify/bin/objdump2itb : line 77, 83, 89 i added the "r" at the start of the variables;
- core-v-verify/bin/yaml2make : added the path to the programs folder starting from core-v-verify e.g. ../programs in line 57;
- core-v-verify/cv32e40p/sim/core/Makefile : changed it to make it work on my pcor they can be defined from a setup file in the main directory;
- core-v-verify/cv32e40p/tb/core/tb_top_verilator.cpp : non necessary change : line 47 can be changed to top->trace(tfp, 999); tfp->dumpvars(99,"TOP");

# TODO modify the logic in core-v-verif/cv32e40p/tb/core/tb_top_verilator.cpp to allow the dump of all the register in the core e.g. pc, x1, x2...