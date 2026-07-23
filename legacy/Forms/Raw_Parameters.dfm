object FRaw_Parameters: TFRaw_Parameters
  Left = 401
  Top = 238
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Parametros'
  ClientHeight = 288
  ClientWidth = 246
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 247
    Width = 246
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      246
      41)
    object Button1: TButton
      Left = 96
      Top = 9
      Width = 70
      Height = 22
      Anchors = [akTop, akRight]
      Caption = '&Aceptar'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 166
      Top = 9
      Width = 70
      Height = 22
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = '&Cancelar'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 246
    Height = 247
    ActivePage = TabSheet3
    Align = alClient
    HotTrack = True
    MultiLine = True
    TabOrder = 1
    object TabSheet1: TTabSheet
      Caption = 'General'
      object Label1: TLabel
        Left = 10
        Top = 19
        Width = 32
        Height = 13
        Caption = '&Radar:'
        FocusControl = ComboBox1
      end
      object Label5: TLabel
        Left = 120
        Top = 60
        Width = 35
        Height = 13
        Caption = '# &PPIs:'
        FocusControl = Edit2
      end
      object Label6: TLabel
        Left = 10
        Top = 90
        Width = 41
        Height = 13
        Caption = '&Angulos:'
        FocusControl = Edit3
      end
      object Label7: TLabel
        Left = 10
        Top = 130
        Width = 35
        Height = 13
        Caption = '&Celdas:'
        FocusControl = Edit4
      end
      object Label8: TLabel
        Left = 115
        Top = 130
        Width = 42
        Height = 13
        Caption = '&Tama'#241'o:'
        FocusControl = Edit5
      end
      object Label9: TLabel
        Left = 10
        Top = 155
        Width = 45
        Height = 13
        Caption = '&Sectores:'
        FocusControl = Edit6
      end
      object Label10: TLabel
        Left = 115
        Top = 155
        Width = 22
        Height = 13
        Caption = '&Haz:'
        FocusControl = Edit7
      end
      object Label11: TLabel
        Left = 115
        Top = 190
        Width = 47
        Height = 13
        Caption = '&Potencial:'
        FocusControl = Edit8
      end
      object Label12: TLabel
        Left = 210
        Top = 130
        Width = 14
        Height = 13
        Caption = '[m]'
      end
      object Label13: TLabel
        Left = 210
        Top = 155
        Width = 10
        Height = 13
        Caption = '['#176']'
      end
      object Label14: TLabel
        Left = 210
        Top = 190
        Width = 19
        Height = 13
        Caption = '[dB]'
      end
      object Label2: TLabel
        Left = 10
        Top = 60
        Width = 35
        Height = 13
        Caption = '&Lamda:'
        FocusControl = Edit4
      end
      object ComboBox1: TComboBox
        Left = 55
        Top = 15
        Width = 171
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        ItemIndex = 8
        TabOrder = 0
        Text = 'McGill'
        Items.Strings = (
          '(Ninguno)'
          'La Bajada'
          'Punta del Este'
          'Casablanca'
          'Pico San Juan'
          'Camaguey'
          'Pilon'
          'Gran Piedra'
          'McGill'
          'Roma')
      end
      object Edit2: TEdit
        Left = 160
        Top = 56
        Width = 50
        Height = 21
        TabOrder = 2
        Text = '24'
      end
      object Edit3: TEdit
        Left = 55
        Top = 86
        Width = 171
        Height = 21
        TabOrder = 4
        Text = 
          '0.5, 0.6, 0.7, 0.9, 1.1, 1.4, 1.8, 2.2, 2.7, 3.4, 4.1, 4.9, 5.9,' +
          ' 7.1, 8.6, 10.3, 12.3, 14.6, 17.2, 20.3, 24, 28, 32, 34'
      end
      object Edit4: TEdit
        Left = 60
        Top = 126
        Width = 40
        Height = 21
        TabOrder = 5
        Text = '120'
      end
      object Edit5: TEdit
        Left = 165
        Top = 126
        Width = 40
        Height = 21
        TabOrder = 7
        Text = '1000'
      end
      object Edit6: TEdit
        Left = 60
        Top = 151
        Width = 40
        Height = 21
        TabOrder = 6
        Text = '360'
      end
      object Edit7: TEdit
        Left = 165
        Top = 151
        Width = 40
        Height = 21
        TabOrder = 8
        Text = '0.86'
      end
      object Edit8: TEdit
        Left = 165
        Top = 186
        Width = 40
        Height = 21
        TabOrder = 9
        Text = '0.0'
      end
      object UpDown1: TUpDown
        Left = 210
        Top = 56
        Width = 15
        Height = 21
        Associate = Edit2
        Min = 1
        Position = 24
        TabOrder = 3
        Thousands = False
      end
      object ComboBox2: TComboBox
        Left = 55
        Top = 55
        Width = 56
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        ItemIndex = 1
        TabOrder = 1
        Text = '10 cm'
        Items.Strings = (
          '3 cm'
          '10 cm')
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Unidad'
      ImageIndex = 2
      object Label17: TLabel
        Left = 10
        Top = 19
        Width = 41
        Height = 13
        Caption = '&Variable:'
      end
      object Label3: TLabel
        Left = 5
        Top = 84
        Width = 51
        Height = 13
        Caption = '&Pendiente:'
        FocusControl = Edit1
      end
      object Label4: TLabel
        Left = 5
        Top = 114
        Width = 55
        Height = 13
        Caption = '&Corrimiento:'
        FocusControl = Edit9
      end
      object ComboBox6: TComboBox
        Left = 55
        Top = 15
        Width = 171
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 0
      end
      object Edit1: TEdit
        Left = 70
        Top = 80
        Width = 150
        Height = 21
        TabOrder = 2
        Text = '1.0'
      end
      object Edit9: TEdit
        Left = 70
        Top = 110
        Width = 150
        Height = 21
        TabOrder = 3
        Text = '0.0'
      end
      object CheckBox1: TCheckBox
        Left = 140
        Top = 45
        Width = 86
        Height = 17
        BiDiMode = bdLeftToRight
        Caption = '&Codigo Vesta'
        ParentBiDiMode = False
        TabOrder = 1
        OnClick = CheckBox1Click
      end
      object CheckBox2: TCheckBox
        Left = 90
        Top = 145
        Width = 130
        Height = 17
        Alignment = taLeftJustify
        BiDiMode = bdLeftToRight
        Caption = 'Aplicar correccion &R^2'
        ParentBiDiMode = False
        TabOrder = 4
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Fecha'
      ImageIndex = 1
      object MonthCalendar1: TMonthCalendar
        Left = 20
        Top = 25
        Width = 190
        Height = 136
        Date = 37098.467484444450000000
        ShowToday = False
        ShowTodayCircle = False
        TabOrder = 0
      end
      object DateTimePicker1: TDateTimePicker
        Left = 120
        Top = 185
        Width = 91
        Height = 21
        Date = 37098.605371388900000000
        Time = 37098.605371388900000000
        Kind = dtkTime
        TabOrder = 1
      end
    end
  end
end
