unit RadarVector;

interface

uses
  Classes,
  Vector, Description;

type
  TRadarVector = class(TVector)
  public
    procedure Assign( Source : TPersistent );  override;
  private
    fRadar  : TRadar;
    fTime   : TDateTime;
    fLength : integer;
  public
    property Radar  : TRadar    read fRadar  write fRadar;
    property Time   : TDateTime read fTime   write fTime;
    property Length : integer   read fLength write fLength;
  public
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  end;

implementation

// TRadarVector methods

procedure TRadarVector.Assign( Source : TPersistent );
begin
  if Source is TRadarVector
    then
      begin
        fRadar  := TRadarVector(Source).Radar;
        fTime   := TRadarVector(Source).Time;
        fLength := TRadarVector(Source).Length;
      end;
  inherited Assign(Source);
end;

procedure TRadarVector.ReadState( Reader : TReader );
begin
  inherited;
  Radar  := TRadar(Reader.ReadInteger);
  Time   := Reader.ReadFloat;
  Length := Reader.ReadInteger;
end;

procedure TRadarVector.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(ord(Radar));
  Writer.WriteFloat(Time);
  Writer.WriteInteger(Length);
end;

initialization
  Classes.RegisterClass(TRadarVector);
end.
