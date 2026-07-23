unit TopsScan;

interface

uses
  Classes,
  Scan, Plane, Measure, Description, HeightTable,
  RadarData, Observation;

type
  TTopsScan = class;

  TTopsScan = class(TScan)
  public
    constructor Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                            aBottom, aTop : integer;
                            aMinimun : TCode; aLocation : integer );
  public
    procedure Render( aData : TRadarData; aChannel : integer );  override;
  private
    fBottom, fTop : integer;
    fMinimun      : TCode;
    fMinMeasure   : TMeasure;
    fLocation     : single;
  public
    property Minimun : TCode   read fMinimun;
    property Bottom  : integer read fBottom;
    property Top     : integer read fTop;
  private
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
  RadarPlane,
  Movement, PPIScan, Angle, Notify,
  Radars;

// TTopsScan methods

constructor TTopsScan.Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                                  aBottom, aTop : integer;
                                  aMinimun : TCode; aLocation : integer );
begin
  inherited Initialize(aSize, unKM, pkHorizontal);
  fBottom     := aBottom;
  fTop        := aTop;
  fMinMeasure := aMeasure;
  fMinimun    := aMinimun;
  fLocation   := aLocation / 100;
end;

procedure TTopsScan.Render( aData : TRadarData; aChannel : integer );
begin
  with aData as TObservation do
    begin
      Self.Radar := Radar;
      Self.Time  := Time;
      with Channel[aChannel] do
        begin
          Self.Length  := Length;
          fHeightTable := HeightTable.Find(round(Radars.Find(Radar).Location.Altitude),
                                           Beam, Cells, PlanePoint(Length, 1));
        end;
      fAltitude := round(Radars.Find(Radar).Location.Altitude);
      StartNotify(Movements);
      try
        ProcessChannel(aChannel, fMinMeasure, ProcessMove);
      finally
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TTopsScan.ProcessMove( S : TScan );
var
  R, A   : integer;
  Radius : longint;
  Cosine : double;
  HRay   : THeightRay;
  MeanH  : integer;
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
                MeanH := round(Min + fLocation * (Max - Min));
              if MeanH < Bottom
                then continue;
              if MeanH > Top
                then break;
              Radius := round(R * Cosine);
              HCode  := MeasureCode(MeanH, unM);
              for A := Self.Origin.A to Self.Ending.A do
                if (Cell[R, A] >= Minimun) and (Self[Radius, A] < HCode) and
                   (Cell[R, A] <> NODATA)
                  then Self[Radius, A] := HCode
            end;
        end;
  DoNotify;
end;

procedure TTopsScan.ReadState( Reader : TReader );
begin
  inherited;
  fMinimun    := Reader.ReadInteger;
  fMinMeasure := TMeasure(Reader.ReadInteger);
end;

procedure TTopsScan.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(Minimun);
  Writer.WriteInteger(longint(fMinMeasure));
end;

initialization
  Classes.RegisterClass(TTopsScan);
end.

