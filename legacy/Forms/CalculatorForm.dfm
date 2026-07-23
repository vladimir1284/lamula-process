object FCalculator: TFCalculator
  Left = 43
  Top = 91
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Calculador'
  ClientHeight = 373
  ClientWidth = 717
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010001002020100000000000E80200001600000028000000200000004000
    0000010004000000000080020000000000000000000000000000000000000000
    000000008000008000000080800080000000800080008080000080808000C0C0
    C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
    0000070707000000070707000000000000000070708888877070700000000000
    0000000000088877000000000000000000000000008877700000000000000000
    0000000008777700007777708880000000000000877700077777700888F00000
    00000008877007777770088888F0000000000008770077777700888888F00000
    000000087007777770088888880000000000000000877777008888888F000000
    000000000087777008888888F000000000000000088777008888888800000000
    0000000008777008888888880000000000000000087700008888888000000000
    0000000088700880088888000000000000000000880088880088800000000000
    00000000800888888008000000006E4444444408808888888800000000006F66
    66666608088888888800000000006E60F0F0F60088888888F0000F8800006F66
    666666008888888F000000F800006E60F0F0F60888888FF00000000000006F66
    6666660F888FF0000000000000006E60F0F0F60FFFF006460000000000006F66
    666666600000F6460000000000006E0000000000066666460000000000006F08
    888888888060F6460000000000006E0FFFFFFFFF806666460000000000006F0F
    FFFFFFFF8060F6460000000000006E0000000000006666460000000000006FEF
    EFEFEFEFEFEFEFE600000000000006666666666666666660000000000000FF00
    001FFF80003FFFFC07FFFFF80C01FFF00000FFE00000FFC00000FFC00000FFC0
    0001FFE00001FFF80003FFF00007FFF00007FFF0000FFFE0001FFFE0003F8000
    007F000000FF0000020F000003070000078700000FCF00001FFF00000FFF0000
    0FFF00000FFF00000FFF00000FFF00000FFF00000FFF00000FFF80001FFF}
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 717
    Height = 373
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'C'#225'culos del Radar'
      object GroupBox1: TGroupBox
        Left = 0
        Top = 0
        Width = 709
        Height = 34
        Align = alTop
        Caption = 'Radar'
        TabOrder = 0
        object Label1: TLabel
          Left = 9
          Top = 13
          Width = 41
          Height = 13
          Caption = 'Estaci'#243'n'
        end
        object Label2: TLabel
          Left = 246
          Top = 13
          Width = 81
          Height = 13
          Caption = 'Modo de Trabajo'
        end
        object ComboBoxStation: TComboBox
          Left = 53
          Top = 10
          Width = 183
          Height = 21
          Hint = 
            'Carga una Estaci'#243'n | Carga el nombre, las coordenadas y tipo de ' +
            'radar de una estaci'#243'n'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ItemHeight = 13
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          Text = 'Cargue una Estaci'#243'n'
          Items.Strings = (
            'La Bajada (Pinar del Rio)'
            'Punta del Este (Isla de la  Juventud)'
            'Casablanca (Ciudad de La Habana)'
            'Pico San Juan (Cienfuegos)'
            'Loma La Mula (Camag'#252'ey)'
            'Pil'#243'n  (Granma)'
            'Gran Piedra (Santiago de Cuba)')
        end
        object ComboBoxLoadRadarDefaults: TComboBox
          Left = 335
          Top = 9
          Width = 171
          Height = 21
          Hint = 
            'Carga el modo de trabajo | Muestra todos los modos posibles de t' +
            'rabajo del radar y carga los par'#225'metros del que se seleccione'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ItemHeight = 13
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          Text = 'Cargue el modo de trabajo  '
        end
      end
      object PageControl3: TPageControl
        Left = 0
        Top = 34
        Width = 709
        Height = 311
        ActivePage = TabSheet14
        Align = alClient
        HotTrack = True
        MultiLine = True
        TabOrder = 1
        object TabSheet8: TTabSheet
          Caption = 'Constantes del radar'
          object GroupBox5: TGroupBox
            Left = 0
            Top = 0
            Width = 438
            Height = 144
            Caption = 'Transmisor'
            TabOrder = 0
            object RadioGroup1: TRadioGroup
              Left = 2
              Top = 78
              Width = 210
              Height = 63
              Hint = 'Teclee la Frecuencia o la Longitud de Onda.'
              Caption = 'Transmisi'#243'n'
              ItemIndex = 0
              Items.Strings = (
                'Frecuencia [MHz]'
                'Longitud de onda [cm]')
              ParentShowHint = False
              ShowHint = True
              TabOrder = 0
              OnClick = RadioGroup_OnClick
            end
            object RadioGroup2: TRadioGroup
              Tag = 2
              Left = 214
              Top = 79
              Width = 221
              Height = 63
              Hint = 'Teclee la Frecuencia o el Periodo de Repetici'#243'n de los Pulsos.'
              Caption = 'Recurrencia'
              ItemIndex = 0
              Items.Strings = (
                'Frecuencia de Repetici'#243'n [Hz]'
                'Per'#237'odo de Repetici'#243'n [miliseg]')
              ParentShowHint = False
              ShowHint = True
              TabOrder = 1
              OnClick = RadioGroup_OnClick
            end
            object RadioGroup3: TRadioGroup
              Tag = 3
              Left = 2
              Top = 15
              Width = 212
              Height = 63
              Hint = 'Teclee la Potencia Pico o la Potencia Promedio.'
              Caption = 'Potencia'
              ItemIndex = 0
              Items.Strings = (
                'Pico, o prom. en el pulso [kW]'
                'Promedio en el per'#237'odo [W]')
              ParentShowHint = False
              ShowHint = True
              TabOrder = 2
              OnClick = RadioGroup_OnClick
            end
            object RadioGroup4: TRadioGroup
              Tag = 1
              Left = 216
              Top = 16
              Width = 216
              Height = 63
              Hint = 'Teclee la Duraci'#243'n o la Extensi'#243'n del Pulso.'
              Caption = 'Pulso'
              ItemIndex = 0
              Items.Strings = (
                'Duraci'#243'n del Pulso [microseg]'
                'Extensi'#243'n del Pulso [m]')
              ParentShowHint = False
              ShowHint = True
              TabOrder = 3
              OnClick = RadioGroup_OnClick
            end
            object Edit1: TEdit
              Left = 169
              Top = 95
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 4
              OnChange = Freq_OnChange
            end
            object Edit2: TEdit
              Left = 169
              Top = 116
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 5
              OnChange = Wave_OnChange
            end
            object Edit3: TEdit
              Left = 392
              Top = 93
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 6
              OnChange = Prf_OnChange
            end
            object Edit4: TEdit
              Left = 392
              Top = 114
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 7
              OnChange = PrT_OnChange
            end
            object Edit5: TEdit
              Left = 174
              Top = 32
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 8
              OnChange = PeakPower_OnChange
            end
            object Edit6: TEdit
              Left = 174
              Top = 53
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 9
              OnChange = AverPower_OnChange
            end
            object Edit7: TEdit
              Left = 392
              Top = 29
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 10
              OnChange = Dur_OnChange
            end
            object Edit8: TEdit
              Left = 392
              Top = 51
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 11
              OnChange = Ext_OnChange
            end
          end
          object GroupBox6: TGroupBox
            Left = 0
            Top = 144
            Width = 438
            Height = 59
            Caption = 'Receptor'
            TabOrder = 1
            object Label10: TLabel
              Left = 6
              Top = 13
              Width = 101
              Height = 13
              Caption = 'Rango Din'#225'mico [dB]'
            end
            object Label11: TLabel
              Left = 6
              Top = 30
              Width = 157
              Height = 13
              Caption = 'Ancho de Banda  (a -6 dB) [MHz]'
              ParentShowHint = False
              ShowHint = False
            end
            object Label12: TLabel
              Left = 220
              Top = 37
              Width = 150
              Height = 13
              Caption = 'Se'#241'al M'#237'nima Discernible [dBm]'
            end
            object Label3: TLabel
              Left = 232
              Top = 16
              Width = 44
              Height = 13
              Caption = 'Receptor'
            end
            object Edit9: TEdit
              Left = 174
              Top = 11
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 0
            end
            object Edit10: TEdit
              Left = 174
              Top = 35
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 1
            end
            object Edit11: TEdit
              Left = 389
              Top = 38
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 2
            end
            object ComboBox1: TComboBox
              Left = 280
              Top = 12
              Width = 145
              Height = 21
              ItemHeight = 0
              TabOrder = 3
              Text = 'ComboBox1'
            end
          end
          object GroupBox10: TGroupBox
            Left = 0
            Top = 203
            Width = 440
            Height = 60
            Caption = 'Antena'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 2
            object Label13: TLabel
              Left = 4
              Top = 14
              Width = 130
              Height = 13
              Caption = 'Ganancia  de potencia [dB]'
            end
            object Label14: TLabel
              Left = 4
              Top = 37
              Width = 152
              Height = 13
              Caption = 'Ancho del haz (a -3 dB) [grados]'
            end
            object Edit12: TEdit
              Left = 170
              Top = 11
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 0
            end
            object Edit13: TEdit
              Left = 170
              Top = 35
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 1
            end
            object GroupBox11: TGroupBox
              Left = 215
              Top = 12
              Width = 222
              Height = 41
              Caption = 'Circuito de Microondas'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
              TabOrder = 2
              object Label15: TLabel
                Left = 5
                Top = 18
                Width = 166
                Height = 13
                Caption = 'P'#233'rdidas en las gu'#237'as de onda [dB]'
              end
              object Edit14: TEdit
                Left = 176
                Top = 16
                Width = 35
                Height = 18
                Constraints.MaxHeight = 18
                TabOrder = 0
              end
            end
          end
          object BitBtn1: TBitBtn
            Left = 445
            Top = 5
            Width = 89
            Height = 25
            Caption = 'Descripci'#243'n'
            TabOrder = 3
            Glyph.Data = {
              F6020000424DF60200000000000036000000280000000E000000100000000100
              180000000000C002000000000000000000000000000000000000FF00FFFF00FF
              FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF4D4D4DFF00FFFF00
              FFFF00FF0000FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
              FF4D4D4D4D4D4DFF00FFFF00FFFF00FF0000FF00FFFF00FFA6A6A6A6A6A6A6A6
              A6A6A6A6A6A6A6A6A6A64D4D4D4DFFFF4D4D4DA6A6A6FF00FFFF00FF0000FF00
              FF4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4DFFFFFFFFFFFF4D4D4D4D
              4D4DA6A6A6FF00FF00004D4D4DFFFFFFFFFFFFFFFFFF4DFFFFFFFFFF4DFFFFFF
              FFFF4DFFFFFFFFFFFFFFFFFFFFFF4D4D4DA6A6A600004D4D4DFFFFFF4DFFFFFF
              FFFFFFFFFFFFFFFFA64D4DA64D4DFFFFFFFFFFFF4DFFFFFFFFFF4D4D4DA6A6A6
              00004D4D4DFFFFFFFFFFFFFFFFFF4DFFFFFFFFFFFFFFFFFFFFFF4DFFFFFFFFFF
              FFFFFFFFFFFF4D4D4DA6A6A600004D4D4DFFFFFF4DFFFFFFFFFFFFFFFFFFFFFF
              A64D4DA6A6A6FFFFFFFFFFFF4DFFFFFFFFFF4D4D4DA6A6A600004D4D4DFFFFFF
              FFFFFFFFFFFF4DFFFFFFFFFFA6A6A6A64D4DD3D3D3FFFFFFFFFFFFFFFFFF4D4D
              4DA6A6A600004D4D4DFFFFFF4DFFFFFFFFFFFFFFFFFFFFFF4DFFFFA6A6A6A64D
              4DA6A6A64DFFFFFFFFFF4D4D4DA6A6A600004D4D4DFFFFFFFFFFFFFFFFFFA64D
              4DA6A6A6FFFFFFFFFFFFA64D4DA64D4DFFFFFFFFFFFF4D4D4DA6A6A600004D4D
              4DFFFFFF4DFFFFFFFFFFA64D4DA64D4D4DFFFFD3D3D3A64D4DA64D4D4DFFFFFF
              FFFF4D4D4DA6A6A600004D4D4DFFFFFFFFFFFFFFFFFFD3D3D3A64D4DA64D4DA6
              4D4DA64D4DD3D3D3FFFFFFFFFFFF4D4D4DA6A6A600004D4D4DFFFFFF4DFFFFFF
              FFFFFFFFFFFFFFFF4DFFFFFFFFFFFFFFFFFFFFFF4DFFFFFFFFFF4D4D4DA6A6A6
              00004D4D4DFFFFFFFFFFFFFFFFFF4DFFFFFFFFFFFFFFFFFFFFFF4DFFFFFFFFFF
              FFFFFFFFFFFF4D4D4DFF00FF0000FF00FF4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D
              4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4D4DFF00FFFF00FF0000}
          end
          object GroupBox2: TGroupBox
            Left = 440
            Top = 32
            Width = 257
            Height = 233
            Caption = 'Resultados'
            TabOrder = 4
            object Memo1: TMemo
              Left = 2
              Top = 15
              Width = 253
              Height = 216
              Align = alClient
              Lines.Strings = (
                'Memo1')
              TabOrder = 0
            end
          end
        end
        object TabSheet9: TTabSheet
          Caption = 'Estad'#237'stica de la se'#241'al'
          ImageIndex = 1
          object GroupBox12: TGroupBox
            Left = 0
            Top = 0
            Width = 221
            Height = 35
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 0
            object Label16: TLabel
              Left = 8
              Top = 13
              Width = 154
              Height = 13
              Caption = 'Velocidad de la Antena    [r.p.m.]'
            end
            object Edit15: TEdit
              Left = 180
              Top = 10
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 0
            end
          end
          object GroupBox13: TGroupBox
            Left = 0
            Top = 35
            Width = 221
            Height = 35
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 1
            object Label17: TLabel
              Left = 8
              Top = 13
              Width = 126
              Height = 13
              Caption = 'Distancia de Muestreo  [m]'
            end
            object Edit16: TEdit
              Left = 180
              Top = 10
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 0
            end
          end
          object GroupBox14: TGroupBox
            Left = 0
            Top = 70
            Width = 221
            Height = 41
            Caption = 'Tama'#241'o Radial de la Celda'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 2
            object Label18: TLabel
              Left = 8
              Top = 20
              Width = 64
              Height = 13
              Caption = 'Distancia  [m]'
            end
            object Edit17: TEdit
              Left = 180
              Top = 16
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 0
            end
          end
          object RadioGroup6: TRadioGroup
            Tag = 4
            Left = 0
            Top = 111
            Width = 221
            Height = 63
            Caption = 'Tama'#241'o Tangencial de la Celda'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ItemIndex = 0
            Items.Strings = (
              'Angulo  [grados]'
              'Tiempo [# pulsos]')
            ParentFont = False
            TabOrder = 3
            OnClick = RadioGroup_OnClick
          end
          object Edit18: TEdit
            Left = 180
            Top = 129
            Width = 35
            Height = 18
            Constraints.MaxHeight = 18
            TabOrder = 4
            OnChange = AngleCellSize_OnChange
          end
          object Edit19: TEdit
            Left = 180
            Top = 150
            Width = 35
            Height = 18
            Constraints.MaxHeight = 18
            Enabled = False
            TabOrder = 5
            OnChange = TimeCellSize_OnChange
          end
          object RadioGroup7: TRadioGroup
            Tag = 2
            Left = 0
            Top = 177
            Width = 220
            Height = 63
            Hint = 'Teclee la Frecuencia o el Periodo de Repetici'#243'n de los Pulsos.'
            Caption = 'Recurrencia'
            ItemIndex = 0
            Items.Strings = (
              'Frecuencia de Repetici'#243'n [Hz]'
              'Per'#237'odo de Repetici'#243'n [miliseg]')
            ParentShowHint = False
            ShowHint = True
            TabOrder = 6
            OnClick = RadioGroup_OnClick
          end
          object Edit20: TEdit
            Left = 180
            Top = 196
            Width = 35
            Height = 18
            Constraints.MaxHeight = 18
            TabOrder = 7
            OnChange = Prf_OnChange
          end
          object Edit21: TEdit
            Left = 180
            Top = 217
            Width = 35
            Height = 18
            Constraints.MaxHeight = 18
            TabOrder = 8
            OnChange = PrT_OnChange
          end
          object RadioGroup8: TRadioGroup
            Tag = 1
            Left = 224
            Top = 5
            Width = 221
            Height = 63
            Hint = 'Teclee la Duraci'#243'n o la Extensi'#243'n del Pulso.'
            Caption = 'Pulso'
            ItemIndex = 0
            Items.Strings = (
              'Duraci'#243'n del Pulso [microseg]'
              'Extensi'#243'n del Pulso [m]')
            ParentShowHint = False
            ShowHint = True
            TabOrder = 9
            OnClick = RadioGroup_OnClick
          end
          object Edit22: TEdit
            Left = 404
            Top = 21
            Width = 35
            Height = 18
            Constraints.MaxHeight = 18
            TabOrder = 10
            OnChange = Dur_OnChange
          end
          object Edit23: TEdit
            Left = 404
            Top = 43
            Width = 35
            Height = 18
            Constraints.MaxHeight = 18
            TabOrder = 11
            OnChange = Ext_OnChange
          end
          object RadioGroup9: TRadioGroup
            Left = 224
            Top = 72
            Width = 225
            Height = 63
            Hint = 'Teclee la Frecuencia o la Longitud de Onda.'
            Caption = 'Transmisi'#243'n'
            ItemIndex = 0
            Items.Strings = (
              'Frecuencia [MHz]'
              'Longitud de onda [cm]')
            ParentShowHint = False
            ShowHint = True
            TabOrder = 12
            OnClick = RadioGroup_OnClick
          end
          object Edit24: TEdit
            Left = 404
            Top = 90
            Width = 35
            Height = 18
            Constraints.MaxHeight = 18
            TabOrder = 13
            OnChange = Freq_OnChange
          end
          object Edit25: TEdit
            Left = 404
            Top = 111
            Width = 35
            Height = 18
            Constraints.MaxHeight = 18
            TabOrder = 14
            OnChange = Wave_OnChange
          end
          object GroupBox15: TGroupBox
            Left = 224
            Top = 136
            Width = 225
            Height = 41
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 15
            object Label20: TLabel
              Left = 4
              Top = 13
              Width = 158
              Height = 13
              Caption = 'Ancho del haz (a -3 dB)   [grados]'
            end
            object Edit27: TEdit
              Left = 181
              Top = 11
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 0
            end
          end
        end
        object TabSheet10: TTabSheet
          Caption = 'Reflectividad y precipitaci'#243'n'
          ImageIndex = 2
          object GroupBox16: TGroupBox
            Left = 0
            Top = 0
            Width = 225
            Height = 281
            Caption = 'Transmisor'
            TabOrder = 0
            object RadioGroup10: TRadioGroup
              Left = 2
              Top = 78
              Width = 221
              Height = 63
              Hint = 'Teclee la Frecuencia o la Longitud de Onda.'
              Align = alTop
              Caption = 'Transmisi'#243'n'
              ItemIndex = 0
              Items.Strings = (
                'Frecuencia [MHz]'
                'Longitud de onda [cm]')
              ParentShowHint = False
              ShowHint = True
              TabOrder = 0
              OnClick = RadioGroup_OnClick
            end
            object RadioGroup11: TRadioGroup
              Tag = 2
              Left = 2
              Top = 204
              Width = 221
              Height = 63
              Hint = 'Teclee la Frecuencia o el Periodo de Repetici'#243'n de los Pulsos.'
              Align = alTop
              Caption = 'Recurrencia'
              ItemIndex = 0
              Items.Strings = (
                'Frecuencia de Repetici'#243'n [Hz]'
                'Per'#237'odo de Repetici'#243'n [miliseg]')
              ParentShowHint = False
              ShowHint = True
              TabOrder = 1
              OnClick = RadioGroup_OnClick
            end
            object RadioGroup12: TRadioGroup
              Tag = 3
              Left = 2
              Top = 15
              Width = 221
              Height = 63
              Hint = 'Teclee la Potencia Pico o la Potencia Promedio.'
              Align = alTop
              Caption = 'Potencia'
              ItemIndex = 0
              Items.Strings = (
                'Pico, o prom. en el pulso   [kW]'
                'Promedio en el per'#237'odo     [W]')
              ParentShowHint = False
              ShowHint = True
              TabOrder = 2
              OnClick = RadioGroup_OnClick
            end
            object RadioGroup13: TRadioGroup
              Tag = 1
              Left = 2
              Top = 141
              Width = 221
              Height = 63
              Hint = 'Teclee la Duraci'#243'n o la Extensi'#243'n del Pulso.'
              Align = alTop
              Caption = 'Pulso'
              ItemIndex = 0
              Items.Strings = (
                'Duraci'#243'n del Pulso [microseg]'
                'Extensi'#243'n del Pulso [m]')
              ParentShowHint = False
              ShowHint = True
              TabOrder = 3
              OnClick = RadioGroup_OnClick
            end
            object Edit26: TEdit
              Left = 180
              Top = 98
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 4
              OnChange = Freq_OnChange
            end
            object Edit28: TEdit
              Left = 180
              Top = 119
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 5
              OnChange = Wave_OnChange
            end
            object Edit29: TEdit
              Left = 180
              Top = 217
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 6
              OnChange = Prf_OnChange
            end
            object Edit30: TEdit
              Left = 180
              Top = 238
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 7
              OnChange = PrT_OnChange
            end
            object Edit31: TEdit
              Left = 180
              Top = 32
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 8
              OnChange = PeakPower_OnChange
            end
            object Edit32: TEdit
              Left = 180
              Top = 53
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 9
              OnChange = AverPower_OnChange
            end
            object Edit33: TEdit
              Left = 180
              Top = 157
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 10
              OnChange = Dur_OnChange
            end
            object Edit34: TEdit
              Left = 180
              Top = 179
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 11
              OnChange = Ext_OnChange
            end
          end
          object GroupBox17: TGroupBox
            Left = 232
            Top = 8
            Width = 225
            Height = 265
            Caption = 'Receptor'
            TabOrder = 1
            object GroupBox18: TGroupBox
              Left = 2
              Top = 15
              Width = 221
              Height = 35
              Hint = 
                'Teclee el rango din'#225'mico | El rango din'#225'mico es  la diferencia e' +
                'ntre la se'#241'al max. y min. que se recibe sin distorsi'#243'n.'
              Align = alTop
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              TabOrder = 0
              object Label19: TLabel
                Left = 6
                Top = 13
                Width = 101
                Height = 13
                Caption = 'Rango Din'#225'mico [dB]'
              end
              object Edit35: TEdit
                Left = 179
                Top = 11
                Width = 35
                Height = 18
                Constraints.MaxHeight = 18
                TabOrder = 0
              end
            end
            object GroupBox19: TGroupBox
              Left = 2
              Top = 50
              Width = 221
              Height = 35
              Hint = 
                'Teclee el ancho de banda | El ancho de banda del receptor a -6 d' +
                'B'
              Align = alTop
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              TabOrder = 1
              object Label21: TLabel
                Left = 6
                Top = 13
                Width = 157
                Height = 13
                Caption = 'Ancho de Banda  (a -6 dB) [MHz]'
                ParentShowHint = False
                ShowHint = False
              end
              object Edit36: TEdit
                Left = 179
                Top = 10
                Width = 35
                Height = 18
                Constraints.MaxHeight = 18
                TabOrder = 0
              end
            end
            object RadioGroup14: TRadioGroup
              Left = 2
              Top = 85
              Width = 221
              Height = 82
              Align = alTop
              Caption = 'Tipo de Receptor'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ItemIndex = 0
              Items.Strings = (
                'Detector Logar'#237'tmico'
                'Detector Lineal'
                'Detector Cuadr'#225'tico')
              ParentFont = False
              TabOrder = 2
            end
            object GroupBox20: TGroupBox
              Left = 2
              Top = 167
              Width = 221
              Height = 35
              Hint = 
                'Teclee la se'#241'al m'#237'nima discernible | Es la se'#241'al m'#225's peque'#241'a que' +
                ' puede ser detectada en el fondo de los ruidos.'
              Align = alTop
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              TabOrder = 3
              object Label22: TLabel
                Left = 4
                Top = 15
                Width = 150
                Height = 13
                Caption = 'Se'#241'al M'#237'nima Discernible [dBm]'
              end
              object Edit37: TEdit
                Left = 179
                Top = 11
                Width = 35
                Height = 18
                Constraints.MaxHeight = 18
                TabOrder = 0
              end
            end
            object GroupBox21: TGroupBox
              Left = 2
              Top = 202
              Width = 221
              Height = 35
              Hint = 
                'Teclee (opcional) el coeficiente de ruido. |  Muestra en cuanto ' +
                'se deteiora la relaci'#243'n S/N al pasar por el receptor.'
              Align = alTop
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              TabOrder = 4
              object Label23: TLabel
                Left = 6
                Top = 13
                Width = 121
                Height = 13
                Caption = 'Coeficiente de Ruido [dB]'
              end
              object Edit38: TEdit
                Left = 179
                Top = 11
                Width = 35
                Height = 18
                Constraints.MaxHeight = 18
                TabOrder = 0
              end
            end
          end
          object GroupBox22: TGroupBox
            Left = 416
            Top = 32
            Width = 281
            Height = 209
            Caption = 'Antena'
            TabOrder = 2
            object GroupBox23: TGroupBox
              Left = 2
              Top = 15
              Width = 277
              Height = 108
              Align = alTop
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
              TabOrder = 0
              object Label24: TLabel
                Left = 4
                Top = 14
                Width = 139
                Height = 13
                Caption = 'Ganancia  de potencia    [dB]'
              end
              object Label25: TLabel
                Left = 4
                Top = 37
                Width = 158
                Height = 13
                Caption = 'Ancho del haz (a -3 dB)   [grados]'
              end
              object Label26: TLabel
                Left = 4
                Top = 84
                Width = 169
                Height = 13
                Caption = 'Di'#225'metro del reflector (opcional)  [m]'
              end
              object Label27: TLabel
                Left = 4
                Top = 60
                Width = 147
                Height = 13
                Caption = 'L'#243'bulo Lateral (opcional)  [- dB]'
              end
              object Edit39: TEdit
                Left = 181
                Top = 11
                Width = 35
                Height = 18
                Constraints.MaxHeight = 18
                TabOrder = 0
              end
              object Edit40: TEdit
                Left = 181
                Top = 35
                Width = 35
                Height = 18
                Constraints.MaxHeight = 18
                TabOrder = 1
              end
              object Edit41: TEdit
                Left = 181
                Top = 83
                Width = 35
                Height = 18
                Constraints.MaxHeight = 18
                TabOrder = 2
              end
              object Edit42: TEdit
                Left = 181
                Top = 59
                Width = 35
                Height = 18
                AutoSize = False
                Constraints.MaxHeight = 18
                TabOrder = 3
              end
            end
            object GroupBox24: TGroupBox
              Left = 2
              Top = 164
              Width = 277
              Height = 41
              Align = alTop
              Caption = 'Circuito de Microondas'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
              TabOrder = 1
              object Label28: TLabel
                Left = 5
                Top = 18
                Width = 166
                Height = 13
                Caption = 'P'#233'rdidas en las gu'#237'as de onda [dB]'
              end
              object Edit43: TEdit
                Left = 180
                Top = 16
                Width = 35
                Height = 18
                Constraints.MaxHeight = 18
                TabOrder = 0
              end
            end
            object GroupBox25: TGroupBox
              Left = 2
              Top = 123
              Width = 277
              Height = 41
              Align = alTop
              Caption = 'Medio'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
              TabOrder = 2
              object Label29: TLabel
                Left = 4
                Top = 16
                Width = 168
                Height = 13
                Caption = 'Ancho del Espectro de Veloc. [m/s]'
              end
              object Edit44: TEdit
                Left = 180
                Top = 14
                Width = 35
                Height = 18
                AutoSize = False
                Constraints.MaxHeight = 18
                TabOrder = 0
              end
            end
          end
        end
        object TabSheet11: TTabSheet
          Caption = 'Altura del eco'
          ImageIndex = 3
          object GroupBox26: TGroupBox
            Left = 0
            Top = 0
            Width = 110
            Height = 175
            Caption = 'Punto 1'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 0
            object Label30: TLabel
              Left = 7
              Top = 17
              Width = 48
              Height = 13
              Caption = 'Dist. [Km]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label31: TLabel
              Left = 7
              Top = 36
              Width = 42
              Height = 13
              Caption = 'Acim. ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label32: TLabel
              Left = 7
              Top = 55
              Width = 46
              Height = 13
              Caption = 'Elev.   ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label33: TLabel
              Left = 7
              Top = 75
              Width = 44
              Height = 13
              Caption = 'Pot. [dB]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label34: TLabel
              Left = 6
              Top = 93
              Width = 26
              Height = 13
              Caption = 'Hora:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label35: TLabel
              Left = 5
              Top = 133
              Width = 33
              Height = 13
              Caption = 'Fecha:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Edit45: TEdit
              Left = 68
              Top = 15
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 0
              Text = '50'
            end
            object Edit46: TEdit
              Left = 68
              Top = 35
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 1
              Text = '10'
            end
            object Edit47: TEdit
              Left = 68
              Top = 55
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 2
              Text = '1'
            end
            object Edit48: TEdit
              Left = 68
              Top = 75
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 3
              Text = '10'
            end
            object DateTimePicker1: TDateTimePicker
              Left = 6
              Top = 109
              Width = 98
              Height = 20
              Date = 37383.486365740700000000
              Time = 37383.486365740700000000
              Kind = dtkTime
              TabOrder = 4
            end
            object DateTimePicker2: TDateTimePicker
              Left = 6
              Top = 148
              Width = 98
              Height = 20
              Date = 37383.491226898100000000
              Time = 37383.491226898100000000
              TabOrder = 5
            end
          end
          object GroupBox27: TGroupBox
            Left = 111
            Top = 0
            Width = 110
            Height = 175
            Caption = 'Punto 2'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 1
            object Label36: TLabel
              Left = 7
              Top = 17
              Width = 51
              Height = 13
              Caption = 'Dist.  [Km]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label37: TLabel
              Left = 7
              Top = 36
              Width = 42
              Height = 13
              Caption = 'Acim. ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label38: TLabel
              Left = 7
              Top = 55
              Width = 46
              Height = 13
              Caption = 'Elev.   ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label39: TLabel
              Left = 7
              Top = 75
              Width = 44
              Height = 13
              Caption = 'Pot. [dB]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label40: TLabel
              Left = 6
              Top = 93
              Width = 26
              Height = 13
              Caption = 'Hora:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label41: TLabel
              Left = 5
              Top = 133
              Width = 33
              Height = 13
              Caption = 'Fecha:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Edit49: TEdit
              Left = 68
              Top = 15
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 0
              Text = '50'
            end
            object Edit50: TEdit
              Left = 68
              Top = 35
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 1
              Text = '10'
            end
            object Edit51: TEdit
              Left = 68
              Top = 55
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 2
              Text = '1'
            end
            object Edit52: TEdit
              Left = 68
              Top = 75
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 3
              Text = '10'
            end
            object DateTimePicker3: TDateTimePicker
              Left = 6
              Top = 109
              Width = 98
              Height = 20
              Date = 37383.486365740700000000
              Time = 37383.486365740700000000
              Kind = dtkTime
              TabOrder = 4
            end
            object DateTimePicker4: TDateTimePicker
              Left = 6
              Top = 148
              Width = 98
              Height = 20
              Date = 37383.491226898100000000
              Time = 37383.491226898100000000
              TabOrder = 5
            end
          end
        end
        object TabSheet12: TTabSheet
          Caption = 'Resoluci'#243'n tangencial'
          ImageIndex = 4
          object GroupBox28: TGroupBox
            Left = 0
            Top = 0
            Width = 110
            Height = 175
            Caption = 'Punto 1'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 0
            object Label42: TLabel
              Left = 7
              Top = 17
              Width = 48
              Height = 13
              Caption = 'Dist. [Km]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label43: TLabel
              Left = 7
              Top = 36
              Width = 42
              Height = 13
              Caption = 'Acim. ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label44: TLabel
              Left = 7
              Top = 55
              Width = 46
              Height = 13
              Caption = 'Elev.   ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label45: TLabel
              Left = 7
              Top = 75
              Width = 44
              Height = 13
              Caption = 'Pot. [dB]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label46: TLabel
              Left = 6
              Top = 93
              Width = 26
              Height = 13
              Caption = 'Hora:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label47: TLabel
              Left = 5
              Top = 133
              Width = 33
              Height = 13
              Caption = 'Fecha:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Edit53: TEdit
              Left = 68
              Top = 15
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 0
              Text = '50'
            end
            object Edit54: TEdit
              Left = 68
              Top = 35
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 1
              Text = '10'
            end
            object Edit55: TEdit
              Left = 68
              Top = 55
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 2
              Text = '1'
            end
            object Edit56: TEdit
              Left = 68
              Top = 75
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 3
              Text = '10'
            end
            object DateTimePicker5: TDateTimePicker
              Left = 6
              Top = 109
              Width = 98
              Height = 20
              Date = 37383.486365740700000000
              Time = 37383.486365740700000000
              Kind = dtkTime
              TabOrder = 4
            end
            object DateTimePicker6: TDateTimePicker
              Left = 6
              Top = 148
              Width = 98
              Height = 20
              Date = 37383.491226898100000000
              Time = 37383.491226898100000000
              TabOrder = 5
            end
          end
          object GroupBox29: TGroupBox
            Left = 111
            Top = 0
            Width = 110
            Height = 175
            Caption = 'Punto 2'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 1
            object Label48: TLabel
              Left = 7
              Top = 17
              Width = 51
              Height = 13
              Caption = 'Dist.  [Km]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label49: TLabel
              Left = 7
              Top = 36
              Width = 42
              Height = 13
              Caption = 'Acim. ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label50: TLabel
              Left = 7
              Top = 55
              Width = 46
              Height = 13
              Caption = 'Elev.   ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label51: TLabel
              Left = 7
              Top = 75
              Width = 44
              Height = 13
              Caption = 'Pot. [dB]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label52: TLabel
              Left = 6
              Top = 93
              Width = 26
              Height = 13
              Caption = 'Hora:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label53: TLabel
              Left = 5
              Top = 133
              Width = 33
              Height = 13
              Caption = 'Fecha:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Edit57: TEdit
              Left = 68
              Top = 15
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 0
              Text = '50'
            end
            object Edit58: TEdit
              Left = 68
              Top = 35
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 1
              Text = '10'
            end
            object Edit59: TEdit
              Left = 68
              Top = 55
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 2
              Text = '1'
            end
            object Edit60: TEdit
              Left = 68
              Top = 75
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 3
              Text = '10'
            end
            object DateTimePicker7: TDateTimePicker
              Left = 6
              Top = 109
              Width = 98
              Height = 20
              Date = 37383.486365740700000000
              Time = 37383.486365740700000000
              Kind = dtkTime
              TabOrder = 4
            end
            object DateTimePicker8: TDateTimePicker
              Left = 6
              Top = 148
              Width = 98
              Height = 20
              Date = 37383.491226898100000000
              Time = 37383.491226898100000000
              TabOrder = 5
            end
          end
          object GroupBox30: TGroupBox
            Left = 0
            Top = 176
            Width = 233
            Height = 41
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 2
            object Label55: TLabel
              Left = 4
              Top = 13
              Width = 158
              Height = 13
              Caption = 'Ancho del haz (a -3 dB)   [grados]'
            end
            object Edit62: TEdit
              Left = 181
              Top = 11
              Width = 35
              Height = 18
              Constraints.MaxHeight = 18
              TabOrder = 0
            end
          end
        end
        object TabSheet13: TTabSheet
          Caption = 'Movimiento del eco'
          ImageIndex = 5
          object GroupBox31: TGroupBox
            Left = 0
            Top = 0
            Width = 110
            Height = 175
            Caption = 'Punto 1'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 0
            object Label54: TLabel
              Left = 7
              Top = 17
              Width = 48
              Height = 13
              Caption = 'Dist. [Km]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label56: TLabel
              Left = 7
              Top = 36
              Width = 42
              Height = 13
              Caption = 'Acim. ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label57: TLabel
              Left = 7
              Top = 55
              Width = 46
              Height = 13
              Caption = 'Elev.   ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label58: TLabel
              Left = 7
              Top = 75
              Width = 44
              Height = 13
              Caption = 'Pot. [dB]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label59: TLabel
              Left = 6
              Top = 93
              Width = 26
              Height = 13
              Caption = 'Hora:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label60: TLabel
              Left = 5
              Top = 133
              Width = 33
              Height = 13
              Caption = 'Fecha:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Edit61: TEdit
              Left = 68
              Top = 15
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 0
              Text = '50'
            end
            object Edit63: TEdit
              Left = 68
              Top = 35
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 1
              Text = '10'
            end
            object Edit64: TEdit
              Left = 68
              Top = 55
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 2
              Text = '1'
            end
            object Edit65: TEdit
              Left = 68
              Top = 75
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 3
              Text = '10'
            end
            object DateTimePicker9: TDateTimePicker
              Left = 6
              Top = 109
              Width = 98
              Height = 20
              Date = 37383.486365740700000000
              Time = 37383.486365740700000000
              Kind = dtkTime
              TabOrder = 4
            end
            object DateTimePicker10: TDateTimePicker
              Left = 6
              Top = 148
              Width = 98
              Height = 20
              Date = 37383.491226898100000000
              Time = 37383.491226898100000000
              TabOrder = 5
            end
          end
          object GroupBox32: TGroupBox
            Left = 111
            Top = 0
            Width = 110
            Height = 175
            Caption = 'Punto 2'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 1
            object Label61: TLabel
              Left = 7
              Top = 17
              Width = 51
              Height = 13
              Caption = 'Dist.  [Km]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label62: TLabel
              Left = 7
              Top = 36
              Width = 42
              Height = 13
              Caption = 'Acim. ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label63: TLabel
              Left = 7
              Top = 55
              Width = 46
              Height = 13
              Caption = 'Elev.   ['#176']:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label64: TLabel
              Left = 7
              Top = 75
              Width = 44
              Height = 13
              Caption = 'Pot. [dB]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label65: TLabel
              Left = 6
              Top = 93
              Width = 26
              Height = 13
              Caption = 'Hora:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Label66: TLabel
              Left = 5
              Top = 133
              Width = 33
              Height = 13
              Caption = 'Fecha:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object Edit66: TEdit
              Left = 68
              Top = 15
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 0
              Text = '50'
            end
            object Edit67: TEdit
              Left = 68
              Top = 35
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 1
              Text = '10'
            end
            object Edit68: TEdit
              Left = 68
              Top = 55
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 2
              Text = '1'
            end
            object Edit69: TEdit
              Left = 68
              Top = 75
              Width = 35
              Height = 16
              AutoSize = False
              TabOrder = 3
              Text = '10'
            end
            object DateTimePicker11: TDateTimePicker
              Left = 6
              Top = 109
              Width = 98
              Height = 20
              Date = 37383.486365740700000000
              Time = 37383.486365740700000000
              Kind = dtkTime
              TabOrder = 4
            end
            object DateTimePicker12: TDateTimePicker
              Left = 6
              Top = 148
              Width = 98
              Height = 20
              Date = 37383.491226898100000000
              Time = 37383.491226898100000000
              TabOrder = 5
            end
          end
        end
        object TabSheet14: TTabSheet
          Caption = 'Acimut y distancia'
          ImageIndex = 6
          object GroupBoxStation: TGroupBox
            Left = 7
            Top = 46
            Width = 150
            Height = 100
            Caption = 'Coordenadas de la Estaci'#243'n'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 0
            object LabelLatitud: TLabel
              Left = 11
              Top = 22
              Width = 88
              Height = 13
              Caption = 'Latitud     [grados]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object LabelLongitud: TLabel
              Left = 11
              Top = 47
              Width = 88
              Height = 13
              Caption = 'Longitud  [grados]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object LabelHeight: TLabel
              Left = 11
              Top = 72
              Width = 86
              Height = 13
              Caption = 'Altura              [m]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object EditLatitud: TEdit
              Left = 107
              Top = 19
              Width = 35
              Height = 18
              AutoSize = False
              TabOrder = 0
            end
            object EditLongitud: TEdit
              Left = 107
              Top = 45
              Width = 35
              Height = 18
              AutoSize = False
              TabOrder = 1
            end
            object EditHeight: TEdit
              Left = 107
              Top = 70
              Width = 35
              Height = 18
              AutoSize = False
              TabOrder = 2
            end
          end
          object GroupBoxPoint: TGroupBox
            Left = 165
            Top = 46
            Width = 151
            Height = 100
            Caption = 'Coordenadas del Punto 3'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentFont = False
            TabOrder = 1
            object LabelLatitud3: TLabel
              Left = 11
              Top = 22
              Width = 88
              Height = 13
              Caption = 'Latitud     [grados]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object LabelLongitud3: TLabel
              Left = 11
              Top = 47
              Width = 88
              Height = 13
              Caption = 'Longitud  [grados]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object LabelHeight3: TLabel
              Left = 11
              Top = 72
              Width = 86
              Height = 13
              Caption = 'Altura              [m]:'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'MS Sans Serif'
              Font.Style = []
              ParentFont = False
            end
            object EditLatitud3: TEdit
              Left = 107
              Top = 19
              Width = 35
              Height = 18
              AutoSize = False
              TabOrder = 0
            end
            object EditLongitud3: TEdit
              Left = 107
              Top = 45
              Width = 35
              Height = 18
              AutoSize = False
              TabOrder = 1
            end
            object EditHeight3: TEdit
              Left = 107
              Top = 70
              Width = 35
              Height = 18
              AutoSize = False
              TabOrder = 2
            end
          end
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Conversi'#243'n de Unidades'
      ImageIndex = 1
    end
  end
end
