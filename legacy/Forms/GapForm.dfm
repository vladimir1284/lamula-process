object FGapColor: TFGapColor
  Left = 464
  Top = 191
  BorderStyle = bsDialog
  ClientHeight = 148
  ClientWidth = 250
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 173
    Top = 120
    Width = 75
    Height = 25
    Caption = '&Aceptar'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object Button2: TButton
    Left = 95
    Top = 120
    Width = 75
    Height = 25
    Cancel = True
    Caption = '&Cancelar'
    ModalResult = 2
    TabOrder = 1
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 250
    Height = 116
    Align = alTop
    TabOrder = 2
    object Label2: TLabel
      Left = 164
      Top = 36
      Width = 14
      Height = 13
      Caption = 'km'
    end
    object Label1: TLabel
      Left = 10
      Top = 10
      Width = 38
      Height = 13
      Caption = 'Valores:'
    end
    object Label3: TLabel
      Left = 164
      Top = 63
      Width = 14
      Height = 13
      Caption = 'km'
    end
    object Label5: TLabel
      Left = 10
      Top = 62
      Width = 24
      Height = 13
      Caption = 'Filas:'
    end
    object Label4: TLabel
      Left = 10
      Top = 36
      Width = 49
      Height = 13
      Caption = 'Columnas:'
    end
    object Panel2: TPanel
      Left = 197
      Top = 35
      Width = 41
      Height = 41
      BorderStyle = bsSingle
      Caption = 'Color'
      Color = clSilver
      TabOrder = 0
      OnClick = Panel2Click
    end
    object UpDown1: TUpDown
      Left = 139
      Top = 33
      Width = 16
      Height = 21
      Associate = Edit1
      Max = 1000
      Increment = 10
      Position = 60
      TabOrder = 1
    end
    object UpDown2: TUpDown
      Left = 139
      Top = 60
      Width = 16
      Height = 21
      Associate = Edit2
      Enabled = False
      Max = 1000
      Increment = 10
      Position = 60
      TabOrder = 2
    end
    object CheckBox1: TCheckBox
      Left = 13
      Top = 90
      Width = 97
      Height = 17
      Caption = 'Simetria'
      Checked = True
      State = cbChecked
      TabOrder = 3
      OnClick = CheckBox1Click
    end
    object Edit1: TEdit
      Left = 64
      Top = 33
      Width = 75
      Height = 21
      AutoSize = False
      MaxLength = 4
      TabOrder = 4
      Text = '60'
      OnChange = Edit1Change
    end
    object Edit2: TEdit
      Left = 64
      Top = 60
      Width = 75
      Height = 21
      AutoSize = False
      Enabled = False
      MaxLength = 4
      TabOrder = 5
      Text = '60'
    end
  end
  object ColorDialog1: TColorDialog
    Color = clWhite
    Left = 2
    Top = 118
  end
end
