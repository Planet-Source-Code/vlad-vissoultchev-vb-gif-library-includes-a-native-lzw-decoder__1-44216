VERSION 5.00
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "comdlg32.ocx"
Begin VB.Form frmMain 
   BorderStyle     =   3  'Fixed Dialog
   Caption         =   "VB Gif Library"
   ClientHeight    =   2652
   ClientLeft      =   36
   ClientTop       =   264
   ClientWidth     =   7656
   Icon            =   "frmMain.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   2652
   ScaleWidth      =   7656
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdAnimation 
      Caption         =   "Animation"
      Height          =   348
      Left            =   6132
      TabIndex        =   7
      Top             =   2184
      Width           =   1440
   End
   Begin VB.CommandButton cmdClose 
      Cancel          =   -1  'True
      Caption         =   "Close"
      Height          =   348
      Left            =   84
      TabIndex        =   6
      Top             =   2184
      Width           =   1440
   End
   Begin VB.CommandButton cmdIconRenderer 
      Caption         =   "View Deltas"
      Height          =   348
      Left            =   4620
      TabIndex        =   5
      Top             =   2184
      Width           =   1440
   End
   Begin VB.CommandButton cmdBmpView 
      Caption         =   "View"
      Height          =   348
      Left            =   3108
      TabIndex        =   4
      Top             =   2184
      Width           =   1440
   End
   Begin VB.Frame Frame1 
      Caption         =   "GIF Info"
      Height          =   1860
      Left            =   84
      TabIndex        =   1
      Top             =   168
      Width           =   7488
      Begin VB.Label labInfo 
         Height          =   1356
         Left            =   1932
         TabIndex        =   3
         Top             =   252
         Width           =   5472
      End
      Begin VB.Label labCaptions 
         Alignment       =   1  'Right Justify
         Height          =   1356
         Left            =   84
         TabIndex        =   2
         Top             =   252
         Width           =   1776
      End
   End
   Begin VB.CommandButton cmdOpen 
      Caption         =   "Open..."
      Default         =   -1  'True
      Height          =   348
      Left            =   1596
      TabIndex        =   0
      Top             =   2184
      Width           =   1440
   End
   Begin MSComDlg.CommonDialog comDlg 
      Left            =   0
      Top             =   0
      _ExtentX        =   677
      _ExtentY        =   677
      _Version        =   393216
      CancelError     =   -1  'True
      DialogTitle     =   "Gif file"
      Filter          =   "Gif files (*.gif)|*.gif|All files (*.*)|*.*"
      Flags           =   4
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'=========================================================================
'
'   VB Gif Library Project
'   Copyright (c) 2003 Vlad Vissoultchev
'
'   Demo main form
'
'=========================================================================
Option Explicit
Private Const MODULE_NAME As String = "frmMain"

Private m_oReader           As cGifReader

Private Sub ShowError(sFunction As String)
    Screen.MousePointer = vbDefault
    MsgBox Error & vbCrLf & vbCrLf & "Call stack:" & vbCrLf & MODULE_NAME & "." & sFunction & vbCrLf & Err.Source, vbCritical
End Sub

Private Sub cmdAnimation_Click()
    Const FUNC_NAME     As String = "cmdAnimation_Click"
    Dim oFrm            As New frmAnimation
    
    On Error GoTo EH
    oFrm.Init m_oReader
    Exit Sub
EH:
    ShowError FUNC_NAME
    Resume Next
End Sub

Private Sub cmdBmpView_Click()
    Const FUNC_NAME     As String = "cmdBmpView_Click"
    Dim oFrm            As New frmSimpleViewer
    
    On Error GoTo EH
    oFrm.Init m_oReader
    Exit Sub
EH:
    ShowError FUNC_NAME
    Resume Next
End Sub

Private Sub cmdIconRenderer_Click()
    Const FUNC_NAME     As String = "cmdIconRenderer_Click"
    Dim oFrm            As New frmDeltaViewer
    
    On Error GoTo EH
    oFrm.Init m_oReader
    Exit Sub
EH:
    ShowError FUNC_NAME
    Resume Next
End Sub

Private Sub cmdClose_Click()
    Unload Me
End Sub

Private Sub cmdOpen_Click()
    Const FUNC_NAME     As String = "cmdOpen_Click"
    
    On Error GoTo EHCancel
    comDlg.ShowOpen
    On Error GoTo EH
    If m_oReader.Init(comDlg.FileName) Then
        labCaptions = "Filename:" & vbCrLf & "Resolution:" & vbCrLf
        labInfo = m_oReader.FileName & vbCrLf & m_oReader.ScreenWidth & "x" & m_oReader.ScreenHeight & vbCrLf
        If m_oReader.IsTransparent Then
            labCaptions = labCaptions & "Transparent Index:" & vbCrLf
            labInfo = labInfo & m_oReader.TransparentIndex & vbCrLf
        End If
        m_oReader.MoveLast
        If m_oReader.FrameIndex > 1 Then
            labCaptions = labCaptions & "Frames:" & vbCrLf
            labInfo = labInfo & m_oReader.FrameIndex + 1 & vbCrLf
        End If
    Else
        labCaptions = ""
        labInfo = ""
    End If
EHCancel:
    Exit Sub
EH:
    ShowError FUNC_NAME
    Resume Next
End Sub

Private Sub Form_Initialize()
    Set m_oReader = New cGifReader
End Sub

