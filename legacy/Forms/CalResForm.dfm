object FCalRes: TFCalRes
  Left = 419
  Top = 210
  BorderStyle = bsDialog
  Caption = 'Calcular Resoluci'#243'n tangencial'
  ClientHeight = 107
  ClientWidth = 236
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = Edit1Change
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 236
    Height = 60
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
      Width = 109
      Height = 13
      Caption = 'Ancho del haz [grados]'
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
      Width = 67
      Height = 13
      Caption = 'Distancia [km]'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Edit2: TEdit
      Left = 124
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
      Text = '1.5'
      OnChange = Edit1Change
    end
    object Edit1: TEdit
      Left = 124
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
      Text = '50'
      OnChange = Edit1Change
    end
  end
  object GroupBox3: TGroupBox
    Left = 0
    Top = 60
    Width = 236
    Height = 47
    Align = alClient
    Caption = 'Resultados'
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
      Width = 131
      Height = 13
      Caption = 'Resoluci'#243'n tangencial:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 211
      Top = 19
      Width = 17
      Height = 13
      Caption = 'km'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Edit4: TEdit
      Left = 137
      Top = 17
      Width = 68
      Height = 21
      ReadOnly = True
      TabOrder = 0
      Text = 'Edit4'
    end
  end
end
