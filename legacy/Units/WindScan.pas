unit WindScan;

interface

uses
  Classes,
  Scan, Plane, Description, Measure, HeightTable,
  RadarData, Observation,
  FloatMatrix,
  Angle;

type
  TVector = array[0..1] of byte;

  TWindScan = class(TScan)
  public
    constructor Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                            aHeight : integer);
    destructor Destroy;  override;
  public
    procedure Render( aData : TRadarData; aChannel : integer );  override;
  private
    fHeight : integer;
  protected
    fHeightTable : THeightTable;
    fAltitude    : integer;
    procedure ProcessMove( S : TScan );  virtual;
  protected
  public
    fAlpha: TScan;
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  end;

implementation

uses
  SysUtils,
  RadarPlane,
  PPIScan, Movement, Notify,
  Radars;

// TWindScan methods

constructor TWindScan.Initialize;
begin
  inherited Initialize(aSize, aMeasure, pkHorizontal);
  fHeight := aHeight;
  fAlpha := TScan.Initialize(Area, nil, Measure);
end;

destructor TWindScan.Destroy;
begin
  fAlpha.Free;
  inherited;
end;

procedure TWindScan.Render( aData : TRadarData; aChannel : integer );
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
        ProcessChannel(aChannel, unMS, ProcessMove);
      finally
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TWindScan.ProcessMove( S : TScan );
var
  R, A, V, C: integer;
  Radius : longint;
  Cosine : double;
  HRay   : THeightRay;
  Vel: TVector;
begin
  if S is TPPIScan
    then
      with S as TPPIScan do
        begin
{          Cosine := cos(DegreeToRadian * CodeAngle(Angle));
          HRay   := fHeightTable.Ray[Angle];}
          for R := Self.Origin.R to Self.Ending.R do
            begin
{              if HRay[R].Max < fHeight
                then continue;
              if HRay[R].Min > fHeight
                then break;
              Radius := round(R * Cosine);}
              A := Self.Origin.A;
              repeat
                if (Cell[R, A] > 0) and (Cell[R, A + 1] > 0) and
                   (Cell[R, A] <> NODATA) and (Cell[R, A + 1] <> NODATA) then
                  begin
//                    Vel := VelVector(CodeLineal(Cell[R, A], unMS), CodeLineal(Cell[R, A + 1], unMS),
//                                     360/Self.Ending.A*A, 360/Self.Ending.A*(A + 1), CodeAngle(Angle));
//                    V := Self[R, A];
                    if (V < Vel[0]) or (V = NODATA) then
                      begin
                        Self  [R, A    ] := Vel[0];
                        Self  [R, A + 1] := Vel[0];
                        fAlpha[R, A    ] := Vel[1];
                        fAlpha[R, A + 1] := Vel[1];
                      end;
                  end;
                Inc(A, 2);
              until A >= Self.Ending.A;
           end;
        end;
end;

procedure TWindScan.ReadState( Reader : TReader );
begin
  inherited;
  fHeight := Reader.ReadInteger;
end;

procedure TWindScan.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(Height);
end;


initialization
  Classes.RegisterClass(TWindScan);
end.

