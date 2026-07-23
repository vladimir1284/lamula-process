unit ObservationAuto;

interface

{$WARN UNIT_DEPRECATED OFF}

uses
  Forms,
  OleAuto,
  Variants,
  FormAuto,
  Description, Angle, Observation;

type
  TObservationAuto = class;
  TExplorationAuto = class;

  TObservationAuto = class(TFormAuto)
  automated
    function GetRadar        : integer;
    function GetTime         : TDateTime;
    function GetExplorations : integer;
    function GetChannels     : integer;
    function GetExploration(       I : integer ) : variant;
    function GetProduct    ( const S : string  ) : variant;
    function GetChannel    (       I : integer ) : variant;
    function GetScan       (       I : integer ) : variant;
  automated
    procedure Load( const FileName : string );
    procedure Save( const FileName : string );
  automated
    property Radar        : integer   read GetRadar;
    property Time         : TDateTime read GetTime;
    property Explorations : integer   read GetExplorations;
    property Channels     : integer   read GetChannels;
    property Exploration[      I : integer] : variant read GetExploration;
    property Product    [const S : string ] : variant read GetProduct;
    property Channel    [      I : integer] : variant read GetChannel;
    property Scan       [      I : integer] : variant read GetScan;
  protected
    class function FormClass : TFormClass;  override;
  end;

  TExplorationAuto = class(TAutoObject)
  automated
    function GetKind   : integer;
    function GetAngle  : integer;
    function GetStart  : integer;
    function GetFinish : integer;
  automated
    property Kind   : integer read GetKind;
    property Angle  : integer read GetAngle;
    property Start  : integer read GetStart;
    property Finish : integer read GetFinish;
  private
    fMove : TMovementDesc;
  end;

implementation

uses
  Notify,
  Product, ChannelAuto,
  Measure, Scan,
  Shell_Process, ObservationForm;

// TObservationAuto methods

function TObservationAuto.GetRadar : integer;
begin
  Result := ord(TFObservation(Form).Observation.Radar);
end;

function TObservationAuto.GetTime : TDateTime;
begin
  Result := TFObservation(Form).Observation.Time;
end;

function TObservationAuto.GetExplorations : integer;
begin
  Result := TFObservation(Form).Observation.Movements;
end;

function TObservationAuto.GetChannels : integer;
begin
  Result := TFObservation(Form).Observation.Channels;
end;

function TObservationAuto.GetExploration( I : integer ) : variant;
var
  ExplorationAuto : TExplorationAuto;
begin
  ExplorationAuto := TExplorationAuto.Create;
  ExplorationAuto.fMove := TFObservation(Form).Observation.MoveDesc[I];
  Result := ExplorationAuto.OleObject;
end;

function TObservationAuto.GetProduct( const S : string ) : variant;
var
  P : TProduct;
begin
  P := TFObservation(Form).GetProduct( S );
  if assigned(P)
    then Result := P.OleObject
    else Result := null;
end;

function TObservationAuto.GetChannel( I : integer ) : variant;
var
  ChannelAuto : TChannelAuto;
begin
  ChannelAuto := TChannelAuto.Create;
  ChannelAuto.RadarData := TFObservation(Form).Observation;
  ChannelAuto.Index     := I;
  Result := ChannelAuto.OleObject;
end;

function TObservationAuto.GetScan( I : integer ) : variant;
var
  ScanAuto : TScanAuto;
begin
  ScanAuto := TScanAuto.Initialize(TFObservation(Form).Observation.GetScan(I, unDBZ));
  Result := ScanAuto.OleObject;
end;

procedure TObservationAuto.Load( const FileName : string );
begin
  TFObservation(Form).Observation := TObservation.Load( FileName );
end;

procedure TObservationAuto.Save( const FileName : string );
begin
  TFObservation(Form).SaveObservation( FileName );
end;

class function TObservationAuto.FormClass : TFormClass;
begin
  Result := TFObservation;
end;

// TExplorationAuto methods

function TExplorationAuto.GetKind : integer;
begin
  Result := ord(fMove.Kind);
end;

function TExplorationAuto.GetAngle : integer;
begin
  Result := fMove.Angle;
end;

function TExplorationAuto.GetStart : integer;
begin
  Result := fMove.Start;
end;

function TExplorationAuto.GetFinish : integer;
begin
  Result := fMove.Finish;
end;

end.
