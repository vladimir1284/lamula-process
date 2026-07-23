unit Scan;

interface

uses
  Classes, SysUtils,
  Angle,
  RadarPlane, Plane, Movement, Measure, Description,
  RadarData,
  FloatMatrix;

type
  TScan = class(TRadarPlane)
  protected
    constructor Initialize( aSize : TPlanePoint;
                            aMeasure : TMeasure;
                            aKind : TPlaneKind );
    constructor InitConvert( aMove : TMovement;
                             aMeasure : TMeasure );
  public
    procedure Render( Data : TRadarData; Channel : integer );  virtual;  abstract;
  public
    procedure Assign ( Source : TPersistent );  override;
    procedure Convert( Source : TMovement );
  private
    fKind    : TPlaneKind;
    procedure ConvertDB ( PM : integer );
    procedure ConvertDBZ( PM : integer );
    procedure ConvertMMH( PM : integer );
  public
    property Kind    : TPlaneKind read fKind;
  public
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  end;

type
  TScanAuto = class(TRadarPlaneAuto)
  public
    constructor Initialize( aPlane : TScan );
  automated
    function GetKind    : integer;
    function GetMeasure : integer;
  automated
    property Kind    : integer read GetKind;
    property Measure : integer read GetMeasure;
  end;


implementation

uses
  Correction,
  RainTable;

{ TScan methods }

constructor TScan.Initialize( aSize : TPlanePoint;
                              aMeasure : TMeasure;
                              aKind : TPlaneKind );
begin
  inherited Initialize(aSize, nil, aMeasure);
  fKind := aKind;
end;

constructor TScan.InitConvert( aMove : TMovement; aMeasure : TMeasure );
begin
  Measure := aMeasure;
  Convert(aMove);
end;

procedure TScan.Assign( Source : TPersistent );
begin
  if Source is TScan
    then fKind := (Source as TScan).Kind
    else
      if Source is TVertMove
        then fKind := pkVertical
        else fKind := pkHorizontal;
  inherited Assign(Source);
end;

procedure TScan.Convert( Source : TMovement );
var
  theMeasure : TMeasure;
  PM         : integer;
begin
  theMeasure := Measure;
  Assign(Source);
  with Source.Channel do
    PM := round(PotMet + Delta);
  case theMeasure of
    unDB  : ConvertDB (PM);
    unDBZ : ConvertDBZ(PM);
    unMMH : ConvertMMH(PM);
  end;
  if Measure <> theMeasure
    then
      begin
        FillNoData;
        Measure := theMeasure;
      end;
end;

procedure TScan.ConvertDB( PM : integer );
begin
end;

procedure TScan.ConvertDBZ( PM : integer );
var
  A, I : integer;
  SR   : TRay;
begin
  if Measure = unDB
    then
      with Correction.Find(Ending.R, Length) do
        try
          for A := Origin.A to Ending.A do
            begin
              SR := Ray[A];
              for I := 0 to Radiuses - 1 do
                if SR[I] > 0
                  then SR[I] := MeasureCode(CodeMeasure(SR[I], unDB) + Correction[I] + PM, unDBZ);
            end;
          Measure := unDBZ;
        finally
          Free;
        end;
end;

procedure TScan.ConvertMMH( PM : integer );
var
  I, J : integer;
  SR   : TRay;
  Rain : TRain;
begin
  if Measure = unDB
    then ConvertDBZ(PM);
  case Measure of
    unDBZ : Rain := RainTable.Find_ZR;
    unKDP : Rain := RainTable.Find_KDP;
    else    Rain := nil;
  end;
  if assigned(Rain)
    then
      with Rain do
        try
          for J := Origin.A to Ending.A do
            begin
              SR := Ray[J];
              for I := 0 to Radiuses - 1 do
                if SR[I] <> 0
                  then SR[I] := Rain[SR[I]];
            end;
          Measure := unMMH;
        finally
          Free;
        end;
end;

procedure TScan.ReadState( Reader : TReader );
begin
  inherited;
  fKind := TPlaneKind(Reader.ReadInteger);
end;

procedure TScan.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(longint(Kind));
end;

{ TScanAuto }

constructor TScanAuto.Initialize(aPlane: TScan);
begin
  inherited Initialize(aPlane);
end;

function TScanAuto.GetKind: integer;
begin
  Result := ord((Plane as TScan).Kind);
end;

function TScanAuto.GetMeasure: integer;
begin
  Result := ord((Plane as TScan).Measure);
end;

{$IFNDEF MEXOBS}

initialization
  Classes.RegisterClass(TScan);

{$ENDIF}
end.

