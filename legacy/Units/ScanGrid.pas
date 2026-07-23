unit ScanGrid;

interface

uses
  Grid, Plane, Scan, Settings;

type
  TScanGrid = class;

  TScanGrid = class(TGrid)
  public
    constructor Initialize( const anArea : TPlaneArea; aLength : integer );
    constructor Render( aScan : TScan );
  public
    procedure RenderScan( aScan : TScan );
  end;

implementation

uses
  Windows, Classes, MaxsScan, TopDownScan,
  Math,
  FloatMatrix, Notify, Measure,
  Description,
  Radars,
  VestaPlane,
  PRTable, MatLab;

// TScanGrid methods

constructor TScanGrid.Initialize( const anArea : TPlaneArea;
                                  aLength : integer );
begin
  inherited Initialize(anArea, aLength, aLength, pkHorizontal);
end;

constructor TScanGrid.Render( aScan : TScan );
begin
  inherited Initialize(PlaneArea(succ(-aScan.Radiuses), succ(-aScan.Radiuses),
                                 pred( aScan.Radiuses), pred( aScan.Radiuses)),
                       aScan.Length, aScan.Length,
                       pkHorizontal);
  RenderScan(aScan);
end;

procedure TScanGrid.RenderScan( aScan : TScan );
var
  AA, RR : integer;
  XX, YY : integer;
  V      : integer;
  M, N   : TFloatMatrix;
  SR     : TRay;         // Scan Ray
  GR     : TRow;         // Grid Row
  MR     : TFloatRow;    // Matrix Row
  C      : TCode;
  PRT    : TPRTable;
  Zero: boolean;
begin
  with Radars.Find(aScan.Radar).Location do
    Center := Location2D(Longitude, Latitude);
  Time    := aScan.Time;
  Measure := aScan.Measure;
  Zero := theSettings.IncludeZero;
  with Area do
    begin
      M := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
      N := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
    end;
//  N := TPlane.Initialize(Area, nil);
  try
    StartNotify(2);
    PRT := PRTable.Find(aScan.Size, aScan.Length, Length.X);
    with PRT do
      try
        // Scan Polar
        for AA := aScan.Origin.A to aScan.Ending.A do
          begin
            SR := aScan.Ray[AA];
            for RR := aScan.Origin.R to aScan.Ending.R do
              with Polar2Grid[RR, AA] do
                if (X >= Origin.X) and (X <= Ending.X) and
                   (Y >= Origin.Y) and (Y <= Ending.Y)
                  then
                    begin
                      C := SR[RR - aScan.Origin.R];
                      if (C <= MaxCode) and
                         (Zero or (not Zero and (C > 0)))
                        then
                          begin
                          { if Measure <> unMs  then
                              begin
                                // Valor Máximo
                                temp := CodeLineal(C, Measure);
                                if temp > M[X, Y] then
                                  M[X, Y] := temp;
                                N[X, Y] := 1;
                              end
                            else }
                              begin
                                // Promediación
                                M[X, Y] := M[X, Y] + CodeLineal(C, Measure);
                                N[X, Y] := N[X, Y] + 1;
                              end;
                          end;
                    end;
          end;
        DoNotify;
        // Scan Grid
        RR := sqr(aScan.Ending.R * aScan.Length div Length.X);
        MR := nil;
        for YY := Origin.Y to Ending.Y do
          begin
            GR := Self.Row[YY];
            MR := M.   Row[YY];
            for XX := 0 to Columns -1 do
              begin
                V := Round(N[XX + Origin.X, YY]);  //GridCount[XX + Origin.X, YY];
                if V = 0
                  then
                    if (sqr(XX + Origin.X) + sqr(YY)) < RR
                      then
                        with Grid2Polar[XX + Origin.X, YY] do
                          GR[XX] := aScan[R, A]  // interpolate ???
                      else GR[XX] := NoData
                  else GR[XX] := LinealCode(MR[XX]/V, Measure);
              end;
          end;
        DoNotify;
      finally
        PRTable.Free(PRT);
        EndNotify;
      end;
  finally
    N.Free;
    M.Free;
  end;
end;

initialization
  Classes.RegisterClass(TScanGrid);
end.

