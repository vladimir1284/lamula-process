unit PPIScan;

interface

uses
  Classes,
  Scan, Plane, Angle, Description, Movement, Measure,
  RadarScan, RadarData, Observation;

type
  TPPIScan = class;

  TPPIScan = class(TRadarScan)
  public
    constructor Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                            anElevation : TAngle; aBeam : single );
    constructor RenderMove( aMove : THorzMove; aMeasure : TMeasure );
  public
    procedure Render( aData : TRadarData; aChannel : integer );  override;
  end;

implementation

uses
  SysUtils,
  RadarPlane;

// TPPIScan methods

constructor TPPIScan.Initialize( aSize : TPlanePoint; aMeasure : TMeasure;
                                 anElevation : TAngle; aBeam : single );
begin
  inherited Initialize(aSize, aMeasure, pkHorizontal, anElevation, aBeam);
end;

constructor TPPIScan.RenderMove( aMove : THorzMove; aMeasure : TMeasure );
begin
  inherited InitConvert(aMove, aMeasure);
end;

procedure TPPIScan.Render( aData : TRadarData; aChannel : integer );
var
  Move, Best : integer;
  Dist, Min  : integer;
  M          : TMovement;
begin
  with aData as TObservation do
    begin
      Self.Radar := Radar;
      Self.Time := Time;
      Self.Length := Channel[aChannel].Length;
      Best := -1;
      Min  := MaxInt;
      for Move := 0 to Movements - 1 do
        with MoveDesc[Move] do
          if (Channel = aChannel) and
             (Kind = pkHorizontal) and
             SameMeasureSet(Self.Measure, Measure)
            then
              begin
                Dist := abs(Distance(Angle, Self.Angle));
                if Dist < Min
                  then
                    begin
                      Min := Dist;
                      Best := Move;
                    end;
              end;
      if Best >= 0
        then
          begin
            M := Movement[Best];
            if M.Radiuses > Radiuses
              then M.Radiuses := Radiuses;
            try
              Convert(M)
            finally
              M.Free;
            end;
          end
        else raise Exception.Create('No se realizo PPI con los parametros especificados');
    end;
end;

initialization
  Classes.RegisterClass( TPPIScan );
end.

