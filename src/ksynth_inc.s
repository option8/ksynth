*************************
* KSYNTH - as a library *
*************************
*
* ks_setsong        ; a=addrlow, y=addrhi
* ks_player         ; main player
* ks_plater_latched ; alt player with callback
* ks_tonegen        ; only called internally
*


** Random Junk ;) **
ks_song_space      DA    $1000
ks_latch_callback  DA    ks_latch_stub
ks_latch_stub      RTS



** Song Location Setter **
ks_setsong
                   STA   ks_song_space
                   STY   ks_song_space+1
                   STA   ks_get_songvalue+1   ; also patch this in case people want to
                   STY   ks_get_songvalue+2   ; get song values before playing song (like for display)
                   STA   ks_set_songvalue+1   ; also patch this in case people want to
                   STY   ks_set_songvalue+2   ; get song values before playing song (like for display)
                   RTS

** Song Location Getter **
ks_get_songaddr
                   lda   ks_song_space
                   ldy   ks_song_space+1
                   RTS


** Song Length Getter **
ks_get_songlen     jsr   ks_get_songaddr
                   sta   $0                   ; uses ZP $0
                   sty   $1

                   ldy   #0
:loop              lda   ($0),y
                   beq   :found_0
                   iny
                   bne   :loop
:found_0           iny                        ; +1 for second zero as part of note standard
                   tya
                   rts

ks_get_songvalue   lda   $1000,x
                   rts

ks_set_songvalue   sta   $1000,x
                  rts


** Latch Callback Setter **
* NOTE: Be careful to preserve or restore A in your callback.  It is song index.
ks_set_latch       STA   ks_latch_callback
                   STY   ks_latch_callback+1
                   RTS

** Two Tone Generator **
ks_tonegen
                   LDA   $FD                  ;	load second oscillator value into $FE
                   STA   $FE                  ;
                   LDA   #$FF                 ;	load duration multiplier into $FC
                   STA   $FC                  ;
                   LDY   $FA                  ;	load duration into Y
                   LDX   $FB                  ;	load oscillator into X
:tone_loop         DEX                        ;	start countdown first oscillator, X
                   NOP                        ;	wait...
                   NOP                        ;
                   BNE   :no_click            ;	if X = 0, click. otherwise, skip
:click             BIT   $C030                ;	click
                   LDX   $FB                  ;	reset X to beginning of countdown
:no_click          DEC   $FE                  ;	countdown second oscillator, $FE
                   NOP                        ;	wait...
                   NOP                        ;
                   BNE   :no_click2           ;	if $FE = 0, click. otherwise, skip
:click2            BIT   $C030                ;	click
                   LDA   $FD                  ;	reset $FE to beginning of countdown
                   STA   $FE                  ;
:no_click2         DEY                        ;	countdown duration
                   BNE   :tone_loop           ;	if duration hasn't expired, return and count down oscillators
                   LDY   $FA                  ;	if duration has expired, reset duration
                   DEC   $FC                  ;	decrement duration multiplier
                   BNE   :tone_loop           ;	if multiplier hasn't expired, return and count down oscillators
                   RTS                        ;	all done

** Music Player **
ks_player
:patch_player      LDA   ks_song_space
                   STA   :song_space+1
                   STA   :song_space2+1
                   LDY   ks_song_space+1
                   STY   :song_space+2
                   STY   :song_space2+2
                   LDA   #$00                 ;	start at zero
:note_loop         TAX                        ;	X = 0; LOOP
:song_space        LDA   $1000,X              ;	load note duration
                   BEQ   :song_done           ;	if note is 0 duration, end the song
                   STA   $FA                  ;	store duration at $FA
                   INX                        ;	increment to note value
:song_space2       LDA   $1000,X              ;	load note value
                   STA   $FB                  ;	store note value at $FB
                   STA   $FD                  ; 	store note value at $FD
                   CMP   #$FF                 ;	if note value is FF, rest        <- MUTE
                   BNE   :not_rest            ;	skip over if !=FF
                   STA   :click+2             ;	change the $C030 click to $FF30
                   STA   :click2+2            ;	change the $C030 click to $FF30
:not_rest          DEC   $FD                  ;	decrement $FD for That Karateka Sound™
                   TXA                        ;	put current note address in Accumulator
                   STA   $FF                  ;	store that in $FF
                   JSR   ks_tonegen           ;	play the actual note
                   LDA   :click+2             ;	did we mess with the C030 click?
                   CMP   #$FF                 ;	if it's FF, we did. change it back.
                   BNE   :next_note           ;	skip if !=FF
                   LDA   #$C0                 ;	set click points back to $c030   <- UNMUTE
                   STA   :click+2             ;	change the $FF30 click to $C030
                   STA   :click2+2            ;	change the $FF30 click to $C030
:next_note         INC   $FF                  ;	increment to next note address
                   LDA   $FF                  ;	load Accumulator with next note address
                   BNE   :note_loop           ;	branch to LOOP
:song_done         RTS                        ;



ks_player_latched
:patch_player      LDA   ks_song_space
                   STA   :song_space+1
                   STA   :song_space2+1
                   STA   ks_get_songvalue+1
                   LDY   ks_song_space+1
                   STY   :song_space+2
                   STY   :song_space2+2
                   STY   ks_get_songvalue+2
                   LDA   ks_latch_callback
                   STA   :latch_callback+1
                   LDY   ks_latch_callback+1
                   STY   :latch_callback+2

                   LDA   #$00                 ;	start at zero
:latch_callback                               ; secondary def for self-modifying loc
:note_loop         JSR   ks_latch_callback    ; call user callback before each note
                   bcs   :song_done           ; - if carry set, latch is requesting playback stop
                   TAX                        ;	X = 0; LOOP
:song_space        LDA   $1000,X              ;	load note duration
                   BEQ   :song_done           ;	if note is 0 duration, end the song
                   STA   $FA                  ;	store duration at $FA
                   INX                        ;	increment to note value
:song_space2       LDA   $1000,X              ;	load note value
                   STA   $FB                  ;	store note value at $FB
                   STA   $FD                  ; 	store note value at $FD
                   CMP   #$FF                 ;	if note value is FF, rest        <- MUTE
                   BNE   :not_rest            ;	skip over if !=FF
                   STA   :click+2             ;	change the $C030 click to $FF30
                   STA   :click2+2            ;	change the $C030 click to $FF30
:not_rest          DEC   $FD                  ;	decrement $FD for That Karateka Sound™
                   TXA                        ;	put current note address in Accumulator
                   STA   $FF                  ;	store that in $FF
                   JSR   ks_tonegen           ;	play the actual note
                   LDA   :click+2             ;	did we mess with the C030 click?
                   CMP   #$FF                 ;	if it's FF, we did. change it back.
                   BNE   :next_note           ;	skip if !=FF
                   LDA   #$C0                 ;	set click points back to $c030   <- UNMUTE
                   STA   :click+2             ;	change the $FF30 click to $C030
                   STA   :click2+2            ;	change the $FF30 click to $C030
:next_note         INC   $FF                  ;	increment to next note address
                   LDA   $FF                  ;	load Accumulator with next note address
                   BNE   :note_loop           ;	branch to LOOP
:song_done         RTS                        ;
