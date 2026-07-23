inherited FPPIEdit: TFPPIEdit
  Caption = 'PPI'
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl1: TPageControl
    inherited TabSheet1: TTabSheet
      inherited Label4: TLabel
        Visible = False
      end
      inherited Label5: TLabel
        Visible = False
      end
      inherited Label6: TLabel
        Visible = False
      end
      inherited Label15: TLabel
        Visible = False
      end
      inherited Edit1: TEdit
        Visible = False
      end
      inherited UpDown10: TUpDown
        Visible = False
      end
      inherited Edit2: TEdit
        Visible = False
      end
      inherited UpDown11: TUpDown
        Visible = False
      end
    end
    object TabSheet4: TTabSheet [1]
      Caption = 'Elevacion'
      object Label17: TLabel
        Left = 115
        Top = 100
        Width = 4
        Height = 13
        Caption = #176
      end
      object Label16: TLabel
        Left = 10
        Top = 15
        Width = 126
        Height = 76
        AutoSize = False
        Caption = 
          'Si se especifica un angulo no comprendido en la observacion, se ' +
          'toma de los presentes, el mas proximo.'
        WordWrap = True
      end
      object Elevation1: TElevation
        Left = 150
        Top = 15
        Width = 130
        Height = 145
        AntennaType = at_Elevation
        Desired = 0
        Position = 0
        Command = 0
        Count_Rect = 1
        Count_Circ = 1
        Count_Rad = 24
        Count_Small = 144
        Color_Back = clGray
        Color_Ray = clLime
        Color_Mark = clRed
        Color_Rect = clWhite
        Color_Circ = clWhite
        Color_Rad = clYellow
        Color_Small = clWhite
        Color_Cmd = clMaroon
        ReadOnly = False
        OnNewDesired = Elevation1NewDesired
      end
      object Edit10: TEdit
        Left = 35
        Top = 100
        Width = 70
        Height = 21
        TabOrder = 1
        Text = '0.0'
        OnChange = Edit10Change
      end
    end
  end
end
