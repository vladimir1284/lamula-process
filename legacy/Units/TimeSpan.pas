unit TimeSpan;

interface

uses
  Classes,
  DataSource, RadarData,
  Observation,
  Description, Plane, Translator;

const
  TimeSpanExt    = '.tms';
  TimeSpanFilter = 'Periodos|*' + TimeSpanExt;

type
  TTimeSpan = class;

  TTimeSpan = class(TRadarData)
  public
    class function Load( const FileName : string ) : TTimeSpan;
  protected
    constructor LoadTimeSpan( const FileName : string );
  public
    constructor Create;
    destructor  Destroy;  override;
    procedure   Save( const aFileName : string );
  public
    fObservations : TList;
    procedure Insert  ( O : TObservation );
    procedure Remove  ( O : TObservation );
    procedure Delete  ( I : integer      );
    procedure AddFile ( S : string       );
    procedure AddFiles( S : TStrings     );
  private
    function GetFirstTime : TDateTime;
    function GetLastTime  : TDateTime;
    function GetTimeGap   : TDateTime;
    function GetObservation( I : integer ) : TObservation;
  protected
    function  GetSystem : string;                           override;
    function  GetSources : integer;                         override;
    function  GetSource ( I : integer ) : TDataSource;      override;
    procedure SetChannel( I : integer; V : TChannelDesc );  override;
    procedure SetDelta  ( I : integer; V : single );        override;
  public
    property FirstTime    : TDateTime read GetFirstTime;
    property LastTime     : TDateTime read GetLastTime;
    property TimeGap      : TDateTime read GetTimeGap;
    property Observations : integer   read GetSources;
  public
    property Observation[I : integer] : TObservation read GetObservation;  default;
  end;

implementation

uses
  SysUtils;

// Private procedures & functions

function CompareObservationTime( P1, P2 : pointer ) : integer;
begin
  if TObservation(P1).Time < TObservation(P2).Time
    then Result := -1
    else
      if TObservation(P1).Time = TObservation(P2).Time
        then Result := 0
        else Result := 1;
end;

function ChannelsEqual( const Ch1, Ch2 : TChannelDesc ) : boolean;
begin
  Result := (Ch1.Wave    = Ch2.Wave   ) and
            (Ch1.Pulse   = Ch2.Pulse  ) and
            (Ch1.Cells   = Ch2.Cells  ) and
            (Ch1.Length  = Ch2.Length ) and
            (Ch1.Sectors = Ch2.Sectors) and
            (Ch1.Beam    = Ch2.Beam   );
end;

// TTimeSpan methods

class function TTimeSpan.Load( const FileName : string ) : TTimeSpan;
begin
  Result := TTimeSpan.LoadTimeSpan(FileName);
end;

constructor TTimeSpan.LoadTimeSpan( const FileName : string );
var
  F : TextFile;
  D, S : string;
begin
  Create;
  AssignFile(F, FileName);
  reset(F);
  try
    D := ExtractFileDir(FileName);
    while not eof(F) do
      begin
        readln(F, S);
        SetCurrentDir(D);
        Insert(TObservation.Load(S));
      end;
    Time := FirstTime;
  finally
    close(F);
  end;
end;

constructor TTimeSpan.Create;
begin
  inherited;
  fObservations := TList.Create;
end;

destructor TTimeSpan.Destroy;
var
  I : integer;
begin
  for I := fObservations.Count - 1 downto 0 do
    TObservation(fObservations[I]).Release;
  FreeAndNil(fObservations);
  inherited;
end;

procedure TTimeSpan.Save( const aFileName : string );
var
  F : TextFile;
  I : integer;
  N : string;
begin
  AssignFile(F, aFileName);
  rewrite(F);
  try
    for I := 0 to fObservations.Count - 1 do
      begin
        N := TObservation(fObservations[I]).FileName;
        N := ExtractRelativePath(aFileName, N);
        writeln(F, N);
      end;
  finally
    close(F);
  end;
end;

procedure TTimeSpan.Insert( O : TObservation );
var
  I : integer;
begin
  if fObservations.Count = 0
    then
      begin
        Radar    := O.Radar;
        Channels := O.Channels;
        for I := 0 to Channels - 1 do
          Channel[I] := O.Channel[I];
        fObservations.Add(O);
      end
    else
      if (fObservations.IndexOf(O) = -1) and
         (O.Radar = Radar) and (O.Channels = Channels)
        then
          begin
            for I := 0 to Channels - 1 do
              if not ChannelsEqual(Channel[I], O.Channel[I])
                then exit;
            I := 0;
            while (I < fObservations.Count) and
                  (O.Time >= TObservation(fObservations[I]).Time) do
              inc(I);
            fObservations.Insert(I, O);
          end;
end;

procedure TTimeSpan.Remove( O : TObservation );
begin
  fObservations.Remove(O);
end;

procedure TTimeSpan.Delete( I : integer );
begin
  fObservations.Delete(I);
  fObservations.Pack;
end;

procedure TTimeSpan.AddFile( S : string );
begin
  Insert(TObservation.Load(S));
end;

procedure TTimeSpan.AddFiles( S : TStrings );
var
  I : integer;
begin
  for I := 0 to S.Count - 1 do
    AddFile(S[I]);
end;

function TTimeSpan.GetFirstTime : TDateTime;
begin
  Result := TObservation(fObservations[0]).Time;
end;

function TTimeSpan.GetLastTime : TDateTime;
begin
  Result := TObservation(fObservations[pred(fObservations.Count)]).Time;
end;

function TTimeSpan.GetTimeGap : TDateTime;
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

function TTimeSpan.GetSystem : string;
begin
  if fObservations.Count > 0
    then Result := TObservation(fObservations[0]).Translator.Name
    else Result := '';
end;

function TTimeSpan.GetSources : integer;
begin
  Result := fObservations.Count;
end;

function TTimeSpan.GetSource( I : integer ) : TDataSource;
begin
  Result := GetObservation(I);
end;

function TTimeSpan.GetObservation( I : integer ) : TObservation;
begin
  Result := TObservation(fObservations[I]);
end;

procedure TTimeSpan.SetChannel( I : integer; V : TChannelDesc );
begin
  V.PotMet := POTMET_NA;
  inherited SetChannel(I, V);
end;

procedure TTimeSpan.SetDelta( I : integer; V : single );
var
  O : integer;
begin
  inherited SetDelta(I, V);
  for O := 0 to fObservations.Count - 1 do
    Observation[O].Delta[I] := V;
end;

end.
