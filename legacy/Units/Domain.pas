unit Domain;

interface

  uses
    Windows,
    Classes,
    Plane, Description;

  type
    TRegionArea        = class;
      TRegionReference = class;
        TRegion        = class;

    PAreaPoints = ^TAreaPoints;
    TAreaPoints = array[0..maxint div sizeof(TPlanePoint) - 1] of TPlanePoint;

    TRegionArea = class
    public
      constructor Load( var F : TextFile );
      destructor  Destroy;  override;
    private
      fName       : string;
      fAreaCount  : integer;
      fPointCount : integer;
      fPoints     : PAreaPoints;
      fAreas      : TList;
      function GetPoint( I : integer ) : TPlanePoint;
      function GetArea ( I : integer ) : TRegionArea;
    public
      property Name       : string      read fName;
      property PointCount : integer     read fPointCount;
      property AreaCount  : integer     read fAreaCount;
      property Points     : PAreaPoints read fPoints;
      property Point[I : integer] : TPlanePoint read GetPoint;  default;
      property Area [I : integer] : TRegionArea read GetArea;
    public
      function Contains( P : TPlanePoint ) : integer;
    end;

    TRegionReference = class(TRegionArea)
    public
      constructor Load( const aFileName : string );  virtual;
    private
      fRadar      : TRadar;
      fRange      : integer;
      fLength     : TPlanePoint;
      fDefault    : boolean;
      fPriority   : integer;
      fStyle      : integer;
      fName       : string;
      fFileName   : string;
      fReferences : integer;
    public
      property Radar      : TRadar      read fRadar;
      property Range      : integer     read fRange;
      property Length     : TPlanePoint read fLength;
      property Default    : boolean     read fDefault;
      property Priority   : integer     read fPriority;
      property Style      : integer     read fStyle;
      property Name       : string      read fName;
      property FileName   : string      read fFileName;
      property References : integer     read fReferences write fReferences;
    end;

    TRegion = class(TRegionReference)
    public
      constructor Load( const aFileName : string );  override;
    protected
      property References;
    private
      fColor : longint;
    public
      property Color : longint read fColor write fColor;
    end;


implementation

  uses
    SysUtils;


// TRegionArea methods

  constructor TRegionArea.Load( var F : TextFile );
  var
    I : integer;
  begin
    inherited Create;
    try
      readln( F, fName );
      readln( F, fAreaCount );
      fAreas := TList.Create;
      for I := 0 to fAreaCount - 1 do
        fAreas.Add( TRegionArea.Load( F ) );
      readln( F, fPointCount );
      GetMem( fPoints, fPointCount * sizeof(TPlanePoint) );
      for I := 0 to fPointCount - 1 do
        readln( F, fPoints[I].X, fPoints[I].Y );
    except
      on E : EInOutError do
        begin
          E.Message := E.Message + ' Area ' + fName;
          raise;
        end;
    end;
  end;

  destructor TRegionArea.Destroy;
  var
    I : integer;
  begin
    for I := 0 to fAreaCount - 1 do
      TRegionArea(fAreas[I]).Free;
    fAreas.Free;
    FreeMem( fPoints, fPointCount * sizeof(TPlanePoint) );
    inherited;
  end;

  function TRegionArea.GetPoint( I : integer ) : TPlanePoint;
  begin
    Result := fPoints[I];
  end;

  function TRegionArea.GetArea ( I : integer ) : TRegionArea;
  begin
    if I < fAreaCount
      then Result := fAreas[I]
      else Result := Self;
  end;

  function TRegionArea.Contains( P : TPlanePoint ) : integer;
  var
    I : integer;
  begin
    I := 0;
    while (I < fAreaCount) and (TRegionArea(fAreas[I]).Contains(P) = -1) do
      inc( I );
    if I < fAreaCount
      then Result := I
      else
        begin
          I := 0;
          while (I < fPointCount) and (longint(P) <> longint(fPoints[I])) do
            inc( I );
          if I < fPointCount
            then Result := fAreaCount
            else Result := -1;
        end;
  end;


// TRegionReference methods

  constructor TRegionReference.Load( const aFileName : string );
  var
    F : TextFile;
  begin
    fFileName := aFileName;
    AssignFile( F, aFileName );
    Reset( F );
    readln( F, fName );
    readln( F, fRadar );
    readln( F, byte(fDefault) );
    readln( F, fPriority );
    with fLength do
      readln( F, X, Y );
    readln( F, fRange );
    readln( F, fStyle );
    Close( F );
  end;


// TRegion methods

  constructor TRegion.Load( const aFileName : string );
  var
    F       : TextFile;
    R, G, B : byte;
  begin
    fFileName := aFileName;
    AssignFile( F, aFileName );
    Reset( F );
    try
      readln( F, fName );
      readln( F, fRadar );
      readln( F, byte(fDefault) );
      readln( F, fPriority );
      with fLength do
        readln( F, X, Y );
      readln( F, fRange );
      readln( F, fStyle );
      readln( F, R, G, B );
      fColor := RGB( R, G, B );
      TRegionArea.Load( F );
    finally
      Close( F );
    end;
  end;


end.

