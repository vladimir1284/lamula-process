unit RHI;

interface

uses
  VertProduct, Product, Observation, Measure, Angle, Plane, Grid, DataSource,
  EditForm, GridForm, RHIScan;

type
  TRHI     = class;
  TRHIAuto = class;

  TRHI = class(TVertProduct)
  public
    class function Name        : string;        override;
    class function Description : string;        override;
    class function ImageIndex  : integer;       override;
    class function EditForm    : TFEdit;        override;
    class function AutoClass   : CProductAuto;  override;
  protected
    function CreateViewForm : TFGrid;  override;
  protected
    function  GetLabel : string;  override;
    function  GetBrief : string;  override;
    procedure GetEditData;        override;
    procedure SetEditData;        override;
  public
    procedure Render;  override;
    procedure Show;    override;
  private
    fScanIndex : integer;
    fAzimut    : TAngle;
  private
    procedure SetScanIndex( I : integer );
    procedure SetAzimut   ( A : TAngle );
  published
    property ScanIndex : integer read fScanIndex write SetScanIndex stored false;
    property Azimut    : TAngle  read fAzimut    write SetAzimut;
  private
    function RHIProductScan : TRHIScan;
  private
    function ScanFromMove( Index : integer ) : TRHIScan;
    function ScanFromObs                     : TRHIScan;
  end;

  TRHIAuto = class(TVertPrdAuto)
  automated
    function  GetAzimut : single;
    procedure SetAzimut( A : single );
  automated
    property Azimut : single read GetAzimut write SetAzimut;
  end;

implementation

uses
  Classes,
  Settings,
  Forms, SysUtils,
  Notify, Movement, Scan,
  RHIGrid,
  VertEdit, RHIEdit;

// TRHI methods

class function TRHI.Name : string;
begin
  Result := 'RHI';
end;

class function TRHI.Description : string;
begin
  Result := 'RHI';
end;

class function TRHI.ImageIndex : integer;
begin
  Result := 3;
end;

class function TRHI.EditForm : TFEdit;
begin
  if FRHIEdit = nil
    then Application.CreateForm(TFRHIEdit, FRHIEdit);
  Result := FRHIEdit;
end;

class function TRHI.AutoClass : CProductAuto;
begin
  Result := TRHIAuto;
end;

function TRHI.CreateViewForm : TFGrid;
begin
  Result := inherited CreateViewForm;
  Result.GrdGap := Point(100, 5);
end;

function TRHI.GetLabel : string;
begin
  Result := Format('RHI, %s %.1f°', [MeasureVar(Measure), CodeAngle(Azimut)]);
end;

function TRHI.GetBrief : string;
begin
  Result := Format('%s, %s a %.1f°',
                   [Name, MeasureVar(Measure), CodeAngle(Azimut)]);
end;

procedure TRHI.Render;
var
  GridScan : TRHIScan;
begin
  Notify.Declare([0, 100]);
  GridScan := RHIProductScan;
  try
    with Observation.Channel[Channel] do
      fGrid := TRHIGrid.Initialize(Cells * Length div Self.Length,
                                   Bottom, Top,
                                   Self.Length, CellHeight, Azimut );
    try
      //Azimut := GridScan.Azimut;
      TRHIGrid(fGrid).RenderScan(GridScan);
    except
      FreeAndNil(fGrid);
      raise;
    end;
  finally
    GridScan.Free;
  end;
  inherited;
end;

procedure TRHI.GetEditData;
begin
  inherited;
  with EditForm as TFRHIEdit do
    Azimut := Azimut1.Position;
end;

procedure TRHI.SetEditData;
begin
  inherited;
  with EditForm as TFRHIEdit do
    Azimut1.Desired := Azimut;
end;

function TRHI.RHIProductScan : TRHIScan;
var
  MoveIndex : integer;
begin
  if ScanIndex < 0
    then
      with Observation do
        begin
          for MoveIndex := 0 to Movements - 1 do
            with MoveDesc[MoveIndex] do
              if (Kind = pkVertical) and
                 (Channel = Self.Channel) and
                 (Angle = Self.Azimut)
                then break;
          if MoveIndex < Movements
            then ScanIndex := MoveIndex;
        end;
  if (ScanIndex >= 0) and (ScanIndex < Observation.Movements)
    then Result := ScanFromMove(ScanIndex)
    else Result := ScanFromObs;
end;

function TRHI.ScanFromMove(Index: integer): TRHIScan;
var
  M : TMovement;
begin
  M := Observation.Movement[Index];
  M.Radiuses := MaxCells;
  try
    Result := TRHIScan.RenderMove(M as TVertMove, Measure)
  finally
    M.Free;
  end;
end;

function TRHI.ScanFromObs: TRHIScan;
begin
  with Observation.Channel[Channel] do
    begin
      Result := TRHIScan.Initialize(MaxCells, Sectors, Measure,
                                    Azimut, Beam, AngleCode(-3), AngleCode(60));
      Result.Render(Observation, Index);
    end;
end;

procedure TRHI.Show;
begin
  inherited;
  ViewForm.Zoom := 150;
  ViewForm.Adjust;
end;

procedure TRHI.SetAzimut(A: TAngle);
begin
  fScanIndex := -1;
  fAzimut := A;
end;

procedure TRHI.SetScanIndex(I: integer);
begin
  fScanIndex := I;
//... Update Azimut ???
end;

// TRHIAuto methods

function TRHIAuto.GetAzimut : single;
begin
  Result := CodeAngle((Product as TRHI).Azimut);
end;

procedure TRHIAuto.SetAzimut( A : single );
begin
  (Product as TRHI).Azimut := AngleCode(A);
end;

end.
