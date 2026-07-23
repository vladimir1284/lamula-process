unit Volume;

interface

uses
  Windows,
  Classes, Forms,
  Product,
  DataSource, Grid, Measure, Plane, Scan, HeightTable, PRTable, Angle,
  EditForm, GridForm;

type
  TVolume     = class;
  TVolumeAuto = class;

  TVolume = class(TProduct)
  public
    class function  Name        : string;                override;
    class function  Description : string;                override;
    class function  ImageIndex  : integer;               override;
    class function  EditForm    : TFEdit;                override;
    class function  Setup( D : TDataSource ) : boolean;  override;
    class procedure SetDefault;                          override;
    class procedure SetRemember;                         override;
    class function  AutoClass   : CProductAuto;          override;
    class function  CanAnimate  : boolean;               override;
  private
    fTop      : integer;
    fBottom   : integer;
    fChannel  : integer;
    fMeasure  : TMeasure;
    fLength   : integer;
    fArea     : TPlaneArea;
    fHeight   : TCoord;
    fGrids    : array[0..2] of TGrid;
    fMaxCells : integer;
    function  GetGrid    ( Index : integer ) : TGrid;
    procedure SetGrid    ( Index : integer; V : TGrid );
    procedure ReadArea   ( Reader : TReader );
    procedure WriteArea  ( Writer : TWriter );
    procedure ReadGrids  ( Reader : TReader );
    procedure WriteGrids ( Writer : TWriter );
  published
    property Top        : integer  read fTop      write fTop;
    property Bottom     : integer  read fBottom   write fBottom;
    property Channel    : integer  read fChannel  write fChannel;
    property Measure    : TMeasure read fMeasure  write fMeasure;
    property CellHeight : TCoord   read fHeight   write fHeight;
    property Length     : integer  read fLength   write fLength;
    property MaxCells   : integer  read fMaxCells write fMaxCells stored false;
  public  // These properties may not be published
    property Area   : TPlaneArea    read fArea   write fArea;
    property TDGrid : TGrid index 0 read GetGrid write SetGrid;
    property NSGrid : TGrid index 1 read GetGrid write SetGrid;
    property EWGrid : TGrid index 2 read GetGrid write SetGrid;
  protected
    procedure SetDataSource( D : TDataSource );  override;
  protected
    function  GetPosition : TPoint;                override;
    procedure DefineProperties( Filer : TFiler );  override;
  protected
    function  GetLabel : string;  override;
    function  GetBrief : string;  override;
    procedure GetEditData;        override;
    procedure SetEditData;        override;
  public
    procedure Render;   override;
    procedure Update;   override;
    procedure Show;     override;
  private
    fTDScan       : TScan;
    fHeightTable  : THeightTable;
    fScanHeight   : THeightTable;
    fAltitude     : integer;
    fScanAlt      : integer;
    fPRTable      : TPRTable;
    fHighestAngle : TAngle;
    fLocation     : single;
    procedure ProcessMove( S : TScan );
  private
    fViewForms : array[0..2] of TFGrid;
    fDisabled  : array[0..2] of boolean;
    procedure FormClose( Sender : TObject; var Action : TCloseAction );
    function  GetViewForm( Index : integer ) : TFGrid;
    function  GetTDView : TFGrid;
    function  GetNSView : TFGrid;
    function  GetEWView : TFGrid;
  public
    property TDViewForm : TFGrid read GetTDView;
    property NSViewForm : TFGrid read GetNSView;
    property EWViewForm : TFGrid read GetEWView;
  end;

  TVolumeAuto = class(TProductAuto)
  automated
    function  GetChannel : integer;
    function  GetMeasure : integer;
    function  GetCellH   : integer;
    function  GetEast    : integer;        virtual;
    function  GetWest    : integer;        virtual;
    function  GetNorth   : integer;        virtual;
    function  GetSouth   : integer;        virtual;
    function  GetTop     : integer;
    function  GetBottom  : integer;
    function  GetCellV   : integer;
    procedure SetChannel( Ch : integer );
    procedure SetMeasure( M  : integer );
    procedure SetCellH  ( C  : integer );
    procedure SetEast   ( E  : integer );  virtual;
    procedure SetWest   ( W  : integer );  virtual;
    procedure SetNorth  ( N  : integer );  virtual;
    procedure SetSouth  ( S  : integer );  virtual;
    procedure SetTop    ( T  : integer );
    procedure SetBottom ( B  : integer );
    procedure SetCellV  ( C  : integer );
  automated
    property Channel : integer read GetChannel write SetChannel;
    property Measure : integer read GetMeasure write SetMeasure;
    property CellH   : integer read GetCellH   write SetCellH;
    property CellV   : integer read GetCellV   write SetCellV;
    property East    : integer read GetEast    write SetEast;
    property West    : integer read GetWest    write SetWest;
    property North   : integer read GetNorth   write SetNorth;
    property South   : integer read GetSouth   write SetSouth;
    property Top     : integer read GetTop     write SetTop;
    property Bottom  : integer read GetBottom  write SetBottom;
  end;

implementation

uses
  SysUtils,
  Settings,
  RadarData, Observation, Notify,
  Radars,
  VestaPlane,
  PPIScan,
  TopDownScan, NthSthGrid, EstWstGrid, ScanGrid,
  VolumeEdit,
  SupressStatus;  ///mio;

// TVolume methods

class function TVolume.Name : string;
begin
  Result := 'Volumen';
end;

class function TVolume.Description : string;
begin
  Result := 'Pseudo volumen (mapa suizo)';
end;

class function TVolume.ImageIndex : integer;
begin
  Result := 4;
end;

class function TVolume.EditForm : TFEdit;
begin
  if FVolumeEdit = nil
    then Application.CreateForm(TFVolumeEdit, FVolumeEdit);
  Result := FVolumeEdit;
end;

class function TVolume.Setup( D : TDataSource ) : boolean;
var
  b: boolean;
begin
  Result := inherited Setup(D);
  if Result
    then
      with EditForm as TFVolumeEdit do
        begin
          Bottom  := theSettings.DefaultHorzBot;
          Top     := theSettings.DefaultHorzTop;
          Channel := 0;
          Measure := unDBZ;
          CellH := theSettings.DefaultCellH;
          CellV := theSettings.DefaultCellV;
          Supressing := theSettings.DefaultC_SStatusVolume; ///mio
          b := Supressing;//mio
          if D.InheritsFrom(TRadarData)
            then
              with (D as TRadarData).Channel[0], Area1 do
                begin
                  West  := -(Cells * Length div 1000);
                  South := -(Cells * Length div 1000);
                  East  :=  (Cells * Length div 1000);
                  North :=  (Cells * Length div 1000);
                end;
        end;
    theSupressStatus := b;  /////mio
end;

class procedure TVolume.SetDefault;
begin
  inherited;
  with EditForm as TFVolumeEdit do
    begin
      theSettings.DefaultHorzBot   := Bottom;
      theSettings.DefaultHorzTop   := Top;
      theSettings.DefaultC_SStatusVolume := Supressing; //mio
    end;
end;

class procedure TVolume.SetRemember;
begin
  inherited;
  with EditForm as TFVolumeEdit do
    theSettings.DefaultCellV := CellV;
end;

class function TVolume.AutoClass : CProductAuto;
begin
  Result := TVolumeAuto;
end;

class function TVolume.CanAnimate : boolean;
begin
  Result := false;
end;

procedure TVolume.ReadArea( Reader : TReader );
begin
  Area := ReadPlaneArea(Reader);
end;

procedure TVolume.WriteArea( Writer : TWriter );
begin
  WritePlaneArea(Writer, Area);
end;

procedure TVolume.ReadGrids( Reader : TReader );
var
  G0, G1, G2 : TGrid;
begin
  fGrids[0] := nil;
  fGrids[1] := nil;
  fGrids[2] := nil;
  G0 := ReadPlane(Reader, TDGrid) as TGrid;
  G1 := ReadPlane(Reader, NSGrid) as TGrid;
  G2 := ReadPlane(Reader, EWGrid) as TGrid;
  if fDisabled[0]
    then G0.Free
    else fGrids[0] := G0;
  if fDisabled[1]
    then G1.Free
    else fGrids[1] := G1;
  if fDisabled[2]
    then G2.Free
    else fGrids[2] := G2;
  Update;
end;

procedure TVolume.WriteGrids( Writer : TWriter );
begin
  WritePlane(Writer, TDGrid);
  WritePlane(Writer, NSGrid);
  WritePlane(Writer, EWGrid);
end;

function TVolume.GetGrid( Index : integer ) : TGrid;
begin
  Result := fGrids[Index];
end;

procedure TVolume.SetGrid( Index : integer; V : TGrid );
begin
  if fGrids[Index] <> V
    then
      begin
        FreeAndNil(fGrids[Index]);
        fGrids[Index] := V;
      end;
  Update;
end;

procedure TVolume.DefineProperties( Filer : TFiler );
begin
  inherited;
  Filer.DefineProperty('Area',   ReadArea,   WriteArea,   true);
  Filer.DefineProperty('Grids',  ReadGrids,  WriteGrids,  true);
end;

function TVolume.GetLabel : string;
begin
  Result := Format('Volume, %s', [MeasureVar(Measure)]);
end;

function TVolume.GetBrief : string;
begin
  Result := Format('%s, %s entre %dm y %dm',
                   [Name, MeasureVar(Measure), Bottom, Top]);
end;

procedure TVolume.Render;
var
  PRRectSize : TPlanePoint;
begin
  Notify.Declare([0, 10, 90, 100]);
  fGrids[1] := TNthSthGrid.Initialize(Area, Length, CellHeight, Bottom, Top);
  fGrids[2] := TEstWstGrid.Initialize(Area, Length, CellHeight, Bottom, Top);
  try
    with Observation do
      begin
        with Channel[Self.Channel] do
          fTDScan := TTopDownScan.Initialize(PlanePoint(MaxCells, Sectors), Measure,
                                             Bottom, Top);
        try
          with Radars.Find(Radar).Location do
            begin
              fGrids[1].Center := Location2D(Longitude, Latitude);
              fGrids[2].Center := Location2D(Longitude, Latitude);
            end;
          fGrids[1].Time    := Time;
          fGrids[2].Time    := Time;
          fGrids[1].Measure := Measure;
          fGrids[2].Measure := Measure;
          fTDScan.Radar := Radar;
          fTDScan.Time  := Time;
          PRRectSize    := PlanePoint(2 * Channel[Self.Channel].Cells, 2 * Channel[Self.Channel].Cells);
          fScanAlt      := round(Radars.Find(Radar).Location.Altitude);
          fAltitude     := round(Radars.Find(Radar).Location.Altitude/CellHeight);
          fHighestAngle := HighestAngle(Self.Channel);
          fLocation     := theSettings.DefaultTopsLoc / 100;
          with Channel[Self.Channel] do
            begin
              fTDScan.Length := Length;
              StartNotify(1);
              try
                fPRTable       := PRTable.Find(PlanePoint(Cells, Sectors), Length, Self.Length);
                fScanHeight    := HeightTable.Find(fScanAlt,  Beam, Cells, PlanePoint(Length, 1));
                fHeightTable   := HeightTable.Find(fAltitude, Beam, Cells, PlanePoint(Length, Self.CellHeight));
              finally
                EndNotify;
              end;
            end;
          StartNotify(Movements);
          try
            ProcessChannel(Self.Channel, Measure, ProcessMove);
          finally
            PRTable.Free(fPRTable);
            HeightTable.Free(fScanHeight);
            HeightTable.Free(fHeightTable);
            EndNotify;
          end;
          fGrids[0] := TScanGrid.Initialize(Area, Length);
          try
            TScanGrid(fGrids[0]).RenderScan(fTDScan);
          except
            FreeAndNil(fGrids[0]);
            raise;
          end;
        finally
          FreeAndNil(fTDScan);
        end;
      end;
  except
    FreeAndNil(fGrids[1]);
    FreeAndNil(fGrids[2]);
    raise;
  end;
  inherited;
end;

procedure TVolume.Update;
begin
  if assigned(fGrids[0]) then TDViewForm.Grid := fGrids[0];
  if assigned(fGrids[1]) then NSViewForm.Grid := fGrids[1];
  if assigned(fGrids[2]) then EWViewForm.Grid := fGrids[2];
end;

procedure TVolume.Show;
begin
  Update;
  if assigned(TDViewForm) then TDViewForm.Show;
  if assigned(NSViewForm) then NSViewForm.Show;
  if assigned(EWViewForm) then EWViewForm.Show;
end;

procedure TVolume.GetEditData;
var
  CellsInFormat: integer;
begin
  inherited;
  with EditForm as TFVolumeEdit do
    begin
      fBottom   := Bottom;
      fTop      := Top;
      fChannel  := Channel;
      fMeasure  := Measure;
      fLength   := CellH;
      fHeight   := CellV;
      fArea     := PlaneArea(Area1.West  * 1000 div fLength,
                             Area1.South * 1000 div fLength,
                             Area1.East  * 1000 div fLength,
                             Area1.North * 1000 div fLength);
      fMaxCells := round(MaxRange * 1000 / (DataSource as TRadarData).Channel[fChannel].Length);
      CellsInFormat := (DataSource as TRadarData).Channel[fChannel].Cells;
      if fMaxCells > CellsInFormat then
        fMaxCells := CellsInFormat;
    end;
end;

procedure TVolume.SetEditData;
begin
  inherited;
  with EditForm as TFVolumeEdit do
    begin
      Bottom  := fBottom;
      Top     := fTop;
      Channel := fChannel;
      Measure := fMeasure;
      CellH   := fLength;
      CellV   := fHeight;
      with Area1 do
        begin
          West  := fArea.A.X * fLength div 1000;
          South := fArea.A.Y * fLength div 1000;
          East  := fArea.B.X * fLength div 1000;
          North := fArea.B.Y * fLength div 1000;
        end;
      MaxRange := round(fMaxCells * (DataSource as TRadarData).Channel[fChannel].Length / 1000);
    end;
end;

procedure TVolume.ProcessMove( S : TScan );
var
  RR, AA : integer;
  Y1, Y2 : integer;
  X1, X2 : integer;
  V, C   : TCode;
  I      : integer;
  Cosine : double;
  HRay   : THeightRay;
  SRay   : THeightRay;
  Radius : longint;
  Range  : boolean;
begin
  if S is TPPIScan
    then
      with S as TPPIScan do
        begin
          Cosine := cos(DegreeToRadian * CodeAngle(Angle));
          HRay   := fHeightTable.Ray[Angle];
          SRay   := fScanHeight. Ray[Angle];
          for RR := 0 to MaxCells - 1 do
            begin
              Range := (SRay[RR].Max >= fBottom) and
                       (SRay[RR].Min <= fTop);
              Radius := round(RR * Cosine);
              with HRay[RR] do
                begin
                  Y1 := Min;
                  if Angle < fHighestAngle
                    then Y2 := Max
                    else Y2 := Min + round((Max - Min) * fLocation);
                  X1 := Y1;
                  X2 := Y2;
                end;
              if Y1 < fGrids[1].Origin.Y then Y1 := fGrids[1].Origin.Y;
              if Y2 > fGrids[1].Ending.Y then Y2 := fGrids[1].Ending.Y;
              if X1 < fGrids[2].Origin.X then X1 := fGrids[2].Origin.X;
              if X2 > fGrids[2].Ending.X then X2 := fGrids[2].Ending.X;
              for AA := Origin.A to Ending.A do
                with fPRTable.Polar2Grid[RR, AA] do
                  if Cell[RR, AA] <> NODATA then
                  begin
                    C := Cell[RR, AA];
                    if Range
                      then
                        begin
                          V := fTDScan[Radius, AA];
                          if (V = NoData) or (C > V)
                            then fTDScan[Radius, AA] := C;
                        end;
                    if InArea(fArea, X, Y)
                      then
                        begin
                          for I := Y1 to Y2 do
                            begin
                              V := fGrids[1][X, I];
                              if (V = NoData) or (C > V)
                                then fGrids[1][X, I] := C;
                            end;
                         for I := X1 to X2 do
                           begin
                             V := fGrids[2][I, Y];
                             if (V = NoData) or (C > V)
                               then fGrids[2][I, Y] := C;
                           end;
                        end;
                  end;
            end;
        end;
  DoNotify;
end;

function TVolume.GetViewForm( Index : integer ) : TFGrid;
begin
  if not fDisabled[Index] and (fViewForms[Index] = nil)
    then
      begin
        fViewForms[Index] := TFGrid.Create(Self);
        fViewForms[Index].Product  := Self;
        fViewForms[Index].OnClose  := FormClose;
        fViewForms[Index].Tag      := Index;
        fViewForms[Index].Pin.Down := true;
      end;
  Result := fViewForms[Index];
end;

function TVolume.GetTDView : TFGrid;
begin
  Result := GetViewForm(0);
end;

function TVolume.GetNSView : TFGrid;
begin
  Result := GetViewForm(1);
  if assigned(TDViewForm)
    then
      with TDViewForm do
        begin
          Result.Top  := Top + Height;
          Result.Left := Left;
        end;
end;

function TVolume.GetEWView : TFGrid;
begin
  Result := GetViewForm(2);
  if assigned(TDViewForm)
    then
      with TDViewForm do
        begin
          Result.Top  := Top;
          Result.Left := Left + Width;
        end;
end;

procedure TVolume.SetDataSource( D : TDataSource );
begin
  FreeAndNil(fGrids[0]);
  FreeAndNil(fGrids[1]);
  FreeAndNil(fGrids[2]);
  inherited;
end;
  
function TVolume.GetPosition : TPoint;
begin
  with TDViewForm do
    Result := Point(Left + Width, Top);
end;

procedure TVolume.FormClose( Sender : TObject; var Action : TCloseAction );
begin
  Action := caNone;
  Free;
end;

// TVolumeAuto methods

function TVolumeAuto.GetChannel : integer;
begin
  Result := (Product as TVolume).Channel;
end;

function TVolumeAuto.GetMeasure : integer;
begin
  Result := ord((Product as TVolume).Measure);
end;

function TVolumeAuto.GetCellH : integer;
begin
  Result := (Product as TVolume).Length;
end;

function TVolumeAuto.GetEast : integer;
begin
  Result := (Product as TVolume).Area.Right;
end;

function TVolumeAuto.GetWest : integer;
begin
  Result := (Product as TVolume).Area.Left;
end;

function TVolumeAuto.GetNorth : integer;
begin
  Result := (Product as TVolume).Area.Top;
end;

function TVolumeAuto.GetSouth : integer;
begin
  Result := (Product as TVolume).Area.Bottom;
end;

function TVolumeAuto.GetTop : integer;
begin
  Result := (Product as TVolume).Top;
end;

function TVolumeAuto.GetBottom : integer;
begin
  Result := (Product as TVolume).Bottom;
end;

function TVolumeAuto.GetCellV : integer;
begin
  Result := (Product as TVolume).CellHeight;
end;

procedure TVolumeAuto.SetChannel( Ch : integer );
begin
  (Product as TVolume).Channel := Ch;
end;

procedure TVolumeAuto.SetMeasure( M : integer );
begin
  (Product as TVolume).Measure := TMeasure(M);
end;

procedure TVolumeAuto.SetCellH( C : integer );
begin
  (Product as TVolume).Length := C;
end;

procedure TVolumeAuto.SetEast( E : integer );
begin
  (Product as TVolume).Area := PlaneArea(GetWest, E, GetNorth, GetSouth);
end;

procedure TVolumeAuto.SetWest( W : integer );
begin
  (Product as TVolume).Area := PlaneArea(W, GetEast, GetNorth, GetSouth);
end;

procedure TVolumeAuto.SetNorth( N : integer );
begin
  (Product as TVolume).Area := PlaneArea(GetWest, GetEast, N, GetSouth);
end;

procedure TVolumeAuto.SetSouth( S : integer );
begin
  (Product as TVolume).Area := PlaneArea(GetWest, GetEast, GetNorth, S);
end;

procedure TVolumeAuto.SetTop( T : integer );
begin
  (Product as TVolume).Top := T;
end;

procedure TVolumeAuto.SetBottom( B : integer );
begin
  (Product as TVolume).Bottom := B;
end;

procedure TVolumeAuto.SetCellV( C : integer );
begin
  (Product as TVolume).CellHeight := C;
end;

end.

