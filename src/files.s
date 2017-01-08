
* CALL AFTER GETLN() to copy string to ProDOS parm
StrBufToFilename
                      stx   _filename
                      ldy   #0
:loop                 cpx   #0
                      beq   :done
                      lda   $200,y
                      and   #%01111111     ; clear high bit from crappy GETLN
                      sta   _filename+1,y  ; skip len byte
                      dex
                      iny
                      bne   :loop          ; BRA
:done                 rts


** This is an example string for assembly
** We can overwrite it, but must use str format (leading length byte)
_filename             str   'filename'
_filename_sample_len  =     *-_filename    ; necessary to pad out our example w/o waste
                      ds    255-_filename_sample_len


CreateFile
                      jsr   MLI
                      dfb   $C0
                      da    CreateFileParam
                      bcc   :no_error
:no_error             rts

OpenFile
                      jsr   MLI
                      dfb   $C8            ; OPEN P8 request ($C8)
                      da    OpenFileParam
                      bcc   :no_error
:no_error             rts

WriteFile             lda   OpenRefNum
                      sta   WriteRefNum
                      jsr   MLI
                      dfb   $CB            ; READ P8 request ($CB)
                      da    WriteFileParam
                      lda   WriteResult
                      rts

* Destination loc in ($0)
* NOT 16 bit safe!  Will fail files above one page in size
ReadFile
                                           ;lda   #0
                                           ;sta   IOBuffer
                                           ;sta   IOBuffer+1         ;zero load area, just in case
                      lda   OpenRefNum     ; get file handle of last opened file
                      sta   ReadRefNum
                      jsr   MLI
                      dfb   $CA            ; READ P8 request ($CA)
                      da    ReadFileParam
                      bcs   :readFail

                      ldy   ReadResult
:copy_loop            lda   IOBuffer,y
                      sta   ($0),y
                      dey
                      bpl   :copy_loop
                      rts

:readFail             cmp   #$4C           ;eof - ok on new file
                      beq   :giveUp
                      rts                  ; error bubbles up
:giveUp               clc
                      rts                  ; return with error state



CloseFile
                      lda   OpenRefNum
                      sta   CloseRefNum
                      jsr   MLI
                      dfb   $CC            ; CLOSE P8 request ($CC)
                      da    CloseFileParam
                      rts                  ; return with error state - not checked!



** PRODOS PARAMETER TABLES
OpenFileParam
                      dfb   #$03           ; number of parameters
                      dw    _filename
                      dw    $900
OpenRefNum            db    0              ; assigned by open call


CloseFileParam
                      dfb   #$01           ; number of parameters
CloseRefNum           db    0


CreateFileParam
                      dfb   7              ; number of parameters
                      dw    _filename      ; pointer to filename
                      dfb   $C3            ; normal (full) file access permitted
                      dfb   $06            ; make it a $06 (bin) file
                      dfb   $00,$00        ; AUX_TYPE, not used
                      dfb   $01            ; standard file
                      dfb   $00,$00        ; creation date (unused)
                      dfb   $00,$00        ; creation time (unused)


ReadFileParam
                      dfb   4              ; number of parameters
ReadRefNum            db    0              ; set by open subroutine above
                      da    IOBuffer
                      dw    #256           ; request count (length)
ReadResult            dw    0              ; result count (amount actually read before EOF)


WriteFileParam
                      dfb   4              ; number of parameters
WriteRefNum           db    0              ; set by open subroutine above
                      da    IOBuffer
_write_request_count  dw    #2             ; request count (length)
WriteResult           dw    0              ; result count (amount transferred)


Quit
                      sta   TXTPAGE1       ; Don't forget to give them back the right page!
                      jsr   MLI            ; first actual command, call ProDOS vector
                      dfb   $65            ; QUIT P8 request ($65)
                      da    QuitParm
                      bcs   Error
                      brk   $00            ; shouldn't ever  here!
Error                 brk   $00            ; shouldn't be here either

QuitParm              dfb   4              ; number of parameters
                      dfb   0              ; standard quit type
                      da    $0000          ; not needed when using standard quit
                      dfb   0              ; not used
                      da    $0000          ; not used



                      ds    \
IOBuffer              ds    512
