object FEditAutoPilot: TFEditAutoPilot
  Left = 526
  Top = 193
  BorderStyle = bsDialog
  Caption = 'FEditAutoPilot'
  ClientHeight = 222
  ClientWidth = 303
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 303
    Height = 191
    ActivePage = TabSheet1
    Align = alTop
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'General'
      object Label1: TLabel
        Left = 2
        Top = 12
        Width = 49
        Height = 13
        Caption = 'Inferior (m)'
      end
      object Label2: TLabel
        Left = 150
        Top = 12
        Width = 56
        Height = 13
        Caption = 'Superior (m)'
      end
      object Label3: TLabel
        Left = 4
        Top = 46
        Width = 38
        Height = 13
        Caption = 'Variable'
      end
      object SpinEdit1: TSpinEdit
        Left = 55
        Top = 8
        Width = 74
        Height = 22
        Increment = 100
        MaxValue = 0
        MinValue = 0
        TabOrder = 0
        Value = 0
      end
      object SpinEdit2: TSpinEdit
        Left = 215
        Top = 8
        Width = 74
        Height = 22
        Increment = 100
        MaxValue = 100000
        MinValue = 0
        TabOrder = 1
        Value = 0
      end
      object ComboBox1: TComboBox
        Left = 55
        Top = 42
        Width = 74
        Height = 21
        ItemHeight = 13
        TabOrder = 2
        Text = 'P [dB]'
        Items.Strings = (
          'P [dB]'
          'Z [dBZ]'
          'R [mm/h]')
      end
      object GroupBox2: TGroupBox
        Left = 0
        Top = 80
        Width = 295
        Height = 42
        Caption = 'Animaci'#243'n'
        TabOrder = 3
        object Label32: TLabel
          Left = 8
          Top = 17
          Width = 101
          Height = 13
          Caption = 'Cantidad de  cuadros'
        end
        object SpinEdit21: TSpinEdit
          Left = 117
          Top = 13
          Width = 74
          Height = 22
          MaxValue = 1000
          MinValue = 0
          TabOrder = 0
          Value = 0
        end
      end
      object GroupBox3: TGroupBox
        Left = 150
        Top = 34
        Width = 145
        Height = 41
        Caption = 'Topes'
        TabOrder = 4
        object Label4: TLabel
          Left = 10
          Top = 17
          Width = 35
          Height = 13
          Caption = 'M'#237'nimo'
        end
        object SpinEdit3: TSpinEdit
          Left = 65
          Top = 12
          Width = 74
          Height = 22
          MaxValue = 0
          MinValue = 0
          TabOrder = 0
          Value = 0
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = #193'rea'
      ImageIndex = 1
      object Label8: TLabel
        Left = 155
        Top = 10
        Width = 45
        Height = 13
        Caption = 'Este (Km)'
      end
      object Label9: TLabel
        Left = 155
        Top = 35
        Width = 52
        Height = 13
        Caption = 'Oeste (Km)'
      end
      object Label10: TLabel
        Left = 155
        Top = 60
        Width = 50
        Height = 13
        Caption = 'Norte (Km)'
      end
      object Label11: TLabel
        Left = 155
        Top = 85
        Width = 40
        Height = 13
        Caption = 'Sur (Km)'
      end
      object Label12: TLabel
        Left = 155
        Top = 109
        Width = 55
        Height = 13
        Caption = 'Celda H (m)'
      end
      object Label31: TLabel
        Left = 155
        Top = 133
        Width = 54
        Height = 13
        Caption = 'Celda V (m)'
      end
      object Area1: TArea
        Left = 10
        Top = 6
        Width = 134
        Height = 134
        West = -500
        East = -500
        North = 0
        South = 0
        AreaColor = clBlack
        MaxWest = -500
        MaxEast = 500
        MaxNorth = 500
        MaxSouth = -500
        Style = asRectangle
        OnChange = Area1Change
      end
      object SpinEdit7: TSpinEdit
        Left = 216
        Top = 6
        Width = 74
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 1
        Value = 0
        OnChange = SpinEdit7Change
      end
      object SpinEdit8: TSpinEdit
        Left = 216
        Top = 31
        Width = 74
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 2
        Value = 0
        OnChange = SpinEdit8Change
      end
      object SpinEdit9: TSpinEdit
        Left = 216
        Top = 56
        Width = 74
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 3
        Value = 0
        OnChange = SpinEdit9Change
      end
      object SpinEdit10: TSpinEdit
        Left = 216
        Top = 81
        Width = 74
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 4
        Value = 0
        OnChange = SpinEdit10Change
      end
      object SpinEdit11: TSpinEdit
        Left = 216
        Top = 105
        Width = 74
        Height = 22
        Increment = 100
        MaxValue = 0
        MinValue = 0
        TabOrder = 5
        Value = 0
      end
      object SpinEdit23: TSpinEdit
        Left = 216
        Top = 129
        Width = 74
        Height = 22
        Increment = 100
        MaxValue = 0
        MinValue = 0
        TabOrder = 6
        Value = 0
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'L'#237'nea'
      ImageIndex = 2
      object Label14: TLabel
        Left = 155
        Top = 10
        Width = 59
        Height = 13
        Caption = 'Inicio X (Km)'
      end
      object Label15: TLabel
        Left = 155
        Top = 35
        Width = 59
        Height = 13
        Caption = 'Inicio Y (Km)'
      end
      object Label16: TLabel
        Left = 155
        Top = 60
        Width = 48
        Height = 13
        Caption = 'Fin X (Km)'
      end
      object Label17: TLabel
        Left = 155
        Top = 85
        Width = 48
        Height = 13
        Caption = 'Fin Y (Km)'
      end
      object Label18: TLabel
        Left = 155
        Top = 114
        Width = 55
        Height = 13
        Caption = 'Celda H (m)'
      end
      object Label20: TLabel
        Left = 155
        Top = 139
        Width = 54
        Height = 13
        Caption = 'Celda V (m)'
      end
      object Area2: TArea
        Left = 10
        Top = 6
        Width = 134
        Height = 134
        West = -500
        East = -500
        North = 90
        South = 10
        AreaColor = clBlack
        MaxWest = -500
        MaxEast = 500
        MaxNorth = 500
        MaxSouth = -500
        Style = asLine
      end
      object SpinEdit13: TSpinEdit
        Left = 216
        Top = 6
        Width = 74
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 1
        Value = 0
      end
      object SpinEdit14: TSpinEdit
        Left = 216
        Top = 31
        Width = 74
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 2
        Value = 0
      end
      object SpinEdit15: TSpinEdit
        Left = 216
        Top = 56
        Width = 74
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 3
        Value = 0
      end
      object SpinEdit16: TSpinEdit
        Left = 216
        Top = 81
        Width = 74
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 4
        Value = 0
      end
      object SpinEdit17: TSpinEdit
        Left = 216
        Top = 110
        Width = 74
        Height = 22
        Increment = 100
        MaxValue = 0
        MinValue = 0
        TabOrder = 5
        Value = 0
      end
      object SpinEdit19: TSpinEdit
        Left = 216
        Top = 135
        Width = 74
        Height = 22
        Increment = 100
        MaxValue = 0
        MinValue = 0
        TabOrder = 6
        Value = 0
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Elevaci'#243'n'
      ImageIndex = 3
      object Label21: TLabel
        Left = 8
        Top = 24
        Width = 135
        Height = 52
        Caption = 
          'Si se especifica un '#225'ngulo no comprendido en la observaci'#243'n se t' +
          'oma, de los presentes, el m'#225's pr'#243'ximo.'
        WordWrap = True
      end
      object Label22: TLabel
        Left = 98
        Top = 111
        Width = 4
        Height = 13
        Caption = #176
      end
      object Elevation1: TElevation
        Left = 160
        Top = 15
        Width = 121
        Height = 121
        AntennaType = at_Elevation
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
        OnNewDesired = Elevation1NewDesired
      end
      object Edit1: TEdit
        Left = 12
        Top = 109
        Width = 81
        Height = 21
        TabOrder = 1
        OnChange = Edit1Change
      end
    end
    object TabSheet5: TTabSheet
      Caption = 'Acimut'
      ImageIndex = 4
      object Label23: TLabel
        Left = 8
        Top = 8
        Width = 127
        Height = 65
        Caption = 
          'Si se especifica un '#225'ngulo comprendido en la observaci'#243'n, la cre' +
          'aci'#243'n del producto se acelera considerablemente.'
        WordWrap = True
      end
      object Label24: TLabel
        Left = 98
        Top = 110
        Width = 4
        Height = 13
        Caption = #176
      end
      object Azimut1: TAzimut
        Left = 144
        Top = 8
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
      object Edit2: TEdit
        Left = 12
        Top = 109
        Width = 81
        Height = 21
        TabOrder = 1
        Text = '0'
        OnChange = Edit2Change
      end
    end
    object TabSheet6: TTabSheet
      Caption = 'Tiempo'
      ImageIndex = 5
      object Label25: TLabel
        Left = 15
        Top = 14
        Width = 212
        Height = 39
        Caption = 
          'Advertencia: Acumulados sobre intervalos mayores de 15 minutos n' +
          'o producen buenas aproximaciones.'
        WordWrap = True
      end
      object Label26: TLabel
        Left = 15
        Top = 70
        Width = 164
        Height = 13
        Caption = 'Intervalo de acumulaci'#243'n (minutos)'
      end
      object SpinEdit20: TSpinEdit
        Left = 183
        Top = 66
        Width = 74
        Height = 22
        MaxValue = 0
        MinValue = 0
        TabOrder = 0
        Value = 0
      end
    end
    object TabSheet7: TTabSheet
      Caption = 'Ubicaci'#243'n'
      ImageIndex = 6
      object Label27: TLabel
        Left = 12
        Top = 8
        Width = 136
        Height = 91
        Caption = 
          'Desplazando el cursor de la barra a la derecha se puede variar e' +
          'l c'#225'lculo de la ubicaci'#243'n del tope de nubosidad dentro del volum' +
          'en cubierto por el haz del radar.'
        WordWrap = True
      end
      object Label28: TLabel
        Left = 12
        Top = 99
        Width = 135
        Height = 52
        Caption = 
          'Este c'#225'lculo siempre es una aproximaci'#243'n y su exactitud depende ' +
          'en gran medida del ancho del haz.'
        WordWrap = True
      end
      object Label29: TLabel
        Left = 216
        Top = 14
        Width = 69
        Height = 13
        Caption = 'L'#237'mite superior'
      end
      object Label30: TLabel
        Left = 217
        Top = 135
        Width = 63
        Height = 13
        Caption = 'L'#237'mite inferior'
      end
      object TrackBar1: TTrackBar
        Left = 171
        Top = 8
        Width = 45
        Height = 146
        Ctl3D = True
        Max = 100
        Orientation = trVertical
        ParentCtl3D = False
        Frequency = 10
        TabOrder = 0
      end
    end
  end
  object Button1: TButton
    Left = 225
    Top = 194
    Width = 75
    Height = 25
    Caption = 'Aceptar'
    ModalResult = 1
    TabOrder = 1
  end
  object Button2: TButton
    Left = 145
    Top = 194
    Width = 75
    Height = 25
    Caption = 'Cancelar'
    ModalResult = 2
    TabOrder = 2
  end
end
