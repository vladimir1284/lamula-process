unit MaxsScan;

interface

uses
  Classes,
  Scan, Plane, Measure, Description, HeightTable,
  RadarData, Observation, TimeSpan;

type
  TMaxsScan = class;
    
  TMaxsScan = class(TScan)
  public
    constructor Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                            aBottom, aTop : integer );
  public
    procedure Render( aData : TRadarData; aChannel : integer );  override;
  private
    fBottom, fTop : integer;
    fMaxsMeasure  : TMeasure;
  public
    property Bottom : integer read fBottom;
    property Top    : integer read fTop;
  private
    fMaxsPlane   : TPlane;
    fHeightTable : THeightTable;
    fAltitude    : integer;
    procedure ProcessMove( S : TScan );
  public
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  end;

implementation

uses
  SysUtils,
  Movement, PPIScan, Angle, Notify,
  Radars;

// TMaxsScan methods

constructor TMaxsScan.Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                                  aBottom, aTop : integer );
begin
  inherited Initialize(aSize, unKM, pkHorizontal);
  fBottom      := aBottom;
  fTop         := aTop;
  fMaxsMeasure := aMeasure;
end;

procedure TMaxsScan.Render( aData : TRadarData; aChannel : integer );
begin
  with aData as TObservation do
    begin
      Self.Radar := Radar;
      Self.Time  := Time;
      fMaxsPlane := TPlane.Initialize(Area, nil);
      fAltitude  := round(Radars.Find(Radar).Location.Altitude);
      with Channel[aChannel] do
        begin
          Self.Length  := Length;
          fHeightTable := HeightTable.Find(fAltitude, Beam, Cells, PlanePoint(Length, 1));
        end;
      StartNotify(Movements);
      try
        ProcessChannel(aChannel, fMaxsMeasure, ProcessMove);
      finally
        FreeAndNil(fMaxsPlane);
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TMaxsScan.ProcessMove( S : TScan );
var
  R, A   : integer;
  Cosine : double;
  Radius : integer;
  HRay   : THeightRay;
  MeanH  : longint;
  HCode  : TCode;
begin
  if S is TPPIScan
    then
      with S as TPPIScan do
        begin
          Cosine := cos(DegreeToRadian * CodeAngle(Angle));
          HRay   := fHeightTable.Ray[Angle];
          for R := Self.Origin.R to Self.Ending.R do
            begin
              with HRay[R] do
                MeanH := round(Min + (Max - Min)/2);
              if MeanH < Bottom
                then continue;
              if MeanH > Top
                then break;
              HCode  := MeasureCode(MeanH, unM);
              Radius := round(R * Cosine);
              for A := Self.Origin.A to Self.Ending.A do
                if (Cell[R, A] > fMaxsPlane[Radius, A]) and
                   (Cell[R, A] <> NODATA)
                  then
                    begin
                      Self      [Radius, A] := HCode;
                      fMaxsPlane[Radius, A] := Cell[R, A];
                    end;
            end;
        end;
  DoNotify;
end;

procedure TMaxsScan.ReadState( Reader : TReader );
begin
  inherited;
  fTop         := Reader.ReadInteger;
  fBottom      := Reader.ReadInteger;
  fMaxsMeasure := TMeasure(Reader.ReadInteger);
end;

procedure TMaxsScan.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(Top);
  Writer.WriteInteger(Bottom);
  Writer.WriteInteger(longint(fMaxsMeasure));
end;

initialization
  Classes.RegisterClass(TMaxsScan);
end.

