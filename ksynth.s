				ORG		$0300

DURATION		EQU		$FA					; Note DURATION
XCOUNTER		EQU		$FB					; X oscillator counter
MULTIPLIER		EQU		$FC					; duration multiplier (defaults to $ff)	
OSCILLATOR		EQU		$FD					; second oscillator value - decrements once for vibrato
OSCCOUNTER		EQU		$FE					; tracks second oscillator value
SEQUENCE		EQU		$FF					; note number/address offset from song origin
MIDILOOKUP		EQU		$1100				; MIDI style note lookup table
SONGORIGIN		EQU		$1000				; song header start address
CLICKBIT1		EQU		$031E				; modified byte - set to FF for rest note
CLICKBIT2		EQU		$0313


GENERATOR		LDA		OSCILLATOR			; load second oscillator value into $FE
				STA		OSCCOUNTER			; 
				LDA		#$FF				; load duration multiplier into $FC
				STA		MULTIPLIER			; 
				LDY		DURATION			; load duration into Y
				LDX		XCOUNTER			; load oscillator into X
STARTCOUNT		DEX							; start countdown first oscillator, X
				NOP							; wait...
				NOP							; 
				BNE		COUNTDOWN2			; if X = 0, click. otherwise, skip
CLICK1			BIT		$C030				; click
RESETX			LDX		XCOUNTER			; reset X to beginning of countdown
COUNTDOWN2		DEC		OSCCOUNTER			; countdown second oscillator, $FE
				NOP							; wait...
				NOP							; 
				BNE		COUNTTIME			; if $FE = 0, click. otherwise, skip
CLICK2			BIT		$C030				; click
RESETOSC2		LDA		OSCILLATOR			; reset $FE to beginning of countdown
				STA		OSCCOUNTER			; 
COUNTTIME		DEY							; countdown duration
				BNE		STARTCOUNT			; if duration hasn't expired, return and count down oscillators
				LDY		DURATION			; if duration has expired, reset duration 
COUNTTIME2		DEC		MULTIPLIER			; decrement duration multiplier
				BNE		STARTCOUNT			; if multiplier hasn't expired, return and count down oscillators
				RTS							; all done
				
				ORG 	$0330
				
				
PLAYER			LDA		#$00				; start at zero
]LOOP 			TAX							; X = 0	; LOOP
				LDA		SONGORIGIN,X		; load note duration
				BEQ		ENDSONG				; if note is 0 duration, end the song
				STA		DURATION			; store duration at $FA
				INX							; increment pointer to note value
				LDA		SONGORIGIN,X		; load note MIDI-style value
				TAY							; lookup note loop value from lookup table
				LDA		MIDILOOKUP,Y		; 
				STA		XCOUNTER			; store note value at $FB
				STA		OSCILLATOR			; 	store note value at $FD
				CMP		#$FF				; if note value is FF, rest
				BNE		SETOSC2				; skip over if !=FF
				STA		CLICKBIT1			; change the $C030 click to BIT $FF30	
				STA		CLICKBIT2			; change the $C030 click to BIT $FF30	
SETOSC2 		DEC		OSCILLATOR			; decrement $FD for That Karateka Sound™
				TXA							; put current note pointer in Accumulator
				STA		SEQUENCE			; store that in $FF						
				JSR		GENERATOR			; play the actual note
				LDA		CLICKBIT1			; did we mess with the C030 click?
				CMP		#$FF				; if it's FF, we did. change it back.
				BNE		NEXTNOTE			; skip if !=FF
				LDA		#$C0				; set click points back to $c030
				STA		CLICKBIT1			; 
				STA		CLICKBIT2			; 
NEXTNOTE		INC		SEQUENCE			; increment to next note address
				LDA		SEQUENCE			; load Accumulator with next note address
				BNE		]LOOP				; branch to LOOP
ENDSONG 		RTS							; 
	
	
				ORG		$1130											; MIDI lookup table
				
				HEX		00,00,00,FC,EF,E1,D5,C9,BD,B3,A9,9F,96,8E,86,7E	; $1130
				HEX		77,71,6A,64,5E,59,54,4F,4B,47,43,3F,3C,38,35,32	; $1140
				HEX		2F,2D,2A,27,25,23,21,1F,1E,1C,1A,19,17,16,15,13	; $1150
			