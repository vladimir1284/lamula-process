object FCalPot: TFCalPot
  Left = 168
  Top = 71
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Calcular Potencial Meteorol'#243'gico'
  ClientHeight = 291
  ClientWidth = 436
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  Visible = True
  OnCanResize = FormCanResize
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 436
    Height = 41
    Align = alTop
    Caption = 'Cargar datos nominales de una estaci'#243'n'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    object Label1: TLabel
      Left = 9
      Top = 18
      Width = 41
      Height = 13
      Caption = 'Estaci'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object ComboBox1: TComboBox
      Left = 54
      Top = 15
      Width = 177
      Height = 21
      Hint = 
        'Carga una Estaci'#243'n | Carga el nombre, las coordenadas y tipo de ' +
        'radar de una estaci'#243'n'
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 13
      ItemIndex = 4
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      Text = 'Loma La Mula (Camag'#252'ey)'
      OnChange = ComboBox1Change
      Items.Strings = (
        'La Bajada (Pinar del Rio)'
        'Punta del Este (Isla de la  Juventud)'
        'Casablanca (Ciudad de La Habana)'
        'Pico San Juan (Cienfuegos)'
        'Loma La Mula (Camag'#252'ey)'
        'Pil'#243'n  (Granma)'
        'Gran Piedra (Santiago de Cuba)')
    end
  end
  object GroupBox5: TGroupBox
    Left = 0
    Top = 41
    Width = 436
    Height = 128
    Align = alTop
    Caption = 'Datos del Transmisor'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object RadioGroup1: TRadioGroup
      Left = 2
      Top = 11
      Width = 212
      Height = 56
      Hint = 'Teclee la Frecuencia o la Longitud de Onda.'
      Caption = 'Transmisi'#243'n'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemIndex = 0
      Items.Strings = (
        'Frecuencia [MHz]'
        'Longitud de onda [cm]')
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = RadioGroup1Click
    end
    object RadioGroup2: TRadioGroup
      Tag = 2
      Left = 215
      Top = 11
      Width = 217
      Height = 56
      Hint = 'Teclee la Frecuencia o el Periodo de Repetici'#243'n de los Pulsos.'
      Caption = 'Recurrencia'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemIndex = 0
      Items.Strings = (
        'Frecuencia de Repetici'#243'n [Hz]'
        'Per'#237'odo de Repetici'#243'n [miliseg]')
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = RadioGroup2Click
    end
    object RadioGroup3: TRadioGroup
      Tag = 3
      Left = 3
      Top = 67
      Width = 212
      Height = 56
      Hint = 'Teclee la Potencia Pico o la Potencia Promedio.'
      Caption = 'Potencia'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemIndex = 0
      Items.Strings = (
        'Pico, o prom. en el pulso [kW]'
        'Promedio en el per'#237'odo [W]')
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      OnClick = RadioGroup3Click
    end
    object RadioGroup4: TRadioGroup
      Tag = 1
      Left = 216
      Top = 67
      Width = 216
      Height = 56
      Hint = 'Teclee la Duraci'#243'n o la Extensi'#243'n del Pulso.'
      Caption = 'Pulso'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemIndex = 0
      Items.Strings = (
        'Duraci'#243'n del Pulso [microseg]'
        'Extensi'#243'n del Pulso [m]')
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = RadioGroup4Click
    end
    object Edit5: TEdit
      Left = 175
      Top = 80
      Width = 35
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnChange = Edit5Change
    end
    object Edit6: TEdit
      Left = 175
      Top = 100
      Width = 35
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnChange = Edit6Change
    end
    object Edit1: TEdit
      Left = 175
      Top = 24
      Width = 35
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnChange = Edit1Change
    end
    object Edit2: TEdit
      Left = 175
      Top = 44
      Width = 35
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnChange = Edit2Change
    end
    object Edit3: TEdit
      Left = 394
      Top = 24
      Width = 35
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnChange = Edit3Change
    end
    object Edit4: TEdit
      Left = 394
      Top = 44
      Width = 35
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
      OnChange = Edit4Change
    end
    object Edit7: TEdit
      Left = 394
      Top = 80
      Width = 35
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 10
      OnChange = Edit7Change
    end
    object Edit8: TEdit
      Left = 394
      Top = 100
      Width = 35
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 11
      OnChange = Edit8Change
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 243
    Width = 436
    Height = 48
    Align = alClient
    Caption = 'Resultado'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object Label2: TLabel
      Left = 16
      Top = 21
      Width = 195
      Height = 13
      Caption = 'Potencial meteorol'#243'gico del radar:'
    end
    object Label3: TLabel
      Left = 286
      Top = 22
      Width = 16
      Height = 13
      Caption = 'dB'
    end
    object Edit15: TEdit
      Left = 214
      Top = 18
      Width = 66
      Height = 21
      ReadOnly = True
      TabOrder = 0
      Text = 'Edit15'
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 169
    Width = 436
    Height = 74
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object GroupBox10: TGroupBox
      Left = 0
      Top = 0
      Width = 215
      Height = 74
      Caption = 'Datos de la Antena'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      object Label13: TLabel
        Left = 6
        Top = 15
        Width = 130
        Height = 13
        Caption = 'Ganancia  de potencia [dB]'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label14: TLabel
        Left = 6
        Top = 33
        Width = 152
        Height = 13
        Caption = 'Ancho del haz (a -3 dB) [grados]'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label15: TLabel
        Left = 6
        Top = 52
        Width = 166
        Height = 13
        Caption = 'P'#233'rdidas en las gu'#237'as de onda [dB]'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Edit12: TEdit
        Left = 175
        Top = 11
        Width = 35
        Height = 18
        Constraints.MaxHeight = 18
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnChange = Edit9Change
      end
      object Edit13: TEdit
        Left = 175
        Top = 31
        Width = 35
        Height = 18
        Constraints.MaxHeight = 18
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnChange = Edit9Change
      end
      object Edit14: TEdit
        Left = 175
        Top = 51
        Width = 35
        Height = 18
        Constraints.MaxHeight = 18
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnChange = Edit9Change
      end
    end
    object GroupBox6: TGroupBox
      Left = 216
      Top = 0
      Width = 219
      Height = 74
      Caption = 'Datos del Receptor'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      object Label11: TLabel
        Left = 7
        Top = 16
        Width = 157
        Height = 13
        Caption = 'Ancho de Banda  (a -6 dB) [MHz]'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        ParentShowHint = False
        ShowHint = False
      end
      object LabelMinDiscSignal: TLabel
        Left = 6
        Top = 34
        Width = 153
        Height = 13
        Caption = 'Se'#241'al M'#237'nima Discernible  [dBm]'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Edit10: TEdit
        Left = 179
        Top = 13
        Width = 35
        Height = 18
        Constraints.MaxHeight = 18
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnChange = Edit9Change
      end
      object Edit9: TEdit
        Left = 179
        Top = 33
        Width = 35
        Height = 18
        Constraints.MaxHeight = 18
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnChange = Edit9Change
      end
    end
  end
end
