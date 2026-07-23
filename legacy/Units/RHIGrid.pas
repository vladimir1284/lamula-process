unit RHIGrid;

interface

uses
  Classes,
  Grid, Plane, Scan, Observation, Measure, Angle,
  RHIScan,
  PRTable, HeightTable, FloatMatrix;

type
  TRHIGrid = class(TGrid)
  public
    constructor Initialize( aRange : integer; aBottom, aTop : integer;
                            aLength : integer; aCellHeight : integer;
                            anAzimut : TAngle );
  private
    fAzimut : TAngle;
  public
    property Azimut : TAngle  read fAzimut;
  public
    procedure Render( anObs : TObservation; aChannel : integer; aMeasure : TMeasure );
    procedure RenderScan( aScan : TRHIScan );
  private
    fPRTable     : TPRTable;
    fHeightTable : THeightTable;
    fMtx         : TFloatMatrix;
    fAzimutIndex : integer;
    fAltitude    : integer;
    procedure ProcessMove( S : TScan );
  public
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  private
    procedure CreateFromMovement( Obs : TObservation; MoveIndex    : integer; Measure : TMeasure );
    procedure CreateFromChannel ( Obs : TObservation; ChannelIndex : integer; Measure : TMeasure );
  end;

implementation

uses
  Windows, SysUtils,
  Math,
  Notify, Movement,
  Radars,
  VestaPlane,
  PPIScan;

// TRHIGrid methods

constructor TRHIGrid.Initialize( aRange : integer; aBottom, aTop : integer;
                                 aLength : integer; aCellHeight : integer;
                                 anAzimut : TAngle );
begin
  inherited Initialize(PlaneArea(0,      aBottom div aCellHeight,
                                 aRange, aTop    div aCellHeight),
                       aLength, aCellHeight,
                       pkVertical);
  fAzimut := anAzimut;
  Orientation := goRightLeft;
end;

procedure TRHIGrid.Render( anObs : TObservation; aChannel : integer; aMeasure : TMeasure );
var
  Move : integer;
begin
  with anObs do
    begin
      with Radars.Find(Radar).Location do
        Self.Center := Location2D(Longitude, Latitude);
      Self.Time := Time;
      Self.Measure := aMeasure;
      Move := 0;
      while Move < Movements do
        with MoveDesc[Move] do
          if (Kind = pkVertical) and
             (Channel = aChannel) and
             (Angle = Azimut)
            then break
            else inc(Move);
      if Move < Movements
        then CreateFromMovement(anObs, Move, aMeasure)
        else CreateFromChannel(anObs, aChannel, aMeasure);
    end;
end;

procedure TRHIGrid.RenderScan( aScan : TRHIScan );
var
  A, R   : integer;
  RS, RF : integer;
  XX, YY : integer;
  M      : TFloatMatrix;
  SR     : TRay;         // Scan Ray
  C      : TCode;
  HT     : THeightTable;
  HR     : THeightRay;
  CS     : double;
  Y1, Y2 : integer;
  Altitude : integer;
begin
  with Radars.Find(aScan.Radar).Location do
    Center := Location2D(Longitude, Latitude);
  Time := aScan.Time;
  Measure := aScan.Measure;
  with Area do
    M := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
  try
    StartNotify(2);
    Altitude := round(Radars.Find(aScan.Radar).Location.Altitude/Length.Y);
    HT := HeightTable.Find(Altitude, (aScan as TRHIScan).Beam, aScan.Size.X,
                           PlanePoint(aScan.Length, Length.Y));
    try
      for A := aScan.Origin.A to aScan.Ending.A do
        begin
          HR := HT.Ray[A * Codes div aScan.Sectors + aScan.Start];
          SR := aScan.Ray[A];
          CS := cos(DegreeToRadian * CodeAngle(A * Codes div aScan.Sectors));
          for R := aScan.Origin.R to aScan.Ending.R do
            begin
              Y1 := HR[R].Min;
              Y2 := HR[R].Max;
              if (Y1 <= Ending.Y) and (Y2 >= Origin.Y)
                then
                  begin
                    RS := Min(round(R       * (aScan.Length/CS)/Length.X),     Ending.X);
                    RF := Min(round(succ(R) * (aScan.Length/CS)/Length.X) - 1, Ending.X);
                    for YY := Max(Y1, Origin.Y) to Min(Y2, Ending.Y) do
                      begin
                        C := SR[R];
                        if C <= MaxCode
                          then
                            for XX := RS to Max(RS, RF) do
                              begin
                                M   [XX, YY] :=    M[XX, YY] + CodeLineal(C, Measure);
                                Self[XX, YY] := Self[XX, YY] + 1;
                              end;
                      end;
                  end;
            end;
        end;
      Average(M, Measure);
    finally
      HT.Free;
    end;
  finally
    M.Free;
  end;
end;

procedure TRHIGrid.ProcessMove( S : TScan );
var
  RR, I  : integer;
  Y1, Y2 : integer;
  HRay   : THeightRay;
  SRay   : TRay;
  Radius : integer;
  Cosine : double;
  FirstR : integer;
begin
  if S is TPPIScan
    then
      with S as TPPIScan do
        begin
          HRay := fHeightTable.Ray[Angle];
          SRay := Ray[fAzimutIndex];
          Cosine := cos(DegreeToRadian * CodeAngle(Angle));
          FirstR := round(Self.Origin.X / Cosine);
          for RR := FirstR to Ending.R do
            begin
              Y1 := HRay[RR].Min;
              Y2 := HRay[RR].Max;
              if Y1 > Self.Ending.Y
                then break;
              if Y1 < Self.Origin.Y
                then Y1 := Self.Origin.Y;
              if Y2 > Self.Ending.Y
                then Y2 := Self.Ending.Y;
              Radius := round(RR * Cosine);
              if Radius <= Self.Ending.X
                then
                  for I := Y1 to Y2 do
//                    if (SRay[RR] > 0) and (SRay[RR] <> NODATA) then
                      begin
                        fMtx[Radius, I] := fMtx[Radius, I] + CodeLineal(SRay[RR], Measure);
                        Self[Radius, I] := Self[Radius, I] + 1;
                      end
                else break;
            end;
        end;
  DoNotify;
end;

procedure TRHIGrid.ReadState( Reader : TReader );
begin
  inherited;
  fAzimut := Reader.ReadInteger;
end;

procedure TRHIGrid.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(Azimut);
end;

procedure TRHIGrid.CreateFromMovement( Obs : TObservation; MoveIndex : integer; Measure : TMeasure );
var
  M       : TMovement;
  RHIScan : TRHIScan;
begin
  M := Obs.Movement[MoveIndex];
  try
    RHIScan := TRHIScan.RenderMove(M as TVertMove, Measure);
    try
      RenderScan(RHIScan);
    finally
      RHIScan.Free;
    end;
  finally
    M.Free;
  end;
end;

procedure TRHIGrid.CreateFromChannel( Obs : TObservation; ChannelIndex : integer; Measure : TMeasure );
begin
  with Obs do
    begin
      fAltitude := round(Radars.Find(Radar).Location.Altitude / Length.Y);
      with Channel[ChannelIndex] do
        begin
          fPRTable     := PRTable.Find(PlanePoint(Cells, Sectors), Length, Self.Length.X);
          fHeightTable := HeightTable.Find(fAltitude, Beam, Cells, PlanePoint(Length, Self.Length.Y));
        end;
      with Area do
        fMtx := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
      fAzimutIndex := Azimut * Channel[ChannelIndex].Sectors div Angle.Codes;
      StartNotify(Movements);
      try
        ProcessChannel(ChannelIndex, Measure, ProcessMove);
        Average(fMtx, Measure);
      finally
        FreeAndNil(fMtx);
        PRTable.Free(fPRTable);
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

initialization
  Classes.RegisterClass(TRHIGrid);
end.

