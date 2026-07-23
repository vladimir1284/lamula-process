object FTXTReport: TFTXTReport
  Left = 221
  Top = 192
  Width = 435
  Height = 300
  Caption = 'Reporte [TXT]'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsMDIChild
  Menu = MainMenu1
  OldCreateOrder = True
  Position = poDefault
  Visible = True
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 427
    Height = 254
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object MainMenu1: TMainMenu
    Left = 5
    Top = 5
    object Reporte1: TMenuItem
      Caption = '&Reporte'
      GroupIndex = 2
      object Salvar1: TMenuItem
        Caption = '&Salvar...'
        ShortCut = 113
        OnClick = Salvar1Click
      end
      object Copiar1: TMenuItem
        Caption = 'Copiar'
        OnClick = Copiar1Click
      end
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'txt'
    Filter = 'Reportes|*.txt'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
    Title = 'Salvar Reporte'
    Left = 395
    Top = 5
  end
end
