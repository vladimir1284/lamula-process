unit Accumulate;

interface

uses
  Product,
  HorzProduct, DataSource, Measure,
  EditForm;

type
  TAccumulate     = class;
  TAccumulateAuto = class;

  TAccumulate = class(THorzProduct)
  public
    class function  Name        : string;                 override;
    class function  Description : string;                 override;
    class function  ImageIndex  : integer;                override;
    class function  EditForm    : TFEdit;                 override;
    class function  Accept( D : CDataSource ) : boolean;  override;
    class function  Setup ( D : TDataSource ) : boolean;  override;
    class procedure SetDefault;                           override;
    class function  AutoClass   : CProductAuto;           override;
    class function  CanAnimate  : boolean;                override;
  private
    fInterval  : TDateTime;
    fStartTime : TDateTime;
    fStopTime  : TDateTime;
  published
    property Interval  : TDateTime read fInterval  write fInterval;
    property StartTime : TDateTime read fStartTime write fStartTime;
    property StopTime  : TDateTime read fStopTime  write fStopTime;
  protected
    function  GetLabel : string;  override;
    function  GetBrief : string;  override;
    procedure GetEditData;        override;
    procedure SetEditData;        override;
  public
    procedure Render; override;
  end;

  TAccumulateAuto = class(THorzPrdAuto)
  automated
    function  GetStartTime : TDateTime;
    function  GetStopTime  : TDateTime;
    procedure SetStartTime( T : TDateTime );
    procedure SetStopTime ( T : TDateTime );
  automated
    property StartTime : TDateTime read GetStartTime write SetStartTime;
    property StopTime  : TDateTime read GetStopTime  write SetStopTime;
  end;

implementation

uses
  Forms, SysUtils,
  Settings,
  TimeSpan, Observation, Notify, Plane,
  ContributionScan, ScanGrid,
  AccumulateEdit,
  SupressStatus; ///mio********;;

const
  FiveMinutes =  5 / (24 * 60);
  TenMinutes  = 10 / (24 * 60);

// TAccumulate methods

class function TAccumulate.Name : string;
begin
  Result := 'Acumulado';
end;

class function TAccumulate.Description : string;
begin
  Result := 'Acumulado de precipitacion durante un periodo de tiempo';
end;

class function TAccumulate.ImageIndex : integer;
begin
  Result := 0;
end;

class function TAccumulate.EditForm : TFEdit;
begin
  if FAccumulateEdit = nil
    then Application.CreateForm( TFAccumulateEdit, FAccumulateEdit );
  Result := FAccumulateEdit;
end;

class function TAccumulate.Accept( D : CDataSource ) : boolean;
begin
  Result := D.InheritsFrom(TTimeSpan);
end;

class function TAccumulate.Setup( D : TDataSource ) : boolean;
var
  b: boolean;
begin
  Result := inherited Setup(D);
  if Result
    then
      with EditForm as TFAccumulateEdit, D as TTimeSpan do
        begin
          Bottom    := theSettings.DefaultCAPPIBot;
          Top       := theSettings.DefaultCAPPITop;
          StartTime := FirstTime;
          StopTime  := LastTime + FiveMinutes;
          Interval  := FiveMinutes;
          Supressing := theSettings.DefaultC_SStatusCAPPI; ///mio
          b := Supressing;//mio
        end;
      theSupressStatus :=b;  /////mio
end;

class procedure TAccumulate.SetDefault;
begin
  inherited;
  with EditForm as TFAccumulateEdit do
    begin
      theSettings.DefaultCAPPIBot := Bottom;
      theSettings.DefaultCAPPITop := Top;
      theSettings.DefaultC_SStatusCAPPI := Supressing; //mio
    end;
end;

class function TAccumulate.AutoClass : CProductAuto;
begin
  Result := TAccumulateAuto;
end;

class function TAccumulate.CanAnimate : boolean;
begin
  Result := false;
end;

function TAccumulate.GetLabel : string;
begin
  Result := 'Rainfall accumulate';
end;

function TAccumulate.GetBrief : string;
begin
  Result := Format('%s desde %s hasta %s',
                   [Name,
                    FormatDateTime('h:nn-ddddd', StartTime),
                    FormatDateTime('h:nn-ddddd', StopTime)]);
end;

procedure TAccumulate.Render;
var
  GridScan : TContributionScan;
begin
  Notify.Declare([0, 90, 100]);
  with TimeSpan.Channel[Channel] do
    GridScan := TContributionScan.Initialize(PlanePoint(MaxCells, Sectors),
                                             Bottom, Top,
                                             Interval,
                                             StartTime, StopTime);
  try
    GridScan.Render(TimeSpan, Channel);
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

procedure TAccumulate.GetEditData;
begin
  inherited;
  with EditForm as TFAccumulateEdit do
    begin
      fStartTime := StartTime;
      fStopTime  := StopTime;
      fInterval  := Interval; 
    end;
end;

procedure TAccumulate.SetEditData;
begin
  inherited;
  with EditForm as TFAccumulateEdit do
    begin
      StartTime := fStartTime;
      StopTime  := fStopTime;
      Interval  := fInterval;
    end;
end;

// TAccumulateAuto methods

function TAccumulateAuto.GetStartTime : TDateTime;
begin
  Result := (Product as TAccumulate).StartTime;
end;

function TAccumulateAuto.GetStopTime : TDateTime;
begin
  Result := (Product as TAccumulate).StopTime;
end;

procedure TAccumulateAuto.SetStartTime( T : TDateTime );
begin
  (Product as TAccumulate).StartTime := T;
end;

procedure TAccumulateAuto.SetStopTime( T : TDateTime );
begin
  (Product as TAccumulate).StopTime := T;
end;

end.
