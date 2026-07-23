unit Notify;

interface

  type
    TNotify = procedure ( Progress : integer ) of object;

  procedure Create( aNotify : TNotify );
  procedure Destroy;

  procedure Enable;
  procedure Disable;

  procedure Declare( aStops : array of integer );

  procedure StartNotify( aCount : integer );
  procedure EndNotify;

  procedure DoNotify;


implementation

  uses
    Windows;

  type
    PNotifyData = ^TNotifyData;
    TNotifyData = record
      Notify       : TNotify;
      Disabled     : integer;
      Start, Range : integer;
      Increment    : double;
      Progress     : double;
      StopCount    : integer;
      Stops        : array[0..9] of integer;
      CurrentStop  : integer;
    end;

  var
    tlsIndex : integer;


// Private procedures & functions

  function TlsSlot : PNotifyData;
  begin
    Result := TlsGetValue( tlsIndex );
    if Result = nil
      then
        begin
          Result := New( PNotifyData );
          TlsSetValue( tlsIndex, Result );
        end;
  end;


// Public procedures & functions

  procedure Create( aNotify : TNotify );
  begin
    with TlsSlot^ do
      begin
        Notify   := aNotify;
        Disabled := 0;
      end;
  end;

  procedure Destroy;
  begin
    dispose( TlsSlot );
    TlsSetValue( tlsIndex, nil );
  end;

  procedure Enable;
  begin
    with TlsSlot^ do
      if Disabled > 0
        then dec( Disabled );
  end;

  procedure Disable;
  begin
    with TlsSlot^ do
      inc( Disabled );
  end;

  procedure Declare( aStops : array of integer );
  var
    I : integer;
  begin
    with TlsSlot^ do
      if Disabled = 0
        then
          begin
            StopCount := high(aStops);
            for I := 0 to StopCount - 1 do
              Stops[I] := aStops[I + 1];
            CurrentStop := 0;
            Start       := aStops[0];
            Range       :=  Stops[0] - Start;
          end;
  end;

  procedure StartNotify( aCount : integer );
  begin
    with TlsSlot^ do
      if Disabled = 0
        then
          begin
            Increment := Range / aCount;
            Progress  := Start;
            if assigned(Notify)
              then Notify( Start );
          end;
  end;

  procedure EndNotify;
  begin
    with TlsSlot^ do
      if Disabled = 0
        then
          begin
            if assigned(Notify)
              then Notify( Stops[CurrentStop] );
            inc( Start, Range );
            inc( CurrentStop );
            Range := Stops[CurrentStop] - Start;
          end;
  end;

  procedure DoNotify;
  begin
    with TlsSlot^ do
      if Disabled = 0
        then
          begin
            Progress := Progress + Increment;
            if assigned(Notify)
              then Notify( round(Progress) );
          end;
  end;


initialization
  tlsIndex := TlsAlloc;
finalization
  TlsFree( tlsIndex );
end.

