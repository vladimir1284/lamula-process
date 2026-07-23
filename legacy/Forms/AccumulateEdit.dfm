inherited FAccumulateEdit: TFAccumulateEdit
  BorderIcons = [biSystemMenu, biHelp]
  Caption = 'Acumulado'
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl1: TPageControl
    inherited TabSheet1: TTabSheet
      inherited Label1: TLabel
        Visible = False
      end
      inherited ComboBox1: TComboBox
        Visible = False
      end
    end
    inherited TabSheet2: TTabSheet
      inherited Edit8: TEdit
        Height = 21
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Tiempo'
      object Label16: TLabel
        Left = 10
        Top = 119
        Width = 49
        Height = 13
        Caption = '&Comienza:'
        FocusControl = Edit10
      end
      object Label17: TLabel
        Left = 10
        Top = 144
        Width = 41
        Height = 13
        Caption = '&Termina:'
        FocusControl = Edit11
      end
      object Label18: TLabel
        Left = 80
        Top = 95
        Width = 30
        Height = 13
        Caption = '&Fecha'
        FocusControl = Edit10
      end
      object Label19: TLabel
        Left = 154
        Top = 95
        Width = 23
        Height = 13
        Caption = '&Hora'
        FocusControl = Edit12
      end
      object Label22: TLabel
        Left = 215
        Top = 95
        Width = 44
        Height = 13
        Caption = '&Intervalo:'
        FocusControl = Edit7
      end
      object Label23: TLabel
        Left = 260
        Top = 129
        Width = 16
        Height = 13
        Caption = 'min'
        FocusControl = Edit12
      end
      object Label21: TLabel
        Left = 10
        Top = 10
        Width = 270
        Height = 41
        AutoSize = False
        Caption = 
          'Advertencia: Solo se integra durante el intervalo maximo entre o' +
          'bservaciones especificado, el resto del intervalo se considera s' +
          'in precipitaciones.'
        WordWrap = True
      end
      object Label24: TLabel
        Left = 10
        Top = 55
        Width = 270
        Height = 36
        AutoSize = False
        Caption = 
          'Advertencia: Acumulados sobre intervalos mayores de 15 minutos n' +
          'o producen buenas aproximaciones.'
        WordWrap = True
      end
      object Edit10: TEdit
        Left = 65
        Top = 115
        Width = 60
        Height = 21
        TabOrder = 0
      end
      object Edit11: TEdit
        Left = 65
        Top = 140
        Width = 60
        Height = 21
        TabOrder = 1
      end
      object Edit12: TEdit
        Left = 135
        Top = 115
        Width = 60
        Height = 21
        TabOrder = 2
      end
      object Edit13: TEdit
        Left = 135
        Top = 140
        Width = 60
        Height = 21
        TabOrder = 3
      end
      object Edit7: TEdit
        Left = 215
        Top = 125
        Width = 30
        Height = 21
        TabOrder = 4
        Text = '15'
      end
      object UpDown12: TUpDown
        Left = 245
        Top = 125
        Width = 15
        Height = 21
        Associate = Edit7
        Min = 1
        Max = 60
        Position = 15
        TabOrder = 5
        Thousands = False
        Wrap = False
      end
    end
  end
end
