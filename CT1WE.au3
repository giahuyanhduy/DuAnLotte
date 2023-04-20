#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include 'CommMG.au3'
#include 'TCPIP_SERVER.au3'

;Opt("mustdeclarevars", 1)
Opt("TrayIconHide", 1)	; khong hien thi tren system tray
OnAutoItExitRegister("OnAutoItExit")
;#Region Configure Hotkeys
;HotKeySet('{ScrollLock}', '_Exit')
Global $lpControl = 1
;#EndRegion Configure Hotkeys


;COM Vars
Global $CMPort = 1				; Port
Global $CmBoBaud = 9600			; Baud
Global $CmboDataBits =  8		; Data Bits
Global $CmBoParity = "none"		; Parity
Global $CmBoStop = 1			; Stop
Global $setflow = 2				; Flow
Global $sportSetError = ""

Global $WE_port = 5000
TCPSetup(5000) ; Khoi tai TCP PORT 5000


if FileExists("we.ini") Then
   $CMPort = IniRead("we.ini","CONNECT","Port",1)				; Port
   $CmBoBaud = IniRead("we.ini","CONNECT","Baud",9600)			; Baud
   $CmBoParity = IniRead("we.ini","CONNECT","Parity","none")
   $CmBoStop = IniRead("we.ini","CONNECT","Stopbit",1)
   $sUnit = IniRead("we.ini","WE","Unit","KG")
   ConsoleWrite ("WE.INI LOADED")
EndIf

;ToolTip("PORT:"&$CMPort,0,0)

_CommSetPort($CMPort, $sportSetError, $CmBoBaud, $CmboDataBits, $CmBoParity, $CmBoStop, $setflow)
_CommSetBufferSizes(2048,2048)

Global $OutPut = "NC|-----|"&$sUnit&"#" ; Not connect
local  $tcpMsg = ""

local $Connect_timer = TimerInit()
local $comStr = ""

while ($lpControl) ; MAIN LOOP

   if TimerDiff($Connect_timer) > 60000 Then ;sau 1 phut tat
	  Global $OutPut = "NC|-----|"&$sUnit&"#" ; Not connect
	  ;ConsoleWrite ($OutPut&@CRLF)
   EndIf

   $tcpMsg = $tcpMsg & getTCP()  ; Ham nay bi cham khi khong co ky tu nhan ; gay loi tran buffer input cua RS232
								 ; moi lan goi chi nhan 1 ky tu ???
   ;ConsoleWrite($tcpMsg&@CRLF)

   local $cEnd = StringRight($tcpMsg,1)

   If $cEnd = "#" Then ; ket thuc lenh ?
	  ConsoleWrite($tcpMsg)
	  $tcpMsg = StringLeft($tcpMsg,3)

	  if StringCompare($tcpMsg,"REQ") = 0 Then
		 putTCP($OutPut)
	  ElseIf StringCompare($tcpMsg,"END") = 0 Then ; Lenh ket thuc chuong trinh
		 $lpControl = 0 ; Dat DK thoat
	  EndIf

	  $tcpMsg = ""
   EndIf


   if  Number(_CommGetInputcount()) > 0 Then

	  do
		 $comStr = $comStr & _Commgetstring() ;_CommGetLine(@CR,1000)
		 Sleep(10);    // cho doc het chuoi
		 ;ToolTip($comStr,0,0);

	  Until Number(_CommGetInputCount()) = 0



	  ;thuat toan: tim dau cham cua trong luong,tu phai sang trai
	  ;tim chuoi $sUnit ("Kg") trong khoang 16 ky tu cuoi
	  ;Neu co : lay nguoc ve tu dau cham 3 ky tu den chu Kg -> trong luong.

	  ;ToolTip(">"&$comStr,0,0); hien thi man hinh

	  If StringLen($comStr) > 9 Then

		 ;local $dotPos = StringInStr($comStr,'.',0,-1)
		 ;local $unitPos = StringInStr($comStr,$sUnit,0,-1)
		 ;If  ($dotPos > 0) And ($unitPos > 0) Then
		 ;If  ($unitPos > 4) Then
			;local $nchar = $unitPos - $dotPos + 3
			local $startcpy =StringLen($comStr) - 7  ;$unitPos - 4
			local $weight = Number(stringMid($comStr,$startcpy,5))/1000
			local $unit = $sUnit  ; "KG"
			$OutPut = "ST"&"|"&$weight&"|"&$unit&"#"
			ConsoleWrite ($comStr&"->"&$OutPut&@CRLF)
			$Connect_timer = TimerInit()
			local $comStr = ""
		 ;EndIf


	  EndIf



#cs
	  If StringLen($comStr) > 10 Then
		 ;ConsoleWrite($comStr) ;  ST,GS,+      0.00     g : DL can tra ve
		 $comStr = StringStripWS ($comStr, 8 ) ; Strip ALL -> ST,GS,+0.00g
		 local $status = StringLeft($comStr,2)
		 local $weight = Number(stringMid($comStr,7,(StringLen($comStr)-7)))
		 local $unit = StringRight($comStr,1)
		 $OutPut = $status&"|"&$weight&"|"&$unit&"#"
		 ;ConsoleWrite ($OutPut&@CRLF)
		 $Connect_timer = TimerInit()
	  EndIf
#ce

   EndIf

WEnd

Exit
;------------------------------------------------------
Func _Exit() ; Goi tu HotKey "ScrLk"
   $lpControl = 0 ; Dat DK thoat
EndFunc
;------------------------------------------------------
Func OnAutoItExit() ; Chua chay o day

   TCPIP_OnAutoItExit()

EndFunc

