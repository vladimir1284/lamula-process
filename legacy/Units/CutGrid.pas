unit CutGrid;

interface

uses
  Classes,
  Grid, Plane, Observation, Description, Measure, Scan,
  FloatMatrix,
  PRTable, HeightTable, Settings;

type
  TCutGrid = class;

  TCutGrid = class(TGrid)
  public
    constructor Initialize( aLength : integer; aCellHeight : integer;
                            HMin, HMax : integer; aP1, aP2 : TPlanePoint );
    procedure   Render( anObs : TObservation; aChannel : integer; aMeasure : TMeasure );
  private
    fP1, fP2 : TPlanePoint;
  public
    property P1 : TPlanePoint read fP1;
    property P2 : TPlanePoint read fP2;
  private
    fPRTable     : TPRTable;
    fHeightTable : THeightTable;
    fMtx         : TFloatMatrix;
    fCoords      : TList;
    fAltitude    : integer;
    procedure ProcessMove( S : TScan );
    procedure GetCoords;
  public
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  end;

implementation

uses
  SysUtils, Math,
  Angle, PPIScan, Notify,
  Radars;

// TCutGrid methods

constructor TCutGrid.Initialize( aLength : integer; aCellHeight : integer;
                                 HMin, HMax : integer; aP1, aP2 : TPlanePoint );
var
  D : integer;
begin
  D := ceil(sqrt(sqr(aP2.X - aP1.X) + sqr(aP2.Y - aP1.Y)));
  inherited Initialize(PlaneArea(0, HMin div aCellHeight, D - 1, HMax div aCellHeight - 1),
                       aLength, aCellHeight,
                       pkVertical);
  fP1 := aP1;
  fP2 := aP2;
  Orientation := goLeftRight;
end;

procedure TCutGrid.Render( anObs : TObservation; aChannel : integer; aMeasure : TMeasure );
var
  PRSize : TPlanePoint;
begin
  with anObs do
    begin
      with Radars.Find(Radar).Location do
        Self.Center := Location2D(Longitude, Latitude);
      Self.Time := Time;
      Self.Measure := aMeasure;
      if abs(P1.X) > abs(P2.X)
        then PRSize.X := 2 * abs(P1.X)
        else PRSize.X := 2 * abs(P2.X);
      if abs(P1.Y) > abs(P2.Y)
        then PRSize.Y := 2 * abs(P1.Y)
        else PRSize.Y := 2 * abs(P2.Y);
      fAltitude := round(Radars.Find(Radar).Location.Altitude/Length.Y);
      with Channel[aChannel] do
        begin
          fHeightTable := HeightTable.Find(fAltitude, Beam, Cells, PlanePoint(Length, Self.Length.Y));
          fPRTable := PRTable.Find(PlanePoint(Cells, Sectors), Length, Self.Length.X);
          try
            GetCoords;
          finally
            PRTable.Free(fPRTable);
          end;
        end;
      with Area do
        begin
          fMtx := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
        end;
      StartNotify(anObs.Movements);
      try
        ProcessChannel(aChannel, aMeasure, ProcessMove);
        Average(fMtx, Measure);
      finally
        FreeAndNil(fCoords);
//        FreeAndNil(fMtx);
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TCutGrid.ProcessMove( S : TScan );
var
  P, I    : integer;
  Cosine  : double;
  RR, AA  : integer;
  Y1, Y2  : integer;
  HRay    : THeightRay;
  Zero    : boolean;
//  PCoords : TPointRow;
begin
//  PCoords := nil;
  Zero := theSettings.IncludeZero;
  if S is TPPIScan
    then
      with S as TPPIScan do
        begin
          Cosine  := cos(DegreeToRadian * CodeAngle(Angle));
          HRay    := fHeightTable.Ray[Angle];
//          PCoords := TPointRow(fCoords.List);
//          for P := 0 to Self.Width - 1 do
          for P := 0 to fCoords.Count - 1 do
            if fCoords[P] <> nil
              then
                begin
//                  with PCoords[P] do
                  with TPlanePoint(fCoords[P]) do
                    begin
                      RR := round(R/Cosine);
                      AA := A;
                    end;
                  if RR < Radiuses
                    then
                      begin
                        Y1 := HRay[RR].Min;
                        Y2 := HRay[RR].Max;
                        if Y1 > Self.Ending.Y
                          then Continue;
                        if Y1 < Self.Origin.Y
                          then Y1 := Self.Origin.Y;
                        if Y2 > Self.Ending.Y
                          then Y2 := Self.Ending.Y;
                        for I := Y1 to Y2 do
                          if (S[RR, AA] <> NODATA) and
                             (Zero or (not Zero and (S[RR, AA] > 0))) then
                            begin
                              fMtx[P, I] := fMtx[P, I] + CodeLineal(S[RR, AA], Measure);
                              Self[P, I] := Self[P, I] + 1;
                            end;
                      end;
                end;
        end;
  DoNotify;
end;

procedure TCutGrid.GetCoords;
var
  I      : integer;
  DX, DY : double;
  SX, SY : double;
  RX, RY : integer;
begin
  fCoords := TList.Create;
  fCoords.Capacity := Width;
  DX := (P2.X - P1.X) / Width;
  DY := (P2.Y - P1.Y) / Width;
  SX := P1.X;
  SY := P1.Y;
  with fPRTable do
    for I := 0 to Width - 1 do
      begin
        RX := round(SX);
        RY := round(SY);
        if GridIncluded(RX, RY)
          then fCoords.Add(pointer(Grid2Polar[RX, RY]))
          else fCoords.Add(nil);
        SX := SX + DX;
        SY := SY + DY;
      end;
end;

procedure TCutGrid.ReadState( Reader : TReader );
begin
  inherited;
  fP1 := ReadPlanePoint(Reader);
  fP2 := ReadPlanePoint(Reader);
end;

procedure TCutGrid.WriteState( Writer : TWriter );
begin
  inherited;
  WritePlanePoint(Writer, P1);
  WritePlanePoint(Writer, P2);
end;

initialization
  Classes.RegisterClass(TCutGrid);
end.

