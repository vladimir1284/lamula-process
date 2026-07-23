unit CAPPI;

interface

uses
  HorzProduct, DataSource,
  EditForm;

type
  TCAPPI = class;

  TCAPPI = class(THorzProduct)
  public
    class function  Name                     : string;   override;
    class function  Description              : string;   override;
    class function  ImageIndex               : integer;  override;
    class function  EditForm                 : TFEdit;   override;
  protected
    function GetLabel : string;  override;
    function GetBrief : string;  override;
  public
    procedure Render; override;
  end;

implementation

uses
  Forms, SysUtils,
  Settings,
  Notify, Observation, ScanGrid, Measure, Plane,
  CAPPIScan,
  CAPPIEdit,
  SupressStatus; ///mio

// TCAPPI methods

class function TCAPPI.Name : string;
begin
  Result := 'CAPPI';
end;

class function TCAPPI.Description : string;
begin
  Result := 'CAPPI entre dos niveles';
end;

class function TCAPPI.ImageIndex : integer;
begin
  Result := 14;
end;

class function TCAPPI.EditForm : TFEdit;
begin
  if FCAPPIEdit = nil
    then Application.CreateForm( TFCAPPIEdit, FCAPPIEdit );
  Result := FCAPPIEdit;
end;

function TCAPPI.GetLabel : string;
begin
  Result := Format('CAPPI, %s %dm - %dm', [MeasureVar(Measure), Bottom, Top]);
end;

function TCAPPI.GetBrief : string;
begin
  Result := Format('%s, %s desde %dm hasta %dm',
                   [Name, MeasureVar(Measure), Bottom, Top]);
end;

procedure TCAPPI.Render;
var
  GridScan : TCAPPIScan;
begin
  Notify.Declare([0, 90, 100]);
  with Observation.Channel[Channel] do
    GridScan := TCAPPIScan.Initialize(PlanePoint(MaxCells, Sectors), Measure,
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
