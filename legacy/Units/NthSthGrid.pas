unit NthSthGrid;

interface

uses
  Windows,
  Classes,
  Grid, Plane, Observation, Description, Measure, Scan, Angle,
  PRTable, HeightTable;

type
  TNthSthGrid = class(TGrid)
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

// TNthSthGrid methods

constructor TNthSthGrid.Initialize( const anArea : TPlaneArea;
                                    aLength : integer; aCellHeight : integer;
                                    aBottom, aTop : integer );
begin
  inherited Initialize(PlaneArea(anArea.Left,  aBottom div aCellHeight,
                                 anArea.Right, aTop    div aCellHeight),
                        aLength, aCellHeight,
                        pkVertical);
  fRenderArea := anArea;
  fTop        := aTop;
  fBottom     := aBottom;
  Orientation := goLeftRight;
end;

procedure TNthSthGrid.Render( anObs : TObservation; aChannel : integer; aMeasure : TMeasure );
begin
  with anObs do
    begin
      with Radars.Find(Radar).Location do
        Self.Center := Location2D(Longitude, Latitude);
      Self.Time     := Time;
      Self.Measure  := aMeasure;
      fAltitude     := round(Radars.Find(Radar).Location.Altitude/Length.Y);
      fHighestAngle := HighestAngle(aChannel);
      fLocation     := theSettings.DefaultTopsLoc/100;
      with Channel[aChannel] do
        begin
          fPRTable     := PRTable.Find(PlanePoint(Cells, Sectors), Length, Self.Length.X);
          fHeightTable := HeightTable.Find(fAltitude, Beam, Cells, PlanePoint(Length, Self.Length.Y));
        end;
      StartNotify(Movements);
      try
        ProcessChannel(aChannel, Measure, ProcessMove);
      finally
        PRTable.Free(fPRTable);
        HeightTable.Free(fHeightTable);
        EndNotify;
      end;
    end;
end;

procedure TNthSthGrid.ProcessMove( S : TScan );
var
  RR, AA : integer;
  Y1, Y2 : integer;
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
                  Y1 := Min;
                  if Angle < fHighestAngle
                    then Y2 := Max
                    else Y2 := Min + round((Max - Min) * fLocation);
                end;
              if Y1 > Self.Ending.Y
                then break;
              if Y2 > Self.Ending.Y
                then Y2 := Self.Ending.Y;
              if Y1 < Self.Origin.Y
                then Y1 := Self.Origin.Y;
              for AA := Origin.A to Ending.A do
                with fPRTable.Polar2Grid[RR, AA] do
                  if InArea(fRenderArea, X, Y) and (Cell[RR, AA] <> NODATA)
                    then
                      begin
                        C := Cell[RR, AA];
                        for I := Y1 to Y2 do
                          begin
                            V := Self[X, I];
                            if (V = NoData) or (C > V)
                              then Self[X, I] := C;
                          end;
                      end;
            end;
        end;
  DoNotify;
end;

procedure TNthSthGrid.ReadState( Reader : TReader );
begin
  inherited;
  fTop        := Reader.ReadInteger;
  fBottom     := Reader.ReadInteger;
  fRenderArea := ReadPlaneArea(Reader);
end;

procedure TNthSthGrid.WriteState( Writer : TWriter );
begin
  inherited;
  Writer.WriteInteger(Top);
  Writer.WriteInteger(Bottom);
  WritePlaneArea(Writer, RenderArea);
end;

class function TNthSthGrid.DefaultGap : TPoint;
begin
  Result   := inherited DefaultGap;
  Result.Y := 5;
end;

initialization
  Classes.RegisterClass(TNthSthGrid);
end.

