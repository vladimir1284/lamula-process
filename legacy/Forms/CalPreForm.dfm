object FCalPre: TFCalPre
  Left = 236
  Top = 187
  BorderStyle = bsDialog
  Caption = 'Calcular precipitaci'#243'n'
  ClientHeight = 127
  ClientWidth = 279
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 279
    Height = 80
    Align = alTop
    Caption = 'Datos'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object Label2: TLabel
      Left = 6
      Top = 37
      Width = 63
      Height = 13
      Caption = 'Coeficiente A'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label3: TLabel
      Left = 6
      Top = 56
      Width = 63
      Height = 13
      Caption = 'Coeficiente B'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label1: TLabel
      Left = 6
      Top = 17
      Width = 91
      Height = 13
      Caption = 'Reflectividad [dBZ]'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Edit2: TEdit
      Left = 102
      Top = 35
      Width = 45
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Text = '10'
      OnChange = Edit1Change
    end
    object Edit3: TEdit
      Left = 102
      Top = 55
      Width = 45
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      Text = '10'
      OnChange = Edit1Change
    end
    object Edit1: TEdit
      Left = 102
      Top = 15
      Width = 45
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      Text = '20'
      OnChange = Edit1Change
    end
  end
  object GroupBox3: TGroupBox
    Left = 0
    Top = 80
    Width = 279
    Height = 47
    Align = alClient
    Caption = 'Resultado'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object Label4: TLabel
      Left = 5
      Top = 20
      Width = 159
      Height = 13
      Caption = 'Intensidad de precipitaci'#243'n:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 240
      Top = 19
      Width = 32
      Height = 13
      Caption = 'mm/h'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Edit4: TEdit
      Left = 166
      Top = 17
      Width = 68
      Height = 21
      ReadOnly = True
      TabOrder = 0
      Text = 'Edit4'
    end
  end
end
