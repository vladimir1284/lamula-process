object FRTFReport: TFRTFReport
  Left = 279
  Top = 175
  Width = 435
  Height = 300
  Caption = 'Reporte [RTF]'
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
  object RichEdit1: TRichEdit
    Left = 0
    Top = 0
    Width = 427
    Height = 246
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 0
    WantTabs = True
    WordWrap = False
  end
  object MainMenu1: TMainMenu
    object Reporte1: TMenuItem
      Caption = '&Reporte'
      GroupIndex = 2
      object Salvar1: TMenuItem
        Caption = '&Salvar...'
        ShortCut = 113
        OnClick = Salvar1Click
      end
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'rtf'
    Filter = 'Reportes|*.rtf'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
    Title = 'Salvar Reporte'
    Left = 400
  end
end
