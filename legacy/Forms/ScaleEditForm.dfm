object FScaleEdit: TFScaleEdit
  Left = 251
  Top = 224
  BorderStyle = bsDialog
  Caption = 'Editar escala'
  ClientHeight = 105
  ClientWidth = 210
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 10
    Top = 20
    Width = 31
    Height = 13
    Caption = '&Titulo:'
    FocusControl = Edit1
  end
  object Label2: TLabel
    Left = 10
    Top = 50
    Width = 27
    Height = 13
    Caption = '&Valor:'
    FocusControl = Edit2
  end
  object Button1: TButton
    Left = 50
    Top = 80
    Width = 70
    Height = 20
    Caption = '&Aceptar'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object Button2: TButton
    Left = 130
    Top = 80
    Width = 70
    Height = 20
    Cancel = True
    Caption = '&Cancelar'
    ModalResult = 2
    TabOrder = 1
  end
  object Panel1: TPanel
    Left = 140
    Top = 45
    Width = 60
    Height = 22
    Caption = '&Color'
    TabOrder = 2
    OnClick = Panel1Click
  end
  object Edit1: TEdit
    Left = 50
    Top = 15
    Width = 150
    Height = 21
    TabOrder = 3
  end
  object Edit2: TEdit
    Left = 50
    Top = 45
    Width = 60
    Height = 21
    ReadOnly = True
    TabOrder = 4
    Text = '0'
    OnChange = Edit2Change
  end
  object UpDown1: TUpDown
    Left = 110
    Top = 45
    Width = 15
    Height = 21
    Associate = Edit2
    Min = 0
    Max = 255
    Position = 0
    TabOrder = 5
    Thousands = False
    Wrap = False
  end
  object ColorDialog1: TColorDialog
    Ctl3D = True
    Left = 5
    Top = 70
  end
end
