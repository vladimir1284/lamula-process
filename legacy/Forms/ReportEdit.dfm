object FReportEdit: TFReportEdit
  Left = 237
  Top = 162
  Width = 316
  Height = 360
  HorzScrollBar.Visible = False
  VertScrollBar.Visible = False
  Caption = 'Reporte'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 5
    Top = 7
    Width = 300
    Height = 282
    ActivePage = TabSheet1
    TabOrder = 0
    object TabSheet2: TTabSheet
      Caption = 'Areas'
      object TreeView1: TTreeView
        Left = 9
        Top = 10
        Width = 275
        Height = 236
        Indent = 19
        TabOrder = 0
        OnMouseDown = TreeView1MouseDown
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Incluir'
      object CheckBox1: TCheckBox
        Left = 24
        Top = 13
        Width = 249
        Height = 17
        Caption = #193'rea de la Regi'#243'n (km'#178')'
        TabOrder = 0
      end
      object CheckBox2: TCheckBox
        Left = 24
        Top = 39
        Width = 249
        Height = 17
        Caption = #193'rea cubierta (%)'
        Checked = True
        State = cbChecked
        TabOrder = 1
      end
      object CheckBox3: TCheckBox
        Left = 24
        Top = 65
        Width = 249
        Height = 17
        Caption = 'Promedio en la Regi'#243'n '
        Checked = True
        State = cbChecked
        TabOrder = 2
      end
      object CheckBox4: TCheckBox
        Left = 24
        Top = 91
        Width = 249
        Height = 17
        Caption = 'M'#225'ximo '
        Checked = True
        State = cbChecked
        TabOrder = 3
      end
      object CheckBox5: TCheckBox
        Left = 24
        Top = 117
        Width = 249
        Height = 17
        Caption = 'M'#237'nimo '
        TabOrder = 4
      end
      object CheckBox6: TCheckBox
        Left = 24
        Top = 142
        Width = 249
        Height = 17
        Caption = 'Promedio en el '#225'rea cubierta '
        Checked = True
        State = cbChecked
        TabOrder = 5
      end
      object CheckBox7: TCheckBox
        Left = 24
        Top = 168
        Width = 249
        Height = 17
        Caption = 'Mediana '
        TabOrder = 6
      end
      object CheckBox8: TCheckBox
        Left = 24
        Top = 196
        Width = 249
        Height = 17
        Caption = 'Volumen (Mill. m'#179')'
        TabOrder = 7
      end
      object CheckBox9: TCheckBox
        Left = 24
        Top = 221
        Width = 249
        Height = 17
        Caption = 'Desviacion st'#225'ndar '
        Checked = True
        State = cbChecked
        TabOrder = 8
      end
    end
    object TabSheet1: TTabSheet
      Caption = 'General'
      object Label1: TLabel
        Left = 135
        Top = 140
        Width = 36
        Height = 13
        Caption = '&Umbral:'
        FocusControl = Edit1
      end
      object Edit1: TEdit
        Left = 185
        Top = 135
        Width = 80
        Height = 21
        TabStop = False
        Enabled = False
        ReadOnly = True
        TabOrder = 1
        Text = '0'
      end
      object UpDown1: TUpDown
        Left = 265
        Top = 135
        Width = 14
        Height = 21
        Max = 250
        TabOrder = 2
        TabStop = True
        Thousands = False
        Wrap = True
        OnClick = UpDown1Click
      end
      object GroupBox1: TGroupBox
        Left = 10
        Top = 10
        Width = 270
        Height = 105
        Caption = '&Editor'
        TabOrder = 0
        object CheckBox10: TCheckBox
          Left = 15
          Top = 49
          Width = 100
          Height = 17
          Caption = 'Microsoft &Word'
          TabOrder = 0
          Visible = False
        end
        object CheckBox11: TCheckBox
          Left = 15
          Top = 26
          Width = 100
          Height = 17
          Caption = 'Editor de &RTF'
          Checked = True
          State = cbChecked
          TabOrder = 1
        end
        object CheckBox12: TCheckBox
          Left = 15
          Top = 75
          Width = 100
          Height = 17
          Caption = '&Texto simple'
          TabOrder = 2
          Visible = False
        end
      end
    end
  end
  object Button1: TButton
    Left = 150
    Top = 296
    Width = 75
    Height = 24
    Caption = '&Crear'
    Default = True
    ModalResult = 1
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 230
    Top = 296
    Width = 75
    Height = 24
    Cancel = True
    Caption = 'Cancelar'
    ModalResult = 2
    TabOrder = 2
  end
end
