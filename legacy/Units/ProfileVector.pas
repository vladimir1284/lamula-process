unit ProfileVector;

interface

uses
  Types, Classes,
  RadarVector, Plane, Observation, Measure, Scan, HeightTable;

type
  TProfileVector = class(TRadarVector)
  public
    constructor Initialize( const aPoint : TPoint; aLength : integer;
                            aBottom, aTop : integer );
    procedure   Assign( Source : TPersistent );  override;
    procedure   Render( anObs : TObservation; aChannel : integer; aMeasure : TMeasure );
  private
    fTop, fBottom : integer;
    fPoint        : TPoint;  // in units of m
    fLength       : integer;
    fMeasure      : TMeasure;
  public
    property Top     : integer  read fTop;
    property Bottom  : integer  read fBottom;
    property Point   : TPoint   read fPoint;
    property Length  : integer  read fLength;
    property Measure : TMeasure read fMeasure;
  public
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  private
    fHeightTable : THeightTable;
    fAltitude    : integer;
    fSector      : integer;
    fRange       : integer;
    fDataPoints  : TList;
    fDataHeight  : TList;
    procedure ProcessMove( S : TScan );
    procedure Interpolate;
  end;

implementation

uses
  SysUtils,
  Math,
  utMath,
  Angle,
  Radars,
  PPIScan,
  Notify;

// TProfileVector methods

constructor TProfileVector.Initialize( const aPoint : TPoint; aLength : integer;
                                       aBottom, aTop : integer );
begin
  inherited Initialize(aBottom div aLength, aTop div aLength);
  fLength := aLength;
  fPoint  := aPoint;
  fTop    := aTop;
  fBottom := aBottom;
end;

procedure TProfileVector.Assign( Source : TPersistent );
begin
  if Source is TProfileVector
    then
      begin
        fTop     := TProfileVector(Source).Top;
        fBottom  := TProfileVector(Source).Bottom;
        fPoint   := TProfileVector(Source).Point;
        fLength  := TProfileVector(Source).Length;
        fMeasure := TProfileVector(Source).Measure;
      end;
  inherited Assign(Source);
end;

procedure TProfileVector.Render( anObs : TObservation; aChannel : integer; aMeasure : TMeasure );
begin
  with anObs do
    begin
      Self.Radar := Radar;
      Self.Time  := Time;
      fMeasure   := aMeasure;
      fAltitude  := round(Radars.Find(Radar).Location.Altitude/Length);
      with Channel[aChannel] do
        begin
          fHeightTable := HeightTable.Find(fAltitude, Beam, Cells, PlanePoint(Length, 1));  // Height resolution = 1 meter
          fRange := round(sqrt(sqr(Point.X/Length) + sqr(Point.Y/Length)));
          if Point.Y <> 0
            then
              begin
                fSector := round(ArcTan2(Point.X, Point.Y) * Sectors/(2*Pi));
                if fSector < 0
                  then inc(fSector, Sectors);
              end
            else
              if Point.X >= 0
                then fSector := 0
                else fSector := Sectors div 2;
        end;
      fDataPoints := TList.Create;
      fDataHeight := TList.Create;
      StartNotify(Movements);
      try
        if fRange > 0
          then ProcessChannel(aChannel, Measure, ProcessMove);
        Interpolate;
      finally
        FreeAndNil(fDataPoints);
        FreeAndNil(fDataHeight);
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TProfileVector.ProcessMove( S : TScan );
var
  R, H, V : integer;
begin
  if S is TPPIScan
    then
      with S as TPPIScan do
        begin
          R := round(fRange/cos(DegreeToRadian * CodeAngle(Angle)));
          V := S[R,fSector];
          if (R < Radiuses) and (V >= MinCode) and (V <= MaxCode)
            then
              begin
                with fHeightTable.Ray[Angle][R] do
                  if (Min <> InvalidHeight) and (Max <> InvalidHeight)
                    then H := (Max + Min) div 2
                    else H := InvalidHeight;
                if (H >= fBottom) and (H < fTop)
                  then
                    begin
                      fDataHeight.Add(pointer(H));
                      fDataPoints.Add(pointer(V));
                    end;
              end;
        end;
  DoNotify;
end;

procedure TProfileVector.Interpolate;
var
  I, N : integer;
  XA, YA, Y2 : array of double;
  XX, YY : double;
begin
  assert(fDataHeight.Count = fDataPoints.Count);
  N := fDataHeight.Count + 1;
  SetLength(XA, N);
  SetLength(YA, N);
  SetLength(Y2, N);
  for I := 0 to fDataHeight.Count - 1 do
    begin
      XA[I] := integer(fDataHeight[I]);
      YA[I] := CodeMeasure(integer(fDataPoints[I]), Measure);
    end;
  XA[N-1] := 20000.0;
  YA[N-1] := CodeMeasure(0, Measure);
  try
    FillChar(Cells^, Size, NoData);
    Spline(XA, YA, N, cs_Natural, cs_Natural, Y2);
    for I := 0 to Size - 1 do
      begin
        XX := Origin + I * Length;
        if XX <= XA[0]
          then YY := YA[0]
          else YY := SplInt(XA, YA, Y2, N, XX);
        Cells^[I] := MeasureCode(YY, Measure);
      end;
  except
  end;
end;

procedure TProfileVector.ReadState( Reader : TReader );
begin
  inherited;
  fLength := Reader.ReadInteger;
  fTop    := Reader.ReadInteger;
  fBottom := Reader.ReadInteger;
  fPoint  := ReadPoint(Reader);
end;

procedure TProfileVector.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(fLength);
  Writer.WriteInteger(fTop);
  Writer.WriteInteger(fBottom);
  WritePoint(Writer, fPoint);
end;

initialization
  Classes.RegisterClass(TProfileVector);
end.
