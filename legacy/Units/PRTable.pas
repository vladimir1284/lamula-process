unit PRTable;

interface

uses
  Classes, SysUtils,
  Plane;

type
  EPRTableException = class(Exception);
    EPRTableError   = class(EPRTableException);

type
  TPointRow   = TPointArray;
  TPointRay   = TPointArray;
  TPointTable = array of TPointArray;

type
  TPRTable = class
  public
    constructor Create( aPolarCells : TPlanePoint;
                        aPolarSize, aGridSize : integer );
    destructor  Destroy;  override;
  protected
    fGridSize     : smallint;
    fPolarSize    : smallint;
    fGridEntries  : TPlanePoint;
    fPolarEntries : TPlanePoint;
    function GetGridCells  : TPlanePoint;
    function GetPolarCells : TPlanePoint;
    function GetGridArea   : TPlaneArea;
    function GetPolarArea  : TPlaneArea;
    function GetPolar2Grid( R, A : integer ) : TPlanePoint;
    function GetGrid2Polar( X, Y : integer ) : TPlanePoint;
    function GetPointRay  ( A : integer )    : TPointRay;
    function GetPointRow  ( Y : integer )    : TPointRow;
  public
    property GridSize     : smallint    read fGridSize;
    property PolarSize    : smallint    read fPolarSize;
    property GridCells    : TPlanePoint read GetGridCells;
    property PolarCells   : TPlanePoint read GetPolarCells;
    property GridEntries  : TPlanePoint read fGridEntries;
    property GridArea     : TPlaneArea  read GetGridArea;
    property PolarArea    : TPlaneArea  read GetPolarArea;
    property PolarEntries : TPlanePoint read fPolarEntries;
    property Polar2Grid[R, A : integer] : TPlanePoint read GetPolar2Grid;
    property Grid2Polar[X, Y : integer] : TPlanePoint read GetGrid2Polar;
  public {for friends}
    property PointRay[A : integer] : TPointRay read GetPointRay;
    property PointRow[Y : integer] : TPointRow read GetPointRow;
  public
    function PolarIncluded( C1, C2 : integer ) : boolean;
    function GridIncluded ( C1, C2 : integer ) : boolean;
  private
    fPolar2Grid : TPointTable;
    fGrid2Polar : TPointTable;
    procedure AllocateTableMem;
    procedure FreeTableMem;
    procedure AllocatePolarTables;
    procedure AllocateGridTables;
    procedure FreePolarTables;
    procedure FreeGridTables;
  private
    Angle_90  : integer;
    Angle_180 : integer;
    Angle_270 : integer;
    Angle_360 : integer;
    procedure FindAngles;
  end;

function Find( aPolarCells : TPlanePoint;
               aPolarSize, aGridSize : integer ) : TPRTable;
function Free( var aPRTable : TPRTable ) : boolean;

procedure StartCaching;
procedure StopCaching;

implementation

uses
  Math;

threadvar
  CachedTables : TList;

// Public procedures & functions

function Find( aPolarCells : TPlanePoint;
               aPolarSize, aGridSize : integer ) : TPRTable;
var
  I : integer;
begin
  if assigned(CachedTables)
    then
      for I := 0 to CachedTables.Count - 1 do
        with TPRTable(CachedTables[I]) do
          if (aPolarCells.A = PolarCells.A) and
             (aPolarCells.R <= PolarCells.R) and
             (aPolarSize = PolarSize) and
             (aGridSize = GridSize)
            then
              begin
                Result := TPRTable(CachedTables[I]);
                exit;
              end;
  Result := TPRTable.Create( aPolarCells, aPolarSize, aGridSize );
end;

function Free( var aPRTable : TPRTable ) : boolean;
begin
  Result := not assigned(CachedTables);
  if Result
    then FreeAndNil(aPRTable);
end;

procedure StartCaching;
begin
  CachedTables := TList.Create;
end;

procedure StopCaching;
var
  I : integer;
begin
  if assigned(CachedTables)
    then
      try
        for I := CachedTables.Count - 1 downto 0 do
          TPRTable(CachedTables[I]).Free;
      finally
        CachedTables.Clear;
        FreeAndNil(CachedTables);
      end;
end;

// TPRTable methods

constructor TPRTable.Create( aPolarCells : TPlanePoint;
                             aPolarSize, aGridSize : integer );

  procedure CreatePolarTables;  {Polar -> Rectangular}
  var
    A, R, X, Y    : integer;
    Ang, dAng     : double;
    XInc, YInc    : double;
    theX, theY    : double;
  begin
    dAng := (2*Pi)/aPolarCells.A;
    Ang  := dAng/2;
    for A := 0 to fPolarEntries.A - 1 do
      begin
        XInc := aPolarSize * sin(Ang)/aGridSize;
        YInc := aPolarSize * cos(Ang)/aGridSize;
        theX := 0;
        theY := 0;
        for R := 0 to fPolarEntries.R - 1 do
          begin
            X := round(theX);
            Y := round(theY);
            fPolar2Grid[A][R] := PlanePoint(X, Y);
            theX := theX + XInc;
            theY := theY + YInc;
          end;
        Ang := Ang + dAng;
      end;
  end;

  procedure CreateGridTables;
  var
    X, Y, A, R : integer;
    theX, theY : double;
    Shift      : double;
    Rad2Deg    : double;
  begin
    Shift   := aGridSize/4;
    theY    := Shift;
    Rad2Deg := fPolarEntries.A/(Pi/2);
    for Y := 0 to fGridEntries.Y - 1 do
      begin
        theX := Shift;
        for X := 0 to fGridEntries.X - 1 do
          begin
            R := round(sqrt(sqr(theX) + sqr(theY))/aPolarSize);
            A := round(Rad2Deg * arctan(theX/theY));
            fGrid2Polar[Y][X] := PlanePoint(R, A);
            theX := theX + aGridSize;
          end;
        theY := theY + aGridSize;
      end;
  end;

begin
  inherited Create;
  fPolarEntries.R := aPolarCells.R;
  fPolarEntries.A := aPolarCells.A div 4;
  fGridEntries.X  := ceil(aPolarCells.R * aPolarSize/aGridSize);
  fGridEntries.Y  := ceil(aPolarCells.R * aPolarSize/aGridSize);
  fPolarSize := aPolarSize;
  fGridSize  := aGridSize;
  FindAngles;
  try
    AllocateTableMem;
    CreatePolarTables;
    CreateGridTables;
  except
    FreeTableMem;
    raise;
  end;
  if assigned(CachedTables)
    then CachedTables.Add(Self);
end;

destructor TPRTable.Destroy;
begin
  FreeTableMem;
  inherited Destroy;
end;

function TPRTable.GetGridCells : TPlanePoint;
begin
  with fGridEntries do
    Result := PlanePoint(2*X, 2*Y);
end;

function TPRTable.GetPolarCells : TPlanePoint;
begin
  with fPolarEntries do
    Result := PlanePoint(R, 4*A);
end;

function TPRTable.GetPolar2Grid( R, A : integer ) : TPlanePoint;
begin
  if A < Angle_90
    then Result := fPolar2Grid[A][R]             // Primer cuadrante
  else if A < Angle_180
    then
      with fPolar2Grid[Angle_180 - A - 1][R] do  // Segundo cuadrante
        begin
          Result.X :=  X;
          Result.Y := -Y;
        end
  else if A < Angle_270
    then
      with fPolar2Grid[A - Angle_180][R] do      // Tercer cuadrante
        begin
          Result.X := -X;
          Result.Y := -Y;
        end
  else if A < Angle_360
    then
      with fPolar2Grid[Angle_360 - A - 1][R] do  // Cuarto cuadrante
        begin
          Result.X := -X;
          Result.Y :=  Y;
        end
  else Result := GetPolar2Grid(R, A mod Angle_360);
end;

function TPRTable.GetGrid2Polar( X, Y : integer ) : TPlanePoint;
begin
  if (X >= 0) and (Y > 0)
    then Result := fGrid2Polar[Y][X]  // Primer cuadrante
  else if (X > 0) and (Y <= 0)
    then with fGrid2Polar[-Y][X] do   // Segundo cuadrante
      begin
        Result.R := R;
        Result.A := Angle_180 - A - 1;
      end
  else if (X <= 0) and (Y < 0)
    then with fGrid2Polar[-Y][-X] do  // Tercer cuadrante
      begin
        Result.R := R;
        Result.A := Angle_180 + A;
      end
  else
    with fGrid2Polar[Y][-X] do        // Cuarto cuadrante
      begin
        Result.R := R;
        Result.A := Angle_360 - A - 1;
      end;
end;

function TPRTable.GetPointRay( A : integer ) : TPointRay;
begin
  Result := TPointRay(fPolar2Grid[A]);
end;

function TPRTable.GetPointRow( Y : integer ) : TPointRow;
begin
  Result := TPointRow(fGrid2Polar[Y])
end;

procedure TPRTable.AllocateTableMem;
begin
  AllocatePolarTables;
  AllocateGridTables;
end;

procedure TPRTable.FreeTableMem;
begin
  FreePolarTables;
  FreeGridTables;
end;

procedure TPRTable.AllocatePolarTables;
begin
  SetLength(fPolar2Grid, fPolarEntries.A, fPolarEntries.R);
end;

procedure TPRTable.AllocateGridTables;
begin
  SetLength(fGrid2Polar, fGridEntries.Y, fGridEntries.X);
end;

procedure TPRTable.FreePolarTables;
begin
  Finalize(fPolar2Grid);
end;

procedure TPRTable.FreeGridTables;
begin
  Finalize(fGrid2Polar);
end;

procedure TPRTable.FindAngles;
begin
  Angle_90  :=     PolarEntries.A;
  Angle_180 := 2 * PolarEntries.A;
  Angle_270 := 3 * PolarEntries.A;
  Angle_360 := 4 * PolarEntries.A;
end;

function TPRTable.GridIncluded(C1, C2: integer): boolean;
begin
  with GridArea do
    Result := (C1 >= A.X) and (C1 <= B.X) and
              (C2 >= A.Y) and (C2 <= B.Y);
end;

function TPRTable.PolarIncluded(C1, C2: integer): boolean;
begin
  with PolarArea do
    Result := (C1 >= A.R) and (C1 <= B.R) and
              (C2 >= A.A) and (C2 <= B.A);
end;

function TPRTable.GetGridArea: TPlaneArea;
begin
  with Result do
    begin
      A.X := -pred(fGridEntries.X);
      A.Y := -pred(fGridEntries.Y);
      B.X :=  pred(fGridEntries.X);
      B.Y :=  pred(fGridEntries.Y);
    end;
end;

function TPRTable.GetPolarArea: TPlaneArea;
begin
  with Result do
    begin
      A.R := 0;
      A.A := 0;
      B.R := pred(fPolarEntries.R);
      B.A := pred(fPolarEntries.A);
    end;
end;

end.

