unit Regions;

interface

uses
  Region, Description;

procedure Create;
procedure Destroy;
procedure Update;

function  Find   ( Lg, Lt : single; Index : integer ) : TRegion;
procedure Release( aRegion : TRegion );

function  GetReference( I : integer ) : TRegionReference;
function  Count                       : integer;

implementation

uses
  Windows,
  SysUtils, Classes,
  Configuration,
  FileIterator, Shell_Process, GridForm;

var
  theReferences : TList = nil;
  theRegions    : TList = nil;

// Private procedures & functions

procedure Register( const aFileName : string );
begin
  try
    theReferences.Add(TRegionReference.Load(aFileName));
    theRegions.Add(nil);
  except
    on EInOutError do
      begin
        MessageBeep(MB_ICONHAND);
        MessageBox(0, pchar('El encabezamiento del archivo ' + aFileName + 'contiene errores. ' +
                            'La region descrita en el archivo no estara disponible.'),
                   'Regiones', MB_OK or MB_ICONSTOP);
      end;
  end;
end;

function ComparePriorities( R1, R2 : pointer ) : integer;
begin
  Result := TRegionReference(R1).Priority - TRegionReference(R2).Priority;
end;

// Public procedures & functions

procedure Create;
begin
  if assigned(theReferences) or assigned(theRegions)
    then Destroy;
  theReferences := TList.Create;
  theRegions    := TList.Create;
  ProcessMultiPath(theConfiguration.RegionTables + PathDelim + '*.rgn', Register, false);
  theReferences.Sort(ComparePriorities);
end;

procedure Destroy;
var
  I : integer;
begin
  if assigned(theReferences)
    then
      begin
        for I := 0 to theReferences.Count - 1 do
          TRegionReference(theReferences[I]).Free;
        FreeAndNil(theReferences);
      end;
  if assigned(theRegions)
    then
      begin
        for I := 0 to theRegions.Count - 1 do
          TRegion(theRegions[I]).Free;
        FreeAndNil(theRegions);
      end;
end;

procedure Update;
var
  i: integer;
begin
  Destroy;
  Create;
end;

function Find( Lg, Lt : single; Index : integer ) : TRegion;
var
  I : integer;
  C : integer;
begin
  C := Index;
  for I := 0 to Count - 1 do
    with TRegionReference(theReferences[I]) do
      if (Abs(Center.Longitude - Lg) <= 0.001) and (Abs(Center.Latitude - Lt) <= 0.001)
        then
          if C = 0
            then
              begin
                if References = 0
                  then theRegions[I] := TRegion.Load(FileName);
                References := References + 1;
                Result     := theRegions[I];
                exit;
              end
            else dec(C);
  raise Exception.Create('No se encuentra region');
end;

procedure Release( aRegion : TRegion );
var
  I : integer;
begin
  if assigned(aRegion)
    then
      begin
        I := theRegions.IndexOf(aRegion);
        if I >= 0
          then
            with TRegionReference(theReferences[I]) do
              begin
                References := References - 1;
                if References = 0
                  then
                    begin
                      aRegion.Free;
                      theRegions[I] := nil;
                    end;
              end;
      end;
end;

function GetReference( I : integer ) : TRegionReference;
begin
  Result := theReferences[I];
end;

function Count : integer;
begin
  if assigned(theReferences)
    then Result := theReferences.Count
    else Result := 0;
end;

initialization
  Create;
finalization
  Destroy;
end.

