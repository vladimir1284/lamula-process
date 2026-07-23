unit HorzProduct;

interface

uses
  Classes,
  GridProduct, Product, Measure, Plane, DataSource,
  EditForm;

type
  THorzProduct = class;
  CHorzProduct = class of THorzProduct;
  THorzPrdAuto = class;

  THorzProduct = class(TGridProduct)
  public
    class function  Accept( D : CDataSource ) : boolean;  override;
    class function  Setup ( D : TDataSource ) : boolean;  override;
    class procedure SetDefault;                           override;
    class procedure SetRemember;                          override;
    class function  AutoClass : CProductAuto;             override;
  private
    fTop    : integer;
    fBottom : integer;
  published
    property Top    : integer read fTop    write fTop    stored true;
    property Bottom : integer read fBottom write fBottom stored true;
  public
    procedure Render;  override;
  protected
    function  GetBrief : string;  override;
    procedure GetEditData;        override;
    procedure SetEditData;        override;
  protected
    procedure RenderEnsemble;
  end;

  THorzPrdAuto = class(TGridPrdAuto)
  automated
    function  GetTop    : integer;
    function  GetBottom : integer;
    procedure SetTop   ( V : integer );
    procedure SetBottom( V : integer );
  automated
    property Top    : integer read GetTop    write SetTop;
    property Bottom : integer read GetBottom write SetBottom;
  end;

implementation

uses
  SysUtils,
  Settings,
  Ensemble,
  HorzEdit,
  SupressStatus; ///mio********;

// THorzProduct methods

class function THorzProduct.Accept( D : CDataSource ) : boolean;
begin
  Result := inherited Accept(D) or D.InheritsFrom(TEnsemble);
end;

class function THorzProduct.Setup( D : TDataSource ) : boolean;
var
  b: boolean;
begin
  Result := inherited Setup(D);
  if Result
    then
      with EditForm as TFHorzEdit, TheSettings do
        begin
          Bottom := DefaultHorzBot;
          Top    := DefaultHorzTop;
          Supressing := DefaultC_SStatusHorzProduct;///mio
          b := Supressing;//mio
        end;
  theSupressStatus := b;  /////mio
end;

class procedure THorzProduct.SetDefault;
begin
  inherited;
  with EditForm as TFHorzEdit, TheSettings do
    begin
      DefaultHorzBot := Bottom;
      DefaultHorzTop := Top;
      DefaultC_SStatusHorzProduct := Supressing; //mio
    end;
end;

class procedure THorzProduct.SetRemember;
begin
  inherited;
  with (EditForm as TFHorzEdit), theSettings do
    DefaultCellH := CellH;
end;

class function THorzProduct.AutoClass : CProductAuto;
begin
  Result := THorzPrdAuto;
end;

procedure THorzProduct.Render;
begin
  if DataSource is TEnsemble
    then RenderEnsemble;
  inherited;
end;

function THorzProduct.GetBrief : string;
begin
  Result := inherited GetBrief +
            Format(' desde %dm hasta %dm', [Bottom, Top]);
end;

procedure THorzProduct.GetEditData;
begin
  inherited;
  with EditForm as TFHorzEdit do
    begin
      fBottom := Bottom;
      fTop    := Top;
    end;
end;

procedure THorzProduct.SetEditData;
begin
  inherited;
  with EditForm as TFHorzEdit do
    begin
      Bottom := fBottom;
      Top    := fTop;
    end;
end;

procedure THorzProduct.RenderEnsemble;
begin
//...
end;

// THorzPrdAuto methods

function THorzPrdAuto.GetTop : integer;
begin
  Result := (Product as THorzProduct).Top;
end;

function THorzPrdAuto.GetBottom : integer;
begin
  Result := (Product as THorzProduct).Bottom;
end;

procedure THorzPrdAuto.SetTop( V : integer );
begin
  (Product as THorzProduct).Top := V;
end;

procedure THorzPrdAuto.SetBottom( V : integer );
begin
  (Product as THorzProduct).Bottom := V;
end;

end.
