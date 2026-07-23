unit Wind;

interface

uses
  HorzProduct, DataSource,
  GridForm, EditForm;

type
  TWind = class;

  TWind = class(THorzProduct)
  public
    class function  Name                     : string;   override;
    class function  Description              : string;   override;
    class function  ImageIndex               : integer;  override;
    class function  EditForm                 : TFEdit;   override;
    class function  Setup( D : TDataSource ) : boolean;  override;
    class procedure SetDefault;                          override;
  protected
    function GetLabel : string;  override;
    function GetBrief : string;  override;
  public
    procedure Render; override;
  private
    fWindHeight: integer;
  published
    property Height: integer read fWindHeight write fWindHeight;
  end;

implementation

uses
  Forms, SysUtils,
  Settings,
  Notify, Observation, ScanGrid, Measure, Plane,
  WindScan,
  WindEdit;

// Wind methods

class function TWind.Name : string;
begin
  Result := 'Viento';
end;

class function TWind.Description : string;
begin
  Result := 'Viento a una altura';
end;

class function TWind.ImageIndex : integer;
begin
  Result := 7;
end;

class function TWind.EditForm : TFEdit;
begin
  if FWindEdit = nil
    then Application.CreateForm( TFWindEdit, FWindEdit );
  Result := FWindEdit;
end;

class function TWind.Setup( D : TDataSource ) : boolean;
var
  b: boolean;
begin
  Result := inherited Setup(D);
  if Result
    then
      with EditForm as TFWindEdit do
        begin
          WindHeight  := theSettings.DefaultWindHeight;
          Measure := unMS;
        end;
end;

class procedure TWind.SetDefault;
begin
  with EditForm as TFWindEdit do
    begin
      theSettings.DefaultWindHeight := Height;
    end;
end;

function TWind.GetLabel : string;
begin
  Result := Format('Viento, %s %dm', [MeasureVar(Measure), Height]);
end;

function TWind.GetBrief : string;
begin
  Result := Format('%s, %s a %dm',
                   [Name, MeasureVar(Measure), Height]);
end;

procedure TWind.Render;
var
  GridScan : TWindScan;
begin
  Notify.Declare([0, 90, 100]);
  with Observation.Channel[Channel] do
    GridScan := TWindScan.Initialize(PlanePoint(MaxCells, Sectors), Measure,
                                     Height);
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

end.

