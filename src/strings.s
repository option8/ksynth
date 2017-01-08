**** MACROS
* GOXY #x;#y
* PRINTXY #x;#y;StringAddrWord
* PRINTSTRING #addr

**** FUNCTIONS
* GoXY
* PrintStringsX
* PrintString


** MACROS
PRINTSTRING               MAC
                          lda   #]1
                          ldy   #>]1
                          jsr   PrintString
                          <<<

GOXY                      MAC
                          ldx   ]1
                          ldy   ]2
                          stx   $24
                          sty   $25
                          jsr   VTAB
                          <<<

PRINTXY                   MAC
                          ldx   ]1
                          ldy   ]2
                          stx   $24
                          sty   $25
                          jsr   VTAB
                          lda   #]3
                          ldy   #>]3
                          jsr   PrintString
                          <<<

GoXY                      stx   $24
                          sty   $25
                          jsr   VTAB
                          rts


** FUNCTIONS

*	lda #MainMenuStrs
*	ldy #>MainMenuStrs
*	ldx #05	; horiz pos
PrintStringsX             stx   _printstringsx_horiz

                          sta   $0
                          sty   $1
:loop                     lda   _printstringsx_horiz
                          sta   $24
                          lda   $0                        ; slower, but allows API reuse
                          ldy   $1
                          jsr   PrintString               ; y is last val
                          iny
                          lda   ($0),y
                          beq   :done
                          tya                             ; not done so add strlen to source ptr
                          clc
                          adc   $0
                          sta   $0
                          bcc   :loop
                          inc   $1
:nocarry                  bcs   :loop                     ; BRA


:done                     rts



_printstringsx_horiz      db    00

* PrintString (A=Low Byte,  Y=High Byte)
PrintString               sta   :loop+1
                          sty   :loop+2

                          ldy   #0
:loop                     lda   $FFFF,y                   ; dummy bytes
                          beq   :done
                          jsr   COUT
                          iny
                          bne   :loop                     ; BRA
:done                     rts


** Natural style, right aligned, no leading zeros
** Assumes a byte passed in.  So space for 3 decimal digits, plz.
** Cursor is leftmost char, which may be blank.
** A value of zero still prints a single zero on the right.
** Params: A=low byte  Y=high byte
PRNUM                     pha                             ;start with leftmost so stash low byte
                          tya                             ; work on high byte
                          beq   :space1                   ; nothing to print
:high_byte_low_nib        jsr   PRHEX                     ; otherwise
                          bne   :low_byte_high_nib        ; BRA
:space1                   lda   #" "                      ;"
                          jsr   COUT
:low_byte_high_nib        pla
                          pha                             ; save one for later
                          lsr
                          lsr
                          lsr
                          lsr
                          beq   :space2
                          jsr   PRHEX
                          sec
                          bcs   :low_byte_low_nib         ; BRA
:space2                   lda   #" "                      ;"
                          jsr   COUT
:low_byte_low_nib         pla
                          and   #$0F                      ; just low nib
                          jsr   PRHEX
                          rts




******* BELOW REALLY COMES FROM MMT MENU (mmt/src/menu.s) ******
** I'm thinking these are mostly related to string hangling for input and output
** so it is starting to make sense to put them here.
** BUT!!!! I need to have 8-bit versions available for a generic library


* x/y = high/low
BINtoBCD                  stx   BIN
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

BIN                       dw    $0000
BCD                       ds    3

BINBCD16                  SED                             ; Switch to decimal mode
                          LDA   #0                        ; Ensure the result is clear
                          STA   BCD+0
                          STA   BCD+1
                          STA   BCD+2
                          LDX   #16                       ; The number of source bits

:CNVBIT                   ASL   BIN+0                     ; Shift out one bit
                          ROL   BIN+1
                          LDA   BCD+0                     ; And add into result
                          ADC   BCD+0
                          STA   BCD+0
                          LDA   BCD+1                     ; propagating any carry
                          ADC   BCD+1
                          STA   BCD+1
                          LDA   BCD+2                     ; ... thru whole result
                          ADC   BCD+2
                          STA   BCD+2
                          DEX                             ; And repeat for next bit
                          BNE   :CNVBIT
                          CLD                             ; Back to binary
                          rts

* 16-bit mode!!!
BCDBIN16
                          clc
                          xce
                          rep   #$30
                          stz   BIN
                          lda   BCD
                          and   #$000F                    ;get 1's
                          sta   BIN
                          lda   BCD
                          and   #$00F0                    ;get 10's
                          lsr
                          lsr
                          lsr
                          lsr
                          jsr   TIMES10
                          clc
                          adc   BIN                       ;add 10's back to BIN
                          sta   BIN
                          lda   BCD
                          and   #$0f00                    ;get 100's
                          xba
                          jsr   TIMES10
                          jsr   TIMES10
                          clc
                          adc   BIN
                          sta   BIN
                          lda   BCD
                          and   #$f000                    ;get 1000's
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
                          ldx   #9                        ;9 loops since because initial value already in M
:tensloop                 clc
:tensadd                  adc   #$0000                    ;placeholder, gets overwritten above
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



*** INPUT LIBRARY FOR MENU
* Pass desired length in A
* y/x= storage area
GetHexByteOrder
                          pha
                          lda   #$1                       ;1=6502 ordering
                          sta   _gethex_byteorder
                          pla
                          bne   GetHexStart               ; BRA

GetHex                    stz   _gethex_byteorder         ;0=linear order (01 23 45 67 etc, in memory)
GetHexStart
                          sta   _gethex_maxlen
                          stx   _gethex_resultptr
                          sty   _gethex_resultptr+1
                          stz   _gethex_current
                          lda   $24
                          sta   _gethex_screenx           ;stash x.  gets clobbered by RDKEY

:input                    jsr   RDKEY

                          cmp   #$9B                      ;esc = abort
                          bne   :notesc
                          rts
:notesc                   cmp   #$FF                      ;del
                          beq   :goBack
                          cmp   #$88
                          bne   :notBack
:goBack
                          lda   _gethex_current
                          beq   :badChar                  ; otherwise result = -1
                          dec   _gethex_current
                          dec   _gethex_screenx
                          GOXY  _gethex_screenx;$25
                          sec
                          bcs   :input                    ; BRA
:notBack                  cmp   #"9"+1
                          bcs   :notNum                   ;bge > 9
                          cmp   #"0"
                          bcc   :badChar                  ;
                          sec
                          sbc   #"0"
                          sec
                          bcs   :storeInput               ; BRA
:notNum                   cmp   #"a"
                          bcc   :notLower
                          sec
                          sbc   #$20                      ;ToUpper
:notLower                 cmp   #"A"
                          bcc   :badChar
                          cmp   #"F"+1
                          bcs   :badChar
                          bcc   :gotHex
***
:badChar                  jmp   :input                    ;jmp out of here
***
:gotHex
                          sec
                          sbc   #"A"-10
:storeInput
                          pha
                          jsr   PRHEX
                          pla
                          ldy   _gethex_current
                          sta   _gethex_buffer,y
                          inc   _gethex_screenx
                          iny
                          cpy   #_gethex_internalmax
                          bge   :internalmax
                          cpy   _gethex_maxlen
                          bge   :passedmax
                          sty   _gethex_current
                          sec
                          bcs   :input                    ; BRA
:internalmax
:passedmax
                          lda   _gethex_resultptr         ;set destination buffer to result memory
                          sta   $0
                          lda   _gethex_resultptr+1
                          sta   $1
                                                          ;prep to copy back to result
                          lda   _gethex_byteorder
                          beq   :linearcopy
:byteordercopy            ldx   #0
                          lda   _gethex_maxlen
                          lsr                             ;/2 ... took a looong time to find this bug
                          tay
                          dey                             ;we start at n-1 and work down to 0
:copyBufferBackwardsByte  lda   _gethex_buffer,x
                          asl                             ; move to upper nibble
                          asl
                          asl
                          asl
                          sta   ($0),y                    ; store
                          inx
                          lda   _gethex_buffer,x
                          ora   ($0),y
                          sta   ($0),y
                          dey
                          inx
                          cpx   _gethex_maxlen
                          bcc   :copyBufferBackwardsByte
                          rts



:linearcopy               ldx   #0
                          ldy   #0
:copyBuffer               lda   _gethex_buffer,x
                          asl                             ; move to upper nibble
                          asl
                          asl
                          asl
                          sta   ($0),y                    ; store
                          inx
                          lda   _gethex_buffer,x
                          ora   ($0),y
                          sta   ($0),y
                          iny
                          inx
                          cpx   _gethex_maxlen
                          bcc   :copyBuffer
                          rts



_gethex_internalmax       equ   8
_gethex_resultptr         da    0000
_gethex_maxlen            db    1
_gethex_current           db    0
_gethex_buffer            ds    _gethex_internalmax
_gethex_screenx           db    0
_gethex_byteorder         db    0                         ;0=linear, 1=6502 address byte order.. Least significant byte first.

