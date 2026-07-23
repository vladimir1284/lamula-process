unit TimeSpanForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, Bargauge, StdCtrls, ComCtrls, Buttons, Grids, ExtCtrls,
  TimeSpan, Observation, Product, Animation, FormAuto, GridForm;

type
  TFTimeSpan = class(TForm)
    MainMenu1: TMainMenu;
    Mostrar1: TMenuItem;
    N2: TMenuItem;
    Animacion2: TMenuItem;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Label4: TLabel;
    Bevel1: TBevel;
    Edit5: TEdit;
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
    Edit13: TEdit;
    Edit14: TEdit;
    Edit15: TEdit;
    Edit7: TEdit;
    TabSheet3: TTabSheet;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    ListView1: TListView;
    TabSheet4: TTabSheet;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    Animacion1: TMenuItem;
    Memo1: TMemo;
    Label1: TLabel;
    Label3: TLabel;
    Label7: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit6: TEdit;
    Label13: TLabel;
    Label14: TLabel;
    Edit3: TEdit;
    Edit4: TEdit;
    Button3: TButton;
    Button2: TButton;
    StringGrid2: TStringGrid;
    SaveDialog1: TSaveDialog;
    OpenDialog1: TOpenDialog;
    Lamina2: TMenuItem;
    Lamina1: TMenuItem;
    PopupMenu2: TPopupMenu;
    PopupMenu3: TPopupMenu;
    Predefinido1: TMenuItem;
    Editar1: TMenuItem;
    Abrir1: TMenuItem;
    Eliminar1: TMenuItem;
    N4: TMenuItem;
    Periodo2: TMenuItem;
    TabSheet5: TTabSheet;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton7: TSpeedButton;
    SpeedButton8: TSpeedButton;
    ListView2: TListView;
    N3: TMenuItem;
    Aadir1: TMenuItem;
    Panel1: TPanel;
    Label15: TLabel;
    ProgressBar1: TProgressBar;
    Button1: TButton;
    StringGrid1: TStringGrid;
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure AnimationClick(Sender: TObject);
    procedure Salvar1Click(Sender: TObject);
    procedure Abrir1Click(Sender: TObject);
    procedure StringGrid2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StringGrid2KeyPress(Sender: TObject; var Key: Char);
    procedure SpeedButton1Click(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure ListView1KeyPress(Sender: TObject; var Key: Char);
    procedure Editar1Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Periodo2Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure ListView2DblClick(Sender: TObject);
    procedure Predefinido1Click(Sender: TObject);
    procedure Lamina1Click(Sender: TObject);
    procedure StringGrid1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StringGrid1SelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure StringGrid1SetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: String);
    procedure StringGrid1GetEditText(Sender: TObject; ACol, ARow: Integer;
      var Value: String);
  private
    fProductMutex : THandle;
  public
    property ProductMutex : THandle read fProductMutex;
  private
    fTimeSpan : TTimeSpan;
    fFormAuto : TFormAuto;
    function  GetFormAuto  : TFormAuto;
    function  GetOleObject : variant;
    procedure SetTimeSpan       ( aTimeSpan : TTimeSpan );
    procedure ResetTimeSpan;
    procedure ProgressNotify    ( Progress : integer );
    procedure AddObsProduct     ( Container : TContainer; Index : integer );
    procedure AddTSpProduct     ( Container : TContainer; Index : integer );
    procedure DefaultAnimation  ( Container : TContainer );
    procedure CustomAnimation   ( Container : TContainer );
    procedure DefaultProduct    ( Container : TContainer );
    procedure CustomProduct     ( Container : TContainer );
    procedure ClearContainerList( ListView  : TListView );
    procedure UpdateProductMenus;
  private
    procedure CMWinIniChange( var Message : TWMWinIniChange );  message CM_WININICHANGE;
  public  // for friends only (TTimespanAuto)
    procedure UpdateTimeSpanView;
  public
    property TimeSpan  : TTimeSpan read fTimeSpan    write SetTimeSpan;
    property FormAuto  : TFormAuto read GetFormAuto  write fFormAuto;
    property OleObject : variant   read GetOleObject;
  public
    function  GetProduct     ( const S : string   ) : TProduct;
    function  GetAnmProduct  ( const S : string   ) : TProduct;
    function  CreateAnimation(       P : TProduct ) : TProduct;
    function  CreateProduct  (       P : TProduct ) : TProduct;
    function  RenderProduct  (       P : TProduct ) : TProduct;
    function  RenderAnimation(       P : TProduct ) : TAnimation;
    procedure RenderInit     ( const S : string   );
    procedure RenderDone;
  end;

var
  FTimeSpan: TFTimeSpan;

implementation

{$R *.DFM}

uses
  Configuration,
  Settings,
  Plane, Angle, Notify,
  FormUtils, TimeSpanAuto, GridProduct,
  Radars, Products,
  PRTable, HeightTable,
  Shell_Process;

const
  StringGrid1ColWidths : array[0..8] of integer = (20, 45, 40, 40, 40, 50, 50, 52, 52);
  //StringGrid1ColWidths : array[0..6] of integer = (20, 40, 40, 40, 40, 50, 50);
  StringGrid2ColWidths : array[0..4] of integer = (25, 55, 50, 45, 200);

type
  TRenderingThread = class(TThread)
  public
    constructor Create( TSForm : TFTimeSpan; Product : TProduct );
    destructor  Destroy;  override;
  protected
    procedure Execute;  override;
  protected
    fTimeSpan  : TTimeSpan;
    fProduct   : TProduct;
    fTSForm    : TFTimeSpan;
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

constructor TRenderingThread.Create( TSForm : TFTimeSpan; Product : TProduct );
begin
  FreeOnTerminate  := true;
  ReturnValue      := 0;
  fTSForm          := TSForm;
  fProduct         := Product;
  fTimeSpan        := TSForm.TimeSpan;
  fNotify          := TSForm.ProgressNotify;
  FShell.BusyCount := fShell.BusyCount + 1;
  inherited Create(false);
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
  Synchronize(fTSForm.RenderDone);
end;

procedure TRenderingThread.DoException;
begin
  Application.ShowException(fException);
end;

procedure TRenderingThread.DoInitialize;
begin
  if Self is TAnimationThread
    then fTSForm.RenderInit('Creando animacion, ' + Product.Name + '...')
    else fTSForm.RenderInit('Creando '            + Product.Name + '...');
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
    WaitForSingleObject(fTSForm.ProductMutex, INFINITE);
    Notify.Create(VisualNotify);
    try
      Synchronize(DoInitialize);
      Render;
    finally
      Notify.Destroy;
      ReleaseMutex(fTSForm.ProductMutex);
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
  with fTSForm.RenderProduct(fProduct) do
    if Rendered
      then Synchronize(Show)
      else Free;
end;

// TAnimationThread methods

procedure TAnimationThread.Render;
begin
  fAnimation := fTSForm.RenderAnimation(fProduct);
  if assigned(fAnimation)
    then Synchronize(DoShowAnimation);
end;

procedure TAnimationThread.DoShowAnimation;
begin
  fAnimation.Position := 0;
end;

// TFTimeSpan methods

function TFTimeSpan.CreateAnimation( P : TProduct ) : TProduct;
begin
  if assigned(P)
    then TAnimationThread.Create(Self, P);
  Result := nil;
end;

function TFTimeSpan.CreateProduct( P : TProduct ) : TProduct;
begin
  if assigned(P)
    then TProductThread.Create(Self, P);
  Result := P;
end;

procedure TFTimeSpan.DefaultAnimation( Container : TContainer );
begin
  CreateAnimation(Container.Default);
end;

procedure TFTimeSpan.CustomAnimation( Container : TContainer );
begin
  CreateAnimation(Container.Custom);
end;

procedure TFTimeSpan.DefaultProduct( Container : TContainer );
begin
  CreateProduct(Container.Default);
end;

procedure TFTimeSpan.CustomProduct( Container : TContainer );
begin
  CreateProduct(Container.Custom);
end;

function TFTimeSpan.RenderProduct( P : TProduct ) : TProduct;
begin
  if assigned(P)
    then
      begin
        P.DataSource := TimeSpan;
        P.Render;
      end;
  Result := P;
end;

function TFTimeSpan.RenderAnimation( P : TProduct ) : TAnimation;
var
  I : integer;
begin
  if assigned(P)
    then
      begin
        Notify.Declare([0, 100]);
        PRTable.StartCaching;
        HeightTable.StartCaching;
        StartNotify(TimeSpan.Observations);
        with TimeSpan do
          try
            Result := TAnimation.Create(nil);
            with Result do
              begin
                Product := P;
                Frames := Observations;
                for I := 0 to Observations - 1 do
                  try
                    Notify.Disable;
                    P.DataSource := Observation[I];
                    P.Render;
                    if P.Rendered
                      then Frame[I] := P
                      else raise Exception.Create('');
                    Notify.Enable;
                    Notify.DoNotify;
                  except
                    on E : Exception do
                      begin
                        FreeAndNil(Result);
                        E.Message := 'No se pudo crear el cuadro numero ' +
                                     IntToStr(succ(I)) + ':'#13#10 + E.Message;
                        raise;
                      end;
                  end;
               end;
          finally
            HeightTable.StopCaching;
            PRTable.StopCaching;
            EndNotify;
          end;
      end
    else Result := nil;
end;

procedure TFTimeSpan.RenderInit( const S : string );
begin
  Update;
  Button2.Enabled   := false;
  Button3.Enabled   := false;
  Eliminar1.Enabled := false;
  ProgressBar1.Position := 0;
  Label15.Caption := S;
  ProgressBar1.Show;
  Label15.Show;
end;

procedure TFTimeSpan.RenderDone;
begin
  Label15.Hide;
  ProgressBar1.Hide;
  Label15.Caption := '';
  ProgressBar1.Position := 0;
  Button2.Enabled   := true;
  Button3.Enabled   := true;
  Eliminar1.Enabled := true;
end;

function TFTimeSpan.GetProduct( const S : string ) : TProduct;
begin
  Result := FindProduct(ListView2, S);
end;

function TFTimeSpan.GetAnmProduct( const S : string ) : TProduct;
begin
  Result := FindProduct(ListView1, S);
end;

procedure TFTimeSpan.ClearContainerList( ListView : TListView );
var
  I : integer;
begin
  for I := ListView.Items.Count - 1 downto 0 do
    TContainer(ListView.Items[I].Data).Free;
  ListView.Items.Clear;
end;

procedure TFTimeSpan.UpdateProductMenus;
var
  I : integer;
  M : TMenuItem;
begin
  MenuItemClear(Animacion1);
  MenuItemClear(Animacion2);
  with ListView1 do
    for I := 0 to Items.Count - 1 do
      begin
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

function TFTimeSpan.GetFormAuto : TFormAuto;
begin
  if fFormAuto = nil
    then
      begin
        fFormAuto := TTimeSpanAuto.Create;
        fFormAuto.Form := Self;
      end;
  Result := fFormAuto;
end;

function TFTimeSpan.GetOleObject : variant;
begin
  Result := FormAuto.OleObject;
end;

procedure TFTimeSpan.SetTimeSpan( aTimeSpan : TTimeSpan );
begin
  if assigned(fTimeSpan) and (fTimeSpan <> aTimeSpan )
    then fTimeSpan.Release;
  fTimeSpan := aTimeSpan;
  UpdateTimeSpanView;
end;

procedure TFTimeSpan.UpdateTimeSpanView;

  function TimeSpanMemo : string;
  var
    H, M : integer;
  begin
    with fTimeSpan do
      if Observations = 1
        then
          begin
            Result := 'Una observacion a la';
            if FormatDateTime('ha/p', FirstTime)[1] <> '1'
              then Result := Result + 's';
            Result := Result + FormatDateTime(' t', FirstTime);
          end
        else
          begin
            H  :=            trunc(24 * (LastTime - FirstTime));
            M  := round(60 * frac (24 * (LastTime - FirstTime)));
            if M >= 60
              then
                begin
                  inc(H, M div 60);
                  M := M mod 60; 
                end;
            Result := IntToStr(Observations) + ' observaciones durante ';
            if H > 0
              then
                begin
                  Result := Result + IntToStr(H) + ' hora';
                  if H > 1 then Result := Result + 's';
                end;
            if (H > 0) and (M > 0)
              then Result := Result + ' y ';
            if M > 0
              then
                begin
                  Result := Result + IntToStr(M) + ' minuto';
                  if M > 1 then Result := Result + 's';
                end;
          end;
  end;

  procedure FillObservationEntry( Index : integer );
  var
    I : integer;
  begin
    with StringGrid2.Rows[Index + 1], fTimeSpan[Index] do
      begin
        // Numero
        Strings[0] := IntToStr(Index + 1);
        // Fecha
        Strings[1] := DateToStr(Time);
        // Hora
        Strings[2] := FormatDateTime('t', Time);
        // Angulos
        Strings[3] := FloatToStrF(CodeAngle(MoveDesc[0].Angle), ffFixed, 4, 1);
        for I := 1 to Movements - 1 do
          Strings[3] := Strings[3] + ', ' + FloatToStrF(CodeAngle(MoveDesc[I].Angle), ffFixed, 4, 1);
        // FileName
        Strings[4] := FileName;
      end;
  end;

var
  I : integer;
begin
  if assigned(fTimeSpan) and (fTimeSpan.Observations > 0)
    then
      with fTimeSpan do
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
          Edit6.Text := FormatDateTime('h:nn:ss', TimeGap);
          // Memo
          Memo1.Text := TimeSpanMemo;
          // Caption
          Caption := FormatDateTime('h:nn-ddddd', FirstTime) + ' a ' +
                     FormatDateTime('h:nn-ddddd', LastTime)  + ' - ' +
                     'Periodo ' + System;
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
          ClearContainerList(ListView1);
          ClearContainerList(ListView2);
          Products.EnumProducts(TObservation, true,  AddObsProduct);
          Products.EnumProducts(TTimeSpan,    false, AddTSpProduct);
          UpdateProductMenus;
          // Observations
          StringGrid2.RowCount := Observations + 1;
          for I := 0 to Observations - 1 do
            FillObservationEntry(I);
          SetRelColWidths(StringGrid2, StringGrid2ColWidths);
          PageControl1.Enabled := true;
          Button1.Enabled      := true;
        end
    else ResetTimeSpan;
end;

procedure TFTimeSpan.ResetTimeSpan;
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

procedure TFTimeSpan.ProgressNotify( Progress : integer );
begin
  ProgressBar1.Position := Progress;
end;

procedure TFTimeSpan.AddObsProduct( Container : TContainer; Index : integer );
begin
  with Container do
    begin
      Owner      := Self;
      DataSource := TimeSpan;
      with ListView1.Items.Add do
        begin
          Caption    := Product.Name;
          ImageIndex := Product.ImageIndex;
          Data       := Container;
          SubItems.Add(Product.ClassName);
          SubItems.Add(Product.Description);
        end;
    end;
end;

procedure TFTimeSpan.AddTSpProduct( Container : TContainer; Index : integer );
begin
  with Container do
    begin
      Owner      := Self;
      DataSource := TimeSpan;
      with ListView2.Items.Add do
        begin
          Caption    := Product.Name;
          ImageIndex := Product.ImageIndex;
          Data       := Container;
          SubItems.Add(Product.ClassName);
          SubItems.Add(Product.Description);
        end;
    end;
end;

procedure TFTimeSpan.CMWinIniChange(var Message: TWMWinIniChange);
begin
  UpdateTimespanView;
  inherited;
end;

// Component methods

procedure TFTimeSpan.FormResize(Sender: TObject);
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
          SetRelColWidths(StringGrid1, StringGrid1ColWidths);
        end;
  // Observaciones
  with TabSheet4 do
    if Showing
      then
        begin
          Button3.Left := Width - Button3.Width - 10;
          Button2.Left := Button3.Left - Button2.Width;
          Button2.Top := Height - Button2.Height - 5;
          Button3.Top := Button2.Top;
          StringGrid2.Width  := Width - 20;
          StringGrid2.Height := Button2.Top - 25;
          SetRelColWidths(StringGrid2, StringGrid2ColWidths);
        end;
  // Productos
  with TabSheet5 do
    if Showing
      then
        begin
          theWidth := SpeedButton5.Width +
                      SpeedButton6.Width +
                      SpeedButton7.Width +
                      SpeedButton8.Width + 20;
          if Width >= theWidth
            then theWidth := Width;
          SpeedButton8.Left := theWidth - SpeedButton4.Width - 10;
          SpeedButton7.Left := SpeedButton8.Left - SpeedButton7.Width;
          SpeedButton6.Left := SpeedButton7.Left - SpeedButton6.Width;
          SpeedButton5.Left := SpeedButton6.Left - SpeedButton5.Width;
          ListView2.Top    := SpeedButton5.Top + SpeedButton5.Height + 5;
          ListView2.Width  := Width - 20;
          ListView2.Height := Height - ListView2.Top - 10;
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
end;

procedure TFTimeSpan.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet1;
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
    end;
  // Observaciones
  with StringGrid2 do
    begin
      //DefaultRowHeight := 16;
      with Rows[0] do
        begin
          Strings[0] := 'No.';
          Strings[1] := 'Fecha';
          Strings[2] := 'Hora';
          Strings[3] := 'Angulos';
          Strings[4] := 'Archivo';
        end;
      SetRelColWidths(StringGrid2, StringGrid2ColWidths);
    end;
  // Animaciones
  with ListView1 do
    begin
      LargeImages := FShell.LargeImages;
      SmallImages := FShell.SmallImages;
    end;
  // Productos
  with ListView2 do
    begin
      LargeImages := FShell.LargeImages;
      SmallImages := FShell.SmallImages;
    end;
  fProductMutex := CreateMutex(nil, false, nil);
  // OpenDialog
  OpenDialog1.InitialDir := theSettings.Observations;
  OpenDialog1.Filter     := ObservationFilter;
  // SaveDialog
  SaveDialog1.InitialDir := theSettings.TimeSpans;
  SaveDialog1.Filter     := TimeSpanFilter;
end;

procedure TFTimeSpan.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if WaitForSingleObject(ProductMutex, 0) = WAIT_OBJECT_0
    then Action := caFree
    else Action := caNone;
end;

procedure TFTimeSpan.FormDestroy(Sender: TObject);
begin
  if assigned(fFormAuto)
    then fFormAuto.Release;
  CloseHandle(fProductMutex);
  if assigned(fTimeSpan)
    then fTimeSpan.Release;
end;

procedure TFTimeSpan.Button2Click(Sender: TObject);
begin
  with OpenDialog1 do
    if Execute
      then
        begin
          fTimeSpan.AddFiles(Files);
          UpdateTimeSpanView;
        end;
end;

procedure TFTimeSpan.Button3Click(Sender: TObject);
var
  I : integer;
begin
  for I := StringGrid2.Selection.Bottom downto StringGrid2.Selection.Top do
    fTimeSpan.Delete(I - 1);
  UpdateTimeSpanView;
end;

procedure TFTimeSpan.Button1Click(Sender: TObject);
var
  P : TPoint;
begin
  P.X := Button1.Width;
  P.Y := 0;
  P := Button1.ClientToScreen(P);
  PopupMenu1.Popup(P.X, P.Y);
end;

procedure TFTimeSpan.AnimationClick(Sender: TObject);
begin
  CreateAnimation(TContainer(ListView1.Items[(Sender as TMenuItem).Tag].Data).Custom);
end;

procedure TFTimeSpan.Salvar1Click(Sender: TObject);
begin
  with SaveDialog1 do
    if Execute
      then fTimeSpan.Save(FileName);
end;

procedure TFTimeSpan.Abrir1Click(Sender: TObject);
var
  I : integer;
begin
  for I := StringGrid2.Selection.Top - 1 to StringGrid2.Selection.Bottom - 1 do
    begin
      TObservation(fTimeSpan[I]).AddRef;
      FShell.ShowObservation(TObservation(fTimeSpan[I]), wsNormal);
    end;
end;

procedure TFTimeSpan.Periodo2Click(Sender: TObject);
var
  TS : TTimeSpan;
  I  : integer;
begin
  TS := TTimeSpan.Create;
  for I := StringGrid2.Selection.Top - 1 to StringGrid2.Selection.Bottom - 1 do
    begin
      TObservation(fTimeSpan[I]).AddRef;
      TS.Insert(TObservation(fTimeSpan[I]));
    end;
  FShell.ShowTimeSpan(TS, wsNormal);
end;

procedure TFTimeSpan.StringGrid2MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  C, R : longint;
begin
  with Sender as TStringGrid do
    begin
      MouseToCell( X, Y, C, R );
      if (R >= FixedRows) and ((R < Selection.Top) or (R > Selection.Bottom))
        then Row := R;
    end;
end;

procedure TFTimeSpan.StringGrid2KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13
    then
      with (Sender as TStringGrid).Selection do
        if Bottom > Top
          then Periodo2Click(Periodo2)
          else Abrir1Click(Abrir1);
end;

procedure TFTimeSpan.SpeedButton1Click(Sender: TObject);
begin
  ListView1.ViewStyle := TViewStyle((Sender as TSpeedButton).Tag);
end;

procedure TFTimeSpan.SpeedButton5Click(Sender: TObject);
begin
  ListView2.ViewStyle := TViewStyle((Sender as TSpeedButton).Tag);
end;

procedure TFTimeSpan.ListView1DblClick(Sender: TObject);
begin
  with ListView1 do
    if assigned(Selected)
      then DefaultAnimation(Selected.Data);
end;

procedure TFTimeSpan.ListView2DblClick(Sender: TObject);
begin
  with ListView2 do
    if assigned(Selected)
      then DefaultProduct(Selected.Data);
end;

procedure TFTimeSpan.Predefinido1Click(Sender: TObject);
begin
  if PageControl1.ActivePage = TabSheet5
    then ListView2DblClick(ListView2)
    else ListView1DblClick(ListView1);
end;

procedure TFTimeSpan.Editar1Click(Sender: TObject);
begin
  if PageControl1.ActivePage = TabSheet5
    then
      begin
        with ListView2 do
          if assigned(Selected)
            then CustomProduct(Selected.Data)
      end
    else
      begin
        with ListView1 do
          if assigned(Selected)
            then CustomAnimation(Selected.Data);
      end;
end;

procedure TFTimeSpan.ListView1KeyPress(Sender: TObject; var Key: Char);
begin
  case Key of
    #13 : Predefinido1Click(Predefinido1);
    #32 : Editar1Click(Sender);
  end;
end;

procedure TFTimeSpan.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE
    then Close;
end;

procedure TFTimeSpan.Lamina1Click(Sender: TObject);
begin
  CreateProduct(GetProduct('Acumulado'));
end;

procedure TFTimeSpan.StringGrid1MouseDown(Sender: TObject;
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

procedure TFTimeSpan.StringGrid1SelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := aCol = 8;
end;

procedure TFTimeSpan.StringGrid1SetEditText(Sender: TObject; ACol,
  ARow: Integer; const Value: String);
begin
  if aCol = 8
    then
      try
        fTimeSpan.Delta[aRow - 1] := StrToFloat(Value);
      except
        on EConvertError do
          fTimeSpan.Delta[aRow - 1] := 0.0;
      end;
end;

procedure TFTimeSpan.StringGrid1GetEditText(Sender: TObject; ACol,
  ARow: Integer; var Value: String);
begin
  if aCol = 8
    then Value := FloatToStrF(fTimeSpan.Delta[aRow - 1], ffFixed, 5, 2);
end;

end.
