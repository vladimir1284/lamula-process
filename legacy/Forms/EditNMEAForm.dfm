object FEditNMEA: TFEditNMEA
  Left = 477
  Top = 205
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Reconstrucci'#243'n de Trayectoria'
  ClientHeight = 120
  ClientWidth = 403
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 7
    Top = 14
    Width = 30
    Height = 13
    Caption = 'Avi'#243'n:'
  end
  object Label2: TLabel
    Left = 93
    Top = 14
    Width = 56
    Height = 13
    Caption = 'Trayectoria:'
  end
  object GroupBox3: TGroupBox
    Left = 1
    Top = 35
    Width = 200
    Height = 82
    Caption = 'Inicio'
    TabOrder = 0
    object Label3: TLabel
      Left = 8
      Top = 56
      Width = 26
      Height = 13
      Caption = 'Hora:'
    end
    object TrackBar1: TTrackBar
      Left = 2
      Top = 15
      Width = 196
      Height = 29
      Align = alTop
      Frequency = 2
      TabOrder = 0
      OnChange = TrackBar1Change
    end
    object DateTimePicker2: TDateTimePicker
      Left = 41
      Top = 53
      Width = 89
      Height = 21
      Date = 39321.687986111110000000
      Time = 39321.687986111110000000
      Kind = dtkTime
      TabOrder = 1
    end
  end
  object GroupBox2: TGroupBox
    Left = 201
    Top = 35
    Width = 200
    Height = 82
    Caption = 'Final'
    TabOrder = 1
    object Label4: TLabel
      Left = 8
      Top = 56
      Width = 26
      Height = 13
      Caption = 'Hora:'
    end
    object TrackBar2: TTrackBar
      Left = 2
      Top = 15
      Width = 196
      Height = 29
      Align = alTop
      Frequency = 2
      TabOrder = 0
      OnChange = TrackBar1Change
    end
    object DateTimePicker4: TDateTimePicker
      Left = 41
      Top = 53
      Width = 89
      Height = 21
      Date = 39321.687986111110000000
      Time = 39321.687986111110000000
      Kind = dtkTime
      TabOrder = 1
    end
  end
  object Panel2: TPanel
    Left = 154
    Top = 6
    Width = 42
    Height = 30
    BorderStyle = bsSingle
    Caption = 'Color'
    Color = clFuchsia
    TabOrder = 2
    OnClick = Panel2Click
  end
  object Panel1: TPanel
    Left = 40
    Top = 6
    Width = 42
    Height = 30
    BorderStyle = bsSingle
    Caption = 'Color'
    Color = clMoneyGreen
    TabOrder = 3
    OnClick = Panel1Click
  end
  object Button1: TButton
    Left = 222
    Top = 7
    Width = 176
    Height = 25
    Caption = 'Recargar archivo Res'
    TabOrder = 4
    OnClick = Button1Click
  end
  object ColorDialog1: TColorDialog
    Left = 369
    Top = 84
  end
end
