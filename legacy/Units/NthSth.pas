unit NthSth;

interface

uses
  VertProduct, Observation, Measure, Angle, Plane, DataSource,
  EditForm, GridForm;

type
  TNthSth = class;

  TNthSth = class(TVertProduct)
  public
    class function Name        : string;   override;
    class function Description : string;   override;
    class function ImageIndex  : integer;  override;
    class function EditForm    : TFEdit;   override;
  protected
    function CreateViewForm : TFGrid;  override;
    function GetLabel       : string;  override;
    function GetBrief       : string;  override;
  public
    procedure Render;  override;
    procedure Show;    override;
  end;

implementation

uses
  Classes,
  Settings,
  Forms, SysUtils,
  Notify, Movement, Scan,
  NthSthGrid,
  VertEdit, NthSthEdit;

// TNthSth methods

class function TNthSth.Name : string;
begin
  Result := 'Max_NS';
end;

class function TNthSth.Description : string;
begin
  Result := 'Vista frontal de maximos';
end;

class function TNthSth.ImageIndex : integer;
begin
  Result := 11;
end;

class function TNthSth.EditForm : TFEdit;
begin
  if FNthSthEdit = nil
    then Application.CreateForm(TFNthSthEdit, FNthSthEdit);
  Result := FNthSthEdit;
end;

function TNthSth.CreateViewForm : TFGrid;
begin
  Result := inherited CreateViewForm;
  Result.GrdGap := Point(100, 5);
end;

function TNthSth.GetLabel : string;
begin
  Result := Format('NS Maxs, %s %dm - %dm', [MeasureVar(Measure), Bottom, Top]);
end;

function TNthSth.GetBrief : string;
begin
  Result := Format('%s, %s entre %dm y %dm',
                   [Name, MeasureVar(Measure), Bottom, Top]);
end;

procedure TNthSth.Render;
begin
  Notify.Declare([0, 100]);
  fGrid := TNthSthGrid.Initialize(Area, Length, CellHeight, Bottom, Top);
  try
    TNthSthGrid(fGrid).Render(Observation, Channel, Measure);
  except
    FreeAndNil(fGrid);
    raise;
  end;
  inherited;
end;

procedure TNthSth.Show;
begin
  inherited;
  ViewForm.AdjustVert;
end;

end.
