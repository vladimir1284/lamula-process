unit Product;

interface

{$WARN UNIT_DEPRECATED OFF}

uses
  Windows,
  Classes, Forms, Controls, OleAuto,
  Variants,
  Result,
  EditForm,
  DataSource, Observation, TimeSpan, Ensemble, Measure;

const
  ProductExt    = '.prd';
  NetCDFExt     = '.nc';
  BinaryExt     = '.bin';
  BitmapExt     = '.bmp';
  GIFExt        = '.gif';
  JPGExt        = '.jpg';
  JPEGExt       = '.jpeg';
  ProductFilter = 'Producto|*' + ProductExt;
  NetCDFFilter  = 'NetCDF|*' + NetCDFExt;
  BinaryFilter  = 'Binario|*' + BinaryExt;
  BitmapFilter  = 'Bitmap|*' + BitmapExt;
  GIFFilter     = 'GIF|*' + GIFExt;
  JPegFilter    = 'JPeg|*' + JPGExt + ';*' + JPEGExt;
  ImagesFilter  = BitmapFilter + '|' + GIFFilter + '|' + JPegFilter;

type
  TFileFormat = (ffUnknown, ffProduct, ffNetCDF, ffBinary,
                 ffBmpImage, ffGIFImage, ffJPGImage,
                 ffCSVTable,
                 ffAnimation, ffGIFAnim);

type
  TProduct     = class;
  CProduct     = class of TProduct;
  TProductAuto = class;
  CProductAuto = class of TProductAuto;

  TProduct = class(TResult)
  public
    destructor Destroy;  override;
  public
    class function  Name        : string;                 virtual;  abstract;
    class function  Description : string;                 virtual;  abstract;
    class function  ImageIndex  : integer;                virtual;
    class function  Accept( D : CDataSource ) : boolean;  virtual;
    class function  Setup ( D : TDataSource ) : boolean;  virtual;
    class procedure SetDefault;                           virtual;
    class procedure SetRemember;                          virtual;
    class function  EditForm    : TFEdit;                 virtual;  abstract;
    class function  AutoClass   : CProductAuto;           virtual;  abstract;
    class function  CanAnimate  : boolean;                virtual;
  private
    fOnDestroy  : TNotifyEvent;
    fRendered   : boolean;
    fDataSource : TDataSource;
    fPrdAuto    : TProductAuto;
    function  GetPrdAuto     : TProductAuto;
    function  GetOleObject   : variant;
    function  GetObservation : TObservation;
    function  GetTimeSpan    : TTimeSpan;
    function  GetEnsemble    : TEnsemble;
  protected
    procedure SetDataSource( D : TDataSource );  virtual;
    function  GetLabel    : string;              virtual;  abstract;
    function  GetBrief    : string;              virtual;  abstract;
    function  GetPosition : TPoint;              virtual;  abstract;
  published
    property PrdLabel   : string       read GetLabel;
    property Brief      : string       read GetBrief;
    property Rendered   : boolean      read fRendered   write fRendered     stored false;
    property DataSource : TDataSource  read fDataSource write SetDataSource stored false;
    property OnDestroy  : TNotifyEvent read fOnDestroy  write fOnDestroy    stored false;
  public
    property Position    : TPoint       read GetPosition;
    property ProductAuto : TProductAuto read GetPrdAuto;
    property OleObject   : variant      read GetOleObject;
  protected
    property Observation : TObservation read GetObservation;
    property TimeSpan    : TTimeSpan    read GetTimeSpan;
    property Ensemble    : TEnsemble    read GetEnsemble;
  public
    function  Default   : boolean;  virtual;
    function  Customize : boolean;  virtual;
    procedure Render;               virtual;
    procedure Update;               virtual;  abstract;
    procedure Show;                 virtual;  abstract;
  protected
    procedure GetEditData;  virtual;
    procedure SetEditData;  virtual;
  end;

  TProductAuto = class(TAutoObject)
  automated
    procedure Load( const FileName : string );  virtual;
    procedure Save( const FileName : string );  virtual;
    procedure Close;
    function  Default   : wordbool;
    function  Customize : wordbool;
    procedure Render;
    procedure Update;
    procedure Show;
  automated
    function GetName        : string;
    function GetDescription : string;
    function GetBrief       : string;
    function GetRendered    : wordbool;
  automated
    property Name        : string   read GetName;
    property Description : string   read GetDescription;
    property Brief       : string   read GetBrief;
    property Rendered    : wordbool read GetRendered;
  private
    fProduct : TProduct;
    procedure RenderObservation;
    procedure RenderTimeSpan;
    procedure RenderEnsemble;
  public
    property Product : TProduct read fProduct;
  end;

type
  TContainer = class
  public
    constructor Create( ProductClass : CProduct );
  private
    fProduct    : CProduct;
    fDataSource : TDataSource;
    fOwner      : TComponent;
  public
    property Product    : CProduct    read fProduct;
    property DataSource : TDataSource read fDataSource write fDataSource;
    property Owner      : TComponent  read fOwner      write fOwner;
  public
    function Default : TProduct;
    function Custom  : TProduct;
  end;

implementation

uses
  SysUtils, ObservationForm, TimeSpanForm, EnsembleForm, Settings;

// TProduct methods

destructor TProduct.Destroy;
begin
  if assigned(fOnDestroy)
    then OnDestroy(Self);
  if assigned(fPrdAuto)
    then fPrdAuto.Release;
  SetDataSource(nil);
  inherited;
end;

class function TProduct.ImageIndex : integer;
begin
  Result := 0;
end;

class function TProduct.Accept( D : CDataSource ) : boolean;
begin
  Result := D.InheritsFrom(TObservation);
end;

class function TProduct.Setup( D : TDataSource ) : boolean;
begin
  theSettings.Folder := Name + '\'; 
  Result := EditForm <> nil;
  if Result
    then EditForm.DataSource := D;
end;

class procedure TProduct.SetDefault;
begin
end;

class procedure TProduct.SetRemember;
begin
end;

class function TProduct.CanAnimate : boolean;
begin
  Result := true;
end;

procedure TProduct.SetDataSource( D : TDataSource );
begin
  fRendered   := false;
  fDataSource := D;
end;

function TProduct.GetPrdAuto : TProductAuto;
begin
  if fPrdAuto = nil
    then
      begin
        fPrdAuto := AutoClass.Create;
        fPrdAuto.fProduct := Self;
      end;
  Result := fPrdAuto;
end;

function TProduct.GetOleObject : variant;
begin
  Result := ProductAuto.OleObject;
end;

function TProduct.GetObservation : TObservation;
begin
  Result := fDataSource as TObservation;
end;

function TProduct.GetTimeSpan : TTimeSpan;
begin
  Result := fDataSource as TTimeSpan;
end;

function TProduct.GetEnsemble : TEnsemble;
begin
  Result := fDataSource as TEnsemble;
end;

function TProduct.Default : boolean;
begin
  GetEditData;
  Result := true;
end;

function TProduct.Customize : boolean;
begin
  if EditForm <> nil
    then
      with EditForm do
        begin
          SetEditData;
          Result := (ShowModal = mrOk);
          if Result
            then GetEditData;
        end
    else Result := false;
end;

procedure TProduct.Render;
begin
  fRendered := true;
end;

procedure TProduct.GetEditData;
begin
  if EditForm.SetDefault
    then SetDefault;
  if EditForm.Remember
    then SetRemember;
end;

procedure TProduct.SetEditData;
begin
end;

// TProductAuto methods

procedure TProductAuto.Load( const FileName : string );
begin
  with TFileStream.Create(FileName, fmShareDenyWrite or fmOpenRead) do
    try
      fProduct := ReadComponent(Product) as TProduct;
    finally
      Free;
    end;
end;

procedure TProductAuto.Save( const FileName : string );
begin
  with TFileStream.Create(FileName, fmCreate) do
    try
      WriteComponent(Product);
    finally
      Free;
    end;
end;

procedure TProductAuto.Close;
begin
  FreeAndNil(fProduct);
end;

function TProductAuto.Default : wordbool;
begin
  Result := Product.Default;
end;

function TProductAuto.Customize : wordbool;
begin
  Result := Product.Customize;
end;

procedure TProductAuto.Render;
begin
  if Product.Owner is TFObservation
    then RenderObservation
  else if Product.Owner is TFTimeSpan
    then RenderTimeSpan
  else if Product.Owner is TFEnsemble
    then RenderEnsemble;
end;

procedure TProductAuto.Update;
begin
  Product.Update;
end;

procedure TProductAuto.Show;
begin
  Product.Show;
end;

function TProductAuto.GetName : string;
begin
  Result := Product.Name;
end;

function TProductAuto.GetDescription : string;
begin
  Result := Product.Description;
end;

function TProductAuto.GetBrief : string;
begin
  Result := Product.Brief;
end;

function TProductAuto.GetRendered : wordbool;
begin
  Result := Product.Rendered;
end;

procedure TProductAuto.RenderObservation;
begin
  (Product.Owner as TFObservation).CreateProduct(Product);
end;

procedure TProductAuto.RenderTimeSpan;
begin
  (Product.Owner as TFTimeSpan).CreateProduct(Product);
end;

procedure TProductAuto.RenderEnsemble;
begin
  (Product.Owner as TFEnsemble).CreateProduct(Product);
end;

// TContainer methods

constructor TContainer.Create( ProductClass : CProduct );
begin
  inherited Create;
  fProduct := ProductClass;
end;

function TContainer.Default : TProduct;
begin
  Product.Setup(DataSource);
  Result := Product.Create(Owner);
  if not (Result.Default or Result.Customize)
    then FreeAndNil(Result);
end;

function TContainer.Custom : TProduct;
begin
  if Product.Setup(DataSource)
    then
      begin
        Result := Product.Create(Owner);
        Result.Default;
        if not Result.Customize
          then FreeAndNil(Result);
      end
    else Result := nil;
end;

end.

