unit VertEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  HorzEdit, Area, StdCtrls, Spin, Grids, ComCtrls;

type
  TFVertEdit = class(TFHorzEdit)
    Label16: TLabel;
    Edit7: TEdit;
    UpDown2: TUpDown;
  private
    function  GetCellV: integer;
    procedure SetCellV(V: integer);
  public
    property CellV: integer read GetCellV write SetCellV;
  end;

var
  FVertEdit: TFVertEdit;

implementation

{$R *.DFM}

function TFVertEdit.GetCellV: integer;
begin
  Result := UpDown2.Position;
end;

procedure TFVertEdit.SetCellV(V: integer);
begin
  UpDown2.Position := V;
end;

end.
