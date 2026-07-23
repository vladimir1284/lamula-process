unit CAPPIScan;

interface

uses
  Classes,
  Scan, Plane, Description, Measure, HeightTable,
  RadarData, Observation, 
  FloatMatrix;

type
  TCAPPIScan = class(TScan)
  public
    constructor Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                            aBottom, aTop : integer );
  public
    procedure Render( aData : TRadarData; aChannel : integer );  override;
  private
    fBottom, fTop : integer;
  public
    property Bottom : integer read fBottom;
    property Top    : integer read fTop;
  private
    fHeightTable : THeightTable;
    fMtx         : TFloatMatrix;
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
  PPIScan, Movement, Angle, Notify,
  Radars;

// TCAPPIScan methods

constructor TCAPPIScan.Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                                   aBottom, aTop : integer );
begin
  inherited Initialize(aSize, aMeasure, pkHorizontal);
  fBottom := aBottom;
  fTop    := aTop;
end;

procedure TCAPPIScan.Render( aData : TRadarData; aChannel : integer );
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
      with Area do
        fMtx := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
      StartNotify(Movements);
      try
        ProcessChannel(aChannel, Measure, ProcessMove);
        Average(fMtx, Measure);
      finally
        FreeAndNil(fMtx);
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TCAPPIScan.ProcessMove( S : TScan );
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
                    fMtx[Radius, A] := fMtx[Radius, A] + CodeLineal(Cell[R, A], Measure);
                    Self[Radius, A] := Self[Radius, A] + 1;
                  end;
            end;
        end;
  DoNotify;
end;

procedure TCAPPIScan.ReadState( Reader : TReader );
begin
  inherited;
  fTop    := Reader.ReadInteger;
  fBottom := Reader.ReadInteger;
end;

procedure TCAPPIScan.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(Top);
  Writer.WriteInteger(Bottom);
end;

initialization
  Classes.RegisterClass(TCAPPIScan);
end.

