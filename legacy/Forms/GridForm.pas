{$DEFINE NMEA_2010}

unit GridForm;

interface

uses
  SysUtils, Windows, Messages, Classes, Controls,
  Forms, Dialogs, ExtCtrls, Menus, StdCtrls, Graphics,
  Product, Scale, Measure, Border, Region, Plane, Animation,
  Grid, BarGauge, Spin, Buttons, ComCtrls, ToolWin, ImgList,
  FormAuto, ScanGrid, Angle, WindScan, WindPPIScan, WindGrid,
  Scan, PPIScan, DirMonitor, StrUtils;

const
  CircCount = 10;

type
  TFGrid = class(TForm)
    Panel2: TPanel;
    MainMenu1: TMainMenu;
    Vista1: TMenuItem;
    Exploracion1: TMenuItem;
    Archivo1: TMenuItem;
    Salvar1: TMenuItem;
    SaveDialog1: TSaveDialog;
    Edit1: TEdit;
    Escala1: TMenuItem;
    Imagen1: TMenuItem;
    Llenaralto1: TMenuItem;
    Llenarancho1: TMenuItem;
    N2: TMenuItem;
    Ampliar1: TMenuItem;
    Reducir1: TMenuItem;
    Label1: TLabel;
    Tamaoreal1: TMenuItem;
    Cuadriculas1: TMenuItem;
    Radios1: TMenuItem;
    Ajustar1: TMenuItem;
    GuiadeCorte1: TMenuItem;
    Fronteras1: TMenuItem;
    ColorDialog1: TColorDialog;
    Salvar2: TMenuItem;
    N1: TMenuItem;
    Reporte1: TMenuItem;
    Cortar1: TMenuItem;
    Copiar1: TMenuItem;
    UpDown1: TUpDown;
    Panel4: TPanel;
    PopupMenu1: TPopupMenu;
    MenuItem1: TMenuItem;
    Insertar1: TMenuItem;
    Eliminar1: TMenuItem;
    MenuItem2: TMenuItem;
    Abrir1: TMenuItem;
    Salvar3: TMenuItem;
    MenuItem4: TMenuItem;
    Titulos1: TMenuItem;
    Valores1: TMenuItem;
    Splitter1: TSplitter;
    Editar1: TMenuItem;
    SaveDialog2: TSaveDialog;
    OpenDialog1: TOpenDialog;
    Imprimir1: TMenuItem;
    Climatologia1: TMenuItem;
    ToolBar1: TToolBar;
    ImageList1: TImageList;
    ToolButton1: TToolButton;
    Timer1: TTimer;
    ToolBar2: TToolBar;
    Pin: TSpeedButton;
    TrackBar1: TTrackBar;
    Panel3: TPanel;
    SpeedButton1: TSpeedButton;
    ScrollBar2: TScrollBar;
    ScrollBar1: TScrollBar;
    Recortar1: TMenuItem;
    PaintBox1: TPaintBox;
    N5: TMenuItem;
    Topografia1: TMenuItem;
    Radar1: TMenuItem;
    Editar2: TMenuItem;
    Fronteras2: TMenuItem;
    Cuadriculas2: TMenuItem;
    Climatologa2: TMenuItem;
    Radios2: TMenuItem;
    N3: TMenuItem;
    Suavizar1: TMenuItem;
    N4: TMenuItem;
    Perfil1: TMenuItem;
    SpeedButton2: TSpeedButton;
    Panel1: TPanel;
    Label2: TLabel;
    Edit2: TEdit;
    UpDown2: TUpDown;
    Label6: TLabel;
    Bevel1: TBevel;
    Splitter2: TSplitter;
    Bevel2: TBevel;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    Label3: TLabel;
    Edit3: TEdit;
    UpDown3: TUpDown;
    Label11: TLabel;
    x: TEdit;
    UpDown4: TUpDown;
    Distancia1: TMenuItem;
    CalcularDistancia1: TMenuItem;
    Distancia2: TMenuItem;
    RejillaLatLon1: TMenuItem;
    RejillaLatiudLongitud1: TMenuItem;
    NMEA: TMenuItem;
    DirMonitor1: TDirMonitor;
    ATTEXRusia1: TMenuItem;
    Circulo1: TMenuItem;
    Crculo1: TMenuItem;
    ReconstruirTrayectoria1: TMenuItem;
    procedure MenuItemClick(Sender: TObject);
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure Panel2Resize(Sender: TObject);
    procedure Edit1Exit(Sender: TObject);
    procedure Llenaralto1Click(Sender: TObject);
    procedure Llenarancho1Click(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure ScrollBarScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure Salvar1Click(Sender: TObject);
    procedure Tamaoreal1Click(Sender: TObject);
    procedure Cuadriculas2Click(Sender: TObject);
    procedure Radios2Click(Sender: TObject);
    procedure Ajustar1Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure GuiadeCorte1Click(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormDestroy(Sender: TObject);
    procedure Fronteras1Click(Sender: TObject);
    procedure Fronteras2Click(Sender: TObject);
    procedure Regiones2Click(Sender: TObject);
    procedure Cortar1Click(Sender: TObject);
    procedure Reporte1Click(Sender: TObject);
    procedure Copiar1Click(Sender: TObject);
    procedure Edit1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UpDown1Click(Sender: TObject; Button: TUDBtnType);
    procedure Ampliar1Click(Sender: TObject);
    procedure Reducir1Click(Sender: TObject);
    procedure Panel4Resize(Sender: TObject);
    procedure LookClick(Sender: TObject);
    procedure Abrir1Click(Sender: TObject);
    procedure Salvar3Click(Sender: TObject);
    procedure Insertar1Click(Sender: TObject);
    procedure Eliminar1Click(Sender: TObject);
    procedure Editar1Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure Imprimir1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Climatologa2Click(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure Panel3Resize(Sender: TObject);
    procedure Recortar1Click(Sender: TObject);
    function  GetFormImage : TBitmap;
    function  GetExportableImage : TBitmap;
    procedure Escala1Click(Sender: TObject);
    procedure Suavizar1Click(Sender: TObject);
    procedure Splitter1CanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure SpeedButton2Click(Sender: TObject);
    procedure CalculateWinds;
    procedure Edit2Change(Sender: TObject);
    procedure UpDown3Click(Sender: TObject; Button: TUDBtnType);
    procedure UpDown2Changing(Sender: TObject; var AllowChange: Boolean);
    procedure Siembra1Click(Sender: TObject);
    procedure Distancia1Click(Sender: TObject);
    procedure Distancia2Click(Sender: TObject);
    procedure Archivo1Click(Sender: TObject);
    procedure CalcularDistancia1Click(Sender: TObject);
    procedure Vista1Click(Sender: TObject);
    procedure Perfil1Click(Sender: TObject);
    procedure RejillaLatiudLongitud1Click(Sender: TObject);
    procedure DirMonitor1Change(sender: TObject; Action: TAction;
      FileName: String);
    procedure ATTEXRusia1Click(Sender: TObject);
    procedure Crculo1Click(Sender: TObject);
    procedure DispositivoNMEA1Click(Sender: TObject);
    procedure ReconstruirTrayectoria1Click(Sender: TObject);
  protected
    fEnableProfileMark: boolean;
    fWindGrid: TWindGrid;
    fEnableWind: boolean;
    fWindLength: integer;
    fProfileMark: TPoint;
//    property OnClose;
  public
    fCirCenter    : array[0..CircCount - 1] of TPoint;
    fCirRad       : array[0..CircCount - 1] of integer;
    fCirShowCenter: array[0..CircCount - 1] of boolean;
    fCirShowNumber: array[0..CircCount - 1] of boolean;
    fCirColor     : array[0..CircCount - 1] of TColor;
    fCirShow      : array[0..CircCount - 1] of boolean;
    fCirShowRad   : array[0..CircCount - 1] of boolean;
    fCirUseOther  : array[0..CircCount - 1] of boolean;
    fCirOther     : array[0..CircCount - 1] of integer;
    fEnableMovMark1, fEnableMovMark2: boolean;
    procedure SaveData        ( const FileName : string );
  public
    procedure SavePrdData     ( const FileName : string; Format : TFileFormat );
    procedure SaveAnmData     ( const FileName : string; Format : TFileFormat );
    procedure SaveAnmFrames   ( const FileName : string; Format : TFileFormat );
  protected
    procedure SaveBMPImage    ( const FileName : string );
    procedure SaveGIFImage    ( const FileName : string );
    procedure SaveJPGImage    ( const FileName : string );
    procedure SaveProduct     ( const FileName : string );
    procedure SaveAnimation   ( const FileName : string );
    procedure SaveCSVFile     ( const FileName : string );
    procedure SaveCDFFile     ( const FileName : string );
    procedure SaveBinFile     ( const FileName : string );
    procedure SaveGIFAnimation( const FileName : string );
  private
    fGrid       : TGrid;
    fDisplayGrid: TGrid;
    fCenter     : T2DLocation;
    fGridScale  : TScale;
    fZoom       : integer;
    fGWidth     : integer;
    fGHeight    : integer;
    fMaxZoom    : integer;
    fMinZoom    : integer;
    fWinGDC      : HDC;
    fWinGBitmap  : HBitmap;
    fOriginalBM  : HBitmap;
    fWinGBMInfo  : PBitmapInfo;
    fWinGBMBits  : pointer;
    fBordersBM   : TBitmap;
    fRegionsBM   : TBitmap;
    fBackBitmap  : TBitmap;
    fBuffBitmap  : TBitmap;
    GL, GT, GW, GH : integer;
    PL, PT, PW, PH : integer;
    PPMW, PPMH : double;
    fClmGap : TPoint;
    fGrdGap : TPoint;
    fRadGap : TPoint;
    fLatLonGap: T2DLocation;
    fClmColor : TColor;
    fGrdColor : TColor;
    fRadColor : TColor;
    fLatLonColor: TColor;
    fCenterPos : TPoint;
    fCutOrg : TPoint;
    fCutEnd : TPoint;
    fBorders : TList;
    fRegions : TList;
    fAreas   : TList;
    fProduct : TProduct;
    fRH_lat,
    fRH_lon: single;
    fRH_name: string;
    procedure CreateBitmap;
    procedure RemoveBitmap;
    procedure RemoveDC;
    procedure RemoveScale;
    procedure RemoveAll;
    procedure SetGrid      ( aGrid : TGrid );
    procedure SetZoom      ( aZoom : integer );
    procedure FillBitmapInfo;
    procedure FillBitmap;
    procedure UpdateZoom;
    procedure SetScale ( aScale : TScale );
    procedure PaintBorder      ( aCanvas : TCanvas; aBorder : TBorder );
    procedure PaintArea        ( aCanvas : TCanvas; anArea  : TArea );
    procedure PaintGrdGrate    ( aCanvas : TCanvas; aGap : TPoint; aColor : TColor );
    procedure PaintGeoGrate    ( aCanvas : TCanvas; aGap: T2DLocation; aColor: TColor);
    procedure PaintRadGrate    ( aCanvas : TCanvas );
    procedure PaintCircle    ( aCanvas : TCanvas; aCenter : TPoint; aRadio, aNumber: integer; aColor : TColor; ShowCenter, ShowNumber, ShowRad: boolean );
    procedure PaintCut         ( aCanvas : TCanvas );
    procedure PaintMovMark     ( aCanvas : TCanvas; aPoint : TPoint; aText: string);
    procedure PaintProfileMark ( aCanvas : TCanvas; aPoint : TPoint);
    procedure PaintWind        ( aCanvas : TCanvas );
    procedure PaintNMEA        ( aCanvas : TCanvas; RealTime: boolean );
    procedure PaintExpl        ( aCanvas : TCanvas );
    procedure PaintRadar       ( aCanvas : TCanvas );
    function  Box2Grid     ( aPoint  : TPoint ) : TPoint;
    function  Grid2Box     ( aPoint  : TPoint ) : TPoint;
    function  Grid2Polar   ( aPoint  : TPoint ) : TPoint;
    function  Grid2Loc     ( aPoint  : TPoint ) : T2DLocation;
    function  Loc2Box      (aLoc: T2Dlocation): TPoint;
    function  Loc2Cart     (aLoc: T2Dlocation): TPoint;
    function  XFromAngle   ( aRadius, anAngle : single): integer;
    function  YFromAngle   ( aRadius, anAngle : single): integer;
    function  Box2Meter    ( aPoint   : TPoint ) : TPoint;
    procedure SetCutOrg    ( aCutOrg  : TPoint );
    procedure SetCutEnd    ( aCutEnd  : TPoint );
    procedure SetProfileMark( aProfileMark : TPoint );
    procedure UpdateProfile( aPoint: TPoint);
    procedure ReleaseAreas;
    procedure SetProduct   ( aProduct : TProduct );
    procedure CheckCoordinates;
    procedure PanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DrawCaption  ( BM : TBitmap );
    procedure DrawCopyright( BM : TBitmap );
    procedure DrawScale    ( BM : TBitmap );
//    procedure DrawProfile
  public
    procedure ReleaseBorders;
    procedure ReleaseRegions;
    procedure UpdateBordersMenu;
    procedure UpdateRegionsMenu;
    procedure UpdateTreeAreas;
    property Grid    : TGrid    read fGrid      write SetGrid;
    property Scale   : TScale   read fGridScale write SetScale;
    property Zoom    : integer  read fZoom      write SetZoom;
    property ClmGap  : TPoint   read fClmGap    write fClmGap;
    property GrdGap  : TPoint   read fGrdGap    write fGrdGap;
    property RadGap  : TPoint   read fRadGap    write fRadGap;
    property CutOrg  : TPoint   read fCutOrg    write SetCutOrg;
    property CutEnd  : TPoint   read fCutEnd    write SetCutEnd;
    property Product : TProduct read fProduct   write SetProduct;
    property ProfileMark : TPoint read fProfileMark  write SetProfileMark;
  private
    fCutOrgDrag : boolean;
    fCutEndDrag : boolean;
    fMovMark1Drag : boolean;
    fMovMark2Drag : boolean;
    fProfileDrag : boolean;
    fCutProduct : TProduct;
    fClicked    : TPanel;
    procedure CutDestroy( Sender : TObject );
    procedure UpdateCut;
    procedure CheckCutUpdate;
  public
    procedure Adjust;
    procedure AdjustHorz;
    procedure AdjustVert;
    procedure UpdateMaskBitmap;
    procedure UpdateBackBitmap;
    procedure UpdateBuffBitmap;
  private
    fAnimation : TAnimation;
    fPlaying   : boolean;
    fFormAuto  : TFormAuto;
    function  GetFormAuto : TFormAuto;
    function  GetOleObject : variant;
    function  GetPosition : integer;
    procedure SetAnimation( A : TAnimation );
    procedure SetPosition( P : integer );
    procedure AnimationDestroy ( Sender : TObject );
    procedure CheckAnimationSave;
  public
    property Animation : TAnimation read fAnimation  write SetAnimation;
    property Playing   : boolean    read fPlaying;
    property Position  : integer    read GetPosition write SetPosition;
    property FormAuto  : TFormAuto  read GetFormAuto write fFormAuto;
    property OleObject : variant    read GetOleObject;
  end;

var
  FGrid: TFGrid;

type
  TAreaEntry = class
    Selected : boolean;
    Area     : TArea;
    constructor Create( A : TArea );
  end;

type
  EGIF = class(Exception);

implementation

{$R *.DFM}

uses
  Clipbrd, Math, CommCtrl, DateUtils,
  Settings,
  Scales, Borders, Regions, Products, Cut, GridProduct,
  VestaPlane,
  TreeImages,
  ScaleEditForm,
  GapForm,
  ObservationForm, Shell_Process,
  Report, ReportEdit,
  JPeg,
  GIFImage,
  NetCDF,
  GridAuto, AnimationAuto,
  Topography,
  VersionInfo,
  TimeUtils,
  UtStr,
  ProfileVector,
  Observation, CalMovForm, HorzProduct, PRTable, Description,
  CalcFunctions, SowForm, VertProduct, CircleEditForm, EditNMEAForm;

const
  SpinDelta = 0.1;  // 10%

const
  GrdMinDelta = 10;
  RadMinDelta = 10;

const
  AnHour  = 1/24;
  CutSize = 4;
  MovMarkSize = 5;
  ProfSize = 5;

const
  GIFAnimExt    = '.gfa';  // used for specifying an animated GIF
  GIFFrameExt   = '.gfi';  // single frame GIF

const
  PrdFilter = ProductFilter   + '|' +
              NetCDFFilter    + '|' +
              BinaryFilter    + '|' +
              ImagesFilter    + '|' +
              TableFilter;
  AnmFilter = AnimationFilter + '|' +
              GIFAnimFilter   + '|' +
              ProductFilter   + '|' +
              NetCDFFilter    + '|' +
              BinaryFilter    + '|' +
              ImagesFilter    + '|' +
              TableFilter;

const
  TmpAnimPrefix = 'Tmp';

// TAreaEntry methods

  constructor TAreaEntry.Create( A : TArea );
  begin
    inherited Create;
    Area     := A;
    Selected := A.Region.Default;
  end;

// TFGrid methods

procedure TFGrid.SaveData( const FileName : string );
var
  E : string;
  F : TFileFormat;
begin
  E := LowerCase(ExtractFileExt(FileName));
  if E = ProductExt
    then F := ffProduct
  else if (E = NetCDFExt)
    then F := ffNetCDF
  else if (E = BinaryExt)
    then F := ffBinary
  else if E = BitmapExt
    then F := ffBMPImage
  else if (E = JPGExt) or (E = JPEGExt)
    then F := ffJPGImage
  else if (E = CSVExt)
    then F := ffCSVTable
  else if E = AnimationExt
    then F := ffAnimation
  else if (E = GIFFrameExt) or ((E = GIFExt) and not assigned(fAnimation))
    then F := ffGIFImage
  else if (E = GIFAnimExt) or ((E = GIFExt) and assigned(fAnimation))
    then F := ffGIFAnim
  else   F := ffUnknown;
  if assigned(fAnimation)
    then SaveAnmData(FileName, F)
    else SavePrdData(FileName, F);
end;

procedure TFGrid.SavePrdData( const FileName : string; Format : TFileFormat );
begin
  case Format of
    ffProduct  : SaveProduct (FileName);
    ffNetCDF   : SaveCDFFile (FileName);
    ffBinary   : SaveBinFile (FileName);
    ffBMPImage : SaveBMPImage(FileName);
    ffGIFImage : SaveGIFImage(FileName);
    ffJPGImage : SaveJPGImage(FileName);
    ffCSVTable : SaveCSVFile (FileName);
    else
      raise Exception.Create('Formato desconocido: ' + FileName);
  end;
end;

procedure TFGrid.SaveAnmData( const FileName : string; Format : TFileFormat );
begin
  case Format of
    ffAnimation : SaveAnimation(FileName);
    ffGIFAnim   : SaveGIFAnimation(FileName);
    ffProduct..ffCSVTable:
      SaveAnmFrames(FileName, Format);
    else
      raise Exception.Create('Formato desconocido: ' + FileName);
  end;
end;

procedure TFGrid.SaveAnmFrames( const FileName : string; Format : TFileFormat );
var
  I, J, P : integer;
  N, M    : string;
begin
  J := Length(FileName);
  while (J > 0) and (FileName[J] <> '.') do
    dec(J);
  P := Position;
  try
    for I := 1 to Animation.Frames do
      begin
        Position := I - 1;
        M := '_' + PadStrRight(IntToStr(I), '0', 3);
        N := FileName;
        Insert(M, N, J);
        SavePrdData(N, Format);
        Application.ProcessMessages;
      end;
  finally
    Position := P;
  end;
end;

procedure TFGrid.SaveBMPImage( const FileName : string );
begin
  with GetExportableImage do
    try
      SaveToFile(FileName);
    finally
      Free;
    end;
end;

procedure TFGrid.SaveGIFImage( const FileName : string );
var
  FormImage : TBitmap;
begin
  FormImage := GetExportableImage;
  try
    with TGIFImage.Create do
      try
        ColorReduction := rmNone;
        Assign(FormImage);
        SaveToFile(FileName);
      finally
        Free;
      end;
  finally
    FormImage.Free;
  end;
end;

procedure TFGrid.SaveJPGImage( const FileName : string );
var
  JPegImage : TJPegImage;
  FormImage : TBitmap;
begin
  JPegImage := TJPegImage.Create;
  try
    FormImage := GetExportableImage;
    try
      JPegImage.Assign(FormImage);
    finally
      FormImage.Free;
    end;
    JPegImage.SaveToFile(FileName);
  finally
    JPegImage.Free;
  end;
end;

procedure TFGrid.SaveProduct( const FileName : string );
var
  S : TStream;
begin
  S := TFileStream.Create(FileName, fmCreate);
  try
    with TWriter.Create(S, 4096) do
      try
        WriteRootComponent(Product);
      finally
        Free;
      end;
  finally
    S.Free;
  end;
end;

procedure TFGrid.SaveAnimation( const FileName : string );
begin
  if assigned(fAnimation)
    then fAnimation.Save(FileName);
end;

procedure TFGrid.SaveCSVFile( const FileName : string );
begin
  Grid.SaveCSV(FileName);
end;

procedure TFGrid.SaveCDFFile( const FileName : string );
type
  PFloatArray = ^TFloatArray;
  TFloatArray = array[0..0] of single;
var
  NCID : integer;
  ID_Dim: array[0..1] of integer;
  ID_Grid : integer;
  S : string;
  I, J, K : integer;
  F : single;
  Msr : TMeasure;
  Count : integer;
  Data  : PFloatArray;
begin
  if nc_create(pchar(FileName), NC_NOFILL, NCID) = 0
    then
      try
        Msr := Grid.Measure;
        // Global attributes
        S := Product.Name;
        nc_put_att_text(NCID, NC_GLOBAL, 'Name', Length(S), pchar(S));
        S := Product.Description;
        nc_put_att_text(NCID, NC_GLOBAL, 'Description', Length(S), pchar(S));
        S := Product.Brief;
        nc_put_att_text(NCID, NC_GLOBAL, 'Brief', Length(S), pchar(S));
        F := Grid.Center.Longitude;
        nc_put_att_float(NCID, NC_GLOBAL, 'Longitude', NC_FLOAT, 1, F);
        F := Grid.Center.Latitude;
        nc_put_att_float(NCID, NC_GLOBAL, 'Latitude', NC_FLOAT, 1, F);
        S := DateTimeToStr(Grid.Time);
        nc_put_att_text(NCID, NC_GLOBAL, 'Date', Length(S), pchar(S));
        I := YearOf(Grid.Time);
        nc_put_att_int(NCID, NC_GLOBAL, 'Year', NC_INT, 1, I);
        I := MonthOf(Grid.Time);
        nc_put_att_int(NCID, NC_GLOBAL, 'Month', NC_INT, 1, I);
        I := DayOf(Grid.Time);
        nc_put_att_int(NCID, NC_GLOBAL, 'Day', NC_INT, 1, I);
        I := HourOf(Grid.Time);
        nc_put_att_int(NCID, NC_GLOBAL, 'Hour', NC_INT, 1, I);
        I := MinuteOf(Grid.Time);
        nc_put_att_int(NCID, NC_GLOBAL, 'Minute', NC_INT, 1, I);
        I := SecondOf(Grid.Time);
        nc_put_att_int(NCID, NC_GLOBAL, 'Second', NC_INT, 1, I);
        // Dimmensions
        nc_def_dim(NCID, 'X', Grid.Width,  ID_Dim[1]);
        nc_def_dim(NCID, 'Y', Grid.Height, ID_Dim[0]);
        // Variable
        S := MeasureVar(Msr);
        nc_def_var(NCID, pchar(S), NC_FLOAT, 2, ID_Dim, ID_Grid);
        // Variable attributes
        I := ord(Msr);
        S := MeasureName(Msr);
        nc_put_att_text(NCID, ID_Grid, 'Units', Length(S), pchar(S));
        I := (Product as TGridProduct).Length;
        nc_put_att_int(NCID, ID_Grid, 'Length', NC_INT, 1, I);
        I := (Product as TGridProduct).Area.A.X;
        nc_put_att_int(NCID, ID_Grid, 'A.X', NC_INT, 1, I);
        I := (Product as TGridProduct).Area.A.Y;
        nc_put_att_int(NCID, ID_Grid, 'A.Y', NC_INT, 1, I);
        I := (Product as TGridProduct).Area.B.X;
        nc_put_att_int(NCID, ID_Grid, 'B.X', NC_INT, 1, I);
        I := (Product as TGridProduct).Area.B.Y;
        nc_put_att_int(NCID, ID_Grid, 'B.Y', NC_INT, 1, I);
        //...
        nc_enddef(NCID);
        //...
        Count := Grid.Width * Grid.Height;
        GetMem(Data, Count * sizeof(single));
        try
{          for I := 0 to Count - 1 do
            if Grid.Cells[I] <= MaxCode
              then Data[I] := CodeMeasure(Grid.Cells[I], Msr)
              else Data[I] := CodeMeasure(MinCode, Msr);}
          K := 0;
          with Grid do
            for J := Ending.Y downto Origin.Y do
              for I := Origin.X to Ending.X do
                begin
                  if Grid.Cell[I, J] <= MaxCode
                    then Data[K] := CodeMeasure(Grid.Cell[I, J], Msr)
                  else Data[K] := CodeMeasure(MinCode, Msr);
                  Inc(K);
                end;
          nc_put_var_float(NCID, ID_Grid, Data^[0]);
        finally
          FreeMem(Data);
        end;
        //...
      finally
        nc_close(NCID);
      end;
end;

procedure TFGrid.SaveBinFile( const FileName : string );
begin
  Grid.SaveBinary(FileName);
end;

procedure TFGrid.SaveGIFAnimation( const FileName : string );
var
  I, P, R : integer;
  Image   : TBitmap;
  Ext     : TGIFGraphicControlExtension;
  LoopExt : TGIFAppExtNSLoop;
begin
  P := Position;
  with TGIFImage.Create do
    try
      ColorReduction := rmNone;
      for I := 0 to Animation.Frames - 1 do
        begin
          Position := I;
          Image := GetExportableImage;
          try
            R := Add(Image);
            if I = 0
              then
                begin
                  LoopExt := TGIFAppExtNSLoop.Create(Images[R]);
                  LoopExt.Loops := 0;
                  Images[R].Extensions.Add(LoopExt);
                end;
            Ext := TGIFGraphicControlExtension.Create(Images[R]);
            Ext.Delay := theSettings.DefaultAnmDelay div 10;  // Animation delay
            Images[R].Extensions.Add(Ext);
          finally
            Image.Free;
          end;
          Application.ProcessMessages;
        end;
      OptimizeColorMap;
      Optimize([ooCrop, {ooMerge,} ooCleanup, ooColorMap], rmNone, dmNearest, 0);
      SaveToFile(FileName);
    finally
      Position := P;
      Free;
    end;
end;

procedure TFGrid.DrawCaption( BM : TBitmap );
var
  Caption : string;
begin
  if assigned(BM)
    then
      begin
        Caption := fProduct.PrdLabel + ' ' +
                   FormatDateTime(' d"/"mm"/"yy hh":"nn "Z"', LocalTimeToZTime(fGrid.Time));
        with BM.Canvas do
          begin
            Font.Name   := 'MS Sans Serif';
            Font.Size   := 8;
            Font.Style  := [fsBold];
            Brush.Style := bsClear;
            Font.Color  := clBlack;
            TextOut(1, 0, Caption);
            TextOut(1, 1, Caption);
            TextOut(1, 2, Caption);
            TextOut(2, 0, Caption);
            TextOut(2, 2, Caption);
            TextOut(3, 0, Caption);
            TextOut(3, 1, Caption);
            TextOut(3, 2, Caption);
            Font.Color  := clWhite;
            TextOut(2, 1, Caption);
          end;
      end;
end;

procedure TFGrid.DrawCopyright( BM : TBitmap );
var
  S    : string;
  X, Y : integer;
  C    : TSize;
begin
  if assigned(BM)
    then
      begin
        X := BM.Width;
        Y := BM.Height;
        S := 'Vesta ' + VersionToStr(FileVersion) + ' (c) LDT [µP]';
        with BM.Canvas do
          begin
            Font.Name   := 'Arial';
            Font.Size   := 8;
            Font.Style  := [fsBold];
            Brush.Style := bsClear;
            Font.Color  := clBlack;
            C := TextExtent(S);
            X := Max(3, X - C.CX - 3);
            Y := Max(3, Y - C.CY - 2);
            TextOut(X - 1, Y - 1, S);
            TextOut(X - 1, Y + 0, S);
            TextOut(X - 1, Y + 1, S);
            TextOut(X + 0, Y - 1, S);
            TextOut(X + 0, Y + 1, S);
            TextOut(X + 1, Y - 1, S);
            TextOut(X + 1, Y + 0, S);
            TextOut(X + 1, Y + 1, S);
            Font.Color  := clWhite;
            TextOut(X + 0, Y + 0, S);
          end;
      end;
end;

procedure TFGrid.DrawScale( BM : TBitmap );
begin
  if assigned(BM)
    then
      begin
      //...
      end;
end;

function TFGrid.GetExportableImage : TBitmap;
begin
  Result := TBitmap.Create;
  try
    Result.Assign(fBuffBitmap);
    if theSettings.ShowImgCaptions
      then DrawCaption(Result);
    if theSettings.ShowImgCopyrights
      then DrawCopyright(Result);
    if theSettings.ShowImgScale
      then DrawScale(Result);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TFGrid.GetFormImage : TBitmap;
begin
  try
    Result := GetExportableImage;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure TFGrid.CreateBitmap;
begin
  if fWinGBitmap = 0
    then
      begin
        FillBitmapInfo;
        fWinGBitmap := CreateDIBSection(fWinGDC, fWinGBMInfo^,
                                        DIB_RGB_COLORS, fWinGBMBits,
                                        0, 0);
        fOriginalBM := SelectObject(fWinGDC, fWinGBitmap);
      end;
  if fWingBitMap <> 0
    then FillBitmap
    else RemoveAll;
end;

procedure TFGrid.RemoveBitmap;
begin
  if fWinGBitmap <> 0
    then
      begin
        if fOriginalBM <> 0
          then SelectObject(fWinGDC, fOriginalBM);
        DeleteObject(fWinGBitmap);
        fWinGBitmap := 0;
      end;
end;

procedure TFGrid.RemoveDC;
begin
  if fWinGDC <> 0
    then
      begin
        DeleteDC(fWinGDC);
        fWinGDC := 0;
      end;
end;

procedure TFGrid.RemoveScale;
begin
  if assigned(fGridScale)
    then
      begin
        fGridScale.Release;
        fGridScale := nil;
      end;
end;

procedure TFGrid.RemoveAll;
begin
  RemoveBitmap;
  RemoveDC;
  RemoveScale;
  Label1.Caption := '';
  Salvar1.Enabled := false;
end;

procedure TFGrid.ReleaseBorders;
var
  I : integer;
begin
  if assigned(fBorders)
    then
      begin
        for I := fBorders.Count - 1 downto 0 do
          Borders.Release(TBorder(fBorders[I]));
        fBorders.Clear;
      end;
end;

procedure TFGrid.ReleaseRegions;
var
  I : integer;
begin
  if assigned(fRegions)
    then
      begin
        for I := fRegions.Count - 1 downto 0 do
          Regions.Release(TRegion(fRegions[I]));
        fRegions.Clear;
      end;
end;

procedure TFGrid.ReleaseAreas;
var
  I : integer;
begin
  if assigned(fAreas)
    then
      begin
        for I := fAreas.Count - 1 downto 0 do
          TAreaEntry(fAreas[I]).Free;
        fAreas.Clear;
      end;
end;

procedure TFGrid.SetProduct( aProduct : TProduct );
begin
  fProduct := aProduct;
  GetProductLargeIcon(aProduct, Icon);
  Label1.Caption := fProduct.Brief;
  Label1.Hint    := Label1.Caption;
  Radar1.Enabled := not (fProduct is TCut);
  Radar1.Checked := Radar1.Checked and Radar1.Enabled;
  if fProduct is TVertProduct then
    begin
      Cuadriculas1.Caption := 'Rejilla Vertical';
      Cuadriculas2.Caption := Cuadriculas1.Caption;
      Climatologia1.Visible := false;
      Climatologa2.Visible := Climatologia1.Visible;
      Radios1.Visible := false;
      Radios2.Visible := Radios1.Visible;
      Cuadriculas1.Checked  := theSettings.ShowVerticalGrid;
      Climatologia1.Checked := false;
      Radios1.Checked       := false;
    end
end;

procedure TFGrid.UpdateBordersMenu;
var
  I, C : integer;
  M    : TMenuItem;
begin
  C := 0;
  with Fronteras1 do
    for I := Count - 1 downto 0 do
      Remove(Items[I]);
  with Fronteras2 do
    for I := Count - 1 downto 0 do
      Remove(Items[I]);
  ReleaseBorders;
  if fGrid.Kind = pkHorizontal
    then
      for I := 0 to Borders.Count - 1 do
        with Borders.GetReference(I) do
          if (Center.Longitude = fGrid.Center.Longitude) and
             (Center.Latitude  = fGrid.Center.Latitude)
            then
              begin
                M := TMenuItem.Create(Self);
                M.Caption := Name;
                M.Checked := Default;
                M.OnClick := Fronteras1Click;
                M.Tag     := C;
                Fronteras1.Add(M);
                if Default
                  then fBorders.Add(Borders.Find(Center.Longitude, Center.Latitude, C))
                  else fBorders.Add(nil);
                M := TMenuItem.Create(Self);
                M.Caption := Name;
                M.Enabled := Default;
                M.OnClick := Fronteras2Click;
                M.Tag     := C;
                Fronteras2.Add(M);
                inc(C);
              end;
  Fronteras1.Enabled := C > 0;
  Fronteras2.Enabled := C > 0;
end;

procedure TFGrid.UpdateRegionsMenu;

  procedure AddAreas( A : TArea );
  var
    I : integer;
  begin
    fAreas.Add(TAreaEntry.Create(A));
    for I := 0 to A.AreaCount - 1 do
      AddAreas(A.Areas[I]);
  end;

var
  I, C : integer;
  M    : TMenuItem;
  R    : TRegion;
begin
{  with Regiones2 do
    for I := Count - 1 downto 0 do
      Remove(Items[I]);}
  ReleaseRegions;
  ReleaseAreas;
  C := 0;
  if fGrid.Kind = pkHorizontal
    then
      for I := 0 to Regions.Count - 1 do
        with Regions.GetReference(I) do
          if (Center.Longitude = fGrid.Center.Longitude) and
             (Center.Latitude  = fGrid.Center.Latitude)
            then
              begin
                R := Regions.Find(Center.Longitude, Center.Latitude, C);
                fRegions.Add(R);
                AddAreas(R);
                M := TMenuItem.Create(Self);
                M.Caption := Name;
                M.OnClick := Regiones2Click;
                M.Tag     := C;
{                Regiones2.Add(M);}
                inc(C);
              end;
end;

procedure TFGrid.UpdateMaskBitmap;
var
  I : integer;
  L : PPointerList;
begin
  GL := 0;
  PL := 0;
  if fGWidth <= PaintBox1.Width
    then PL := (PaintBox1.Width - PW) div 2
    else GL := ScrollBar1.Position;
  GT := 0;
  PT := 0;
  if fGHeight <= PaintBox1.Height
    then PT := (PaintBox1.Height - PH) div 2
    else GT := ScrollBar2.Position;
  fCenterPos.X := GL + GW div 2;
  fCenterPos.Y := GT + GH div 2;
  // Regions
  with fRegionsBM do
    begin
      Width  := PaintBox1.Width;
      Height := PaintBox1.Height;
      BitBlt(Canvas.Handle, 0, 0, Width, Height,
             0, 0, 0, BLACKNESS);
      L := fAreas.List;
      for I := 0 to fAreas.Count - 1 do
        with TAreaEntry(L^[I]) do
          if Selected
            then PaintArea(Canvas, Area);
      Modified := true;
    end;
  // Borders
  with fBordersBM do
    begin
      Width  := PaintBox1.Width;
      Height := PaintBox1.Height;
      BitBlt(Canvas.Handle, 0, 0, Width, Height,
             0, 0, 0, BLACKNESS);
      for I := 0 to Fronteras1.Count - 1 do
        if Fronteras1.Items[I].Checked
          then PaintBorder(Canvas, fBorders[I]);
      // Radials
      if Radios1.Checked
        then PaintRadGrate(Canvas);
      // Grid
      if Climatologia1.Checked
        then PaintGrdGrate(Canvas, fClmGap, fClmColor);
      if Cuadriculas1.Checked then
        PaintGrdGrate(Canvas, fGrdGap, fGrdColor)
      else if fProduct is TVertProduct then
        PaintGrdGrate(Canvas, Point(0, 0), fGrdColor);
      // Latitud Longitud
      if RejillaLatLon1.Checked then
        PaintGeoGrate(Canvas, fLatLonGap, fLatLonColor);
      // Radar
      if Radar1.Checked
        then PaintRadar(Canvas);
      Modified := true;
      // Círculo
      if Circulo1.Checked then
        for i := 0 to CircCount - 1 do
          if fCirShow[i] then
            begin
              if fCirUseOther[i] then
                PaintCircle(Canvas, fCirCenter[fCirOther[i]], fCirRad[i], i + 1, fCirColor[i], fCirShowCenter[i], fCirShowNumber[i], fCirShowRad[i])
              else
                PaintCircle(Canvas, fCirCenter[i], fCirRad[i], i + 1, fCirColor[i], fCirShowCenter[i], fCirShowNumber[i], fCirShowRad[i])
            end;
    end;
  // Background
  UpdateBackBitmap;
  // Update
  fBuffBitmap.Assign(fBackBitmap);
  UpdateBuffBitmap;
end;

procedure TFGrid.UpdateBackBitmap;
var
  R : TRect;
begin
  with fBackBitmap do
    begin
      Width  := PaintBox1.Width;
      Height := PaintBox1.Height;
      Canvas.Brush.Color := PaintBox1.Color;
      Canvas.Brush.Style := bsSolid;
      Canvas.Pen.style   := psClear;
      Canvas.Rectangle(-1, -1, Width + 1, Height + 1);
      if Topografia1.Enabled and Topografia1.Checked
        then
          begin
            R.TopLeft     := Box2Meter(Point(0, 0));
            R.BottomRight := Box2Meter(Point(Width, Height));
            R.Left   := R.Left   div 1000;
            R.Right  := R.Right  div 1000;
            R.Top    := R.Top    div 1000;
            R.Bottom := R.Bottom div 1000;
            MapTopography(fGrid.Center, fBackBitmap, R, PPMW, PPMH);
          end;
      Modified := true;
    end;
end;

procedure TFGrid.UpdateBuffBitmap;
begin
  with fBuffBitmap do
    begin
      if assigned(fGrid)
        then
          begin
            Canvas.Draw(0, 0, fBackBitmap);
            if Exploracion1.Checked
              then PaintExpl(Canvas);
            Canvas.CopyMode := cmSRCCOPY;
            Canvas.Draw(0, 0, fRegionsBM);  // Transparent Draw
            Canvas.Draw(0, 0, fBordersBM);  // Transparent Draw
            if Guiadecorte1.Checked
              then PaintCut(Canvas);
            if fEnableWind then PaintWind(Canvas);
            if fEnableProfileMark then PaintProfileMark(Canvas, fProfileMark);
            if fEnableMovMark1 then PaintMovMark(Canvas, MovMark1, '1');
            if fEnableMovMark2 then PaintMovMark(Canvas, MovMark2, '2');
            if ATTEXRusia1.Checked then PaintNMEA(Canvas, true);
            if ReconstruirTrayectoria1.Checked then PaintNMEA(Canvas, false);
          end;
    end;
  PaintBox1Paint(PaintBox1);
end;

procedure TFGrid.CheckCoordinates;
var
  P : TPoint;
begin
  if GetCursorPos(P)
    then
      with PaintBox1 do
        begin
          P := ScreenToClient(P);
          if (P.X < Width) and (P.Y < Height)
            then PaintBox1MouseMove(PaintBox1, [], P.X, P.Y);
        end;
end;

procedure TFGrid.SetGrid( aGrid : TGrid );
var
  First : boolean;
  Flag  : boolean;
begin
  First := fGrid = nil;
  Flag  := First or (fGrid <> aGrid);
  if assigned(fGrid)
    then RemoveBitmap;
  if assigned(aGrid)
    then
      begin
        if fWinGDC = 0
          then fWinGDC := CreateCompatibleDC(0);
        if fWinGDC <> 0
          then
            begin
              if (Scale = nil) or (Scale.Measure <> aGrid.Measure)
                then SetScale(Scales.Find(aGrid.Measure));
              fGrid := aGrid;
              CreateBitmap;
            end
          else RemoveAll;
        if assigned(fGrid)
          then
            begin
              //Caption := FormatDateTime('hh":"nn "Z" d"/"mm"/"yy ', LocalTimeToZTime(fGrid.Time)) +
              //           Product.Name;
              if assigned(Animation)
                then Caption := '[' + IntToStr(Animation.Position + 1) + '] ' +
                                FormatDateTime('h:nn-ddddd', fGrid.Time) + ' - ' +
                                Format('%s/%d', [Product.Name, TGridProduct(Product).Channel + 1])
                else Caption := FormatDateTime('h:nn-ddddd', fGrid.Time) + ' - ' +
                                Format('%s/%d', [Product.Name, TGridProduct(Product).Channel + 1]);
              Label1.Caption := Product.Brief;
              Label1.Hint    := Label1.Caption;
              if Flag
                then
                  begin
                    GuiadeCorte1.Enabled := (fGrid.Kind = pkHorizontal) and
                                            assigned(Owner) and
                                            assigned(Owner.Owner) and
                                            (Owner.Owner is TFObservation);
                    Cortar1.     Enabled := GuiadeCorte1.Checked;
                    Perfil1.     Checked := false;
                    fProfileMark.X       := 10;
                    Reporte1.Enabled     := fGrid.Kind = pkHorizontal;
                    Topografia1.Enabled  := (fGrid.Kind = pkHorizontal) and
                                            MapAvailable(fGrid.Center);
                    Salvar1.Enabled      := true;
                    if (fGrid.Center.Longitude <> fCenter.Longitude) or
                       (fGrid.Center.Latitude  <> fCenter.Latitude)
                      then
                        begin
                          UpdateBordersMenu;
                          UpdateRegionsMenu;
                          fCenter := fGrid.Center;
                        end;
                    if (fClmGap.X = 0) and (fClmGap.Y = 0)
                      then fClmGap := Point(15, 15);
                    if (fGrdGap.X = 0) and (fGrdGap.Y = 0)
                      then fGrdGap := fGrid.DefaultGap;
                    if (fRadGap.X = 0) and (fRadGap.Y = 0)
                      then fRadGap := fGrid.DefaultGap;
                    //UpdateZoom;  // ???
                    fCenterPos.X := fGrid.Width  div 2;
                    fCenterPos.Y := fGrid.Height div 2;
                    SetZoom(fZoom);
                    if First and Pin.Down
                      then Recortar1Click(Ajustar1);
                    UpdateTreeAreas;
                  end
                else UpdateBuffBitmap;
              CheckCoordinates;
            end;
      end;
end;

procedure TFGrid.SetZoom( aZoom : integer );
begin
  if aZoom < fMinZoom
    then fZoom := fMinZoom
    else
      if aZoom > fMaxZoom
        then fZoom := fMaxZoom
        else fZoom := aZoom;
  if assigned(fGrid)
    then
      begin
        fGWidth  := round(fGrid.Width  * (fZoom/100));
        fGHeight := round(fGrid.Height * (fZoom/100));
        UpdateZoom;
      end;
  UpDown1.Position  := fZoom;
  UpDown1.Increment := trunc(fZoom * SpinDelta) + 1;
  Edit1.Text := IntToStr(fZoom) + '%';
  Edit1.SelectAll;
end;

procedure TFGrid.Adjust;
begin
  if WindowState = wsNormal
    then
      begin
        ClientWidth  := fGWidth  + ClientWidth  - PaintBox1.Width;
        ClientHeight := fGHeight + ClientHeight - PaintBox1.Height;
        if fProduct is TVertProduct then
          begin
            ClientWidth := ClientWidth + 36;
            ClientHeight := ClientHeight + 32;
          end;
      end;
end;

procedure TFGrid.AdjustHorz;
begin
  if WindowState = wsNormal
    then ClientWidth  := fGWidth  + ClientWidth  - PaintBox1.Width;
end;

procedure TFGrid.AdjustVert;
begin
  if WindowState = wsNormal
    then ClientHeight := fGHeight + ClientHeight - PaintBox1.Height;
end;

procedure RenderGrid( Data                : PCellArray;
                      Values              : TPalValues;
                      Surface             : PByteArray;
                      Default             : byte;
                      Size, Width, Height : integer );
var
  RowSize : integer;
  GridRow : PCellArray;
  SurfRow : PByteArray;
  I       : integer;
  Index   : byte;
  Code    : byte;
begin
  RowSize := (Width + 3) and not 3;
  GridRow := @Data^   [Height * Width  ];
  SurfRow := @Surface^[Height * RowSize];
  while Height > 0 do
    begin
      dec(Height);
      dec(PCell(GridRow), Width);
      dec(PByte(SurfRow), RowSize);
      for I := 0 to Width - 1 do
        begin
          Code  := GridRow[I];
          Index := 0;
          while (Index < Size) and (Code > Values[Index]) do
            inc(Index);
          if (Index >= Size)
            then Index := Default;
          SurfRow[I] := Index;
        end;
    end;
end;

procedure TFGrid.FillBitmap;
var
  DisplayGrid: TGrid;
begin
  if not Assigned(fDisplayGrid) then
    fDisplayGrid := TGrid.Create;
  try
    if Suavizar1.Checked then
      fDisplayGrid.Soften(fGrid)
    else
      fDisplayGrid.Assign(fGrid);
    RenderGrid(fDisplayGrid.Cells, fGridScale.Values, fWinGBMBits,
               fGridScale.Size,
               fGridScale.Size, fGrid.Width, fGrid.Height);
  finally
//    DisplayGrid.Free;
  end;
end;

procedure TFGrid.FillBitmapInfo;
var
  I : integer;
  C : longint;
begin
  with fWinGBMInfo.bmiHeader do
    begin
      biSize          := sizeof(fWinGBMInfo.bmiHeader);
      biWidth         := fGrid.Width;
      biHeight        := fGrid.Height;
      biPlanes        := 1;
      biBitCount      := 8;
      biCompression   := 0;
      biXPelsPerMeter := 0;
      biYPelsPerMeter := 0;
      biClrUsed       := fGridScale.Size + 1;
      biClrImportant  := 0;
    end;
  for I := 0 to fGridScale.Size do
    with fWinGBMInfo.bmiColors[I] do
      begin
        if I < fGridScale.Size
          then C := fGridScale.Colors[I]
          else C := fGridScale.Colors[0];
        rgbRed      :=  C and $000000FF;
        rgbGreen    := (C and $0000FF00) shr 8;
        rgbBlue     := (C and $00FF0000) shr 16;
        rgbReserved := 0;
      end;
end;

procedure TFGrid.MenuItemClick(Sender: TObject);
begin
  with Sender as TMenuItem do
    Checked := not Checked;
  UpdateMaskBitmap;
end;

procedure TFGrid.Suavizar1Click(Sender: TObject);
begin
  with Sender as TMenuItem do
    Checked := not Checked;
  FillBitmap;
  UpdateBuffBitmap;
end;

procedure TFGrid.Fronteras1Click(Sender: TObject);
begin
  with Sender as TMenuItem do
    begin
      if Checked
        then
          begin
            Borders.Release(fBorders[Tag]);
            fBorders[Tag] := nil;
          end
        else
          with fGrid do
            fBorders[Tag] := Borders.Find(Center.Longitude, Center.Latitude, Tag);
      Fronteras2[Tag].Enabled := not Checked;
    end;
  MenuItemClick(Sender);
end;

procedure TFGrid.Fronteras2Click(Sender: TObject);
begin
  with ColorDialog1, Sender as TMenuItem do
    begin
      Color := TBorder(fBorders[Tag]).Color;
      if Execute
        then
          begin
            TBorder(fBorders[Tag]).Color := Color;
            UpdateMaskBitmap;
          end;
    end;
end;

procedure TFGrid.Regiones2Click(Sender: TObject);
begin
  with ColorDialog1, Sender as TMenuItem do
    begin
      Color := TRegion(fRegions[Tag]).Color;
      if Execute
        then
          begin
            TRegion(fRegions[Tag]).Color := Color;
            UpdateMaskBitmap;
          end;
    end;
end;

procedure TFGrid.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  P, R : TPoint;
  Code : byte;
  I    : integer;
  S    : string;
  Loc  : T2DLocation;
  Rvor, Avor : real;
begin
  if (assigned(fGrid) and (PW > 0) and (PH > 0))
//    and (X >= 0) and (Y >= 0) and (X <= PaintBox1.Width) and (Y <= PaintBox1.Height)
    then
      begin
        // Drag cut-line?
        R := Box2Grid(Point(X, Y));
        if fCutOrgDrag then CutOrg := R;
        if fCutEndDrag then CutEnd := R;
        // Drag movmarks?
        if fMovMark1Drag then
          begin
            MovMark1 := R;
            MovMark1Loc := Grid2Loc(R);
            UpdateBuffBitmap;
            CheckMovMarks;
          end
        else if fMovMark2Drag then
          begin
            MovMark2 := R;
            MovMark2Loc := Grid2Loc(R);
            UpdateBuffBitmap;
            CheckMovMarks;
          end;
        // Drag Profile
        if fProfileDrag then
          begin
            UpdateProfile(Box2Meter(Point(X, Y)));
            ProfileMark := R;
          end;
        // Status bar
        FShell.StatusBar1.Panels[0].Text := '';
        FShell.StatusBar1.Panels[1].Text := '';
        FShell.StatusBar1.Panels[2].Text := '';
        with fGrid do
          if ((Kind = pkVertical) and
              (R.X >= fGrid.Origin.X) and (R.X <= fGrid.Ending.X) and
              (R.Y >= fGrid.Origin.Y) and (R.Y <= fGrid.Ending.Y)) or
             (Kind = pkHorizontal) then
            begin
              // Panel 0: Cartesian coordinates
              FShell.StatusBar1.Panels[0].Text := FloatToStr(R.X * (Length.X/1000)) + ' km, ' + FloatToStr(R.Y * (Length.Y/1000)) + ' km';
              // Panel 1: Polar coordinates
              P := Grid2Polar(R);
              if Kind = pkVertical
                then
                  case Orientation of
                    goLeftRight:
                      if P.Y <= 90
                        then P.Y := 90 - P.Y
                        else P.Y := P.Y - 270;
                    goTopDown:
                      if P.Y > 90
                        then P.Y := 180 - P.Y;
                    //...
                  end;
              FShell.StatusBar1.Panels[1].Text := IntToStr(P.X) + ' km, ' +
                                                  IntToStr(P.Y) + 'º';
              // Panel 2: Point value
              if (X >= PL) and (X < PL + PW) and
                 (Y >= PT) and (Y < PT + PH)
                then Code := fDisplayGrid[R.X, R.Y]
                else Code := NoData;
              if Code = 0
                then FShell.StatusBar1.Panels[2].Text := '< Sensibilidad'
              else if Code = NoData
                then FShell.StatusBar1.Panels[2].Text := 'Sin dato'
                else FShell.StatusBar1.Panels[2].Text := Format('%8.2f %s', [CodeMeasure(Code, Measure), MeasureName(Measure)]);
              // Panel 3: Geographic coordinates
              if Kind = pkHorizontal
                then
                  begin
                    Loc := Grid2Loc(R);
                    with Loc do
                      FShell.StatusBar1.Panels[3].Text := Format('%dº %.2d'' N, %dº %.2d'' W',
                                                                 [trunc(Latitude), trunc(60 * frac(Latitude)),
                                                                  trunc(Longitude),  trunc(60 * frac(Longitude))]);
                  end
                else
                  FShell.StatusBar1.Panels[3].Text := '';
              // Panel 5: Scale caption
              if Code <= MaxCode
                then FShell.StatusBar1.Panels[5].Text := fGridScale.Caption[fGridScale.Index[Code]]
                else FShell.StatusBar1.Panels[5].Text := '';
              // Panel 4: Cut-line length
              if GuiadeCorte1.Checked
                then
                  begin
                    I := round(sqrt(sqr(fCutEnd.X - fCutOrg.X) + sqr(fCutEnd.Y - fCutOrg.Y)));
                    I := I * fGrid.Length.X div 1000;
                    FShell.StatusBar1.Panels[4].Text := IntToStr(I) + ' km';
                  end;
              // Panel 6: Polar Coordinates from RadioHelp
              if Kind = pkHorizontal then
                begin
                  Rvor := Range(fRH_lat*pi/180, fRH_lon*pi/180, Loc.Latitude*pi/180, Loc.Longitude*pi/180);
                  Avor := Azimut(fRH_lat*pi/180, fRH_lon*pi/180, Loc.Latitude*pi/180, Loc.Longitude*pi/180, Rvor);
                  FShell.StatusBar1.Panels[6].Text := FloatToStrF(Avor, ffFixed, 14, 2) + 'º, ' +
                                                      FloatToStrF(Rvor, ffFixed, 14, 2) + ' km desde ' + fRH_name;
                end
              else
                FShell.StatusBar1.Panels[6].Text := '';
              // Círculo
              if Circulo1.Checked then
                FShell.StatusBar1.Panels[7].Text := ' Círculo 1: ' + IntToStr(fCirCenter[0].X) + ' km, ' + IntToStr(fCirCenter[0].Y) + ' km';
            end;
        // Location
        FShell.RichEdit1.Lines.Clear;
        R := Box2Meter(Point(X, Y));
        for I := 0 to fRegions.Count - 1 do
          begin
            S := TRegion(fRegions[I]).Location(R);
            if S <> ''
              then FShell.RichEdit1.Lines.Add(S);
          end;
        //FShell.RichEdit1.ScrollBy(0, 0);       // Problems in WinXP !!!
      end
    else
      begin
        // Coordinates
        FShell.StatusBar1.Panels[0].Text := '';
        FShell.StatusBar1.Panels[1].Text := '';
        FShell.StatusBar1.Panels[2].Text := '';
        FShell.StatusBar1.Panels[3].Text := '';
        FShell.StatusBar1.Panels[4].Text := '';
        FShell.StatusBar1.Panels[5].Text := '';
        FShell.StatusBar1.Panels[6].Text := '';
        // Location
        FShell.RichEdit1.Clear;
      end;
end;

procedure TFGrid.FormCreate(Sender: TObject);
var
  i: integer;
begin
  GetMem(fWinGBMInfo, sizeof(TBitmapInfoHeader) + 256 * sizeof(TRGBQuad));
  fBuffBitmap := TBitmap.Create;
  fRegionsBM := TBitmap.Create;
  fRegionsBM.Transparent := true;
  fregionsBM.TransparentColor := clBlack;
  fBordersBM := TBitmap.Create;
  fBordersBM.Transparent := true;
  fBordersBM.TransparentColor := clBlack;
  fBackBitmap := TBitmap.Create;
  fMaxZoom := 2000;
  fMinZoom := 0;
  Ampliar1.ShortCut := ShortCut(VK_ADD,      []);
  Reducir1.ShortCut := ShortCut(VK_SUBTRACT, []);
  PaintBox1.Canvas.Brush.Style := bsSolid;
  PaintBox1.Canvas.Pen.Style   := psClear;
  SetZoom(100);
  fClmColor := clGray;
  fGrdColor := clWhite;
  fRadColor := clSilver;
  fCirColor[0] := clWhite;
  fCirColor[1] := clFuchsia;
  fCirColor[2] := clWhite;
  fCirColor[3] := clBlue;
  fCirColor[4] := clBlue;
  fCirColor[5] := clYellow;
  fCirColor[6] := clLime;
  fCirColor[7] := clRed;
  fCirColor[8] := clSilver;
  fCirColor[9] := clGreen;
  for i := 0 to CircCount - 1 do
    begin
      fCirRad[i] := 25;
      fCirCenter[i] := Point(10 + i*10, 10 + i*10);
      fCirShowCenter[i] := false;
      fCirShow[i] := false;
      fCirShowNumber[i] := false;
      fCirShowRad[i] := false;
      fCirUseOther[i] := false;
      fCirOther[i] := 0;
    end;
  fCirShow[0] := true;
  fCirShowCenter[0] := true;
  fCirShow[1] := true;
  fCirRad[1] := 40;
  fCirUseOther[1] := true;
  fCirUseOther[3] := true;
  fCirOther[1] := 0;
  fCirOther[3] := 2;
  fCirShow[2] := false;
  fCirShowCenter[2] := true;
  fCirShow[3] := false;
  fCirRad[3] := 40;
  fCirCenter[2]:= Point(-40, -40);
  fLatLonColor := clWhite;
  fLatLonGap := Location2D(1, 1);
  fBorders := TList.Create;
  fRegions := TList.Create;
  fAreas   := TList.Create;
  // SaveDialog
  SaveDialog1.InitialDir := theSettings.Products;
  SaveDialog1.Filter     := PrdFilter;
  // Menu defaults
  Exploracion1.Checked  := theSettings.ShowExploracion;
  Topografia1.Checked   := theSettings.ShowTopografia;
  Escala1.Checked       := theSettings.ShowEscala;
  Radar1.Checked        := theSettings.ShowRadar;
  Cuadriculas1.Checked  := theSettings.ShowCuadriculas;
  Climatologia1.Checked := theSettings.ShowClimatologia;
  Radios1.Checked       := theSettings.ShowRadios;
  GuiaDeCorte1.Checked  := theSettings.ShowGuiaDeCorte;
  Suavizar1.Checked     := theSettings.ShowImgSuavizar;
  // Scale Panel
  SpeedButton1Click(SpeedButton1);
  fDisplayGrid := TGrid.Create;
  // Radio Help
  fRH_name := settings_RH.Data[theSettings.RadioHelp].Name;
  fRH_lat  := DegreeToDecDegree(settings_RH.Data[theSettings.RadioHelp].Lat);
  fRH_lon  := DegreeToDecDegree(settings_RH.Data[theSettings.RadioHelp].Lon);
end;

procedure TFGrid.FormDestroy(Sender: TObject);
begin
  if assigned(fFormAuto)
    then fFormAuto.Release;
  if assigned(fCutProduct) and (fCutProduct as TCut).ViewForm.Pin.Down
    then FreeAndNil(fCutProduct);
  if FShell.ActiveMDIChild = Self
    then FShell.TreeView1.Items.Clear;
  ReleaseAreas;
  ReleaseRegions;
  ReleaseBorders;
  FreeAndNil(fAreas);
  FreeAndNil(fRegions);
  FreeAndNil(fBorders);
  RemoveAll;
  FreeAndNil(fBuffBitmap);
  FreeAndNil(fBordersBM);
  FreeAndNil(fRegionsBM);
  FreeAndNil(fBackBitmap);
  if Grid1 = Self then Grid1 := nil;
  if Grid2 = Self then Grid2 := nil;
  ReallocMem(fWinGBMInfo, 0);
  FreeAndNil(fWindGrid);
  fDisplayGrid.Free;
  CheckMovMarks;
end;

procedure TFGrid.Panel2Resize(Sender: TObject);
begin
  with Panel2 do
    begin
      Label1.Left   := 0;
      ToolBar1.Left := 0;
      ToolBar2.Left := 0;
      Label1.Width  := Width - Label1.Left;
    end;
end;

procedure TFGrid.Edit1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN : Edit1Exit(Self);
    VK_ESCAPE : SetZoom(fZoom);
    VK_UP     : if ssShift in Shift
                  then SetZoom(fZoom +  1)
                  else SetZoom(fZoom + 10);
    VK_DOWN   : if ssShift in Shift
                  then SetZoom(fZoom -  1)
                  else SetZoom(fZoom - 10);
    VK_PRIOR  : SetZoom(fZoom + UpDown1.Increment);
    VK_NEXT   : SetZoom(fZoom - UpDown1.Increment);
  end;
end;

procedure TFGrid.Edit1Exit(Sender: TObject);
var
  S : string;
  P : integer;
begin
  S := Edit1.Text;
  P := pos('%', S);
  if P > 0 then Delete(S, P, 1);
  SetZoom(StrToIntDef(S, 100));
end;

procedure TFGrid.UpDown1Click(Sender: TObject; Button: TUDBtnType);
begin
  SetZoom((Sender as TUpDown).Position);
end;

procedure TFGrid.Tamaoreal1Click(Sender: TObject);
begin
  SetZoom(100);
end;

procedure TFGrid.Llenaralto1Click(Sender: TObject);
begin
  SetZoom(trunc(141 * (PaintBox1.Height/fGrid.Height)));
end;

procedure TFGrid.Llenarancho1Click(Sender: TObject);
begin
  SetZoom(trunc(141 * (PaintBox1.Width/fGrid.Width)));
end;

procedure TFGrid.PaintBox1Paint(Sender: TObject);
begin
  with PaintBox1 do
    BitBlt(Canvas.Handle,             0, 0, Width - 1, Height - 1,
           fBuffBitmap.Canvas.Handle, 0, 0,
           SRCCOPY);
end;

procedure TFGrid.PaintExpl( aCanvas : TCanvas );
var
  BM : TBitmap;
begin
  BM := TBitmap.Create;
  try
    BM.TransparentColor := Scale.Colors[0];
    BM.Transparent := Topografia1.Checked;
    BM.Width  := PW;
    BM.Height := PH;
    ///////////////////////////////////////////////////////
    //BM.Handle := CreateCompatibleBitmap(fWinGDC, PW, PH);
    // Problems in transparent draw under Win98
    SetStretchBltMode(BM.Canvas.Handle, COLORONCOLOR);
    StretchBlt(BM.Canvas.Handle, 0, 0, PW, PH,
               fWinGDC, GL, GT, GW, GH, SRCCOPY);
    BM.Modified := true;
    aCanvas.CopyMode := cmSRCCOPY;
    aCanvas.Draw(PL, PT, BM);
  finally
    BM.Free;
  end;
end;

procedure TFGrid.PaintRadar( aCanvas : TCanvas );
var
  C : TPoint;
begin
  C := Grid2Box(Classes.Point(0, 0));
  with aCanvas, C do
    begin
      Brush.Style := bsClear;
      Pen.Color := clRed;
      Pen.Style := psSolid;
      Pen.Width := 2;
      Ellipse(X - 3, Y - 3, X + 3, Y + 3);
      MoveTo(X - 4, Y - 4);
      LineTo(X - 2, Y - 2);
      MoveTo(X - 4, Y + 4);
      LineTo(X - 2, Y + 2);
      MoveTo(X + 4, Y - 4);
      LineTo(X + 2, Y - 2);
      MoveTo(X + 4, Y + 4);
      LineTo(X + 2, Y + 2);
      Pen.Width := 1;
    end;
end;

procedure TFGrid.PaintBorder( aCanvas : TCanvas; aBorder : TBorder );
var
  I, J : integer;
  C, P : TPoint;
  L    : TBorderLine;
begin
  with aCanvas, aBorder do
    begin
      Pen.Style := psSolid;
      Pen.Color := Color;
      C := Grid2Box(Classes.Point(0, 0));
      L := nil;
      for J := 0 to Count - 1 do
        begin
          L := Lines[J];
          if Pos(cBorderWord, LineName[J]) > 0 then   // Ciudad
            begin
              C := Grid2Box(Classes.Point(0, 0));
              with L[0] do
                begin
                  P.X := C.X + trunc( X * Length.X * PPMW);
                  P.Y := C.Y + trunc(-Y * Length.Y * PPMH);
                end;
              Brush.Style := bsSolid;
              Brush.Color := $00FFFFFF and (not Pen.Color);;
              Pen.Width := 2;
              Ellipse(P.X - L[1].X div 2, P.Y - L[1].X div 2, P.X + L[1].X div 2, P.Y + L[1].X div 2);
              Pen.Width := 1;
              Brush.Style := bsClear;
              if L[1].Y = 1 then
                Font.Style := [fsBold]
              else if L[1].Y = 0 then
                Font.Style := [];
              Font.Name := 'MS Sans Serif';
              Font.Size := L[1].X;
              Font.Color := $00FFFFFF and (not Pen.Color);
              TextOut(P.X + 1, P.Y    , Copy(LineName[J], System.Length(cBorderWord) + 1, System.Length(LineName[J]) - System.Length(cBorderWord) + 1));
              TextOut(P.X    , P.Y + 1, Copy(LineName[J], System.Length(cBorderWord) + 1, System.Length(LineName[J]) - System.Length(cBorderWord) + 1));
              TextOut(P.X - 1, P.Y    , Copy(LineName[J], System.Length(cBorderWord) + 1, System.Length(LineName[J]) - System.Length(cBorderWord) + 1));
              TextOut(P.X    , P.Y - 1, Copy(LineName[J], System.Length(cBorderWord) + 1, System.Length(LineName[J]) - System.Length(cBorderWord) + 1));
              TextOut(P.X + 1, P.Y + 1, Copy(LineName[J], System.Length(cBorderWord) + 1, System.Length(LineName[J]) - System.Length(cBorderWord) + 1));
              TextOut(P.X + 1, P.Y - 1, Copy(LineName[J], System.Length(cBorderWord) + 1, System.Length(LineName[J]) - System.Length(cBorderWord) + 1));
              TextOut(P.X - 1, P.Y + 1, Copy(LineName[J], System.Length(cBorderWord) + 1, System.Length(LineName[J]) - System.Length(cBorderWord) + 1));
              TextOut(P.X - 1, P.Y - 1, Copy(LineName[J], System.Length(cBorderWord) + 1, System.Length(LineName[J]) - System.Length(cBorderWord) + 1));
              Font.Color := Pen.Color;
              TextOut(P.X, P.Y, Copy(LineName[J], System.Length(cBorderWord) + 1, System.Length(LineName[J]) - System.Length(cBorderWord) + 1));
            end
          else
            begin
              Pen.Width := 1;
              with L[0] do
                begin
                  P.X := C.X + trunc( X * Length.X * PPMW);
                  P.Y := C.Y + trunc(-Y * Length.Y * PPMH);
                  MoveTo(P.X, P.Y);
                end;
              for I := 1 to Counts[J] - 1 do
                with L[I] do
                  begin
                    P.X := C.X + trunc( X * Length.X * PPMW);
                    P.Y := C.Y + trunc(-Y * Length.Y * PPMH);
                    LineTo(P.X, P.Y);
                  end;
            end;
        end;
    end;
end;

procedure TFGrid.PaintArea( aCanvas : TCanvas; anArea : TArea );
var
  I       : integer;
  C, P, Q : TPoint;
begin
  with anArea.Region, aCanvas do
    begin
      Pen.Style   := psClear;
      Brush.Color := Color;
      Brush.Style := TBrushStyle(Style);
      C.X := 0;
      C.Y := 0;
      C   := Grid2Box(C);
      Q.X := Ceil(Length.X * PPMW / 2);
      Q.Y := Ceil(Length.Y * PPMH / 2);
      for I := 0 to anArea.PointCount - 1 do
        with anArea.Points[I] do
          begin
            P.X := C.X + trunc( X * Length.X * PPMW);
            P.Y := C.Y + trunc(-Y * Length.Y * PPMH);
            Rectangle(P.X - Q.X,     P.Y - Q.Y,
                      P.X + Q.X + 1, P.Y + Q.Y + 1);
          end;
    end;
end;

procedure TFGrid.PaintGrdGrate( aCanvas : TCanvas; aGap : TPoint; aColor : TColor );
var
  P, val, dx, dy: integer;
  Delta : double;
  Pos   : double;
  GrdOrg, GrdEnd: TPoint;
  size: TSize;
  str: string;
begin
  with aCanvas do
    begin
      GrdOrg.X := Round(PL + (0.5 - fGrid.Origin.X - GL) * (PW/GW));
      GrdOrg.Y := Round(PT + (0.5 - fGrid.Origin.Y - GT) * (PH/GH));
      GrdEnd.X := Round(PL + (0.5 + fGrid.Ending.X - GL) * (PW/GW));
      GrdEnd.Y := Round(PT + (0.5 + fGrid.Ending.Y - GT) * (PH/GH));
      dx := Round(PPMW*fGrid.Length.X/2);
      dy := Round(PPMH*fGrid.Length.Y/2);
      if fProduct is TVertProduct then
        Pen.Style := psDot;
      Pen.Color := aColor;
      Pen.Mode := pmCopy;
      Pen.Width := 1;
      Font.Color := aColor;
      Font.Size := 8;
      Font.Name := 'Arial';
      Font.Style := [];
      if (aGap.X > 0) and (GW > 0) and (PW > 0)
        then
          begin
            Delta := aGap.X * (1000/fGrid.Length.X) * (PW/GW);
            if Delta >= GrdMinDelta
              then
                begin
                  Pos := GrdOrg.X;
                  P   := round(Pos);
                  val := 0;
                  while P < Width do
                    begin
                      if (fProduct is TVertProduct) then
                        begin
                          MoveTo(P - dx, GrdOrg.Y);
                          if (P < GrdEnd.X) then
                            begin
                              str := IntToStr(val);
                              LineTo(P - dx, GrdEnd.Y);
                              size := TextExtent(str);
                              TextOut(P - size.cx div 2 - dx, GrdEnd.Y + dy, str);
                              Inc(val, aGap.X);
                            end;
                        end
                      else
                        begin
                          MoveTo(P, 0);
                          LineTo(P, Height);
                        end;
                      Pos := Pos + Delta;
                      P   := round(Pos);
                    end;
                  Pos := GrdOrg.X - Delta;
                  P   := round(Pos);
                  while P >= 0 do
                    begin
                      MoveTo(P, 0);
                      if not (fProduct is TVertProduct) then
                        LineTo(P, Height);
                      Pos := Pos - Delta;
                      P   := round(Pos);
                    end;
                end;
          end;
      if (aGap.Y > 0) and (GH > 0) and (PH > 0)
        then
          begin
            Delta := aGap.Y * (1000/fGrid.Length.Y) * (PH/GH);
            if Delta >= GrdMinDelta
              then
                begin
                  Pos := GrdEnd.Y;
                  P   := round(Pos);
                  while P < Height do
                    begin
                      MoveTo(0, P);
                      if not (fProduct is TVertProduct) then
                        LineTo(Width, P);
                      Pos := Pos + Delta;
                      P   := round(Pos);
                    end;
                  Pos := GrdEnd.Y;// - Delta;
                  P   := round(Pos);
                  val := 0;
                  while P >= 0 do
                    begin
                      if fProduct is TVertProduct then
                        begin
                          MoveTo(GrdOrg.X, P + dy);
                          if P > GrdOrg.Y then
                            begin
                              LineTo(GrdEnd.X, P + dy);
                              str := IntToStr(val);
                              size := TextExtent(str);
                              if val > 0 then
                                begin
                                  TextOut(GrdOrg.X - size.cx - dx - 2, P - size.cy div 2 + dy, str);
                                end;
                              Inc(val, aGap.Y);
                            end
                        end
                      else
                        begin
                          MoveTo(0, P);
                          LineTo(Width, P);
                        end;
                      Pos := Pos - Delta;
                      P   := round(Pos);
                    end;
                end;
          end;
        Delta := aGap.X * (1000/fGrid.Length.X) * (PW/GW);
        if Delta >= GrdMinDelta
          then
            begin
              Pos := GrdOrg.X;
              P   := round(Pos);
              if not (fProduct is TVertProduct) then
                begin
                  MoveTo(P, 0);
                  LineTo(P, Height);
                end
            end;
      if fProduct is TVertProduct then
        begin
          Pen.Mode := pmNotCopy;
          Pen.Style := psSolid;
          Pen.Width := 2;
          Brush.Style := bsClear;
          Rectangle(GrdOrg.X - dx, GrdOrg.Y - dy, GrdEnd.X + dx + 1, GrdEnd.Y + dy + 1);
          Pen.Mode := pmCopy;
        end;
      if fProduct is TCut then
        begin
          fCutOrg.X := 0;
          fCutOrg.Y := fGrid.Ending.Y + 1;
          fCutEnd.X := fGrid.Ending.X;
          fCutEnd.Y := fGrid.Ending.Y + 1;
          PaintCut(aCanvas);
        end;
    end;
end;

procedure TFGrid.PaintGeoGrate( aCanvas : TCanvas; aGap: T2DLocation; aColor: TColor);
var
  lt, ln: single;
  OrgLoc, EndLoc, RadLoc: T2DLocation;
  P, LastP: TPoint;
  Ran, Azm: single;
  latfactor, lonfactor: single;
  str: string;
  LonList: TStringList;
  size: TSize;
begin
  // Necesita refinamiento para trabajar en otro hemisferion
  if (Zoom >= 20) then
    begin
      OrgLoc := Grid2Loc(Box2Grid(Point(0, 0)));
      EndLoc := Grid2Loc(Box2Grid(Point(PaintBox1.Width, PaintBox1.Height)));
      RadLoc := Grid.Center;
      lonfactor := 10 * aGap.Longitude; latfactor := 1;
      P := Point(-1, -1);
      LonList := TStringList.Create;
      while (latfactor <> 10 * aGap.Latitude) do
        with aCanvas do
          begin
            Font.Color := aColor;
            Brush.Style := bsClear;
            if lonfactor = 1 then
              latfactor := 10 * aGap.Latitude;
            lt := Trunc(OrgLoc.Latitude/aGap.Latitude + 3) * aGap.Latitude;
            repeat
              ln := Trunc(OrgLoc.Longitude/aGap.Longitude + 1) * aGap.Longitude;
              repeat
                LastP := P;
                P := Loc2Box(Location2D(ln, lt));
                Pixels[P.X, P.Y] := aColor;
                if (latfactor = 1) and (LastP.X <= 1) and (P.X > 1) and (P.Y > 0) then
                  begin
                    str := IntToStr(Trunc(lt)) + '°';
                    if Frac(lt) <> 0 then
                      str := str + IntToStr(Round(Frac(lt)*60)) + '''';
                    TextOut(P.X, P.Y, str);
                  end;
                if (lonfactor = 1) and (P.X > 0) and (P.Y > 0) then
                  begin
                    str := IntToStr(Trunc(ln)) + '°';
                    if Frac(ln) <> 0 then
                      str := str + IntToStr(Round(Frac(ln)*60)) + '''';
                    if LonList.IndexOf(str) = -1 then
                      begin
                        size := TextExtent(str);
                        LonList.Add(str);
                        TextOut(P.X, P.Y, str);
                      end;
                  end;
                ln := ln + aGap.Longitude / lonfactor * Sign(EndLoc.Longitude - OrgLoc.Longitude);
              until ln < EndLoc.Longitude - 4;
              lt := lt + aGap.Latitude / latfactor * Sign(EndLoc.Latitude - OrgLoc.Latitude);
            until lt < EndLoc.Latitude;
            lonfactor := 1;
          end;
      LonList.Free;
    end;
end;

procedure TFGrid.PaintCircle( aCanvas : TCanvas; aCenter : TPoint; aRadio, aNumber: integer; aColor : TColor; ShowCenter, ShowNumber, ShowRad: boolean );
var
  DeltaX   : double;
  DeltaY   : double;
  P0X, P0Y : double;
  P1X, P1Y : double;
  GridCenter, CC: TPoint;
  str: string;
  size: TSize;
begin
  with aCanvas do
    begin
      if aColor = clBlack then
        Inc(aColor);
      Pen.Style := psSolid;
      Pen.Color := aColor;
      Brush.Style := bsClear;
      DeltaX := aRadio * (1000/fGrid.Length.X)*PW/GW;
      DeltaY := aRadio * (1000/fGrid.Length.Y)*PW/GW;
      GridCenter := Grid2Box(Point(0, 0));
      if (DeltaX >= RadMinDelta) and (DeltaY >= RadMinDelta)
        then
          begin
            P0X := GridCenter.X + aCenter.X*1000/fGrid.Length.X*PW/GW - DeltaX;
            P1X := GridCenter.X + aCenter.X*1000/fGrid.Length.X*PW/GW + DeltaX;
            P0Y := GridCenter.Y + -aCenter.Y*1000/fGrid.Length.Y*PW/GW - DeltaY;
            P1Y := GridCenter.Y + -aCenter.Y*1000/fGrid.Length.Y*PW/GW + DeltaY;
            Ellipse(round(P0X), round(P0Y), round(P1X), round(P1Y));
            Font.Color := Pen.Color;
            if ShowRad then
              begin
                str := IntToStr(round(aRadio));
                size := TextExtent(str);
                TextOut(round((P1X - P0X)/2 + P0X) - size.cx div 2, round(P1Y), str);
              end;
            if ShowNumber then
              begin
                str := IntToStr(round(aNumber));
                size := TextExtent(str);
                TextOut(round((P1X - P0X)/2 + P0X) - size.cx div 2, round(P0Y) - size.cy, str);
              end;
            if ShowCenter then
              begin
                CC := Point(round((P1X - P0X)/2 + P0X), round((P1Y - P0Y)/2 + P0Y));
                Pen.Width := 1;
                MoveTo(CC.X - 4, CC.Y);
                LineTo(CC.X + 5, CC.Y);
                MoveTo(CC.X, CC.Y - 4);
                LineTo(CC.X, CC.Y + 5);
              end;
          end;
    end;
end;

procedure TFGrid.PaintRadGrate( aCanvas : TCanvas );
var
  DeltaX   : double;
  DeltaY   : double;
  P0X, P0Y : double;
  P1X, P1Y : double;
  Sqrt2    : integer;
  str: string;
  val: double;
  size: TSize;
begin
  if (fRadGap.X > 0) and (fRadGap.Y > 0) and (GW > 0) and (GH > 0)
    then
      with aCanvas do
        begin
          Pen.Style := psSolid;
          Pen.Color := fRadColor;
          Brush.Style := bsClear;
          DeltaX := fRadGap.X * (1000/fGrid.Length.X) * (PW/GW);
          DeltaY := fRadGap.Y * (1000/fGrid.Length.Y) * (PH/GH);
          if (DeltaX >= RadMinDelta) and (DeltaY >= RadMinDelta)
            then
              begin
                P0X := PL + (0.5 - fGrid.Origin.X - GL) * (PW/GW) - DeltaX;
                P1X := PL + (0.5 - fGrid.Origin.X - GL) * (PW/GW) + DeltaX;
                P0Y := PT + (0.5 + fGrid.Ending.Y - GT) * (PH/GH) - DeltaY;
                P1Y := PT + (0.5 + fGrid.Ending.Y - GT) * (PH/GH) + DeltaY;
                Sqrt2 := round(sqrt(2) * Width / 2);
                val := RadGap.X;
                while (P0X >= -Sqrt2) or (P0Y >= -Sqrt2) or
                      (P1X < Width + Sqrt2) or (P1Y < Height + Sqrt2) do
                  begin
                    Ellipse(round(P0X), round(P0Y), round(P1X), round(P1Y));
                    Font.Color := Pen.Color;
                    str := IntToStr(round(val));
                    size := TextExtent(str);
                    TextOut(round(P0X) - size.cx - 2, round((P1Y - P0Y)/2 + P0Y) - size.cy div 2, str);
                    TextOut(round((P1X - P0X)/2 + P0X) - size.cx div 2, round(P1Y), str);
                    P0X := P0X - DeltaX;
                    P1X := P1X + DeltaX;
                    P0Y := P0Y - DeltaY;
                    P1Y := P1Y + DeltaY;
                    val := val + RadGap.X;
                  end;
              end;
        end;
end;

procedure TFGrid.PaintCut( aCanvas : TCanvas );
var
  P1, P2 : TPoint;
begin
  with aCanvas do
    begin
      Pen.Mode := pmCopy;
      Pen.Width := 1;
      P1 := Grid2Box(fCutOrg);
      P2 := Grid2Box(fCutEnd);
      Pen.Style := psSolid;
      Pen.Color := clLime;
      MoveTo(P2.X, P2.Y);
      LineTo(P1.X, P1.Y);
      Pen.Color := clBtnShadow;
      Brush.Style := bsSolid;
      Brush.Color := clGreen;
      Rectangle(P2.X - CutSize, P2.Y - CutSize, P2.X + CutSize, P2.Y + CutSize);
      Brush.Color := clLime;
      Rectangle(P1.X - CutSize, P1.Y - CutSize, P1.X + CutSize, P1.Y + CutSize);
      Pen.Color := clBtnHighlight;
      MoveTo(P2.X - CutSize, P2.Y + CutSize - 1);
      LineTo(P2.X - CutSize, P2.Y - CutSize);
      LineTo(P2.X + CutSize, P2.Y - CutSize);
      MoveTo(P1.X - CutSize, P1.Y + CutSize - 1);
      LineTo(P1.X - CutSize, P1.Y - CutSize);
      LineTo(P1.X + CutSize, P1.Y - CutSize);
      Brush.Style := bsClear;
      Font.Name  := 'Arial';
      Font.Size  := 6;
      Font.Style := [fsBold];
      Font.Color := $00101010;
      TextOut(P2.X - CutSize + 3, P2.Y - CutSize - 1, '2');
      TextOut(P1.X - CutSize + 2, P1.Y - CutSize - 1, '1');
    end;
end;

procedure TFGrid.PaintMovMark;
var
  P: TPoint;
begin
  with aCanvas do
    begin
      P := Grid2Box(aPoint);
      Pen.Style := psSolid;
      Pen.Color := clBlack;
      Pen.Width := 1;
      Brush.Style := bsSolid;
      Brush.Color := clWhite;
      Rectangle(P.X - 2, P.Y - 2, P.X + 3, P.Y + 3);
      Rectangle(P.X - 1 - MovMarkSize, P.Y - 1, P.X + 2 + MovMarkSize, P.Y + 2);
      Rectangle(P.X - 1, P.Y - 1 - MovMarkSize, P.X + 2, P.Y + 2 + MovMarkSize);
      Ellipse(P.X + MovMarkSize - 2, P.Y + MovMarkSize - 1, P.X + MovMarkSize + 7, P.Y + MovMarkSize + 11);
      Pen.Color := clWhite;
      MoveTo(P.X - MovMarkSize, P.Y);
      LineTo(P.X + MovMarkSize + 1, P.Y);
      MoveTo(P.X, P.Y - MovMarkSize);
      LineTo(P.X, P.Y + MovMarkSize + 1);
      Rectangle(P.X - 1, P.Y - 1, P.X + 2, P.Y + 2);
      Ellipse(P.X + MovMarkSize - 1, P.Y + MovMarkSize, P.X + MovMarkSize + 6, P.Y + MovMarkSize + 10);
      Font.Name  := 'Arial';
      Font.Size  := 6;
      Font.Style := [fsBold];
      Font.Color := $00101010;
      Brush.Style := bsClear;
      if aText = '1' then
        TextOut(P.X + MovMarkSize , P.Y + MovMarkSize, aText)
      else
        TextOut(P.X + MovMarkSize + 1, P.Y + MovMarkSize, aText);
    end;
end;

procedure TFGrid.PaintProfileMark;
var
  P: TPoint;
begin
  with aCanvas do
    begin
      P := Grid2Box(aPoint);
      Pen.Style := psSolid;
      Pen.Color := clBlack;
      Brush.Style := bsSolid;
      Brush.Color := clYellow;
      Rectangle(P.X - 1, P.Y - 13, P.X + 2, P.Y);
      Pen.Color := clYellow;
      MoveTo(P.X - 4, P.Y - 4);
      LineTo(P.X, P.Y);
      LineTo(P.X + 5, P.Y - 5);
      Pen.Color := clBlack;
      MoveTo(P.X - 5, P.Y - 4);
      LineTo(P.X, P.Y + 1);
      LineTo(P.X + 6, P.Y - 5);
      LineTo(P.X + 4, P.Y - 5);
      LineTo(P.X + 1, P.Y - 2);
      MoveTo(P.X - 6, P.Y - 5);
      LineTo(P.X - 4, P.Y - 5);
      LineTo(P.X - 1, P.Y - 2);
    end;
end;

procedure TFGrid.PaintWind;
const
  Radius = 25;
  BackRadius = 8;
  BackAngle  = 32;

  Scale0 = 2;  {kn}
  Scale1 = 5;
  Scale2 = 10;
  Scale3 = 50;

  procedure DrawVector(P: TPoint; Rho: integer; Phi: single);
  var
    P1: TPoint;

    procedure DrawValue(Pos: integer; Val: integer);
    begin
      with aCanvas do
        if (Val Div Scale3) > 0 then
          begin
            P1.X := P.X + XFromAngle(Radius + Pos, Phi);
            P1.Y := P.Y + YFromAngle(Radius + Pos, Phi);
            MoveTo(P1.X, P1.Y);
            P1.X := P1.X + XFromAngle(BackRadius - 2, Phi + pi/2);
            P1.Y := P1.Y + YFromAngle(BackRadius - 2, Phi + pi/2);
            LineTo(P1.X, P1.Y);
            P1.X := P1.X + XFromAngle(BackRadius, Phi + 8/6*pi );
            P1.Y := P1.Y + YFromAngle(BackRadius, Phi + 8/6*pi);
            LineTo(P1.X, P1.Y);
            if (Val - Scale3) >= Scale1 then
              if Val Div Scale3 > 1 then
                DrawValue(Pos - 4, Val - Scale3)
              else
                DrawValue(Pos - 7, Val - Scale3);
          end
        else if (Val Div Scale2) > 0 then
          begin
            P1.X := P.X + XFromAngle(Radius + Pos, Phi);
            P1.Y := P.Y + YFromAngle(Radius + Pos, Phi);
            MoveTo(P1.X, P1.Y);
            P1.X := P1.X + XFromAngle(BackRadius, Phi + pi/3);
            P1.Y := P1.Y + YFromAngle(BackRadius, Phi + pi/3);
            LineTo(P1.X, P1.Y);
            if (Val - Scale2) >= Scale1 then
              DrawValue(Pos - 3, Val - Scale2);
          end
        else if ((Val Div Scale1) > 0) or (Val > Scale0)then
          begin
            if Pos = 0 then Dec(Pos, 4);
            P1.X := P.X + XFromAngle(Radius + Pos, Phi);
            P1.Y := P.Y + YFromAngle(Radius + Pos, Phi);
            MoveTo(P1.X, P1.Y);
            P1.X := P1.X + XFromAngle(BackRadius - 2, Phi + pi/3);
            P1.Y := P1.Y + YFromAngle(BackRadius - 2, Phi + pi/3);
            LineTo(P1.X, P1.Y);
            if (Val - Scale1) >= Scale1 then
              DrawValue(Pos - 3, Val - Scale1);
          end
        else if Val <= Scale0 then
          begin
            MoveTo(P.X, P.Y);
            P1.X := P.X + XFromAngle(BackRadius, Phi + pi/4);
            P1.Y := P.Y + YFromAngle(BackRadius, Phi + pi/4);
            LineTo(P1.X, P1.Y);
            MoveTo(P.X, P.Y);
            P1.X := P.X + XFromAngle(BackRadius, Phi - pi/4);
            P1.Y := P.Y + YFromAngle(BackRadius, Phi - pi/4);
            LineTo(P1.X, P1.Y);
          end;
    end;

  begin
    with aCanvas do
      begin
        Pen.Style := psSolid;
        Pen.Color := clBlack;
        MoveTo(P.X, P.Y);
        P1.X := P.X + XFromAngle(Radius, Phi);
        P1.Y := P.Y + YFromAngle(Radius, Phi);
        LineTo(P1.X, P1.Y);
        DrawValue(0, Rho);
      end;
  end;

var
  X, Y: integer;
  P, P1: TPoint;
  GridP,
  Polar: TPlanePoint;
begin
  with fWindGrid do
    for Y := Origin.Y to Ending.Y do
      for X := Origin.X to Ending.X do
    begin
      P := Grid2Box(Point(X * fWindLength div 1000, Y * fWindLength div 1000));
      if Cell[X, Y] > 0 then
        DrawVector(P, Byte2Velocity(Cell[X, Y]), pi - Byte2Angle(Angle[X, Y]))
    end;
end;

procedure TFGrid.PaintNMEA(aCanvas: TCanvas; RealTime: boolean);

var
  S: TStringList;
  str: string;
  i, up, down: integer;
  lt, ln, lastlt, lastln, course, R, A: single;
  P, P1, P2, P3, PCart: TPoint;
  RadLoc: T2DLocation;
  first, DrawPlane: boolean;
  PlaneColor, TraceColor: TColor;
begin
  DirMonitor1.Active := false;
  Sleep(1);
  S := TStringList.Create;
  if not FileExists(TheSettings.NMEA_ATTEX) then
    ShowMessage('NMEA ATETEX Rusia: No se encuentra el archivo res')
  else
    begin
      S.LoadFromFile(TheSettings.NMEA_ATTEX);
      ValidateNMEAStringList(S);
      if RealTime then
        begin
          down := S.Count - 1;
          up := S.Count - 200;
          if up < 0 then up := 0;
          PlaneColor := clBlack;
          TraceColor := clRed;
        end
      else
        begin
          down := FEditNMEA.TrackBar2.Position;
          up := FEditNMEA.TrackBar1.Position;
          PlaneColor := FEditNMEA.Panel1.Color;
          TraceColor := FEditNMEA.Panel2.Color;
        end;
      RadLoc := Grid.Center;
      with aCanvas, TheSettings do
        begin
          Pen.Color := TraceColor;
          Pen.Width := 2;
          Pen.Style := psSolid;
          first := true;
          DrawPlane := false;
          lastlt := 0;
          lastln := 0;
          for i := down - 1 downto up do
            begin
              if NMEA_ATTEX_Format = 1 then
                str := S[i]
              else
                str := GetStringItem(S[i], '''', 1);
              {$IFDEF NMEA_2010}
              if (Pos('$GPS', str) <> 0) and (Pos('INVALID', str) = 0) then
              {$ELSE}
              if (Pos('$GPGGA', str) <> 0) and (Pos('INVALID', str) = 0) then
              {$ENDIF}
                begin
                  {$IFDEF NMEA_2010}
                  lt := StrToFloat(GetStringItem(str, ',', 4));
                  ln := StrToFloat(GetStringItem(str, ',', 6));
                  {$ELSE}
                  lt := StrToFloat(GetStringItem(str, ',', 2));
                  ln := StrToFloat(GetStringItem(str, ',', 4));
                  {$ENDIF}
                  lt := Trunc(lt/100) + Frac(lt/100)*10/6;
                  ln := Trunc(ln/100) + Frac(ln/100)*10/6;
                  if first then
                    begin
                      PCart := Loc2Cart(Location2D(ln, lt));
                      FShell.StatusBar2.Panels[1].Text :=  IntToStr(PCart.X) +  ' km, ' + IntToStr(PCart.Y) + ' km';
                      {$IFDEF NMEA_2010}
                      FShell.StatusBar2.Panels[2].Text := 'Altitud: ' + GetStringItem(str, ',', 11) + ' m';
                      {$ELSE}
                      FShell.StatusBar2.Panels[2].Text := 'Altitud: ' + GetStringItem(str, ',', 9) + ' m';
                      {$ENDIF}
                      R := Range(fRH_lat*pi/180, fRH_lon*pi/180, lt*pi/180, ln*pi/180);
                      A := Azimut(fRH_lat*pi/180, fRH_lon*pi/180, lt*pi/180, ln*pi/180, R);
                      FShell.StatusBar2.Panels[3].Text := ' ' + FloatToStrF(A, ffFixed, 14, 2) + 'º, ' +
                                                          FloatToStrF(R, ffFixed, 14, 2) + ' km desde ' + fRH_name;
                    end;
                  P := Loc2Box(Location2D(ln, lt));
                  if first then
                    MoveTo(P.X, P.Y)
                  else
                    LineTo(P.X, P.Y);
                  if (i > 0) and first then
                    begin
                      if NMEA_ATTEX_Format = 1 then
                        str := S[i - 1]
                      else
                      {$IFDEF NMEA_2010}
                        str := GetStringItem(S[i], '''', 1);
                      if (Pos('$GPS', str) <> 0) and (Pos('INVALID', str) = 0) then
                      {$ELSE}
                        str := GetStringItem(S[i - 1], '''', 1);
                      if (Pos('$GPRMC', str) <> 0) and (Pos('INVALID', str) = 0) then
                      {$ENDIF}
                        begin
                          P1 := P;
                          {$IFDEF NMEA_2010}
                          course := StrToFloat(GetStringItem(str, ',', 16));
                          {$ELSE}
                          course := StrToFloat(GetStringItem(str, ',', 8));
                          {$ENDIF}
                          DrawPlane := true;
                        end;
                    end;
                  first := false;
                end;
            end;
          if DrawPlane then
            begin
              MoveTo(P1.X, P1.Y);
              Pen.Color := PlaneColor;
              Pen.Width := 2;
              Pen.Style := psSolid;
              P2.X := CalMovForm.XFromAngle(15, course);
              P2.Y := CalMovForm.YFromAngle(15, course);
              LineTo(P1.X + P2.X, P1.Y + P2.Y);
              P3.X := P1.X + Round(P2.X/1.5); P3.Y := P1.Y + Round(P2.Y/1.5);
              MoveTo(P3.X, P3.Y);
              LineTo(P3.X + CalMovForm.XFromAngle(7, course + 135), P3.Y + CalMovForm.YFromAngle(7, course + 135));
              MoveTo(P3.X, P3.Y);
              LineTo(P3.X + CalMovForm.XFromAngle(7, course - 135), P3.Y + CalMovForm.YFromAngle(7, course - 135));
            end;
        end;
      S.Free;
      DirMonitor1.Active := true;
    end;
end;

procedure TFGrid.UpdateZoom;
begin
  if assigned(fGrid)
    then
      with PaintBox1 do
        begin
          if fGWidth <= Width
            then
              begin
                GW := fGrid.Width;
                PW := fGWidth;
              end
            else
              begin
                GW := round(fGrid.Width * (Width/fGWidth));
                PW := Width;
              end;
          if fGHeight <= Height
            then
              begin
                GH := fGrid.Height;
                PH := fGHeight;
              end
            else
              begin
                GH := round(fGrid.Height * (Height/fGHeight));
                PH := Height;
              end;
          PPMW := PW / (GW * fGrid.Length.X);
          PPMH := PH / (GH * fGrid.Length.Y);
          with ScrollBar1 do
            begin
              Max := fGrid.Width - GW;
              LargeChange := GW div 2;
              if fCenterPos.X > LargeChange
                then Position := fCenterPos.X - LargeChange
                else Position := 0;
            end;
          with ScrollBar2 do
            begin
              Max := fGrid.Height - GH;
              LargeChange := GH div 2;
              if fCenterPos.Y > LargeChange
                then Position := fCenterPos.Y - LargeChange
                else Position := 0;
            end;
          UpdateMaskBitmap;
        end;
end;

procedure TFGrid.SetScale( aScale : TScale );

  function CreatePanel( aTag : integer ) : TPanel;
  begin
    Result := TPanel.Create(Self);
    with Result do
      begin
        Tag   := aTag;
        Color := fGridScale.Color[aTag];
        if (((Color and $FF0000) shr 16) +
            ((Color and $00FF00) shr  8) +
            ((Color and $0000FF) shr  0)) < (3 * 64)
          then Font.Color := clWhite
          else Font.Color := clBlack;
        with fGridScale do
          begin
            Hint := fGridScale.Caption[aTag];
            if Hint <> ''
              then Hint := Hint + ' ';
            if (aTag < pred(Size)) or (fGridScale.Measure = unMS)
              then Hint := Hint + Format('<= %g ', [CodeMeasure(Value[aTag], Measure)])
              else Hint := Hint + Format('> %g ', [CodeMeasure(Value[aTag - 1], Measure)]);
            Hint := Hint + MeasureName(fGridScale.Measure);
            if Look
              then Result.Caption := Caption[aTag]
              else
                if (aTag < pred(Size)) or (Measure = unMS)
                  then Result.Caption := Format('%g', [CodeMeasure(Value[aTag], Measure)])
                  else Result.Caption := '>'
          end;
        BevelOuter  := bvLowered;
        ShowHint    := true;
        PopupMenu   := PopupMenu1;
        OnMouseDown := PanelMouseDown;
      end;
  end;

var
  I : integer;
  V : boolean;
begin
  if assigned(fGridScale) and (aScale <> fGridScale)
    then fGridScale.Release;
  fGridScale := aScale;
  if assigned(fGridScale)
    then
      begin
        PaintBox1.Color := fGridScale.Color[0];
        V := Panel4.Visible;
        Panel4.Visible := false;
        Valores1.Checked := not fGridScale.Look;
        Titulos1.Checked :=     fGridScale.Look;
        with Panel4 do
          for I := ControlCount - 1 downto 0 do
            RemoveControl(Controls[I]);
        with fGridScale do
          for I := 0 to Size - 1 do
            Panel4.InsertControl(CreatePanel(I));
        Panel4Resize(Panel4);
        Panel4.Visible := V;
      end
    else PaintBox1.ParentColor := true;
  if assigned(fGrid)
    then
      begin
        DeleteObject(SelectObject(fWinGDC, fOriginalBM));
        FillBitmapInfo;
        fWinGBitmap := CreateDIBSection(fWinGDC, fWinGBMInfo^, DIB_RGB_COLORS, fWinGBMBits, 0, 0);
        fOriginalBM := SelectObject(fWinGDC, fWinGBitmap);
        FillBitmap;
        UpdateBuffBitmap;
      end;
end;

procedure TFGrid.ScrollBarScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  UpdateMaskBitmap;
end;

procedure TFGrid.Salvar1Click(Sender: TObject);
const
  PrdFormats : array[0..7] of TFileFormat = (ffUnknown,
                                             ffProduct, ffNetCDF, ffBinary,
                                             ffBMPImage, ffGIFImage, ffJPGImage,
                                             ffCSVTable);
  AnmFormats : array[0..9] of TFileFormat = (ffUnknown,
                                             ffAnimation, ffGIFAnim,
                                             ffProduct, ffNetCDF, ffBinary,
                                             ffBMPImage, ffGIFImage, ffJPGImage,
                                             ffCSVTable);
var
  P : boolean;
begin
  P := Playing;
  if assigned(fAnimation) and P
    then ToolButton1Click(ToolButton1);
  with SaveDialog1 do
    begin
      if assigned(fAnimation)
        then Filter := AnmFilter
        else Filter := PrdFilter;
      if TMenuItem(Sender).Name = 'Salvar1' then
        FilterIndex := 1
      else if TMenuItem(Sender).Name = 'Salvar2' then
        FilterIndex := 5;  
      if Execute
        then
          if assigned(fAnimation)
            then SaveAnmData(FileName, AnmFormats[FilterIndex])
            else SavePrdData(FileName, PrdFormats[FilterIndex]);
    end;
  if assigned(fAnimation) and P
    then ToolButton1Click(ToolButton1);
end;

procedure TFGrid.Ampliar1Click(Sender: TObject);
begin
  SetZoom(fZoom + UpDown1.Increment);
end;

procedure TFGrid.Reducir1Click(Sender: TObject);
begin
  SetZoom(fZoom - UpDown1.Increment);
end;

procedure TFGrid.Copiar1Click(Sender: TObject);
begin
  FShell.CopiarClick(Sender);
end;

procedure TFGrid.Imprimir1Click(Sender: TObject);
begin
  Print;
end;

procedure TFGrid.Cuadriculas2Click(Sender: TObject);
begin
  with TFGapColor.Create(Self) do
    try
      Caption := 'Rejilla de Observación';
      Gap     := fGrdGap;
      Color   := fGrdColor;
      if ShowModal = mrOk
        then
          begin
            fGrdGap   := Gap;
            fGrdColor := Color;
          end;
      if Cuadriculas1.Checked
        then UpdateMaskBitmap;
    finally
      Free;
    end;
end;

procedure TFGrid.Climatologa2Click(Sender: TObject);
begin
  with TFGapColor.Create(Self) do
    try
      Caption := 'Rejilla de Climatología';
      Gap     := fClmGap;
      Color   := fClmColor;
      if ShowModal = mrOk
        then
          begin
            fClmGap   := Gap;
            fClmColor := Color;
          end;
      if Climatologia1.Checked
        then UpdateMaskBitmap;
    finally
      Free;
    end;
end;

procedure TFGrid.Radios2Click(Sender: TObject);
begin
  with TFGapColor.Create(Self) do
    try
      Caption := 'Anillas de Distancia';
      Gap     := fRadGap;
      Color   := fRadColor;
      Label4.Caption := 'Radio:';
      Label5.Visible := false;
      Edit2.Visible := false;
      UpDown2.Visible := false;
      Label3.Visible := false;
      CheckBox1.Visible := false;
      CheckBox1.Enabled := true;
      if ShowModal = mrOk
        then
          begin
            fRadGap   := Gap;
            fRadGap.Y := fRadGap.X;
            fRadColor := Color;
          end;
      if Radios1.Checked
        then UpdateMaskBitmap;
    finally
      Free;
    end;
end;

procedure TFGrid.Recortar1Click(Sender: TObject);
var
  FullSize : TPoint;
begin
  if WindowState = wsNormal
    then
      begin
        FullSize.X := fGWidth  + ClientWidth  - PaintBox1.Width;
        FullSize.Y := fGHeight + ClientHeight - PaintBox1.Height;
        if ClientWidth > FullSize.X
          then ClientWidth := FullSize.X;
        if ClientHeight > FullSize.Y
          then ClientHeight := FullSize.Y;
      end;
end;

procedure TFGrid.Ajustar1Click(Sender: TObject);
begin
  Adjust;
end;

procedure TFGrid.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE : Close;
  end;
end;

procedure TFGrid.GuiadeCorte1Click(Sender: TObject);
begin
  GuiadeCorte1.Checked := not GuiadeCorte1.Checked;
  Cortar1.Enabled := GuiadeCorte1.Checked;
  UpdateBuffBitmap;
end;

function TFGrid.Grid2Box( aPoint : TPoint ) : TPoint;
begin
  with fGrid do
    begin
      Result.X := PL + round((0.5 + aPoint.X - Origin.X - GL) * (PW/GW));
      Result.Y := PT + round((0.5 - aPoint.Y + Ending.Y - GT) * (PH/GH));
    end;
end;

function TFGrid.Box2Grid( aPoint : TPoint ) : TPoint;
begin
  with fGrid do
    begin
      Result.X := Origin.X + GL + trunc((aPoint.X - PL) * (GW/PW));
      Result.Y := Ending.Y - GT - trunc((aPoint.Y - PT) * (GH/PH));
    end;
end;

function TFGrid.Box2Meter( aPoint : TPoint ) : TPoint;
begin
  if (PW > 0) and (PH > 0)
    then
      with fGrid do
        begin
          Result.X := (Origin.X + GL + trunc((aPoint.X - PL) * (GW/PW))) * Length.X;
          Result.Y := (Ending.Y - GT - trunc((aPoint.Y - PT) * (GH/PH))) * Length.Y;
          inc(Result.X, round(frac((aPoint.X - PL) * GW/PW) * Length.X) - Length.X div 2);
          inc(Result.Y, Length.Y div 2 - round(frac((aPoint.Y - PT) * GH/PH) * Length.Y));
        end
    else FillChar(Result, sizeof(Result), 0);
end;

function TFGrid.Grid2Polar( aPoint : TPoint ) : TPoint;
begin
  with fGrid do
    begin
      Result.X := round(sqrt(sqr(aPoint.X * (Length.X/1000)) +
                             sqr(aPoint.Y * (Length.Y/1000))));
      if aPoint.Y = 0
        then
          if aPoint.X = 0
            then Result.Y := 0
            else
              if aPoint.X > 0
                then Result.Y := 90
                else Result.Y := 270
        else Result.Y := round(180/Pi * arctan((aPoint.X/aPoint.Y * Length.X/Length.Y)));
      if aPoint.Y < 0
        then inc(Result.Y, 180);
      if Result.Y < 0
        then inc(Result.Y, 360);
    end;
end;

function TFGrid.Grid2Loc( aPoint  : TPoint ) : T2DLocation;
var
  rg, az: single;
begin
  with fGrid do
    begin
      rg := sqrt(sqr(aPoint.X * (Length.X/1000)) +
                 sqr(aPoint.Y * (Length.Y/1000)));
      if aPoint.Y = 0
        then
          if aPoint.X = 0
            then az := 0
            else
              if aPoint.X > 0
                then az := 90
                else az := 270
        else az := 180/Pi * arctan((aPoint.X/aPoint.Y * Length.X/Length.Y));
      if aPoint.Y < 0
        then az := az + 180;
      if az < 0
        then az := az + 360;
      Result := Reckon(Center.Latitude, Center.Longitude, rg, az);
    end;
end;

function TFGrid.Loc2Box(aLoc: T2DLocation): TPoint;
var
  RadLoc: T2DLocation;
  Ran, Azm: real;
  BoxCenter: TPoint;
begin
  RadLoc := Grid.Center;
  BoxCenter := Grid2Box(Point(0, 0));
  Ran := Range(RadLoc.Latitude*pi/180, RadLoc.Longitude*pi/180, aLoc.Latitude*pi/180, aLoc.Longitude*pi/180);
  Azm := Azimut(RadLoc.Latitude*pi/180, RadLoc.Longitude*pi/180, aLoc.Latitude*pi/180, aLoc.Longitude*pi/180, Ran);
  Result.X := BoxCenter.X + Round(1000/Grid.Length.X*Vy(Ran, Azm*pi/180)*Zoom/100);
  Result.Y := BoxCenter.Y - Round(1000/Grid.Length.X*Vx(Ran, Azm*pi/180)*Zoom/100);
//  result := Grid2Box(Point(Round(1000/Grid.Length.X*Vy(Ran, Azm*pi/180)), Round(1000/Grid.Length.X*Vx(Ran, Azm*pi/180))));
end;

function TFGrid.Loc2Cart(aLoc: T2DLocation): TPoint;
var
  RadLoc: T2DLocation;
  Ran, Azm: real;
//  BoxCenter: TPoint;
begin
  RadLoc := Grid.Center;
//  BoxCenter := Grid2Box(Point(0, 0));
  Ran := Range(RadLoc.Latitude*pi/180, RadLoc.Longitude*pi/180, aLoc.Latitude*pi/180, aLoc.Longitude*pi/180);
  Azm := Azimut(RadLoc.Latitude*pi/180, RadLoc.Longitude*pi/180, aLoc.Latitude*pi/180, aLoc.Longitude*pi/180, Ran);
  Result.X := Round(Vy(Ran, Azm*pi/180));
  Result.Y := Round(Vx(Ran, Azm*pi/180));
end;

procedure TFGrid.SetCutOrg( aCutOrg : TPoint );
begin
  fCutOrg := aCutOrg;
  UpdateBuffBitmap;
end;

procedure TFGrid.SetCutEnd( aCutEnd : TPoint );
begin
  fCutEnd := aCutEnd;
  UpdateBuffBitmap;
end;

procedure TFGrid.SetProfileMark( aProfileMark : TPoint );
begin
  fProfileMark := aProfileMark;
  UpdateBuffBitmap;
end;

procedure TFGrid.UpdateProfile(aPoint: Tpoint);
var
  Obs  : TObservation;
  Prof : TProfileVector;
begin
  try
    Obs  := (Owner.Owner as TFObservation).Observation;
    Prof := TProfileVector.Initialize(aPoint, TheSettings.DefaultCellV, 0, 20000);
    Prof.Render(Obs, 0, Grid.Measure);
    FShell.DisplayProfile(Prof);
  finally
    FreeAndNil(Prof);
  end;
end;

procedure TFGrid.PaintBox1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P, R : TPoint;
begin
  // Corte
  P := Box2Grid(Point(X, Y));
  if GuiadeCorte1.Enabled and (PW > 0) and (PH > 0)
    then
      begin
        if ssDouble in Shift
          then
            begin
              Guiadecorte1.Checked := true;
              Cortar1.Enabled := true;
              if Button = mbRight then CutOrg := P;
              if Button = mbLeft then CutEnd := P;
              CheckCutUpdate;
            end
          else
            if GuiadeCorte1.Checked then
              begin
                if (abs(fCutOrg.X - P.X) < CutSize) and (abs(fCutOrg.Y - P.Y) < CutSize)
                  then fCutOrgDrag := true
                  else
                    if (abs(fCutEnd.X - P.X) < CutSize) and (abs(fCutEnd.Y - P.Y) < CutSize)
                      then fCutEndDrag := true;
              end;
        PaintBox1MouseMove(Sender, Shift, X, Y);
      end;
  // Marcas de Distancia
  if Distancia1.Checked and
     (abs(MovMark1.X - P.X) < MovMarkSize) and (abs(MovMark1.Y - P.Y) < MovMarkSize) then
    fMovMark1Drag := true
  else if Distancia2.Checked and
     (abs(MovMark2.X - P.X) < MovMarkSize) and (abs(MovMark2.Y - P.Y) < MovMarkSize) then
    fMovMark2Drag :=  true;
  // Vertical Profile
  if Perfil1.Checked and
     (abs(ProfileMark.X - P.X) < ProfSize) and (ProfileMark.Y - P.Y < ProfSize*2) then
    fProfileDrag := true;
  // Profile
  if Perfil1.Checked and (ssCtrl in Shift) and (ssLeft in Shift)
    then
      begin
        UpdateProfile(Box2Meter(Point(X, Y)));
        fEnableProfileMark := true;
        ProfileMark := Box2Grid(Point(X, Y));
      end;
  // MovMarks
  if Product is THorzProduct then
    if (ssLeft in Shift) and (ssShift in Shift) then
      begin
        fEnableMovMark1 := true;
        with FCalMov, fGrid do
          begin
            MovMark1 := Box2Grid(Point(X, Y));
            Distancia1.Checked := true;
            MovMark1Loc := Grid2Loc(MovMark1);
            if assigned(Grid1) and (Grid1 <> Self) then
              begin
                Grid1.fEnableMovMark1 := false;
                Grid1.UpdateBuffBitmap;
              end;
            Grid1 := Self;
            UpdateBuffBitMap;
          end;
        CheckMovMarks;
      end
    else if (ssRight in Shift) and (ssShift in Shift) then
      begin
        fEnableMovMark2 := true;
        with FCalMov, fGrid do
          begin
            MovMark2 := Box2Grid(Point(X, Y));
            Distancia2.Checked := true;
            MovMark2Loc := Grid2Loc(MovMark2);
            if assigned(Grid2) and (Grid2 <> Self) then
              begin
                Grid2.fEnableMovMark2 := false;
                Grid2.UpdateBuffBitmap;
              end;
            Grid2 := Self;
            UpdateBuffBitMap;
          end;
        CheckMovMarks;
      end;
end;

procedure TFGrid.PaintBox1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if fCutOrgDrag or fCutEndDrag then
    CheckCutUpdate;
//  if fMovMark1Drag or fMovMark2Drag then
//    CheckMovMarks;
  fCutOrgDrag := false;
  fCutEndDrag := false;
  fMovMark1Drag := false;
  fMovMark2Drag := false;
  fProfileDrag := false;
end;

procedure TFGrid.Cortar1Click(Sender: TObject);
begin
  UpdateCut;
end;

procedure TFGrid.CutDestroy( Sender : TObject );
begin
  fCutProduct := nil;
  if Sender is TFGrid
    then TFGrid(Sender).FormDestroy(Sender);
end;

procedure TFGrid.UpdateCut;
var
  theP1, theP2 : TPlanePoint;
  theMeasure   : TMeasure;
  CutClass     : CProduct;
begin
  theP1 := PlanePoint(fCutOrg.X, fCutOrg.Y);
  theP2 := PlanePoint(fCutEnd.X, fCutEnd.Y);
  if (theP1.X = theP2.X) and (theP1.Y = theP2.Y) then
    raise Exception.Create('Posiciones de inicio y final de corte idénticas');
  if (Grid.Measure <= unMMH) or (Grid.Measure = unMS) or (Grid.Measure = unSW)
    then theMeasure := Grid.Measure
    else theMeasure := unDBZ;
  with Owner.Owner as TFObservation  do
    begin
      if (fCutProduct = nil) or not (fCutProduct as TCut).ViewForm.Pin.Down
        then
          begin
            if assigned(fCutProduct)
              then
                begin
                  (fCutProduct as TCut).ViewForm.Pin.Enabled := false;
                  (fCutProduct as TCut).OnDestroy := nil;
                end;
            CutClass := GetProductByName('Corte');
            CutClass.Setup(Observation);
            fCutProduct := CutClass.Create(Owner);
            with (fCutProduct as TCut).ViewForm.Pin do
              begin
                Visible := true;
                Enabled := true;
                Down    := true;
              end;
            (fCutProduct as TCut).OnDestroy := CutDestroy;
          end;
      if assigned(fCutProduct)
        then
          with fCutProduct as TCut do
            begin
              Default;
              Measure := theMeasure;
              Channel := (Self.Product as TGridProduct).Channel;
              Length  := Self.Grid.Length.X;
              Area    := PlaneArea(theP1.X, theP1.Y, theP2.X, theP2.Y);
              CreateProduct(fCutProduct);
            end;
    end;
end;

procedure TFGrid.CheckCutUpdate;
begin
  if assigned(fCutProduct) and
     (fCutProduct as TCut).ViewForm.Pin.Down
    then UpdateCut;
end;

procedure TFGrid.UpdateTreeAreas;
var
  EntryIndex : integer;
  Nodes      : TTreeNodes;
  PAreas     : PPointerList;

  procedure AddAreas( N : TTreeNode; A : TArea );
  var
    I : integer;
    L : PPointerList;
  begin
    if TAreaEntry(PAreas^[EntryIndex]).Selected
      then N.StateIndex := tiAll
      else N.StateIndex := tiNone;
    inc(EntryIndex);
    if assigned(A.Areas)
      then
        begin
          L := A.Areas.List;
          for I := 0 to A.AreaCount - 1 do
            AddAreas(Nodes.AddChildObject(N, TArea(L^[I]).Name, PAreas^[EntryIndex]), TArea(L^[I]));
        end;
  end;

var
  I : integer;
begin
  if assigned(fGrid)
    then
      begin
        PAreas := fAreas.List;
        Nodes  := FShell.TreeView1.Items;
        Nodes.Clear;
        Nodes.BeginUpdate;
        EntryIndex := 0;
        for I := 0 to fRegions.Count - 1 do
          AddAreas(Nodes.AddObject(nil, TRegion(fRegions[I]).Name, PAreas^[EntryIndex]), fRegions[I]);
        Nodes.EndUpdate;
      end;
end;

function FillAreaList( Nodes : TTreeNodes ) : TList;

  procedure AddNodeAreas( Node : TTreeNode );
  var
    N : TTreeNode;
  begin
    if Node.StateIndex = tiAll
      then Result.Add(Node.Data);
    N := Node.GetFirstChild;
    while assigned(N) do
      begin
        AddNodeAreas(N);
        N := Node.GetNextChild(N);
      end;
  end;

var
  N : TTreeNode;
begin
  Result := TList.Create;
  N := Nodes.GetFirstNode;
  while assigned(N) do
    begin
      AddNodeAreas(N);
      N := N.GetNextSibling;
    end;
end;

procedure TFGrid.Reporte1Click(Sender: TObject);
var
  Nodes : TTreeNodes;

  procedure AddAreas( N : TTreeNode; A : TArea );
  var
    I : integer;
  begin
    if (A is TRegion) and (A as TRegion).Report
      then N.StateIndex := tiAll
      else N.StateIndex := tiNone;
    for I := 0 to A.AreaCount - 1 do
      AddAreas(Nodes.AddChildObject(N, A.Area[I].Name, A.Areas[I]), A.Areas[I]);
  end;

var
  I      : integer;
  Report : TReport;
  Flags  : TReportFlagSet;
begin
  with TFReportEdit.Create(Self) do
    try
      TreeView1.StateImages := TreeImages.Images;
      Nodes := TreeView1.Items;
      Nodes.Clear;
      for I := 0 to fRegions.Count - 1 do
        AddAreas(Nodes.AddObject(nil, TRegion(fRegions[I]).Name, fRegions[I]), fRegions[I]);
      Measure   := fGrid.Measure;
      Threshold := fGridScale.Value[0];
      if ShowModal = mrOk
        then
          begin
            Application.MainForm.Update;
            Flags := [];
            if CheckBox1.Checked then include(Flags, rfArea);
            if CheckBox2.Checked then include(Flags, rfCoating);
            if CheckBox3.Checked then include(Flags, rfAverage);
            if CheckBox4.Checked then include(Flags, rfMax);
            if CheckBox5.Checked then include(Flags, rfMin);
            if CheckBox6.Checked then include(Flags, rfMean);
            if CheckBox7.Checked then include(Flags, rfMedian);
            if CheckBox8.Checked then include(Flags, rfVolume);
            if CheckBox9.Checked then include(Flags, rfStdDev);
            Report := TReport.Create(Product, Grid, FillAreaList(TreeView1.Items),
                                     Threshold, Flags);
            try
              if CheckBox12.Checked then Report.PlainTextShow;
              if CheckBox11.Checked then Report.RichEditShow;
              if CheckBox10.Checked then Report.MicrosoftWordShow;
            finally
              Report.Free;
            end;
          end;
    finally
      Free;
    end;
end;

procedure TFGrid.PanelMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  fClicked := Sender as TPanel;
end;

procedure TFGrid.Panel4Resize(Sender: TObject);
var
  I, H, R, P : integer;
begin
  if assigned(fGridScale)
    then
      with Sender as TPanel do
        begin
          H := Height div fGridScale.Size;
          R := Height mod fGridScale.Size;
          for I := 0 to ControlCount - 1 do
            with Controls[I] as TPanel do
              begin
                P := fGridScale.Size - 1 - Tag;
                if P < R
                  then
                    begin
                      Top    := P * H + P;
                      Height := H + 1;
                    end
                  else
                    begin
                      Top    := P * H + R;
                      Height := H;
                    end;
                Width := Parent.Width;
              end;
        end;
end;

procedure TFGrid.LookClick(Sender: TObject);
begin
  fGridScale.Look := not fGridScale.Look;
  SetScale(fGridScale);
end;

procedure TFGrid.Abrir1Click(Sender: TObject);
var
  S : TScale;
begin
  with OpenDialog1 do
    begin
      FileName := fGridScale.FileName;
      if Execute
        then
          begin
            S := TScale.Load(FileName);
            S.Measure := fGrid.Measure;
            SetScale(S);
          end;
    end;
end;

procedure TFGrid.Salvar3Click(Sender: TObject);
begin
  with SaveDialog2 do
    begin
      FileName := fGridScale.FileName;
      if Execute
        then fGridScale.Save(FileName);
    end;
end;


procedure TFGrid.Insertar1Click(Sender: TObject);
begin
  if assigned(fClicked)
    then
      begin
        fGridScale.Insert(fClicked.Tag);
        SetScale(fGridScale);
      end;
end;

procedure TFGrid.Eliminar1Click(Sender: TObject);
begin
  if assigned(fClicked) and (fGridScale.Size > 2)
    then
      begin
        fGridScale.Delete(fClicked.Tag);
        SetScale(fGridScale);
      end;
end;

procedure TFGrid.Editar1Click(Sender: TObject);
begin
  if assigned(fClicked)
    then
      with TFScaleEdit.Create(nil) do
        try
          ScaleMeasure     := fGridScale.Measure;
          Edit1.Text       := fGridScale.Caption[fClicked.Tag];
          UpDown1.Position := fGridScale.Value  [fClicked.Tag];
          Panel1.Color     := fGridScale.Color  [fClicked.Tag];
          DrawValue;
          if ShowModal = mrOk
            then
              begin
                fGridScale.Caption[fClicked.Tag] := Edit1.Text;
                fGridScale.Value  [fClicked.Tag] := UpDown1.Position;
                fGridScale.Color  [fClicked.Tag] := Panel1.Color;
                SetScale(fGridScale);
              end;
        finally
          Release;
        end;
end;

procedure TFGrid.SpeedButton1Click(Sender: TObject);
begin
  with Sender as TSpeedButton do
    begin
      Panel4.Visible    := Down;
      Splitter1.Visible := Down;
 //     Splitter1.Left    := Panel4.Left - Splitter1.Width;
    end;
end;

procedure TFGrid.FormActivate(Sender: TObject);
begin
  Panel2Resize(Panel2);
  UpdateTreeAreas;
end;

procedure TFGrid.ToolButton1Click(Sender: TObject);
const
  Indexes : array[boolean] of integer = (0, 5);
  Hints   : array[boolean] of string  = ('Animar', 'Pausa' );
begin
  fPlaying := not fPlaying;
  ToolButton1.ImageIndex := Indexes[fPlaying];
  ToolButton1.Hint := Hints[fPlaying];
  Timer1.Interval := theSettings.DefaultAnmDelay;
  Timer1.Enabled := fPlaying;
end;

function TFGrid.GetFormAuto : TFormAuto;
begin
  if fFormAuto = nil
    then
      begin
        if assigned(Animation)
          then fFormAuto := TAnimationAuto.Create
          else fFormAuto := TGridAuto.Create;
        fFormAuto.Form := Self
      end;
  Result := fFormAuto;
end;

function TFGrid.GetOleObject : variant;
begin
  Result := FormAuto.OleObject;
end;

procedure TFGrid.SetAnimation( A : TAnimation );
begin
  if assigned(fAnimation) and (A <> fAnimation)
    then
      begin
        CheckAnimationSave;
        fAnimation.OnDestroy := nil;
        FreeAndNil(fAnimation);
      end;
  fAnimation := A;
  if assigned(fAnimation)
    then
      begin
        fAnimation.Ondestroy := AnimationDestroy;
        TrackBar1.Max := pred(fAnimation.Frames);
        // Parche para salir siempre animada
        // ToolButton1Click(Self);
        ToolBar1.Visible := true;
      end;
end;

function TFGrid.GetPosition : integer;
begin
  if assigned(fAnimation)
    then Result := Animation.Position
    else Result := 0;
end;

procedure TFGrid.SetPosition( P : integer );
begin
  TrackBar1.Position := P;
  if Animation.Position <> TrackBar1.Position
    then Animation.Position := TrackBar1.Position;
  TrackBar1.Hint := IntToStr(P + 1);
  Update;
end;

procedure TFGrid.AnimationDestroy( Sender : TObject );
begin
  Timer1.Enabled := false;
  CheckAnimationSave;
  fAnimation := nil;
end;

procedure TFGrid.CheckAnimationSave;
begin
  if not Application.Terminated and
     (copy(Animation.FileName, 1, length(AnimationPrefix)) = AnimationPrefix) and
     (Application.MessageBox('¿Desea salvar la animacion?',
                             'Animacion',
                              MB_ICONQUESTION or MB_YESNO) = IDYES)
    then Salvar1Click(Self);
end;

procedure TFGrid.Timer1Timer(Sender: TObject);
begin
  if Position < pred(Animation.Frames)
    then Position := Position + 1
    else
      begin
        sleep(Timer1.Interval*3);
        Position := 0;
      end;
end;

procedure TFGrid.TrackBar1Change(Sender: TObject);
begin
  with TrackBar1 do
    begin
      if assigned(Animation)
        then Animation.Position := Position;
      Hint := IntToStr(Position + 1);
    end;
end;

procedure TFGrid.Panel3Resize(Sender: TObject);
begin
  UpdateZoom;
end;

procedure TFGrid.Escala1Click(Sender: TObject);
begin
  with Escala1 do
    begin
      Checked := not Checked;
      SpeedButton1.Down := Checked;
    end;
  SpeedButton1Click(SpeedButton1);
end;

procedure TFGrid.Splitter1CanResize(Sender: TObject; var NewSize: Integer;
  var Accept: Boolean);
begin
  if NewSize > (ClientWidth - 100)
    then NewSize := ClientWidth - 100;
end;

procedure TFGrid.SpeedButton2Click(Sender: TObject);
begin
    // Angles
  UpDown3.Max := 2;
  UpDown3.Min := 1;

  with SpeedButton2 do
    begin
      Panel1.Visible := Down;
      Splitter2.Visible := Down;
      if Down then CalculateWinds
      else
        begin
          fEnableWind := false;
          UpdateBuffBitMap;
        end;
    end;
end;

procedure TFGrid.CalculateWinds;
var
  i, Channel: integer;
  Scan: TScan;
  DataSource: TObservation;
  WindArea: TArea;
begin
  FreeAndNil(fWindGrid);
  if not assigned(fProduct) then exit;
  DataSource := TObservation(fProduct.DataSource);
  Channel := TGridProduct(fProduct).Channel;
  with DataSource.Channel[Channel] do
    Scan := TPPIScan.Initialize(PlanePoint(Cells, Sectors), UnMS, 1, Beam);
  Scan.Render(DataSource, Channel);
  fWindLength := UpDown2.Position;
  with Grid do
    fWindGrid := TWindGrid.Initialize(PlaneArea(Area.Left   * 1000 div fWindLength,
                                                Area.Bottom * 1000 div fWindLength,
                                                Area.Right  * 1000 div fWindLength,
                                                Area.Top    * 1000 div fWindLength), fWindLength);
  try
    fWindGrid.RenderScan(Scan);
    fEnableWind := true;
    UpdateBuffBitMap;
  finally
  end;
end;

function TFGrid.XFromAngle;
begin
  result := Round(aRadius*cos(anAngle));
end;

function TFGrid.YFromAngle;
begin
  result := Round(aRadius*sin(anAngle));
end;

procedure TFGrid.Edit2Change(Sender: TObject);
begin
//  CalculateWinds;
end;

procedure TFGrid.UpDown3Click(Sender: TObject; Button: TUDBtnType);
begin
  with TObservation(fProduct.DataSource) do
//    Label4.Caption := FloatToStrF(CodeAngle(Movement[UpDown3.Position - 1].Angle), ffFixed, 10, 2)
end;

procedure TFGrid.UpDown2Changing(Sender: TObject;
  var AllowChange: Boolean);
begin
  CalculateWinds;
end;

procedure TFGrid.Siembra1Click(Sender: TObject);
begin
  FSow.Show;
end;

procedure TFGrid.Distancia1Click(Sender: TObject);
begin
  with Distancia1 do
    begin
      Checked := not Checked;
      if Checked then
        begin
          HideMovMark1;
          fEnableMovMark1 := true;
          Grid1 := Self;
          MovMark1.X := 10;
          MovMark1.Y := 10;
          MovMark1Loc := Grid2Loc(MovMark1);
          CheckMovMarks;
        end
      else
        HideMovMark1;
      UpdateBuffBitmap;
    end;
end;

procedure TFGrid.Distancia2Click(Sender: TObject);
begin
  with Distancia2 do
    begin
      Checked := not Checked;
      if Checked then
        begin
          HideMovMark2;
          fEnableMovMark2 := true;
          Grid2 := Self;
          MovMark2.X := -10;
          MovMark2.Y := -10;
          MovMark2Loc := Grid2Loc(MovMark2);
          CheckMovMarks;
        end
      else
        HideMovMark2;
      UpdateBuffBitmap;
    end;
end;

procedure TFGrid.Archivo1Click(Sender: TObject);
begin
  CalcularDistancia1.Enabled := MarksAssigned;
end;

procedure TFGrid.CalcularDistancia1Click(Sender: TObject);
begin
  CheckMovMarks
end;

procedure TFGrid.Vista1Click(Sender: TObject);
begin
  Distancia1.Visible := fProduct is THorzProduct;
  Distancia2.Visible := fProduct is THorzProduct;
  Distancia1.Checked := fEnableMovMark1;
  Distancia2.Checked := fEnableMovMark2;
  Perfil1.Visible := fProduct is THorzProduct;
  Fronteras1.Visible := fProduct is THorzProduct;
  RejillaLatLon1.Visible := fProduct is THorzProduct;
  Escala1.Checked := SpeedButton1.Down;
  NMEA.Visible := fProduct is THorzProduct;
  Circulo1.Visible := fProduct is THorzProduct;
end;

procedure TFGrid.Perfil1Click(Sender: TObject);
begin
  with Perfil1 do
    begin
      Checked := not Checked;
      fEnableProfileMark := Checked;
      if Checked then
        UpdateProfile(Box2Meter(Grid2Box(ProfileMark)));
      UpdateBuffBitmap;
    end;
end;

procedure TFGrid.RejillaLatiudLongitud1Click(Sender: TObject);
begin
  with TFGapColor.Create(Self) do
    try
      Caption := 'Rejilla Latitud Longitud';
      Label4.Caption := 'Latitud:';
      Label5.Caption := 'Longitud:';
      Label2.Caption := 'º';
      Label2.Left := Label2.Left - 20;
      Label3.Left := Label3.Left - 20;
      Label3.Caption := 'º';
      UpDown1.Visible := false;
      UpDown2.Visible := false;
      with fLatLonGap do
        begin
          Edit1.Text := FloatToStrF(Latitude, ffFixed, 7, 2);
          Edit2.Text := FloatToStrF(Longitude, ffFixed, 7, 2);
        end;
      Color   := fLatLonColor;
      with fLatLonGap do
        repeat
          if ShowModal = mrOk then
              begin
                Latitude := StrToFloat(Edit1.Text);
                Longitude := StrToFloat(Edit2.Text);
                fLatLonColor := Color;
              end;
        until (Latitude > 0) and (Longitude > 0);
      if RejillaLatLon1.Checked
        then UpdateMaskBitmap;
    finally
      Free;
    end;
end;

procedure TFGrid.DirMonitor1Change(sender: TObject; Action: TAction;
  FileName: String);
begin
  UpdateBuffBitmap;
end;

procedure TFGrid.ATTEXRusia1Click(Sender: TObject);
begin
  with ATTEXRusia1 do
    begin
      Checked := not Checked;
      FShell.StatusBar2.Visible := Checked;
      with DirMonitor1 do
        if Checked then
          begin
            Directory := ExtractFilePath(TheSettings.NMEA_ATTEX);
            Active := true;
          end
        else
          begin
            Directory := 'c:\';
            Active := false;
          end;
    end;
  UpdateBuffBitmap;
end;

procedure TFGrid.Crculo1Click(Sender: TObject);
var
  i, j: integer;
begin
  with TFCircleEdit.Create(Self) do
    try
      ComboBox1Change(Sender);
      if ShowModal = mrOk
        then
          begin
            fCirCenter[ComboBox1.ItemIndex]     := Gap;
            fCirColor[ComboBox1.ItemIndex]      := Color;
            fCirRad[ComboBox1.ItemIndex]        := Radio;
            fCirShowCenter[ComboBox1.ItemIndex] := ShowCenter;
            fCirShow[ComboBox1.ItemIndex]       := ShowCir;
            fCirShowNumber[Combobox1.ItemIndex] := ShowNumber;
            fCirShowRad[Combobox1.ItemIndex]    := ShowRad;
            if AllCircles.Checked then
              begin
                for i := 0 to FShell.MDIChildCount - 1 do
                  if (FShell.MDIChildren[i] is TFGrid) then
                    for j := 0 to CircCount - 1 do
                      begin
                        TFGrid(FShell.MDIChildren[i]).fCirCenter[j]     := fCirCenter[j];
                        TFGrid(FShell.MDIChildren[i]).fCirColor[j]      := fCirColor[j];
                        TFGrid(FShell.MDIChildren[i]).fCirRad[j]        := fCirRad[j];
                        TFGrid(FShell.MDIChildren[i]).fCirShowCenter[j] := fCirShowCenter[j];
                        TFGrid(FShell.MDIChildren[i]).fCirShow[j]       := fCirShow[j];
                        TFGrid(FShell.MDIChildren[i]).fCirShowNumber[j] := fCirShowNumber[j];
                        TFGrid(FShell.MDIChildren[i]).fCirShowRad[j]    := fCirShowRad[j];
                        if TFGrid(FShell.MDIChildren[i]).Circulo1.Checked then
                          TFGrid(FShell.MDIChildren[i]).UpdateMaskBitmap;
                      end
              end
            else if Circulo1.Checked
              then UpdateMaskBitmap;
          end;
    finally
      Free;
    end;
end;

procedure TFGrid.DispositivoNMEA1Click(Sender: TObject);
begin
  FEditNMEA.Show;
end;

procedure TFGrid.ReconstruirTrayectoria1Click(Sender: TObject);
begin
  with ReconstruirTrayectoria1 do
    begin
      Checked := not Checked;
      FEditNMEA.Reload;
      FEditNMEA.Show;
    end;
  UpdateBuffBitmap;
end;

end.


