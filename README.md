# arch-lab
Includes developed HDL codes, pictures of waveforms and schematics for the implementation of an ARM processor.
Codes are developed by moein maleki and ashkan jafari, for Architecture Lab, University of Tehran, Fall of 2022. 

The Overall functionality of the system is explained in "ARM.pdf". Seperate condion_check, control_unit, val2_generator units are 
designed to implement the functionality of the processor.

As of 16-Dec-2022, each subdirectory in this repository was simulated, verified, tested and synthesized on an Intel DE2 - Cyclone II FPGA board,
except the SRAM subdirectory, which due to air pollution in Tehran, we weren't able to actually synthesize and test the developed code with the
on-board SRAM memory, and instread modeled an sram module and tested, verified the functionality of the system in that way.  

This project was made up of different coding stages:

  1- base, the first level, aims at creating a 5-stage pipelined processor with hazard detection.
      Surveying "arm_processor.v" gives a better understanding of how seperate stages are implented.
      Wires are carefully named and grouped, in order to reduce confusion. following them in "arm_processor.v" should be an easy task.
      Instruction memory and the data memory are seperated.
      Former lies at "IF_Stage.v" where each instruction is a 32-bit entry in a switch-case. (Not the best way of doing it, I know :( )
      Latter is situated in "MEM_Stage.v" and takes the form a 2-D reg variable.
      Data memory addresses are first subtracted by 1024, then aligned in an 4-byte format.
      Each data memory entry is a byte, 32 bits are stored in a little indian format.
      alu_result in this stage is the address to be accessed and val_rm is the data to be written to, in case of a store instruction 
      
  2- forwarding, the second level, has a seperate forwarding unit. the unit is instanciated in "arm_processor.v".
  
  3- sram, the third level, uses the on-board sram IC instead of the data memory being sotred on the fpga ram modules.
  
