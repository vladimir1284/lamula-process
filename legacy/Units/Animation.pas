unit Animation;

interface

uses
  Classes,
  Result, Product;

const
  AnimationExt    = '.anm';
  AnimationFilter = 'Animacion|*' + AnimationExt;
  GIFAnimFilter   = 'GIF Animado|*' + GIFExt;

const
  AnimationPrefix = 'Ani';

type
  TIntArray = array of integer;

type
  TAnimation = class(TResult)
  public
    destructor  Destroy;  override;
    constructor Load( aFileName : string );
    procedure   Save( aFileName : string );
  private
    fFileName     : string;
    fFrames       : integer;
    fPosition     : integer;
    fProductClass : CProduct;
    fProduct      : TProduct;
    fOnDestroy    : TNotifyEvent;
    procedure SetFileName( const aFileName : string );
    procedure SetFrames  ( aCount    : integer  );
    procedure SetPosition( aPosition : integer  );
    function  GetFrame   ( I : integer ) : TProduct;
    procedure SetFrame   ( I : integer; aProduct : TProduct );
    function  GetProduct : TProduct;
    procedure SetProduct ( P : TProduct );
  public
    property FileName     : string       read fFileName     write SetFileName;
    property Frames       : integer      read fFrames       write SetFrames;
    property Position     : integer      read fPosition     write SetPosition;
    property ProductClass : CProduct     read fProductClass;
    property Product      : TProduct     read GetProduct    write SetProduct;
    property OnDestroy    : TNotifyEvent read fOnDestroy    write fOnDestroy;
  public
    property Frame[I : integer] : TProduct read GetFrame write SetFrame;
  private
    fStream     : TStream;
    fFrameIndex : TIntArray;
    procedure ReadHeader;
    procedure WriteHeader;
    procedure ProductDestroy( Sender : TObject );
    procedure OpenAnimationFile;
    procedure CreateAnimationFile;
  end;

implementation

uses
  Windows,
  SysUtils,
  GridProduct;

// TAnimation methods

destructor TAnimation.Destroy;
begin
  if assigned(fOnDestroy)
    then fOnDestroy(Self);
  if assigned(fProduct)
    then
      begin
        fProduct.OnDestroy := nil;
        FreeAndNil(fProduct);
      end;
  FreeAndNil(fStream);
  if copy(ExtractFileName(fFileName), 1, length(AnimationPrefix)) = AnimationPrefix
    then DeleteFile(fFileName);
  inherited;
end;

constructor TAnimation.Load( aFileName : string );
begin
  inherited Create(nil);
  SetFileName(aFileName);
end;

procedure TAnimation.Save( aFileName : string );
begin
  if assigned(fStream)
    then SetFileName(aFileName);
end;

procedure TAnimation.SetFileName( const aFileName : string );
begin
  if assigned(fStream)
    then
      begin
        FreeAndNil(fStream);
        if FileExists(aFileName)
          then DeleteFile(aFileName);
        if UpperCase(ExtractFileExt(fFileName)) = '.TMP'
          then RenameFile(fFileName, aFileName)
          else CopyFile(pchar(fFileName), pchar(aFileName), false);
      end;
  fFileName := aFileName;
  OpenAnimationFile;
end;

procedure TAnimation.SetFrames( aCount : integer  );
begin
  if Frames <> aCount
    then
      begin
        SetLength(fFrameIndex, aCount);
        if aCount > Frames
          then FillChar(fFrameIndex[Frames], (aCount - Frames) * sizeof(integer), 0);
        fFrames := aCount;
      end;
end;

procedure TAnimation.SetPosition( aPosition : integer );
begin
  fPosition := aPosition;
  fStream.Seek(fFrameIndex[fPosition], soFromBeginning);
  if fProductClass <> nil
    then
      begin
        with (Product as TGridProduct).ViewForm do
          if Animation = nil
            then Animation := pointer(Self);
        fStream.ReadComponent(fProduct);
      end;
end;

function TAnimation.GetFrame( I : integer ) : TProduct;
begin
  fStream.Seek(fFrameIndex[I], soFromBeginning);
  Result := fStream.ReadComponent(nil) as ProductClass;
end;

procedure TAnimation.SetFrame( I : integer; aProduct : TProduct );
begin
  if ProductClass = nil
    then
      begin
        fProductClass := CProduct(aProduct.ClassType);
        CreateAnimationFile;
      end;
  if aProduct is ProductClass
    then
      begin
        fFrameIndex[I] := fStream.Seek(0, soFromEnd);
        fStream.WriteComponent(aProduct);
        WriteHeader;
      end
    else raise Exception.CreateFmt('No se puede incorporar %s a una animacion de %s',
                                   [aProduct.Name, ProductClass.Name]);
end;

function TAnimation.GetProduct : TProduct;
begin
  if (fProduct = nil) and assigned(fProductClass)
    then
      begin
        fProduct := fProductClass.Create(nil);
        fProduct.OnDestroy := ProductDestroy;
      end;
  Result := fProduct;
end;

procedure TAnimation.SetProduct( P : TProduct );
begin
  if assigned(fProduct)
    then FreeAndNil(fProduct);
  fProduct := P;
  fProduct.OnDestroy := ProductDestroy;
end;

procedure TAnimation.ReadHeader;
begin
  fStream.Seek(0, soFromBeginning);
  with TReader.Create(fStream, 1024) do
    try
      ReadSignature;
      fProductClass := CProduct(Classes.FindClass(ReadString));
      Frames        := ReadInteger;
      ReadListBegin;
      Read(fFrameIndex[0], Frames * sizeof(integer));
      ReadListEnd;
    finally
      Free;
    end;
end;

procedure TAnimation.WriteHeader;
begin
  fStream.Seek(0, soFromBeginning);
  if assigned(fProductClass)
    then
      with TWriter.Create(fStream, 1024) do
        try
          WriteSignature;
          WriteString(fProductClass.ClassName);
          WriteInteger(Frames);
          WriteListBegin;
          Write(fFrameIndex[0], Frames * sizeof(integer));
          WriteListEnd;
        finally
          Free;
        end;
end;

procedure TAnimation.ProductDestroy( Sender : TObject );
begin
  fProduct      := nil;
  fProductClass := nil;
  Free;
end;

procedure TAnimation.OpenAnimationFile;
begin
  fStream := TFileStream.Create(fFileName, fmShareDenyWrite or fmOpenRead);
  ReadHeader;
end;

procedure TAnimation.CreateAnimationFile;
begin
  if fFileName = ''
    then
      begin
        SetLength(fFileName, MAX_PATH);
        GetTempPath(MAX_PATH, pchar(fFileName));
        GetTempFileName(pchar(fFileName), AnimationPrefix, 0, pchar(fFileName));
        SetLength(fFileName, StrLen(pchar(fFileName)));
      end;
  fStream := TFileStream.Create(fFileName, fmShareDenyWrite or fmCreate);
//  fStream := TMemoryStream.Create;
  WriteHeader;
end;

end.
