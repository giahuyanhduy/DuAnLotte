#include <ColorConstants.au3>
#include <GuiConstantsEx.au3>
#include <EditConstants.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <Array.au3>
#include <File.au3>
#Include <WinAPIEx.au3>
#include <FileConstants.au3>
#include <Math.au3>
#include <StaticConstants.au3>
#include <Date.au3>
;#include "ColorRef.au3"
;Opt("mustdeclarevars", 1)
;Opt("TrayIconHide", 1)	; khong hien thi tren system tray
OnAutoItExitRegister("OnAutoItExit")

Const $MAX_PAR = 32			; Toi da truyen nhan 32 TEXT

Global $con_status = 0	; trang thai ket noi
Global $iSocket = 0
Global $f_ready = 0 ; khi nhan clipboard thi = 1 khi in xong 4 ban tin thi = 0

dim $CMD_START
dim $CMD_STOP
dim $CMD_UPDATE

dim $WE_Sock ; WE socket


Global $iX1 = 20
Global $X11 = 150
Global $iX2 = 300
Global $X2 = 500

Global $iWIDTH = 280
Global $iHEGHT = 32
Global $iY	= 25

Global $Y1	= 30
Global $Y11	= 60
Global $Y2	= 30
Global $Y3	= 90
Global $Y31	= 120
Global $Y4	= 150
Global $Y5	= 300

Global $butW = 120
Global $barW = 460

Global $ip
Global $port
Global $user
Global $pass

global $debugtxt = "" ; Dung cho chuong trinh MiniKey Connect

Global $oldWeight = 0

;---------------------------------------------------------------------------
if FileExists("data.ini") Then

   $ip = IniRead("data.ini","MINIKEY","IP","192.168.1.123")
   $port = IniRead("data.ini","MINIKEY","Port","3000")
   $user = IniRead("data.ini","MINIKEY","User","admin")
   $pass = IniRead("data.ini","MINIKEY","Pass","1234")

   if ProcessExists ("CT1WE.EXE") Then
	  MsgBox(0,"Info","WE Ready !",2)
   Else
	  Run("CT1WE.EXE")
	  sleep(500)
   EndIf
   SRandom(@SEC+@MIN*60)

   ;_ArrayDisplay($sMsg);
Else
	  msgbox(0,"ERROR","data.ini file Not Found")
	  Exit
EndIf


;---------------------------------------------------------------------------------------------
; MAIN LOOP
;---------------------------------------------------------------------------------------------


local $hGUI = GUICreate("WEIGH & PRINT V1.0", 640 , 220 , 120, 120);@DesktopHeight - 480)
GUICtrlSetState(-1, $GUI_ACCEPTFILES)
GUISetFont(12,200)

Global $LBL1 = GUICtrlCreateLabel("WEIGH", $iX1, $Y11, $iWIDTH, $iHEGHT*2.8,$SS_LEFT)
GUISetFont(38,400)
Global $LBL2 = GUICtrlCreateLabel("-----g", $X11, $Y1, $iWIDTH, $iHEGHT*2.8,$SS_RIGHT,0x1001)
GUICtrlSetColor(-1, 0xFF6060) ; RED/GREEN/BLUE
GUICtrlSetBkColor(-1, Ramdom_BLUE()) ; Ramdom_BLUE() 0xB0B0FF

GUISetFont(12,200)

local $id_Button_PRINT = GUICtrlCreateButton("&PRINT",  $X2, $Y2, $butW, $butW*0.36);,$SS_CENTER)
GUICtrlSetState($id_Button_PRINT, $GUI_DISABLE)
;GUICtrlSetColor(-1, $COLOR_RED + $COLOR_GREEN)

local $idStatus = GUICtrlCreateLabel("MiniKey IP:"&$ip, $iX1, $Y4+$iHEGHT/3, $barW, $iHEGHT,0x1001)
GUICtrlSetColor(-1, $COLOR_GREEN)
GUICtrlSetBkColor(-1, 0xF0E060)

local $id_Button_CONN = GUICtrlCreateButton("&CONNECT", $X2, $Y3, $butW, $butW*0.36)
GUICtrlSetColor(-1, $COLOR_RED + $COLOR_GREEN)

local $id_Button_EXIT = GUICtrlCreateButton("E&XIT", $X2, $Y4, $butW, $butW*0.36)
GUICtrlSetColor(-1, $COLOR_BLACK)

;local $hEdit = GUICtrlCreateEdit($debugtxt,$iX1,($iY +$iHEGHT*7.5),  @DesktopWidth  - 690, 250)

GUISetState()

Mk_setup()



if Connect() = 0 then
   $con_status = 1
   GUICtrlSetData($id_Button_CONN,"&DISCON")
   ;GUICtrlSetState($Button1, $GUI_DISABLE)
   GUICtrlSetState($id_Button_PRINT, $GUI_ENABLE)
   GUICtrlSetData($idStatus,"Minikey: Connected")
   ;ConsoleWrite ("MINIKEY OK")
EndIf

;ConsoleWrite("Socket:"&$iSocket&@CR)
;$con_status = 1

global $WE_sock = WE_Connect()

local $tcpMsg = ""

local $Connect_timer = TimerInit()

dim $aWE_data
dim $WE_status
dim $PRN_data

local $WE_wait = 0

While(1)

   if (TimerDiff($Connect_timer) > 500) AND ($WE_wait = 0) Then
	  if $WE_sock <> -1 Then
		 TCPSend($WE_Sock,"REQ#")
		 $WE_wait = 1
	  Else
		 $WE_sock = WE_Connect()
	  EndIf
   ElseIf TimerDiff($Connect_timer) > 5000 Then
	  $Connect_timer = TimerInit()
	  TCPCloseSocket($WE_sock)
	  $WE_sock = WE_Connect()
	  $WE_wait = 0
   EndIf

   if ($con_status = 1) Then
	  ;GUICtrlSetData($id_Button_CONN,"&DISCON")
	  ;poll_rcv()	;kiem tra nhan du lieu
   EndIf


   $tcpMsg = $tcpMsg & TCPRecv($WE_Sock, 32)

   local $cEnd = StringRight($tcpMsg,1)
   If $cEnd = "#" Then ; ket thuc lenh ?

	  $tcpMsg = StringLeft($tcpMsg,Stringlen($tcpMsg)-1)
	  ConsoleWrite($tcpMsg&@CRLF)

	  $aWE_data  = StringSplit($tcpMsg,"|")

	  if $aWE_data[0] =3 Then
		 ;_ArrayDisplay($aWE_data)
		 $WE_status = $aWE_data[1]
		 $PRN_data = $aWE_data[2]&$aWE_data[3]

		 if NOT($PRN_data = $oldWeight) Then
			$oldWeight = $PRN_data
			Print()		; goi DL ra may in
		 EndIf

		 GUICtrlSetData($LBL2,$PRN_data);
		 if $WE_status = "ST" Then
			GUICtrlSetBkColor($LBL2, Ramdom_BLUE()) ;
		 Else
			GUICtrlSetBkColor($LBL2, Ramdom_YELLOW()) ;
		 EndIf

		 $Connect_timer = TimerInit()

	  EndIf

	  $WE_wait = 0
	  $tcpMsg = ""

   EndIf

   local $gui_msg = GUIGetMsg()
   Select
	  Case $gui_msg = $GUI_EVENT_CLOSE
		 Exit
	  Case $gui_msg = $id_Button_EXIT
		 Exit
	  Case $gui_msg = $id_Button_CONN
		   ; $debugtxt = ""
			if ($con_status = 0) Then
				  if Connect() = 0 then
					 $con_status = 1
					 GUICtrlSetData($id_Button_CONN,"&DISCON")
					 GUICtrlSetData($idStatus,"Minikey: Connected")
					 GUICtrlSetState($id_Button_PRINT, $GUI_ENABLE)
				  EndIf
			Else
				  Disconnect()
					 $con_status = 0
					 GUICtrlSetData($id_Button_CONN,"&CONNECT")
					 GUICtrlSetData($idStatus,"Minikey: Disconnected")
					 GUICtrlSetState($id_Button_PRINT, $GUI_DISABLE)
				  EndIf
	  Case $gui_msg = $id_Button_PRINT
			Print()
			Send_CMD($CMD_START)

;#cs
;		 local $sCMDTMP = "CMD:U;Printing data;" & $PRN_data &"#"
;		 local $err_cnt = Send_CMD("OBJ:Static1;TEX="&$PRN_data&"#")

;			$err_cnt += Send_CMD($sCMDTMP)
;			$err_cnt += Send_CMD($CMD_UPDATE)
;			$err_cnt += Send_CMD($CMD_START)

;		 if $err_cnt = 0 Then
;			GUICtrlSetData($idStatus,"Printing: "&$PRN_data)
;		 Else
;			GUICtrlSetData($idStatus,"Minikey communication error")
;		 EndIf
;#ce
   EndSelect

WEnd

;-----------------------------------------------------------------
func Print()
   		 local $sCMDTMP = "CMD:U;Printing data;" & $PRN_data &"#"
		; local $err_cnt = Send_CMD("OBJ:Text1;TEX="&$PRN_data&"#")

		 local $err_cnt = Send_CMD("OBJ:Static1;TEX="&$PRN_data&"#")

			$err_cnt += Send_CMD($sCMDTMP)
			$err_cnt += Send_CMD($CMD_UPDATE)
			;$err_cnt += Send_CMD($CMD_START)

		 if $err_cnt = 0 Then
			GUICtrlSetData($idStatus,"Printing: "&$PRN_data)
		 Else
			GUICtrlSetData($idStatus,"Minikey communication error")
		 EndIf
EndFunc


func Ramdom_BLUE() ; tao mau xanh duong thay doi

   local $r = int(Random(0x90,0xD8));
   $r = $r*0x10000 + $r*0x100 + 0xFF
   return $r

EndFunc

func Ramdom_YELLOW() ; tao mau xanh duong thay doi
   local $r = int(Random(0x60,0xD0));
   $r = 0xFF*0x10000 + 0xFF*0x100 + $r
   return $r
EndFunc


;-----------------------------------------------------------------
Func OnAutoItExit()
   TCPSend($WE_Sock,"END#")
   GUICtrlSetData($idStatus,"Please wait a minute !")
   if $iSocket > 0 Then
	  ;Send_CMD($CMD_STOP)
	  Disconnect()
	  CloseTCP()
	  ToolTip("")
   EndIf
EndFunc   ;==>OnAutoItExit

#include "mkutils.au3"

;-----------------------------------------------------------------
Func WE_Connect()

local $Server = @IPAddress1
local $Port = 5000
TCPStartup()
local $Socket = TCPConnect(TCPNameToIP($Server), $Port)
return $Socket
EndFunc


#cs
   $sCMDTMP = "CMD:U;MSG "&$sMsg[$cnt]&";DENSITY "& $roll_density &"GSM;CODE "& $roll_product &"#"
   $err_cnt += Send_CMD($sCMDTMP)
   $err_cnt += Send_CMD($CMD_UPDATE)
#ce

