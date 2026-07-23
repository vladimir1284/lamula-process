unit WindGrid;

interface

uses
  Grid, Plane, Scan, FloatMatrix, Angle;

type
  TWindGrid = class(TGrid)
  private
    fAngle: TPlane;
    function WindOnCircularArc(aScan: TScan; Radius: integer; a1, a2: TAngle): TVector;
  public
    constructor Initialize(const anArea : TPlaneArea; aLength : integer);
    destructor Destroy;                          override;
    procedure RenderScan( aScan : TScan );
    property Angle: TPlane read fAngle;
  end;

implementation

uses
  Windows, Classes, SysUtils,
  Math,
  Notify, Measure,
  Description,
  Radars,
  VestaPlane,
  PRTable,
  CalcFunctions;

constructor TWindGrid.Initialize;
begin
  inherited Initialize(anArea, aLength, aLength, pkHorizontal);
end;

destructor TWindGrid.Destroy;
begin
  Angle.Free;
  inherited;
end;

function TWindGrid.WindOnCircularArc(aScan: TScan; Radius: integer; a1, a2: TAngle): TVector;
var
  P, Pt, V, C, K: TSingleDynMatrix;
  AngleLength, ce, Cdt, nv: single;
  ParamCount, i, na: integer;
begin

  // NODATA Bug  !!!

  ParamCount := a2 - a1;
  with aScan do
    AngleLength := 2*pi/(Ending.A - Origin.A);
  SetLength(Pt, 2, ParamCount);
  SetLength(V, ParamCount, 1);
  SetLength(K, 2, 1);
  ce := cos(CodeAngle(aScan.Angle)*pi/180);
  for i := a1 to a2 - 1 do
    begin
      Pt[0, i - a1] := ce*sin(i*AngleLength);
      Pt[1, i - a1] := ce*cos(i*AngleLength);
      if i <= aScan.Ending.A then na := i else na := i - aScan.Ending.A;
      if aScan.Cell[Radius, na] = NODATA then nv := 0 else nv := CodeMeasure(aScan.Cell[Radius, na], unMS);
      V[i - a1, 0] := nv;
    end;

{  SetLength(P, 2, 3);
  P[0, 0] := 1; P[0, 1] := 2; P[0, 2] := 3;
  P[1, 0] := 4; P[1, 1] := 5; P[1, 2] := 6;}

  P := MTranspose(Pt);

  C := MMult(Pt, P);

  C := MInverse(C);
  V := MMult(Pt, V);
  K := MMult(C, V);
  Result[0] := K[0, 0];
  Result[1] := K[1, 0];
end;

procedure TWindGrid.RenderScan;
var
  R, A, YY, XX: integer;
  C1, C2, CZero: byte;
  Vel, Vel1: TVector;
  PRT: TPRTable;
  N, Vx, Vy: TFloatMatrix;
  dCell: integer;

  function NextAngle(anAngle, anOffset: integer): integer;
  begin
    if anAngle + anOffset > aScan.Ending.A then
      result := anAngle + anOffset - aScan.Ending.A
    else if anAngle + anOffset < aScan.Origin.A then
      result :=  -(anAngle + anOffset)
    else
      result := anAngle + anOffset
  end;

var
  i: integer;
begin
// Calculate Vectors
  fAngle := TPlane.Initialize(Area, nil);
  PRT := PRTable.Find(aScan.Size, aScan.Length, Length.X);
  with Area do
    begin
      Vx := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
      Vy := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
      N  := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
    end;
  dCell := 40;
  for R := aScan.Origin.R to aScan.Ending.R do
    begin
      A := aScan.Origin.A;
      repeat
        C1 := aScan.Cell[R, A];
        C2 := aScan.Cell[R, NextAngle(A, dCell)];
        if (C1 <> NODATA) and (C2 <> NODATA) then
          begin
            Vel := VADVector(CodeLineal(C1, unMS), CodeLineal(C2, unMS),
                             360/aScan.Ending.A*A, 360/aScan.Ending.A*(A + dCell),
                             CodeAngle(aScan.Angle));
            with PRT.Polar2Grid[R, NextAngle(A, dCell Div 2)] do
              if (X >= Origin.X) and (X <= Ending.X) and
                 (Y >= Origin.Y) and (Y <= Ending.Y)
                then
                  begin
                    Vx[X, Y] := Vx[X, Y] + Vel[0] ;
                    Vy[X, Y] := Vy[X, Y] + Vel[1] ;
                    N [X, Y] := N [X, Y] + 1;
                  end;
          end;
        Inc(A);
{       Vel := WindOnCircularArc(aScan, R, A, A + dCell);}
        for i := 1 to dCell do
          begin
            with PRT.Polar2Grid[R, NextAngle(A, i)] do
              if (X >= Origin.X) and (X <= Ending.X) and
                 (Y >= Origin.Y) and (Y <= Ending.Y)
                then
                  begin
                    Vx[X, Y] := Vx[X, Y] + Vel[0] ;
                    Vy[X, Y] := Vy[X, Y] + Vel[1] ;
                    N [X, Y] := N [X, Y] + 1;
                  end;
          end;
        Inc(A, dCell);
      until A >= aScan.Ending.A;
    end;
// Calculate Vector Average
  for XX := Origin.X to Ending.X do
    for YY := Origin.Y to Ending.Y do
      begin
        if N[XX, YY] > 1 then
          begin
            Vel[0] := Vx[XX, YY]/N[XX, YY];
            Vel[1] := Vy[XX, YY]/N[XX, YY];
          end
        else
          begin
            Vel[0] := Vx[XX, YY];
            Vel[1] := Vy[XX, YY];
          end;
        Self [XX, YY] := Velocity2Byte(Rho(Vel[0], Vel[1]));
        Angle[XX, YY] := Angle2Byte(Phi(Vel[0], Vel[1]));
      end;
  PRT.Free;
  Vx.Free;
  Vy.Free;
  N.Free;
end;

end.
