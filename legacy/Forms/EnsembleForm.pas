unit EnsembleForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, StdCtrls, ComCtrls, Buttons, Grids, ExtCtrls,
  Ensemble, FormAuto, Product, Animation;

type
  TFEnsemble = class(TForm)
    MainMenu1: TMainMenu;
    Panel1: TPanel;
    Label15: TLabel;
    ProgressBar1: TProgressBar;
    Button1: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TrackBar1: TTrackBar;
    ListView2: TListView;
    StringGrid2: TStringGrid;
    TabSheet5: TTabSheet;
    StringGrid3: TStringGrid;
    Button2: TButton;
    Button3: TButton;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    ListView1: TListView;
    Label1: TLabel;
    StringGrid1: TStringGrid;
    Memo1: TMemo;
    Label14: TLabel;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit2: TEdit;
    Edit1: TEdit;
    Label13: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label7: TLabel;
    Label4: TLabel;
    Edit5: TEdit;
    Bevel1: TBevel;
    Edit6: TEdit;
    SaveDialog1: TSaveDialog;
    OpenDialog1: TOpenDialog;
    PopupMenu1: TPopupMenu;
    Producto1: TMenuItem;
    N1: TMenuItem;
    Animacion1: TMenuItem;
    PopupMenu2: TPopupMenu;
    Abrir1: TMenuItem;
    N3: TMenuItem;
    Aadir1: TMenuItem;
    Eliminar1: TMenuItem;
    N4: TMenuItem;
    Conjunto2: TMenuItem;
    PopupMenu3: TPopupMenu;
    Predefinido1: TMenuItem;
    Editar1: TMenuItem;
    Mostrar1: TMenuItem;
    Producto2: TMenuItem;
    N2: TMenuItem;
    Animacion2: TMenuItem;
    Label5: TLabel;
    Edit7: TEdit;
    UpDown1: TUpDown;
    Label6: TLabel;
    Edit8: TEdit;
    Label8: TLabel;
    UpDown2: TUpDown;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ProductClick(Sender: TObject);
    procedure AnimationClick(Sender: TObject);
    procedure SpeedButtonClick(Sender: TObject);
    procedure Salvar1Click(Sender: TObject);
    procedure EditChange(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Abrir1Click(Sender: TObject);
    procedure Conjunto2Click(Sender: TObject);
    procedure StringGrid3KeyPress(Sender: TObject; var Key: Char);
    procedure StringGrid2Enter(Sender: TObject);
    procedure StringGrid2Exit(Sender: TObject);
  private
  //fProductThread : TThread;
    fProductMutex  : THandle;
  public
    property ProductMutex : THandle read fProductMutex;
  private
    fEnsemble : TEnsemble;
    fFormAuto : TFormAuto;
    function  GetFormAuto  : TFormAuto;
    function  GetOleObject : variant;
    procedure SetEnsemble       ( anEnsemble : TEnsemble );
    procedure ResetEnsemble;
    procedure ProgressNotify    ( Progress : integer );
    procedure AddProduct        ( Container : TContainer; Index : integer );
    {
    procedure AddTSpProduct     ( Container : TContainer; Index : integer );
    procedure DefaultAnimation  ( Container : TContainer );
    procedure CustomAnimation   ( Container : TContainer );
    procedure DefaultProduct    ( Container : TContainer );
    procedure CustomProduct     ( Container : TContainer );
    }
    procedure ClearContainerList( ListView  : TListView );
    procedure UpdateProductMenus;
    procedure UpdateStepView;
    procedure UpdateObsView;
  private
    procedure CMWinIniChange( var Message : TWMWinIniChange );  message CM_WININICHANGE;
  public  // for friends only (TEnsembleAuto)
    procedure UpdateEnsembleView;
  public
    property Ensemble  : TEnsemble read fEnsemble   write SetEnsemble;
    property FormAuto  : TFormAuto read GetFormAuto write fFormAuto;
    property OleObject : variant   read GetOleObject;
  public
    function  GetStpProduct  ( const S : string   ) : TProduct;
    function  GetAnmProduct  ( const S : string   ) : TProduct;
    function  CreateProduct  (       P : TProduct ) : TProduct;
    procedure CreateAnimation(       P : TProduct );
    function  RenderProduct  (       P : TProduct ) : TProduct;
    function  RenderAnimation(       P : TProduct ) : TAnimation;
    procedure RenderInit     ( const S : string   );
    procedure RenderDone;
  end;

var
  FEnsemble: TFEnsemble;

implementation

{$R *.DFM}

uses
  Configuration, Settings,
  FormUtils,
  EnsembleAuto,
  Description, Angle,
  Observation,
  Products, Radars,
  Shell_Process,
  Notify;

const
  StringGrid1ColWidths : array[0..4] of integer = (20, 60, 40, 40, 120);
  StringGrid2ColWidths : array[0..5] of integer = (20, 50, 50, 30, 40, 70);
  StringGrid3ColWidths : array[0..6] of integer = (20, 25, 50, 40, 30, 35, 100);


type
  TRenderingThread = class(TThread)
  public
    constructor Create( EForm : TFEnsemble; Product : TProduct );
    destructor  Destroy;  override;
  protected
    procedure Execute;  override;
  protected
    fEnsemble  : TEnsemble;
    fProduct   : TProduct;
    fEForm     : TFEnsemble;
    fNotify    : TNotify;
    fProgress  : integer;
    fException : Exception;
    procedure DoException;
    procedure DoInitialize;
    procedure DoNotify;
    procedure VisualNotify( aProgress : integer );
    procedure Render;       virtual;  abstract;
    procedure DoTerminate;  override;
  public
    property Product : TProduct read fProduct;
  end;

  TProductThread = class(TRenderingThread)
  protected
    procedure Render;  override;
  end;

  TAnimationThread = class(TRenderingThread)
  private
    fAnimation : TAnimation;
    procedure DoShowAnimation;
  protected
    procedure Render;  override;
  end;

// TRenderingThread methods

constructor TRenderingThread.Create( EForm : TFEnsemble; Product : TProduct );
begin
  FreeOnTerminate  := true;
  ReturnValue      := 0;
  fEForm           := EForm;
  fProduct         := Product;
  fEnsemble        := EForm.Ensemble;
  fNotify          := EForm.ProgressNotify;
  FShell.BusyCount := fShell.BusyCount + 1;
  inherited Create(false);
  Priority := tpHigher;
end;

destructor TRenderingThread.Destroy;
begin
  if ReturnValue <> 0
    then FreeAndNil(fProduct);
  FShell.BusyCount := FShell.BusyCount - 1;
  inherited;
end;

procedure TRenderingThread.DoTerminate;
begin
  inherited;
  Synchronize(fEForm.RenderDone);
end;

procedure TRenderingThread.DoException;
begin
  Application.ShowException(fException);
end;

procedure TRenderingThread.DoInitialize;
begin
  if Self is TAnimationThread
    then fEForm.RenderInit('Creando animacion, ' + Product.Name + '...')
    else fEForm.RenderInit('Creando '            + Product.Name + '...');
end;

procedure TRenderingThread.DoNotify;
begin
  fNotify(fProgress);
end;

procedure TRenderingThread.VisualNotify( aProgress : integer );
begin
  fProgress := aProgress;
  Synchronize(DoNotify);
end;

procedure TRenderingThread.Execute;
begin
  try
    WaitForSingleObject(fEForm.ProductMutex, INFINITE);
    Notify.Create(VisualNotify);
    try
      Synchronize(DoInitialize);
      Render;
    finally
      Notify.Destroy;
      ReleaseMutex(fEForm.ProductMutex);
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

// TProductThread methods

procedure TProductThread.Render;
begin
  with fEForm.RenderProduct(fProduct) do
    if Rendered
      then Synchronize(Show);
end;


// TAnimationThread methods

procedure TAnimationThread.Render;
begin
  fAnimation := fEForm.RenderAnimation(fProduct);
  Synchronize(DoShowAnimation);
end;

procedure TAnimationThread.DoShowAnimation;
begin
  fAnimation.Position := 0;
end;

// TFEnsembleForm methods

function TFEnsemble.GetFormAuto : TFormAuto;
begin
  if fFormAuto = nil
    then
      begin
        fFormAuto := TEnsembleAuto.Create;
        fFormAuto.Form := Self;
      end;
  Result := fFormAuto;
end;

function TFEnsemble.GetOleObject : variant;
begin
  Result := FormAuto.OleObject;
end;

procedure TFEnsemble.SetEnsemble( anEnsemble : TEnsemble );
begin
  if assigned(fEnsemble) and (fEnsemble <> anEnsemble)
    then fEnsemble.Release;
  fEnsemble := anEnsemble;
  UpdateEnsembleView;
end;

procedure TFEnsemble.ResetEnsemble;
begin
  Caption := '';
  Memo1.Text := '';
  Edit5.Text := '';
  Edit1.Text := '';
  Edit2.Text := '';
  Edit3.Text := '';
  Edit4.Text := '';
  Edit6.Text := '';
  PageControl1.ActivePage := TabSheet1;
  PageControl1.Enabled := false;
  Button1.Enabled      := false;
end;

procedure TFEnsemble.ProgressNotify( Progress : integer );
begin
  ProgressBar1.Position := Progress;
end;

procedure TFEnsemble.AddProduct( Container : TContainer; Index : integer );
begin
  with Container do
    begin
      Owner      := Self;
      DataSource := Ensemble;
      with ListView1.Items.Add do
        begin
          Caption    := Product.Name;
          ImageIndex := Product.ImageIndex;
          Data       := Container;
          SubItems.Add(Product.ClassName);
          SubItems.Add(Product.Description);
        end;
      with ListView2.Items.Add do
        begin
          Caption    := Product.Name;
          ImageIndex := Product.ImageIndex;
          Data       := Container;
        end;
    end;
end;

procedure TFEnsemble.ClearContainerList( ListView : TListView );
var
  I : integer;
begin
  for I := ListView.Items.Count - 1 downto 0 do
    TContainer(ListView.Items[I].Data).Free;
  ListView.Items.Clear;
end;

procedure TFEnsemble.UpdateStepView;

  procedure AddEntry( Index : integer );
  var
    I : integer;
  begin
    with StringGrid2.Rows[StringGrid2.RowCount - 1], fEnsemble[Index] do
      begin
        // Numero
        Strings[0] := IntToStr(Index + 1);
        // Fecha
        Strings[1] := DateToStr(Time);
        // Hora
        Strings[2] := FormatDateTime('t', Time);
        // Radar
        Strings[3] := IntToStr(ord(Radar));
        // Angulos
        Strings[4] := FloatToStrF(CodeAngle(MoveDesc[0].Angle), ffFixed, 4, 1);
        for I := 1 to Movements - 1 do
          Strings[4] := Strings[4] + ', ' + FloatToStrF(CodeAngle(MoveDesc[I].Angle), ffFixed, 4, 1);
        // FileName
        Strings[5] := FileName;
      end;
    StringGrid2.RowCount := succ(StringGrid2.RowCount);
  end;

var
  I    : integer;
  S, F : TDateTime;
begin
  TrackBar1.Min := 0;
  TrackBar1.Max := fEnsemble.Steps;
  StringGrid2.RowCount := 2;
  StringGrid2.Rows[1].Clear;
  for I := 0 to fEnsemble.Observations - 1 do
    if fEnsemble.Step[I] = TrackBar1.Position
      then AddEntry(I);
  S := fEnsemble.FirstTime + TrackBar1.Position * fEnsemble.StepTime;
  F := S + fEnsemble.StepTime;
  Label1.Caption := Format('Desde %s-%s, hasta %s-%s',
                           [DateToStr(S), FormatDateTime('t', S),
                            DateToStr(F), FormatDateTime('t', F)]);
  if StringGrid2.RowCount > 2
    then StringGrid2.RowCount := pred(StringGrid2.RowCount);
end;

procedure TFEnsemble.UpdateObsView;
var
  I, J : integer;
begin
  StringGrid3.RowCount := succ(fEnsemble.Observations);
  for I := 0 to fEnsemble.Observations - 1 do
    begin
      with StringGrid3.Rows[I + 1], fEnsemble[I] do
        begin
          // Numero
          Strings[0] := IntToStr(I + 1);
          // Paso
          Strings[1] := IntToStr(fEnsemble.Step[I]);
          // Fecha
          Strings[2] := DateToStr(Time);
          // Hora
          Strings[3] := FormatDateTime('t', Time);
          // Radar
          Strings[4] := IntToStr(ord(Radar));
          // Angulos
          Strings[5] := FloatToStrF(CodeAngle(MoveDesc[0].Angle), ffFixed, 4, 1);
          for J := 1 to Movements - 1 do
            Strings[5] := Strings[5] + ', ' + FloatToStrF(CodeAngle(MoveDesc[J].Angle), ffFixed, 4, 1);
          // FileName
          Strings[6] := FileName;
        end;
    end;
end;

procedure TFEnsemble.UpdateProductMenus;
var
  I : integer;
  M : TMenuItem;
begin
  MenuItemClear(Producto1);
  MenuItemClear(Producto2);
  MenuItemClear(Animacion1);
  MenuItemClear(Animacion2);
  with ListView1 do
    for I := 0 to Items.Count - 1 do
      begin
        M := TMenuItem.Create(Self);
        M.Caption := Items[I].Caption + '...';
        M.OnClick := ProductClick;
        M.Tag     := I;
        Producto1.Add(M);
        M := TMenuItem.Create(Self);
        M.Caption := Items[I].Caption + '...';
        M.OnClick := ProductClick;
        M.Tag     := I;
        Producto2.Add(M);
        M := TMenuItem.Create(Self);
        M.Caption := Items[I].Caption + '...';
        M.OnClick := AnimationClick;
        M.Tag     := I;
        Animacion1.Add(M);
        M := TMenuItem.Create(Self);
        M.Caption := Items[I].Caption + '...';
        M.OnClick := AnimationClick;
        M.Tag     := I;
        Animacion2.Add(M);
      end;
end;

procedure TFEnsemble.CMWinIniChange( var Message : TWMWinIniChange );
begin
  UpdateEnsembleView;
  inherited;
end;

procedure TFEnsemble.UpdateEnsembleView;

  function EnsembleMemo : string;
  var
    R : TRadar;
    C : integer;
  begin
    with fEnsemble do
      begin
        if Observations = 1
          then Result := 'Una observacion de '
          else Result := IntToStr(Observations) + ' observaciones de ';
        C := 0;
        for R := rdLaBajada to rdGranPiedra do
          if R in Radars
            then inc(C);
        if C = 1
          then Result := Result + 'un radar en '
          else Result := Result + IntToStr(C) + ' radares en ';
        if Steps = 1
          then Result := Result + 'un paso'
          else Result := Result + IntToStr(Steps) + ' pasos';
      end;
  end;

  procedure FillRadarEntry( Row : TStrings; Radar : TRadar );
  begin
    with Radars.Find(Radar) do
      begin
        Row[0] := IntToStr(ord(Radar));
        Row[1] := Name;               // Nombre
        Row[2] := BrandStr(Brand);  // Modelo
        Row[3] := TrustStr(Trust);  // Calidad
        Row[4] := Owner;
      end;
  end;

var
  I : integer;
  R : TRadar;
  H, M, S, D : word;
begin
  if assigned(fEnsemble) and (fEnsemble.Observations > 0)
    then
      with fEnsemble do
        begin
          // Sistema
          Edit5.Text := System;
          // Fecha y hora
          // Desde
          Edit1.Text := FormatDateTime(LongDateFormat,  FirstTime);
          Edit3.Text := FormatDateTime(ShortTimeFormat, FirstTime);
          // Hasta
          Edit2.Text := FormatDateTime(LongDateFormat,  LastTime);
          Edit4.Text := FormatDateTime(ShortTimeFormat, LastTime);
          // Intervalo maximo
          Edit6.Text := FormatDateTime('h:mm:ss', TimeGap);
          // Memo
          Memo1.Text := EnsembleMemo;
          // Caption
          Caption := FormatDateTime('h:nn-ddddd', FirstTime) + ' a ' +
                     FormatDateTime('h:nn-ddddd', LastTime)  + ' - ' +
                     'Conjunto ' + System;
          // Radares
          StringGrid1.RowCount := succ(RadarCount);
          I := 0;
          for R := low(TRadar) to high(TRadar) do
            if R in Radars
              then
                begin
                  inc(I);
                  FillRadarEntry(StringGrid1.Rows[I], R);
                end;
          // Productos
          ClearContainerList(ListView1);
          ListView2.Items.Clear;
          {ClearContainerList(ListView2);}
          Products.EnumProducts(TObservation, true, AddProduct);
          UpdateProductMenus;
          // Paso
          UpdateStepView;
          SetRelColWidths(StringGrid2, StringGrid2ColWidths);
          // Observaciones
          UpdateObsView;
          SetRelColWidths(StringGrid3, StringGrid3ColWidths);
          // Duracion del paso
          DecodeTime(StepTime, H, M, S, D);
          Edit7.OnChange := nil;
          Edit8.OnChange := nil;
          Edit7.Text := IntToStr(H);
          Edit8.Text := IntToStr(M);
          Edit7.OnChange := EditChange;
          Edit8.OnChange := EditChange;
          //
          PageControl1.Enabled := true;
          Button1.Enabled      := true;
        end
    else ResetEnsemble;
end;

function TFEnsemble.GetStpProduct( const S : string ) : TProduct;
begin
  Result := FindProduct(ListView2, S);
end;

function TFEnsemble.GetAnmProduct( const S : string ) : TProduct;
begin
  Result := FindProduct(ListView1, S);
end;

procedure TFEnsemble.CreateAnimation( P : TProduct );
begin
  if assigned(P)
    then TAnimationThread.Create(Self, P);
end;

function TFEnsemble.CreateProduct( P : TProduct ) : TProduct;
begin
  if assigned(P)
    then TProductThread.Create(Self, P);
  Result := P;
end;

function TFEnsemble.RenderProduct( P : TProduct ) : TProduct;
begin
  //...
  Result := nil;
end;

function TFEnsemble.RenderAnimation( P : TProduct ) : TAnimation;
begin
  //...
  Result := nil;
end;

procedure TFEnsemble.RenderInit( const S : string );
begin
end;

procedure TFEnsemble.RenderDone;
begin
end;

// Component methods

procedure TFEnsemble.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet1;
  // Radares
  with StringGrid1.Rows[0] do
    begin
      Strings[0] := 'No.';
      Strings[1] := 'Nombre';
      Strings[2] := 'Modelo';
      Strings[3] := 'Calidad';
      Strings[4] := 'Ubicacion';
    end;
  SetRelColWidths(StringGrid1, StringGrid1ColWidths);
  // Animaciones
  with ListView1 do
    begin
      LargeImages := FShell.LargeImages;
      SmallImages := FShell.SmallImages;
    end;
  // Productos del paso
  with ListView2 do
    begin
      LargeImages := FShell.LargeImages;
      SmallImages := FShell.SmallImages;
    end;
  fProductMutex := CreateMutex(nil, false, nil);
  // Observaciones del paso
  with StringGrid2.Rows[0] do
    begin
      Strings[0] := 'No.';
      Strings[1] := 'Fecha';
      Strings[2] := 'Hora';
      Strings[3] := 'Radar';
      Strings[4] := 'Angulos';
      Strings[5] := 'Archivo';
    end;
  SetRelColWidths(StringGrid2, StringGrid2ColWidths);
  // Observaciones
  with StringGrid3.Rows[0] do
    begin
      Strings[0] := 'No.';
      Strings[1] := 'Paso';
      Strings[2] := 'Fecha';
      Strings[3] := 'Hora';
      Strings[4] := 'Radar';
      Strings[5] := 'Angulos';
      Strings[6] := 'Archivo';
    end;
  SetRelColWidths(StringGrid3, StringGrid3ColWidths);
  // OpenDialog
  OpenDialog1.InitialDir := theSettings.Observations;
  OpenDialog1.Filter     := ObservationFilter;
  // SaveDialog
  SaveDialog1.InitialDir := theSettings.Ensembles;
  SaveDialog1.Filter     := EnsembleFilter;
end;

procedure TFEnsemble.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if WaitForSingleObject(ProductMutex, 0) = WAIT_OBJECT_0
    then Action := caFree
    else Action := caNone;
end;

procedure TFEnsemble.FormResize(Sender: TObject);
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
          Edit5.Width    := Width - Edit5.Left - 10;
          Bevel1.Width   := Width - 20;
          Memo1.Width    := Width  - Memo1.Left - 15;
          Memo1.Height   := Height - Memo1.Top  - 15;
          UpDown1.Width  := 12;
          UpDown2.Width  := 12;
        end;
  // Radares
  with TabSheet2 do
    if Showing
      then
        begin
          StringGrid1.Width  := Width - 20;
          StringGrid1.Height := Height - 30;
          SetRelColWidths(StringGrid1, StringGrid1ColWidths);
        end;
  // Animacion
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
          SpeedButton4.Left := theWidth - SpeedButton4.Width - 10;
          SpeedButton3.Left := SpeedButton4.Left - SpeedButton3.Width;
          SpeedButton2.Left := SpeedButton3.Left - SpeedButton2.Width;
          SpeedButton1.Left := SpeedButton2.Left - SpeedButton1.Width;
          ListView1.Top    := SpeedButton1.Top + SpeedButton1.Height + 5;
          ListView1.Width  := Width - 20;
          ListView1.Height := Height - ListView1.Top - 10;
        end;
  // Paso
  with TabSheet4 do
    if Showing
      then
        begin
          TrackBar1.Hide;
          ListView2.Left     := Width - ListView2.Width - 10;
          ListView2.Height   := Height - 20;
          TrackBar1.Width    := Width - ListView2.Width - 15;
          Label1.Width       := Width - ListView2.Width - 30;
          StringGrid2.Width  := Width - ListView2.Width - 30;
          StringGrid2.Height := Height - StringGrid2.Top - 10;
          TrackBar1.Show;
          SetRelColWidths(StringGrid2, StringGrid2ColWidths);
        end;
  // Observaciones
  with TabSheet5 do
    if Showing
      then
        begin
          Button3.Left := Width - Button3.Width - 10;
          Button2.Left := Button3.Left - Button2.Width;
          Button2.Top  := Height - Button2.Height - 5;
          Button3.Top  := Button2.Top;
          StringGrid3.Width  := Width - 20;
          StringGrid3.Height := Button2.Top - 25;
          SetRelColWidths(StringGrid3, StringGrid3ColWidths);
        end;
end;

procedure TFEnsemble.Button1Click(Sender: TObject);
var
  P : TPoint;
begin
  P.X := Button1.Width;
  P.Y := 0;
  P := Button1.ClientToScreen(P);
  PopupMenu1.Popup(P.X, P.Y);
end;

procedure TFEnsemble.ProductClick(Sender: TObject);
begin
  CreateProduct(TContainer(ListView2.Items[(Sender as TMenuItem).Tag].Data).Default);
end;

procedure TFEnsemble.AnimationClick(Sender: TObject);
begin
  CreateAnimation(TContainer(ListView1.Items[(Sender as TMenuItem).Tag].Data).Default);
end;

procedure TFEnsemble.SpeedButtonClick(Sender: TObject);
begin
  ListView1.ViewStyle := TViewStyle((Sender as TSpeedButton).Tag);
end;

procedure TFEnsemble.Salvar1Click(Sender: TObject);
begin
  with SaveDialog1 do
    if Execute
      then fEnsemble.Save(FileName);
end;

procedure TFEnsemble.EditChange(Sender: TObject);
var
  T : TDateTime;
begin
  T := EncodeTime(StrToInt(Edit7.Text), StrToInt(Edit8.Text), 0, 0);
  if T >= aMinute
    then
      begin
        fEnsemble.StepTime := T;
        UpdateEnsembleView;
      end;
end;

procedure TFEnsemble.TrackBar1Change(Sender: TObject);
begin
  UpdateStepView;
end;

procedure TFEnsemble.Button2Click(Sender: TObject);
begin
  with OpenDialog1 do
    if Execute
      then
        begin
          fEnsemble.AddFiles(Files);
          UpdateEnsembleView;
        end;
end;

procedure TFEnsemble.Button3Click(Sender: TObject);
var
  I : integer;
begin
  for I := StringGrid3.Selection.Bottom - 1 downto StringGrid3.Selection.Top - 1 do
    fEnsemble.Delete(I);
  UpdateEnsembleView;
end;

procedure TFEnsemble.Abrir1Click(Sender: TObject);
var
  I : integer;
begin
  if ActiveControl is TStringGrid
    then
      with TStringGrid(ActiveControl) do
        for I := Selection.Top to Selection.Bottom do
          begin
            TObservation(fEnsemble[pred(StrToInt(Cells[0, I]))]).AddRef;
            FShell.ShowObservation(TObservation(fEnsemble[pred(StrToInt(Cells[0, I]))]), wsNormal);
          end;
end;

procedure TFEnsemble.Conjunto2Click(Sender: TObject);
var
  E : TEnsemble;
  I : integer;
begin
  E := TEnsemble.Create;
  E.StepTime := fEnsemble.StepTime;
  for I := StringGrid3.Selection.Top - 1 to StringGrid3.Selection.Bottom - 1 do
    begin
      TObservation(fEnsemble[I]).AddRef;
      E.Insert(TObservation(fEnsemble[I]));
    end;
  FShell.ShowEnsemble(E);
end;

procedure TFEnsemble.StringGrid3KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13
    then
      with (Sender as TStringGrid).Selection do
        if Bottom > Top
          then Conjunto2Click(Conjunto2)
          else Abrir1Click(Abrir1);
end;

procedure TFEnsemble.StringGrid2Enter(Sender: TObject);
begin
  Aadir1.Enabled := false;
  Eliminar1.Enabled := false;
end;

procedure TFEnsemble.StringGrid2Exit(Sender: TObject);
begin
  Aadir1.Enabled := true;
  Eliminar1.Enabled := true;
end;

end.
