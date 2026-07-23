unit Maxs;

interface

uses
  HorzProduct, RadarData, Observation, Plane, Measure, Angle, ScanGrid, Grid,
  EditForm;

type
  TMaxs = class(THorzProduct)
  public
    class function Name        : string;   override;
    class function Description : string;   override;
    class function ImageIndex  : integer;  override;
    class function EditForm    : TFEdit;   override;
  protected
    function GetLabel : string;  override;
    function GetBrief : string;  override;
  public
    procedure Render;  override;
  end;

implementation

uses
  Forms, SysUtils,
  Notify, Movement, Scan,
  MaxsScan,
  MaxsEdit, GridForm;

// TMaxs methods

class function TMaxs.Name : string;
begin
  Result := 'Altura';
end;

class function TMaxs.Description : string;
begin
  Result := 'Altura de ecos maximos';
end;

class function TMaxs.ImageIndex : integer;
begin
  Result := 2;
end;

class function TMaxs.EditForm : TFEdit;
begin
  if FMaxsEdit = nil
    then Application.CreateForm(TFMaxsEdit, FMaxsEdit);
  Result := FMaxsEdit;
end;

function TMaxs.GetLabel : string;
begin
  Result := Format('Maxs Height, %s', [MeasureVar(Measure)]);
end;

function TMaxs.GetBrief : string;
begin
  Result := Format('%s de maximos, %s entre %dm y %dm',
                   [Name, MeasureVar(Measure), Bottom, Top]);
end;

procedure TMaxs.Render;
var
  GridScan : TMaxsScan;
begin
  Notify.Declare( [0, 90, 100] );
  with Observation.Channel[Channel] do
    GridScan := TMaxsScan.Initialize(PlanePoint(MaxCells, Sectors), Measure,
                                     Bottom, Top);
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
