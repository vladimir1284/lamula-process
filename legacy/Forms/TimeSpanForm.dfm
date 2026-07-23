object FTimeSpan: TFTimeSpan
  Left = 213
  Top = 165
  AutoScroll = False
  Caption = 'Periodo'
  ClientHeight = 272
  ClientWidth = 430
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsMDIChild
  Icon.Data = {
    0000010002002020100000000000E80200002600000010101000000000002801
    00000E0300002800000020000000400000000100040000000000000200000000
    0000000000000000000000000000000000000000800000800000008080008000
    0000800080008080000080808000C0C0C0000000FF0000FF000000FFFF00FF00
    0000FF00FF00FFFF0000FFFFFF00000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000FFFFFFF00000000000000000
    000000FFFFF0FFFFF0000000000000000000FFFFFFF0FFFFFFF0000000000000
    000FFF0FFFF0FFFF0FFF00000000000000FFFFFFFFF0FFFFFFFFF00000000000
    0FFFFFFFFFFFFFFFFFFFFF00000000000FFFFFFFFFFFFF0FFFFFFF0000000000
    FF0FFFFFFFFFFF00FFFF0FF000000000FFFFFFFFFFFFF0F0FFFFFFF00000000F
    FFFFFFFFFFFFF00FFFFFFFFF0000000FFFFFFFFFFFFF0F0FFFFFFFFF0000000F
    FFFFFFFFFFFF00FFFFFFFFFF0000000F0000FFFFFFF0F0FFFFF0000F0000000F
    FFFFFFFFFF0F0FFFFFFFFFFF0000000FFFFFFFFFF0F0F7FFFFFFFFFF0000000F
    FFFFFFFF0F0FFF7FFFFFFFFF00000000FFFFFFF0F0FFFFF7FFFFFFF000000000
    FF0FFF0F0FFFFFFF7FFF0FF0000000000FFFF0F0FFFFFFFFF7FFFF0000000000
    0FFFFF0FFFFFFFFFFF7FFF000000000000FFFFFFFFF0FFFFFFFFF00000000000
    000FFF0FFFF0FFFF0FFF0000000000000000FFFFFFF0FFFFFFF0000000000000
    000000FFFFF0FFFFF00000000000000000000000FFFFFFF00000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000FFFFFFFFFFF01FFFFF8003FFFE0000FFFC00
    007FF800003FF000001FE000000FC0000007C000000780000003800000038000
    0003000000010000000100000001000000010000000100000001000000018000
    00038000000380000003C0000007C0000007E000000FF000001FF800003FFC00
    007FFE0000FFFF8003FFFFF01FFF280000001000000020000000010004000000
    0000800000000000000000000000000000000000000000000000000080000080
    000000808000800000008000800080800000C0C0C000808080000000FF0000FF
    000000FFFF00FF000000FF00FF00FFFF0000FFFFFF0000000000000000000000
    000000000000000000FFF00000000000FFF0FFF00000000FFFF0FFFF000000FF
    FFFFFFFFF00000FFFFFF00FFF0000FFFFFFFFFFFFF000F00FFF00FF00F000FFF
    FF008FFFFF0000FFF00FF8FFF00000FF00FFFF8FF000000FFFF0FFFF00000000
    FFF0FFF00000000000FFF00000000000000000000000FC3F0000F00F0000E007
    0000C00300008001000080010000000000000000000000000000000000008001
    000080010000C0030000E0070000F00F0000FC3F0000}
  Menu = MainMenu1
  OldCreateOrder = True
  Position = poDefaultPosOnly
  Visible = True
  OnActivate = FormResize
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 430
    Height = 240
    ActivePage = TabSheet3
    Align = alClient
    HotTrack = True
    TabOrder = 0
    OnChange = FormResize
    object TabSheet1: TTabSheet
      Caption = 'Caracteristicas'
      object Label4: TLabel
        Left = 10
        Top = 20
        Width = 40
        Height = 13
        Caption = 'Sistema:'
      end
      object Bevel1: TBevel
        Left = 10
        Top = 45
        Width = 400
        Height = 6
        Shape = bsTopLine
      end
      object Label1: TLabel
        Left = 20
        Top = 95
        Width = 34
        Height = 13
        Caption = 'Desde:'
        FocusControl = Edit1
      end
      object Label3: TLabel
        Left = 20
        Top = 120
        Width = 31
        Height = 13
        Caption = 'Hasta:'
        FocusControl = Edit2
      end
      object Label7: TLabel
        Left = 20
        Top = 150
        Width = 82
        Height = 13
        Caption = '&Intervalo maximo:'
        FocusControl = Edit6
      end
      object Label13: TLabel
        Left = 70
        Top = 70
        Width = 33
        Height = 13
        Caption = 'Fecha:'
      end
      object Label14: TLabel
        Left = 220
        Top = 70
        Width = 26
        Height = 13
        Caption = 'Hora:'
      end
      object Edit5: TEdit
        Left = 60
        Top = 20
        Width = 230
        Height = 16
        TabStop = False
        AutoSelect = False
        AutoSize = False
        BorderStyle = bsNone
        Ctl3D = False
        ParentColor = True
        ParentCtl3D = False
        ReadOnly = True
        TabOrder = 0
      end
      object Memo1: TMemo
        Left = 275
        Top = 70
        Width = 130
        Height = 125
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        TabOrder = 1
        WantReturns = False
      end
      object Edit1: TEdit
        Left = 70
        Top = 95
        Width = 150
        Height = 20
        TabStop = False
        AutoSelect = False
        BorderStyle = bsNone
        Ctl3D = False
        ParentColor = True
        ParentCtl3D = False
        ReadOnly = True
        TabOrder = 2
      end
      object Edit2: TEdit
        Left = 70
        Top = 120
        Width = 150
        Height = 20
        TabStop = False
        AutoSelect = False
        BorderStyle = bsNone
        Ctl3D = False
        ParentColor = True
        ParentCtl3D = False
        ReadOnly = True
        TabOrder = 3
      end
      object Edit6: TEdit
        Left = 110
        Top = 150
        Width = 126
        Height = 20
        TabStop = False
        AutoSelect = False
        BorderStyle = bsNone
        Ctl3D = False
        ParentColor = True
        ParentCtl3D = False
        ReadOnly = True
        TabOrder = 4
      end
      object Edit3: TEdit
        Left = 220
        Top = 95
        Width = 45
        Height = 20
        TabStop = False
        AutoSelect = False
        BorderStyle = bsNone
        Ctl3D = False
        ParentColor = True
        ParentCtl3D = False
        ReadOnly = True
        TabOrder = 5
      end
      object Edit4: TEdit
        Left = 220
        Top = 120
        Width = 45
        Height = 20
        TabStop = False
        AutoSelect = False
        BorderStyle = bsNone
        Ctl3D = False
        ParentColor = True
        ParentCtl3D = False
        ReadOnly = True
        TabOrder = 6
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Radar'
      object Label6: TLabel
        Left = 10
        Top = 100
        Width = 117
        Height = 13
        Caption = 'Formatos de adquisicion:'
      end
      object Label2: TLabel
        Left = 10
        Top = 55
        Width = 38
        Height = 13
        Caption = 'Modelo:'
      end
      object Label10: TLabel
        Left = 10
        Top = 15
        Width = 40
        Height = 13
        Caption = 'Nombre:'
      end
      object Label11: TLabel
        Left = 10
        Top = 75
        Width = 58
        Height = 13
        Caption = 'Fabricacion:'
      end
      object Label12: TLabel
        Left = 10
        Top = 35
        Width = 51
        Height = 13
        Caption = 'Ubicacion:'
      end
      object GroupBox1: TGroupBox
        Left = 285
        Top = 15
        Width = 125
        Height = 81
        Caption = 'Coordenadas:'
        Ctl3D = True
        ParentCtl3D = False
        TabOrder = 4
        object Label5: TLabel
          Left = 10
          Top = 20
          Width = 35
          Height = 13
          Caption = 'Latitud:'
        end
        object Label8: TLabel
          Left = 10
          Top = 40
          Width = 44
          Height = 13
          Caption = 'Longitud:'
        end
        object Label9: TLabel
          Left = 10
          Top = 60
          Width = 32
          Height = 13
          Caption = 'Altitud:'
        end
        object Edit8: TEdit
          Left = 60
          Top = 20
          Width = 60
          Height = 15
          TabStop = False
          AutoSelect = False
          AutoSize = False
          BorderStyle = bsNone
          Ctl3D = False
          ParentColor = True
          ParentCtl3D = False
          ReadOnly = True
          TabOrder = 0
        end
        object Edit9: TEdit
          Left = 60
          Top = 40
          Width = 60
          Height = 15
          TabStop = False
          AutoSelect = False
          AutoSize = False
          BorderStyle = bsNone
          Ctl3D = False
          ParentColor = True
          ParentCtl3D = False
          ReadOnly = True
          TabOrder = 1
        end
        object Edit10: TEdit
          Left = 60
          Top = 60
          Width = 60
          Height = 16
          TabStop = False
          AutoSelect = False
          AutoSize = False
          BorderStyle = bsNone
          Ctl3D = False
          ParentColor = True
          ParentCtl3D = False
          ReadOnly = True
          TabOrder = 2
        end
      end
      object Edit13: TEdit
        Left = 80
        Top = 55
        Width = 180
        Height = 15
        TabStop = False
        AutoSelect = False
        AutoSize = False
        BorderStyle = bsNone
        Ctl3D = False
        ParentColor = True
        ParentCtl3D = False
        ReadOnly = True
        TabOrder = 2
      end
      object Edit14: TEdit
        Left = 80
        Top = 15
        Width = 180
        Height = 16
        TabStop = False
        AutoSize = False
        BorderStyle = bsNone
        Ctl3D = False
        ParentColor = True
        ParentCtl3D = False
        ReadOnly = True
        TabOrder = 0
      end
      object Edit15: TEdit
        Left = 80
        Top = 35
        Width = 180
        Height = 16
        TabStop = False
        AutoSize = False
        BorderStyle = bsNone
        Ctl3D = False
        ParentColor = True
        ParentCtl3D = False
        ReadOnly = True
        TabOrder = 1
      end
      object Edit7: TEdit
        Left = 80
        Top = 75
        Width = 180
        Height = 15
        TabStop = False
        AutoSelect = False
        AutoSize = False
        BorderStyle = bsNone
        Ctl3D = False
        ParentColor = True
        ParentCtl3D = False
        ReadOnly = True
        TabOrder = 3
      end
      object StringGrid1: TStringGrid
        Left = 10
        Top = 120
        Width = 400
        Height = 75
        ColCount = 9
        DefaultRowHeight = 16
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goDrawFocusSelected, goColSizing, goEditing, goThumbTracking]
        TabOrder = 5
        OnGetEditText = StringGrid1GetEditText
        OnMouseDown = StringGrid1MouseDown
        OnSelectCell = StringGrid1SelectCell
        OnSetEditText = StringGrid1SetEditText
        ColWidths = (
          18
          43
          30
          43
          42
          52
          36
          43
          64)
      end
    end
    object TabSheet5: TTabSheet
      Caption = 'Productos'
      object SpeedButton5: TSpeedButton
        Left = 308
        Top = 10
        Width = 25
        Height = 25
        Hint = 'Iconos grandes'
        GroupIndex = 1
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000010000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          777777777777700000077777777777777777777777777744447777777777774F
          F47777777777774FF47777777777774F44777000000777444777777777777777
          77777744447777777777774FF47777777777774FF47777777777774F44777777
          7777774447777777777777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButton5Click
      end
      object SpeedButton6: TSpeedButton
        Tag = 1
        Left = 333
        Top = 10
        Width = 25
        Height = 25
        Hint = 'Iconos peque'#241'os'
        GroupIndex = 1
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000010000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          777777744477777777777774F470007777777774477777777777777777777777
          777777777777777777777777777744477777777777774F470007777777774477
          777777777777777777777777777777777777744477777777777774F470007777
          7777744777777777777777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButton5Click
      end
      object SpeedButton7: TSpeedButton
        Tag = 2
        Left = 358
        Top = 10
        Width = 25
        Height = 25
        Hint = 'Lista'
        GroupIndex = 1
        Down = True
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000010000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          7777744477777444777774F4700074F470007447777774477777777777777777
          77777777777777777777744477777444777774F4700074F47000744777777447
          777777777777777777777777777777777777744477777444777774F4700074F4
          7000744777777447777777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButton5Click
      end
      object SpeedButton8: TSpeedButton
        Tag = 3
        Left = 383
        Top = 10
        Width = 25
        Height = 25
        Hint = 'Detalles'
        GroupIndex = 1
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000010000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          7777477000070007000777777777777777774770000700070007777777777777
          7777477000070007000777777777777777774770000700070007777777777777
          7777477000070007000777777777777777774444444444444444777777777777
          7777777000070007000777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButton5Click
      end
      object ListView2: TListView
        Left = 10
        Top = 40
        Width = 400
        Height = 155
        BevelInner = bvNone
        BevelOuter = bvNone
        Columns = <
          item
            Caption = 'Nombre'
            Width = -1
            WidthType = (
              -1)
          end
          item
            Caption = 'Clase'
            Width = -1
            WidthType = (
              -1)
          end
          item
            Caption = 'Descripcion'
            Width = -2
            WidthType = (
              -2)
          end>
        HideSelection = False
        HotTrack = True
        HotTrackStyles = [htHandPoint, htUnderlineHot]
        IconOptions.AutoArrange = True
        ReadOnly = True
        ParentShowHint = False
        PopupMenu = PopupMenu3
        ShowHint = False
        SortType = stBoth
        TabOrder = 0
        ViewStyle = vsList
        OnDblClick = ListView2DblClick
        OnKeyPress = ListView1KeyPress
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Animacion'
      object SpeedButton1: TSpeedButton
        Left = 308
        Top = 10
        Width = 25
        Height = 25
        Hint = 'Iconos grandes'
        GroupIndex = 1
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000010000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          777777777777700000077777777777777777777777777744447777777777774F
          F47777777777774FF47777777777774F44777000000777444777777777777777
          77777744447777777777774FF47777777777774FF47777777777774F44777777
          7777774447777777777777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButton1Click
      end
      object SpeedButton2: TSpeedButton
        Tag = 1
        Left = 333
        Top = 10
        Width = 25
        Height = 25
        Hint = 'Iconos peque'#241'os'
        GroupIndex = 1
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000010000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          777777744477777777777774F470007777777774477777777777777777777777
          777777777777777777777777777744477777777777774F470007777777774477
          777777777777777777777777777777777777744477777777777774F470007777
          7777744777777777777777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButton1Click
      end
      object SpeedButton3: TSpeedButton
        Tag = 2
        Left = 358
        Top = 10
        Width = 25
        Height = 25
        Hint = 'Lista'
        GroupIndex = 1
        Down = True
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000010000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          7777744477777444777774F4700074F470007447777774477777777777777777
          77777777777777777777744477777444777774F4700074F47000744777777447
          777777777777777777777777777777777777744477777444777774F4700074F4
          7000744777777447777777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButton1Click
      end
      object SpeedButton4: TSpeedButton
        Tag = 3
        Left = 383
        Top = 10
        Width = 25
        Height = 25
        Hint = 'Detalles'
        GroupIndex = 1
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000010000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          7777477000070007000777777777777777774770000700070007777777777777
          7777477000070007000777777777777777774770000700070007777777777777
          7777477000070007000777777777777777774444444444444444777777777777
          7777777000070007000777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButton1Click
      end
      object ListView1: TListView
        Left = 10
        Top = 40
        Width = 400
        Height = 155
        BevelInner = bvNone
        BevelOuter = bvNone
        Columns = <
          item
            Caption = 'Nombre'
            Width = -1
            WidthType = (
              -1)
          end
          item
            Caption = 'Clase'
            Width = -1
            WidthType = (
              -1)
          end
          item
            Caption = 'Descripcion'
            Width = -2
            WidthType = (
              -2)
          end>
        HideSelection = False
        HotTrack = True
        HotTrackStyles = [htHandPoint, htUnderlineHot]
        IconOptions.AutoArrange = True
        ReadOnly = True
        ParentShowHint = False
        PopupMenu = PopupMenu3
        ShowHint = False
        SortType = stBoth
        TabOrder = 0
        ViewStyle = vsList
        OnDblClick = ListView1DblClick
        OnKeyPress = ListView1KeyPress
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Observaciones'
      object Button3: TButton
        Left = 340
        Top = 185
        Width = 70
        Height = 20
        Caption = '&Eliminar'
        TabOrder = 0
        OnClick = Button3Click
      end
      object Button2: TButton
        Left = 270
        Top = 185
        Width = 70
        Height = 20
        Caption = '&A'#241'adir...'
        TabOrder = 1
        OnClick = Button2Click
      end
      object StringGrid2: TStringGrid
        Left = 10
        Top = 15
        Width = 400
        Height = 160
        DefaultRowHeight = 16
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goRangeSelect, goColSizing, goRowSelect, goThumbTracking]
        PopupMenu = PopupMenu2
        TabOrder = 2
        OnDblClick = Abrir1Click
        OnKeyPress = StringGrid2KeyPress
        OnMouseDown = StringGrid2MouseDown
        ColWidths = (
          29
          65
          59
          64
          64)
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 240
    Width = 430
    Height = 32
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object Label15: TLabel
      Left = 5
      Top = 2
      Width = 3
      Height = 13
      Transparent = True
      Visible = False
    end
    object ProgressBar1: TProgressBar
      Left = 5
      Top = 16
      Width = 333
      Height = 13
      TabOrder = 0
      Visible = False
    end
    object Button1: TButton
      Left = 348
      Top = 5
      Width = 80
      Height = 25
      Caption = '&Mostrar...'
      Default = True
      TabOrder = 1
      OnClick = Button1Click
    end
  end
  object MainMenu1: TMainMenu
    Left = 400
    object Mostrar1: TMenuItem
      Caption = '&Mostrar'
      GroupIndex = 2
      object Lamina2: TMenuItem
        Caption = '&Lamina'
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Animacion2: TMenuItem
        Caption = '&Animacion'
      end
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 400
    Top = 250
    object Lamina1: TMenuItem
      Caption = '&Lamina'
      OnClick = Lamina1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Animacion1: TMenuItem
      Caption = '&Animacion'
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'tsp'
    Filter = 'Periodos|*.tsp'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
    Title = 'Salvar periodo'
    Left = 369
    Top = 65535
  end
  object OpenDialog1: TOpenDialog
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofPathMustExist, ofFileMustExist]
    Title = 'A'#241'adir observacion'
    Left = 339
    Top = 65535
  end
  object PopupMenu2: TPopupMenu
    Left = 350
    Top = 185
    object Abrir1: TMenuItem
      Caption = '&Abrir'
      OnClick = Abrir1Click
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object Aadir1: TMenuItem
      Caption = 'A'#241'a&dir...'
      ShortCut = 45
      OnClick = Button2Click
    end
    object Eliminar1: TMenuItem
      Caption = '&Eliminar'
      ShortCut = 46
      OnClick = Button3Click
    end
    object N4: TMenuItem
      Caption = '-'
    end
    object Periodo2: TMenuItem
      Caption = '&Periodo'
      OnClick = Periodo2Click
    end
  end
  object PopupMenu3: TPopupMenu
    Left = 380
    Top = 185
    object Predefinido1: TMenuItem
      Caption = '&Predefinido'
      OnClick = Predefinido1Click
    end
    object Editar1: TMenuItem
      Caption = '&Editar...'
      OnClick = Editar1Click
    end
  end
end
