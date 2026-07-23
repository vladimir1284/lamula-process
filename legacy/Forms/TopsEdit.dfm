inherited FTopsEdit: TFTopsEdit
  Caption = 'Topes'
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl1: TPageControl
    inherited TabSheet1: TTabSheet
      inherited Label1: TLabel
        Top = 14
      end
      object Label16: TLabel [6]
        Left = 183
        Top = 45
        Width = 20
        Height = 13
        Caption = '&Min:'
      end
      inherited StringGrid1: TStringGrid
        Left = 6
        Width = 276
      end
      inherited CheckBox1: TCheckBox
        Top = 71
        TabOrder = 9
      end
      inherited CheckBox3: TCheckBox
        Caption = 'Suprimir &Ecos Fijos'
      end
      object Edit15: TEdit [14]
        Left = 208
        Top = 41
        Width = 60
        Height = 21
        TabOrder = 6
        Text = '0'
      end
      object UpDown15: TUpDown
        Left = 268
        Top = 41
        Width = 16
        Height = 21
        Max = 255
        TabOrder = 8
        OnClick = UpDown15Click
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Ubicacion'
      object Label17: TLabel
        Left = 215
        Top = 10
        Width = 67
        Height = 13
        Caption = 'Limite superior'
      end
      object Label18: TLabel
        Left = 215
        Top = 147
        Width = 61
        Height = 13
        Caption = 'Limite inferior'
      end
      object Label19: TLabel
        Left = 15
        Top = 10
        Width = 151
        Height = 86
        AutoSize = False
        Caption = 
          'Desplazando el cursor de la barra a la derecha se puede variar e' +
          'l calculo de la ubicacion del tope de nubosidad dentro del volum' +
          'en cubierto por el haz del radar.'
        WordWrap = True
      end
      object Label20: TLabel
        Left = 15
        Top = 100
        Width = 151
        Height = 56
        AutoSize = False
        Caption = 
          'Este calculo siempre es una aproximacion, y su exactitud depende' +
          ' en gran medida del ancho del haz.'
        WordWrap = True
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
    end
  end
end
