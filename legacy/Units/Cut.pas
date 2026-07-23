unit Cut;

interface

uses
  Product,
  VertProduct, Observation, Measure, Angle, Plane, DataSource,
  EditForm, GridForm;

type
  TCut     = class;
  TCutAuto = class;

  TCut = class(TVertProduct)
  public
    class function Name        : string;        override;
    class function Description : string;        override;
    class function EditForm    : TFEdit;        override;
    class function ImageIndex  : integer;       override;
    class function AutoClass   : CProductAuto;  override;
  protected
    function CreateViewForm : TFGrid;  override;
    function GetLabel       : string;  override;
    function GetBrief       : string;  override;
  public
    function  Default : boolean;  override;
    procedure Render;             override;
    procedure Show;               override;
  end;

  TCutAuto = class(TVertPrdAuto)
  automated
    property OriginX : integer read GetWest  write SetWest;
    property OriginY : integer read GetNorth write SetNorth;
    property FinishX : integer read GetEast  write SetEast;
    property FinishY : integer read GetSouth write SetSouth;
  end;

implementation

uses
  Classes,
  Settings,
  Forms, SysUtils,
  Notify, Movement, Scan,
  CutGrid,
  VertEdit, CutEdit;

// TCut methods

class function TCut.Name : string;
begin
  Result := 'Corte';
end;

class function TCut.Description : string;
begin
  Result := 'Corte vertical entre dos puntos';
end;

class function TCut.ImageIndex : integer;
begin
  Result := 9;
end;

class function TCut.EditForm : TFEdit;
begin
  if FCutEdit = nil
    then Application.CreateForm(TFCutEdit, FCutEdit);
  Result := FCutEdit;
end;

class function TCut.AutoClass : CProductAuto;
begin
  Result := TCutAuto;
end;

function TCut.CreateViewForm : TFGrid;
begin
  Result := inherited CreateViewForm;
  Result.GrdGap := Point(25, 5);
//Result.Zoom   := 150;
  Result.Panel4.Visible := false;
  Result.Splitter1.Visible := false;
end;

function TCut.Default : boolean;
begin
  inherited Default;
  Result := false;
end;

function TCut.GetLabel : string;
begin
  Result := Format('Vertical Cut, %s', [MeasureVar(Measure)]);
end;

function TCut.GetBrief : string;
begin
  Result := Format('%s, %s (%d,%d)-(%d,%d)',
                   [Name, MeasureVar(Measure),
                    Area.Left   * Length div 1000,
                    Area.Top    * Length div 1000,
                    Area.Right  * Length div 1000,
                    Area.Bottom * Length div 1000]);
end;

procedure TCut.Render;
begin
  Notify.Declare([0, 100]);
  fGrid := TCutGrid.Initialize(Length, CellHeight, Bottom, Top,
                               Area.A, Area.B);
  try
    TCutGrid(fGrid).Render(Observation, Channel, Measure);
  except
    FreeAndNil(fGrid);
    raise;
  end;
  inherited;
end;

procedure TCut.Show;
var
  first: boolean;
begin
  first := ViewForm.Grid = nil;
  inherited;
  if first then
    ViewForm.Zoom := 150
  else
    ViewForm.Zoom := ViewForm.Zoom;  
  ViewForm.Adjust;
end;

end.
