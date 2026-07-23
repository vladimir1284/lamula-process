unit PPI;

interface

uses
  HorzProduct, Product, Observation, Plane, Measure, Angle, ScanGrid, Grid,
  PPIScan,
  EditForm;

type
  TPPI     = class;
  TPPIAuto = class;

  TPPI = class(THorzProduct)
  public
    class function Name        : string;        override;
    class function Description : string;        override;
    class function EditForm    : TFEdit;        override;
    class function ImageIndex  : integer;       override;
    class function AutoClass   : CProductAuto;  override;
  public
    procedure Render;  override;
  protected
    function  GetLabel : string;  override;
    function  GetBrief : string;  override;
    procedure GetEditData;        override;
    procedure SetEditData;        override;
  private
    fScanIndex : integer;
    fElevation : TAngle;
  private
    procedure SetScanIndex( I : integer );
    procedure SetElevation( E : TAngle );
  published
    property ScanIndex : integer read fScanIndex write SetScanIndex stored false;
    property Elevation : TAngle  read fElevation write SetElevation;
  private
    function PPIProductScan : TPPIScan;
  end;

  TPPIAuto = class(THorzPrdAuto)
  automated
    function  GetElevation : single;
    procedure SetElevation( E : single );
  automated
    property Elevation : single read GetElevation write SetElevation;
  end;

implementation

uses
  Forms, SysUtils,
  Notify, Movement, Scan,
  PPIEdit, GridForm;

// TPPI methods

class function TPPI.Name : string;
begin
  Result := 'PPI';
end;

class function TPPI.Description : string;
begin
  Result := 'PPI';
end;

class function TPPI.EditForm : TFEdit;
begin
  if FPPIEdit = nil
    then Application.CreateForm(TFPPIEdit, FPPIEdit);
  Result := FPPIEdit;
end;

class function TPPI.ImageIndex : integer;
begin
  Result := 1;
end;

class function TPPI.AutoClass : CProductAuto;
begin
  Result := TPPIAuto;
end;

function TPPI.GetLabel : string;
begin
  Result := Format('PPI, %s %.1f°', [MeasureVar(Measure), CodeAngle(Elevation)]);
end;

function TPPI.GetBrief : string;
begin
  Result := Format('%s, %s a %.1f°',
                   [Name, MeasureVar(Measure), CodeAngle(Elevation)]);
end;

procedure TPPI.Render;
var
  GridScan : TPPIScan;
begin
  Notify.Declare([0, 100]);
  GridScan := PPIProductScan;
  try
    fGrid := TScanGrid.Initialize(Area, Length);
    try
      Elevation := GridScan.Angle;
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

function TPPI.PPIProductScan: TPPIScan;
begin
  if (ScanIndex >= 0) and (ScanIndex < Observation.Movements)
    then Result := TPPIScan.RenderMove(Observation.Movement[ScanIndex] as THorzMove, Measure)
    else
      begin
        with Observation.Channel[Channel] do
          Result := TPPIScan.Initialize(PlanePoint(MaxCells, Sectors), Measure,
                                          Elevation, Beam);
        Result.Render(Observation, Channel);
      end;
end;

procedure TPPI.GetEditData;
begin
  inherited;
  with EditForm as TFPPIEdit do
    Elevation := Elevation1.Desired;
end;

procedure TPPI.SetEditData;
begin
  inherited;
  with EditForm as TFPPIEdit do
    Elevation1.Desired := Elevation;
end;

procedure TPPI.SetElevation(E: TAngle);
begin
  fScanIndex := -1;
  fElevation := E;
end;

procedure TPPI.SetScanIndex(I: integer);
begin
  fScanIndex := I;
//... Update Elevation ???
end;

// TPPIAuto methods

function TPPIAuto.GetElevation : single;
begin
  Result := CodeAngle((Product as TPPI).Elevation);
end;

procedure TPPIAuto.SetElevation( E : single );
begin
  (Product as TPPI).Elevation := AngleCode(E);
end;

end.
