object FEdit: TFEdit
  Left = 586
  Top = 272
  BorderStyle = bsDialog
  Caption = 'Edit'
  ClientHeight = 248
  ClientWidth = 296
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 136
    Top = 219
    Width = 75
    Height = 24
    Caption = '&Crear'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object Button2: TButton
    Left = 216
    Top = 219
    Width = 75
    Height = 24
    Cancel = True
    Caption = 'Cancelar'
    ModalResult = 2
    TabOrder = 1
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 296
    Height = 214
    ActivePage = TabSheet2
    Align = alTop
    HotTrack = True
    TabOrder = 2
    Visible = False
    object TabSheet1: TTabSheet
      Caption = 'General'
      object Label1: TLabel
        Left = 165
        Top = 15
        Width = 41
        Height = 13
        Caption = '&Variable:'
        ParentShowHint = False
        ShowHint = True
      end
      object Label3: TLabel
        Left = 8
        Top = 97
        Width = 41
        Height = 13
        Caption = '&Formato:'
        FocusControl = StringGrid1
      end
      object StringGrid1: TStringGrid
        Left = 8
        Top = 118
        Width = 272
        Height = 61
        ColCount = 7
        DefaultColWidth = 20
        DefaultRowHeight = 16
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goColSizing, goRowSelect, goThumbTracking]
        TabOrder = 0
        OnSelectCell = StringGrid1SelectCell
      end
      object CheckBox1: TCheckBox
        Left = 217
        Top = 74
        Width = 64
        Height = 17
        Alignment = taLeftJustify
        Caption = '&Recordar'
        TabOrder = 1
      end
      object ComboBox1: TComboBox
        Left = 210
        Top = 11
        Width = 75
        Height = 21
        AutoComplete = False
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 2
      end
      object CheckBox3: TCheckBox
        Left = 5
        Top = 75
        Width = 109
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Suprimir Ecos Fijos'
        TabOrder = 3
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Area'
      object Label13: TLabel
        Left = 215
        Top = 109
        Width = 11
        Height = 13
        Caption = '&H:'
        FocusControl = Edit8
      end
      object Label14: TLabel
        Left = 175
        Top = 109
        Width = 30
        Height = 13
        Caption = 'Celda:'
      end
      object Label11: TLabel
        Left = 20
        Top = 149
        Width = 42
        Height = 13
        Caption = '&Alcance:'
        FocusControl = Edit9
      end
      object Area1: TArea
        Left = 20
        Top = 10
        Width = 130
        Height = 130
        West = 10
        East = 90
        North = 90
        South = 10
        AreaColor = clGray
        MaxWest = 0
        MaxEast = 100
        MaxNorth = 100
        MaxSouth = 0
        Style = asRectangle
        OnChange = Area1Change
      end
      object Edit3: TEdit
        Left = 210
        Top = 7
        Width = 60
        Height = 21
        TabOrder = 1
        Text = '0'
        OnChange = Edit3Change
      end
      object Edit4: TEdit
        Left = 210
        Top = 29
        Width = 60
        Height = 21
        TabOrder = 2
        Text = '0'
        OnChange = Edit4Change
      end
      object Edit5: TEdit
        Left = 210
        Top = 52
        Width = 60
        Height = 21
        TabOrder = 3
        Text = '0'
        OnChange = Edit5Change
      end
      object Edit6: TEdit
        Left = 210
        Top = 75
        Width = 60
        Height = 21
        TabOrder = 4
        Text = '0'
        OnChange = Edit6Change
      end
      object UpDown4: TUpDown
        Left = 270
        Top = 6
        Width = 12
        Height = 21
        Associate = Edit3
        Max = 0
        TabOrder = 5
        OnClick = UpDown4Click
      end
      object UpDown5: TUpDown
        Left = 270
        Top = 28
        Width = 12
        Height = 21
        Associate = Edit4
        Max = 0
        TabOrder = 6
        OnClick = UpDown5Click
      end
      object UpDown6: TUpDown
        Left = 270
        Top = 51
        Width = 12
        Height = 21
        Associate = Edit5
        Max = 0
        TabOrder = 7
        OnClick = UpDown6Click
      end
      object UpDown7: TUpDown
        Left = 270
        Top = 74
        Width = 12
        Height = 21
        Associate = Edit6
        Max = 0
        TabOrder = 8
        OnClick = UpDown7Click
      end
      object CheckBox2: TCheckBox
        Left = 210
        Top = 147
        Width = 70
        Height = 17
        Alignment = taLeftJustify
        Caption = '&Recordar'
        TabOrder = 9
      end
      object Edit8: TEdit
        Left = 230
        Top = 105
        Width = 40
        Height = 21
        TabOrder = 10
        Text = '1000'
      end
      object UpDown8: TUpDown
        Left = 270
        Top = 104
        Width = 12
        Height = 21
        Associate = Edit8
        Min = 100
        Max = 10000
        Increment = 100
        Position = 1000
        TabOrder = 11
        Thousands = False
      end
      object Edit9: TEdit
        Left = 75
        Top = 145
        Width = 60
        Height = 21
        TabOrder = 12
        Text = '10'
      end
      object UpDown1: TUpDown
        Left = 135
        Top = 145
        Width = 12
        Height = 21
        Associate = Edit9
        Min = 10
        Max = 1000
        Increment = 10
        Position = 10
        TabOrder = 13
      end
    end
  end
end
