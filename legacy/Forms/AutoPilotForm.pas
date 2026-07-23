unit AutoPilotForm;

//{$DEFINE INIFILE} //IniFile or Registry

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CheckLst, Buttons, ComCtrls, Contnrs, FileCtrl, IniFiles,
  Registry, DateUtils, Translators, Observation, Product, Products, GridForm,
  Translator, Maxs, CAPPI, SpatialAnimation, EstWst, NthSth, TopDown, PPI,
  Contribution, RHI, Tops, VIL, Volume, Accumulate, GridProduct, HorzProduct,
  Plane, Measure, Settings, DirMonitor, TimeSpan, Animation, PrTable,
  HeightTable, Math, Angle, VertProduct, SyncObjs, Spin;

type
  TFAutoPilot = class(TForm)
    GroupBox1: TGroupBox;
    ListBox1: TCheckListBox;
    GroupBox2: TGroupBox;
    CheckListBox1: TCheckListBox;
    Edit2: TEdit;
    Label3: TLabel;
    SpeedButton1: TSpeedButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    GroupBox4: TGroupBox;
    CheckListBox2: TCheckListBox;
    GroupBox5: TGroupBox;
    CheckListBox3: TCheckListBox;
    SpinEdit1: TSpinEdit;
    Label2: TLabel;
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure CheckListBox1DblClick(Sender: TObject);
    procedure CheckListBox2DblClick(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure CheckListBox1ClickCheck(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure CheckListBox3DblClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    procedure WriteForm;
    procedure ReadForm;
  end;

type

  TAPProduct = class
  private
    fChecked, fTimeSpan: boolean;
    fName: string;
    fBottom, fTop,
    fMeasure,
    fCellH,
    fMaxRange, fObs_Count,
    fWidth, fHeight, fZoom: integer;
    PClass: CProduct;
    fView: TFGrid;
    fPrd: TProduct;
    fTSpan: TTimeSpan;
    fAnimation: TAnimation;
  public
    constructor Create(aClass: CProduct; TimeSpan: boolean; Box: TCheckListBox);
    destructor Destroy; override;
    procedure WriteForm; virtual; abstract;
    procedure ReadForm; virtual; abstract;
    procedure SaveData(Folder: string); virtual;
    procedure LoadData(Folder: string); virtual;
    procedure Execute(var Obs: TObjectList); virtual;
    procedure SetParams(Prd: TProduct); virtual; abstract;
    procedure CloseView(Sender: TObject; var CloseAction: TCloseAction);
    property Obs_Count: integer read fObs_Count;
  end;

  TAPGrid = class (TAPProduct)
  private
    fEast, fWest, fNorth, fSouth: integer;
  public
    procedure WriteForm; override;
    procedure ReadForm; override;
    procedure SaveData(Folder: string); override;
    procedure LoadData(Folder: string); override;
    procedure Execute(var Obs: TObjectList); override;
    procedure SetParams(Prd: TProduct); override;
  end;

  TAPVert = class (TAPGrid)
    fCellHeight: integer;
  public
    procedure WriteForm; override;
    procedure ReadForm; override;
    procedure SaveData(Folder: string); override;
    procedure LoadData(Folder: string); override;
    procedure SetParams(Prd: TProduct); override;
  end;

  TAPPPI = class (TAPGrid)
  private
    fElevation: single;
  public
    procedure WriteForm; override;
    procedure ReadForm; override;
    procedure SaveData(Folder: string); override;
    procedure LoadData(Folder: string); override;
    procedure SetParams(Prd: TProduct); override;
  end;

  TAPRHI = class (TAPVert)
  private
    fAzimuth: single;
  public
    procedure WriteForm; override;
    procedure ReadForm; override;
    procedure SaveData(Folder: string); override;
    procedure LoadData(Folder: string); override;
    procedure SetParams(Prd: TProduct); override;
  end;

  TAPContribution = class (TAPGrid)
  private
    fInterval: integer;
  public
    procedure WriteForm; override;
    procedure ReadForm; override;
    procedure SaveData(Folder: string); override;
    procedure LoadData(Folder: string); override;
    procedure SetParams(Prd: TProduct); override;
  end;

  TAPTops = class (TAPGrid)
  private
    fMinimum,
    fLocation: integer;
  public
    procedure WriteForm; override;
    procedure ReadForm; override;
    procedure SaveData(Folder: string); override;
    procedure LoadData(Folder: string); override;
    procedure SetParams(Prd: TProduct); override;
  end;

  TAPVil = class (TAPGrid)
  public
    procedure SetParams(Prd: TProduct); override;
  end;

//========== Threads ============

  TExecuteTaskThread = class(TThread)
  protected
    procedure Execute; override;
    procedure Go;
  end;

//========== Task ===============

  TTask = class
  private
    fChecked, fActive: boolean;
    fFolder: string;
    fProduct: TObjectList;
    fDirMonitor: TDirMonitor;
    fTimeOld: integer;
    function GetProduct(Name: string): TAPProduct;
    function GetTSProduct(Name: string): TAPProduct;
    function GetPrd(i: integer): TAPProduct;
    procedure SetPrd(i: integer; Prd: TAPProduct);
    procedure CreateObsList;
    function ObsInList(FileName: string): boolean;
  public
    fName: string;
    fObs: TObjectList;
    constructor Create(Name: string);
    destructor Destroy; override;
    property Product[Name: string]: TAPProduct read GetProduct;
    property Prd[i: integer]: TAPProduct read GetPrd write SetPrd;
    property TSProduct[Name: string]: TAPProduct read GetTSProduct;
    procedure WriteForm;
    procedure ReadForm;
    procedure SaveData(Folder: string);
    procedure LoadData(Folder: string);
    procedure Execute;
    procedure DirChange(sender: TObject; Action: TAction; FileName: String);
    procedure ActiveDirMonitor;
  end;

  TAllTask = class
  private
    fTask: TObjectList;
    function GetTask(i: integer): TTask;
  public
    fInterval: integer;
    constructor Create;
    destructor Destroy; override;
    property Task[i: integer]: TTask read GetTask; default;
    procedure SaveData;
    procedure LoadData;
    procedure Execute;
  end;

const
  TaskFolder = 'AutoPilot';

var
  FAutoPilot: TFAutoPilot;
  APTask: TAllTask;
  TaskThreadRunning: TEvent;

{$IFDEF INIFILE}
  IniFile: TIniFile;
{$ELSE}
  IniFile: TRegistryIniFile;
{$ENDIF}

implementation

{$R *.dfm}

uses EditAutoPilotForm, TimeSpanForm, Shell_Process, ObservationForm;

//=========== TAPProduct ===============

constructor TAPProduct.Create;
begin
  PClass := aClass;
  fName := PClass.Name;
  fTimeSpan := TimeSpan;
  fChecked := false;
  if fTimeSpan then
    fObs_Count := 5
  else
    fObs_Count := 1;
  Box.Items.Add(fName);
end;

destructor TAPProduct.Destroy;
begin
  inherited;
end;

procedure TAPProduct.SaveData;
begin
  with IniFile do
    begin
      WriteBool(Folder, 'Checked', fChecked);
      WriteInteger(Folder, 'Bottom', fBottom);
      WriteInteger(Folder, 'Top', fTop);
      WriteInteger(Folder, 'Measure', fMeasure);
      WriteInteger(Folder, 'CellH', fCellH);
      WriteInteger(Folder, 'MaxRange', fMaxRange);
      WriteInteger(Folder, 'Width', fWidth);
      WriteInteger(Folder, 'Height', fHeight);
      WriteInteger(Folder, 'Zoom', fZoom);
      WriteInteger(Folder, 'Obs_Count', fObs_Count);
    end;
end;

procedure TAPProduct.LoadData;
begin
  with IniFile do
    begin
      fChecked := ReadBool(Folder, 'Checked', false);
      fBottom := ReadInteger(Folder, 'Bottom', 0);
      fTop := ReadInteger(Folder, 'Top', 20000);
      fMeasure := ReadInteger(Folder, 'Measure', 1);
      fCellH := ReadInteger(Folder, 'CellH', 1000);
      fMaxRange := ReadInteger(Folder, 'MaxRange', 500);
      fWidth := ReadInteger(Folder, 'Width', 500);
      fHeight := ReadInteger(Folder, 'Height', 400);
      fZoom := ReadInteger(Folder, 'Zoom', 100);
      fObs_Count := ReadInteger(Folder, 'Obs_Count', 1);
    end;
end;

procedure TAPProduct.CloseView;
begin
  CloseAction := caFree;
  fView := nil;
  if fTimeSpan then
    begin
      fTSpan.Release;
      fTSpan := nil;
      fAnimation.OnDestroy := nil;
    end
  else
    begin
      FreeAndNil(fPrd);
    end;
end;

procedure TAPProduct.Execute;
var
  i: integer;                                
  newobs: boolean;
begin
  if (not fTimeSpan) and (Obs.Count > 0) then
    begin
      if not Assigned(fPrd) then
        fPrd := PClass.Create(nil);
      if fPrd.DataSource <> TObservation(Obs.Last) then
        begin
          if Assigned(fPrd.DataSource) then
            fPrd.DataSource.Release;
          fPrd.DataSource := TObservation(Obs.Last);
          TObservation(Obs.Last).AddRef;
          SetParams(fPrd);
          fPrd.Render;
          // Application.ProcessMessages;
          sleep(5);
          if (not Assigned(fView)) then
            begin
              fView := TFGrid.Create(FShell);
              fView.FormStyle := fsMDIChild;
              fView.Visible := true;
            end;
          fView.Product := fPrd;
          fView.Grid := TGridProduct(fPrd).Grid;
          fView.Show;
          fView.OnClose := CloseView;
       end;
    end
  else if Obs.Count > 0 then
    begin
      if not Assigned(fTSpan) then
        fTSpan := TTimeSpan.Create;
      newobs := false;
      for i := Obs.Count - 1 downto Max(Obs.Count - fObs_Count, 0) do
        if fTSpan.fObservations.IndexOf(TObservation(Obs[i])) = -1 then
          begin
            newobs := true;
            fTSpan.Insert(TObservation(Obs[i]));
            TObservation(Obs[i]).AddRef;
          end;
      while fTSpan.Observations > fObs_Count do
        begin
          fTSpan.Observation[0].Release;
          fTSpan.Delete(0);
        end;
      if newobs then
        begin
          FreeAndNil(fAnimation);
          with fTSpan do
            begin
              fAnimation := TAnimation.Create(nil);
              with fAnimation do
                begin
                  Frames := Observations;
                  for I := 0 to Observations - 1 do
                    try
                      fPrd := PClass.Create(nil);
                      fPrd.DataSource := Observation[I];
                      SetParams(fPrd);
                      fPrd.Render;
                      // Application.ProcessMessages;
                      sleep(5);
                      if fPrd.Rendered then
                        Frame[I] := fPrd;
                      fPrd.Free;
                    except
                      on E : Exception do
                        begin
                          FreeAndNil(fAnimation);
                          raise;
                        end;
                    end;
                end;
            end;
          if (not Assigned(fView)) then
            begin
              fView := TFGrid.Create(FShell);
              fView.FormStyle := fsMDIChild;
              fView.Visible := true;
            end;
          fView.Grid := TGridProduct(fAnimation.Product).Grid;
          TGridProduct(fAnimation.Product).ViewForm := fView;
          fAnimation.Position := fAnimation.Frames - 1;
          fView.TrackBar1.Position := fAnimation.Frames - 1;
          if fView.Playing then
            fView.ToolButton1Click(fView);
          fView.OnClose := CloseView;
        end;
    end;
end;

//=========== TAPGrid ===============

procedure TAPGrid.WriteForm;
begin
  with FEditAutoPilot do
    begin
      Caption := fName;
      TabSheet1.TabVisible := true;
      TabSheet2.TabVisible := true;
      TabSheet3.TabVisible := false;
      TabSheet4.TabVisible := false;
      TabSheet5.TabVisible := false;
      TabSheet6.TabVisible := false;
      TabSheet7.TabVisible := false;
      PageControl1.ActivePageIndex := 0;
      Label31.Visible := false;
      SpinEdit23.Visible := false;
      GroupBox3.Visible := false;
      GroupBox2.Visible := fTimeSpan;
      SpinEdit1.Value := fBottom;
      SpinEdit2.Value := fTop;
      ComboBox1.ItemIndex := fMeasure;
      SpinEdit7.Value := fEast;
      SpinEdit8.Value := fWest;
      SpinEdit9.value := fNorth;
      SpinEdit10.Value := fSouth;
      SpinEdit11.Value := fCellH;
      SpinEdit21.Value := fObs_Count;
    end;
end;

procedure TAPGrid.ReadForm;
begin
  with FEditAutoPilot do
    begin
      fBottom := SpinEdit1.Value;
      fTop := SpinEdit2.Value;
      fMeasure := ComboBox1.ItemIndex;
      fEast := SpinEdit7.Value;
      fWest := SpinEdit8.Value;
      fNorth := SpinEdit9.Value;
      fSouth := SpinEdit10.Value;
      fCellH := SpinEdit11.Value;
      fObs_Count := SpinEdit21.Value;
    end;
end;

procedure TAPGrid.SaveData;
begin
  inherited;
  with IniFile do
    begin
      WriteInteger(Folder, 'North', fNorth);
      WriteInteger(Folder, 'South', fSouth);
      WriteInteger(Folder, 'East', fEast);
      WriteInteger(Folder, 'West', fWest);
    end;
end;

procedure TAPGrid.LoadData;
begin
  inherited;
  with IniFile do
    begin
      fNorth := ReadInteger(Folder, 'North', -500);
      fSouth := ReadInteger(Folder, 'South', 500);
      fEast := ReadInteger(Folder, 'East', -500);
      fWest := ReadInteger(Folder, 'West', 500);
    end;
end;

procedure TAPGrid.Execute;
begin
  inherited;
end;

procedure TAPGrid.SetParams;
begin
  with THorzProduct(Prd) do
    begin
      Bottom := fBottom;
      Top    := fTop;
      Channel := 0;
      Area    := PlaneArea(-450, -450, 450, 450);
      Length := 1000;
      MaxCells := TObservation(Prd.DataSource).Channel[0].Cells;
      Measure := TMeasure(fMeasure + 1);
    end;
end;

//=========== TAPPPI ===============

procedure TAPPPI.WriteForm;
begin
  inherited;
  with FEditAutoPilot do
    begin
      TabSheet4.TabVisible := true;
      Edit1.Text := FloatToStrF(fElevation, ffFixed, 5, 1);
    end;
end;

procedure TAPPPI.ReadForm;
begin
  inherited;
  with FEditAutoPilot do
    begin
      fElevation := StrToFloat(Edit1.Text);
    end;
end;

procedure TAPPPI.SaveData;
begin
  inherited;
  IniFile.WriteFloat(Folder, 'Elevation', fElevation);
end;

procedure TAPPPI.LoadData;
begin
  inherited;
  fElevation := IniFile.ReadFloat(Folder, 'Elevation', 0.0);
end;

procedure TAPPPI.SetParams;
begin
  inherited;
  with TPPI(Prd) do
    Elevation := AngleCode(fElevation)
end;

//=========== TAPRHI ===============

procedure TAPRHI.WriteForm;
begin
  inherited;
  with FEditAutoPilot do
    begin
      TabSheet5.TabVisible := true;
      Edit2.Text := FloatToStrF(fAzimuth, ffFixed, 5, 1);
    end;
end;

procedure TAPRHI.ReadForm;
begin
  inherited;
  with FEditAutoPilot do
    begin
      fAzimuth := StrToFloat(Edit2.Text);
    end;
end;

procedure TAPRHI.SaveData;
begin
  inherited;
  IniFile.WriteFloat(Folder, 'Azimuth', fAzimuth);
end;

procedure TAPRHI.LoadData;
begin
  inherited;
  fAzimuth := IniFile.ReadFloat(Folder, 'Azimuth', 0.0);
end;

procedure TAPRHI.SetParams;
begin
  inherited;
  with TRHI(Prd) do
    begin
      Azimut := AngleCode(fAzimuth)
    end;
end;

//=========== TAPContribution ===============

procedure TAPContribution.WriteForm;
begin
  inherited;
  with FEditAutoPilot do
    begin
      TabSheet6.TabVisible := true;
      SpinEdit20.Value := fInterval;
    end;
end;

procedure TAPContribution.ReadForm;
begin
  inherited;
  with FEditAutoPilot do
    fInterval := SpinEdit20.Value;
end;

procedure TAPContribution.SaveData;
begin
  inherited;
  IniFile.WriteInteger(Folder, 'Interval', fInterval);
end;

procedure TAPContribution.LoadData;
begin
  inherited;
  fInterval := IniFile.ReadInteger(Folder, 'Interval', 5);
end;

procedure TAPContribution.SetParams;
begin
  inherited;
  with TContribution(Prd) do
    begin
      Measure := unMMH;
      Interval := EncodeTime(0, fInterval, 0, 0);
    end;
end;

//=========== TAPTops ===============

procedure TAPTops.WriteForm;
begin
  inherited;
  with FEditAutoPilot do
    begin
      GroupBox3.Visible := true;
      SpinEdit3.Value := fMinimum;
      TabSheet7.TabVisible := true;
      TrackBar1.Position := 100 - fLocation;
    end;
end;

procedure TAPTops.ReadForm;
begin
  inherited;
  with FEditAutoPilot do
    begin
      fMinimum := SpinEdit3.Value;
      fLocation := 100 - TrackBar1.Position;
    end;
end;

procedure TAPTops.SaveData;
begin
  inherited;
  with IniFile do
    begin
      WriteInteger(Folder, 'Minimum', fMinimum);
      WriteInteger(Folder, 'Location', fLocation);
    end;
end;

procedure TAPTops.LoadData;
begin
  inherited;
  with IniFile do
    begin
      fMinimum := ReadInteger(Folder, 'Minimum', 5);
      fLocation := ReadInteger(Folder, 'Location', 5);
    end;
end;

procedure TAPTops.SetParams;
begin
  inherited;
  with TTops(Prd) do
    begin
      Minimum := MeasureCode(fMinimum, Measure);
      Location := fLocation;
    end;
end;

//=============== TAPVIL ================

procedure TAPVIL.SetParams;
begin
  inherited;
  with TVIL(Prd) do
    begin
      Measure := unKGM;
      C1 := TheSettings.DefaultVILC1;
      C2 := TheSettings.DefaultVILC2;
    end;
end;

//================ TAPVert =================

procedure TAPVert.WriteForm;
begin
  inherited;
  with FEditAutoPilot do
    begin
      Label31.Visible := true;
      SpinEdit23.Visible := true;
      SpinEdit23.Value := fCellHeight;
    end;
end;

procedure TAPVert.ReadForm;
begin
  inherited;
  with FEditAutoPilot do
    fCellHeight := SpinEdit23.Value;
end;

procedure TAPVert.SaveData;
begin
  inherited;
  IniFile.WriteInteger(Folder, 'CellHeight', 1000);
end;

procedure TAPVert.LoadData;
begin
  inherited;
  fCellHeight := IniFile.ReadInteger(Folder, 'CellHeight', 1000);
end;

procedure TAPVert.SetParams;
begin
  inherited;
  with TVertProduct(Prd) do
    begin
      CellHeight := fCellHeight;
    end;
end;

//=============== TExecuteTask ==================

procedure TExecuteTaskThread.Execute;
begin
  Synchronize(Go);
  TaskThreadRunning.ResetEvent;
end;

procedure TExecuteTaskThread.Go;
begin
  APTask.Execute;
end;

//=============== TTask =================

constructor TTask.Create;
begin
  fName := Name;
  fProduct := TObjectList.Create;
  fObs := TObjectList.Create(false);
  fDirMonitor := TDirMonitor.Create(nil);
  with fProduct, FAutoPilot do
    begin
      // Productos
      Add(TAPGrid.Create        (TMaxs,         false, CheckListBox1)); // Altura
      Add(TAPGrid.Create        (TCAPPI,        false, CheckListBox1)); // CAPPI
      Add(TAPVert.Create        (TEstWst,       false, CheckListBox1)); // Max_EW
      Add(TAPVert.Create        (TNthSth,       false, CheckListBox1)); // Max_NS
      Add(TAPGrid.Create        (TTopDown,      false, CheckListBox1)); // Maximos
      Add(TAPPPI.Create         (TPPI,          false, CheckListBox1)); // PPI
      Add(TAPContribution.Create(TContribution, false, CheckListBox1)); // Precipitacion
      Add(TAPRHI.Create         (TRHI,          false, CheckListBox1)); // RHI
      Add(TAPTops.Create        (TTops,         false, CheckListBox1)); // Topes
      Add(TAPVIL.Create         (TVIL,          false, CheckListBox1)); // VIL
      // Animaciones
      Add(TAPGrid.Create        (TMaxs,         true,  CheckListBox2)); // Altura
      Add(TAPGrid.Create        (TCAPPI,        true,  CheckListBox2)); // CAPPI
      Add(TAPVert.Create        (TEstWst,       true,  CheckListBox2)); // Max_EW
      Add(TAPVert.Create        (TNthSth,       true,  CheckListBox2)); // Max_NS
      Add(TAPGrid.Create        (TTopDown,      true,  CheckListBox2)); // Maximos
      Add(TAPPPI.Create         (TPPI,          true,  CheckListBox2)); // PPI
      Add(TAPContribution.Create(TContribution, true,  CheckListBox2)); // Precipitacion
      Add(TAPRHI.Create         (TRHI,          true,  CheckListBox2)); // RHI
      Add(TAPTops.Create        (TTops,         true,  CheckListBox2)); // Topes
      Add(TAPVIL.Create         (TVIL,          true,  CheckListBox2)); // VIL
    end;
end;

function TTask.ObsInList;
var
  i: integer;
begin
  result := false;
  for i := 0 to fObs.Count - 1 do
    if TObservation(fObs[i]).FileName = FileName then
      begin
        result := true;
        exit;
      end;
end;

destructor TTask.Destroy;
var
  i: integer;
begin
  fProduct.Free;
  fDirMonitor.Free;
  for i := 0 to fObs.Count - 1 do
    TObservation(fObs[i]).Release;
  fObs.Free;
  inherited;
end;

function TTask.GetProduct;
var
  i: integer;
begin
  result := nil;
  for i := 0 to fProduct.Count - 1 do
    if (TAPProduct(fProduct[i]).fName = Name) and
       (not TAPProduct(fProduct[i]).fTimeSpan) then
      begin
        result := TAPProduct(fProduct[i]);
        exit;
      end;
end;

function TTask.GetTSProduct;
var
  i: integer;
begin
  result := nil;
  for i := 0 to fProduct.Count - 1 do
    if (TAPProduct(fProduct[i]).fName = Name) and
       (TAPProduct(fProduct[i]).fTimeSpan) then
      begin
        result := TAPProduct(fProduct[i]);
        exit;
      end;
end;

function TTask.GetPrd;
begin
  result := TAPProduct(fProduct[i]);
end;

procedure TTask.SetPrd;
begin
  fProduct[i] := Prd;
end;

function Compare(Item1, Item2: Pointer): Integer;
begin
  result := CompareDateTime(TObservation(Item1).Time, TObservation(Item2).Time);
end;

procedure TTask.CreateObsList;

  procedure LookForObs(Folder: string);
  var
    sr: TSearchRec;
    O: TObservation;
    Tran: TTranslator;
  begin
    if FindFirst(Folder + '*.*', faAnyFile, sr) = 0 then
    begin
      repeat
        try
           Tran := Translators.Find(Folder + sr.Name);
           if Assigned(Tran) then
             begin
               // Application.ProcessMessages;
               sleep(5);
               Tran.Free;
               O := TObservation.Load(Folder + sr.Name);
               if (HoursBetween(Now, O.Time) <= fTimeOld) then
                 begin
                   if not ObsInList(O.FileName) then
                     fObs.Add(O)
                   else
                     O.Release;
                 end
               else
                 begin
                   O.Release;
                   if fActive then
                     MoveFile(PAnsiChar(Folder + sr.Name), PAnsiChar(Folder + '\Old\' + sr.Name));
                 end;
             end;
         except
           on E: Exception do;
         end;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;
  end;

var
  i: integer;

begin
  if fFolder <> '' then
    begin
      if not DirectoryExists(IncludeTrailingPathDelimiter(fFolder) + '\Old\') then
        ForceDirectories(IncludeTrailingPathDelimiter(fFolder) + '\Old\');
      LookForObs(IncludeTrailingPathDelimiter(fFolder));
      fObs.Sort(@Compare);
      while fObs.Count > 100 do
        begin
          TObservation(fObs.First).Release;
          fObs.Delete(0);
        end;
    end;
end;

procedure TTask.WriteForm;
var
  i: integer;
begin
  with FAutoPilot do
    begin
      CheckListBox1.OnClickCheck := nil;
      CheckListBox2.OnClickCheck := nil;
      CheckListBox3.OnClickCheck := nil;
      Edit2.OnChange := nil;
      Edit2.Text := fFolder;
      CheckBox1.Checked := fActive;
      SpinEdit1.Value := fTimeOld;
      with CheckListBox1 do
        for i := 0 to Items.Count - 1 do
          Checked[i] := GetProduct(Items[i]).fChecked;
      with CheckListBox2 do
        for i := 0 to Items.Count - 1 do
          Checked[i] := GetTSProduct(Items[i]).fChecked;
      CheckListBox3.Checked[0] := Prd[i].fChecked;
      CheckListBox1.OnClickCheck := CheckListBox1ClickCheck;
      CheckListBox2.OnClickCheck := CheckListBox1ClickCheck;
      CheckListBox3.OnClickCheck := CheckListBox1ClickCheck;
      Edit2.OnChange := CheckListBox1ClickCheck;
    end;
end;

procedure TTask.ReadForm;
var
  i: integer;
begin
  with FAutoPilot do
    begin
      fFolder := Edit2.Text;
      fTimeOld := SpinEdit1.Value;
      fActive := CheckBox1.Checked;
      with CheckListBox1 do
        for i := 0 to Items.Count - 1 do
          GetProduct(Items[i]).fChecked := Checked[i];
      with CheckListBox2 do
        for i := 0 to Items.Count - 1 do
          GetTSProduct(Items[i]).fChecked := Checked[i];
      Prd[i].fChecked := CheckListBox3.Checked[0];
    end;
  ActiveDirMonitor;
end;

procedure TTask.SaveData;
var
  i: integer;
begin
  with IniFile do
    begin
      ReadForm;
      WriteInteger(Folder, 'Product_Count', fProduct.Count);
      WriteBool(Folder, 'Checked', fChecked);
      WriteString(Folder, 'Folder', fFolder);
      WriteInteger(Folder, 'TimeOld', fTimeOld);
      WriteBool(Folder, 'Active', fActive);
    end;
  for i := 0 to fProduct.Count - 1 do
    if Prd[i].fTimeSpan then
      Prd[i].SaveData(Folder + '\' + Prd[i].fName + '_TimeSpan')
    else
      Prd[i].SaveData(Folder + '\' + Prd[i].fName)
end;

procedure TTask.LoadData;
var
  i, Product_Count: integer;
begin
  with IniFile do
    begin
      Product_Count := ReadInteger(Folder, 'Product_Count', 20);
      fChecked := ReadBool(Folder, 'Checked', true);
      fFolder := ReadString(Folder, 'Folder', '');
      fTimeOld := ReadInteger(Folder, 'TimeOld', 5);
      fActive := ReadBool(Folder, 'Active', true);
    end;
  for i := 0 to Product_Count - 1 do
    if Prd[i].fTimeSpan then
      Prd[i].LoadData(Folder + '\' + Prd[i].fName + '_TimeSpan')
    else
      Prd[i].LoadData(Folder + '\' + Prd[i].fName);
  ActiveDirMonitor;
end;

procedure TTask.Execute;
var
  i: integer;
begin
  CreateObsList;
  for i := 0 to fProduct.Count - 1 do
    if Prd[i].fChecked then
      Prd[i].Execute(fObs);
  i := 0;
  while i < fObs.Count do
    begin
      if TObservation(fObs[i]).References = 1 then
        begin
          TObservation(fObs[i]).Release;
          fObs.Delete(i);
          i := 0;
        end
      else Inc(i);
    end;
end;

procedure TTask.DirChange;
var
  O: TObservation;
  i: integer;
begin
 { if FShell.CheckBox1.Checked then
    begin
      O := TObservation.Load(filename);
      if Assigned(O) and (fObs.IndexOf(O) = -1) then
         fObs.Add(O);
      fObs.Sort(@Compare);
      while fObs.Count > 200 do
        begin
          fObs[fObs.Count - 1] := nil;
          fObs.Delete(fObs.Count - 1);
        end;
      for i := 0 to fProduct.Count - 1 do
        if Prd[i].fChecked then
          Prd[i].Execute(fObs);
    end;}
end;

procedure TTask.ActiveDirMonitor;
begin
{  if fFolder <> '' then
    with fDirMonitor do
      begin
        Directory := fFolder;
        FilterAction := [faADDED, faMODIFIED];
        FilterNotification := [nfLAST_WRITE];
        Active := true;
        WatchSubtree := false;
        OnChange := DirChange;
      end;}
end;

//========= TAllTask ==============

constructor TAllTask.Create;
var
  i: integer;
begin
  fTask := TObjectList.Create;
  with FAutoPilot do
    for i := 0 to ListBox1.Count - 1 do
      begin
        fTask.Add(TTask.Create(ListBox1.Items[i]));
      end;
end;

destructor TAllTask.Destroy;
begin
  fTask.Free;
  inherited;
end;

function TAllTask.GetTask;
begin
  result := TTask(fTask[i])
end;

procedure TAllTask.SaveData;
var
  i: integer;
begin
  with IniFile do
    begin
      WriteInteger(TaskFolder, 'Task_Count', fTask.Count);
      WriteInteger(TaskFolder, 'Interval', fInterval);
    end;
  for i := 0 to fTask.Count - 1 do
    Task[i].SaveData(TaskFolder + '\' + Task[i].fName);
end;

procedure TAllTask.LoadData;
var
  i, Task_Count: integer;
begin
  with IniFile do
    begin
      Task_Count := ReadInteger(TaskFolder, 'Task_Count', 1);
      fInterval := ReadInteger(TaskFolder, 'Interval', 15);
    end;
  for i := 0 to Task_Count - 1 do
    Task[i].LoadData(TaskFolder + '\' + Task[i].fName);
end;

procedure TAllTask.Execute;
var
  i: integer;
begin
  for i := 0 to fTask.Count - 1 do
    if Task[i].fChecked then
      Task[i].Execute;
end;

//===================== TFAutoPilot ====================

procedure TFAutoPilot.FormCreate(Sender: TObject);
begin
  {$IFDEF INIFILE}
  IniFile := TIniFile.Create(IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'PilotoAutomatico.ini');
  {$ELSE}
  IniFile := TRegistryIniFile.Create('Software\LDT\Vesta\Process');
  {$ENDIF}
  APTask := TAllTask.Create;
  APTask.LoadData;
  ListBox1.Checked[0] := true;
end;

procedure TFAutoPilot.FormDestroy(Sender: TObject);
begin
  APTask.Free;
end;

procedure TFAutoPilot.CheckListBox1DblClick(Sender: TObject);
begin
  with APTask[ListBox1.ItemIndex].Product[CheckListBox1.Items[CheckListBox1.ItemIndex]] do
    begin
      WriteForm;
      if FEditAutoPilot.ShowModal = mrOk then
        ReadForm;
    end;
end;

procedure TFAutoPilot.CheckListBox2DblClick(Sender: TObject);
begin
  with APTask[ListBox1.ItemIndex].TSProduct[CheckListBox2.Items[CheckListBox2.ItemIndex]] do
    begin
      WriteForm;
      if FEditAutoPilot.ShowModal = mrOk then
        ReadForm;
    end;
end;

procedure TFAutoPilot.WriteForm;
var
  i: integer;
begin
  APTask.LoadData;
//  UpDown1.Position := APTask.fInterval;
  ListBox1.Clear;
  for i := 0 to APTask.fTask.Count - 1 do
    begin
      ListBox1.Items.Add(APTask[i].fName);
      ListBox1.Checked[i]:= APTask[i].fChecked;
    end;
end;

procedure TFAutoPilot.ReadForm;
var
  i: integer;
begin
//  APTask.fInterval := UpDown1.Position;
  for i := 0 to APTask.fTask.Count - 1 do
    begin
      APTask[i].fName := ListBox1.Items[i];
      APTask[i].fChecked := ListBox1.Checked[i];
    end;
  APTask.SaveData;
end;

procedure TFAutoPilot.ListBox1Click(Sender: TObject);
begin
  APTask[ListBox1.ItemIndex].WriteForm;
end;

procedure TFAutoPilot.CheckListBox1ClickCheck(Sender: TObject);
begin
  if ListBox1.ItemIndex = -1 then
    MessageDlg('Seleccione una tarea', mtError, [mbOk], 0)
  else
    APTask[ListBox1.ItemIndex].ReadForm;
end;

procedure TFAutoPilot.FormShow(Sender: TObject);
begin
  FShell.Timer1.Enabled := false;
  if ListBox1.ItemIndex = -1 then
    begin
      ListBox1.ItemIndex := 0;
      ListBox1Click(Sender);
    end;
end;

procedure TFAutoPilot.SpeedButton1Click(Sender: TObject);
var
  temp: string;
begin
  temp := Edit2.Text;
  SelectDirectory('Seleccione la carpeta origen de observaciones', '', temp);
  Edit2.Text := temp;
end;

procedure TFAutoPilot.CheckListBox3DblClick(Sender: TObject);
begin
  with APTask[ListBox1.ItemIndex].TSProduct[CheckListBox3.Items[CheckListBox3.ItemIndex]] do
    begin
      WriteForm;
      if FEditAutoPilot.ShowModal = mrOk then
        ReadForm;
    end;
end;

procedure TFAutoPilot.Button3Click(Sender: TObject);
begin
  ReadForm;
  FShell.Timer1Timer(Sender);
end;

procedure TFAutoPilot.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  with FShell do
    Timer1.Enabled := CheckBox1.Checked;
end;

procedure TFAutoPilot.Button1Click(Sender: TObject);
begin
  ReadForm;
end;

initialization
  TaskThreadRunning := TEvent.Create(nil, true, false, '');
finalization
  TaskThreadRunning.Free;
end.
