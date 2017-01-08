***********************************
* KSYNTH - as BASIC CALL routines *
**************************s*********


** BASIC EXAMPLE 1
*
* 10 CALL 768,1,2048    : REM SETSONG 2048 = $800
* 20 CALL 768,2         : REM PLAYSONG
* 30 CALL 768,3         : REM PLAYNOTE
* 40 PRINT PEEK(944)    : REM 1=SONG NOT DONE  0=SONG DONE (RESTART BY CALLING SETSONG AGAIN) 944=$3B0
*


                          org   $300                      ; Change this to where you want to load it in BASIC.  Hex $300 = Dec 768


entry                     jsr   COMBYTE                   ; get first CALL param in X
:check1                   cpx   #1                        ; SETSONG
                          beq   ks_set_song
:check2                   cpx   #2                        ; PLAYSONG
                          beq   ks_play_song              ; will RTS to BASIC
:check3                   bne   ks_play_note              ; will RTS to BASIC


* ks_set_song        ; a=addrlow, y=addrhi
* ks_play_song      ; main player
* ks_play_note      ; alt player for use with animation
* ks_tonegen        ; only called internally
*

** Music Player **
ks_play_note              lda   _ks_player_note_position
                          asl
                          clv   ; clear V flag
                          bvc   :note_loop
ks_play_song              lda #0  ; start at 0
                          bit _bit_overflower ; set V flag
:note_loop                TAX                             ;	X = 0; LOOP
]song_space               LDA   $1000,X                   ;	load note duration
                          BEQ   :song_done                ;	if note is 0 duration, end the song
                          STA   $FA                       ;	store duration at $FA
                          INX                             ;	increment to note value
]song_space2              LDA   $1000,X                   ;	load note value
                          STA   $FB                       ;	store note value at $FB
                          STA   $FD                       ; 	store note value at $FD
                          CMP   #$FF                      ;	if note value is FF, rest        <- MUTE
                          BNE   :not_rest                 ;	skip over if !=FF
                          STA   :click+2                  ;	change the $C030 click to $FF30
                          STA   :click2+2                 ;	change the $C030 click to $FF30
:not_rest                 DEC   $FD                       ;	decrement $FD for That Karateka Sound™
                          TXA                             ;	put current note address in Accumulator
                          STA   $FF                       ;	store that in $FF
                          PHP ; save because tonegen uses bit and destroys V
                          JSR   ks_tonegen                ;	play the actual note
                          PLP ; and restore.  could be better
                          LDA   :click+2                  ;	did we mess with the C030 click?
                          CMP   #$FF                      ;	if it's FF, we did. change it back.
                          BNE   :next_note                ;	skip if !=FF
                          LDA   #$C0                      ;	set click points back to $c030   <- UNMUTE
                          STA   :click+2                  ;	change the $FF30 click to $C030
                          STA   :click2+2                 ;	change the $FF30 click to $C030
:next_note                INC   $FF                       ;	increment to next note address
                          bvc   :onenote                  ; if onenote mode (v is clear) then do one note logic
                          LDA   $FF                       ;	load Accumulator with next note address
                          bvs   :note_loop                ;	BRAnch to LOOP
:song_done                bvc   :onenote_done             ; remember 0 is in A so we just write to peek location and exit
                          RTS                             ;
:onenote                  INC   _ks_player_note_position  ; uses this alt counter
                          LDA   #1
:onenote_done             sta   song_not_done
                          rts
song_not_done             =     $3B0


** Song Location Setter **
ks_set_song               JSR   CHKCOM
                          JSR   FRMNUM
                          JSR   GETADR
                          LDA   LINNUM
                          STA   ]song_space+1               ; self-modifying patches
                          STA   ]song_space2+1
                          LDA   LINNUM+1
                          STA   ]song_space+2
                          STA   ]song_space2+2

                          LDA   #$00                      ; SETSONG resets the single note player back to start of song
                          STA   _ks_player_note_position

                          RTS



** Two Tone Generator **
ks_tonegen
                          LDA   $FD                       ;	load second oscillator value into $FE
                          STA   $FE                       ;
                          LDA   #$FF                      ;	load duration multiplier into $FC
                          STA   $FC                       ;
                          LDY   $FA                       ;	load duration into Y
                          LDX   $FB                       ;	load oscillator into X
:tone_loop                DEX                             ;	start countdown first oscillator, X
                          NOP                             ;	wait...
                          NOP                             ;
                          BNE   :no_click                 ;	if X = 0, click. otherwise, skip
:click                    BIT   $C030                     ;	click
                          LDX   $FB                       ;	reset X to beginning of countdown
:no_click                 DEC   $FE                       ;	countdown second oscillator, $FE
                          NOP                             ;	wait...
                          NOP                             ;
                          BNE   :no_click2                ;	if $FE = 0, click. otherwise, skip
:click2                   BIT   $C030                     ;	click
                          LDA   $FD                       ;	reset $FE to beginning of countdown
                          STA   $FE                       ;
:no_click2                DEY                             ;	countdown duration
                          BNE   :tone_loop                ;	if duration hasn't expired, return and count down oscillators
                          LDY   $FA                       ;	if duration has expired, reset duration
                          DEC   $FC                       ;	decrement duration multiplier
                          BNE   :tone_loop                ;	if multiplier hasn't expired, return and count down oscillators
                          RTS                             ;	all done



_ks_player_note_position  DB    0                         ; keeps track upon re-entry
_bit_overflower db $40  ; bit 6 (v) is 1
                          put   APPLEROM
                          sav   KSYNTHBAS
