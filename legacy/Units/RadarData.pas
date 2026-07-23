unit RadarData;

interface

uses
  Classes,
  DataSource, Plane, Movement, Description;

type
  CRadarData = class of TRadarData;
  TRadarData = class(TDataSource)
  public
    function Contains( Radar : TRadar ) : boolean;  override;
  private
    fRadar       : TRadar;
    fTime        : TDateTime;
    fChannels    : integer;
    fChannelDesc : TChannelDescArray;
    procedure SetChannels( V : integer );
    function  GetChannel ( I : integer ) : TChannelDesc;
    function  GetDelta   ( I : integer ) : single;
  protected
    procedure SetChannel ( I : integer; V : TChannelDesc );  virtual;
    procedure SetDelta   ( I : integer; V : single );        virtual;
  public
    property Radar    : TRadar    read fRadar    write fRadar;
    property Time     : TDateTime read fTime     write fTime;
    property Channels : integer   read fChannels write SetChannels;
  public
    property Channel[I : integer] : TChannelDesc read GetChannel write SetChannel;
    property Delta  [I : integer] : single       read GetDelta   write SetDelta;
 end;

implementation

uses
  Settings;

// TRadarData methods

function TRadarData.Contains( Radar : TRadar ) : boolean;
begin
  Result := Radar = Self.fRadar;
end;

procedure TRadarData.SetChannels( V : integer );
begin
  fChannels := V;
  SetLength(fChannelDesc, fChannels);
end;

function TRadarData.GetChannel( I : integer ) : TChannelDesc;
begin
  Result := fChannelDesc[I];
end;

function TRadarData.GetDelta( I : integer ) : single;
begin
  Result := fChannelDesc[I].Delta;
end;

procedure TRadarData.SetChannel( I : integer; V : TChannelDesc );
//var
//  MaxCells : integer;
begin
//  MaxCells := round(theSettings.DefaultMaxRange * V.Length/1000);
  fChannelDesc[I] := V;
//  if V.Cells > MaxCells
//    then fChannelDesc[I].Cells := MaxCells;
end;

procedure TRadarData.SetDelta( I : integer; V : single );
begin
  fChannelDesc[I].Delta := V;
end;

end.

