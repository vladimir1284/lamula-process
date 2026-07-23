unit Region;

interface

uses
  Windows,
  Classes,
  Plane, Description;

type
  TAreaPoints = array of TPlanePoint;

type
  TArea              = class;
    TRegionReference = class;
      TRegion        = class;

  TArea = class
  public
    constructor Create( R : TRegion; var F : TextFile );
    destructor  Destroy;  override;
  protected
    procedure LoadName  ( var F : TextFile );
    procedure LoadAreas ( var F : TextFile );
    procedure LoadPoints( var F : TextFile );
  private
    fName       : string;
    fRegion     : TRegion;
    fAreaCount  : integer;
    fPointCount : integer;
    fAreas      : TList;
    fPoints     : TAreaPoints;
    function GetPoint( I : integer ) : TPlanePoint;
    function GetArea ( I : integer ) : TArea;
  public
    property Name       : string      read fName;
    property Region     : TRegion     read fRegion;
    property AreaCount  : integer     read fAreaCount;
    property PointCount : integer     read fPointCount;
    property Areas      : TList       read fAreas;
    property Points     : TAreaPoints read fPoints;
    property Point[I : integer] : TPlanePoint read GetPoint;  default;
    property Area [I : integer] : TArea read GetArea;
  protected
    function Contains( P : TPlanePoint ) : integer;
    function Location( P : TPlanePoint ) : string;
  end;

  TRegionReference = class(TArea)
  public
    constructor Load( const aFileName : string );
  protected
    procedure ReadData( var F : TextFile );  virtual;
  private
    fCenter     : T2DLocation;
    fRange      : integer;
    fLength     : TPlanePoint;
    fDefault    : boolean;
    fReport     : boolean;
    fPriority   : integer;
    fStyle      : integer;
    fColor      : longint;
    fFileName   : string;
    fReferences : integer;
  public
    property Center     : T2DLocation read fCenter;
    property Range      : integer     read fRange;
    property Length     : TPlanePoint read fLength;
    property Default    : boolean     read fDefault;
    property Report     : boolean     read fReport;
    property Priority   : integer     read fPriority;
    property Style      : integer     read fStyle;
    property Color      : longint     read fColor      write fColor;
    property FileName   : string      read fFileName;
    property References : integer     read fReferences write fReferences;
  end;

  TRegion = class(TRegionReference)
  protected
    procedure ReadData( var F : TextFile );  override;
  protected
    property References;
  private
    fCount : integer;
  public
    property Count : integer read fCount;
  public
    function Contains( P : TPoint ) : integer;
    function Location( P : TPoint ) : string;
  end;

implementation

uses
  SysUtils;

// Private procedures & functions

function LoadStr( var F : TextFile ) : string;
begin
  repeat
    readln(F, Result);
  until Result <> '';
  UniqueString(Result);
  OEMToChar(pchar(Result), pchar(Result));
end;

function LoadValue( var F : TextFile ) : integer;
begin
  try
    readln(F, Result);
  except
    on EInOutError do
      Result := 0;
  end;
end;

// TArea methods

constructor TArea.Create( R : TRegion; var F : TextFile );
begin
  try
    fRegion := R;
    LoadName(F);
    LoadAreas(F);
    LoadPoints(F);
  except
    on E : Exception do
      begin
        E.Message := 'Area ' + fName + ': ' + E.Message;
        raise;
      end;
  end;
end;

destructor TArea.Destroy;
var
  I : integer;
begin
  if assigned(fAreas)
    then
      begin
        for I := 0 to fAreaCount - 1 do
          TArea(fAreas[I]).Free;
        FreeAndNil(fAreas);
      end;
  inherited;
end;

procedure TArea.LoadName( var F : TextFile );
begin
  fName := LoadStr(F);
end;

procedure TArea.LoadAreas( var F : TextFile );
var
  I : integer;
begin
  fAreaCount := LoadValue(F);
  if fAreaCount > 0
    then
      begin
        fAreas := TList.Create;
        for I := 0 to fAreaCount - 1 do
          fAreas.Add(TArea.Create(Region, F));
      end;
end;

procedure TArea.LoadPoints( var F : TextFile );
var
  I : integer;
begin
  fPointCount := LoadValue(F);
  if fPointCount > 0
    then
      begin
        SetLength(fPoints, fPointCount);
        for I := 0 to fPointCount - 1 do
          readln(F, fPoints[I].X, fPoints[I].Y);
      end;
end;

function TArea.GetPoint( I : integer ) : TPlanePoint;
begin
  Result := fPoints[I];
end;

function TArea.GetArea( I : integer ) : TArea;
begin
  if I < fAreaCount
    then Result := fAreas[I]
    else Result := Self;
end;

function TArea.Contains( P : TPlanePoint ) : integer;
var
  I : integer;
begin
  I := 0;
  while (I < fAreaCount) and (TArea(fAreas[I]).Contains(P) = -1) do
    inc(I);
  if I < fAreaCount
    then Result := I
    else
      begin
        I := 0;
        while (I < fPointCount) and (longint(P) <> longint(fPoints[I])) do
          inc(I);
        if I < fPointCount
          then Result := fAreaCount
          else Result := -1;
      end;
end;

function TArea.Location( P : TPlanePoint ) : string;
var
  I : integer;
begin
  I := Contains(P);
  if I >= 0
    then
      begin
        Result := Name;
        if I < fAreaCount
          then Result := Result + ', ' + TArea(fAreas[I]).Location(P);
        for I := succ(I) to fAreaCount - 1 do
          if Area[I].Contains(P) >= 0
            then Result := Result + '; ' + TArea(fAreas[I]).Location(P);
      end
    else Result := '';
end;

// TRegionReference methods

constructor TRegionReference.Load( const aFileName : string );
var
  F : TextFile;
begin
  try
    fFileName := aFileName;
    AssignFile(F, aFileName);
    Reset(F);
    try
      ReadData(F);
    finally
      Close(F);
    end;
  except
    on E : Exception do
      begin
        E.Message := 'Area ' + fName + ': ' + E.Message;
        raise;
      end;
  end;
end;

procedure TRegionReference.ReadData( var F : TextFile );
var
  R, G, B : byte;
begin
  readln(F, fCenter.Longitude, fCenter.Latitude);
  readln(F, byte(fDefault), byte(fReport));
  readln(F, fPriority);
  with fLength do
    readln(F, X, Y);
  readln(F, fRange);
  readln(F, fStyle);
  readln(F, R, G, B);
  fColor := RGB(R, G, B);
  LoadName(F);
end;

// TRegion methods

procedure TRegion.ReadData( var F : TextFile );
begin
  inherited ReadData(F);
  fRegion := Self;
  LoadAreas(F);
  LoadPoints(F);
end;

function TRegion.Contains( P : TPoint ) : integer;
var
  PP : TPlanePoint;
begin
  PP.X := round(P.X / Length.X);
  PP.Y := round(P.Y / Length.Y);
  Result := inherited Contains(PP);
end;

function TRegion.Location( P : TPoint ) : string;
var
  PP : TPlanePoint;
begin
  if Contains(P) >= 0
    then
      begin
        PP.X := round(P.X / Length.X);
        PP.Y := round(P.Y / Length.Y);
        Result := inherited Location(PP)
      end
    else Result := '';
end;

end.

