unit TopDown;

interface

uses
  HorzProduct, Observation, Plane, Measure, Angle, ScanGrid, Grid,
  EditForm;

type
  TTopDown = class;

  TTopDown = class(THorzProduct)
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
  TopDownScan,
  TopDownEdit, GridForm;

// TTopDown methods

class function TTopDown.Name : string;
begin
  Result := 'Maximos';
end;

class function TTopDown.Description : string;
begin
  Result := 'Vista superior de maximos';
end;

class function TTopDown.ImageIndex : integer;
begin
  Result := 5;
end;

class function TTopDown.EditForm : TFEdit;
begin
  if FTopDownEdit = nil
    then Application.CreateForm(TFTopDownEdit, FTopDownEdit);
  Result := FTopDownEdit;
end;

function TTopDown.GetLabel : string;
begin
  Result := Format('Maxs, %s %dm - %dm', [MeasureVar(Measure), Bottom, Top]);
end;

function TTopDown.GetBrief : string;
begin
  Result := Format('%s, %s entre %dm y %dm',
                   [Name, MeasureVar(Measure), Bottom, Top]);
end;

procedure TTopDown.Render;
var
  GridScan : TTopDownScan;
begin
  Notify.Declare([0, 90, 100]);
  with Observation.Channel[Channel] do
    GridScan := TTopDownScan.Initialize(PlanePoint(MaxCells, Sectors), Measure,
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
