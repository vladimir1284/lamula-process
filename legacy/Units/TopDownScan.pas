unit TopDownScan;

interface

uses
  Classes,
  Scan, Plane, Description, Measure, HeightTable,
  RadarData, Observation;

type
  TTopDownScan = class;

  TTopDownScan = class(TScan)
  public
    constructor Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                            aMin, aMax : integer );
  public
    procedure Render( aData : TRadarData; aChannel : integer );  override;
  private
    fBottom, fTop : integer;
  public
    property Bottom : integer read fBottom;
    property Top    : integer read fTop;
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
  PPIScan, Movement, Angle, Notify,
  Radars,
  VestaPlane;

// TTopDownScan methods

constructor TTopDownScan.Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                                     aMin, aMax : integer );
begin
  inherited Initialize(aSize, aMeasure, pkHorizontal);
  fBottom := aMin;
  fTop    := aMax;
end;

procedure TTopDownScan.Render( aData : TRadarData; aChannel : integer );
begin
  with aData as TObservation do
    begin
      Self.Radar := Radar;
      Self.Time  := Time;
      fAltitude  := round(Radars.Find(Radar).Location.Altitude);
      with Channel[aChannel] do
        begin
          Self.Length  := Length;
          fHeightTable := HeightTable.Find(fAltitude, Beam, Cells, PlanePoint(Length, 1));
        end;
      StartNotify(Movements);
      try
        ProcessChannel(aChannel, Measure, ProcessMove);
      finally
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TTopDownScan.ProcessMove( S : TScan );
var
  R, A   : integer;
  Radius : longint;
  Cosine : double;
  HRay   : THeightRay;
  V, C   : integer;
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
                begin
                  V := Self[Radius, A];
                  C := Cell[R, A];
                  if ((V = NoData) or (C > V)) and (C <> NODATA)
                    then Self[Radius, A] := C;
                end;
            end;
        end;
  DoNotify;
end;

procedure TTopDownScan.ReadState( Reader : TReader );
begin
  inherited;
  fTop    := Reader.ReadInteger;
  fBottom := Reader.ReadInteger;
end;

procedure TTopDownScan.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(Top);
  Writer.WriteInteger(Bottom);
end;


initialization
  Classes.RegisterClass(TTopDownScan);
end.

