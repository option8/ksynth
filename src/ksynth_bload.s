***************************
* KSYNTH - as a bloadable *
***************************

* Originally this was built with two known entry points and could be summed up as :
* Two Tone Generator entry point @ $300:
* 300: A5 FD 85 FE A9 FF 85 FC A4 FA A6 FB CA EA EA D0 05 8D 30 C0 A6 FB C6 FE EA EA D0 07 8D 30 C0 A5 FD 85 FE 88 D0 E6 A4 FA C6 FC D0 E0 60
* Player entry point @ $330:
* 330: A9 00 AA BD 00 10 F0 31 85 FA E8 BD 00 10 85 FB 85 FD C9 FF D0 06 8D 1E 03 8D 13 03 C6 FD 8A 85 FF 20 00 03 AD 13 03 C9 FF D0 08 A9 C0 8D 1E 03 8D 13 03 E6 FF A5 FF D0 C9 60


** Two Tone Generator **
                org   $300
ks_tonegen
                LDA   $FD         ;	load second oscillator value into $FE
                STA   $FE         ;
                LDA   #$FF        ;	load duration multiplier into $FC
                STA   $FC         ;
                LDY   $FA         ;	load duration into Y
                LDX   $FB         ;	load oscillator into X
:tone_loop      DEX               ;	start countdown first oscillator, X
                NOP               ;	wait...
                NOP               ;
                BNE   :no_click   ;	if X = 0, click. otherwise, skip
:click          BIT   $C030       ;	click
                LDX   $FB         ;	reset X to beginning of countdown
:no_click       DEC   $FE         ;	countdown second oscillator, $FE
                NOP               ;	wait...
                NOP               ;
                BNE   :no_click2  ;	if $FE = 0, click. otherwise, skip
:click2         BIT   $C030       ;	click
                LDA   $FD         ;	reset $FE to beginning of countdown
                STA   $FE         ;
:no_click2      DEY               ;	countdown duration
                BNE   :tone_loop  ;	if duration hasn't expired, return and count down oscillators
                LDY   $FA         ;	if duration has expired, reset duration
                DEC   $FC         ;	decrement duration multiplier
                BNE   :tone_loop  ;	if multiplier hasn't expired, return and count down oscillators
                RTS               ;	all done


                ds    $330-*      ; pad 3-bytes for BLOAD version

** Music Player **
                org   $330
ks_player


                LDA   #$00        ;	start at zero
:note_loop      TAX               ;	X = 0; LOOP
ks_song_space   =     *
ks_song_space2  =     *
:song_space     LDA   $1000,X     ;	load note duration
                BEQ   :song_done  ;	if note is 0 duration, end the song
                STA   $FA         ;	store duration at $FA
                INX               ;	increment to note value
:song_space     LDA   $1000,X     ;	load note value
                STA   $FB         ;	store note value at $FB
                STA   $FD         ; 	store note value at $FD
                CMP   #$FF        ;	if note value is FF, rest        <- MUTE
                BNE   :not_rest   ;	skip over if !=FF
                STA   :click+2    ;	change the $C030 click to $$FF30
                STA   :click2+2   ;	change the $C030 click to $$FF30
:not_rest       DEC   $FD         ;	decrement $FD for That Karateka Sound™
                TXA               ;	put current note address in Accumulator
                STA   $FF         ;	store that in $FF
                JSR   ks_tonegen  ;	play the actual note
                LDA   :click+2    ;	did we mess with the C030 click?
                CMP   #$FF        ;	if it's FF, we did. change it back.
                BNE   :next_note  ;	skip if !=FF
                LDA   #$C0        ;	set click points back to $c030   <- UNMUTE
                STA   :click+2    ;	change the $FF30 click to $C030
                STA   :click2+2   ;	change the $FF30 click to $C030
:next_note      INC   $FF         ;	increment to next note address
                LDA   $FF         ;	load Accumulator with next note address
                BNE   :note_loop  ;	branch to LOOP
:song_done      RTS               ;

                sav   KSYNTHB


