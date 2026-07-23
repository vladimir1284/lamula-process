unit GridProduct;

interface

uses
  Windows,
  Variants,
  Product, Grid, Plane, Measure, DataSource,
  Classes, Forms,
  EditForm, GridForm,
  SupressStatus;

type
  TGridProduct = class(TProduct)
  public
    class function  Setup( D  : TDataSource ) : boolean;  override;
    class procedure SetDefault;                           override;
    class function  EditForm  : TFEdit;                   override;
    class function  AutoClass : CProductAuto;             override;
    class procedure SetRemember;                          override;
  protected
    procedure SetDataSource( D : TDataSource );  override;
    function  GetBrief : string;                 override;
  protected
    function  CreateViewForm : TFGrid;                                       virtual;
    procedure ViewFormClose( Sender : TObject; var Action : TCloseAction );  virtual;
  protected
    fGrid : TGrid;
    procedure SetGrid( aGrid : TGrid );  virtual;
  private
    fChannel  : integer;
    fMeasure  : TMeasure;
    fLength   : integer;
    fArea     : TPlaneArea;
    fMaxCells : integer;
    fViewForm : TFGrid;
    procedure ReadArea   ( Reader : TReader );
    procedure WriteArea  ( Writer : TWriter );
    procedure ReadGrid   ( Reader : TReader );
    procedure WriteGrid  ( Writer : TWriter );
    function  GetViewForm : TFGrid;
    procedure SetViewForm( aViewForm : TFGrid );
  private
    procedure SetChannel( aChannel : integer );
  {
    procedure SetMeasure( aMeasure : TMeasure );
    procedure SetLength ( aLength  : integer );
  }
  published
    property Channel  : integer  read fChannel    write SetChannel;
    property Measure  : TMeasure read fMeasure    write fMeasure;
    property Length   : integer  read fLength     write fLength;
    property ViewForm : TFGrid   read GetViewForm write SetViewForm stored false;
    property MaxCells : integer  read fMaxCells   write fMaxCells   stored false;
  public  // these properties may not be published
    property Area     : TPlaneArea  read fArea   write fArea;
    property Grid     : TGrid       read fGrid   write SetGrid;
  protected
    function  GetPosition : TPoint;                override;
    procedure DefineProperties( Filer : TFiler );  override;
  public
    procedure Update;  override;
    procedure Show;    override;
  protected
    procedure GetEditData;  override;
    procedure SetEditData;  override;
  end;

type
  TGridPrdAuto = class(TProductAuto)
  automated
    function  GetView : variant;
    function  Animate : variant;
  automated
    procedure Save( const FileName : string );  override;
  automated
    function  GetChannel  : integer;
    function  GetMeasure  : integer;
    function  GetCellH    : integer;
    function  GetEast     : integer;       virtual;
    function  GetWest     : integer;       virtual;
    function  GetNorth    : integer;       virtual;
    function  GetSouth    : integer;       virtual;
    function  GetMaxRange : integer;       virtual;
    function  GetCells    : variant;       virtual;
    procedure SetChannel ( V : integer );
    procedure SetMeasure ( V : integer );
    procedure SetCellH   ( V : integer );
    procedure SetEast    ( V : integer );  virtual;
    procedure SetWest    ( V : integer );  virtual;
    procedure SetNorth   ( V : integer );  virtual;
    procedure SetSouth   ( V : integer );  virtual;
    procedure SetMaxRange( V : integer );  virtual;
  automated
    property View     : variant read GetView;
    property Channel  : integer read GetChannel  write SetChannel;
    property Measure  : integer read GetMeasure  write SetMeasure;
    property CellH    : integer read GetCellH    write SetCellH;
    property East     : integer read GetEast     write SetEast;
    property West     : integer read GetWest     write SetWest;
    property North    : integer read GetNorth    write SetNorth;
    property South    : integer read GetSouth    write SetSouth;
    property MaxRange : integer read GetMaxRange write SetMaxRange;
    property Cells    : variant read GetCells;
  private
    procedure AnimateTimeSpan;
    procedure AnimateEnsemble;
  end;

implementation

uses
  SysUtils,
  Settings,
  RadarData,
  TimeSpanForm,
  EnsembleForm,
  AnimationAuto;

// TGridProduct methods

class function TGridProduct.Setup( D : TDataSource ) : boolean;
begin
  Result := inherited Setup(D);
  if Result
    then
      with EditForm as TFEdit, TheSettings do
        begin
          Measure := TMeasure(DefaultMeasure);
          Channel := DefaultChannel;
          CellH   := DefaultCellH;
        end;
end;

class procedure TGridProduct.SetDefault;
begin
  inherited;
  with EditForm as TFEdit, TheSettings do
    begin
      DefaultMeasure := ord(Measure);
      DefaultChannel := Channel;
    end;
end;

class function TGridProduct.EditForm : TFEdit;
begin
  if FEdit = nil
    then FEdit := TFEdit.Create(Application.MainForm);
  Result := FEdit;
end;

class function TGridProduct.AutoClass : CProductAuto;
begin
  Result := TGridPrdAuto;
end;

class procedure TGridProduct.SetRemember;
begin
  inherited;
  with (EditForm as TFEdit), theSettings do
    begin
      DefaultHorzEast  := Area1.East;
      DefaultHorzWest  := Area1.West;
      DefaultHorzNorth := Area1.North;
      DefaultHorzSouth := Area1.South;
      DefaultMaxRange := MaxRange;
    end;
end;

procedure TGridProduct.ViewFormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caNone;
  Self.Free;
end;

procedure TGridProduct.SetDataSource( D : TDataSource );
begin
  if assigned(fGrid)
    then FreeAndNil(fGrid);  //Grid := nil;  // ???
  inherited;
end;

function TGridProduct.GetBrief : string;
begin
  Result := Format('%s[%d], %s', [Name, Channel + 1, MeasureVar(Measure)]);
end;

procedure TGridProduct.SetChannel( aChannel : integer );
begin
  if aChannel <> fChannel
    then
      begin
        EditForm.Channel := aChannel;
        GetEditData;
      end;
end;

{
procedure TGridProduct.SetMeasure( aMeasure : TMeasure );
begin
  if aMeasure <> fMeasure
    then
      begin
        EditForm.Measure := aMeasure;
        GetEditData;
      end;
end;

procedure TGridProduct.SetLength( aLength  : integer );
begin
  fLength := aLength;
  SetEditData;
end;
}

function TGridProduct.CreateViewForm : TFGrid;
begin
  Result := TFGrid.Create(Self);
  Result.FormStyle := fsMDIChild;
  Result.Visible := true;
end;

procedure TGridProduct.SetGrid( aGrid : TGrid );
begin
  if aGrid <> fGrid
    then
      begin
        if assigned(fGrid)
          then FreeAndNil(fGrid);
        fGrid := aGrid;
      end;
  if assigned(fViewForm) and assigned(fGrid)
    then Update;
end;

function TGridProduct.GetViewForm : TFGrid;
begin
  if fViewForm = nil
    then
      begin
        fViewForm := CreateViewForm;
        fViewForm.Product := Self;
        fViewForm.OnClose := ViewFormClose;
      end;
  Result := fViewForm;
end;

procedure TGridProduct.SetViewForm( aViewForm : TFGrid );
begin
  if assigned(fViewForm)
    then fViewForm.Release;
  fViewForm := aViewForm;
  if assigned(aViewForm)
    then
      begin
        fViewForm.Product := Self;
        fViewForm.OnClose := ViewFormClose;
      end;
end;

function TGridProduct.GetPosition : TPoint;
begin
  with ViewForm do
    Result := Point(Left + Width, Top);
end;

procedure TGridProduct.ReadArea( Reader : TReader );
begin
  fArea := ReadPlaneArea(Reader);
end;

procedure TGridProduct.WriteArea( Writer : TWriter );
begin
  WritePlaneArea(Writer, fArea);
end;

procedure TGridProduct.ReadGrid( Reader : TReader );
begin
  Grid := ReadPlane(Reader, Grid) as TGrid;
end;

procedure TGridProduct.WriteGrid( Writer : TWriter );
begin
  WritePlane(Writer, Grid);
end;

procedure TGridProduct.DefineProperties( Filer : TFiler );
begin
  inherited;
  Filer.DefineProperty('Area', ReadArea, WriteArea, true);
  Filer.DefineProperty('Grid', ReadGrid, WriteGrid, assigned(fGrid));
end;

procedure TGridProduct.Update;
begin
  ViewForm.Grid := fGrid;
end;

procedure TGridProduct.Show;
begin
  Update;
  ViewForm.Show;
end;

procedure TGridProduct.GetEditData;
var
  CellsInFormat: integer;
begin
  inherited;
  with EditForm as TFEdit do
    begin
      fChannel  := Channel;
      fMeasure  := Measure;
      fLength   := CellH;
      fArea     := PlaneArea(Area1.West  * 1000 div fLength,
                             Area1.South * 1000 div fLength,
                             Area1.East  * 1000 div fLength,
                             Area1.North * 1000 div fLength);
      fMaxCells := round(MaxRange * 1000 / (DataSource as TRadarData).Channel[fChannel].Length);
      CellsInFormat := (DataSource as TRadarData).Channel[fChannel].Cells;
      if fMaxCells > CellsInFormat then
        fMaxCells := CellsInFormat;
      theSupressStatus := Supressing; ////mio*****
    end;
end;

procedure TGridProduct.SetEditData;
begin
  inherited;
  with EditForm as TFEdit do
    begin
      Channel := fChannel;
      Measure := fMeasure;
      CellH   := fLength;
      with Area1 do
        begin
          West  := fArea.A.X * fLength div 1000;
          South := fArea.A.Y * fLength div 1000;
          East  := fArea.B.X * fLength div 1000;
          North := fArea.B.Y * fLength div 1000;
        end;
      MaxRange := round(fMaxCells * (DataSource as TRadarData).Channel[fChannel].Length / 1000);
    end;
end;

// TGridPrdAuto methods

function TGridPrdAuto.GetView : variant;
begin
  Result := (Product as TGridProduct).ViewForm.OleObject;
end;

function TGridPrdAuto.Animate : variant;
var
  AnmAuto : TAnimationAuto;
begin
  if (Product is TGridProduct) and
     ((Product.Owner is TFTimeSpan) or (Product.Owner is TFEnsemble))
    then
      begin
        AnmAuto := TAnimationAuto.Create;
        AnmAuto.Form := (Product as TGridProduct).ViewForm;
        if Product.Owner is TFTimeSpan
          then AnimateTimeSpan
        else if Product.Owner is TFEnsemble
          then AnimateEnsemble;
        Result := AnmAuto.OleObject;
      end
    else Result := null;
end;

procedure TGridPrdAuto.Save( const FileName : string );
begin
  ((Product as TGridProduct).ViewForm as TFGrid).SaveData(FileName);
end;

function TGridPrdAuto.GetChannel : integer;
begin
  Result := (Product as TGridProduct).Channel;
end;

function TGridPrdAuto.GetMeasure : integer;
begin
  Result := ord((Product as TGridProduct).Measure);
end;

function TGridPrdAuto.GetCellH : integer;
begin
  Result := (Product as TGridProduct).Length;
end;

function TGridPrdAuto.GetEast : integer;
begin
  Result := (Product as TGridProduct).Area.Right;
end;

function TGridPrdAuto.GetWest : integer;
begin
  Result := (Product as TGridProduct).Area.Left;
end;

function TGridPrdAuto.GetNorth : integer;
begin
  Result := (Product as TGridProduct).Area.Top;
end;

function TGridPrdAuto.GetSouth : integer;
begin
  Result := (Product as TGridProduct).Area.Bottom;
end;

function TGridPrdAuto.GetMaxRange : integer;
begin
  with Product as TGridProduct do
    Result := MaxCells * Length div 1000;
end;

procedure TGridPrdAuto.SetChannel( V : integer );
begin
  (Product as TGridProduct).Channel := V;
end;

procedure TGridPrdAuto.SetMeasure( V : integer );
begin
  (Product as TGridProduct).Measure := TMeasure(V);
end;

procedure TGridPrdAuto.SetCellH( V : integer );
begin
  (Product as TGridProduct).Length := V;
end;

procedure TGridPrdAuto.SetEast( V : integer );
begin
  (Product as TGridProduct).Area := PlaneArea(GetWest, V, GetNorth, GetSouth);
end;

procedure TGridPrdAuto.SetWest( V : integer );
begin
  (Product as TGridProduct).Area := PlaneArea(V, GetEast, GetNorth, GetSouth);
end;

procedure TGridPrdAuto.SetNorth( V : integer );
begin
  (Product as TGridProduct).Area := PlaneArea(GetWest, GetEast, V, GetSouth);
end;

procedure TGridPrdAuto.SetSouth( V : integer );
begin
  (Product as TGridProduct).Area := PlaneArea(GetWest, GetEast, GetNorth, V);
end;

procedure TGridPrdAuto.SetMaxRange( V : integer );
begin
  with Product as TGridProduct do
    MaxCells := V * 1000 div Length;
end;

function TGridPrdAuto.GetCells : variant;
begin
  with (Product as TGridProduct).Grid do
    begin
      Result := VarArrayCreate([0, CellCount], varByte);
      Move(Cells^, VarArrayLock(Result)^, CellCount);
      VarArrayUnlock(Result);
    end;
end;

procedure TGridPrdAuto.AnimateTimeSpan;
begin
  (Product.Owner as TFTimeSpan).CreateAnimation(Product);
end;

procedure TGridPrdAuto.AnimateEnsemble;
begin
  (Product.Owner as TFEnsemble).CreateProduct(Product);
end;

end.
