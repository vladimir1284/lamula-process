object FCalRef: TFCalRef
  Left = 380
  Top = 186
  BorderStyle = bsDialog
  Caption = 'Calcular Reflectividad'
  ClientHeight = 151
  ClientWidth = 268
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCanResize = FormCanResize
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 268
    Height = 105
    Align = alTop
    Caption = 'Datos'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object Label2: TLabel
      Left = 6
      Top = 60
      Width = 105
      Height = 13
      Caption = 'Distancia del eco [km]'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label3: TLabel
      Left = 6
      Top = 79
      Width = 104
      Height = 13
      Caption = 'Potencia recibida [dB]'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object GroupBox2: TGroupBox
      Left = 3
      Top = 13
      Width = 262
      Height = 41
      Caption = 'Potencial Meteorol'#243'gico'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      object Label1: TLabel
        Left = 49
        Top = 18
        Width = 72
        Height = 13
        Caption = '[dB]    Estaci'#243'n'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object ComboBox1: TComboBox
        Left = 126
        Top = 14
        Width = 132
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
      object Edit1: TEdit
        Left = 5
        Top = 16
        Width = 41
        Height = 18
        Constraints.MaxHeight = 18
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnChange = Edit1Change
      end
    end
    object Edit2: TEdit
      Left = 119
      Top = 58
      Width = 41
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Text = '50'
      OnChange = Edit1Change
    end
    object Edit3: TEdit
      Left = 119
      Top = 77
      Width = 41
      Height = 18
      Constraints.MaxHeight = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      Text = '0'
      OnChange = Edit1Change
    end
  end
  object GroupBox3: TGroupBox
    Left = 0
    Top = 105
    Width = 268
    Height = 46
    Align = alClient
    Caption = 'Resultado'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object Label4: TLabel
      Left = 9
      Top = 20
      Width = 126
      Height = 13
      Caption = 'Reflectividad del eco:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 233
      Top = 19
      Width = 24
      Height = 13
      Caption = 'dBZ'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Edit4: TEdit
      Left = 138
      Top = 17
      Width = 90
      Height = 21
      ReadOnly = True
      TabOrder = 0
      Text = 'Edit4'
    end
  end
end
