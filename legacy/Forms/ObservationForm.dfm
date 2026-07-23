object FObservation: TFObservation
  Left = 304
  Top = 219
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  AutoScroll = False
  Caption = 'Observacion'
  ClientHeight = 272
  ClientWidth = 430
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
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
    0088777777777777777770000000000000088888888888888888000000000000
    0000000000000000000000000000000000000000888880000000000000000000
    0000000888880000000000000000000000000088877000000000000000000000
    000008877700000000000000000000000000877770000777770088FF00000000
    00087770007777770088888F0000000000887700777777008888888F00000000
    0087700777777008888888F0000000000087007777770088888888F000000000
    000008777770088888888F000000000000000877770088888888F00000000000
    00008877700888888888F000000000000000877700888888888F000000000000
    000087700008888888F000000000000000088700880088888F00000000000000
    0008800888800888F000000000000000000800888888008F0000000000000000
    008808888888800000000000000000000080888888888F000000000000000000
    008088888888F000000000000000000000088888888F00000F88000000000000
    0008888888F0000000F800000000000000888888FF0000000000800000000000
    00F888FF00000000000000000000000000FFFF00000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000FC00007FF800003FFC00007FFE0000FFFFE0
    3FFFFFC07FFFFF80FFFFFF01800FFE000007FC000007F8000007F800000FF800
    000FFC00001FFF00003FFE00003FFE00007FFE0000FFFC0001FFFC0003FFFC00
    07FFF8000FFFF8000FFFF80020FFF800707FF800F87FF801FC7FF803FFFFF80F
    FFFFFC3FFFFFFFFFFFFFFFFFFFFF280000001000000020000000010004000000
    0000800000000000000000000000000000000000000000000000000080000080
    000000808000800000008000800080800000C0C0C000808080000000FF0000FF
    000000FFFF00FF000000FF00FF00FFFF0000FFFFFF0000000000000000000007
    777777700000000007770000000000007780000000000008880088007F000078
    808880777F000080088807777000000088807777F00000078807777F00000008
    800777F00000000007707F00000000707777000000000007777F000000000007
    77700000000000077F0000000000000F000000000000C007FFFFE00FFFF0F8FF
    7008F0EF8888E001FFFFC001FFF0C0030088F007888FE007FFFFE00FFFF0E01F
    0008C03F88F0C04FFFFFC0E7FF08C1FF8800C7FF8F0F}
  Menu = MainMenu1
  OldCreateOrder = True
  PopupMenu = PopupMenu1
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
    ActivePage = TabSheet1
    Align = alClient
    HotTrack = True
    TabOrder = 0
    OnChange = PageControl1Change
    object TabSheet1: TTabSheet
      Caption = 'Caracteristicas'
      object Label1: TLabel
        Left = 160
        Top = 70
        Width = 33
        Height = 13
        Caption = '&Fecha:'
      end
      object Label3: TLabel
        Left = 160
        Top = 147
        Width = 39
        Height = 13
        Caption = '&Archivo:'
      end
      object Label4: TLabel
        Left = 10
        Top = 20
        Width = 40
        Height = 13
        Caption = 'Sistema:'
      end
      object Label7: TLabel
        Left = 160
        Top = 97
        Width = 26
        Height = 13
        Caption = '&Hora:'
      end
      object Bevel1: TBevel
        Left = 10
        Top = 45
        Width = 400
        Height = 6
        Shape = bsTopLine
      end
      object Label13: TLabel
        Left = 160
        Top = 170
        Width = 42
        Height = 13
        Caption = '&Tama'#241'o:'
      end
      object Edit1: TEdit
        Left = 210
        Top = 69
        Width = 191
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
      object Edit3: TEdit
        Left = 210
        Top = 146
        Width = 165
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
        TabOrder = 1
      end
      object Memo1: TMemo
        Left = 15
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
      object Edit4: TEdit
        Left = 210
        Top = 169
        Width = 165
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
      object Edit6: TEdit
        Left = 210
        Top = 97
        Width = 100
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
      object Edit2: TEdit
        Left = 210
        Top = 117
        Width = 100
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
        TabOrder = 5
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
        TabOrder = 0
        OnGetEditText = StringGrid1GetEditText
        OnMouseDown = StringGridMouseDown
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
        TabOrder = 3
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
        TabOrder = 1
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
        TabOrder = 2
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
        TabOrder = 4
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Productos'
      DesignSize = (
        422
        212)
      object SpeedButton1: TSpeedButton
        Left = 323
        Top = 0
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
        OnClick = SpeedButtonClick
      end
      object SpeedButton2: TSpeedButton
        Tag = 1
        Left = 348
        Top = 0
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
        OnClick = SpeedButtonClick
      end
      object SpeedButton3: TSpeedButton
        Tag = 2
        Left = 373
        Top = 0
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
        OnClick = SpeedButtonClick
      end
      object SpeedButton4: TSpeedButton
        Tag = 3
        Left = 398
        Top = 0
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
        OnClick = SpeedButtonClick
      end
      object ListView1: TListView
        Left = 5
        Top = 28
        Width = 410
        Height = 178
        Anchors = [akLeft, akTop, akRight, akBottom]
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
            Caption = 'Descripci'#243'n'
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
      Caption = 'Exploraciones'
      object StringGrid2: TStringGrid
        Left = 10
        Top = 15
        Width = 400
        Height = 186
        ColCount = 7
        DefaultRowHeight = 16
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goRangeSelect, goColSizing, goRowSelect, goThumbTracking]
        PopupMenu = PopupMenu2
        TabOrder = 0
        OnDblClick = StringGrid2DblClick
        OnKeyPress = StringGrid2KeyPress
        OnMouseDown = StringGridMouseDown
        ColWidths = (
          29
          65
          59
          59
          59
          54
          50)
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
  object PopupMenu1: TPopupMenu
    Left = 400
    Top = 250
    object Superior1: TMenuItem
      Caption = '&Maximos'
      OnClick = SuperiorClick
    end
    object Lluvia1: TMenuItem
      Caption = '&Intensidad'
      OnClick = LluviaClick
    end
    object Topes1: TMenuItem
      Caption = '&Topes'
      OnClick = TopesClick
    end
    object Volumen1: TMenuItem
      Caption = '&Volumen'
      OnClick = VolumenClick
    end
    object Espacial1: TMenuItem
      Caption = '&Espacial'
      OnClick = Espacial1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Producto1: TMenuItem
      Caption = '&Producto'
    end
    object Animacion1: TMenuItem
      Caption = '&Animacion'
      object Espacial2: TMenuItem
        Tag = 1
        Caption = '&Espacial...'
        OnClick = Espacial1Click
      end
    end
  end
  object PopupMenu2: TPopupMenu
    OnPopup = PopupMenu2Popup
    Left = 281
    Top = 21
    object Precipitacion1: TMenuItem
      Tag = 3
      Caption = '&Precipitacion'
      OnClick = MovementClick
    end
    object Reflectividad1: TMenuItem
      Tag = 2
      Caption = '&Reflectividad'
      OnClick = MovementClick
    end
    object Potencia1: TMenuItem
      Tag = 1
      Caption = 'Po&tencia'
      OnClick = MovementClick
    end
    object Velocidad1: TMenuItem
      Tag = 4
      Caption = '&Velocidad'
      OnClick = MovementClick
    end
    object AnchoEspectral1: TMenuItem
      Tag = 16
      Caption = '&Ancho Espectral'
      OnClick = MovementClick
    end
    object N4: TMenuItem
      Caption = '-'
    end
    object ZDR1: TMenuItem
      Tag = 9
      Caption = '&ZDR'
      OnClick = MovementClick
    end
    object PhiDP1: TMenuItem
      Tag = 10
      Caption = 'Ph&iDP'
      OnClick = MovementClick
    end
    object KDP1: TMenuItem
      Tag = 12
      Caption = '&KDP'
      OnClick = MovementClick
    end
    object RhoHV1: TMenuItem
      Tag = 11
      Caption = 'R&hoHV'
      OnClick = MovementClick
    end
    object GCP1: TMenuItem
      Tag = 13
      Caption = '&GCP'
      OnClick = MovementClick
    end
    object TID1: TMenuItem
      Tag = 14
      Caption = '&TID'
      OnClick = MovementClick
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object Salvar2: TMenuItem
      Caption = '&Salvar...'
      SubMenuImages = FShell.ImageList1
      ImageIndex = 1
      OnClick = Salvar2Click
    end
    object Eliminar1: TMenuItem
      Caption = 'Eliminar...'
      OnClick = Eliminar1Click
    end
  end
  object MainMenu1: TMainMenu
    Left = 152
    Top = 22
    object Mostrar1: TMenuItem
      Caption = '&Mostrar'
      GroupIndex = 2
      object Alturas2: TMenuItem
        Caption = '&Maximos'
        OnClick = SuperiorClick
      end
      object Lluvia2: TMenuItem
        Caption = '&Intensidad'
        OnClick = LluviaClick
      end
      object Topes2: TMenuItem
        Caption = '&Topes'
        OnClick = TopesClick
      end
      object Volumen2: TMenuItem
        Caption = '&Volumen'
        OnClick = VolumenClick
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Producto2: TMenuItem
        Caption = '&Producto'
      end
    end
  end
  object PopupMenu3: TPopupMenu
    Left = 248
    Top = 21
    object Predefinido1: TMenuItem
      Caption = '&Crear'
      OnClick = ListView1DblClick
    end
    object Editar1: TMenuItem
      Caption = '&Editar...'
      OnClick = Editar1Click
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '.obs'
    Filter = 'Vesta (*.obs)|*.obs|NetCDF (*.nc)|*.nc|Dato Crudo (*.raw)|*.raw'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofNoReadOnlyReturn, ofEnableSizing]
    Left = 184
    Top = 21
  end
  object SaveDialog2: TSaveDialog
    DefaultExt = '.raw'
    Filter = 'Dato crudo|*.raw'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 216
    Top = 21
  end
end
