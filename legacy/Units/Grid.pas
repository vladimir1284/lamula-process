unit Grid;

interface

uses
  Windows,
  Classes,
  VestaPlane, Plane, Description, Measure;

const
  CSVExt = '.csv';
  TableFilter = 'Tabla|*' + CSVExt;

type
  TGridOrientation = (goDoesntMatter, goLeftRight, goTopDown, goRightLeft, goBottomUp);

type
  TGrid = class(TVestaPlane)
  public
    constructor Initialize( const anArea : TPlaneArea;
                            aLX, aLY : integer;
                            aKind : TPlaneKind );
  public
    procedure Assign( Source : TPersistent );  override;
  private
    fCenter      : T2DLocation;
    fTime        : TDateTime;
    fKind        : TPlaneKind;
    fLength      : TPlanePoint;
    fOrientation : TGridOrientation;
  public
    property Center      : T2DLocation      read fCenter      write fCenter;
    property Time        : TDateTime        read fTime        write fTime;
    property Kind        : TPlaneKind       read fKind        write fKind;
    property Length      : TPlanePoint      read fLength      write fLength;
    property Orientation : TGridOrientation read fOrientation write fOrientation stored false;
  public
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  public
    class function DefaultGap : TPoint;  virtual;
  public
    procedure SaveCSV( const FileName : string );
    procedure Soften ( Source : TGrid );
  private
    procedure Soften_Average( Source : TGrid );
    procedure Soften_Count  ( Source : TGrid );
  end;

implementation

// TGrid methods

constructor TGrid.Initialize( const anArea : TPlaneArea;
                              aLX, aLY : integer;
                              aKind : TPlaneKind );
begin
  inherited Initialize(anArea, nil, unNone);
  fLength      := PlanePoint(aLX, aLY);
  fKind        := aKind;
  fOrientation := goDoesntMatter;
end;

procedure TGrid.Assign( Source : TPersistent );
begin
  if Source is TGrid
    then
      begin
        fCenter  := (Source as TGrid).Center;
        fTime    := (Source as TGrid).Time;
        fLength  := (Source as TGrid).Length;
        fKind    := (Source as TGrid).Kind;
      end;
  inherited Assign(Source);
end;

procedure TGrid.ReadState( Reader : TReader );
begin
  inherited;
  fCenter.Longitude := Reader.ReadFloat;
  fCenter.Latitude  := Reader.ReadFloat;
  fTime             := Reader.ReadFloat;
  fKind             := TPlaneKind(Reader.ReadInteger);
  fLength           := ReadPlanePoint(Reader);
end;

procedure TGrid.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteFloat(fCenter.Longitude);
  Writer.WriteFloat(fCenter.Latitude);
  Writer.WriteFloat(fTime);
  Writer.WriteInteger(longint(fKind));
  WritePlanePoint(Writer, fLength);
end;

procedure TGrid.SaveCSV( const FileName : string );
var
  F    : TextFile;
  I, J : integer;
begin
  AssignFile(F, FileName);
  Rewrite(F);
  writeln(F, MeasureVar(Measure), ' [', MeasureName(Measure), ']');
  writeln(F, '(', Origin.X, ', ', Origin.Y, ') - (',
                   Ending.X, ', ', Ending.Y, ') / ', Length.X, 'm');
  writeln(F, '(0, 0) -> ', Center.Longitude:4:2, ', ',
                           Center.Latitude :4:2);
  writeln(F);
  for J := Ending.Y downto Origin.Y do
    begin
      for I := Origin.X to Ending.X - 1 do
        if Cell[I, J] <= MaxCode
          then write(F, CodeMeasure(Cell[I, J], Measure):6:2, ', ')
          else write(F, 'NODATA', ', ');
      if Cell[Ending.X, J] <= MaxCode
        then writeln(F, CodeMeasure(Cell[Ending.X, J], Measure):6:2)
        else writeln(F, 'NODATA');
    end;
  Close(F);
end;

class function TGrid.DefaultGap : TPoint;
begin
  Result.X := 50;
  Result.Y := 50;
end;

procedure TGrid.Soften_Average( Source : TGrid );
var
  X, Y : integer;
  S    : double;
  W    : integer;  //double;
  Src  : TRow;
  Src1 : TRow;
  Src2 : TRow;
  Dst  : TRow;
  P    : TCode;
const
  CenterWeight = 1.0;
  SideWeight   = 0.5;
  CornerWeight = 0.2;
begin
  Assign(Source);
  Src  := Source.Row[Origin.Y];
  Src2 := Source.Row[Origin.Y + 1];
  for Y := Origin.Y + 1 to Ending.Y - 1 do
    begin
      Src1 := Src;
      Src  := Src2;
      Src2 := Source.Row[Y + 1];
      Dst  := Self  .Row[Y];
      for X := 1 to Width - 2 do
        begin
          P := Src[X];
          if (P > 0) and (P <= MaxCode)
            then
              begin
                // Center
                S := {CenterWeight * }CodeLineal(P, Measure);
                W := 1;  //1.0;
                // Left side
                P := Src[X - 1];
                if (P > 0) and (P <= MaxCode)
                  then
                    begin
                      S := S + {SideWeight * }CodeLineal(P, Measure);
                      inc(W);  //W := W + SideWeight;
                    end;
                // Right side
                P := Src[X + 1];
                if (P > 0) and (P <= MaxCode)
                  then
                    begin
                      S := S + {SideWeight * }CodeLineal(P, Measure);
                      inc(W);  //W := W + SideWeight;
                    end;
                // Up side
                P := Src1[X];
                if (P > 0) and (P <= MaxCode)
                  then
                    begin
                      S := S + {SideWeight * }CodeLineal(P, Measure);
                      inc(W);  //W := W + SideWeight;
                    end;
                // Down side
                P := Src2[X];
                if (P > 0) and (P <= MaxCode)
                  then
                    begin
                      S := S + {SideWeight * }CodeLineal(P, Measure);
                      inc(W);  //W := W + SideWeight;
                    end;
                // Upper-left corner
                P := Src1[X - 1];
                if (P > 0) and (P <= MaxCode)
                  then
                    begin
                      S := S + {CornerWeight * }CodeLineal(P, Measure);
                      inc(W);  //W := W + CornerWeight;
                    end;
                // Upper-right corner
                P := Src1[X + 1];
                if (P > 0) and (P <= MaxCode)
                  then
                    begin
                      S := S + {CornerWeight * }CodeLineal(P, Measure);
                      inc(W);  //W := W + CornerWeight;
                    end;
                // Lower-left corner
                P := Src2[X - 1];
                if (P > 0) and (P <= MaxCode)
                  then
                    begin
                      S := S + {CornerWeight * }CodeLineal(P, Measure);
                      inc(W);  //W := W + CornerWeight;
                    end;
                // Lower-right corner
                P := Src2[X + 1];
                if (P > 0) and (P <= MaxCode)
                  then
                    begin
                      S := S + {CornerWeight * }CodeLineal(P, Measure);
                      inc(W);  //W := W + CornerWeight;
                    end;
                // Average
                Dst[X] := LinealCode(S/W, Measure);
              end;
        end;
    end;
end;

procedure TGrid.Soften_Count( Source : TGrid );
var
  X, Y : integer;
  I, M : integer;
  Src  : TRow;
  Src1 : TRow;
  Src2 : TRow;
  Dst  : TRow;
  P    : TCode;
  C    : array[TCode] of integer;
begin
  Assign(Source);
  Src  := Source.Row[Origin.Y];
  Src2 := Source.Row[Origin.Y + 1];
  for Y := Origin.Y + 1 to Ending.Y - 1 do
    begin
      Src1 := Src;
      Src  := Src2;
      Src2 := Source.Row[Y + 1];
      Dst  := Self  .Row[Y];
      for X := 1 to Width - 2 do
        begin
          FillChar(C, sizeof(C), 0);
          // Center
          inc(C[Src[X]]);
          // Left side
          inc(C[Src[X - 1]]);
          // Right side
          inc(C[Src[X + 1]]);
          // Up side
          inc(C[Src1[X]]);
          // Down side
          inc(C[Src2[X]]);
          // Upper-left corner
          inc(C[Src1[X - 1]]);
          // Upper-right corner
          inc(C[Src1[X + 1]]);
          // Lower-left corner
          inc(C[Src2[X - 1]]);
          // Lower-right corner
          inc(C[Src2[X + 1]]);
          // Maximum
          P := 0;
          M := 0;
          for I := MinCode to MaxCode do
            if C[I] > M
              then
                begin
                  M := C[I];
                  P := I;
                end;
          Dst[X] := P;
        end;
    end;
end;

procedure TGrid.Soften( Source : TGrid );
begin
  if Source.Measure in [unGCP, unTID]
    then Soften_Count  (Source)
    else Soften_Average(Source);
end;

initialization
  Classes.RegisterClass(TGrid);
end.

