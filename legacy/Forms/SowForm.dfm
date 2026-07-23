object FSow: TFSow
  Left = 242
  Top = 143
  BorderStyle = bsDialog
  Caption = 'Siembra'
  ClientHeight = 271
  ClientWidth = 391
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 391
    Height = 121
    Align = alTop
    Caption = 'Punto de siembra'
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 32
      Width = 32
      Height = 13
      Caption = 'Latitud'
    end
    object Label2: TLabel
      Left = 208
      Top = 32
      Width = 41
      Height = 13
      Caption = 'Longitud'
    end
    object Label3: TLabel
      Left = 16
      Top = 56
      Width = 51
      Height = 13
      Caption = 'Radio (km)'
    end
    object Label4: TLabel
      Left = 224
      Top = 64
      Width = 24
      Height = 13
      Caption = 'Color'
    end
    object Edit1: TEdit
      Left = 72
      Top = 28
      Width = 121
      Height = 21
      TabOrder = 0
    end
    object Edit2: TEdit
      Left = 256
      Top = 32
      Width = 121
      Height = 21
      TabOrder = 1
    end
    object Edit3: TEdit
      Left = 72
      Top = 56
      Width = 121
      Height = 21
      TabOrder = 2
    end
    object ColorBox1: TColorBox
      Left = 256
      Top = 56
      Width = 121
      Height = 22
      Style = [cbStandardColors, cbExtendedColors, cbPrettyNames]
      ItemHeight = 16
      TabOrder = 3
    end
    object Button1: TButton
      Left = 16
      Top = 88
      Width = 75
      Height = 25
      Caption = 'Agregar'
      TabOrder = 4
      OnClick = Button1Click
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 121
    Width = 391
    Height = 150
    Align = alClient
    Caption = 'Base de datos'
    TabOrder = 1
    object Label5: TLabel
      Left = 8
      Top = 16
      Width = 36
      Height = 13
      Caption = 'Archivo'
    end
    object SpeedButton1: TSpeedButton
      Left = 184
      Top = 16
      Width = 23
      Height = 22
    end
    object Edit4: TEdit
      Left = 56
      Top = 16
      Width = 121
      Height = 21
      TabOrder = 0
      Text = 'Edit4'
    end
    object ListView1: TListView
      Left = 2
      Top = 43
      Width = 387
      Height = 105
      Align = alBottom
      Checkboxes = True
      Columns = <
        item
          Caption = 'Fecha'
        end
        item
          Caption = 'Latitud'
        end
        item
          Caption = 'Longitud'
        end
        item
          Caption = 'Radio'
        end
        item
          Caption = 'Color'
        end>
      GridLines = True
      RowSelect = True
      TabOrder = 1
      ViewStyle = vsReport
    end
  end
end
