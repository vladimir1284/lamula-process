unit Correction;

interface

type
  TCorrectionTable = array of byte;

type
  TCorrection = class
  public
    constructor Create( aCells, aLength : integer );
    destructor  Destroy;  override;
  protected
    fCells      : integer;
    fLength     : integer;
    fCorrection : TCorrectionTable;
    function GetScope : integer;
    function GetValue( I : integer ) : byte;
  public
    property Scope  : integer read GetScope;
    property Cells  : integer read fCells;
    property Length : integer read fLength;
  public
    property Correction : TCorrectionTable read fCorrection;
    property Value[I : integer] : byte read GetValue;  default;
  end;

function Find( aCells, aLength : integer ) : TCorrection;

implementation

uses
  Classes, SysUtils,
  Math;

// Public procedures & functions

function Find( aCells, aLength : integer ) : TCorrection;
begin
  Result := TCorrection.Create(aCells, aLength);
end;

// TCorrection methods

constructor TCorrection.Create( aCells, aLength : integer );
var
  I      : integer;
  Radius : double;
  dRad   : double;
  Corr   : integer;
begin
  inherited Create;
  fCells  := aCells;
  fLength := aLength;
  SetLength(fCorrection, fCells);
  fCorrection[0] := 0;
  dRad   := fLength / 1000;  // km
  Radius := dRad;
  for I := 0 to fCells - 1 do
    begin
      Corr := round(20 * Log10(Radius));
      if Corr < 0
        then Corr := 0;
      fCorrection[I] := Corr;
      Radius := Radius + dRad;
    end;
end;

destructor TCorrection.Destroy;
begin
  Finalize(fCorrection);
  inherited Destroy;
end;

function TCorrection.GetScope : integer;
begin
  Result := longint(fCells) * fLength div 1000;
end;

function TCorrection.GetValue( I : integer ) : byte;
begin
  Result := fCorrection[I];
end;

end.
