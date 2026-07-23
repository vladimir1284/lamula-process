unit EstWstGrid;

interface

uses
  Windows, 
  Classes,
  Grid, Plane, Observation, Description, Measure, Scan, Angle,
  PRTable, HeightTable;

type
  TEstWstGrid = class(TGrid)
  public
    constructor Initialize( const anArea : TPlaneArea;
                            aLength : integer; aCellHeight : integer;
                            aBottom, aTop : integer );
    procedure   Render( anObs : TObservation; aChannel : integer; aMeasure : TMeasure );
  private
    fTop, fBottom : integer;
    fRenderArea   : TPlaneArea;
  public
    property Top        : integer    read fTop;
    property Bottom     : integer    read fBottom;
    property RenderArea : TPlaneArea read fRenderArea;
  private
    fPRTable      : TPRTable;
    fHeightTable  : THeightTable;
    fAltitude     : integer;
    fHighestAngle : TAngle;
    fLocation     : single;
    procedure ProcessMove( S : TScan );
  public
    procedure ReadState ( Reader : TReader );  override;
    procedure WriteState( Writer : TWriter );  override;
  public
    class function DefaultGap : TPoint;  override;
  end;

implementation

uses
  SysUtils,
  Settings,
  Movement, RadarPlane, PPIScan, Notify,
  Radars,
  VestaPlane,
  RainTable;

// TEstWstGrid methods

constructor TEstWstGrid.Initialize( const anArea : TPlaneArea;
                                    aLength : integer; aCellHeight : integer;
                                    aBottom, aTop : integer );
begin
  inherited Initialize(PlaneArea(aBottom div aCellHeight, anArea.Top,
                                 aTop    div aCellHeight, anArea.Bottom),
                       aCellHeight, aLength,
                       pkVertical);
  fRenderArea := anArea;
  fTop        := aTop;
  fBottom     := aBottom;
  Orientation := goTopDown;
end;

procedure TEstWstGrid.Render( anObs : TObservation; aChannel : integer; aMeasure : TMeasure );
begin
  with anObs do
    begin
      with Radars.Find(Radar).Location do
        Self.Center := Location2D(Longitude, Latitude);
      Self.Time     := Time;
      Self.Measure  := aMeasure;
      fAltitude     := round(Radars.Find(Radar).Location.Altitude/Length.X);
      fHighestAngle := HighestAngle(aChannel);
      fLocation     := theSettings.DefaultTopsLoc/100;
      with Channel[aChannel] do
        begin
          fPRTable     := PRTable.Find(PlanePoint(Cells, Sectors), Length, Self.Length.Y);
          fHeightTable := HeightTable.Find(fAltitude, Beam, Cells, PlanePoint(Length, Self.Length.X));
        end;
      StartNotify(anObs.Movements);
      try
        ProcessChannel(aChannel, aMeasure, ProcessMove);
      finally
        PRTable.Free(fPRTable);
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TEstWstGrid.ProcessMove( S : TScan );
var
  RR, AA : integer;
  X1, X2 : integer;
  V, C   : TCode;
  I      : integer;
  HRay   : THeightRay;
begin
  if S is TPPIScan
    then
      with S as TPPIScan do
        begin
          HRay := fHeightTable.Ray[Angle];
          for RR := Origin.R to Ending.R do
            begin
              with HRay[RR] do
                begin
                  X1 := Min;
                  if Angle < fHighestAngle
                    then X2 := Max
                    else X2 := round(Min + (Max - Min) * fLocation);
                end;
              if X1 > Self.Ending.X
                then break;
              if X1 < Self.Origin.X
                then X1 := Self.Origin.X;
              if X2 > Self.Ending.X
                then X2 := Self.Ending.X;
              for AA := Origin.A to Ending.A do
                with fPRTable.Polar2Grid[RR, AA] do
                  if InArea(fRenderArea, X, Y) and (Cell[RR, AA] <> NODATA)
                    then
                      begin
                        C := Cell[RR, AA];
                        for I := X1 to X2 do
                          begin
                            V := Self[I, Y];
                            if (V = NoData) or (C > V)
                              then Self[I, Y] := C;
                          end;
                      end;
            end;
        end;
  DoNotify;
end;

procedure TEstWstGrid.ReadState( Reader : TReader );
begin
  inherited;
  fTop        := Reader.ReadInteger;
  fBottom     := Reader.ReadInteger;
  fRenderArea := ReadPlaneArea(Reader);
end;

procedure TEstWstGrid.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(Top);
  Writer.WriteInteger(Bottom);
  WritePlaneArea(Writer, RenderArea);
end;

class function TEstWstGrid.DefaultGap : TPoint;
begin
  Result   := inherited DefaultGap;
  Result.X := 5;
end;

initialization
  Classes.RegisterClass(TEstWstGrid);
end.

