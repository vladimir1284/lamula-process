unit GridAuto;

interface

uses
  Forms,
  FormAuto;

type
  TGridAuto = class(TFormAuto)
  protected
    class function FormClass : TFormClass;  override;
  automated
    function  GetZoom    : integer;
    function  GetWidth   : integer;
    function  GetHeight  : integer;
    function  GetScrollX : integer;
    function  GetScrollY : integer;
    procedure SetZoom   ( Z : integer );
    procedure SetWidth  ( W : integer );
    procedure SetHeight ( H : integer );
    procedure SetScrollX( X : integer );
    procedure SetScrollY( Y : integer );
    function  GetProduct   : variant;
  automated
    property Zoom    : integer read GetZoom    write SetZoom;
    property Width   : integer read GetWidth   write SetWidth;
    property Height  : integer read GetHeight  write SetHeight;
    property ScrollX : integer read GetScrollX write SetScrollX;
    property ScrollY : integer read GetScrollY write SetScrollY;
  automated
    property Product   : variant read GetProduct;
  end;

implementation

uses
  GridForm, Grid;

  class function TGridAuto.FormClass : TFormClass;
  begin
    Result := TFGrid;
  end;

  function TGridAuto.GetZoom : integer;
  begin
    Result := (Form as TFGrid).Zoom;
  end;

  function TGridAuto.GetWidth : integer;
  begin
    Result := (Form as TFGrid).Width;
  end;

  function TGridAuto.GetHeight : integer;
  begin
    Result := (Form as TFGrid).Height;
  end;

  function TGridAuto.GetScrollX : integer;
  begin
    Result := (Form as TFGrid).ScrollBar1.Position;
  end;

  function TGridAuto.GetScrollY : integer;
  begin
    Result := (Form as TFGrid).ScrollBar2.Position;
  end;

  procedure TGridAuto.SetZoom( Z : integer );
  begin
    (Form as TFGrid).Zoom := Z;
  end;

  procedure TGridAuto.SetWidth( W : integer );
  begin
    (Form as TFGrid).Width := W;
  end;

  procedure TGridAuto.SetHeight( H : integer );
  begin
    (Form as TFGrid).Height := H;
  end;

  procedure TGridAuto.SetScrollX( X : integer );
  begin
    (Form as TFGrid).ScrollBar1.Position := X;
  end;

  procedure TGridAuto.SetScrollY( Y : integer );
  begin
    (Form as TFGrid).ScrollBar2.Position := Y;
  end;

function TGridAuto.GetProduct : variant;
begin
  with (Form as TFGrid) do
    if assigned(Product)
      then Result := Product.OleObject;
end;

end.

