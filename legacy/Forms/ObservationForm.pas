unit ObservationForm;

interface

uses
  Observation, Description, Scan, Movement, Measure, Grid,
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons, ExtCtrls,
  BarGauge, Grids, Menus, DdeMan, Spin, ComCtrls,
  Product, Plane, FormAuto;

type
  TFObservation = class(TForm)
    PopupMenu1: TPopupMenu;
    PopupMenu2: TPopupMenu;
    Lluvia1: TMenuItem;
    Topes1: TMenuItem;
    Precipitacion1: TMenuItem;
    Potencia1: TMenuItem;
    MainMenu1: TMainMenu;
    Mostrar1: TMenuItem;
    Lluvia2: TMenuItem;
    Topes2: TMenuItem;
    Volumen1: TMenuItem;
    Alturas2: TMenuItem;
    Volumen2: TMenuItem;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label7: TLabel;
    Bevel1: TBevel;
    Label13: TLabel;
    Edit1: TEdit;
    Edit3: TEdit;
    Edit5: TEdit;
    Edit4: TEdit;
    Edit6: TEdit;
    Edit2: TEdit;
    TabSheet2: TTabSheet;
    Label6: TLabel;
    Label2: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    GroupBox1: TGroupBox;
    Label5: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Edit8: TEdit;
    Edit9: TEdit;
    Edit10: TEdit;
    StringGrid1: TStringGrid;
    Edit13: TEdit;
    Edit14: TEdit;
    Edit15: TEdit;
    Edit7: TEdit;
    TabSheet4: TTabSheet;
    StringGrid2: TStringGrid;
    TabSheet3: TTabSheet;
    PopupMenu3: TPopupMenu;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    Editar1: TMenuItem;
    Predefinido1: TMenuItem;
    N2: TMenuItem;
    Producto2: TMenuItem;
    N1: TMenuItem;
    Producto1: TMenuItem;
    Memo1: TMemo;
    Reflectividad1: TMenuItem;
    Panel1: TPanel;
    Label15: TLabel;
    ProgressBar1: TProgressBar;
    Button1: TButton;
    Superior1: TMenuItem;
    SaveDialog1: TSaveDialog;
    Velocidad1: TMenuItem;
    N3: TMenuItem;
    Salvar2: TMenuItem;
    SaveDialog2: TSaveDialog;
    N4: TMenuItem;
    ZDR1: TMenuItem;
    PhiDP1: TMenuItem;
    KDP1: TMenuItem;
    RhoHV1: TMenuItem;
    GCP1: TMenuItem;
    TID1: TMenuItem;
    Animacion1: TMenuItem;
    Espacial2: TMenuItem;
    Espacial1: TMenuItem;
    ListView1: TListView;
    Eliminar1: TMenuItem;
    AnchoEspectral1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure LluviaClick(Sender: TObject);
    procedure MovementClick(Sender: TObject);
    procedure TopesClick(Sender: TObject);
    procedure SuperiorClick(Sender: TObject);
    procedure VolumenClick(Sender: TObject);
    procedure StringGrid3KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure StringGrid1SelectCell(Sender: TObject; Col, Row: Longint;
      var CanSelect: Boolean);
    procedure StringGrid1SetEditText(Sender: TObject; ACol, ARow: Longint;
      const Value: String);
    procedure StringGrid1GetEditText(Sender: TObject; ACol, ARow: Longint;
      var Value: string);
    procedure FormDestroy(Sender: TObject);
    procedure StringGridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpeedButtonClick(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure ListView1KeyPress(Sender: TObject; var Key: Char);
    procedure Editar1Click(Sender: TObject);
    procedure ProductoClick(Sender: TObject);
    procedure StringGrid2DblClick(Sender: TObject);
    procedure StringGrid2KeyPress(Sender: TObject; var Key: Char);
    procedure Salvar1Click(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure PopupMenu2Popup(Sender: TObject);
    procedure Salvar2Click(Sender: TObject);
    procedure Espacial1Click(Sender: TObject);
    procedure Eliminar1Click(Sender: TObject);
  private
    fProductMutex : THandle;
  public
    property ProductMutex : THandle read fProductMutex;
  private
    fObservation : TObservation;
    fFormAuto    : TFormAuto;
    function  GetFormAuto  : TFormAuto;
    function  GetOleObject : variant;
    procedure SetObservation( anObservation : TObservation );
    procedure ResetObservation;
    procedure UpdateObsView;
    procedure AddProduct    ( Container : TContainer; Index : integer );
    procedure MoveGraph     ( Index : integer; aMeasure : TMeasure );
    procedure DefaultProduct( Container : TContainer );
    procedure CustomProduct ( Container : TContainer );
    procedure UpdateProductMenus;
  private
    procedure CMWinIniChange( var Message : TWMWinIniChange );  message CM_WININICHANGE;
  public
    property Observation : TObservation read fObservation write SetObservation;
    property FormAuto    : TFormAuto    read GetFormAuto  write fFormAuto;
    property OleObject   : variant      read GetOleObject;
  public
    function  GetProduct     ( S : string   ) : TProduct;
    function  RenderProduct  ( P : TProduct ) : TProduct;
    procedure RenderInit     ( const S : string );
    procedure RenderDone;
    procedure CreateProduct  ( P : TProduct );
    procedure ProgressNotify ( Progress : integer );
    procedure SaveObservation( const FileName : string );
  end;

//var
//  FObservation: TFObservation;

function ChannelCaption( const Channel : TChannelDesc ) : string;

implementation

{$R *.DFM}

uses
  Configuration,
  Settings,
  FormUtils, TimeUtils,
  ObservationAuto,
  Angle, Notify,
  Products, Radars,
  GridProduct, PPI, RHI,
  Shell_Process,
  Translator, Translators,
  VestaFile, DRFile, CDFFile, RawFile, VestaTranslator;

const
  StringGrid1ColWidths : array[0..8] of integer = (20, 45, 40, 40, 40, 50, 50, 52, 52);
  StringGrid2ColWidths : array[0..6] of integer = (20, 80, 55, 60, 50, 50, 50);

type
  TProductThread = class(TThread)
  public
    constructor Create( ObsForm : TFObservation; Product : TProduct );
    destructor  Destroy;  override;
  protected
    procedure Execute;  override;
  private
    fProduct   : TProduct;
    fObsForm   : TFObservation;
    fNotify    : TNotify;
    fProgress  : integer;
    fException : Exception;
    procedure DoException;
    procedure DoInitialize;
    procedure DoNotify;
    procedure VisualNotify( aProgress : integer );
    procedure DoTerminate;  override;
  public
    property Product : TProduct read fProduct;
  end;

// TProductThread methods

constructor TProductThread.Create( ObsForm : TFObservation; Product : TProduct );
begin
  FreeOnTerminate := true;
  ReturnValue     := 0;
  fObsForm := ObsForm;
  fProduct := Product;
  fNotify  := ObsForm.ProgressNotify;
  FShell.BusyCount := fShell.BusyCount + 1;
  inherited Create(false);
end;

destructor TProductThread.Destroy;
begin
  if ReturnValue <> 0
    then FreeAndNil(fProduct);
  FShell.BusyCount := FShell.BusyCount - 1;
  inherited;
end;

procedure TProductThread.Execute;
begin
  try
    WaitForSingleObject(fObsForm.ProductMutex, INFINITE);
    Notify.Create(VisualNotify);
    try
      Synchronize(DoInitialize);
      with fObsForm.RenderProduct(Product) do
        if Rendered
          then Synchronize(Show)
          else Free;
    finally
      Notify.Destroy;
      ReleaseMutex(fObsForm.ProductMutex);
    end;
  except
    on E : Exception do
      begin
        fException := E;
        Synchronize(DoException);
        ReturnValue := -1;
      end;
  end;
end;

procedure TProductThread.DoException;
begin
  Application.ShowException(fException);
end;

procedure TProductThread.DoInitialize;
begin
  fObsForm.RenderInit('Creando ' + Product.Name + '...');
end;

procedure TProductThread.DoTerminate;
begin
  inherited;
  Synchronize(fObsForm.RenderDone);
end;

procedure TProductThread.DoNotify;
begin
  fNotify(fProgress);
end;

procedure TProductThread.VisualNotify( aProgress : integer );
begin
  fProgress := aProgress;
  Synchronize(DoNotify);
end;

// Public procedures & functions

function ChannelCaption( const Channel : TChannelDesc ) : string;
begin
  try
    with Channel do
      begin
        case Wave of
          wl3cm  : Result := '3 cm';
          wl10cm : Result := '10 cm';
        end;
        case Pulse of
          plLong  : Result := Result + ', largo, ';
          plShort : Result := Result + ', corto, ';
        end;
        Result := Result + IntToStr(Cells) + 'x' + IntToStr(Length);
      end;
  except
    on EConvertError do
      Result := '';
  end;
end;

// TFObservation methods

function TFObservation.GetProduct( S : string ) : TProduct;
begin
  Result := FindProduct(ListView1, S);
end;

procedure TFObservation.CreateProduct( P : TProduct );
begin
  if assigned(P)
    then TProductThread.Create(Self, P);
end;

function TFObservation.RenderProduct( P : TProduct ) : TProduct;
begin
  if assigned(P)
    then
      begin
        P.DataSource := Observation;
        P.Render;
      end;
  Result := P;
end;

procedure TFObservation.RenderInit( const S : string );
begin
  Update;
  ProgressBar1.Position := 0;
  Label15.Caption := S;
  ProgressBar1.Show;
  Label15.Show;
end;

procedure TFObservation.RenderDone;
begin
  Label15.Hide;
  ProgressBar1.Hide;
  Label15.Caption := '';
  ProgressBar1.Position := 0;
end;

procedure TFObservation.DefaultProduct( Container : TContainer );
begin
  CreateProduct(Container.Default);
end;

procedure TFObservation.CustomProduct( Container : TContainer );
begin
  CreateProduct(Container.Custom);
end;

function TFObservation.GetFormAuto : TFormAuto;
begin
  if fFormAuto = nil
    then
      begin
        fFormAuto := TObservationAuto.Create;
        fFormAuto.Form := Self;
      end;
  Result := fFormAuto;
end;

function TFObservation.GetOleObject : variant;
begin
  Result := FormAuto.OleObject;
end;

procedure TFObservation.SetObservation( anObservation : TObservation );
begin
  if assigned(fObservation) and (fObservation <> anObservation)
    then fObservation.Release;
  fObservation := anObservation;
  UpdateObsView;
end;

procedure TFObservation.UpdateObsView;

  function ObservationMemo : string;
  var
    I, HC, VC : integer;
  begin
    with fObservation do
      begin
        HC := 0;
        VC := 0;
        for I := 0 to Movements - 1 do
          with MoveDesc[I] do
            case Kind of
              pkHorizontal : inc(HC);
              pkVertical   : inc(VC);
            end;
        if HC > 0
          then
            if HC = 1
              then Result := 'Una exploracion horizontal'
              else Result := IntToStr(HC) + ' exploraciones horizontales';
        if VC > 0
          then
            begin
              if Result <> ''
                then Result := Result + ' y ';
              if VC = 1
                then Result := 'Una exploracion vertical'
                else Result := IntToStr(VC) + ' exploraciones verticales';
            end;
        if Result <> ''
          then Result := Result + '.'
          else Result := 'Formato de observacion desconocido';
      end;
  end;

var
  I       : integer;
  SearchR : TSearchRec;
begin
  if assigned(fObservation)
    then
      with fObservation do
        begin
          // Sistema
          Edit5.Text := System;
          // Caption
          Caption := FormatDateTime('h:nn-ddddd', Time) + ' - ' + 'Observacion ' + System;
          // Fecha
          Edit1.Text := FormatDateTime(LongDateFormat, Time);
          // Hora
          //Edit6.Text := FormatDateTime(ShortTimeFormat, Time);
          Edit6.Text := FormatDateTime('hh:nn "Hora local"', Time) + ' ';
          Edit2.Text := FormatDateTime('hh:nn "Z"', LocalTimeToZTime(Time));
          // Archivo
          Edit3.Text := ExtractFileName(FileName);
          // Tamaño
          SysUtils.FindFirst(FileName, faAnyFile, SearchR);
          SysUtils.FindClose(SearchR);
          Edit4.Text := IntToStr(SearchR.Size) + ' bytes';
          // Memo
          Memo1.Text := ObservationMemo;
          // Radar
          with Radars.Find(Radar) do
            begin
              // Nombre
              Edit14.Text := Name;
              // Ubicacion
              Edit15.Text := Owner;
              // Modelo
              Edit13.Text := Radars.BrandStr(Brand);
              // Fabricante
              Edit7.Text := Radars.Manufacturer(Brand);
              // Coordenadas
              with Location do
                begin
                  // Latitud
                  Edit8.Text := FloatToStrF(Latitude, ffFixed, 6, 2) + '°';
                  // Longitud
                  Edit9.Text := FloatToStrF(Longitude, ffFixed, 6, 2) + '°';
                  // Altitud
                  Edit10.Text := FloatToStrF(Altitude, ffFixed, 4, 0) + ' m';
                end;
            end;
          // Canales (grid)
          StringGrid1.RowCount := Channels + 1;
          for I := 0 to Channels - 1 do
            FillChannelRow(StringGrid1.Rows[I + 1], Channel[I]);
          SetRelColWidths(StringGrid1, StringGrid1ColWidths);
          // Productos
          ListView1.Items.Clear;
          Products.EnumProducts(TObservation, false, AddProduct);
          UpdateProductMenus;
          // Exploraciones (grid)
          StringGrid2.RowCount := Movements + 1;
          for I := 1 to Movements do
            with StringGrid2.Rows[I], MoveDesc[pred(I)] do
              begin
                // Numero
                Strings[0] := IntToStr(I);
                // Hora
                try
                  Strings[1] := TimeToStr(Time);
                except
                  Strings[1] := 'Invalido';
                end;
                // Tipo
                case Kind of
                  pkHorizontal : Strings[2] := 'PPI';
                  pkVertical   : Strings[2] := 'RHI';
                  else Strings[2] := 'desconocido';
                end;
                // Canal
                Strings[3] := StringGrid1.Cells[0, succ(Channel)] + ' (' +
                              StringGrid1.Cells[1, succ(Channel)] + ')';
                // Angulo
                Strings[4] := FloatToStrF(CodeAngle(Angle), ffFixed, 5, 1);
                // Comienzo
                Strings[5] := FloatToStrF(CodeAngle(Start), ffFixed, 5, 1);
                // Fin
                Strings[6] := FloatToStrF(CodeAngle(Finish), ffFixed, 5, 1);
              end;
          SetRelColWidths(StringGrid2, StringGrid2ColWidths);
          PageControl1.Enabled := true;
          Lluvia1.Enabled      := true;
          Topes1.Enabled       := true;
          Superior1.Enabled    := true;
          Volumen1.Enabled     := true;
          Button1.Enabled      := true;
        end
    else ResetObservation;
end;

procedure TFObservation.ResetObservation;
begin
  Caption := '';
  Memo1.Text := '';
  Edit5.Text := '';
  Edit1.Text := '';
  Edit2.Text := '';
  Edit6.Text := '';
  Edit3.Text := '';
  Edit4.Text := '';
  PageControl1.ActivePage := TabSheet1;
  PageControl1.Enabled := false;
  Lluvia1.Enabled      := false;
  Topes1.Enabled       := false;
  Superior1.Enabled    := false;
  Volumen1.Enabled     := false;
  Button1.Enabled      := false;
end;

procedure TFObservation.ProgressNotify( Progress : integer );
begin
  ProgressBar1.Position := Progress;
end;

procedure TFObservation.AddProduct( Container : TContainer; Index : integer );
begin
  with Container do
    begin
      Owner      := Self;
      DataSource := Observation;
      with ListView1.Items.Add do
        begin
          Caption    := Product.Name;
          ImageIndex := Product.ImageIndex;
          Data       := Container;
//              SubItems.Add(Product.ClassName);
          SubItems.Add(Product.Description);
        end;
    end;
end;

procedure TFObservation.UpdateProductMenus;
var
  I : integer;
  M : TMenuItem;
begin
  MenuItemClear(Producto1);
  MenuItemClear(Producto2);
  with ListView1 do
    for I := 0 to Items.Count - 1 do
      begin
        M := TMenuItem.Create(Self);
        M.Caption := Items[I].Caption + '...';
        M.OnClick := ProductoClick;
        M.Tag     := I;
        Producto1.Add(M);
        M := TMenuItem.Create(Self);
        M.Caption := Items[I].Caption + '...';
        M.OnClick := ProductoClick;
        M.Tag     := I;
        Producto2.Add(M);
      end;
end;

procedure TFObservation.CMWinIniChange(var Message: TWMWinIniChange);
begin
  UpdateObsView;
  inherited;
end;

//  Component methods

procedure TFObservation.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet1;
  // Measure menu items
  Precipitacion1.Tag := ord(unMMH);
  Reflectividad1.Tag := ord(unDBZ);
  Potencia1     .Tag := ord(unDB);
  Velocidad1    .Tag := ord(unMS);
  // Canales
  with StringGrid1 do
    begin
      //DefaultRowHeight := 16;
      with Rows[0] do
        begin
          Strings[0] := 'No.';
          Strings[1] := 'Lambda';
          Strings[2] := 'Pulso';
          Strings[3] := 'Sector';
          Strings[4] := 'Celdas';
          Strings[5] := 'Tamaño';
          Strings[6] := 'Alcance';
          Strings[7] := 'Potencial';
          Strings[8] := 'Delta Pot.';
        end;
      SetRelColWidths(StringGrid1, StringGrid1ColWidths);
      Col := 8;
      Row := 1;
    end;
  // Exploraciones
  with StringGrid2 do
    begin
      //DefaultRowHeight := 16;
      with Rows[0] do
        begin
          Strings[0] := 'No.';
          Strings[1] := 'Hora';
          Strings[2] := 'Tipo';
          Strings[3] := 'Formato';
          Strings[4] := 'Angulo';
          Strings[5] := 'Comienzo';
          Strings[6] := 'Fin';
        end;
      SetRelColWidths(StringGrid2, StringGrid2ColWidths);
    end;
  // Productos
  with ListView1 do
    begin
      LargeImages := FShell.LargeImages;
      SmallImages := FShell.SmallImages;
    end;
  fProductMutex := CreateMutex(nil, false, nil);
end;

procedure TFObservation.FormDestroy(Sender: TObject);
begin
  if assigned(fFormAuto)
    then fFormAuto.Release;
  CloseHandle(fProductMutex);
  if assigned(fObservation)
    then fObservation.Release;
end;

procedure TFObservation.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE
    then Close;
end;

procedure TFObservation.MoveGraph( Index : integer; aMeasure : TMeasure );
var
  P : TProduct;
begin
  with fObservation.MoveDesc[Index] do
    begin
      case Kind of
        pkHorizontal : P := GetProduct('PPI');
        pkVertical   : P := GetProduct('RHI');
        else raise Exception.Create('Tipo de exploracion desconocido');
      end;
      if assigned(P)
        then
          begin
            (P as TGridProduct).Channel := Channel;
            (P as TGridProduct).Measure := aMeasure;
            case Kind of
              pkHorizontal : (P as TPPI).ScanIndex := Index;
              pkVertical   : (P as TRHI).ScanIndex := Index;
            end;
            CreateProduct(P);
          end;
    end;
end;

procedure TFObservation.Button1Click(Sender: TObject);
var
  P : TPoint;
begin
  P.X := Button1.Width;
  P.Y := 0;
  P := Button1.ClientToScreen(P);
  PopupMenu1.Popup(P.X, P.Y);
end;

procedure TFObservation.StringGrid3KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) or (Key = VK_SPACE)
    then PopupMenu2.Popup(Left + Width div 2, Top + Height div 2);
end;

procedure TFObservation.MovementClick(Sender: TObject);
var
  I : integer;
begin
  with StringGrid2 do
    for I := Selection.Top to Selection.Bottom do
      MoveGraph(I - 1, TMeasure((Sender as TMenuItem).Tag));
end;

procedure TFObservation.LluviaClick(Sender: TObject);
begin
  CreateProduct(GetProduct('CAPPI'));
end;

procedure TFObservation.TopesClick(Sender: TObject);
begin
  CreateProduct(GetProduct('Topes'));
end;

procedure TFObservation.SuperiorClick(Sender: TObject);
begin
  CreateProduct(GetProduct('Maximos'));
end;

procedure TFObservation.VolumenClick(Sender: TObject);
begin
  CreateProduct(GetProduct('Volumen'));
end;

procedure TFObservation.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if WaitForSingleObject(ProductMutex, 0) = WAIT_OBJECT_0
    then Action := caFree
    else Action := caNone;
end;

procedure TFObservation.FormResize(Sender: TObject);
var
  theWidth : integer;
begin
  Button1.Left       := Panel1.Width - Button1.Width - 2;
  ProgressBar1.Width := Button1.Left - 15;
  // Caracteristicas
  with TabSheet1 do
    if Showing
      then
        begin
          if Width < 270
            then theWidth := 270
            else theWidth := Width;
          Edit5.Width    := Width - Edit5.Left - 10;
          Bevel1.Width   := theWidth - 20;
          Label1. Left   := theWidth - 260;
          Label7. Left   := theWidth - 260;
          Label3. Left   := theWidth - 260;
          Label13.Left   := theWidth - 260;
          Edit1.Left     := theWidth - 210;
          Edit6.Left     := theWidth - 210;
          Edit2.Left     := theWidth - 210;
          Edit3.Left     := theWidth - 210;
          Edit4.Left     := theWidth - 210;
          Memo1.Width    := Label1.Left - 30;
          Memo1.Height   := Height - Memo1.Top - 15;
        end;
  // Radar
  with TabSheet2 do
    if Showing
      then
        begin
          StringGrid1.Width  := Width - 20;
          StringGrid1.Height := Height - StringGrid1.Top - 10;
          if Width < 350
            then theWidth := 350
            else theWidth := Width;
          GroupBox1.Left := theWidth - GroupBox1.Width - 10;
          Edit14.Width   := GroupBox1.Left - Edit14.Left - 10;
          Edit15.Width   := Edit14.Width;
          Edit13.Width   := Edit14.Width;
          Edit7.Width    := Edit14.Width;
        end;
  // Exploraciones
  with TabSheet4 do
    if Showing
      then
        begin
          StringGrid2.Width  := Width - 20;
          StringGrid2.Height := Height - 25;
        end;
  // Productos
  with TabSheet3 do
    if Showing
      then
        begin
          theWidth := SpeedButton1.Width +
                      SpeedButton2.Width +
                      SpeedButton3.Width +
                      SpeedButton4.Width + 20;
          if Width >= theWidth
            then theWidth := Width;
//          SpeedButton4.Left := theWidth - SpeedButton4.Width - 10;
//          SpeedButton3.Left := SpeedButton4.Left - SpeedButton3.Width;
//          SpeedButton2.Left := SpeedButton3.Left - SpeedButton2.Width;
//          SpeedButton1.Left := SpeedButton2.Left - SpeedButton1.Width;
//          ListView1.Top    := SpeedButton1.Top + SpeedButton1.Height + 5;
//          ListView1.Width  := Width - 20;
//          ListView1.Height := Height - ListView1.Top - 10;
        end;
  SetRelColWidths(StringGrid1, StringGrid1ColWidths);
  SetRelColWidths(StringGrid2, StringGrid2ColWidths);
end;

procedure TFObservation.StringGrid1SelectCell(Sender: TObject; Col,
  Row: Longint; var CanSelect: Boolean);
begin
  CanSelect := Col = 8;
end;

procedure TFObservation.StringGrid1SetEditText(Sender: TObject; ACol,
  ARow: Longint; const Value: String);
begin
  if aCol = 8
    then
      try
        fObservation.Delta[aRow - 1] := StrToFloat(Value);
      except
        on EConvertError do
          fObservation.Delta[aRow - 1] := 0.0;
      end;
end;

procedure TFObservation.StringGrid1GetEditText(Sender: TObject; ACol,
  ARow: Longint; var Value: string);
begin
  if aCol = 8
    then Value := FloatToStrF(fObservation.Delta[aRow - 1], ffFixed, 5, 2);
end;

procedure TFObservation.StringGridMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  C, R : longint;
begin
  with Sender as TStringGrid do
    begin
      MouseToCell(X, Y, C, R);
      if (R >= FixedRows) and ((R < Selection.Top) or (R > Selection.Bottom))  
        then Row := R;
    end;
end;

procedure TFObservation.SpeedButtonClick(Sender: TObject);
begin
  ListView1.ViewStyle := TViewStyle((Sender as TSpeedButton).Tag);
end;

procedure TFObservation.ListView1DblClick(Sender: TObject);
begin
  with ListView1 do
    if assigned(Selected)
      then DefaultProduct(Selected.Data);
end;

procedure TFObservation.ListView1KeyPress(Sender: TObject; var Key: Char);
begin
  case Key of
    #13 : ListView1DblClick(Sender);
    #32 : Editar1Click(Sender);
  end;
end;

procedure TFObservation.Editar1Click(Sender: TObject);
begin
  with ListView1 do
    if assigned(Selected)
      then CustomProduct(Selected.Data);
end;

procedure TFObservation.ProductoClick(Sender: TObject);
begin
  CreateProduct(TContainer(ListView1.Items[(Sender as TMenuItem).Tag].Data).Custom);
end;

procedure TFObservation.StringGrid2DblClick(Sender: TObject);
var
  i: integer;
begin
  PopupMenu2Popup(Sender);
  if Reflectividad1.Enabled then
    MovementClick(Reflectividad1)
  else if Precipitacion1.Enabled then
    MovementClick(Precipitacion1)
  else if Velocidad1.Enabled then
    MovementClick(Velocidad1)
  else if AnchoEspectral1.Enabled then
    MovementClick(AnchoEspectral1)
  else if ZDR1.Enabled then
    MovementClick(ZDR1)
  else if PhiDP1.Enabled then
    MovementClick(PhiDP1)
  else if KDP1.Enabled then
    MovementClick(KDP1)
  else if RhoHV1.Enabled then
    MovementClick(RhoHV1)
  else if GCP1.Enabled then
    MovementClick(GCP1)
  else if TID1.Enabled then
    MovementClick(TID1)
end;

procedure TFObservation.StringGrid2KeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key = #13 then StringGrid2DblClick(Sender);
end;

procedure TFObservation.PageControl1Change(Sender: TObject);
begin
  FormResize(Self);
end;

procedure TFObservation.Salvar1Click(Sender: TObject);
begin
  with SaveDialog1 do
    if Execute
      then SaveObservation(FileName);
end;

procedure TFObservation.SaveObservation(const FileName: string);
var
  T : TTranslator;
  I : integer;
  M : TMovement;
begin
  T := Translators.Find(FileName);
  if assigned(T)
    then
      try
        T.Create(FileName);
        T.Design    := Observation.Design;
        T.Radar     := Observation.Radar;
        T.DateTime  := Observation.Time;
        T.Movements := Observation.Movements;
        T.Channels  := Observation.Channels;
        for I := 0 to Observation.Channels - 1 do
          T.Channel[I] := Observation.Channel[I];
        for I := 0 to Observation.Movements - 1 do
          begin
            M := Observation.Movement[I];
            try
              T.MoveDesc[I] := Observation.MoveDesc[I];
              T.Movement[I] := M;
            finally
              M.Free;
            end;
          end;
        T.Close;
      finally
        T.Free;
      end
    else raise Exception.Create('Formato de observacion no soportado: ' + ExtractFileName(FileName));
end;

procedure TFObservation.PopupMenu2Popup(Sender: TObject);
var
  I : integer;
  A : TMeasureSet;
begin
  A := [];
  with StringGrid2 do
    for I := Selection.Top to Selection.Bottom do
      Include(A, Observation.MoveDesc[I - 1].Measure);
  Potencia1.      Enabled := (unDB  in A);
  Reflectividad1. Enabled := (unDB  in A) or (unDBZ in A);
  Precipitacion1. Enabled := (unDB  in A) or (unDBZ in A) or (unMMH in A) or (unKDP in A);
  Velocidad1.     Enabled := (unMS  in A);
  AnchoEspectral1.Enabled := (unSW  in A);
  ZDR1.           Enabled := (unZDR in A);
  PhiDP1.         Enabled := (unPDP in A);
  KDP1.           Enabled := (unKDP in A);
  RhoHV1.         Enabled := (unRHO in A);
  GCP1.           Enabled := (unGCP in A);
  TID1.           Enabled := (unTID in A);
end;

procedure TFObservation.Salvar2Click(Sender: TObject);
var
  I : integer;
begin
  with StringGrid2 do
    for I := Selection.Top to Selection.Bottom do
      with Observation.Movement[I - 1] do
        try
          with SaveDialog2 do
            if Execute
              then SaveBinary(FileName);
        finally
          Free;
        end;
end;

procedure TFObservation.Espacial1Click(Sender: TObject);
var
  P : CProduct;
  C : TContainer;
begin
  P := GetProductByName('Espacial');
  if assigned(P)
    then
      begin
        C := TContainer.Create(P);
        C.Owner := Self;
        C.DataSource := Observation;
        if (Sender as TMenuItem).Tag = 0
          then CreateProduct(C.Default)
          else CreateProduct(C.Custom);
      end
    else Espacial1.Enabled := false;
end;

procedure TFObservation.Eliminar1Click(Sender: TObject);
var
  T : TVestaTranslator;
  I, c : integer;
  M : TMovement;
  FileName, FileName1: string;
begin
  if MessageDlg('¿ Está seguro que desea eliminar el (los) PPI ?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      T := TVestaTranslator.CreateTranslator;
      with StringGrid2 do
        try
          FileName := ChangeFileExt(Observation.FileName, '.XXX');
          T.Create(Filename);
          T.Movements := Observation.Movements - (Selection.Bottom - Selection.Top) - 1;
          T.Design    := Observation.Design;
          T.Radar     := Observation.Radar;
          T.DateTime  := Observation.Time;
          T.Channels  := Observation.Channels;
          for I := 0 to Observation.Channels - 1 do
            T.Channel[I] := Observation.Channel[I];
          c := 0;
          for I := 0 to Observation.Movements - 1 do
            if not (I + 1 in [Selection.Top..Selection.Bottom]) then
              begin
                M := Observation.Movement[I];
                try
                  T.MoveDesc[c] := Observation.MoveDesc[I];
                  T.Movement[c] := M;
                  Inc(c);
                finally
                  M.Free;
                end;
              end;
          T.Close;
          FileName1 := Observation.FileName;
          Observation.Translator.Close;
          DeleteFile(PChar(FileName1));
          FileName1 := ChangeFileExt(FileName1, '.obs');
          RenameFile(PChar(FileName), PChar(FileName1));
          Observation := TObservation.Load(FileName1);
        finally
          T.Free;
        end
     end;
   end;
end.

