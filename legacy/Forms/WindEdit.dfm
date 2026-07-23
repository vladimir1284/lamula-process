inherited FWindEdit: TFWindEdit
  Caption = 'Viento'
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl1: TPageControl
    ActivePage = TabSheet3
    object TabSheet3: TTabSheet
      Caption = 'Altura'
      ImageIndex = 2
      object Label2: TLabel
        Left = 8
        Top = 16
        Width = 27
        Height = 13
        Caption = 'Altura'
      end
      object Label12: TLabel
        Left = 8
        Top = 64
        Width = 84
        Height = 13
        Caption = 'Ancho de la capa'
      end
      object TrackBar1: TTrackBar
        Left = 175
        Top = 5
        Width = 31
        Height = 161
        Max = 100
        Orientation = trVertical
        Frequency = 10
        Position = 100
        TabOrder = 0
        TickMarks = tmTopLeft
      end
      object Edit7: TEdit
        Left = 8
        Top = 32
        Width = 121
        Height = 21
        TabOrder = 1
        Text = '0'
      end
      object UpDown2: TUpDown
        Left = 129
        Top = 32
        Width = 16
        Height = 21
        Associate = Edit7
        Max = 32767
        TabOrder = 2
      end
      object Edit10: TEdit
        Left = 8
        Top = 80
        Width = 121
        Height = 21
        TabOrder = 3
        Text = '0'
      end
      object UpDown3: TUpDown
        Left = 129
        Top = 80
        Width = 16
        Height = 21
        Associate = Edit10
        Max = 32767
        TabOrder = 4
      end
    end
  end
end
