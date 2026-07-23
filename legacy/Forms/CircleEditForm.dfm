inherited FCircleEdit: TFCircleEdit
  Left = 308
  Top = 144
  Caption = 'C'#237'rculo'
  ClientHeight = 341
  ClientWidth = 239
  PixelsPerInch = 96
  TextHeight = 13
  object Label6: TLabel [0]
    Left = 10
    Top = 62
    Width = 24
    Height = 13
    Caption = 'Filas:'
  end
  object Label7: TLabel [1]
    Left = 164
    Top = 63
    Width = 14
    Height = 13
    Caption = 'km'
  end
  object Label8: TLabel [2]
    Left = 12
    Top = 90
    Width = 24
    Height = 13
    Caption = 'Filas:'
  end
  object Label9: TLabel [3]
    Left = 166
    Top = 91
    Width = 14
    Height = 13
    Caption = 'km'
  end
  inherited Button1: TButton
    Left = 162
    Top = 313
  end
  inherited Button2: TButton
    Left = 84
    Top = 313
  end
  inherited Panel1: TPanel
    Width = 239
    Height = 310
    inherited Label2: TLabel
      Left = 146
      Top = 126
    end
    inherited Label3: TLabel [1]
      Left = 146
      Top = 153
    end
    inherited Label5: TLabel [2]
      Top = 154
      Width = 10
      Caption = 'Y:'
    end
    inherited Label4: TLabel [3]
      Top = 128
      Width = 10
      Caption = 'X:'
    end
    object Label10: TLabel [4]
      Left = 11
      Top = 201
      Width = 31
      Height = 13
      Caption = 'Radio:'
    end
    object Label11: TLabel [5]
      Left = 146
      Top = 200
      Width = 14
      Height = 13
      Caption = 'km'
    end
    object Label12: TLabel [6]
      Left = 10
      Top = 12
      Width = 37
      Height = 13
      Caption = 'C'#237'rculo:'
    end
    inherited Label1: TLabel [7]
      Left = 11
      Top = 68
    end
    object GroupBox1: TGroupBox [8]
      Left = 7
      Top = 69
      Width = 225
      Height = 122
      Caption = 'Coordenadas'
      TabOrder = 12
      object Label13: TLabel
        Left = 22
        Top = 67
        Width = 10
        Height = 13
        Caption = 'X:'
      end
      object Label14: TLabel
        Left = 21
        Top = 95
        Width = 10
        Height = 13
        Caption = 'Y:'
      end
      object CheckBox6: TCheckBox
        Left = 8
        Top = 16
        Width = 186
        Height = 17
        Caption = 'Uitlizar coordenadas de otro c'#237'rculo.'
        TabOrder = 0
        OnClick = CheckBox6Click
      end
      object ComboBox2: TComboBox
        Left = 7
        Top = 36
        Width = 212
        Height = 21
        ItemHeight = 13
        ItemIndex = 0
        TabOrder = 1
        Text = 'C'#237'rculo 1'
        OnChange = ComboBox1Change
        OnDropDown = ComboBox1DropDown
        Items.Strings = (
          'C'#237'rculo 1'
          'C'#237'rculo 2'
          'C'#237'rculo 3'
          'C'#237'rculo 4'
          'C'#237'rculo 5'
          'C'#237'rculo 6'
          'C'#237'rculo 7'
          'C'#237'rculo 8'
          'C'#237'rculo 9'
          'C'#237'rculo 10')
      end
    end
    inherited CheckBox1: TCheckBox [9]
      Left = 153
      Top = 164
      Width = 68
      Checked = False
      State = cbUnchecked
      Visible = False
    end
    inherited Panel2: TPanel [10]
      Left = 190
      Top = 39
      Width = 42
      Height = 30
    end
    inherited UpDown1: TUpDown [11]
      Left = 124
      Top = 133
      Min = -1000
      Increment = 1
    end
    inherited UpDown2: TUpDown [12]
      Left = 124
      Top = 160
      Enabled = True
      Min = -1000
      Increment = 1
    end
    inherited Edit1: TEdit
      Left = 49
      Top = 133
    end
    inherited Edit2: TEdit
      Left = 49
      Top = 160
      Enabled = True
    end
    object AllCircles: TCheckBox
      Left = 9
      Top = 287
      Width = 200
      Height = 17
      Caption = 'Actualizar todos los productos.'
      Checked = True
      State = cbChecked
      TabOrder = 6
    end
    object CheckBox2: TCheckBox
      Left = 9
      Top = 224
      Width = 200
      Height = 17
      Caption = 'Mostrar centro del c'#237'rculo'
      Checked = True
      State = cbChecked
      TabOrder = 7
    end
    object ComboBox1: TComboBox
      Left = 54
      Top = 9
      Width = 179
      Height = 21
      ItemHeight = 13
      ItemIndex = 0
      TabOrder = 8
      Text = 'C'#237'rculo 1'
      OnChange = ComboBox1Change
      OnDropDown = ComboBox1DropDown
      Items.Strings = (
        'C'#237'rculo 1'
        'C'#237'rculo 2'
        'C'#237'rculo 3'
        'C'#237'rculo 4'
        'C'#237'rculo 5'
        'C'#237'rculo 6'
        'C'#237'rculo 7'
        'C'#237'rculo 8'
        'C'#237'rculo 9'
        'C'#237'rculo 10')
    end
    object CheckBox3: TCheckBox
      Left = 11
      Top = 45
      Width = 97
      Height = 17
      Caption = 'Mostrar'
      TabOrder = 9
    end
    object CheckBox4: TCheckBox
      Left = 9
      Top = 266
      Width = 200
      Height = 17
      Caption = 'Mostrar n'#250'mero del c'#237'rculo'
      Checked = True
      State = cbChecked
      TabOrder = 10
    end
    object CheckBox5: TCheckBox
      Left = 9
      Top = 242
      Width = 200
      Height = 23
      Caption = 'Mostrar radio del c'#237'rculo'
      Checked = True
      State = cbChecked
      TabOrder = 11
    end
  end
  object Edit3: TEdit [7]
    Left = 49
    Top = 197
    Width = 75
    Height = 21
    AutoSize = False
    MaxLength = 4
    TabOrder = 3
    Text = '25'
  end
  object UpDown3: TUpDown [8]
    Left = 124
    Top = 197
    Width = 16
    Height = 21
    Associate = Edit3
    Min = 1
    Max = 1000
    Position = 25
    TabOrder = 4
  end
  inherited ColorDialog1: TColorDialog
    Left = 202
    Top = 208
  end
end
