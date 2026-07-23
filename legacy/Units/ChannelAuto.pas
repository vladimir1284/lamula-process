unit ChannelAuto;

interface

{$WARN UNIT_DEPRECATED OFF}

uses
  OleAuto,
  Description, RadarData;

type
  TChannelAuto = class;
    
  TChannelAuto = class(TAutoObject)
  automated
    function  GetWave   : integer;
    function  GetPulse  : integer;
    function  GetCells  : integer;
    function  GetLength : integer;
    function  GetBeam   : single;
    function  GetPotMet : single;
    function  GetDelta  : single;
    procedure SetDelta ( D : single );
    function  GetSectors : integer;
  automated
    property Wave    : integer read GetWave;
    property Pulse   : integer read GetPulse;
    property Cells   : integer read GetCells;
    property Length  : integer read GetLength;
    property Beam    : single  read GetBeam;
    property PotMet  : single  read GetPotMet;
    property Delta   : single  read GetDelta  write SetDelta;
    property Sectors : integer read GetSectors;
  private
    fRadarData : TRadarData;
    fIndex     : integer;
  public
    property RadarData : TRadarData read fRadarData write fRadarData;
    property Index     : integer    read fIndex     write fIndex;
  end;

implementation

// TChannelAuto methods

function TChannelAuto.GetWave : integer;
begin
  Result := ord(RadarData.Channel[Index].Wave);
end;

function TChannelAuto.GetPulse : integer;
begin
  Result := ord(RadarData.Channel[Index].Pulse);
end;

function TChannelAuto.GetCells : integer;
begin
  Result := RadarData.Channel[Index].Cells;
end;

function TChannelAuto.GetLength : integer;
begin
  Result := RadarData.Channel[Index].Length;
end;

function TChannelAuto.GetBeam : single;
begin
  Result := RadarData.Channel[Index].Beam;
end;

function TChannelAuto.GetPotMet : single;
begin
  Result := RadarData.Channel[Index].PotMet;
end;

function TChannelAuto.GetDelta : single;
begin
  Result := RadarData.Delta[Index];
end;

procedure TChannelAuto.SetDelta( D : single );
begin
  RadarData.Delta[Index] := D;
end;

function TChannelAuto.GetSectors: integer;
begin
  Result := RadarData.Channel[Index].Sectors;
end;

end.
