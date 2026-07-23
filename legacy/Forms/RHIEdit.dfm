inherited FRHIEdit: TFRHIEdit
  Caption = 'RHI'
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl1: TPageControl
    object TabSheet4: TTabSheet [1]
      Caption = 'Azimut'
      object Label17: TLabel
        Left = 10
        Top = 15
        Width = 126
        Height = 81
        AutoSize = False
        Caption = 
          'Si se especifica un angulo comprendido en la observacion, la cre' +
          'acion del producto se acelera considerablemente.'
        WordWrap = True
      end
      object Label18: TLabel
        Left = 115
        Top = 100
        Width = 4
        Height = 13
        Caption = #176
      end
      object Azimut1: TAzimut
        Left = 140
        Top = 15
        Width = 145
        Height = 145
        AntennaType = at_Azimut
        Desired = 0
        Position = 0
        Command = 0
        Count_Rect = 1
        Count_Circ = 1
        Count_Rad = 24
        Count_Small = 144
        Color_Back = clTeal
        Color_Ray = clLime
        Color_Mark = clRed
        Color_Rect = clWhite
        Color_Circ = clWhite
        Color_Rad = clYellow
        Color_Small = clWhite
        Color_Cmd = clMaroon
        ReadOnly = False
        OnNewDesired = Azimut1NewDesired
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
    inherited TabSheet2: TTabSheet
      TabVisible = False
      inherited Label14: TLabel
        Visible = False
      end
    end
  end
end
