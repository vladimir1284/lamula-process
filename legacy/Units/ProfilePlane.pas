unit ProfilePlane;

interface

  uses
    Classes,
    Plane, Observation, Description, Measure, Scan,
    FloatMatrix,
    HeightTable;

  type
    TProfilePlane = class(TRectangularPlane)
    public
      constructor Initialize( aCellHeight : integer;
                              HMin, HMax : integer;
                              aPoint : TPlanePoint );
      procedure   Render( anObs : TObservation; aChannel : integer; aMeasure : TMeasure );
    private
      fTop, fBottom : integer;
      fHeight       : integer;
      fPoint        : TPlanePoint;
    public
      property Top        : integer     read fTop;
      property Bottom     : integer     read fBottom;
      property CellHeight : integer     read fHeight;
      property Point      : TPlanePoint read fPoint;
    private
      fPolar       : TPlanePoint;
      fHeightTable : THeightTable;
      fMtx         : TFloatMatrix;
      fAltitude    : integer;
      procedure ProcessMove( S : TScan );
    end;


implementation

  uses
    SysUtils,
    Angle, PPIScan, Notify,
    PRTables, HeightTables, Radars;


// TProfilePlane methods

  constructor TProfilePlane.Initialize( aCellHeight : integer;
                                        HMin, HMax : integer;
                                        aPoint : TPlanePoint );
  begin
    inherited Initialize( PlaneArea( 0, HMin div aCellHeight, 0, HMax div div aCellHeight ) );
    fTop    := HMin;
    fBottom := HMax;
    fPoint  := aPoint;
    fBrief := Format( 'Perfil en %d,%d', [fPoint.X, fPoint.Y] );
  end;

  procedure TProfilePlane.Render( anObs : TObservation; aChannel : integer; aMeasure : TMeasure );
  var
    PRSize : TPlanePoint;
  begin
    with anObs do
      begin
        Self.Radar := Radar;
        Self.Time  := Time;
        fMeasure   := aMeasure;
        if abs(P1.X) > abs(P2.X)
          then PRSize.X := 2 * abs(P1.X)
          else PRSize.X := 2 * abs(P2.X);
        if abs(P1.Y) > abs(P2.Y)
          then PRSize.Y := 2 * abs(P1.Y)
          else PRSize.Y := 2 * abs(P2.Y);
        with Channel[aChannel] do
          begin
            fPRTable     := PRTables.Find( HorzSize, Length, PRSize, 1000 );
            fHeightTable := HeightTables.Find( Beam, PPIAngles, Cells, PlanePoint(Length, Self.Length.Y) );
          end;
        try
          GetCoords;
        finally
          fPRTable.Free;
        end;
        fMtx := NewMatrix( Area );
        fAltitude := round(Radars.Find(Radar).Location.Altitude / Length.Y);
        StartNotify( anObs.Movements );
        try
          ProcessChannel( aChannel, aMeasure, ProcessMove );
          fMtx.Average( Self, Measure );
        finally
          fCoords.Free;
          fMtx.Free;
          fHeightTable.Free;
          EndNotify;
        end;
      end;
  end;

  procedure TProfilePlane.ProcessMove( S : TScan );
  var
    P, I    : integer;
    Cosine  : double;
    RR, AA  : integer;
    Y1, Y2  : integer;
    HRay    : THeightRay;
    PCoords : TPointRow;
  begin
    if S is TPPIScan
      then
        with S as TPPIScan do
          begin
            Cosine  := cos(DegreeToRadian * CodeAngle(Elevation));
            HRay    := fHeightTable.Ray[Elevation];
            PCoords := TPointRow(fCoords.List);
            for P := 0 to Self.Width - 1 do
                begin
                  with PCoords[P] do
                    begin
                      RR := round(R / Cosine);
                      AA := A;
                    end;
                  if RR < Radiuses
                    then
                      begin
                        Y1 := fAltitude + HRay[RR].Min;
                        Y2 := fAltitude + HRay[RR].Max;
                        if Y1 > Self.Ending.Y
                          then Continue;
                        if Y1 < Self.Origin.Y
                          then Y1 := Self.Origin.Y;
                        if Y2 > Self.Ending.Y
                          then Y2 := Self.Ending.Y;
                        for I := Y1 to Y2 do
                          begin
                            fMtx[P, I] := fMtx[P, I] + CodeMeasure( S[RR, AA], Measure );
                            Self[P, I] := Self[P, I] + 1;
                          end
                      end;
                end;
          end;
    DoNotify;
  end;


end.

