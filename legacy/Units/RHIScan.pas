unit RHIScan;

interface

uses
  Classes,
  Scan, Plane, Angle, Description, Movement, Measure,
  RadarScan, RadarData, Observation,
  FloatMatrix;

type
  TRHIScan = class;

  TRHIScan = class(TRadarScan)
  public
    constructor Initialize( aCells, aSectors : integer; aMeasure : TMeasure;
                            anAzimut : TAngle; aBeam : single;
                            aStart, aFinish : TAngle );
    constructor RenderMove( aMove : TVertMove; aMeasure : TMeasure );
  private
    fStart   : TAngle;
    fFinish  : TAngle;
    fSectors : integer;
  public
    property Start   : TAngle  read fStart;
    property Finish  : TAngle  read fFinish;
    property Sectors : integer read fSectors;
  public
    procedure Render( aData : TRadarData; aChannel : integer );  override;
  private
    fIndex : integer;
    fMtx   : TFloatMatrix;
    procedure ProcessMove( S : TScan );
  end;

implementation

uses
  SysUtils, Math,
  Notify, PPIScan;

// TRHIScan methods

constructor TRHIScan.Initialize( aCells, aSectors : integer; aMeasure : TMeasure;
                                 anAzimut : TAngle; aBeam : single;
                                 aStart, aFinish : TAngle );
var
  Angles : integer;
begin
  Angles := Distance(aFinish, aStart) * aSectors div Codes;
  inherited Initialize(PlanePoint(aCells, Angles), aMeasure, pkVertical, anAzimut, aBeam);
  fStart   := aStart;
  fFinish  := aFinish;
  fSectors := aSectors;
  Area := PlaneArea(Origin.R, Start  * Sectors div Codes,
                    Ending.R, Finish * Sectors div Codes);
  Clear;
end;

constructor TRHIScan.RenderMove( aMove : TVertMove; aMeasure : TMeasure );
begin
  inherited InitConvert(aMove, aMeasure);
  fStart   := aMove.Start;
  fFinish  := aMove.Finish;
  fSectors := aMove.Channel.Sectors;
end;

procedure TRHIScan.Render( aData : TRadarData; aChannel : integer );
begin
  with aData as TObservation do
    begin
      with Channel[aChannel] do
        begin
          Self.Length := Length;
          fIndex := (Angle * Sectors) div Codes;
        end;
      with Area do
        fMtx := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
      StartNotify(Movements);
      try
        ProcessChannel(aChannel, Measure, ProcessMove);
        Average(fMtx, Measure);
      finally
        FreeAndNil(fMtx);
        EndNotify;
      end;
    end;
end;

procedure TRHIScan.ProcessMove( S : TScan );
var
  SR   : TRay;
  CR   : TRay;
  MR   : TFloatRow;
  R, A : integer;
begin
  MR := nil;
  if S is TPPIScan
    then
      with S as TPPIScan do
        begin
          A  := Distance(Angle, Start) * Sectors div Codes;
          CR := Self.Ray[A];
          MR := fMtx.Row[A];
          SR := Ray[fIndex];
          for R := 0 to Min(Self.Radiuses, Radiuses) - 1 do
            if SR[R] <> NODATA then
              begin
                MR[R] := MR[R] + CodeLineal(SR[R], Measure);
                inc(CR[R]);
              end;
        end;
end;

initialization
  Classes.RegisterClass(TRHIScan);
end.

