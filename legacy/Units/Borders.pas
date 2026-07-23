unit Borders;

interface

uses
  Border, Description;

procedure Create;
procedure Destroy;
procedure Update;

function  Find   ( Lg, Lt : single; Index : integer ) : TBorder;
procedure Release( aBorder : TBorder );

function  GetReference( I : integer ) : TBorderReference;
function  Count                       : integer;

function BorderCompare(Item1, Item2: Pointer): Integer;

implementation

uses
  Windows,
  SysUtils, Classes,
  Configuration,
  FileIterator;

var
  theReferences : TList = nil;
  theBorders    : TList = nil;

// Private procedures & functions

function BorderCompare;
begin
  result := TBorderReference(Item1).Range - TBorderReference(Item2).Range;
end;

procedure Register( const aFileName : string );
begin
  try
    theReferences.Add(TBorderReference.Load( aFileName ));
    theBorders.Add(nil);
  except
    on EInOutError do
      begin
        MessageBeep(MB_ICONHAND);
        MessageBox(0, pchar('El encabezamiento del archivo ' + aFileName + 'contiene errores.' +
                            'La frontera descrita en el archivo no estara disponible.'),
                   'Fronteras', MB_OK or MB_ICONSTOP);
      end;
  end;
end;


// Public procedures & functions

procedure Create;
begin
  if assigned(theReferences) or assigned(theBorders)
    then Destroy;
  theReferences := TList.Create;
  theBorders    := TList.Create;
  ProcessMultiPath(theConfiguration.BorderTables + PathDelim + '*.brd', Register, false);
  theReferences.Sort(BorderCompare);
//  theBorders.Sort(BorderCompare);
end;

procedure Destroy;
var
  I : integer;
begin
  if assigned(theReferences)
    then
      begin
        for I := theReferences.Count - 1 downto 0 do
          TBorderReference(theReferences[I]).Free;
        FreeAndNil(theReferences);
      end;
  if assigned(theBorders)
    then
      begin
        for I := theBorders.Count - 1 downto 0 do
          TBorder(theBorders[I]).Free;
        FreeAndNil(theBorders);
      end;
end;

procedure Update;
begin
  Destroy;
  Create;
end;

function Find( Lg, Lt : single; Index : integer ) : TBorder;
var
  I : integer;
  C : integer;
begin
  C := Index;
  for I := 0 to Count - 1 do
    with TBorderReference(theReferences[I]) do
      if (Center.Longitude = Lg) and (Center.Latitude = Lt)
        then
          if C = 0
            then
              begin
                if References = 0
                  then theBorders[I] := TBorder.Load(FileName);
                References := References + 1;
                Result     := theBorders[I];
                exit;
              end
            else dec(C);
  raise Exception.Create('No se encuentra frontera');
end;

procedure Release( aBorder : TBorder );
var
  I : integer;
begin
  if assigned(aBorder)
    then
      begin
        I := theBorders.IndexOf(aBorder);
        if I >= 0
          then
            with TBorderReference(theReferences[I]) do
              begin
                References := References - 1;
                if References = 0
                  then
                    begin
                      TBorder(theBorders[I]).Free;
                      theBorders[I] := nil;
                    end;
              end;
      end;
end;

function GetReference( I : integer ) : TBorderReference;
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

