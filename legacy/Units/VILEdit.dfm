inherited FVilEdit: TFVilEdit
  Caption = 'VIL'
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl1: TPageControl
    ActivePage = TabSheet1
    inherited TabSheet1: TTabSheet
      inherited Label1: TLabel
        Left = 70
        Top = 75
        Visible = False
      end
      object Label16: TLabel [6]
        Left = 195
        Top = 15
        Width = 16
        Height = 13
        Caption = 'C1:'
      end
      object Label17: TLabel [7]
        Left = 195
        Top = 45
        Width = 16
        Height = 13
        Caption = 'C2:'
      end
      inherited ComboBox1: TComboBox
        Visible = False
      end
      inherited CheckBox3: TCheckBox
        TabOrder = 9
      end
      inherited UpDown11: TUpDown
        Top = 41
      end
      object Edit7: TEdit
        Left = 220
        Top = 11
        Width = 60
        Height = 21
        TabOrder = 7
        Text = '0.00524'
      end
      object Edit10: TEdit
        Left = 220
        Top = 41
        Width = 60
        Height = 21
        TabOrder = 8
        Text = '0.57143'
      end
    end
    inherited TabSheet2: TTabSheet
      inherited UpDown4: TUpDown
        Top = 7
      end
      inherited UpDown5: TUpDown
        Top = 29
      end
      inherited UpDown6: TUpDown
        Top = 52
      end
      inherited UpDown7: TUpDown
        Top = 75
      end
      inherited UpDown8: TUpDown
        Top = 102
      end
    end
  end
end
