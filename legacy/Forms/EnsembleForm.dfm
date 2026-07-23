object FEnsemble: TFEnsemble
  Left = 278
  Top = 173
  Width = 438
  Height = 316
  Caption = 'Conjunto'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsMDIChild
  Icon.Data = {
    0000010001002020100000000000E80200001600000028000000200000004000
    0000010004000000000000020000000000000000000000000000000000000000
    0000000080000080000000808000800000008000800080800000C0C0C0008080
    80000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000008888800000000000000000000
    0000088888888800000000000000000000008888888888800000000000000000
    0008888888888888000000000000000000088888888888880000000000000000
    0088888888888888800000000000000000888888888888000000000000000000
    0088888888880077708800000000000000888888888077777088880000000000
    0088000008077777708888800000000000007777700777777088888800000000
    0007777770F077770888888800000000080777770FFF07770888888880000000
    888077770FFFF0708888888880000000888807770FFFF0088888888880000008
    888880070FFF0008888888888000000888888880000077088888888880000008
    8888888807777708888888888000000888888888807777088888888800000008
    8888888880777708888888880000000888888888880777088888888000000000
    8888888888807088888888000000000088888888888800888888000000000000
    0888888888880000000000000000000000888888888000000000000000000000
    0000888880000000000000000000000000000000000000000000000000000000
    000000000000000000000000000000000000000000000000000000000000FFFF
    FFFFFFFFFFFFFFE0FFFFFF803FFFFF001FFFFE000FFFFC0007FFFC0007FFF800
    03FFF80000FFF800003FF800001FF800000FF8000007F8000007F0000003E000
    0003E0000003C0000003C0000003C0000003C0000007C0000007C000000FE000
    001FE000003FF00040FFF800FFFFFC01FFFFFF07FFFFFFFFFFFFFFFFFFFF}
  Menu = MainMenu1
  OldCreateOrder = True
  Position = poDefaultPosOnly
  Visible = True
  OnActivate = FormResize
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 230
    Width = 430
    Height = 32
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
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
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 430
    Height = 230
    ActivePage = TabSheet3
    Align = alClient
    HotTrack = True
    TabOrder = 1
    OnChange = FormResize
    object TabSheet1: TTabSheet
      Caption = 'Caracteristicas'
      object Label14: TLabel
        Left = 220
        Top = 70
        Width = 26
        Height = 13
        Caption = 'Hora:'
      end
      object Label13: TLabel
        Left = 70
        Top = 70
        Width = 33
        Height = 13
        Caption = 'Fecha:'
      end
      object Label2: TLabel
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
      end
      object Label4: TLabel
        Left = 10
        Top = 20
        Width = 45
        Height = 13
        Caption = 'Sistemas:'
      end
      object Bevel1: TBevel
        Left = 10
        Top = 45
        Width = 400
        Height = 6
        Shape = bsTopLine
      end
      object Label5: TLabel
        Left = 20
        Top = 178
        Width = 90
        Height = 13
        Caption = '&Duracion del Paso:'
      end
      object Label6: TLabel
        Left = 148
        Top = 178
        Width = 6
        Height = 13
        Caption = 'h'
      end
      object Label8: TLabel
        Left = 193
        Top = 178
        Width = 8
        Height = 13
        Caption = 'm'
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
        TabOrder = 0
        WantReturns = False
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
        TabOrder = 1
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
        TabOrder = 4
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
        TabOrder = 5
      end
      object Edit6: TEdit
        Left = 120
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
        TabOrder = 6
      end
      object Edit7: TEdit
        Left = 115
        Top = 175
        Width = 20
        Height = 21
        TabStop = False
        AutoSelect = False
        ReadOnly = True
        TabOrder = 7
        Text = '1'
        OnChange = EditChange
      end
      object UpDown1: TUpDown
        Left = 135
        Top = 175
        Width = 12
        Height = 21
        Associate = Edit7
        Max = 72
        Position = 1
        TabOrder = 8
      end
      object Edit8: TEdit
        Left = 160
        Top = 175
        Width = 20
        Height = 21
        TabStop = False
        AutoSelect = False
        ReadOnly = True
        TabOrder = 9
        Text = '0'
        OnChange = EditChange
      end
      object UpDown2: TUpDown
        Left = 180
        Top = 175
        Width = 12
        Height = 21
        Associate = Edit8
        Max = 59
        TabOrder = 10
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Radares'
      object StringGrid1: TStringGrid
        Left = 10
        Top = 15
        Width = 400
        Height = 186
        DefaultRowHeight = 16
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goRangeSelect, goColSizing, goRowSelect, goThumbTracking]
        TabOrder = 0
        ColWidths = (
          29
          65
          59
          64
          64)
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
          0400000000008000000000000000000000001000000000000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          777777777777700000077777777777777777777777777744447777777777774F
          F47777777777774FF47777777777774F44777000000777444777777777777777
          77777744447777777777774FF47777777777774FF47777777777774F44777777
          7777774447777777777777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButtonClick
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
          0400000000008000000000000000000000001000000000000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          777777744477777777777774F470007777777774477777777777777777777777
          777777777777777777777777777744477777777777774F470007777777774477
          777777777777777777777777777777777777744477777777777774F470007777
          7777744777777777777777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButtonClick
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
          0400000000008000000000000000000000001000000000000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          7777744477777444777774F4700074F470007447777774477777777777777777
          77777777777777777777744477777444777774F4700074F47000744777777447
          777777777777777777777777777777777777744477777444777774F4700074F4
          7000744777777447777777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButtonClick
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
          0400000000008000000000000000000000001000000000000000000000000000
          80000080000000808000800000008000800080800000C0C0C000808080000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
          7777477000070007000777777777777777774770000700070007777777777777
          7777477000070007000777777777777777774770000700070007777777777777
          7777477000070007000777777777777777774444444444444444777777777777
          7777777000070007000777777777777777777777777777777777}
        ParentShowHint = False
        ShowHint = True
        OnClick = SpeedButtonClick
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
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Paso'
      object Label1: TLabel
        Left = 10
        Top = 55
        Width = 286
        Height = 13
        AutoSize = False
        Caption = 'Desde 22/12/97-11:02, hasta 22/12/97-22:57 '
      end
      object TrackBar1: TTrackBar
        Left = 0
        Top = 10
        Width = 307
        Height = 30
        Max = 0
        PageSize = 1
        TabOrder = 0
        OnChange = TrackBar1Change
      end
      object ListView2: TListView
        Left = 312
        Top = 10
        Width = 100
        Height = 196
        BevelInner = bvNone
        BevelOuter = bvNone
        Columns = <
          item
            Caption = 'Producto'
            Width = -2
            WidthType = (
              -2)
          end>
        HotTrack = True
        HotTrackStyles = [htHandPoint, htUnderlineHot]
        PopupMenu = PopupMenu3
        TabOrder = 1
        ViewStyle = vsList
      end
      object StringGrid2: TStringGrid
        Left = 10
        Top = 80
        Width = 287
        Height = 125
        ColCount = 6
        DefaultRowHeight = 16
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goRangeSelect, goColSizing, goRowSelect, goThumbTracking]
        PopupMenu = PopupMenu2
        TabOrder = 2
        OnEnter = StringGrid2Enter
        OnExit = StringGrid2Exit
        ColWidths = (
          29
          65
          59
          20
          2
          64)
      end
    end
    object TabSheet5: TTabSheet
      Caption = 'Observaciones'
      object StringGrid3: TStringGrid
        Left = 10
        Top = 15
        Width = 400
        Height = 160
        ColCount = 7
        DefaultRowHeight = 16
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goRangeSelect, goColSizing, goRowSelect, goThumbTracking]
        PopupMenu = PopupMenu2
        TabOrder = 0
        OnDblClick = Abrir1Click
        OnKeyPress = StringGrid3KeyPress
        ColWidths = (
          29
          65
          59
          64
          55
          44
          64)
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
      object Button3: TButton
        Left = 340
        Top = 185
        Width = 70
        Height = 20
        Caption = '&Eliminar'
        TabOrder = 2
        OnClick = Button3Click
      end
    end
  end
  object MainMenu1: TMainMenu
    Left = 400
    object Mostrar1: TMenuItem
      Caption = '&Mostrar'
      GroupIndex = 2
      object Producto2: TMenuItem
        Caption = '&Producto'
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Animacion2: TMenuItem
        Caption = '&Animacion'
      end
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'ens'
    Filter = 'Conjuntos|*.ens'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
    Title = 'Salvar conjunto'
    Left = 369
    Top = 65535
  end
  object OpenDialog1: TOpenDialog
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofPathMustExist, ofFileMustExist]
    Title = 'A'#241'adir observacion'
    Left = 339
    Top = 65535
  end
  object PopupMenu1: TPopupMenu
    Left = 400
    Top = 250
    object Producto1: TMenuItem
      Caption = '&Producto'
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Animacion1: TMenuItem
      Caption = '&Animacion'
    end
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
    object Conjunto2: TMenuItem
      Caption = '&Conjunto'
      OnClick = Conjunto2Click
    end
  end
  object PopupMenu3: TPopupMenu
    Left = 380
    Top = 185
    object Predefinido1: TMenuItem
      Caption = '&Predefinido'
    end
    object Editar1: TMenuItem
      Caption = '&Editar...'
    end
  end
end
