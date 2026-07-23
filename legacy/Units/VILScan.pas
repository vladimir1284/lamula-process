unit VILScan;

interface

uses
  Classes,
  Scan, Plane, Description, Measure, HeightTable,
  PPIScan,     
  RadarData, Observation,
  FloatMatrix;

type
  TVILScan = class(TScan)
  public
    constructor Initialize( aSize : TPlanePoint;
                            aMin, aMax : integer;
                            aC1, aC2 : double );
  public
    procedure Render( aData : TRadarData; aChannel : integer );  override;
  private
    fBottom, fTop : integer;
    fC1, fC2      : double;
    procedure Multiply( Mtx : TFloatMatrix; V : double );
  public
    property Bottom : integer read fBottom;
    property Top    : integer read fTop;
    property C1     : double  read fC1;
    property C2     : double  read fC2;
  private
    fHeightTable : THeightTable;
    fMtx         : TFloatMatrix;
    fAltitude    : integer;
    fPowerTable  : PCodeTable;
    procedure ProcessMove( S : TScan );
  public
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  end;

implementation

uses
  SysUtils,
  Math,
  Movement, Notify, Angle,
  Radars;

// TVilScan methods

constructor TVILScan.Initialize( aSize : TPlanePoint;
                                 aMin, aMax : integer;
                                 aC1, aC2 : double );
begin
  inherited Initialize(aSize, unKGM, pkHorizontal );
  fBottom := aMin;
  fTop    := aMax;
  fC1     := aC1;
  fC2     := aC2;
end;

procedure TVILScan.Render( aData : TRadarData; aChannel : integer );
var
  I : integer;
begin
  with aData as TObservation do
    begin
      Self.Radar := Radar;
      Self.Time  := Time;
      fAltitude := round(Radars.Find(Radar).Location.Altitude);
      with Channel[aChannel] do
        begin
          Self.Length  := Length;
          fHeightTable := HeightTable.Find(fAltitude, Beam, Cells, PlanePoint(Length, 1));
        end;
      with Area do
        fMtx := NewFloatMatrix(A.X, A.Y, B.X, B.Y);
      fMtx.Clear;
      new(fPowerTable);
      for I := MinCode to MaxCode do
        fPowerTable[I] := Power(CodeLineal(I, unDBZ), C2);
      StartNotify(Movements);
      try
        ProcessChannel(aChannel, unDBZ, ProcessMove);
        Multiply(fMtx, fC1);
      finally
        dispose(fPowerTable);
        fPowerTable := nil;
        FreeAndNil(fMtx);
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TVILScan.ProcessMove( S : TScan );
var
  R, A   : integer;
  Radius : longint;
  Cosine : double;
  HRay   : THeightRay;
begin
  if S is TPPIScan
    then
      with TPPIScan(S) do
        begin
          Cosine := cos(DegreeToRadian * CodeAngle(Angle));
          HRay   := fHeightTable.Ray[Angle];
          for R := Self.Origin.R to Self.Ending.R do
            begin
              if HRay[R].Max <= fBottom
                then continue;
              if HRay[R].Min >= fTop
                then break;
              Radius := round(R * Cosine);
              for A := Self.Origin.A to Self.Ending.A do
                if Cell[R, A] <> NODATA then
                  fMtx[Radius, A] := fMtx[Radius, A] + fPowerTable[Cell[R, A]] * (HRay[R].Max - HRay[R].Min)/1000;
            end;
        end;
  DoNotify;
end;

procedure TVILScan.ReadState( Reader : TReader );
begin
  inherited;
  fTop    := Reader.ReadInteger;
  fBottom := Reader.ReadInteger;
  fC1     := Reader.ReadFloat;
  fC2     := Reader.ReadFloat;
end;

procedure TVILScan.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(Top);
  Writer.WriteInteger(Bottom);
  Writer.WriteFloat  (C1);
  Writer.WriteFloat  (C2);
end;

procedure TVILScan.Multiply( Mtx : TFloatMatrix; V : double );
var
  I, J : integer;
  CA   : TRow;
  MR   : TFloatRow;
begin
  MR := nil;
  for J := Origin.Y to Ending.Y do
    begin
      CA := CellArray[J];
      MR := Mtx.Row  [J];
      for I := 0 to Width - 1 do
        CA[I] := MeasureCode(MR[I] * V, unKGM);
    end;
end;

initialization
  Classes.RegisterClass(TVILScan);
end.

