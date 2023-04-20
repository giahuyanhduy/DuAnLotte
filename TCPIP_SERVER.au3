#include-once
Dim $tmpSocket
Dim $curSocket
Dim $MainSocket
Dim $htimer_Client
#cs
TCPSetup() ;
While 1
   local $dd = getTCP()
   If $dd <> "" Then
	  putTCP($dd) ; Chen doan SEND2RS232 here
   EndIf
WEnd
#ce
;------------------------------------------------------------------------------------------
Func putTCP ($str)
   TCP_Service()
   local $sent = TCPSend($curSocket, $str)
   If @error Then ; Bad connection detected
	  $curSocket = -1
	  $tmpSocket = -1
   Else
	  $htimer_Client = TimerInit()
   EndIf
EndFunc
;--------------------------------------------------------------------------------------------------
Func TCPsetup($Port) ; chi goi 1 lan de khoi tao KET NOI
Local $MaxCon = 2; Maximum Amount Of Concurrent Connections ; chi truyen/nhan voi connect sau cung.
Global $MaxLength = 128
Global $tmpSocket = -1
Global $curSocket = -1
Global $ipPort = $Port
Global $htimer_Client = TimerInit()	 ; luu lai thoi gian de tinh timeout
Global $MainSocket = TCPStartServer($ipPort, $MaxCon);
If $MainSocket = -1 Then return -1
AutoItSetOption ("TCPTimeout",5) ; default = 100
Return 0
EndFunc
;-------------------------------------------------------------------------------------------------
;Dung de kiem tra Packet duoc goi tu Client hay khong, phai duoc goi lien tuc de duy tri ket noi
;-------------------------------------------------------------------------------------------------
Func getTCP()    ;
   TCP_Service()
   Local $Data = ""
   if $CurSocket >= 0 Then
	  $Data = TCPRecv($curSocket, $MaxLength)   ; Ham nay gay cham chuong trinh ~100ms khi khong co ky tu nhan
	  if $Data <> "" Then						; Da dat Option TCPTimeOut = 5 de xu ly tinh trang cham ~100ms nay.
		 $htimer_Client = TimerInit()	 	; luu lai thoi gian de tinh timeout
	  EndIf
   EndIf
 return $Data
 EndFunc
;------------------------------------------------------------------------------------------
Func TCP_Service() ; Goi de duy tri connect; TCP Polling here ;
   if TimerDiff($htimer_Client) > 10000 Then ; Sau 10s
	  ;MsgBox(0,"Warning","TCP Restart !!!",1)
	  ConsoleWrite("* TCP Restart *"&@CRLF)
	  $tmpSocket = -1 ; Tiep tuc nhan ket noi moi
	  TCPCloseSocket($MainSocket)
	  TCPShutdown()
	  TCPsetup($ipPort)
   EndIf

   if $tmpSocket = -1 Then
	  $tmpSocket = TCPAccept($MainSocket)
	  TCPSend($tmpSocket, "Connected!")
	  if $tmpSocket >= 0 Then
		 $curSocket = $tmpSocket
	  EndIf
   EndIf

EndFunc
;------------------------------------------------------------------------------------------
Func TCPStartServer($Port, $MaxConnect = 2)
    Local $Socket
    $Socket = TCPStartup()
    Select
        Case $Socket = 0
            SetError(@error)
            Return -1
    EndSelect
    $Socket = TCPListen(@IPAddress1, $Port, $MaxConnect)
    Select
        Case $Socket = -1
            SetError(@error)
            Return 0
    EndSelect
    SetError(0)
    Return $Socket
 EndFunc  ;==>TCPStartServer

;-------------------------------------------------------------------------
Func TCPIP_OnAutoItExit() ; Chua chay o day

  ; MsgBox(0,"EXIT","THOAT")

   If $curSocket <> - 1 Then
        TCPCloseSocket($curSocket)
   EndIf

   If $MainSocket <> -1 Then
	  TCPCloseSocket($MainSocket)
   EndIf

   TCPShutdown()
   ConsoleWrite("TCPIP Shutdown")
EndFunc;==>OnAutoItExit