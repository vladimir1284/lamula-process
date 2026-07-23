unit SettingsForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, Buttons, FileCtrl;

const
  TimeSpanKey    = 'VestaTimespan';
  EnsembleKey    = 'VestaEnsemble';
  ObservationKey = 'VestaObservation';
  ProductKey     = 'VestaProduct';
  AnimationKey   = 'VestaAnimation';

type
  TFSettings = class(TForm)
    Button1: TButton;
    TabSheet3: TTabSheet;
    Label20: TLabel;
    Edit20: TEdit;
    Label21: TLabel;
    Edit21: TEdit;
    Label22: TLabel;
    Edit22: TEdit;
    Label23: TLabel;
    Edit23: TEdit;
    Label24: TLabel;
    Edit24: TEdit;
    Label25: TLabel;
    Edit25: TEdit;
    TabSheet2: TTabSheet;
    Button2: TButton;
    TabSheet1: TTabSheet;
    GroupBox1: TGroupBox;
    Label5: TLabel;
    Label7: TLabel;
    Edit30: TEdit;
    Edit32: TEdit;
    UpDown1: TUpDown;
    UpDown2: TUpDown;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Edit40: TEdit;
    Edit41: TEdit;
    Edit42: TEdit;
    Edit43: TEdit;
    Edit44: TEdit;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Edit1: TEdit;
    UpDown3: TUpDown;
    Label2: TLabel;
    Edit2: TEdit;
    UpDown4: TUpDown;
    Label3: TLabel;
    Edit3: TEdit;
    UpDown5: TUpDown;
    Label4: TLabel;
    Edit4: TEdit;
    UpDown6: TUpDown;
    TabSheet4: TTabSheet;
    GroupBox3: TGroupBox;
    Label6: TLabel;
    Edit5: TEdit;
    Label8: TLabel;
    UpDown7: TUpDown;
    TabSheet5: TTabSheet;
    CheckBox1: TCheckBox;
    Label9: TLabel;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    CheckBox7: TCheckBox;
    CheckBox8: TCheckBox;
    Label10: TLabel;
    Edit6: TEdit;
    UpDown8: TUpDown;
    CheckBox9: TCheckBox;
    CheckBox10: TCheckBox;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton9: TSpeedButton;
    SpeedButton10: TSpeedButton;
    SpeedButton11: TSpeedButton;
    SpeedButton12: TSpeedButton;
    OpenDialog1: TOpenDialog;
    TabSheet6: TTabSheet;
    GroupBox4: TGroupBox;
    Label11: TLabel;
    Label12: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label27: TLabel;
    Edit7: TEdit;
    Edit8: TEdit;
    GroupBox5: TGroupBox;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Edit9: TEdit;
    Edit10: TEdit;
    Label33: TLabel;
    Edit11: TEdit;
    Label34: TLabel;
    Edit12: TEdit;
    Label35: TLabel;
    Edit13: TEdit;
    SpeedButton7: TSpeedButton;
    SpeedButton13: TSpeedButton;
    SpeedButton14: TSpeedButton;
    GroupBox6: TGroupBox;
    Label36: TLabel;
    UpDown9: TUpDown;
    Label26: TLabel;
    Edit14: TEdit;
    PageControl1: TPageControl;
    CheckBox11: TCheckBox;
    GroupBox7: TGroupBox;
    Label37: TLabel;
    Label38: TLabel;
    SpeedButton15: TSpeedButton;
    SpeedButton16: TSpeedButton;
    GroupBox8: TGroupBox;
    CheckBox12: TCheckBox;
    GroupBox9: TGroupBox;
    Label39: TLabel;
    Label40: TLabel;
    Edit16: TEdit;
    Label41: TLabel;
    Edit17: TEdit;
    Label42: TLabel;
    Label43: TLabel;
    ComboBox1: TComboBox;
    Edit15: TEdit;
    TabSheet7: TTabSheet;
    GroupBox10: TGroupBox;
    Label44: TLabel;
    ComboBox2: TComboBox;
    Label45: TLabel;
    Label46: TLabel;
    Label47: TLabel;
    Label48: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure CheckBox9Click(Sender: TObject);
    procedure Edit6Change(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure SpeedButton8Click(Sender: TObject);
    procedure SpeedButton9Click(Sender: TObject);
    procedure SpeedButton10Click(Sender: TObject);
    procedure SpeedButton11Click(Sender: TObject);
    procedure SpeedButton12Click(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);
    procedure SpeedButton13Click(Sender: TObject);
    procedure SpeedButton14Click(Sender: TObject);
    procedure SpeedButton16Click(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
  private
    procedure SynchroEdits;
    procedure SelectDir(aEdit: TEdit);
    procedure SelectFile(aEdit: TEdit; aFilter: string);
    procedure ReadRegistry;
    procedure WriteRegistry;
  end;

var
  FSettings: TFSettings = nil;

implementation

{$R *.DFM}

uses
  Registry,
  Settings, Measure, TimeSpan, Observation, Product, Animation,
  Configuration, Ensemble, Borders, Regions, Shell_Process, GridForm;

// TFSettings methods

procedure TFSettings.Button1Click(Sender: TObject);
var
  i: integer;
begin
  with FShell do
    for i := 0 to MDIChildCount do
      if MDIChildren[i] is TFGrid then
        with TFGrid(MDIChildren[i]) do
          begin
            ReleaseRegions;
            ReleaseBorders;
          end;
  with theSettings do
    begin
      // Tamaños
      DefaultHorzEast := Updown3.Position;
      DefaultHorzWest := Updown4.Position;
      DefaultHorzNorth := Updown5.Position;
      DefaultHorzSouth := Updown6.Position;
      DefaultCellH := Updown1.Position;
      DefaultCellV := Updown2.Position;
      DefaultMaxRange := UpDown8.Position;
      // Escalas
      PaletteTable[unDB]  := Edit40.Text;
      PaletteTable[unDBZ] := Edit41.Text;
      PaletteTable[unMMH] := Edit42.Text;
      PaletteTable[unMM]  := Edit43.Text;
      PaletteTable[unKM]  := Edit44.Text;
      // Caminos
      TimeSpans    := Edit20.Text;
      Observations := Edit21.Text;
      Products     := Edit22.Text;
      Animations   := Edit23.Text;
      Reports      := Edit24.Text;
      Images       := Edit25.Text;
      NMEA_ATTEX   := Edit15.Text;
      NMEA_ATTEX_Format := ComboBox1.ItemIndex;
      // Valores
      DefaultAnmDelay := UpDown7.Position;
      // Ver
      ShowExploracion  := CheckBox1.Checked;
      ShowTopografia   := CheckBox2.Checked;
      ShowEscala       := CheckBox3.Checked;
      ShowRadar        := CheckBox4.Checked;
      ShowCuadriculas  := CheckBox5.Checked;
      ShowClimatologia := CheckBox6.Checked;
      ShowRadios       := CheckBox7.Checked;
      ShowGuiaDeCorte  := CheckBox8.Checked;
      ShowImgSuavizar  := CheckBox10.Checked;
      ShowVerticalGrid := CheckBox11.Checked;
      IncludeZero      := CheckBox12.Checked;
      RadioHelp        := ComboBox2.ItemIndex;
    end;
  WriteRegistry;
  Borders.Update;
  Regions.Update;
  with FShell do
    for i := 0 to MDIChildCount do
      if MDIChildren[i] is TFGrid then
        with TFGrid(MDIChildren[i]) do
          begin
            UpdateBordersMenu;
            UpdateRegionsMenu;
            UpdateTreeAreas;
            UpdateMaskBitmap;
          end;
end;

procedure TFSettings.FormCreate(Sender: TObject);
var
  i: integer;
begin
  with theSettings do
    begin
      // Tamaños
      Updown3.Position := DefaultHorzEast;
      Updown4.Position := DefaultHorzWest;
      Updown5.Position := DefaultHorzNorth;
      Updown6.Position := DefaultHorzSouth;
      Updown1.Position := DefaultCellH;
      Updown2.Position := DefaultCellV;
      UpDown8.Position := DefaultMaxRange;
      CheckBox9.Checked := (Updown8.Position =  UpDown3.Position) and
                           (Updown8.Position = -UpDown4.Position) and
                           (Updown8.Position =  UpDown5.Position) and
                           (Updown8.Position = -UpDown6.Position);
      CheckBox9Click(CheckBox9);
      // Escalas
      Edit40.Text := PaletteTable[unDB];
      Edit41.Text := PaletteTable[unDBZ];
      Edit42.Text := PaletteTable[unMMH];
      Edit43.Text := PaletteTable[unMM];
      Edit44.Text := PaletteTable[unKM];
      // Caminos
      Edit20.Text := TimeSpans;
      Edit21.Text := Observations;
      Edit22.Text := Products;
      Edit23.Text := Animations;
      Edit24.Text := Reports;
      Edit25.Text := Images;
      Edit15.Text := NMEA_ATTEX;
      ComboBox1.ItemIndex := NMEA_ATTEX_Format;
      // Valores
      UpDown7.Position := DefaultAnmDelay;
      // Ver
      CheckBox1.Checked  := ShowExploracion;
      CheckBox2.Checked  := ShowTopografia;
      CheckBox3.Checked  := ShowEscala;
      CheckBox4.Checked  := ShowRadar;
      CheckBox5.Checked  := ShowCuadriculas;
      CheckBox6.Checked  := ShowClimatologia;
      CheckBox7.Checked  := ShowRadios;
      CheckBox8.Checked  := ShowGuiaDeCorte;
      CheckBox10.Checked := ShowImgSuavizar;
      CheckBox11.Checked := ShowVerticalGrid;
      CheckBox12.Checked := IncludeZero;
      ComboBox2.Items.Clear;
      for i := 0 to settings_RH.Count - 1 do
        ComboBox2.Items.Add(settings_RH.Data[i].Name);
      ComboBox2.ItemIndex := RadioHelp;
      ComboBox2Change(Self);
    end;
  ReadRegistry;
end;

procedure TFSettings.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TFSettings.FormDestroy(Sender: TObject);
begin
  FSettings := nil;
end;

procedure TFSettings.CheckBox9Click(Sender: TObject);
begin
  with Sender as TCheckBox do
    begin
      Edit1.Enabled   := not Checked;
      Edit2.Enabled   := not Checked;
      Edit3.Enabled   := not Checked;
      Edit4.Enabled   := not Checked;
      UpDown3.Enabled := not Checked;
      UpDown4.Enabled := not Checked;
      UpDown5.Enabled := not Checked;
      UpDown6.Enabled := not Checked;
      Label1.Enabled  := not Checked;
      Label2.Enabled  := not Checked;
      Label3.Enabled  := not Checked;
      Label4.Enabled  := not Checked;
    end;
  SynchroEdits;
end;

procedure TFSettings.SynchroEdits;
begin
  if CheckBox9.Checked
    then
      with UpDown8 do
        begin
          UpDown3.Position :=  Position;
          UpDown4.Position := -Position;
          UpDown5.Position :=  Position;
          UpDown6.Position := -Position;
        end;
end;

procedure TFSettings.Edit6Change(Sender: TObject);
begin
  SynchroEdits;
end;

procedure TFSettings.SelectDir(aEdit: TEdit);
var
  tmp: string;
begin
  if SelectDirectory('Seleccione carpeta', '', tmp) then
    aEdit.Text := tmp;
end;

procedure TFSettings.SelectFile(aEdit: TEdit; aFilter: string);
begin
  with OpenDialog1 do
    begin
      Filter := aFilter + '|' + aFilter;
      InitialDir := ExtractFilePath(aEdit.Text);
      if Execute then
        aEdit.Text := FileName;
    end;
end;

procedure TFSettings.SpeedButton1Click(Sender: TObject);
begin
  SelectDir(Edit20);
end;

procedure TFSettings.SpeedButton2Click(Sender: TObject);
begin
  SelectDir(Edit21);
end;

procedure TFSettings.SpeedButton3Click(Sender: TObject);
begin
  SelectDir(Edit22);
end;

procedure TFSettings.SpeedButton4Click(Sender: TObject);
begin
  SelectDir(Edit23);
end;

procedure TFSettings.SpeedButton5Click(Sender: TObject);
begin
  SelectDir(Edit24);
end;

procedure TFSettings.SpeedButton6Click(Sender: TObject);
begin
  SelectDir(Edit25);
end;

procedure TFSettings.SpeedButton8Click(Sender: TObject);
begin
  SelectFile(Edit40, '*.pal');
end;

procedure TFSettings.SpeedButton9Click(Sender: TObject);
begin
  SelectFile(Edit41, '*.pal');
end;

procedure TFSettings.SpeedButton10Click(Sender: TObject);
begin
  SelectFile(Edit42, '*.pal');
end;

procedure TFSettings.SpeedButton11Click(Sender: TObject);
begin
  SelectFile(Edit43, '*.pal');
end;

procedure TFSettings.SpeedButton12Click(Sender: TObject);
begin
  SelectFile(Edit44, '*.pal');
end;

procedure TFSettings.ReadRegistry;
begin
  with theConfiguration do
    begin
      // Z-R
      Edit7.Text := FloatToStr(RainA);
      Edit8.Text := FloatToStr(RainB);
      // Kdp-R
      Edit9.Text := FloatToStr(KDP_A);
      Edit10.Text := FloatToStr(KDP_B);
      // Archivos
      Edit11.Text := BorderTables;
      Edit12.Text := RegionTables;
      Edit13.Text := TopographyMaps;
      // Speckler
      UpDown9.Position := RadialSpeckler;
    end;
end;

procedure TFSettings.WriteRegistry;
begin
  with theConfiguration do
    begin
      // Z-R
      RainA := StrToFloat(Edit7.Text);
      RainB := StrToFloat(Edit8.Text);
      // Kdp-R
      KDP_A := StrToFloat(Edit9.Text);
      KDP_B := StrToFloat(Edit10.Text);
      // Archivos
      BorderTables   := Edit11.Text;
      RegionTables   := Edit12.Text;
      TopographyMaps := Edit13.Text;
      // Speckler
      RadialSpeckler := UpDown9.Position;
    end;
end;

procedure TFSettings.SpeedButton7Click(Sender: TObject);
begin
  SelectDir(Edit11);
end;

procedure TFSettings.SpeedButton13Click(Sender: TObject);
begin
  SelectDir(Edit12);
end;

procedure TFSettings.SpeedButton14Click(Sender: TObject);
begin
  SelectDir(Edit13);
end;

procedure TFSettings.SpeedButton16Click(Sender: TObject);
begin
  SelectFile(Edit15, '*.txt');
end;

procedure TFSettings.ComboBox2Change(Sender: TObject);
begin
  Label46.Caption  := FloatToStrF(DegreeToDecDegree(settings_RH.Data[ComboBox2.ItemIndex].Lat), ffFixed, 7, 4) + 'º  ( ' +
    FloatToStrF(settings_RH.Data[ComboBox2.ItemIndex].Lat.Deg, ffFixed, 7, 0) + 'º'    +
    FloatToStrF(settings_RH.Data[ComboBox2.ItemIndex].Lat.Min, ffFixed, 7, 0) + ''''   +
    FloatToStrF(settings_RH.Data[ComboBox2.ItemIndex].Lat.Sec, ffFixed, 7, 2) + '''''' + ' N )';
  Label48.Caption  := FloatToStrF(DegreeToDecDegree(settings_RH.Data[ComboBox2.ItemIndex].Lon), ffFixed, 7, 4) + 'º  ( ' +
    FloatToStrF(settings_RH.Data[ComboBox2.ItemIndex].Lon.Deg, ffFixed, 7, 0) + 'º'    +
    FloatToStrF(settings_RH.Data[ComboBox2.ItemIndex].Lon.Min, ffFixed, 7, 0) + ''''   +
    FloatToStrF(settings_RH.Data[ComboBox2.ItemIndex].Lon.Sec, ffFixed, 7, 2) + '''''' + ' W )';
end;

end.
