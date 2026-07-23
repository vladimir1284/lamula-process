unit RainTable;

interface

uses
  Measure;

type
  PRainTable = ^TRainTable;
  TRainTable = array[TCode] of TCode;

type
  TRain = class
  public
    constructor Create_ZR ( A, B : double );
    constructor Create_KDP( A, B : double );
    destructor  Destroy;  override;
  protected
    fA, fB : double;
    fRain  : PRainTable;
  public
    property A : double read fA;
    property B : double read fB;
    function GetValue( I : integer ) : byte;
    function GetRain : PRainTable;
  public
    property Rain : PRainTable read GetRain;
    property Value[I : integer] : byte read GetValue;  default;
  end;

function Find_ZR  : TRain;
function Find_KDP : TRain;

implementation

uses
  Classes, SysUtils,
  Math,
  Configuration;

// Public procedures & functions

function Find_ZR : TRain;
begin
  with theConfiguration do
    Result := TRain.Create_ZR(RainA, RainB);
end;

function Find_KDP : TRain;
begin
  with theConfiguration do
    Result := TRain.Create_KDP(KDP_A, KDP_B);
end;

// TRain methods

constructor TRain.Create_ZR( A, B : double );
var
  I      : integer;
  T1, T2 : extended;
begin
  inherited Create;
  New(fRain);
  fA := A;
  fB := B;
  T1 := 10 * Log10(fA);
  T2 := 10 * fB;
  for I := 0 to 255 do
    fRain[I] := MeasureCode(Power(10, (CodeMeasure(I, unDBZ) - T1)/T2), unMMH);
end;

constructor TRain.Create_KDP( A, B : double );
var
  I : integer;
  K : float;
begin
  inherited Create;
  New(fRain);
  fA := A;
  fB := B;
  for I := 0 to 255 do
    begin
      K := CodeMeasure(I, unKDP);
      if K >= 0
        then fRain[I] := MeasureCode( fA * Power( K, fB), unMMH)
        else fRain[I] := MeasureCode(-fA * Power(-K, fB), unMMH);
    end;
end;

destructor TRain.Destroy;
begin
  Dispose(fRain);
  inherited;
end;

function TRain.GetValue( I : integer ) : byte;
begin
  Result := fRain[I];
end;

function TRain.GetRain : PRainTable;
begin
  Result := fRain;
end;

end.

