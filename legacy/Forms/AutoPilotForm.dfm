object FAutoPilot: TFAutoPilot
  Left = 403
  Top = 190
  BorderStyle = bsDialog
  Caption = 'Configuraci'#243'n del Piloto Autom'#225'tico'
  ClientHeight = 358
  ClientWidth = 370
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 1
    Top = 40
    Width = 369
    Height = 286
    Caption = 'Tareas'
    TabOrder = 0
    object Label3: TLabel
      Left = 8
      Top = 211
      Width = 126
      Height = 13
      Caption = 'Carpeta de Observaciones'
    end
    object SpeedButton1: TSpeedButton
      Left = 336
      Top = 227
      Width = 23
      Height = 22
      Glyph.Data = {
        36030000424D3603000000000000360000002800000010000000100000000100
        1800000000000003000000000000000000000000000000000000FF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF000000
        0000000000000000000000000000000000000000000000000000000000000000
        00000000000000FF00FF84848484848484848484848484848484848484848484
        8484848484848484848484848484848484848484000000FF00FF848484FFFFFF
        00FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FF
        FF848484000000FF00FF848484FFFFFFC6C6C600FFFFC6C6C600FFFFC6C6C600
        FFFFC6C6C600FFFFC6C6C600FFFFC6C6C6848484000000FF00FF848484FFFFFF
        00FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FF
        FF848484000000FF00FF848484FFFFFFC6C6C600FFFFC6C6C600FFFFC6C6C600
        FFFFC6C6C600FFFFC6C6C600FFFFC6C6C6848484000000FF00FF848484FFFFFF
        00FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FF
        FF848484000000FF00FF848484FFFFFFC6C6C600FFFFC6C6C600FFFFC6C6C600
        FFFFC6C6C600FFFFC6C6C600FFFFC6C6C6848484000000FF00FF848484FFFFFF
        00FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FFFFC6C6C600FF
        FF848484000000FF00FF848484FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF848484000000FF00FF848484C6C6C6
        00FFFFC6C6C600FFFFC6C6C600FFFFC6C6C68484848484848484848484848484
        84848484FF00FFFF00FFFF00FF848484C6C6C600FFFFC6C6C600FFFFC6C6C684
        8484FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        848484848484848484848484848484FF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF}
      OnClick = SpeedButton1Click
    end
    object Label2: TLabel
      Left = 232
      Top = 258
      Width = 76
      Height = 13
      Caption = 'horas de atraso.'
    end
    object ListBox1: TCheckListBox
      Left = 10
      Top = 15
      Width = 103
      Height = 186
      Enabled = False
      ItemHeight = 13
      Items.Strings = (
        'Tarea 1')
      TabOrder = 0
      OnClick = ListBox1Click
    end
    object GroupBox2: TGroupBox
      Left = 120
      Top = 8
      Width = 113
      Height = 193
      Caption = 'Productos'
      TabOrder = 1
      object CheckListBox1: TCheckListBox
        Left = 8
        Top = 16
        Width = 97
        Height = 169
        OnClickCheck = CheckListBox1ClickCheck
        ItemHeight = 13
        TabOrder = 0
        OnDblClick = CheckListBox1DblClick
      end
    end
    object Edit2: TEdit
      Left = 8
      Top = 227
      Width = 323
      Height = 21
      TabOrder = 2
      Text = 'Edit2'
      OnChange = CheckListBox1ClickCheck
    end
    object GroupBox4: TGroupBox
      Left = 240
      Top = 8
      Width = 121
      Height = 193
      Caption = 'Animaci'#243'n'
      TabOrder = 3
      object CheckListBox2: TCheckListBox
        Left = 2
        Top = 16
        Width = 111
        Height = 169
        OnClickCheck = CheckListBox1ClickCheck
        ItemHeight = 13
        TabOrder = 0
        OnDblClick = CheckListBox2DblClick
      end
    end
    object SpinEdit1: TSpinEdit
      Left = 156
      Top = 254
      Width = 70
      Height = 22
      MaxValue = 99999999
      MinValue = 0
      TabOrder = 4
      Value = 0
    end
    object CheckBox1: TCheckBox
      Left = 9
      Top = 256
      Width = 145
      Height = 17
      Caption = 'Mover observaciones con:'
      TabOrder = 5
    end
  end
  object Button1: TButton
    Left = 292
    Top = 329
    Width = 75
    Height = 25
    Caption = 'Aceptar'
    ModalResult = 1
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 212
    Top = 329
    Width = 75
    Height = 25
    Caption = 'Cancelar'
    ModalResult = 2
    TabOrder = 2
  end
  object Button3: TButton
    Left = 8
    Top = 8
    Width = 121
    Height = 25
    Caption = 'Procesar ahora'
    TabOrder = 3
    OnClick = Button3Click
  end
  object GroupBox5: TGroupBox
    Left = 248
    Top = 0
    Width = 121
    Height = 42
    Caption = 'Productos'
    TabOrder = 4
    Visible = False
    object CheckListBox3: TCheckListBox
      Left = 2
      Top = 16
      Width = 111
      Height = 20
      OnClickCheck = CheckListBox1ClickCheck
      ItemHeight = 13
      Items.Strings = (
        'Acumulado')
      TabOrder = 0
      OnDblClick = CheckListBox3DblClick
    end
  end
end
