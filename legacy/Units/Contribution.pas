unit Contribution;

interface

uses
  Product,
  HorzProduct, DataSource, Measure,
  EditForm;

type
  TContribution     = class;
  TContributionAuto = class;

  TContribution = class(THorzProduct)
  public
    class function  Name        : string;                override;
    class function  Description : string;                override;
    class function  ImageIndex  : integer;               override;
    class function  EditForm    : TFEdit;                override;
    class function  Setup( D : TDataSource ) : boolean;  override;
    class procedure SetDefault;                          override;
    class function  AutoClass   : CProductAuto;          override;
  private
    fInterval : TDateTime;
  published
    property Interval : TDateTime read fInterval write fInterval;
  protected
    function  GetLabel : string;  override;
    function  GetBrief : string;  override;
    procedure GetEditData;        override;
    procedure SetEditData;        override;
  public
    procedure Render; override;
  end;

  TContributionAuto = class(THorzPrdAuto)
  automated
    function  GetInterval : TDateTime;
    procedure SetInterval( T : TDateTime );
  automated
    property Interval : TDateTime read GetInterval write SetInterval;
  end;

implementation

uses
  Forms, SysUtils,
  Settings,
  TimeSpan, Observation, Notify, Plane,
  ContributionScan, ScanGrid,
  ContributionEdit,
  SupressStatus; //mio

const
  FiveMinutes = 5 / (24 * 60);

// TContribution methods

class function TContribution.Name : string;
begin
  Result := 'Precipitacion';
end;

class function TContribution.Description : string;
begin
  Result := 'Acumulado de precipitacion en un intervalo de tiempo';
end;

class function TContribution.ImageIndex : integer;
begin
  Result := 15;
end;

class function TContribution.EditForm : TFEdit;
begin
  if FContributionEdit = nil
    then Application.CreateForm(TFContributionEdit, FContributionEdit);
  Result := FContributionEdit;
end;

class function TContribution.Setup( D : TDataSource ) : boolean;
var
  b: boolean;
begin
  Result := inherited Setup(D);
  if Result
    then
      with EditForm as TFContributionEdit do
        begin
          Bottom   := theSettings.DefaultCAPPIBot;
          Top      := theSettings.DefaultCAPPITop;
          Interval := FiveMinutes;
          Supressing := theSettings.DefaultC_SStatusContribution; ///mio
          b := Supressing;//mio
        end;
      theSupressStatus := b;  /////mio
end;

class procedure TContribution.SetDefault;
begin
  inherited;
  with EditForm as TFContributionEdit do
    begin
      theSettings.DefaultCAPPIBot := Bottom;
      theSettings.DefaultCAPPITop := Top;
      theSettings.DefaultC_SStatusContribution := Supressing; //mio
    end;
end;

class function TContribution.AutoClass : CProductAuto;
begin
  Result := TContributionAuto;
end;

function TContribution.GetLabel : string;
begin
  Result := Format('Rainfall, %s', [FormatDateTime('n:ss', Interval)]);
end;

function TContribution.GetBrief : string;
begin
  Result := Format('%s, t = %s', [Name, FormatDateTime('n:ss', Interval)]);
end;

procedure TContribution.Render;
var
  GridScan : TContributionScan;
begin
  Notify.Declare([0, 90, 100]);
  with Observation.Channel[Channel] do
    GridScan := TContributionScan.Initialize(PlanePoint(MaxCells, Sectors),
                                             Bottom, Top,
                                             Interval,
                                             Observation.Time,
                                             Observation.Time + Interval);
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

procedure TContribution.GetEditData;
begin
  inherited;
  fInterval := (EditForm as TFContributionEdit).Interval;
end;

procedure TContribution.SetEditData;
begin
  inherited;
  (EditForm as TFContributionEdit).Interval := fInterval;
end;

// TContributionAuto methods

function TContributionAuto.GetInterval : TDateTime;
begin
  Result := (Product as TContribution).Interval;
end;

procedure TContributionAuto.SetInterval( T : TDateTime );
begin
  (Product as TContribution).Interval := T;
end;

end.
