unit Scales;

interface

uses
  Scale, Measure;

function Find( aMeasure : TMeasure ) : TScale;

implementation

uses
  Settings,
  Windows, SysUtils;

// Public procedures & functions

function Find( aMeasure : TMeasure ) : TScale;
begin
  Result := TScale.Load(theSettings.PaletteTable[aMeasure]);
  if assigned(Result)
    then Result.Measure := aMeasure;
end;

end.

