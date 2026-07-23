inherited FContributionEdit: TFContributionEdit
  Left = 335
  Top = 188
  Caption = 'Aporte'
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
    object TabSheet4: TTabSheet
      Caption = 'Tiempo'
      object Label17: TLabel
        Left = 75
        Top = 119
        Width = 122
        Height = 13
        Caption = '&Intervalo de acumulacion:'
        FocusControl = Edit12
      end
      object Label18: TLabel
        Left = 255
        Top = 119
        Width = 16
        Height = 13
        Caption = 'min'
        FocusControl = Edit12
      end
      object Label24: TLabel
        Left = 10
        Top = 40
        Width = 270
        Height = 36
        AutoSize = False
        Caption = 
          'Advertencia: Acumulados sobre intervalos mayores de 15 minutos n' +
          'o producen buenas aproximaciones.'
        WordWrap = True
      end
      object Edit12: TEdit
        Left = 210
        Top = 115
        Width = 30
        Height = 21
        TabOrder = 0
        Text = '15'
      end
      object UpDown12: TUpDown
        Left = 240
        Top = 115
        Width = 16
        Height = 21
        Associate = Edit12
        Min = 1
        Max = 600
        Position = 15
        TabOrder = 1
        Thousands = False
      end
    end
  end
end
