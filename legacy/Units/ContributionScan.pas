unit ContributionScan;

interface

uses
  Classes,
  Scan, Plane, Description, Measure, HeightTable,
  RadarData, Observation, TimeSpan,
  FloatMatrix;

type
  TContributionScan = class(TScan)
  public
    constructor Initialize( aSize : TPlanePoint;
                            aBottom, aTop : integer;
                            aInterval : TDateTime;
                            aStart, aStop : TDateTime );
  public
    procedure Render( aData : TRadarData; aChannel : integer );  override;
  protected
    procedure RenderObs( O : TObservation; aChannel : integer );
    procedure RenderTsp( T : TTimeSpan;    aChannel : integer );
  private
    fBottom, fTop : integer;
    fInterval     : TDateTime;
    fStart, fStop : TDateTime;
  public
    property Bottom   : integer   read fBottom;
    property Top      : integer   read fTop;
    property Interval : TDateTime read fInterval;
    property Start    : TDateTime read fStart;
    property Stop     : TDateTime read fStop;
  private
    fHeightTable : THeightTable;
    fMtx         : TFloatMatrix;
    fAltitude    : integer;
    fObsHours    : double;
    procedure ProcessMove( S : TScan );
    procedure Divide     ( M : TFloatMatrix );
    procedure AddCount   ( P : TPlane );
  public
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  end;

implementation

uses
  SysUtils,
  RadarPlane,
  PPIScan, Movement, Angle, Notify,
  Radars;

const
  FiveMinutes = 5 / (24 * 60);

// TContributionScan methods

constructor TContributionScan.Initialize( aSize : TPlanePoint;
                                          aBottom, aTop : integer;
                                          aInterval : TDateTime;
                                          aStart, aStop : TDateTime );
begin
  inherited Initialize(aSize, unMM, pkHorizontal);
  fBottom   := aBottom;
  fTop      := aTop;
  fInterval := aInterval * 24;  // Hours
  fStart    := aStart;
  fStop     := aStop;
end;

procedure TContributionScan.Render( aData : TRadarData; aChannel : integer );
begin
  Radar  := aData.Radar;
  Length := aData.Channel[aChannel].Length;
  if aData is TObservation
    then RenderObs(aData as TObservation, aChannel)
    else
      if aData is TTimespan
        then RenderTsp(aData as TTimespan, aChannel);
end;

procedure TContributionScan.RenderObs( O : TObservation; aChannel : integer );
begin
  with O do
    begin
      Self.Time := Time;
      fAltitude := round(Radars.Find(Radar).Location.Altitude);
      fObsHours := fInterval;
      with Channel[aChannel] do
        fHeightTable := HeightTable.Find(fAltitude, Beam, Cells, PlanePoint(Length, 1));
      with Area do
        fMtx := NewFloatMatrix( A.X, A.Y, B.X, B.Y );
      StartNotify(Movements);
      try
        ProcessChannel(aChannel, unMMH, ProcessMove);
        Average(fMtx, Measure);
      finally
        FreeAndNil(fMtx);
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TContributionScan.RenderTSp( T : TTimeSpan; aChannel : integer );
var
  I        : integer;
  M        : TFloatMatrix;
  P        : TPlane;
  LastStop : TDateTime;
  NextStop : TDateTime;
begin
  with T do
    begin
      Self.Time  := LastTime;
      with Channel[aChannel] do
        fHeightTable := HeightTable.Find(round(Radars.Find(Radar).Location.Altitude),
                                         Beam, Cells, PlanePoint(Length, 1));
      with Area do
        begin
          fMtx := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
          M    := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
        end;
      P := TPlane.Initialize(Area, nil);
      fAltitude := round(Radars.Find(Radar).Location.Altitude);
      StartNotify(Observations);
      try
        LastStop := Start;
        for I := 0 to Observations - 1 do
          with Observation[I] do
             begin
               if Time > Stop
                 then break;
               if Time > LastStop
                 then LastStop := Time;
               if I < Observations - 1
                 then NextStop := Observation[I + 1].Time
                 else NextStop := Time + Interval; //FiveMinutes;
               if NextStop > Stop
                 then NextStop := Stop;
               fObsHours := 24 * (NextStop - LastStop);
               if fObsHours > Interval
                 then fObsHours := Interval;
               if fObsHours > 0
                 then
                   begin
                     fMtx.Clear;
                     Self.Clear;
                     Notify.Disable;
                     try
                       ProcessChannel(aChannel, unMMH, ProcessMove);
                     except
                       on E : Exception do
                         begin
                           E.Message := 'No se pudo procesar la observacion numero ' +
                                        IntToStr(succ(I)) + ':'#13#10 + E.Message;
                           raise;
                         end;
                     end;
                     Notify.Enable;
                     AddCount(P);
                     Divide(fMtx);
                     M.Add(fMtx);
                   end;
               LastStop := NextStop;
               DoNotify;
             end;
        Assign(P);
        Encode(M, Measure);
      finally
        P.Free;
        M.Free;
        FreeAndNil(fMtx);
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TContributionScan.ProcessMove( S : TScan );
var
  R, A   : integer;
  Radius : longint;
  Cosine : double;
  HRay   : THeightRay;
begin
  if S is TPPIScan
    then
      with S as TPPIScan do
        begin
          Cosine := cos(DegreeToRadian * CodeAngle(Angle));
          HRay   := fHeightTable.Ray[Angle];
          for R := Self.Origin.R to Self.Ending.R do
            begin
              if HRay[R].Max <= fBottom
                then continue;
              if HRay[R].Min >= fTop
                then break;
              Radius := round(R * Cosine);
              for A := Self.Origin.A to Self.Ending.A do
                if Cell[R, A] <> NODATA then
                  begin
                    fMtx[Radius, A] := fMtx[Radius, A] + fObsHours * CodeMeasure(Cell[R, A], unMMH);
                    Self[Radius, A] := Self[Radius, A] + 1;
                  end;
            end;
        end;
  DoNotify;
end;

procedure TContributionScan.Divide( M : TFloatMatrix );
var
  I, J : integer;
  CA   : TRow;
  MR   : TFloatRow;
begin
  MR := nil;
  for J := Origin.Y to Ending.Y do
    begin
      CA :=   Ray[J];
      MR := M.Row[J];
      for I := 0 to Width - 1 do
        if CA[I] <> 0
          then MR[I] := MR[I] / CA[I];
    end;
end;

procedure TContributionScan.AddCount( P : TPlane );
var
  I, J : integer;
  CA   : TRow;
  PR   : TRow;
begin
  for J := Origin.Y to Ending.Y do
    begin
      CA :=   CellArray[J];
      PR := P.CellArray[J];
      for I := 0 to Width - 1 do
        inc(PR[I], CA[I]);
    end;
end;

procedure TContributionScan.ReadState( Reader : TReader );
begin
  inherited;
  fTop    := Reader.ReadInteger;
  fBottom := Reader.ReadInteger;
  fStart  := Reader.ReadFloat;
  fStop   := Reader.ReadFloat;
end;

procedure TContributionScan.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(Top);
  Writer.WriteInteger(Bottom);
  Writer.WriteFloat  (Start);
  Writer.WriteFloat  (Stop);
end;

initialization
  Classes.RegisterClass(TContributionScan);
end.

