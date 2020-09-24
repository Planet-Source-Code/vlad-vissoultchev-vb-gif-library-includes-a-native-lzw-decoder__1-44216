VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Begin VB.Form frmAnimation 
   Caption         =   "Animation Viewer"
   ClientHeight    =   4608
   ClientLeft      =   48
   ClientTop       =   276
   ClientWidth     =   7200
   LinkTopic       =   "Form1"
   ScaleHeight     =   4608
   ScaleWidth      =   7200
   StartUpPosition =   3  'Windows Default
   WindowState     =   2  'Maximized
   Begin VB.Timer tmrMoveNext 
      Enabled         =   0   'False
      Left            =   924
      Top             =   3780
   End
   Begin VB.PictureBox picBottom 
      Align           =   2  'Align Bottom
      BorderStyle     =   0  'None
      Height          =   516
      Left            =   0
      ScaleHeight     =   516
      ScaleWidth      =   7200
      TabIndex        =   1
      Top             =   4092
      Width           =   7200
      Begin MSComctlLib.Slider sldFrames 
         Height          =   348
         Left            =   3108
         TabIndex        =   6
         Top             =   84
         Visible         =   0   'False
         Width           =   2868
         _ExtentX        =   5059
         _ExtentY        =   614
         _Version        =   393216
         SelectRange     =   -1  'True
      End
      Begin VB.CommandButton cmdClose 
         Cancel          =   -1  'True
         Caption         =   "Close"
         Height          =   348
         Left            =   84
         TabIndex        =   3
         Top             =   84
         Width           =   1440
      End
      Begin VB.CommandButton cmdPlay 
         Caption         =   "Play"
         Height          =   348
         Left            =   1596
         TabIndex        =   2
         Top             =   84
         Visible         =   0   'False
         Width           =   1440
      End
      Begin VB.Label labFrame 
         Caption         =   "0/1"
         Height          =   264
         Left            =   6048
         TabIndex        =   4
         Top             =   168
         Width           =   1692
      End
   End
   Begin VB.PictureBox picView 
      Height          =   3708
      Left            =   0
      ScaleHeight     =   3660
      ScaleWidth      =   6264
      TabIndex        =   0
      Top             =   252
      Width           =   6312
   End
   Begin VB.Label labInfo 
      Height          =   264
      Left            =   84
      TabIndex        =   5
      Top             =   0
      Width           =   6228
   End
End
Attribute VB_Name = "frmAnimation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'=========================================================================
'
'   VB Gif Library Project
'   Copyright (c) 2003 Vlad Vissoultchev
'
'   Demo animation viewer
'
'=========================================================================
Option Explicit
Private Const MODULE_NAME As String = "frmAnimation"

Private Declare Function UpdateWindow Lib "user32" (ByVal hwnd As Long) As Long

Private m_oRenderer             As cBmpRenderer
Private WithEvents m_oReader    As cGifReader
Attribute m_oReader.VB_VarHelpID = -1
Private m_lFrameCount           As Long
Private m_aFrames()             As UcsFrameInfo

Private Type UcsFrameInfo
    oPic        As StdPicture
    nDelay      As Long
End Type

Private Sub ShowError(sFunction As String)
    Screen.MousePointer = vbDefault
    MsgBox Error & vbCrLf & vbCrLf & "Call stack:" & vbCrLf & MODULE_NAME & "." & sFunction & vbCrLf & Err.Source, vbCritical
End Sub

Public Function Init(oRdr As cGifReader) As Boolean
    Const FUNC_NAME     As String = "Init"
    
    On Error GoTo EH
    Screen.MousePointer = vbHourglass
    Set m_oReader = oRdr
    If m_oRenderer.Init(oRdr) Then
        labInfo = m_oRenderer.Reader.FileName
        Set picView.Picture = Nothing
        If oRdr.MoveLast() Then
            m_lFrameCount = oRdr.FrameIndex + 1
            If m_lFrameCount > 1 Then
                sldFrames.Min = 1
                sldFrames.Max = m_lFrameCount
                sldFrames.Visible = True
                cmdPlay.Visible = True
            End If
        End If
        Show vbModal
    End If
    Screen.MousePointer = vbDefault
    Exit Function
EH:
    ShowError FUNC_NAME
    Resume Next
End Function

Private Sub cmdClose_Click()
    Unload Me
End Sub

Private Sub cmdPlay_Click()
    Const FUNC_NAME     As String = "cmdPlay_Click"
    
    On Error GoTo EH
    tmrMoveNext.Enabled = Not tmrMoveNext.Enabled
    cmdPlay.Caption = IIf(tmrMoveNext.Enabled, "Pause", "Play")
    If tmrMoveNext.Enabled Then
        tmrMoveNext_Timer
    End If
    Exit Sub
EH:
    ShowError FUNC_NAME
    Resume Next
End Sub

Private Sub Form_Activate()
    Const FUNC_NAME     As String = "Form_Activate"
    Dim lIdx            As Long
    Dim sInfo           As String
    
    On Error GoTo EH
    If UBound(m_aFrames) < 0 And m_lFrameCount > 0 Then
        Screen.MousePointer = vbHourglass
        ReDim m_aFrames(1 To m_lFrameCount)
        If m_oRenderer.MoveFirst() Then
            lIdx = 0
            sInfo = labInfo
            labInfo = "Loading... " & lIdx + 1 & "/" & m_lFrameCount: DoEvents
            Do While True
                '--- error handling resume next exits loop
                If Not m_oRenderer.MoveNext Then
                    Exit Do
                End If
                lIdx = lIdx + 1
                labInfo = "Loading... " & lIdx + 1 & "/" & m_lFrameCount: DoEvents
                With m_aFrames(lIdx)
                    Set .oPic = m_oRenderer.Image
                    .nDelay = m_oRenderer.Reader.DelayTime
                    sldFrames.Value = lIdx
                    DoEvents
                End With
            Loop
            labInfo = sInfo
        End If
        If cmdPlay.Visible Then
            cmdPlay.Value = True
        End If
        Screen.MousePointer = vbDefault
    End If
    labFrame.Visible = cmdPlay.Visible
    Exit Sub
EH:
    ShowError FUNC_NAME
    Resume Next
End Sub

Private Sub Form_Initialize()
    Set m_oRenderer = New cBmpRenderer
    ReDim m_aFrames(-1 To -1)
End Sub

Private Sub Form_Resize()
    On Error Resume Next
    With picView
        .Move 0, .Top, ScaleWidth, ScaleHeight - .Top - picBottom.Height
    End With
End Sub

Private Sub m_oReader_Progress(ByVal CurrentLine As Long)
    labFrame = Format(CurrentLine / m_oReader.ImageHeight, "0.0%")
    UpdateWindow Me.hwnd
End Sub

Private Sub sldFrames_Change()
    Const FUNC_NAME     As String = "sldFrames_Change"
    Dim lDelay          As Long
    
    On Error GoTo EH
    With m_aFrames(sldFrames.Value)
        lDelay = IIf(.nDelay < 8, 80, .nDelay * 10)
        labFrame = sldFrames.Value & "/" & m_lFrameCount & " (" & lDelay & " ms)"
        Set picView.Picture = .oPic
        If tmrMoveNext.Enabled Then
            tmrMoveNext.Interval = lDelay
            tmrMoveNext.Enabled = False
            tmrMoveNext.Enabled = True
        End If
    End With
    sldFrames.SelLength = sldFrames.Value - 1
    Exit Sub
EH:
    ShowError FUNC_NAME
    Resume Next
End Sub

Private Sub sldFrames_Scroll()
    If tmrMoveNext.Enabled Then
        cmdPlay.Value = True
    End If
    sldFrames_Change
End Sub

Private Sub tmrMoveNext_Timer()
    sldFrames.Value = (sldFrames.Value Mod sldFrames.Max) + 1
End Sub
