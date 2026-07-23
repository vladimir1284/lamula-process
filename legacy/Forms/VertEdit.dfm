inherited FVertEdit: TFVertEdit
  Left = 482
  Top = 209
  Caption = 'Vertical'
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl1: TPageControl
    inherited TabSheet2: TTabSheet
      object Label16: TLabel [5]
        Left = 215
        Top = 129
        Width = 10
        Height = 13
        Caption = '&V:'
        FocusControl = Edit7
      end
      inherited Label14: TLabel
        Top = 120
      end
      inherited Edit3: TEdit
        TabOrder = 3
      end
      inherited Edit4: TEdit
        TabOrder = 5
      end
      inherited Edit5: TEdit
        TabOrder = 7
      end
      inherited Edit6: TEdit
        TabOrder = 9
      end
      inherited UpDown4: TUpDown
        Top = 7
        TabOrder = 4
      end
      inherited UpDown5: TUpDown
        Top = 29
        TabOrder = 6
      end
      inherited UpDown6: TUpDown
        Top = 52
        TabOrder = 8
      end
      inherited UpDown7: TUpDown
        Top = 75
        TabOrder = 10
      end
      inherited CheckBox2: TCheckBox
        Top = 152
        TabOrder = 15
      end
      inherited Edit8: TEdit
        TabOrder = 11
      end
      inherited UpDown8: TUpDown
        Top = 102
        TabOrder = 12
      end
      object Edit7: TEdit [20]
        Left = 230
        Top = 125
        Width = 40
        Height = 21
        TabOrder = 13
        Text = '200'
      end
      inherited Edit9: TEdit
        TabOrder = 1
        Text = '500'
      end
      inherited UpDown1: TUpDown
        Position = 500
        TabOrder = 2
      end
      object UpDown2: TUpDown
        Left = 270
        Top = 125
        Width = 12
        Height = 21
        Associate = Edit7
        Min = 100
        Max = 10000
        Increment = 10
        Position = 200
        TabOrder = 14
        Thousands = False
      end
    end
  end
end
