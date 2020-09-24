VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cIconRenderer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'=========================================================================
'
'   VB Gif Library Project
'   Copyright (c) 2003 Vlad Vissoultchev
'
'   Renders frames from cGifReader to 8bpp icons each packed in StdPicture
'
'=========================================================================
Option Explicit
Private Const MODULE_NAME As String = "cIconRenderer"

'=========================================================================
' API
'=========================================================================

'--- for GetStockObject
Private Const WHITE_BRUSH           As Long = 0
Private Const BLACK_BRUSH           As Long = 4

Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As Long)
Private Declare Function GetDC Lib "user32" (ByVal hwnd As Long) As Long
Private Declare Function ReleaseDC Lib "user32" (ByVal hwnd As Long, ByVal hDC As Long) As Long
Private Declare Function CreateCompatibleDC Lib "gdi32" (ByVal hDC As Long) As Long
Private Declare Function CreateCompatibleBitmap Lib "gdi32" (ByVal hDC As Long, ByVal nWidth As Long, ByVal nHeight As Long) As Long
Private Declare Function DeleteDC Lib "gdi32" (ByVal hDC As Long) As Long
Private Declare Function SelectObject Lib "gdi32" (ByVal hDC As Long, ByVal hObject As Long) As Long
Private Declare Function DeleteObject Lib "gdi32" (ByVal hObject As Long) As Long
Private Declare Function StretchDIBits Lib "gdi32" (ByVal hDC As Long, ByVal X As Long, ByVal Y As Long, ByVal dx As Long, ByVal dy As Long, ByVal SrcX As Long, ByVal SrcY As Long, ByVal wSrcWidth As Long, ByVal wSrcHeight As Long, lpBits As Any, lpBitsInfo As Any, ByVal wUsage As Long, ByVal dwRop As Long) As Long
Private Declare Function OleCreatePictureIndirect Lib "olepro32.dll" (lpPictDesc As PICTDESC, riid As Any, ByVal fPictureOwnsHandle As Long, IPic As IPicture) As Long
Private Declare Function BitBlt Lib "gdi32" (ByVal hdcDest As Long, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hdcSrc As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal dwRop As Long) As Long
Private Declare Function SetBkColor Lib "gdi32" (ByVal hDC As Long, ByVal crColor As Long) As Long
Private Declare Function SetTextColor Lib "gdi32" (ByVal hDC As Long, ByVal crColor As Long) As Long
Private Declare Function CreateIconIndirect Lib "user32" (piconinfo As ICONINFO) As Long
Private Declare Function FillRect Lib "user32" (ByVal hDC As Long, lpRect As RECT, ByVal hBrush As Long) As Long
Private Declare Function GetStockObject Lib "gdi32" (ByVal nIndex As Long) As Long

Private Type BITMAPINFOHEADER '40 bytes
    biSize              As Long
    biWidth             As Long
    biHeight            As Long
    biPlanes            As Integer
    biBitCount          As Integer
    biCompression       As Long
    biSizeImage         As Long
    biXPelsPerMeter     As Long
    biYPelsPerMeter     As Long
    biClrUsed           As Long
    biClrImportant      As Long
End Type

Private Type RGBQUAD
    rgbBlue             As Byte
    rgbGreen            As Byte
    rgbRed              As Byte
    rgbReserved         As Byte
End Type

Private Type BITMAPINFO
    bmiHeader           As BITMAPINFOHEADER
    bmiColors(0 To 255) As RGBQUAD
End Type

Private Type RECT
    Left                As Long
    Top                 As Long
    Right               As Long
    Bottom              As Long
End Type

Private Type PICTDESC
    Size                As Long
    Type                As Long
    hBmpOrIcon          As Long
    hPal                As Long
End Type

Private Type ICONINFO
    fIcon               As Long
    xHotspot            As Long
    yHotspot            As Long
    hbmMask             As Long
    hbmColor            As Long
End Type

'=========================================================================
' Constants and member variables
'=========================================================================

Private m_oReader                   As cGifReader
'--- for screen and image arrays
Private m_aImageBits()              As Byte
Private m_aImageLut()               As Byte
'--- look-up table 'powers-of-two'
Private m_aPOT(-1 To 31)            As Long

'=========================================================================
' Error management
'=========================================================================

Private Sub RaiseError(sFunction As String)
    With Err
        .Raise .Number, MODULE_NAME & "." & sFunction & IIf(Erl <> 0, "(" & Erl & ")", "") & vbCrLf _
                & .Source, .Description, .HelpFile, .HelpContext
    End With
End Sub

Private Sub PrintError(sFunction As String)
    Debug.Print MODULE_NAME; "."; sFunction; IIf(Erl <> 0, "(" & Erl & ")", ""); ": "; Err.Description
End Sub

'=========================================================================
' Properties
'=========================================================================

Property Get Reader() As cGifReader
    Set Reader = m_oReader
End Property

Property Get ImageWidth() As Long
    ImageWidth = m_oReader.ImageWidth
End Property

Property Get ImageHeight() As Long
    ImageHeight = m_oReader.ImageHeight
End Property

Property Get Image() As StdPicture
    Const FUNC_NAME     As String = "Image [get]"
    Dim uHead           As BITMAPINFO
    Dim uII             As ICONINFO
    Dim rc              As RECT
    Dim lpPictDesc      As PICTDESC
    Dim aGuid(0 To 3)   As Long
    Dim lIdx            As Long
    Dim lJdx            As Long
    Dim lPass           As Long
    Dim lStep           As Long
    Dim lScanLine       As Long
    Dim aBuffer()       As Byte
    Dim hDC             As Long
    Dim hBmp            As Long
    Dim hOldBmp         As Long
    Dim hSrcDC          As Long
    Dim hMaskDC         As Long
    Dim hMaskBmp        As Long
    Dim hPrevMaskBmp    As Long
    Dim hIcon           As Long
    
    On Error GoTo EH
    '--- prepare BITMAPINFO
    With uHead.bmiHeader
        .biSize = Len(uHead.bmiHeader)
        .biPlanes = 1
        .biBitCount = 8
        .biWidth = ImageWidth
        .biHeight = -ImageHeight
    End With
    '--- transform copy LUT
    For lIdx = 0 To 255
        With uHead.bmiColors(lIdx)
            .rgbRed = m_aImageLut(3 * lIdx + 0)
            .rgbGreen = m_aImageLut(3 * lIdx + 1)
            .rgbBlue = m_aImageLut(3 * lIdx + 2)
        End With
    Next
    If m_oReader.IsTransparent Then
        With uHead.bmiColors(m_oReader.TransparentIndex)
            .rgbRed = &HFF
            .rgbGreen = 0
            .rgbBlue = &HFF
        End With
    End If
    '--- fix padding
    lScanLine = pvPadScanline(ImageWidth)
    If ImageWidth <> lScanLine Or m_oReader.IsInterlaced Then
        ReDim aBuffer(lScanLine * ImageHeight) As Byte
        '--- take care of iterlace too
        For lPass = -4 * m_oReader.IsInterlaced - 1 To (Not m_oReader.IsInterlaced) Step -1
            lStep = m_aPOT(lPass + 1)
            If lStep > 8 Then
                lStep = 8
            End If
            For lIdx = (m_aPOT(lPass) Mod 8) To ImageHeight - 1 Step lStep
                CopyMemory aBuffer(lIdx * lScanLine), m_aImageBits(lJdx * ImageWidth), ImageWidth
                lJdx = lJdx + 1
            Next
        Next
    Else
        aBuffer = m_aImageBits
    End If
    '--- prepare dc
    hSrcDC = GetDC(0)
    hDC = CreateCompatibleDC(hSrcDC)
    hBmp = CreateCompatibleBitmap(hSrcDC, ImageWidth, ImageHeight)
    Call ReleaseDC(0, hSrcDC)
    '--- paint
    hOldBmp = SelectObject(hDC, hBmp)
    Call StretchDIBits(hDC, _
            0, 0, ImageWidth, ImageHeight, _
            0, 0, ImageWidth, ImageHeight, _
            aBuffer(0), uHead, 0, vbSrcCopy)
    '--- alloc resources
    hMaskDC = CreateCompatibleDC(0)
    hMaskBmp = CreateCompatibleBitmap(hMaskDC, ImageWidth, ImageHeight)
    If m_oReader.IsTransparent Then
        '--- select bitmaps
        hPrevMaskBmp = SelectObject(hMaskDC, hMaskBmp)
        '--- create mask
        SetBkColor hDC, vbMagenta '  TransparentColor
        SetTextColor hDC, vbWhite
        BitBlt hMaskDC, 0, 0, ImageWidth, ImageHeight, hDC, 0, 0, vbSrcCopy
        '--- do mask image
        SetBkColor hDC, vbBlack
        BitBlt hDC, 0, 0, ImageWidth, ImageHeight, hMaskDC, 0, 0, vbSrcAnd
        '--- deselect bitmaps
        Call SelectObject(hMaskDC, hPrevMaskBmp)
    Else
        rc.Right = ImageWidth
        rc.Bottom = ImageHeight
        FillRect hMaskDC, rc, GetStockObject(BLACK_BRUSH)
    End If
    Call SelectObject(hDC, hOldBmp)
    '--- create icon
    With uII
        .fIcon = 1
        .hbmColor = hBmp
        .hbmMask = hMaskBmp
    End With
    hIcon = CreateIconIndirect(uII)
    '--- cleanup
    Call DeleteObject(hMaskBmp)
    Call DeleteObject(hBmp)
    Call DeleteDC(hMaskDC)
    Call DeleteDC(hDC)
    '--- fill struct
    With lpPictDesc
        .Size = Len(lpPictDesc)
        .Type = vbPicTypeIcon
        .hBmpOrIcon = hIcon
        .hPal = 0
    End With
    '--- fill in magic IPicture GUID {7BF80980-BF32-101A-8BBB-00AA00300CAB}
    aGuid(0) = &H7BF80980
    aGuid(1) = &H101ABF32
    aGuid(2) = &HAA00BB8B
    aGuid(3) = &HAB0C3000
    '--- create picture from bitmap handle
    Call OleCreatePictureIndirect(lpPictDesc, aGuid(0), True, Image)
    Exit Property
EH:
    RaiseError FUNC_NAME
End Property

'=========================================================================
' Methods
'=========================================================================

Public Function Init(oReader As cGifReader) As Boolean
    Const FUNC_NAME     As String = "Init"
    
    On Error GoTo EH
    Set m_oReader = oReader
    Init = True
    Exit Function
EH:
    RaiseError FUNC_NAME
End Function

Public Function MoveFirst() As Boolean
    Const FUNC_NAME     As String = "MoveFirst"
    
    On Error GoTo EH
    If m_oReader.MoveFirst() Then
        MoveFirst = True
    End If
    Exit Function
EH:
    RaiseError FUNC_NAME
End Function

Public Function MoveNext() As Boolean
    Const FUNC_NAME     As String = "MoveNext"
    
    On Error GoTo EH
    If m_oReader.MoveNext() Then
        m_aImageBits = m_oReader.ImageBits
        m_aImageLut = m_oReader.ImageLut
        MoveNext = True
    End If
    Exit Function
EH:
    RaiseError FUNC_NAME
End Function

Private Function pvPadScanline(ByVal lOffset As Long)
'--- DIB section horizontal scanline padding to dword
    pvPadScanline = (lOffset + 3) And (Not 3)
End Function

'=========================================================================
' Base class events
'=========================================================================

Private Sub Class_Initialize()
    Dim lIdx            As Long
    
    '--- init look-up table for fast 2 ^ x
    m_aPOT(-1) = 0
    m_aPOT(0) = 1
    For lIdx = 1 To 30
        m_aPOT(lIdx) = 2 * m_aPOT(lIdx - 1)
    Next
    m_aPOT(31) = &H80000000
End Sub
