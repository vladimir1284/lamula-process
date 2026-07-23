unit VertProduct;

interface

uses
  Classes,
  GridProduct, Product, Measure, Plane, DataSource,
  EditForm;

type
  TVertProduct = class;
  TVertPrdAuto = class;

  TVertProduct = class(TGridProduct)
  public
    class function  Setup( D : TDataSource ) : boolean;  override;
    class procedure SetDefault;                          override;
    class procedure SetRemember;                         override;
    class function  AutoClass : CProductAuto;            override;
  private
    fTop    : integer;
    fBottom : integer;
    fHeight : integer;
  published
    property Top        : integer read fTop    write fTop;
    property Bottom     : integer read fBottom write fBottom;
    property CellHeight : integer read fHeight write fHeight;
  protected
    procedure GetEditData;  override;
    procedure SetEditData;  override;
  end;

  TVertPrdAuto = class(TGridPrdAuto)
  automated
    function  GetTop    : integer;
    function  GetBottom : integer;
    function  GetCellH  : integer;
    procedure SetTop   ( T  : integer );
    procedure SetBottom( B  : integer );
    procedure SetCellH ( CH : integer );
  automated
    property Top    : integer read GetTop    write SetTop;
    property Bottom : integer read GetBottom write SetBottom;
    property CellH  : integer read GetCellH  write SetCellH;
  end;

implementation

uses
  Settings,
  VertEdit,
  SupressStatus; ///mio********

// TVertProduct methods

class function TVertProduct.Setup( D : TDataSource ) : boolean;
var
  b: boolean;
begin
  Result := inherited Setup( D );
  if Result
    then
      with EditForm as TFVertEdit do
        begin
          Bottom := theSettings.DefaultVertBot;
          Top    := theSettings.DefaultVertTop;
          CellV  := theSettings.DefaultCellV;
          Supressing := theSettings.DefaultC_SStatusVertProduct; ///mio
          b := Supressing;//mio
        end;
      theSupressStatus := b;  /////mio
end;

class procedure TVertProduct.SetDefault;
begin
  inherited;
  with EditForm as TFVertEdit do
    begin
      theSettings.DefaultVertBot := Bottom;
      theSettings.DefaultVertTop := Top;
      theSettings.DefaultC_SStatusVertProduct := Supressing; //mio
    end;
end;

class procedure TVertProduct.SetRemember;
begin
  inherited;
  with EditForm as TFVertEdit do
    theSettings.DefaultCellV := CellV;
end;

class function TVertProduct.AutoClass : CProductAuto;
begin
  Result := TVertPrdAuto;
end;

procedure TVertProduct.GetEditData;
begin
  inherited;
  with EditForm as TFVertEdit do
    begin
      fBottom := Bottom;
      fTop    := Top;
      fHeight := CellV;
    end;
end;

procedure TVertProduct.SetEditData;
begin
  inherited;
  with EditForm as TFVertEdit do
    begin
      Bottom := fBottom;
      Top    := fTop;
      CellV  := fHeight;
    end;
end;

// TVertPrdAuto methods

function TVertPrdAuto.GetTop : integer;
begin
  Result := (Product as TVertProduct).Top;
end;

function TVertPrdAuto.GetBottom : integer;
begin
  Result := (Product as TVertProduct).Bottom;
end;

function TVertPrdAuto.GetCellH : integer;
begin
  Result := (Product as TVertProduct).CellHeight;
end;

procedure TVertPrdAuto.SetTop( T : integer );
begin
  (Product as TVertProduct).Top := T;
end;

procedure TVertPrdAuto.SetBottom( B : integer );
begin
  (Product as TVertProduct).Bottom := B;
end;

procedure TVertPrdAuto.SetCellH( CH : integer );
begin
  (Product as TVertProduct).CellHeight := CH;
end;

end.
