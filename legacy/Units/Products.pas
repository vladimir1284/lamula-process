unit Products;

interface

uses
  Controls, Graphics,
  Product, RadarData;

type
  TProductProc = procedure ( Container : TContainer; Index : integer ) of object;

procedure RegisterProduct( Product : CProduct );

procedure EnumProducts( RD : CRadarData; Anim : boolean; Proc : TProductProc );

function GetProductByName ( Name  : string )  : CProduct;
function GetProductByIndex( Index : integer ) : CProduct;

procedure GetProductLargeIcon( Product : TProduct; Icon : TIcon );
procedure GetProductSmallIcon( Product : TProduct; Icon : TIcon );

implementation

uses
  Classes, SysUtils,
  Shell_Process,
  PPI, RHI, CAPPI, Tops, Maxs, VIL,
  TopDown, NthSth, EstWst, Cut, Contribution,
  Volume,
  Accumulate,
  SpatialAnimation;

var
  ProductClasses : TList = nil;

// Public procedures & functions

procedure RegisterProduct( Product : CProduct );
begin
  ProductClasses.Add(Product);
  Classes.RegisterClass(Product);
end;

procedure EnumProducts( RD : CRadarData; Anim : boolean; Proc : TProductProc );
var
  I : integer;
begin
  for I := 0 to ProductClasses.Count - 1 do
    with CProduct(ProductClasses[I]) do
      if Accept(RD) and (not Anim or CanAnimate)
        then Proc(TContainer.Create(CProduct(ProductClasses[I])), I);
end;

function GetProductByName( Name : string ) : CProduct;
var
  I : integer;
begin
  for I := 0 to ProductClasses.Count - 1 do
    begin
      Result := ProductClasses[I];
      if Result.Name = Name
        then exit;
    end;
  Result := nil;
end;

function GetProductByIndex( Index : integer ) : CProduct;
begin
  Result := ProductClasses[Index];
end;

procedure GetProductLargeIcon( Product : TProduct; Icon : TIcon );
begin
  if assigned(Icon)
    then FShell.LargeImages.GetIcon(Product.ImageIndex, Icon);
end;

procedure GetProductSmallIcon( Product : TProduct; Icon : TIcon );
begin
  if assigned(Icon)
    then FShell.SmallImages.GetIcon(Product.ImageIndex, Icon);
end;

// Init/Final procedures & functions

procedure RegisterProducts;
begin
  RegisterProduct(TPPI);
  RegisterProduct(TRHI);
  RegisterProduct(TCAPPI);
  RegisterProduct(TTops);
  RegisterProduct(TMaxs);
  RegisterProduct(TVIL);
  RegisterProduct(TTopDown);
  RegisterProduct(TNthSth);
  RegisterProduct(TEstWst);
  RegisterProduct(TCut);
  RegisterProduct(TContribution);
  RegisterProduct(TVolume);
  RegisterProduct(TAccumulate);
  RegisterProduct(TSpatialAnimation);
//  RegisterProduct(TWind);
end;

initialization
  ProductClasses := TList.Create;
  RegisterProducts;
finalization
  ProductClasses.Free;
end.

