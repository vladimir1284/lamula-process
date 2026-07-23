object FCalAcmDis: TFCalAcmDis
  Left = 218
  Top = 142
  BorderStyle = bsDialog
  Caption = 'Calcular acimut y distancia'
  ClientHeight = 231
  ClientWidth = 215
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 215
    Height = 164
    Align = alTop
    Caption = 'Datos'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object GroupBox2: TGroupBox
      Left = 2
      Top = 15
      Width = 211
      Height = 84
      Align = alTop
      Caption = 'Coordenadas del radar'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      object Label1: TLabel
        Left = 6
        Top = 39
        Width = 73
        Height = 13
        Caption = 'Latitud [grados]'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label6: TLabel
        Left = 6
        Top = 60
        Width = 82
        Height = 13
        Caption = 'Longitud [grados]'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label7: TLabel
        Left = 6
        Top = 19
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
        Left = 98
        Top = 16
        Width = 106
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
        Left = 98
        Top = 39
        Width = 61
        Height = 18
        Constraints.MaxHeight = 18
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        Text = '10'
        OnChange = Edit1Change
      end
      object Edit2: TEdit
        Left = 98
        Top = 58
        Width = 61
        Height = 18
        Constraints.MaxHeight = 18
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        Text = '10'
        OnChange = Edit1Change
      end
    end
    object GroupBox4: TGroupBox
      Left = 2
      Top = 99
      Width = 211
      Height = 63
      Align = alClient
      Caption = 'Coordenadas del punto'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      object Label8: TLabel
        Left = 6
        Top = 18
        Width = 73
        Height = 13
        Caption = 'Latitud [grados]'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label9: TLabel
        Left = 6
        Top = 39
        Width = 82
        Height = 13
        Caption = 'Longitud [grados]'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Edit6: TEdit
        Left = 98
        Top = 18
        Width = 61
        Height = 18
        Constraints.MaxHeight = 18
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        Text = '21'
        OnChange = Edit1Change
      end
      object Edit7: TEdit
        Left = 98
        Top = 37
        Width = 61
        Height = 18
        Constraints.MaxHeight = 18
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        Text = '77'
        OnChange = Edit1Change
      end
    end
  end
  object GroupBox3: TGroupBox
    Left = 0
    Top = 164
    Width = 215
    Height = 67
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
      Width = 43
      Height = 13
      Caption = 'Acimut:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 163
      Top = 19
      Width = 39
      Height = 13
      Caption = 'grados'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 9
      Top = 42
      Width = 58
      Height = 13
      Caption = 'Distancia:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 163
      Top = 41
      Width = 17
      Height = 13
      Caption = 'km'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Edit4: TEdit
      Left = 68
      Top = 17
      Width = 90
      Height = 21
      ReadOnly = True
      TabOrder = 0
    end
    object Edit5: TEdit
      Left = 68
      Top = 39
      Width = 90
      Height = 21
      ReadOnly = True
      TabOrder = 1
    end
  end
end
