unit VIL;

interface

uses
  DataSource,
  HorzProduct, Observation, Plane, Measure, Angle, ScanGrid, Grid,
  EditForm;

type
  TVIL = class(THorzProduct)
  public
    class function  Name        : string;                 override;
    class function  Description : string;                 override;
    class function  ImageIndex  : integer;                override;
    class function  EditForm    : TFEdit;                 override;
    class function  Setup ( D : TDataSource ) : boolean;  override;
    class procedure SetDefault;                           override;
  protected
    function GetLabel : string;  override;
    function GetBrief : string;  override;
  public
    procedure Render;  override;
  private
    fC1, fC2 : double;
  public
    property C1 : double read fC1 write fC1;
    property C2 : double read fC2 write fC2;
  protected
    procedure GetEditData;  override;
    procedure SetEditData;  override;
  end;

implementation

uses
  Forms, SysUtils,
  Settings,
  Notify, Movement, Scan,
  VilScan,
  VilEdit, GridForm,
  SupressStatus;  ///mio

// TVil methods

class function TVil.Name : string;
begin
  Result := 'VIL';
end;

class function TVil.Description : string;
begin
  Result := 'Volumen Integral Liquido';
end;

class function TVil.ImageIndex : integer;
begin
  Result := 12;
end;

class function TVil.EditForm : TFEdit;
begin
  if FVilEdit = nil
    then Application.CreateForm(TFVilEdit, FVilEdit);
  Result := FVilEdit;
end;

class function TVil.Setup ( D : TDataSource ) : boolean;
var
  b : boolean; //mio
begin
  Result := inherited Setup(D);
  if Result
    then
      with EditForm as TFVilEdit do
        begin
          C1 := theSettings.DefaultVilC1;
          C2 := theSettings.DefaultVilC2;
          Supressing := theSettings.DefaultC_SStatusVil; ///mio
          b:= Supressing;//mio
        end;
     theSupressStatus :=b;  /////mio
end;

class procedure TVil.SetDefault;
begin
  inherited;
  with EditForm as TFVilEdit do
    begin
      theSettings.DefaultVilC1 := C1;
      theSettings.DefaultVilC2 := C2;
      theSettings.DefaultC_SStatusVil := Supressing; //mio
    end;
end;

function TVil.GetLabel : string;
begin
  Result := 'VIL';
end;

function TVil.GetBrief : string;
begin
  Result := Format('%s entre %dm y %dm',
                   [Name, Bottom, Top]);
end;

procedure TVil.Render;
var
  GridScan : TVilScan;
begin
  Notify.Declare([0, 90, 100]);
  with Observation.Channel[Channel] do
    GridScan := TVilScan.Initialize(PlanePoint(MaxCells, Sectors),
                                    Bottom, Top, C1, C2);
  try
    GridScan.Render(Observation, Channel);
    fGrid := TScanGrid.Initialize(Area, Length);
    try
      TScanGrid(fGrid).RenderScan(GridScan);
    except
      FreeAndNil(fGrid);
      raise;
    end;
  finally
    GridScan.Free;
  end;
  inherited;
end;

procedure TVil.GetEditData;
begin
  inherited;
  with EditForm as TFVilEdit do
    begin
      fC1 := C1;
      fC2 := C2;
    end;
end;

procedure TVil.SetEditData;
begin
  inherited;
  with EditForm as TFVilEdit do
    begin
      C1 := fC1;
      C2 := fC2;
    end;
end;

end.
