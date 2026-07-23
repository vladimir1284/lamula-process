object FCalCon: TFCalCon
  Left = 150
  Top = 121
  BorderStyle = bsDialog
  Caption = 'Conversi'#243'n de unidades'
  ClientHeight = 204
  ClientWidth = 382
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object RadioGroup2: TRadioGroup
    Tag = 5
    Left = 3
    Top = 1
    Width = 178
    Height = 140
    Caption = 'Unidades de Distancia'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemIndex = 0
    Items.Strings = (
      'Kil'#243'metros  [Km]'
      'Millas  [mile]'
      'Millas N'#225'ut.  [nmi]'
      'KiloPie  [kft]'
      'Metro  [m]'
      'Pie  [ft]')
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    OnClick = RadioGroup2Click
  end
  object RadioGroup1: TRadioGroup
    Tag = 6
    Left = 184
    Top = 1
    Width = 196
    Height = 100
    Caption = 'Unidades de Velocidad'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemIndex = 0
    Items.Strings = (
      'Km por hora  [Km/h]'
      'Millas por hora  [mile/h]'
      'Nudos (nmi/h)  [kn]'
      'Metros por seg  [m/s]')
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
    OnClick = RadioGroup1Click
  end
  object RadioGroup4: TRadioGroup
    Tag = 7
    Left = 184
    Top = 101
    Width = 196
    Height = 60
    Hint = 'Convierte de dB a unid. lineales y viceversa'
    Caption = 'Logar'#237'tmico <--> Lineal'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemIndex = 0
    Items.Strings = (
      'Log      [dB]'
      'Lineal')
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    OnClick = RadioGroup4Click
  end
  object RadioGroup3: TRadioGroup
    Tag = 8
    Left = 3
    Top = 141
    Width = 178
    Height = 61
    Hint = 'Convierte de dB a unid. lineales y viceversa'
    Caption = 'Grados <--> Radianes'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemIndex = 0
    Items.Strings = (
      'Grados'
      'Radianes')
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    OnClick = RadioGroup3Click
  end
  object Edit5: TEdit
    Left = 127
    Top = 18
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    Text = '10'
    OnChange = Edit5Change
  end
  object Edit6: TEdit
    Left = 127
    Top = 38
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnChange = Edit6Change
  end
  object Edit7: TEdit
    Left = 127
    Top = 58
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
    OnChange = Edit7Change
  end
  object Edit8: TEdit
    Left = 127
    Top = 78
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 7
    OnChange = Edit8Change
  end
  object Edit1: TEdit
    Left = 326
    Top = 18
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 8
    Text = '10'
    OnChange = Edit1Change
  end
  object Edit2: TEdit
    Left = 326
    Top = 38
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 9
    OnChange = Edit2Change
  end
  object Edit3: TEdit
    Left = 326
    Top = 58
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 10
    OnChange = Edit3Change
  end
  object Edit4: TEdit
    Left = 326
    Top = 78
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 11
    OnChange = Edit4Change
  end
  object Edit13: TEdit
    Left = 326
    Top = 118
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 12
    Text = '10'
    OnChange = Edit13Change
  end
  object Edit14: TEdit
    Left = 326
    Top = 138
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 13
    OnChange = Edit14Change
  end
  object Edit11: TEdit
    Left = 127
    Top = 159
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 14
    Text = '10'
    OnChange = Edit11Change
  end
  object Edit12: TEdit
    Left = 127
    Top = 179
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 15
    OnChange = Edit12Change
  end
  object Edit9: TEdit
    Left = 127
    Top = 98
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 16
    OnChange = Edit9Change
  end
  object Edit10: TEdit
    Left = 127
    Top = 118
    Width = 50
    Height = 18
    AutoSize = False
    Constraints.MaxHeight = 18
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 17
    OnChange = Edit10Change
  end
end
