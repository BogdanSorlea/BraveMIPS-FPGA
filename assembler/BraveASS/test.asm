NOP
ADDI r0 r5 13   # some comment
NOP
NOP
ADD r5 r5 r6
NOP
NOP
ADDI r0 r5 3
NOP
NOP
SUB r6 r5 r6
NOP
NOP
SW r0 r5 2
NOP
NOP
LW r0 r7 2
NOP
NOP
ADDI r0 r4 6
NOP
NOP
AND r4 r5 r5
NOP
NOP
ANDI r4 r4 15
NOP
NOP
OR r7 r3 r3
NOP
NOP
ORI r5 r5 8
NOP
NOP
XOR r5 r7 r7
NOP
NOP
ADDI r0 r1 0b1111111111110000
NOP
NOP
NOR r7 r1 r1
NOP
NOP
SLT r7 r1 r1
NOP
NOP
SLTI r7 r3 0
NOP
NOP
SLL r1 r1 0b00010
NOP
NOP
SRL r7 r7 0b00010
NOP
NOP
BEQ r0 r3 SOMELABEL
NOP
NOP
NOP
NOP
NOP
SOMELABEL: ADDI r0 r2 3
NOP
NOP
BNEQ r7 r2 JUMPONELABEL
ADDI r7 r7 2
 JUMPONELABEL  : ADDI r7 r7 14
NOP