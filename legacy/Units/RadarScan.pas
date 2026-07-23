unit RadarScan;

interface

uses
  Classes,
  Scan, Plane, Measure, Angle, Movement;

type
  TRadarScan = class(TScan)
  public
    constructor Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                            aKind : TPlaneKind;
                            anAngle : TAngle; aBeam : single );
    constructor InitConvert( aMove : TMovement; aMeasure : TMeasure );
  public
    procedure Assign ( Source : TPersistent );  override;
  private
    fBeam  : single;
  public
    property Beam : single read fBeam;
  public
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  end;

implementation

{ TRadarScan }

constructor TRadarScan.Initialize(aSize: TPlanePoint; aMeasure: TMeasure;
  aKind: TPlaneKind; anAngle: TAngle; aBeam: single);
begin
  inherited Initialize(aSize, aMeasure, aKind);
  fAngle := anAngle;
  fBeam  := aBeam;
end;

constructor TRadarScan.InitConvert(aMove: TMovement; aMeasure: TMeasure);
begin
  inherited InitConvert(aMove, aMeasure);
  fAngle := aMove.Angle;
  fBeam  := aMove.Channel.Beam;
end;

procedure TRadarScan.ReadState(Reader: TReader);
begin
  inherited;
  with Reader do
    begin
      fAngle := TAngle(ReadInteger);
      fBeam  := ReadFloat;
    end;
end;

procedure TRadarScan.WriteState(Writer: TWriter);
begin
  inherited;
  with Writer do
    begin
      WriteInteger(longint(Angle));
      WriteFloat(Beam);
    end;
end;

procedure TRadarScan.Assign(Source: TPersistent);
begin
  if Source is TRadarScan
    then fBeam := (Source as TRadarScan).Beam;
  inherited;
end;

end.

