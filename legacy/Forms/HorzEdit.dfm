inherited FHorzEdit: TFHorzEdit
  Left = 387
  Top = 201
  Caption = 'Horizontal'
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl1: TPageControl
    Visible = True
    inherited TabSheet1: TTabSheet
      inherited Label3: TLabel
        Left = 10
      end
      object Label4: TLabel [2]
        Left = 10
        Top = 44
        Width = 42
        Height = 13
        Caption = '&Superior:'
      end
      object Label5: TLabel [3]
        Left = 10
        Top = 15
        Width = 35
        Height = 13
        Caption = '&Inferior:'
      end
      object Label6: TLabel [4]
        Left = 140
        Top = 15
        Width = 8
        Height = 13
        Caption = 'm'
      end
      object Label15: TLabel [5]
        Left = 140
        Top = 43
        Width = 8
        Height = 13
        Caption = 'm'
      end
      inherited CheckBox1: TCheckBox
        TabOrder = 6
      end
      inherited ComboBox1: TComboBox
        TabOrder = 5
      end
      inherited CheckBox3: TCheckBox
        Left = 8
        Top = 71
        TabOrder = 7
      end
      object Edit1: TEdit
        Left = 60
        Top = 11
        Width = 60
        Height = 21
        TabOrder = 1
        Text = '0'
      end
      object UpDown10: TUpDown
        Left = 120
        Top = 11
        Width = 16
        Height = 21
        Associate = Edit1
        Max = 20000
        Increment = 100
        TabOrder = 2
        Thousands = False
        OnClick = UpDown10Click
      end
      object Edit2: TEdit
        Left = 60
        Top = 41
        Width = 60
        Height = 21
        TabOrder = 3
        Text = '0'
      end
      object UpDown11: TUpDown
        Left = 120
        Top = 40
        Width = 16
        Height = 21
        Associate = Edit2
        Max = 20000
        Increment = 100
        TabOrder = 4
        Thousands = False
        OnClick = UpDown11Click
      end
    end
    inherited TabSheet2: TTabSheet
      object Label7: TLabel [0]
        Left = 175
        Top = 12
        Width = 24
        Height = 13
        Caption = '&Este:'
        FocusControl = Edit3
      end
      object Label9: TLabel [1]
        Left = 175
        Top = 34
        Width = 31
        Height = 13
        Caption = '&Oeste:'
        FocusControl = Edit4
      end
      object Label8: TLabel [2]
        Left = 175
        Top = 56
        Width = 29
        Height = 13
        Caption = '&Norte:'
        FocusControl = Edit5
      end
      object Label10: TLabel [3]
        Left = 175
        Top = 79
        Width = 19
        Height = 13
        Caption = '&Sur:'
        FocusControl = Edit6
      end
      inherited Label13: TLabel
        Top = 106
      end
      inherited Label14: TLabel
        Top = 106
      end
      inherited Edit4: TEdit
        TabOrder = 3
      end
      inherited Edit5: TEdit
        TabOrder = 5
      end
      inherited Edit6: TEdit
        TabOrder = 7
      end
      inherited UpDown4: TUpDown
        TabOrder = 2
      end
      inherited UpDown5: TUpDown
        TabOrder = 4
      end
      inherited UpDown6: TUpDown
        TabOrder = 6
      end
      inherited Edit8: TEdit
        Top = 102
      end
      inherited UpDown8: TUpDown
        Top = 101
      end
    end
  end
end
