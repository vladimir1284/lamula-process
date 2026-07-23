object FConfiguration: TFConfiguration
  Left = 268
  Top = 167
  BorderIcons = [biSystemMenu, biHelp]
  BorderStyle = bsDialog
  Caption = 'Configuraci'#243'n'
  ClientHeight = 262
  ClientWidth = 312
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Button3: TButton
    Left = 3
    Top = 234
    Width = 75
    Height = 25
    Caption = 'Configurar'
    Default = True
    TabOrder = 0
    OnClick = Button3Click
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 312
    Height = 231
    ActivePage = TabSheet6
    Align = alTop
    HotTrack = True
    TabOrder = 1
    object TabSheet1: TTabSheet
      Caption = 'Ecuaciones'
      object GroupBox1: TGroupBox
        Left = 10
        Top = 10
        Width = 140
        Height = 105
        Caption = 'Z-R'
        TabOrder = 0
        object Label1: TLabel
          Left = 10
          Top = 47
          Width = 9
          Height = 13
          Caption = '&a:'
          FocusControl = Edit1
        end
        object Label2: TLabel
          Left = 10
          Top = 72
          Width = 9
          Height = 13
          Caption = '&b:'
          FocusControl = Edit2
        end
        object Label4: TLabel
          Left = 10
          Top = 25
          Width = 48
          Height = 13
          Caption = 'Ecuacion:'
        end
        object Label6: TLabel
          Left = 65
          Top = 25
          Width = 43
          Height = 13
          Caption = 'Z = a * R'
        end
        object Label3: TLabel
          Left = 110
          Top = 15
          Width = 6
          Height = 13
          Caption = 'b'
        end
        object Edit1: TEdit
          Left = 25
          Top = 45
          Width = 100
          Height = 21
          TabOrder = 0
          Text = '300.0'
        end
        object Edit2: TEdit
          Left = 25
          Top = 70
          Width = 100
          Height = 21
          TabOrder = 1
          Text = '1.4'
        end
      end
      object GroupBox3: TGroupBox
        Left = 160
        Top = 10
        Width = 140
        Height = 105
        Caption = 'R-Kdp'
        TabOrder = 1
        object Label5: TLabel
          Left = 10
          Top = 47
          Width = 9
          Height = 13
          Caption = '&c:'
          FocusControl = Edit3
        end
        object Label7: TLabel
          Left = 10
          Top = 72
          Width = 9
          Height = 13
          Caption = '&d:'
          FocusControl = Edit4
        end
        object Label8: TLabel
          Left = 10
          Top = 25
          Width = 48
          Height = 13
          Caption = 'Ecuacion:'
        end
        object Label9: TLabel
          Left = 65
          Top = 25
          Width = 55
          Height = 13
          Caption = 'R = c * Kdp'
        end
        object Label10: TLabel
          Left = 120
          Top = 15
          Width = 6
          Height = 13
          Caption = 'd'
        end
        object Edit3: TEdit
          Left = 25
          Top = 45
          Width = 100
          Height = 21
          TabOrder = 0
          Text = '300.0'
        end
        object Edit4: TEdit
          Left = 25
          Top = 70
          Width = 100
          Height = 21
          TabOrder = 1
          Text = '1.4'
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Caminos'
      ImageIndex = 2
      object Label11: TLabel
        Tag = 2
        Left = 10
        Top = 119
        Width = 47
        Height = 13
        Caption = '&Fronteras:'
        FocusControl = Edit11
      end
      object Label12: TLabel
        Tag = 3
        Left = 10
        Top = 149
        Width = 48
        Height = 13
        Caption = '&Regiones:'
        FocusControl = Edit12
      end
      object Label13: TLabel
        Tag = 3
        Left = 10
        Top = 179
        Width = 35
        Height = 13
        Caption = '&Mapas:'
        FocusControl = Edit13
      end
      object Edit11: TEdit
        Tag = 2
        Left = 75
        Top = 115
        Width = 215
        Height = 21
        TabOrder = 0
      end
      object Edit12: TEdit
        Tag = 3
        Left = 75
        Top = 145
        Width = 215
        Height = 21
        TabOrder = 1
      end
      object Edit13: TEdit
        Tag = 3
        Left = 75
        Top = 175
        Width = 215
        Height = 21
        TabOrder = 2
      end
    end
    object TabSheet6: TTabSheet
      Caption = 'Asociacion'
      object Label19: TLabel
        Left = 15
        Top = 170
        Width = 36
        Height = 13
        Caption = 'Accion:'
      end
      object GroupBox2: TGroupBox
        Left = 10
        Top = 10
        Width = 281
        Height = 146
        Caption = 'Archivos asociados:'
        TabOrder = 0
        object CheckBox1: TCheckBox
          Left = 15
          Top = 20
          Width = 97
          Height = 17
          Caption = '&Periodos'
          Checked = True
          State = cbChecked
          TabOrder = 0
        end
        object CheckBox2: TCheckBox
          Left = 15
          Top = 68
          Width = 97
          Height = 17
          Caption = '&Observaciones'
          Checked = True
          State = cbChecked
          TabOrder = 1
        end
        object CheckBox3: TCheckBox
          Left = 15
          Top = 91
          Width = 97
          Height = 17
          Caption = 'Pro&ductos'
          Checked = True
          State = cbChecked
          TabOrder = 2
        end
        object CheckBox4: TCheckBox
          Left = 15
          Top = 115
          Width = 97
          Height = 17
          Caption = '&Animaciones'
          Checked = True
          State = cbChecked
          TabOrder = 3
        end
        object Edit5: TEdit
          Left = 115
          Top = 20
          Width = 150
          Height = 21
          TabOrder = 4
        end
        object Edit6: TEdit
          Left = 115
          Top = 68
          Width = 150
          Height = 21
          TabOrder = 5
        end
        object Edit7: TEdit
          Left = 115
          Top = 91
          Width = 150
          Height = 21
          TabOrder = 6
        end
        object Edit8: TEdit
          Left = 115
          Top = 115
          Width = 150
          Height = 21
          TabOrder = 7
        end
        object Edit9: TEdit
          Left = 115
          Top = 44
          Width = 150
          Height = 21
          TabOrder = 8
        end
        object CheckBox5: TCheckBox
          Left = 15
          Top = 44
          Width = 97
          Height = 17
          Caption = '&Conjuntos'
          Checked = True
          State = cbChecked
          TabOrder = 9
        end
      end
      object Edit10: TEdit
        Left = 65
        Top = 170
        Width = 226
        Height = 21
        TabOrder = 1
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Speckler'
      ImageIndex = 3
      object Label14: TLabel
        Left = 14
        Top = 20
        Width = 131
        Height = 13
        Caption = 'Eliminar Speckler Radial (m)'
      end
      object Edit14: TEdit
        Left = 151
        Top = 17
        Width = 121
        Height = 21
        TabOrder = 0
        Text = '0'
      end
      object UpDown1: TUpDown
        Left = 272
        Top = 17
        Width = 16
        Height = 21
        Associate = Edit14
        Max = 32762
        TabOrder = 1
      end
    end
  end
  object Button2: TButton
    Left = 155
    Top = 234
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancelar'
    ModalResult = 2
    TabOrder = 2
  end
  object Button1: TButton
    Left = 234
    Top = 234
    Width = 75
    Height = 25
    Caption = '&Cerrar'
    ModalResult = 1
    TabOrder = 3
    OnClick = Button3Click
  end
end
