inherited FCutEdit: TFCutEdit
  Left = 277
  Caption = 'Corte'
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl1: TPageControl
    ActivePage = TabSheet1
    inherited TabSheet1: TTabSheet
      inherited UpDown11: TUpDown
        Top = 41
      end
    end
    inherited TabSheet2: TTabSheet
      Caption = 'Linea'
      inherited Label7: TLabel
        Left = 165
        Top = 56
        Width = 27
        Caption = 'Fin X:'
      end
      inherited Label9: TLabel
        Left = 165
        Top = 12
        Width = 38
        Caption = 'Inicio X:'
      end
      inherited Label8: TLabel
        Left = 165
        Top = 34
        Width = 38
        Caption = 'Inicio Y:'
      end
      inherited Label10: TLabel
        Left = 165
        Width = 27
        Caption = 'Fin Y:'
      end
      inherited Label14: TLabel
        Left = 165
      end
      inherited Area1: TArea
        Left = 15
        Style = asLine
      end
      inherited Edit3: TEdit
        Top = 52
        TabOrder = 5
      end
      inherited Edit4: TEdit
        Top = 8
        TabOrder = 9
      end
      inherited Edit5: TEdit
        Top = 75
      end
      inherited Edit6: TEdit
        Top = 30
        TabOrder = 3
      end
      inherited UpDown4: TUpDown
        Top = 52
        TabOrder = 6
      end
      inherited UpDown5: TUpDown
        Top = 8
        TabOrder = 10
      end
      inherited UpDown6: TUpDown
        Top = 75
      end
      inherited UpDown7: TUpDown
        Top = 30
        TabOrder = 4
      end
    end
  end
end
