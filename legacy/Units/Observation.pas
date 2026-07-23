unit Observation;

interface

uses
  Forms, Classes, SysUtils, Dialogs,
  DataSource, RadarData,
  Scan, Movement, Translator, Description, Plane, Measure, Angle, Scale, Scales,
  Nexrad_Translator, TranslatorPercentForm;

const
  ADay    = 1;
  AnHour  = ADay/24;
  AMinute = AnHour/60;

type
  TScanProc = procedure ( S : TScan ) of object;

type
  TObservation = class(TRadarData)
  public
    class function Load( const FileName : string ) : TObservation;
  protected
    constructor LoadObservation( const FileName : string );
  public
    destructor Destroy;  override;
    procedure  Save( const aFileName : string );
    procedure  UpdateTranslator;
  private
    fDesign    : string;
    fMovements : integer;
    fMoveDesc  : TMoveDescArray;
    function  GetMovement ( I : integer ) : TMovement;
    function  GetFileName : string;
    procedure SetMovements( V : integer );
    function  GetMoveDesc ( I : integer ) : TMovementDesc;
    procedure SetMoveDesc ( I : integer; V : TMovementDesc );
    function  Supress     ( I : integer; M: TMovement ): TMovement;
    procedure Sup( p1 : PCellArray; p : PCellArray; count : integer);
    procedure RemoveRadialSpeckler( M: TMovement );
  protected
    procedure SetDelta   ( I : integer; V : single );  override;
  protected
    function  GetSystem : string;                      override;
    function  GetSources : integer;                    override;
    function  GetSource( I : integer ) : TDataSource;  override;
  public
    property Design    : string  read fDesign;
    property Movements : integer read fMovements write SetMovements;
    property FileName  : string  read GetFileName;
    property Movement[I : integer] : TMovement     read GetMovement;  default;
    property MoveDesc[I : integer] : TMovementDesc read GetMoveDesc write SetMoveDesc;
  private
//    fReferences : integer;
  public
//    property References : integer     read fReferences;
    fTranslator : TTranslator;
    property Translator : TTranslator read fTranslator write fTranslator;
  public
    function PPIAngles : TList;
    function PPIAnglesOf(aMeasure: TMeasure): TList;
    function RHIAngles : TList;
  public
    function  GetScan       ( I : integer; aMeasure : TMeasure ) : TScan;
    procedure ProcessKind   ( aKind    : TPlaneKind; aMeasure : TMeasure; Process : TScanProc );
    procedure ProcessChannel( aChannel : integer; aMeasure : TMeasure; Process : TScanProc );
    function  HighestAngle  ( aChannel : integer ) : TAngle;
  end;

type
  ECanNotFindTranslator = class(Exception);

function ObservationExts   : TStrings;
function ObservationFilter : string;

implementation

uses
  Configuration,
  Settings,
  PRTable,
  PPIScan, RHIScan,
  Translators,
  SupressStatus;

var
  theObservations : TList = nil;

// TObservation methods

class function TObservation.Load( const FileName : string ) : TObservation;
var
  I : integer;
begin
  I := 0;
  while (I < theObservations.Count) and
        (CompareText(TObservation(theObservations[I]).FileName, FileName) <> 0) do
    inc(I);
  if I < theObservations.Count
    then
      begin
        Result := TObservation(theObservations[I]);
        Result.AddRef;
      end
    else
      begin
        Result := TObservation.LoadObservation(FileName);
        theObservations.Add(Result);
      end;
end;

constructor TObservation.LoadObservation( const FileName : string );
begin
  inherited Create;
  fTranslator := Translators.Find(FileName);
  if assigned(fTranslator)
    then
      begin
        fTranslator.OnProgress := FTranslatorPercent.TranslatorProgress;
        fTranslator.Open(FileName);
        UpdateTranslator;
      end
    else raise ECanNotFindTranslator.Create('No hay traductor registrado para el archivo'#13 + FileName);
end;

procedure TObservation.UpdateTranslator;
var
  I : integer;
begin
  Radar     := fTranslator.Radar;
  Time      := fTranslator.DateTime;
  Channels  := fTranslator.Channels;
  Movements := fTranslator.Movements;
  for I := 0 to Channels - 1 do
    Channel[I] := fTranslator.Channel[I];
  for I := 0 to Movements - 1 do
    MoveDesc[I] := fTranslator.MoveDesc[I];
  fDesign   := fTranslator.Design;
end;

destructor TObservation.Destroy;
begin
  theObservations.Remove(Self);
  if Assigned(fTranslator) then
    FreeAndNil(fTranslator);
  inherited;
end;

procedure TObservation.Save( const aFileName : string );
begin
end;

procedure TObservation.SetDelta( I : integer; V : single );
var
  ChDesc : TChannelDesc;
begin
  inherited SetDelta(I, V);
  ChDesc := Translator.Channel[I];
  ChDesc.Delta := V;
  Translator.Channel[I] := ChDesc;
end;

procedure TObservation.SetMovements( V : integer );
begin
  SetLength(fMoveDesc, V);
  fMovements := V;
end;

procedure TObservation.SetMoveDesc( I : integer; V : TMovementDesc );
begin
  fMoveDesc[I] := V;
end;

function TObservation.GetMoveDesc( I : integer ) : TMovementDesc;
begin
  Result := fMoveDesc[I];
end;

function TObservation.GetMovement( I : integer ) : TMovement;
begin
  Result := fTranslator.Movement[I];
  if theSupressStatus then
    Supress(I, Result);
  RemoveRadialSpeckler(Result);
  Result.Delta := Delta[Result.Channel.Index];
end;

function TObservation.GetSystem : string;
begin
  with fTranslator do
    Result := Name + ' [' + Design + ']';
end;

function TObservation.GetSources : integer;
begin
  Result := 1;
end;

function TObservation.GetSource( I : integer ) : TDataSource;
begin
  if I = 0
    then Result := self
    else Result := nil;
end;

function TObservation.GetFileName : string;
begin
  Result := fTranslator.FileName;
end;

function TObservation.PPIAngles : TList;
var
  I : integer;
begin
  Result := TList.Create;
  for I := 0 to Movements - 1 do
    with MoveDesc[I] do
      if Kind = pkHorizontal
        then Result.Add(pointer(Angle));
end;

function TObservation.PPIAnglesOf(aMeasure: TMeasure) : TList;
var
  I : integer;
begin
  Result := TList.Create;
  for I := 0 to Movements - 1 do
    with MoveDesc[I] do
      if (Kind = pkHorizontal) and (Measure = aMeasure)
        then Result.Add(pointer(Angle));
end;

function TObservation.RHIAngles : TList;
var
  I : integer;
begin
  Result := TList.Create;
  for I := 0 to Movements - 1 do
    with MoveDesc[I] do
    if Kind = pkVertical
      then Result.Add(pointer(Angle));
end;

function TObservation.GetScan( I : integer; aMeasure : TMeasure ) : TScan;
var
  S : TScan;
  M : TMovement;
begin
  if I < Movements
    then
      with MoveDesc[I] do
        begin
          S := nil;
          M := Movement[I];
          try
            case Kind of
              pkHorizontal : S := TPPIScan.RenderMove(M as THorzMove, aMeasure);
              pkVertical   : S := TRHIScan.RenderMove(M as TVertMove, aMeasure);
            end;
          finally
            M.Free;
          end;
          Result := S;
        end
    else Result := nil;
end;

procedure TObservation.ProcessKind( aKind : TPlaneKind; aMeasure : TMeasure; Process : TScanProc );
var
  S : TScan;
  I : integer;
begin
  for I := 0 to Movements - 1 do
    with MoveDesc[I] do
      if Kind = aKind
        then
          begin
            S := GetScan(I, aMeasure);
            if assigned(S)
              then
                try
                  Process(S);
                finally
                  S.Free;
                end;
          end;
end;

procedure TObservation.ProcessChannel( aChannel : integer; aMeasure : TMeasure; Process : TScanProc );
var
  S : TScan;
  I : integer;
  t: string;
begin
  for I := 0 to Movements - 1 do
    with MoveDesc[I] do
      if (Channel = aChannel)
        then
          begin
            S := GetScan(I, aMeasure);
            if assigned(S)
              then
                begin
                try
                  Process(S);
                except
                  on E: Exception do
                    begin
                      t := E.ClassName;
                      ShowMessage(t);
                    end;
                end;
                  S.Free;
                end;
          end;
end;

function TObservation.HighestAngle( aChannel : integer ) : TAngle;
var
  I : integer;
  A : TAngle;
begin
  A := Low(TAngle);
  for I := 0 to Movements - 1 do
    with MoveDesc[I] do
      if (Channel = aChannel) and (Kind = pkHorizontal) and
         (Angle >= A)
        then A := Angle;
  Result := A;
end;

// Public procedures & functions

function ObservationExts : TStrings;
begin
  Result := TStringList.Create;
  Translators.Exts(Result);
end;

function ObservationFilter : string;
var
  I : integer;
  L : TStrings;
begin
  L := ObservationExts;
  if L.Count > 0
    then Result := 'Observaciones|' + '*' + L[0];
  for I := 1 to L.Count - 1 do
    Result := Result + ';*' + L[I];
end;

//**************mio*****************
function TObservation.Supress;
var
  TemplateName : string;
  fTemplate :TTranslator;
  Mov: TMovement;
begin
  TemplateName:= ExtractFilePath(Application.Exename) + 'ClutterMap\Template' + fdesign+ '.OBS';
  if FileExists(TemplateName) then
    begin
      fTemplate := Translators.Find(TemplateName);
      fTemplate.Open(TemplateName);
      Mov := fTemplate.Movement[I];
      Sup(Mov.Cells, M.Cells, M.CellCount);
      Mov.Free;
      fTemplate.Free;
    end;
end;

procedure TObservation.Sup( p1 : PCellArray; p : PCellArray; count : integer);///mio******
var
  N: integer;
begin
  for N:=1 to count-1 do
    p^[N-1]:= p^[N-1]* p1^[N-1];
end;

procedure TObservation.RemoveRadialSpeckler( M: TMovement );
var
  a, r, c, i: integer;
  umbral: integer;
  LowValue: TCode;
  S: TScale;
begin
  S := Scales.Find(M.Measure);
  LowValue := S.Value[0];
  umbral := theConfiguration.RadialSpeckler div M.Length;
  if umbral <> 0 then
    for a := M.Origin.A to M.Ending.A do
      begin
        r := M.Origin.R;
        repeat
          if (M.Cell[r, a] <= LowValue) and (M.Cell[r + 1, a] > LowValue) then
            begin
              c := r;
              repeat
                Inc(c);
              until (c >= M.Ending.R) or (c - r >= umbral) or (M.Cell[c, a] <= LowValue);
              if (c - r) < umbral then
                for i := r to c do M.Cell[i, a] := MinCode;
              r := c;
            end
          else
            Inc(r);
        until r >= M.Ending.R;
      end;
  S.Release;
end;

initialization
  theObservations := TList.Create;
finalization
  theObservations.Free;
end.

