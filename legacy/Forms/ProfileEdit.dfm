inherited FProfileEdit: TFProfileEdit
  Caption = 'Editar perfil'
  PixelsPerInch = 96
  TextHeight = 13
  inherited PageControl1: TPageControl
    ActivePage = TabSheet2
    TabIndex = 1
    inherited TabSheet2: TTabSheet
      Caption = 'Punto'
      inherited Label7: TLabel
        Width = 10
        Caption = '&X:'
      end
      inherited Label9: TLabel
        Width = 10
        Caption = '&Y:'
      end
      inherited Label8: TLabel
        Width = 3
        Caption = ''
        Enabled = False
      end
      inherited Label10: TLabel
        Width = 3
        Caption = ''
        Enabled = False
      end
      inherited Label13: TLabel
        Enabled = False
      end
      inherited Label11: TLabel
        Enabled = False
      end
      inherited Area1: TArea
        Style = asPoint
      end
      inherited Edit5: TEdit
        Enabled = False
      end
      inherited Edit6: TEdit
        Enabled = False
      end
      inherited UpDown6: TUpDown
        Enabled = False
      end
      inherited UpDown7: TUpDown
        Enabled = False
      end
      inherited Edit8: TEdit
        Enabled = False
      end
      inherited UpDown8: TUpDown
        Enabled = False
      end
      inherited Edit9: TEdit
        Enabled = False
      end
      inherited UpDown1: TUpDown
        Enabled = False
      end
    end
  end
end
