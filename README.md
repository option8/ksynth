# KSynth
Beginnings of a dual tone synthesizer for the Apple II

All the code is in this README, since it's small enough to copy and paste into an emulator for now.

The synth code itself

##Two Tone Generator##
```
0300-   A5 FD       LDA   $FD	;	load second oscillator value into $FE
0302-   85 FE       STA   $FE	;
0304-   A9 FF       LDA   #$FF	;	load duration multiplier into $FC
0306-   85 FC       STA   $FC	;
0308-   A4 FA       LDY   $FA	;	load duration into Y
030A-   A6 FB       LDX   $FB	;	load oscillator into X
030C-   CA          DEX			;	start countdown first oscillator, X
030D-   EA          NOP			;	wait...
030E-   EA          NOP			;
030F-   D0 05       BNE   $0316	;	if X = 0, click. otherwise, skip
0311-   2C 30 C0    BIT   $C030	;	click
0314-   A6 FB       LDX   $FB	;	reset X to beginning of countdown
0316-   C6 FE       DEC   $FE	;	countdown second oscillator, $FE
0318-   EA          NOP			;	wait...
0319-   EA          NOP			;
031A-   D0 07       BNE   $0323	;	if $FE = 0, click. otherwise, skip
031C-   2C 30 C0    BIT   $C030	;	click
031F-   A5 FD       LDA   $FD	;	reset $FE to beginning of countdown
0321-   85 FE       STA   $FE	;
0323-   88          DEY			;	countdown duration
0324-   D0 E6       BNE   $030C	;	if duration hasn't expired, return and count down oscillators
0326-   A4 FA       LDY   $FA	;	if duration has expired, reset duration 
0328-   C6 FC       DEC   $FC	;	decrement duration multiplier
032A-   D0 E0       BNE   $030C	;	if multiplier hasn't expired, return and count down oscillators
032C-   60          RTS			;	all done

300: A5 FD 85 FE A9 FF 85 FC A4 FA A6 FB CA EA EA D0 05 8D 30 C0 A6 FB C6 FE EA EA D0 07 8D 30 C0 A5 FD 85 FE 88 D0 E6 A4 FA C6 FC D0 E0 60       
```


##Player##
```
0330-   A9 00       LDA   #$00		;	start at zero
0332-   AA          TAX				;	X = 0; LOOP
0333-   BD 00 10    LDA   $1000,X	;	load note duration
0336-   F0 31       BEQ   $0369		;	if note is 0 duration, end the song
0338-   85 FA       STA   $FA		;	store duration at $FA
033A-   E8          INX				;	increment to note value
033B-   BD 00 10    LDA   $1000,X	;	load note value
033E-   85 FB       STA   $FB		;	store note value at $FB
0340-   85 FD       STA   $FD		; 	store note value at $FD
0342-   C9 FF       CMP   #$FF		;	if note value is FF, rest
0344-   D0 06       BNE   $034C		;	skip over if !=FF
0346-   8D 1E 03    STA   $031E		;	change the $C030 click to $$FF30	
0349-   8D 13 03    STA   $0313		;	change the $C030 click to $$FF30	
034C-   C6 FD       DEC   $FD		;	decrement $FD for That Karateka Sound™
034E-   8A          TXA				;	put current note address in Accumulator
034F-   85 FF       STA   $FF		;	store that in $FF						
0351-   20 00 03    JSR   $0300		;	play the actual note
0354-   AD 13 03    LDA   $0313		;	did we mess with the C030 click?
0357-   C9 FF       CMP   #$FF		;	if it's FF, we did. change it back.
0359-   D0 08       BNE   $0363		;	skip if !=FF
035B-   A9 C0       LDA   #$C0		;	set click points back to $c030
035D-   8D 1E 03    STA   $031E		;
0360-   8D 13 03    STA   $0313		;	
0363-   E6 FF       INC   $FF		;	increment to next note address
0365-   A5 FF       LDA   $FF		;	load Accumulator with next note address
0367-   D0 C9       BNE   $0332		;	branch to LOOP
0369-   60          RTS				;

330: A9 00 AA BD 00 10 F0 31 85 FA E8 BD 00 10 85 FB 85 FD C9 FF D0 06 8D 1E 03 8D 13 03 C6 FD 8A 85 FF 20 00 03 AD 13 03 C9 FF D0 08 A9 C0 8D 1E 03 8D 13 03 E6 FF A5 FF D0 C9 60       
```

##Creating Music##

Music is stored in the following format, beginning (by default) at $1000.

Starting address = A ($1000)

A+0 = duration

_e.g. FF = 1.63 seconds_
	
A+1 = note
	
_e.g. 59 = 440Hz A_

	per chart at [https://www.seventhstring.com/resources/notefrequencies.html]


NOTE |  C     |   C#   |    D   |   Eb   |   E    |   F    |   F#   |    G   |   G#   |   A    |   Bb   |   B    |
|-----| ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ |
FREQ |        |        |        | 155.6  | 164.8  | 174.6  | 185.0  | 196.0  | 207.7  | 220.0  | 233.1  |   246.9
BYTE |        |        |        | FC     | EF     | E1     | D5     | C9     | BD     | B3     | A9     |   9F
FREQ |  261.6 | 277.2  |  293.7 |    311.1  |   329.6  |   349.2  |   370.0  |   392.0 |    415.3  |   440.0  |   466.2  |   493.9
BYTE |  96    | 8E     |  86    |    7E     |   77     |   71     |   6A     |   64    |    5E     |   59     |   54     |   4F
FREQ |  523.3 | 554.4  |  587.3 |    622.3  |   659.3  |   698.5  |   740.0  |   784.0 |    830.6  |   880.0  |   932.3  |   987.8
BYTE |  4B    | 47     |  43    |    3F     |   3C     |   38     |   35     |   32    |    2F     |   2D     |   2A     |   27
FREQ | 1047	| 1109	| 1175	| 1245	| 1319	| 1397	| 1480	| 1568	| 1661	| 1760	| 1865	| 1976
BYTE | 25	|	23	|	21	|	1F	|	1E	|	1C	|	1A	|	19	|	17	|	16	|	15	|	13


##Bb scale:##
```
1000: 20 A9 20 96 20 86 20 7E 20 71 20 64 20 59 20 54 20 59 20 64 20 71 20 7E 20 86 20 96 FF A9 FF FF 10 A9 10 86 10 71 10 54 10 71 10 86 FF A9 00
```

##Karateka victory:##
```
1000: 10 a8 20 FF 08 c7 05 FF 10 a8 15 FF 25 7e 20 FF 10 63 08 FF 80 63 00 00
```

and, of course, the requisite

##Daisy Bell (Bicycle Built For Two)##
```
1000: 30 71 30 86 30 A9 30 e1 10 C9 10 B3 10 A9 20 C9 10 A9 60 e1 30 96 30 71 30 86 30 A9 10 C9 10 B3 10 A9 20 96 10 86 40 96 10 FF 10 86 10 77 10 86
1030: 10 96 20 71 10 86 10 96 40 A9 10 96 20 86 10 A9 20 C9 10 A9 10 C9 40 e1 10 E1 20 A9 10 86 10 96 20 FF 20 A9 10 86 10 96 10 FF 05 86 05 77 10 71 10 86 10 A9 20 96 10 e1 40 A9 00 00
```




##MIDI Translation##

Using the above table as a starting point, a MIDI lookup table can be created. MIDI addresses up to 127 notes, from a C three octaves below Bass Clef, up to a G 9 octaves above. [http://www.midikits.net/midi_analyser/midi_note_numbers_for_octaves.htm]

440hz A is note 69 in MIDI, so byte 69 (0x45) of the KSYNTH lookup table.

By shifting 12 bytes up or down (one octave), a song's range can be easily be changed to fit in KSYNTH's limited range.

```
  C  C# D  D# E  F  F# G  G# A  A# B
0 00 00 00 00 00 00 00 00 00 00 00 00 
1 00 00 00 00 00 00 00 00 00 00 00 00 
2 00 00 00 00 00 00 00 00 00 00 00 00 
3 00 00 00 00 00 00 00 00 00 00 00 00 
4 00 00 00 FC EF E1 D5 C9 BD B3 A9 9F
5 96 8E 86 7E 77 71 6A 64 5E 59 54 4F
6 4B 47 43 3F 3C 38 35 32 2F 2D 2A 27
7 25 23 21 1F 1E 1C 1A 19 17 16 15 13
8 00 00 00 00 00 00 00 00 00 00 00 00 
9 00 00 00 00 00 00 00 00

1133: FC EF E1 D5 C9 BD B3 A9 9F 96 8E 86 7E 77 71 6A 64 5E 59 54 4F 4B 47 43 3F 3C 38 35 32 2F 2D 2A 27 25 23 21 1F 1E 1C 1A 19 17 16 15 13
```


##MIDI-like Player##

_assumes song src at $1000_

_assumes lookup table src at $1100_


```
0330-   A9 00       LDA   #$00		;	start at zero
0332-   AA          TAX				;	X = 0; LOOP
0333-   BD 00 10    LDA   $1000,X	;	load note duration
0336-   F0 31       BEQ   $0369		;	if note is 0 duration, end the song
0338-   85 FA       STA   $FA		;	store duration at $FA
033A-   E8          INX				;	increment pointer to note value
033B-   BD 00 10    LDA   $1000,X	;	load note MIDI-style value
					TAY				;	lookup note loop value from lookup table
					LDA $1100,Y		;
033E-   85 FB       STA   $FB		;	store note value at $FB
0340-   85 FD       STA   $FD		; 	store note value at $FD
0342-   C9 FF       CMP   #$FF		;	if note value is FF, rest
0344-   D0 06       BNE   $034C		;	skip over if !=FF
0346-   8D 1E 03    STA   $031E		;	change the $C030 click to BIT $FF30	
0349-   8D 13 03    STA   $0313		;	change the $C030 click to BIT $FF30	
034C-   C6 FD       DEC   $FD		;	decrement $FD for That Karateka Sound™
034E-   8A          TXA				;	put current note pointer in Accumulator
034F-   85 FF       STA   $FF		;	store that in $FF						
0351-   20 00 03    JSR   $0300		;	play the actual note
0354-   AD 13 03    LDA   $0313		;	did we mess with the C030 click?
0357-   C9 FF       CMP   #$FF		;	if it's FF, we did. change it back.
0359-   D0 08       BNE   $0363		;	skip if !=FF
035B-   A9 C0       LDA   #$C0		;	set click points back to $c030
035D-   8D 1E 03    STA   $031E		;
0360-   8D 13 03    STA   $0313		;	
0363-   E6 FF       INC   $FF		;	increment to next note address
0365-   A5 FF       LDA   $FF		;	load Accumulator with next note address
0367-   D0 C9       BNE   $0332		;	branch to LOOP
0369-   60          RTS				;


330: A9 00 AA BD 00 10 F0 31 85 FA E8 BD 00 10 A8 B9 00 11 85 FB 85 FD C9 FF D0 06 8D 1E 03 8D 13 03 C6 FD 8A 85 FF 20 00 03 AD 13 03 C9 FF D0 08 A9 C0 8D 1E 03 8D 13 03 E6 FF A5 FF D0 C9 60       





This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 United States License. [http://creativecommons.org/licenses/by-sa/3.0/us/]
