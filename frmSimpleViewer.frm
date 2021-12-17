VERSION 5.00
Begin VB.Form frmSimpleViewer 
   Caption         =   "Bitmap Viewer"
   ClientHeight    =   4644
   ClientLeft      =   48
   ClientTop       =   276
   ClientWidth     =   6600
   LinkTopic       =   "Form2"
   ScaleHeight     =   4644
   ScaleWidth      =   6600
   StartUpPosition =   3  'Windows Default
   WindowState     =   2  'Maximized
   Begin VB.PictureBox picBottom 
      Align           =   2  'Align Bottom
      BorderStyle     =   0  'None
      Height          =   516
      Left            =   0
      ScaleHeight     =   516
      ScaleWidth      =   6600
      TabIndex        =   2
      Top             =   4128
      Width           =   6600
      Begin VB.CommandButton cmdClose 
         Cancel          =   -1  'True
         Caption         =   "Close"
         Height          =   348
         Left            =   84
         TabIndex        =   5
         Top             =   84
         Width           =   1440
      End
      Begin VB.CommandButton cmdNext 
         Caption         =   "Next"
         Default         =   -1  'True
         Height          =   348
         Left            =   3108
         TabIndex        =   4
         Top             =   84
         Width           =   1440
      End
      Begin VB.CommandButton cmdFirst 
         Caption         =   "First"
         Height          =   348
         Left            =   1596
         TabIndex        =   3
         Top             =   84
         Width           =   1440
      End
      Begin VB.Label labFrame 
         Caption         =   "0/1"
         Height          =   264
         Left            =   4620
         TabIndex        =   6
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
      Top             =   336
      Width           =   6312
   End
   Begin VB.Label labInfo 
      Height          =   264
      Left            =   84
      TabIndex        =   1
      Top             =   84
      Width           =   6228
   End
End
Attribute VB_Name = "frmSimpleViewer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'=========================================================================
'
'   VB Gif Library Project
'   Copyright (c) 2003 Vlad Vissoultchev
'
'   Demo simple viewer
'
'=========================================================================
Option Explicit
Private Const MODULE_NAME As String = "frmSimpleViewer"

Private m_oRenderer             As cBmpRenderer
Private WithEvents m_oReader    As cGifReader
Attribute m_oReader.VB_VarHelpID = -1
Private m_lFrameCount           As Long

Private Sub ShowError(sFunction As String)
    Screen.MousePointer = vbDefault
    MsgBox Error & vbCrLf & vbCrLf & "Call stack:" & vbCrLf & MODULE_NAME & "." & sFunction & vbCrLf & Err.Source, vbCritical
End Sub

Public Function Init(oRdr As cGifReader)
    Const FUNC_NAME     As String = "Init"
    
    On Error GoTo EH
    Set m_oReader = oRdr
    If m_oRenderer.Init(oRdr) Then
        labInfo = m_oRenderer.Reader.FileName
        Set picView.Picture = Nothing
        If oRdr.MoveLast() Then
            m_lFrameCount = oRdr.FrameIndex + 1
        End If
        If m_oRenderer.MoveFirst() Then
            cmdNext_Click
        End If
        Show vbModal
    End If
    Exit Function
EH:
    ShowError FUNC_NAME
    Resume Next
End Function

Private Sub cmdClose_Click()
    Unload Me
End Sub

Private Sub cmdFirst_Click()
    Const FUNC_NAME     As String = "cmdFirst_Click"
    
    On Error GoTo EH
    Screen.MousePointer = vbHourglass
    Set picView.Picture = Nothing
    If m_oRenderer.MoveFirst() Then
        If m_oRenderer.MoveNext() Then
            Set picView.Picture = m_oRenderer.Image
        End If
    End If
    Screen.MousePointer = vbDefault
    Exit Sub
EH:
    ShowError FUNC_NAME
    Resume Next
End Sub

Private Sub cmdNext_Click()
    Const FUNC_NAME     As String = "cmdNext_Click"
    
    On Error GoTo EH
    Screen.MousePointer = vbHourglass
    If m_oReader.EOF Then
        m_oRenderer.MoveFirst
    End If
    If m_oRenderer.MoveNext() Then
        Set picView.Picture = m_oRenderer.Image
    Else
        If m_oRenderer.MoveFirst() Then
            If m_oRenderer.MoveNext() Then
                Set picView.Picture = m_oRenderer.Image
            End If
        End If
    End If
    Screen.MousePointer = vbDefault
    Exit Sub
EH:
    ShowError FUNC_NAME
    m_oRenderer.MergeCurrentImage
    Resume Next
End Sub

Private Sub Form_Initialize()
    Set m_oRenderer = New cBmpRenderer
End Sub

Private Sub Form_Resize()
    On Error Resume Next
    With picView
        .Move 0, .Top, ScaleWidth, ScaleHeight - .Top - picBottom.Height
    End With
End Sub

Private Sub m_oReader_ImageComplete()
    labFrame = m_oReader.FrameIndex + 1 & "/" & m_lFrameCount
End Sub
