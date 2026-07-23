unit Ensemble;

interface

uses
  Classes,
  DataSource, Observation, Description;

const
  EnsembleExt    = '.ens';
  EnsembleFilter = 'Conjuntos|*' + EnsembleExt;

type
  TEnsemble = class;

  TEnsemble = class(TDataSource)
  public
    class function Load( const FileName : string ) : TEnsemble;
  protected
    constructor LoadEnsemble( const FileName : string );
  public
    constructor Create;
    destructor  Destroy;  override;
    procedure   Save( const aFileName : string );
  public
    function Contains( Radar : TRadar ) : boolean;  override;
  public
    procedure Insert  ( O : TObservation );
    procedure Remove  ( O : TObservation );
    procedure Delete  ( I : integer      );
    procedure AddFile ( S : string       );
    procedure AddFiles( S : TStrings     );
  private
    fRadarCount   : integer;
    fRadars       : TRadarSet;
    fObservations : TList;
    fStepTime     : TDateTime;
    function  GetFirstTime    : TDateTime;
    function  GetLastTime     : TDateTime;
    function  GetTimeGap      : TDateTime;
    function  GetSteps        : integer;
    function  GetObservation( I : integer ) : TObservation;
    function  GetStep       ( I : integer ) : integer;
    procedure UpdateRadars;
  protected
    function GetSystem : string;                      override;
    function GetSources : integer;                    override;
    function GetSource( I : integer ) : TDataSource;  override;
  public
    property FirstTime    : TDateTime read GetFirstTime;
    property LastTime     : TDateTime read GetLastTime;
    property TimeGap      : TDateTime read GetTimeGap;
    property RadarCount   : integer   read fRadarCount;
    property Radars       : TRadarSet read fRadars;
    property Observations : integer   read GetSources;
    property StepTime     : TDateTime read fStepTime write fStepTime;
    property Steps        : integer   read GetSteps;
  public
    property Observation[I : integer] : TObservation read GetObservation;  default;
    property Step       [I : integer] : integer      read GetStep;
  end;

implementation

uses
  SysUtils;

// TEnsemble methods

class function TEnsemble.Load( const FileName : string ) : TEnsemble;
begin
  Result := TEnsemble.LoadEnsemble( FileName );
end;

constructor TEnsemble.LoadEnsemble( const FileName : string );
var
  F : TextFile;
  S : string;
  HH, MM, SS : word;
begin
  Create;
  AssignFile( F, FileName );
  reset( F );
  try
    readln( F, HH, MM, SS );
    fStepTime := EncodeTime( HH, MM, SS, 0 );
    while not eof(F) do
      begin
        readln( F, S );
        Insert( TObservation.Load( S ) );
      end;
  finally
    close( F );
  end;
end;

constructor TEnsemble.Create;
begin
  inherited;
  fObservations := TList.Create;
  fStepTime     := anHour;
end;

destructor TEnsemble.Destroy;
var
  I : integer;
begin
  for I := fObservations.Count - 1 downto 0 do
    TObservation(fObservations[I]).Release;
  FreeAndNil(fObservations);
  inherited;
end;

procedure TEnsemble.Save( const aFileName : string );
var
  F : TextFile;
  I : integer;
  HH, MM, SS, DD : word;
begin
  AssignFile( F, aFileName );
  rewrite( F );
  try
    DecodeTime( fStepTime, HH, MM, SS, DD );
    writeln( F, HH:3, MM:3, SS:3 );
    for I := 0 to fObservations.Count - 1 do
      writeln( F, TObservation(fObservations[I]).FileName );
  finally
    close( F );
  end;
end;

function TEnsemble.Contains( Radar : TRadar ) : boolean;
begin
  Result := Radar in Self.Radars;
end;

procedure TEnsemble.Insert( O : TObservation );
var
  I : integer;
begin
  I := 0;
  while (I < fObservations.Count) and
        (O.Time >= TObservation(fObservations[I]).Time) do
    inc( I );
  fObservations.Insert( I, O );
  UpdateRadars;
end;

procedure TEnsemble.Remove( O : TObservation );
begin
  fObservations.Remove( O );
  UpdateRadars;
end;

procedure TEnsemble.Delete( I : integer );
begin
  fObservations.Delete( I );
  fObservations.Pack;
  UpdateRadars;
end;

procedure TEnsemble.AddFile( S : string );
begin
  Insert( TObservation.Load( S ) );
end;

procedure TEnsemble.AddFiles( S : TStrings );
var
  I : integer;
begin
  for I := 0 to S.Count - 1 do
    AddFile( S[I] );
end;

function TEnsemble.GetFirstTime : TDateTime;
begin
  Result := TObservation(fObservations[0]).Time;
end;

function TEnsemble.GetLastTime : TDateTime;
begin
  Result := TObservation(fObservations[pred(fObservations.Count)]).Time;
end;

function TEnsemble.GetTimeGap : TDateTime;
var
  I : integer;
  D : TDateTime;
begin
  Result := 0;
  for I := 1 to fObservations.Count - 1 do
    begin
      D := TObservation(fObservations[I]).Time -
           TObservation(fObservations[I - 1]).Time;
      if D > Result
        then Result := D;
    end;
end;

function TEnsemble.GetSources : integer;
begin
  Result := fObservations.Count;
end;

function TEnsemble.GetSource( I : integer ) : TDataSource;
begin
  Result := GetObservation( I );
end;

function TEnsemble.GetSteps : integer;
begin
  Result := trunc((LastTime - FirstTime) / fStepTime);
end;

function TEnsemble.GetObservation( I : integer ) : TObservation;
begin
  Result := TObservation(fObservations[I]);
end;

function TEnsemble.GetStep( I : integer ) : integer;
begin
  Result := trunc((Observation[I].Time - FirstTime) / fStepTime);
end;
  
procedure TEnsemble.UpdateRadars;
var
  I : integer;
begin
  fRadars     := [];
  fRadarCount := 0;
  for I := 0 to fObservations.Count - 1 do
    with TObservation(fObservations[I]) do
      if not (Radar in fRadars)
        then
          begin
            include( fRadars, Radar );
            inc( fRadarCount );
          end;
end;

function TEnsemble.GetSystem : string;
var
  I : integer;
begin
  with TStringList.Create do
    try
      Sorted     := true;
      Duplicates := dupIgnore;
      for I := 0 to fObservations.Count - 1 do
        Add( TObservation(fObservations[I]).Translator.Name );
      if Count > 0
        then
          begin
            Result := Strings[0];
            for I := 1 to Count - 1 do
              Result := Result + ', ' + Strings[I];
          end
        else Result := '';
    finally
      Free;
    end;
end;

end.
