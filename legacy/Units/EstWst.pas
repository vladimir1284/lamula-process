unit EstWst;

interface

uses
  VertProduct, Observation, Measure, Angle, Plane, DataSource,
  EditForm, GridForm;

type
  TEstWst = class;

  TEstWst = class(TVertProduct)
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
  Notify, Movement, Scan, EstWstGrid,
  VertEdit, EstWstEdit;

// TEstWst methods

class function TEstWst.Name : string;
begin
  Result := 'Max_EW';
end;

class function TEstWst.Description : string;
begin
  Result := 'Vista lateral de maximos';
end;

class function TEstWst.ImageIndex : integer;
begin
  Result := 11;
end;

class function TEstWst.EditForm : TFEdit;
begin
  if FEstWstEdit = nil
    then Application.CreateForm(TFEstWstEdit, FEstWstEdit);
  Result := FEstWstEdit;
end;

function TEstWst.CreateViewForm : TFGrid;
begin
  Result := inherited CreateViewForm;
  Result.GrdGap := Point(5, 100);
end;

function TEstWst.GetLabel : string;
begin
  Result := Format('EW Maxs, %s %dm - %dm', [MeasureVar(Measure), Bottom, Top]);
end;

function TEstWst.GetBrief : string;
begin
  Result := Format('%s, %s entre %dm y %dm',
                   [Name, MeasureVar(Measure), Bottom, Top]);
end;

procedure TEstWst.Render;
begin
  Notify.Declare([0, 100]);
  fGrid := TEstWstGrid.Initialize(Area, Length, CellHeight, Bottom, Top);
  try
    TEstWstGrid(fGrid).Render(Observation, Channel, Measure);
  except
    FreeAndNil(fGrid);
    raise;
  end;
  inherited;
end;

procedure TEstWst.Show;
begin
  inherited;
  ViewForm.AdjustHorz;
end;

end.
