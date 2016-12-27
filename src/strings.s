**** MACROS
* GOXY #x;#y
* PRINTXY #x;#y;StringAddrWord
* PRINTSTRING #addr
**** FUNCTIONS
* GoXY
* PrintStringsX
* PrintString

PRINTSTRING           MAC
                      lda   #]1
                      ldy   #>]1
                      jsr   PrintString
                      <<<

GOXY                  MAC
                      ldx   ]1
                      ldy   ]2
                      stx   $24
                      sty   $25
                      jsr   VTAB
                      <<<

PRINTXY               MAC
                      ldx   ]1
                      ldy   ]2
                      stx   $24
                      sty   $25
                      jsr   VTAB
                      lda   #]3
                      ldy   #>]3
                      jsr   PrintString
                      <<<

GoXY                  stx   $24
                      sty   $25
                      jsr   VTAB
                      rts

*	lda #MainMenuStrs
*	ldy #>MainMenuStrs
*	ldx #05	; horiz pos
PrintStringsX         stx   _printstringsx_horiz

                      sta   $0
                      sty   $1
:loop                 lda   _printstringsx_horiz
                      sta   $24
                      lda   $0                    ; slower, but allows API reuse
                      ldy   $1
                      jsr   PrintString           ; y is last val
                      iny
                      lda   ($0),y
                      beq   :done
                      tya                         ; not done so add strlen to source ptr
                      clc
                      adc   $0
                      sta   $0
                      bcc   :nocarry
                      inc   $1
:nocarry              bra   :loop


:done                 rts



_printstringsx_horiz  db    00

* PrintString (A=Low Byte,  Y=High Byte)
PrintString           sta   :loop+1
                      sty   :loop+2

                      ldy   #0
:loop                 lda   $FFFF,y               ; dummy bytes
                      beq   :done
                      jsr   COUT
                      iny
                      bra   :loop
:done                 rts






******* BELOW REALLY COMES FROM MMT MENU (mmt/src/menu.s) ******
** I'm thinking these are mostly related to string hangling for input and output
** so it is starting to make sense to put them here.

* x/y = high/low
BINtoBCD              stx   BIN
                      sty   BIN+1
                      jsr   BINBCD16
                      ldx   BCD
                      ldy   BCD+1
                      rts
BCDtoBIN
                      stx   BCD
                      sty   BCD+1
                      jsr   BCDBIN16
                      ldx   BIN
                      ldy   BIN+1
                      rts

BIN                   dw    $0000
BCD                   ds    3

BINBCD16              SED                         ; Switch to decimal mode
                      LDA   #0                    ; Ensure the result is clear
                      STA   BCD+0
                      STA   BCD+1
                      STA   BCD+2
                      LDX   #16                   ; The number of source bits

:CNVBIT               ASL   BIN+0                 ; Shift out one bit
                      ROL   BIN+1
                      LDA   BCD+0                 ; And add into result
                      ADC   BCD+0
                      STA   BCD+0
                      LDA   BCD+1                 ; propagating any carry
                      ADC   BCD+1
                      STA   BCD+1
                      LDA   BCD+2                 ; ... thru whole result
                      ADC   BCD+2
                      STA   BCD+2
                      DEX                         ; And repeat for next bit
                      BNE   :CNVBIT
                      CLD                         ; Back to binary
                      rts

* 16-bit mode!!!
BCDBIN16
                      clc
                      xce
                      rep   #$30
                      stz   BIN
                      lda   BCD
                      and   #$000F                ;get 1's
                      sta   BIN
                      lda   BCD
                      and   #$00F0                ;get 10's
                      lsr
                      lsr
                      lsr
                      lsr
                      jsr   TIMES10
                      clc
                      adc   BIN                   ;add 10's back to BIN
                      sta   BIN
                      lda   BCD
                      and   #$0f00                ;get 100's
                      xba
                      jsr   TIMES10
                      jsr   TIMES10
                      clc
                      adc   BIN
                      sta   BIN
                      lda   BCD
                      and   #$f000                ;get 1000's
                      xba
                      lsr
                      lsr
                      lsr
                      lsr
                      jsr   TIMES10
                      jsr   TIMES10
                      jsr   TIMES10
                      clc
                      adc   BIN
                      sta   BIN
                      sep   #$30
                      rts




                      mx    %00
* 16-bit mode!!!
TIMES10
                      sta   :tensadd+1
                      ldx   #9                    ;9 loops since because initial value already in M
:tensloop             clc
:tensadd              adc   #$0000                ;placeholder, gets overwritten above
                      dex
                      bne   :tensloop
                      rts


                      mx    %11
BINBCDVARDUMP
                      lda   BIN+1
                      jsr   PRBYTE
                      lda   BIN
                      jsr   PRBYTE
                      lda   #" "
                      jsr   COUT
                      lda   BCD+2
                      jsr   PRBYTE
                      lda   BCD+1
                      jsr   PRBYTE
                      lda   BCD
                      jsr   PRBYTE
                      jsr   RDKEY
                      rts
