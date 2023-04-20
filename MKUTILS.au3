; AutoIt Version 3.0.103
; Language:       English
; Author:         Larry Bailey
; Email:          psichosis@tvn.net
; Date: January 11, 2005
;
; Script Function
; Creates a simple GUI showing the use of
; a label, a combobox and a button
; Selecting an item from the combobox
; and clicking the button updates the label text
#include <ColorConstants.au3>
#include <GuiConstantsEx.au3>
#include <EditConstants.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <Array.au3>
#include <File.au3>
#Include <WinAPIEx.au3>

dim $ip
dim $port
dim $user
dim $pass
;dim $con_status	;trang thai ket noi
dim $iSocket
;dim $f_log
;dim $hEdit
dim $debugtxt

;global $CMD_LOGIN = "CMD:C;admin;1234#"
Func Mk_setup()	; goi truoc de thiet lap thong so
   const $CMD_ST = "OBJ:"		; lenh cua minikey ; CB la : "OBJECT:"
   const $CMD_SEP = "="		; dau cach giua lenh va content : CB la ";"
   Const $CMD_END = "#" 		; ket thuc truyen du lieu; giong CB

   ;global $CMD_LOGIN = "CMD:C;admin;1234#"
   global $CMD_LOGIN = "CMD:C;"&$user&";"&$pass&"#"
   global $CMD_DISCON = "CMD:D#"
   global $CMD_START = "CMD:R#"
   global $CMD_STOP = "CMD:S#"
   global $CMD_UPDATE = "CMD:B#"
   ;global $CMD_TXT = "OBJ:Text1;TEX = this is a test#"
   global $REQ_PD = "REQ:PD;on#"
   global $REQ_PI = "REQ:PI#"
   ;CMD:U;User control;Do not;turn off#

   ;global $REQ_TXT1 = "REQ:OBJ;"&$sTXT1&"#" // Su dung cai nay truoc -> static1 -> REQ:CON;Static1
   global $REQ_TXT1 = "REQ:CON;Static1#"
   global $REQ_TXT2 = "REQ:CON;Static2#"
   global $REQ_TXT3 = "REQ:CON;Static3#"
   global $REQ_TXT4 = "REQ:CON;Static4#"

   global $sRCV = " "

   return True
EndFunc

;--------------------------------------------------------------------------------------------------------
Func Send_CMD($sCMD)
local $retry = 2;
   ;ConsoleWrite ($sCMD&@CR)
   ;return True
   if $iSocket > 0 Then
	  While $retry > 0
		 $retry -= 1;
		 $debugtxt &= @CRLF&$sCMD
		 ;GUICtrlSetData($hEdit,$debugtxt)
		 ConsoleWrite ($sCMD&@CR)
		 TCPSend ( $iSocket, $sCMD )
		 Sleep(100)
		 if _chk_rep_() Then
			Return 0 ; true
			;ToolTip("")
		 EndIf
		 Sleep(20)
	  WEnd
	  ;GUICtrlSetData($id_EDIT_TERM,$sCMD&@CRLF,$ES_AUTOVSCROLL + $WS_VSCROLL)
   EndIf
   ;GUICtrlSetData($id_EDIT_TERM,"!!! TCP PORT is not ready !!!"&@CRLF,$ES_AUTOVSCROLL + $WS_VSCROLL)
   ;ToolTip("CMD:F")
   return 1 ; false
EndFunc
;------------
Func _chk_rep_()
local $retry = 50
local $res_OK = "RES:0"
local $res_login = "RES:104" ;User remote login not allowed#
local $res_start = "RES:220" ;Printing, can't start now#
;global $sRCV = " "

   While ($retry > 0)
	  $retry -= 1
	  local $rcv_Data = TCPRecv($iSocket, 4096, 1)
	  if BinaryLen($rcv_Data) > 0 Then
		 $sRCV=BinaryToString($rcv_Data)
		 $debugtxt &= " --> "&$sRCV
		 ;GUICtrlSetData($hEdit,$debugtxt)
		 ConsoleWrite ("->"&$sRCV&@CR)
		 ;ToolTip("RCV:"&$sRCV)

		 ;FileWrite ($f_log, "RCV:"&$sRCV&@CRLF)

		 local $search = StringInStr($sRCV,$res_OK)

		 if ($search > 0) Then
			Return True
		 EndIf

		 local $search = StringInStr($sRCV,$res_login)

		 if ($search > 0) Then
			Return True
		 EndIf

		 local $search = StringInStr($sRCV,$res_start)

		 if ($search > 0) Then
			Return True
		 EndIf

	  EndIf
	  Sleep(10)
   WEnd
	  ;FileWrite ($f_log, "RCV:"&$sRCV&@CRLF)
	  Return False
EndFunc
;--------------------------------------------------------------------------------------------------------------
Func Tcp_Init()

   TCPStartup() ; Start the TCP service.
   $iSocket = TCPConnect($ip, $port)
   If @error Then
		; The server is probably offline/port is not opened on the server.
		;Local $iError = @error
		msgbox(0,"ERROR","MINIKEY IP Not found")
		;MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "ERROR", "Could not connect, Error code: " & $iError)
		Return False
   Else
		;MsgBox($MB_SYSTEMMODAL, "Info", "Connect to HSAJET controller unit successful")
   EndIf

   Return True
EndFunc   ;==>Example

;------------------------------------------------------------------------------------------------------------
Func Disconnect()
   local $isStop = "print=off"
	  if Send_CMD($REQ_PI) > 0 Then
		 Return 1
	  EndIf

	  local $search = StringInStr($sRCV,$isStop)
	  if $search = 0 Then
		 Send_CMD($CMD_STOP)
		 Sleep(3000)
	  EndIf
	  Send_CMD($CMD_DISCON)
	  $iCOM_STATUS = 0
	  CloseTCP()
	  ;TCPCloseSocket($iSocket)
EndFunc   ;==>OnAutoItExit

Func CloseTCP()
   TCPCloseSocket($iSocket)
   TCPShutdown() ; Close the TCP service.
EndFunc
;------------------------------------------------------------------------------------------------------------
Func Connect()
   ;MsgBox($MB_SYSTEMMODAL, "HERE", "here, I'm")
	  if Tcp_Init() Then
;		 $iCOM_STATUS = 1
		 TCP_read(0) ;xoa buffer
		 if Send_CMD($CMD_LOGIN) > 0 Then
			return 1
		 EndIf

		 Sleep(500)
		 TCP_read(0) ;xoa buffer
		 if Send_CMD($REQ_PD) > 0 Then
			return 1
		 EndIf
		 Sleep (200)
		 TCP_read(0) ;xoa buffer

		 if Send_CMD($REQ_PI) >0 Then
			return 1
		 EndIf
		 Sleep (200)
		 local $sPI = TCP_read(1) ;xoa buffer
		 ;MsgBox($MB_OK,"PI",$sPI)
		 ;if $sPi = "on;prints" Then
			;MsgBox($MB_OK,"PI","DANG IN")
			;$iHsaStatus = 1
		 ;Else
			;MsgBox($MB_OK,"PI","DANG TAT")
			;$iHsaStatus = 0
		 ;EndIf
		 ;Load()
	  Else
		 return 1;
	  EndIf
	  return 0;
EndFunc   ;==>OnAutoItExit

;------------------------------------------------------------------------------------------------------------
Func Load()
   local $sResult
   ;if ($iCOM_STATUS = 1) Then
	  Sleep (500)
	  TCP_read(0)
	  Send_CMD($REQ_TXT1)
	  $iSet_TXT1 = TCP_read(0)
	  Sleep (200)
	  Send_CMD($REQ_TXT2)
	  $iSet_TXT2 = TCP_read(0)
	  Sleep (200)
	  Send_CMD($REQ_TXT3)
	  $iSet_TXT3 = TCP_read(0)
	  Sleep (200)
	  Send_CMD($REQ_TXT4)
	  $iSet_TXT4 = TCP_read(0)

   ;EndIf
EndFunc
;------------------------------------------------------------------------------------------------------------
Func CallMsg($msg)

local $isStop = "print=off"

	  if Send_CMD($REQ_PI) > 0 Then
		 return 1
	  EndIf
	  local $search = StringInStr($sRCV,$isStop)
	  if $search = 0 Then
		 Send_CMD($CMD_STOP)
		 Sleep(3000)
	  EndIf

   local $cmd = "CMD:F;"&$msg&"#"
   local $r=0
   $r=Send_CMD($cmd)
   if $r>0 Then
	  MsgBox(0,"ERROR", "!!! MINIKEY OPEN FILE ERROR !!!")
	  ToolTip("ERROR MINIKEY")
	  return 1;
   EndIf
   return 0;
EndFunc

#cs
CMD:F;FILE1# Load “File1”
RES:0;Transmission OK# ..accepted
OBJ:batch;TEX=12345# Chg. batch to 12345
#ce
;-----------------------------------------------------------------------------

Func TCP_read($iPrevious) ; previous=1 khi muon doc trang thai may in : on/off
   local $rcv_Data = TCPRecv($iSocket, 4096, 1)
	  if BinaryLen($rcv_Data) > 0 Then
			local $sRCV=BinaryToString($rcv_Data)
			;GUICtrlSetData($id_EDIT_TERM,"*"&$sRCV&@CRLF,$ES_AUTOVSCROLL + $WS_VSCROLL)
			local $aTMP1 = StringSplit($sRCV,"=")
			local $aTMP2 = StringSplit($aTMP1[$aTmp1[0]-$iPrevious],"#")
			;_ArrayDisplay($aTMP2)
			if ($aTMP2[0]>0) Then
			   return $aTMP2[1]
			EndIf
	  EndIf
   Return False
EndFunc
#cs
$iSet_SEN=GUICtrlRead($id_input_SEN)
$iSet_SEN+=0.20
GUICtrlSetData($id_input_SEN,$iSet_SEN)

*DAT:Text1=text;pos=0,0pix;ori=0;font=AriN18;static=Static1;sep=#RES:0;Transmission OK#
SYS:PRD;1#

2
SYS:PRD
1#

#ce
