unit Tops;

interface

uses
  Product,
  HorzProduct, DataSource, Plane, Measure, Angle, ScanGrid, Grid,
  EditForm;

type
  TTops     = class;
  TTopsAuto = class;

  TTops = class(THorzProduct)
  public
    class function  Name        : string;                override;
    class function  Description : string;                override;
    class function  ImageIndex  : integer;               override;
    class function  EditForm    : TFEdit;                override;
    class function  Setup( D : TDataSource ) : boolean;  override;
    class procedure SetDefault;                          override;
    class function  AutoClass   : CProductAuto;          override;
  private
    fMinimun  : TCode;
    fLocation : integer;
  published
    property Minimum  : TCode   read fMinimun  write fMinimun;
    property Location : integer read fLocation write fLocation;
  protected
    function  GetLabel : string;  override;
    function  GetBrief : string;  override;
    procedure GetEditData;        override;
    procedure SetEditData;        override;
  public
    procedure Render;  override;
  end;

  TTopsAuto = class(THorzPrdAuto)
  automated
    function  GetMinimun  : Measure.float;
    function  GetLocation : integer;
    procedure SetMinimun( M : Measure.float );
    procedure SetLocation( L : integer );
  automated
    property Minimun  : Measure.float read GetMinimun  write SetMinimun;
    property Location : integer       read GetLocation write SetLocation;
  end;

implementation

uses
  Forms, SysUtils,
  Settings,
  Notify, Movement, Scan,
  TopsScan,
  TopsEdit, GridForm,
  SupressStatus; ///mio********

// TTops methods

class function TTops.Name : string;
begin
  Result := 'Topes';
end;

class function TTops.Description : string;
begin
  Result := 'Altura de topes';
end;

class function TTops.ImageIndex : integer;
begin
  Result := 2;
end;

class function TTops.EditForm : TFEdit;
begin
  if FTopsEdit = nil
    then Application.CreateForm(TFTopsEdit, FTopsEdit);
  Result := FTopsEdit;
end;

class function TTops.Setup( D : TDataSource ) : boolean;
var
  b: boolean;
begin
  Result := inherited Setup(D);
  if Result
    then
      with EditForm as TFTopsEdit do
        begin
          Min      := theSettings.DefaultTopsMin;
          Location := theSettings.DefaultTopsLoc;
          Supressing := theSettings.DefaultC_SStatusTops; ///mio
          b := Supressing;//mio
        end;
      theSupressStatus := b;  /////mio
end;

class procedure TTops.SetDefault;
begin
  inherited;
  with EditForm as TFTopsEdit do
    begin
      theSettings.DefaultTopsMin := Min;
      theSettings.DefaultTopsLoc := Location;
      theSettings.DefaultC_SStatusTops := Supressing; //mio
    end;
end;

class function TTops.AutoClass : CProductAuto;
begin
  Result := TTopsAuto;
end;

function TTops.GetLabel : string;
begin
  Result := Format('Tops > %.1f %s',
                   [CodeMeasure(Minimum, Measure),
                    MeasureName(Measure)]);
end;

function TTops.GetBrief : string;
begin
  Result := Format('%s > %.1f %s entre %dm y %dm',
                   [Name, CodeMeasure(Minimum, Measure),
                    MeasureName(Measure), Bottom, Top]);
end;

procedure TTops.Render;
var
  GridScan : TTopsScan;
begin
  Notify.Declare([0, 90, 100]);
  with Observation.Channel[Channel] do
    GridScan := TTopsScan.Initialize(PlanePoint(MaxCells, Sectors), Measure,
                                     Bottom, Top,
                                     Minimum, Location);
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

procedure TTops.GetEditData;
begin
  inherited;
  with EditForm as TFTopsEdit do
    begin
      fMinimun  := Min;
      fLocation := Location;
    end;
end;

procedure TTops.SetEditData;
begin
  inherited;
  with EditForm as TFTopsEdit do
    begin
      Min      := fMinimun;
      Location := fLocation;
    end;
end;

// TTopsAuto methods

function TTopsAuto.GetMinimun : Measure.float;
begin
  with Product as TTops do
    Result := CodeMeasure(Minimum, Measure);
end;

function TTopsAuto.GetLocation : integer;
begin
  Result := (Product as TTops).Location;
end;

procedure TTopsAuto.SetMinimun( M : Measure.float );
begin
  with Product as TTops do
    Minimum := MeasureCode(M, Measure);
end;

procedure TTopsAuto.SetLocation( L : integer );
begin
  (Product as TTops).Location := L;
end;

end.
