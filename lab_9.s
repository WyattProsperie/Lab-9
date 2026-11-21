        .code16
        .text
        .global _start

_start:
# Program the 8255
        mov  $0x80,%al        # 1000 0000b = control word
                              # bit7=1   : this is a MODE-SET word
                              # bit6-5=00: Group A (Port A + PC7-4) Mode 0
                              # bit4=0   : Port A = OUTPUT
                              # bit3=0   : PC7-PC4 = OUTPUT
                              # bit2=0   : Group B (Port B + PC3-0) Mode 0
                              # bit1=0   : Port B = OUTPUT
                              # bit0=0   : PC3-PC0 = OUTPUT
        mov  $0x643,%dx       # DX = control register address (0x640+3)
        out  %al,%dx          # send control word to the 8255

# Starting values
        mov  $2,%si           # SI = digit where the "S" is shown (2..7)
                              # H is at SI-1, E is at SI-2
        mov  $1,%bp           # BP = +1 : move toward dig-7 (to the left)

next_frame:
        mov  $100,%di         # DI = show this picture 100 times (speed)

# Refresh: draw S, H, E one after another
refresh:
        mov  $0x6D,%bl        # S = segments a,c,d,f,g = 0110 1101b
        mov  %si,%cx          # CL = digit number for S
        call draw

        mov  $0x76,%bl        # H = segments b,c,e,f,g = 0111 0110b
        mov  %si,%cx
        dec  %cx              # H is one digit to the right of S
        call draw

        mov  $0x79,%bl        # E = segments a,d,e,f,g = 0111 1001b
        mov  %si,%cx
        sub  $2,%cx           # E is two digits to the right of S
        call draw

        dec  %di              # one refresh done
        jnz  refresh          # repeat until DI = 0

# Move SHE one digit, bounce at the ends
        add  %bp,%si          # SI = SI + (+1 or -1)
        cmp  $7,%si           # S reached dig-7 (left end)?
        je   turn
        cmp  $2,%si           # E reached dig-0 (right end)?
        je   turn
        jmp  next_frame
turn:
        neg  %bp              # +1 becomes -1, -1 becomes +1
        jmp  next_frame


# draw : show ONE letter on ONE digit for a short time
# BL = segment pattern, CL = digit number
draw:
        mov  $0x641,%dx       # DX = Port B
        mov  %bl,%al          # AL = segment pattern
        out  %al,%dx          # Port B -> segments a..g (1 = lit)

        mov  $1,%al           # AL = 0000 0001b
        shl  %cl,%al          # move the 1 left CL times -> bit CL = 1
        not  %al              # invert: chosen digit = 0, all others = 1
        mov  $0x640,%dx       # DX = Port A
        out  %al,%dx          # Port A -> 0 turns that digit ON (PNP)

        mov  $0x400,%cx       # CX = delay count (letter stays lit)
delay:
        loop delay            # count CX down to 0

        mov  $0xFF,%al        # all 1s = all digits OFF
        out  %al,%dx          # DX still = Port A; blank before next letter
        ret
