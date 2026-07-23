unit HeightTable;

interface

uses
  Referenced, Angle, Plane,
  Classes;

type
  THeight = smallint;

const
  InvalidHeight = High(THeight);

type
  THeightCell = packed record
    Min : THeight;
    Max : THeight;
  end;

type
  THeightArray    = array[0..0] of THeightCell;
  THeightRow      = ^THeightArray;
  THeightRay      = THeightRow;
  THeightRowArray = array[0..0] of THeightRow;
  THeights        = ^THeightRowArray;

type
  THeightTable = class
    public
      constructor Create( anAltitude : integer;
                          aBeam : double; aCells : integer;
                          aLength : TPlanePoint );
      destructor  Destroy;  override;
    protected
      fAltitude : integer;
      fBeam     : double;
      fCells    : integer;
      fLength   : TPlanePoint;
      fAngles   : TList;
      fHeights  : TList;
      function  GetRay( A : integer ) : THeightRay;
      function  GetHeights( R, A : integer ) : THeightCell;
    public
      property Altitude : integer     read fAltitude;
      property Beam     : double      read fBeam;
      property Cells    : integer     read fCells;
      property Length   : TPlanePoint read fLength;
      property Ray    [A    : integer] : THeightRay  read GetRay;
      property Heights[R, A : integer] : THeightCell read GetHeights;  default;
    private
      procedure AddRay( A : TAngle );
  end;

function Find( anAltitude : integer;
               aBeam : double; aCells : integer;
               aLength : TPlanePoint ) : THeightTable;
function Free( var aHeightTable : THeightTable ) : boolean;

procedure StartCaching;
procedure StopCaching;

implementation

uses
  SysUtils,
  Notify;

threadvar
  CachedTables : TList;

// Public procedures & functions

function Find( anAltitude : integer;
               aBeam : double; aCells : integer;
               aLength : TPlanePoint ) : THeightTable;
var
  I : integer;
begin
  if assigned(CachedTables)
    then
      for I := 0 to CachedTables.Count - 1 do
        with THeightTable(CachedTables[I]) do
          if (anAltitude = Altitude) and
             (aBeam = Beam) and
             (aCells <= Cells) and
             (longint(Length) = longint(aLength))
            then
              begin
                Result := THeightTable(CachedTables[I]);
                exit;
              end;
  Result := THeightTable.Create(anAltitude, aBeam, aCells, aLength);
end;

function Free( var aHeightTable : THeightTable ) : boolean;
begin
  Result := not assigned(CachedTables);
  if Result
    then FreeAndNil(aHeightTable);
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
          THeightTable(CachedTables[I]).Free;
      finally
        CachedTables.Clear;
        FreeAndNil(CachedTables);
      end;
end;

// THeightTable methods

constructor THeightTable.Create( anAltitude : integer;
                                 aBeam : double; aCells : integer;
                                 aLength : TPlanePoint );
begin
  inherited Create;
  fAltitude := anAltitude;
  fBeam     := aBeam;
  fCells    := aCells;
  fLength   := aLength;
  fAngles   := TList.Create;
  fHeights  := TList.Create;
  if assigned(CachedTables)
    then CachedTables.Add(Self);
end;

destructor THeightTable.Destroy;
var
  I : integer;
begin
  for I := fHeights.Count - 1 downto 0 do
    FreeMem(fHeights[I]);
  FreeAndNil(fHeights);
  FreeAndNil(fAngles);
  inherited Destroy;
end;

function THeightTable.GetRay( A : integer ) : THeightRay;
var
  I : integer;
begin
  I := 0;
  while (I < fAngles.Count) and (integer(fAngles[I]) <> A) do
    inc( I );
  if I = fAngles.Count
    then AddRay(A);
  Result := fHeights[I];
end;

function THeightTable.GetHeights( R, A : integer ) : THeightCell;
begin
  Result := Ray[A][R];
end;

{
procedure THeightTable.AddRay( A : TAngle );
var
  R      : integer;
  MinSin : double;
  MaxSin : double;
  L2KM   : double;
  HRay   : THeightRay;
const
  Beta = 6e-5;
begin
  L2KM := Length.X / 1000;
  MinSin := sin(DegreeToRadian * (CodeAngle(A) - fBeam/2));
  MaxSin := sin(DegreeToRadian * (CodeAngle(A) + fBeam/2));
  GetMem(HRay, fCells * sizeof(THeightCell));
  for R := 0 to fCells - 1 do
    with HRay[R] do
      begin
        Min := round(((MinSin * R * L2KM + Beta * sqr(R * L2KM)) * 1000) / Length.Y);
        Max := round(((MaxSin * R * L2KM + Beta * sqr(R * L2KM)) * 1000) / Length.Y);
      end;
  fAngles.Add(pointer(A));
  fHeights.Add(HRay);
end;
}

procedure THeightTable.AddRay( A : TAngle );
var
  R      : integer;
  MinCos : double;
  MaxCos : double;
  LX2KM  : double;
  LY2KM  : double;
  Height : double;
  HRay   : THeightRay;
const
  Re = 6378.160;
  RefIndex = 4/3;
var
  Rref : double;
  Ralt : double;
  Rpln : double;
begin
  LX2KM  := Length.X/1000;
  LY2KM  := Length.Y/1000;
  Rref   := RefIndex * Re;
  Ralt   := Rref + Altitude * LY2KM;
  MinCos := cos(Pi/2 + DegreeToRadian * (CodeAngle(A) - fBeam/2));
  MaxCos := cos(Pi/2 + DegreeToRadian * (CodeAngle(A) + fBeam/2));
  GetMem(HRay, fCells * sizeof(THeightCell));
  for R := 0 to fCells - 1 do
    with HRay[R] do
      begin
        Rpln := R * LX2KM;
        Height := (sqrt(sqr(Ralt) + sqr(Rpln) - 2*Ralt*Rpln*MinCos) - Rref) / LY2KM;
        if (Height >= Low(THeight)) and (Height < High(THeight))
          then Min := round(Height)
          else Min := InvalidHeight;
        Height := (sqrt(sqr(Ralt) + sqr(Rpln) - 2*Ralt*Rpln*MaxCos) - Rref) / LY2KM;
        if (Height >= Low(THeight)) and (Height < High(THeight))
          then Max := round(Height)
          else Max := InvalidHeight;
      end;
  fAngles.Add(pointer(A));
  fHeights.Add(HRay);
end;

end.

