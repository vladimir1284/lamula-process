unit Shell_Process;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, DdeMan, Menus, Buttons, ExtCtrls,
  TimeSpan, Ensemble, Observation, Product, Animation, ComCtrls,
  GridForm, ToolWin, StdCtrls, ImgList,ProfileVector, Profile_Display,
  matrix, xmldom, XMLIntf, msxmldom, XMLDoc, SyncObjs, GifImage, ExtDlgs,
  Nexrad_File, tsqBZip2, Translators;


type
  TFShell = class(TForm)
    MainMenu1: TMainMenu;
    Archivo1: TMenuItem;
    Abrir1: TMenuItem;
    OpenDialog1: TOpenDialog;
    Ventana1: TMenuItem;
    Organizar1: TMenuItem;
    Cascada1: TMenuItem;
    AzulejoHorizontal1: TMenuItem;
    AzulejoVertical1: TMenuItem;
    Periodo1: TMenuItem;
    Zoom1: TMenuItem;
    Imagen1: TMenuItem;
    Copiar1: TMenuItem;
    Conjunto1: TMenuItem;
    Vesta: TDdeServerConv;
    ImageList1: TImageList;
    Creditos1: TMenuItem;
    N3: TMenuItem;
    Terminar1: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    StatusBar1: TStatusBar;
    SpeedButton1: TSpeedButton;
    Splitter1: TSplitter;
    Salvar1: TMenuItem;
    N1: TMenuItem;
    Configuracin1: TMenuItem;
    N4: TMenuItem;
    Cache0: TMenuItem;
    Cache1: TMenuItem;
    Cache2: TMenuItem;
    Cache3: TMenuItem;
    Cache4: TMenuItem;
    Cache5: TMenuItem;
    Cache6: TMenuItem;
    Cache7: TMenuItem;
    Cache8: TMenuItem;
    Cache9: TMenuItem;
    CoolBar1: TCoolBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    ToolButton18: TToolButton;
    ToolButton19: TToolButton;
    CoolBar2: TCoolBar;
    PopupMenu1: TPopupMenu;
    Botones1: TMenuItem;
    Areas1: TMenuItem;
    N5: TMenuItem;
    Barras1: TMenuItem;
    Botones2: TMenuItem;
    Areas2: TMenuItem;
    SpeedButton2: TSpeedButton;
    LargeImages: TImageList;
    SmallImages: TImageList;
    RichEdit1: TRichEdit;
    TreeView1: TTreeView;
    Panel3: TPanel;
    ProfileDisplay1: TProfileDisplay;
    Calcular1: TMenuItem;
    Potencial1: TMenuItem;
    ReflectividadyPrecipitacin1: TMenuItem;
    Alturadeleco1: TMenuItem;
    Resolucintangencial1: TMenuItem;
    AcimutyDistancia1: TMenuItem;
    Conversindeunidades1: TMenuItem;
    Precipitacin1: TMenuItem;
    fHeader: TXMLDocument;
    fBlob: TXMLDocument;
    ToolButton20: TToolButton;
    CheckBox1: TCheckBox;
    ToolButton21: TToolButton;
    Timer1: TTimer;
    ToolButton16: TToolButton;
    ToolButton5: TToolButton;
    Ayuda1: TMenuItem;
    emasdeAyuda1: TMenuItem;
    StatusBar2: TStatusBar;
    ToolButton17: TToolButton;
    SaveDialog1: TSaveDialog;
    ToolButton22: TToolButton;
    procedure AbrirClick(Sender: TObject);
    procedure ExecuteMacro(Sender: TObject; Msg: TStrings);
    procedure FormCreate(Sender: TObject);
    procedure Organizar1Click(Sender: TObject);
    procedure Cascada1Click(Sender: TObject);
    procedure Azulejo1Click(Sender: TObject);
    procedure NuevoPeriodoClick(Sender: TObject);
    procedure Zoom1Click(Sender: TObject);
    procedure Cerrar1Click(Sender: TObject);
    procedure Terminar1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SalvarClick(Sender: TObject);
    procedure PrevClick(Sender: TObject);
    procedure NextClick(Sender: TObject);
    procedure CopiarClick(Sender: TObject);
    procedure NuevoConjuntoClick(Sender: TObject);
    procedure Creditos1Click(Sender: TObject);
    procedure TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TreeView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure CacheClick(Sender: TObject);
    procedure CoolBar2Resize(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure Botones1Click(Sender: TObject);
    procedure Areas1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure ToolButton13Click(Sender: TObject);
    procedure ToolButton14Click(Sender: TObject);
    procedure Configuracin1Click(Sender: TObject);
    procedure ToolButton20Click(Sender: TObject);
    procedure Potencial1Click(Sender: TObject);
    procedure ReflectividadyPrecipitacin1Click(Sender: TObject);
    procedure Precipitacin1Click(Sender: TObject);
    procedure Alturadeleco1Click(Sender: TObject);
    procedure Resolucintangencial1Click(Sender: TObject);
    procedure AcimutyDistancia1Click(Sender: TObject);
    procedure Conversindeunidades1Click(Sender: TObject);
    procedure ToolButton21Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure ToolButton16Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure ToolButton17Click(Sender: TObject);
    procedure ToolButton22Click(Sender: TObject);
  private
    fBusyCount : integer;
    procedure WMDropFiles( var Message : TWMDropFiles);  message WM_DropFiles;
    procedure CMWinIniChange( var Message : TWMWinIniChange );  message CM_WININICHANGE;
  public
    property BusyCount : integer read fBusyCount write fBusyCount;
  private
    procedure ApplicationIdle( Sender : TObject; var Done : boolean );
    procedure ExecuteCommand ( Sender : TObject; Msg : TStrings );
  protected
    function OpenTimeSpan   ( const aFileName : string ) : variant;
    function OpenEnsemble   ( const aFileName : string ) : variant;
    function OpenObservation( const aFileName : string; WState: TWindowState ) : variant;
    function OpenProduct    ( const aFileName : string ) : variant;
    function OpenAnimation  ( const aFileName : string ) : variant;
  public
    function ShowTimeSpan   ( T : TTimeSpan; WState: TWindowState ) : variant;
    function ShowEnsemble   ( E : TEnsemble    ) : variant;
    function ShowObservation( O : TObservation; WState: TWindowState ) : variant;
    function ShowProduct    ( P : TProduct     ) : variant;
    function ShowAnimation  ( A : TAnimation   ) : variant;
  public
    function Open( const aFileName : string; WState: TWindowState ) : variant;
  private
    fCacheList : array[0..9] of string;
    procedure SaveCache;
    procedure LoadCache;
    procedure RefreshCache;
  public
    procedure AddCacheEntry( Entry : string );
  public
    procedure DisplayProfile( Prof : TProfileVector );
  end;

var
  FShell: TFShell;

function FindProduct( List : TListView; const S : string ) : TProduct;

implementation

{$R *.DFM}

uses
  UtStr,
  Clipbrd,
  ShellAPI, Variants,
  Settings,
  Tools,
  Angle,
  Description,
  Plane,
  Measure,
  Translator,
  Raw_Translator,
  Raw_Parameters,
  Macro,
  GridProduct,
  TimeSpanForm, EnsembleForm, ObservationForm,
  SettingsForm, ConfigurationForm,
  AboutDialog,
  TreeImages,
  Configuration,
  VersionInfo, CalculatorForm, CalPotForm, CalRefForm, CalPreForm,
  CalAltForm, CalResForm, CalAcmDisForm, CalMovForm, CalConForm,
  AutoPilotForm, TopDown, TranslatorPercentForm;

// Private procedures & functions

procedure PropDown( Node : TTreeNode; State : integer );
var
  N : TTreeNode;
begin
  with Node do
    begin
      if HasChildren
        then
          begin
            N := GetFirstChild;
            while N <> nil do
              begin
                PropDown(N, State);
                N := GetNextChild(N);
              end;
          end;
      StateIndex := State;
      TAreaEntry(Data).Selected := (State = tiAll);
    end;
end;

procedure CheckState( Node : TTreeNode );
var
  N : TTreeNode;
  S : integer;
begin
  if Node <> nil
    then
      with Node do
        begin
          N := GetFirstChild;
          S := N.StateIndex;
          N := GetNextChild(N);
          while N <> nil do
            begin
              if N.StateIndex <> S
                then break;
              N := GetNextChild(N);
            end;
          if N = nil
            then StateIndex := S
            else StateIndex := tiPartial;
          TAreaEntry(Data).Selected := (StateIndex = tiAll);
          CheckState(Parent);
        end;
end;

procedure SetState( Node : TTreeNode; State : integer );
begin
  PropDown( Node, State );
  CheckState( Node.Parent );
end;


// Public procedures & functions

function FindProduct( List : TListView; const S : string ) : TProduct;
var
  I : integer;
begin
  with List do
    begin
      I := 0;
      while (I < Items.Count) do
        begin
          if CompareText(TContainer(Items[I].Data).Product.Name, S) = 0
            then break;
          inc(I);
        end;
      if I < Items.Count
        then Result := TContainer(Items[I].Data).Default
        else Result := nil;
    end;
end;

// TFShell methods

procedure TFShell.ApplicationIdle( Sender : TObject; var Done : boolean );
var
  MP : TPoint;
  WC : TWinControl;
begin
  ToolButton2 .Enabled := MDIChildCount > 0;
  ToolButton13.Enabled := MDIChildCount > 1;
  ToolButton14.Enabled := MDIChildCount > 1;
  ToolButton19.Enabled := assigned(ActiveMDIChild);
  Copiar1.Enabled      := ToolButton19.Enabled;
  GetCursorPos(MP);
  WC := FindVCLWindow(MP);
  if assigned(WC) and
     not ((WC is TPanel) and (WC.Owner is TFGrid))
    then
      begin
        RichEdit1.Text := '';
        StatusBar1.Panels[0].Text := '';
        StatusBar1.Panels[1].Text := '';
        StatusBar1.Panels[2].Text := '';
        StatusBar1.Panels[3].Text := '';
        StatusBar1.Panels[4].Text := '';
        StatusBar1.Panels[5].Text := '';
        StatusBar1.Panels[6].Text := '';
        StatusBar1.Panels[7].Text := '';
      end;
  if not (ActiveMDIChild is TFGrid)
    then
      begin
        TreeView1.Items.Clear;
        DisplayProfile(nil);
      end;
end;

function TFShell.Open( const aFileName : string; WState: TWindowState ) : variant;
var
  Ext : string[4];
begin
  try
    Cursor := crHourGlass;
    Ext := LowerCase(ExtractFileExt(aFileName));
    if Ext = TimeSpanExt
      then Result := OpenTimeSpan(aFileName)
    else if Ext = EnsembleExt
      then Result := OpenEnsemble(aFileName)
    else if Ext = ProductExt
      then Result := OpenProduct(aFileName)
    else if Ext = AnimationExt
      then Result := OpenAnimation(aFileName)
    else
      try
        Result := OpenObservation(aFileName, WState);
      except
        on E : ECanNotFindTranslator do
          raise Exception.Create('Tipo de archivo desconocido: ' + aFileName);
      end;
    AddCacheEntry(aFileName);
  finally
    Cursor := crDefault;
  end;
end;

procedure TFShell.AddCacheEntry( Entry : string );
var
  I, J : integer;
begin
  Entry := ExpandFileName(Entry);
  I := 0;
  while (fCacheList[I] <> Entry) and (I < 9) do
    inc(I);
  for J := I downto 1 do
    fCacheList[J] := fCacheList[pred(J)];
  fCacheList[0] := Entry;
  RefreshCache;
  SaveCache;
end;

procedure TFShell.SaveCache;
begin
  with theConfiguration do
    begin
      Cache0 := fCacheList[0];
      Cache1 := fCacheList[1];
      Cache2 := fCacheList[2];
      Cache3 := fCacheList[3];
      Cache4 := fCacheList[4];
      Cache5 := fCacheList[5];
      Cache6 := fCacheList[6];
      Cache7 := fCacheList[7];
      Cache8 := fCacheList[8];
      Cache9 := fCacheList[9];
    end;
end;

procedure TFShell.LoadCache;
var
  I : integer;
begin
  with theConfiguration do
    begin
      fCacheList[0] := Cache0;
      fCacheList[1] := Cache1;
      fCacheList[2] := Cache2;
      fCacheList[3] := Cache3;
      fCacheList[4] := Cache4;
      fCacheList[5] := Cache5;
      fCacheList[6] := Cache6;
      fCacheList[7] := Cache7;
      fCacheList[8] := Cache8;
      fCacheList[9] := Cache9;
      for I := 0 to 9 do
        if ExtractFileName(fCacheList[I]) = ''
          then fCacheList[I] := '';
    end;
  RefreshCache;
end;

function CacheCaption( Entry : string ) : string;
begin
  if Length(Entry) <= 23
    then Result := Entry
    else Result := LeftStr(Entry, 7) +
                   '...' +
                   RightStr(Entry, 13);
end;

procedure TFShell.RefreshCache;
begin
  Cache0.Caption := '&1 '  + CacheCaption(fCacheList[0]);
  Cache1.Caption := '&2 '  + CacheCaption(fCacheList[1]);
  Cache2.Caption := '&3 '  + CacheCaption(fCacheList[2]);
  Cache3.Caption := '&4 '  + CacheCaption(fCacheList[3]);
  Cache4.Caption := '&5 '  + CacheCaption(fCacheList[4]);
  Cache5.Caption := '&6 '  + CacheCaption(fCacheList[5]);
  Cache6.Caption := '&7 '  + CacheCaption(fCacheList[6]);
  Cache7.Caption := '&8 '  + CacheCaption(fCacheList[7]);
  Cache8.Caption := '&9 '  + CacheCaption(fCacheList[8]);
  Cache9.Caption := '1&0 ' + CacheCaption(fCacheList[9]);
  N4.Visible := fCacheList[0] <> '';
  Cache0.Visible := fCacheList[0] <> '';
  Cache1.Visible := fCacheList[1] <> '';
  Cache2.Visible := fCacheList[2] <> '';
  Cache3.Visible := fCacheList[3] <> '';
  Cache4.Visible := fCacheList[4] <> '';
  Cache5.Visible := fCacheList[5] <> '';
  Cache6.Visible := fCacheList[6] <> '';
  Cache7.Visible := fCacheList[7] <> '';
  Cache8.Visible := fCacheList[8] <> '';
  Cache9.Visible := fCacheList[9] <> '';
end;

function TFShell.ShowTimeSpan( T : TTimeSpan; WState: TWindowState ) : variant;
begin
  with TFTimeSpan.Create(Self) do
    try
      WindowState := WState;
      TimeSpan := T;
      Result := OleObject;
    except
      Release;
      raise;
    end;
end;

function TFShell.ShowEnsemble( E : TEnsemble ) : variant;
begin
  with TFEnsemble.Create(Self) do
    try
      Ensemble := E;
      Result   := OleObject;
    except
      Release;
      raise;
    end;
end;

function TFShell.ShowObservation( O : TObservation; WState: TWindowState ) : variant;
begin
  with TFObservation.Create(Self) do
    try
      WindowState := WState;
      Observation := O;
      Result := OleObject;
    except
      Release;
      raise;
    end;
end;

function TFShell.ShowProduct( P : TProduct ) : variant;
begin
  if assigned(P)
    then
      begin
        P.Show;
        Result := P.OleObject;
      end
    else Result := null;
end;

function TFShell.ShowAnimation( A : TAnimation ) : variant;
begin
  if assigned(A)
    then
      begin
        A.Position := 0;
        Result := (A.Product as TGridProduct).ViewForm.OleObject;
      end;
end;

function TFShell.OpenTimeSpan( const aFileName : string ) : variant;
begin
  Result := ShowTimeSpan(TTimeSpan.Load(aFileName), wsNormal);
end;

function TFShell.OpenEnsemble( const aFileName : string ) : variant;
begin
  Result := ShowEnsemble(TEnsemble.Load(aFileName));
end;

function LocaleSeparator : string;
begin
  SetString(Result, nil, GetLocaleInfo( LOCALE_USER_DEFAULT, LOCALE_SLIST, nil, 0 ) - 1);
  if GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SLIST, pchar(Result), Length(Result) + 1) = 0
    then Result := ',';
end;

function ScanAngles( const S : string ) : TList;
var
  S1, S2 : string;
  C      : string;
begin
  Result := TList.Create;
  C := LocaleSeparator;
  SplitStr(C, S, S1, S2);
  while S1 <> '' do
    begin
      Result.Add(pointer(AngleCode(StrToFloat(S1))));
      SplitStr(C, S2, S1, S2);
    end;
end;

function AcceptRawParameters( T : TRaw_Translator ) : boolean;
var
  I     : integer;
  Ch    : TChannelDesc;
  Msr   : TMeasure;
  MDesc : TMovementDesc;
  Ang   : TList;
begin
  with TFRaw_Parameters.Create(FShell) do
    try
      Caption := ExtractFileName(T.FileName);
      MonthCalendar1.Date := T.FileTime;
      DateTimePicker1.Time := T.FileTime;
      Result := ShowModal = mrOk;
      if Result
        then
          begin
            // Date & time
            T.Radar := TRadar(ComboBox1.ItemIndex);
            T.DateTime := trunc(MonthCalendar1.Date) + frac(DateTimePicker1.Time);
            // Measure
            Msr := TMeasure(ComboBox6.ItemIndex);
            // Vesta encoding
            T.VestaCode := CheckBox1.Checked;
            T.RangeCrtn := CheckBox2.Checked;
            // Slope
            try
              T.Slope := StrToFloat(Edit1.Text);
            except
              on EConvertError do T.Slope := 1.0;
            end;
            // Offset
            try
              T.Offset := StrToFloat(Edit9.Text);
            except
              on EConvertError do T.Offset := 0.0;
            end;
            // Channel
            FillChar(Ch, sizeof(Ch), 0);
            Ch.Wave    := TWaveLength(Combobox2.ItemIndex);
            Ch.Cells   := StrToInt  (Edit4.Text);
            Ch.Length  := StrToInt  (Edit5.Text);
            Ch.Sectors := StrToInt  (Edit6.Text);
            Ch.Beam    := StrToFloat(Edit7.Text);
            Ch.PotMet  := StrToFloat(Edit8.Text);
            T.Channels   := 1;
            T.Channel[0] := Ch;
            // Angles
            Ang := ScanAngles(Edit3.Text);
            // Movements
            T.Movements := UpDown1.Position;
            try
              FillChar(MDesc, sizeof(MDesc), 0);
              with MDesc do
                begin
                  Radar   := T.Radar;
                  Time    := T.DateTime;
                  Channel := 0;
                  Kind    := pkHorizontal;
                  Measure := Msr;
                  Start   := ang_0;
                  Finish  := ang_360;
                  SectorCount := Ch.Sectors;
                end;
              for I := 0 to T.Movements - 1 do
                begin
                  MDesc.Angle := TAngle(Ang[I]);
                  T.MoveDesc[I] := MDesc;
                end;
            finally
              Ang.Free;
            end;
          end;
    finally
      Free;
    end;
end;

function TFShell.OpenObservation( const aFileName : string; WState: TWindowState ) : variant;
var
  Obs : TObservation;
begin
  Obs := TObservation.Load(aFileName);
  if assigned(Obs) and (Obs.Translator is TRaw_Translator)
    then
      if AcceptRawParameters(TRaw_Translator(Obs.Translator))
        then Obs.UpdateTranslator
        else
          begin
            Obs.Release;
            Obs := nil;
          end;
  if assigned(Obs)
    then Result := ShowObservation(Obs, WState)
    else Result := null;
end;

function TFShell.OpenProduct( const aFileName : string ) : variant;
begin
  with TFileStream.Create(aFileName, fmOpenRead or fmShareDenyWrite) do
    try
      Result := ShowProduct(ReadComponent(nil) as TProduct);
    finally
      Free;
    end;
end;

function TFShell.OpenAnimation( const aFileName : string ) : variant;
begin
  Result := ShowAnimation(TAnimation.Load(aFileName));
end;

procedure TFShell.ExecuteCommand( Sender : TObject; Msg : TStrings );
var
  Command : string;
begin
  Command := LowerCase(Msg[0]);
  if Command = 'open'
    then Open(BeforeStr('"', AfterStr('"', Msg[1])), wsNormal);
end;

procedure TFShell.WMDropFiles( var Message : TWMDropFiles);
var
  FileCount : integer;
  FileName  : array[0..255] of char;
  I         : integer;
begin
  with Message do
    begin
      FileCount := DragQueryFile(Drop, $FFFFFFFF, nil, 0);
      for I := 0 to FileCount - 1 do
        begin
          DragQueryFile(Drop, I, @FileName[0], sizeof(FileName));
          Open(FileName, wsNormal);
        end;
      DragFinish(Drop);
    end;
end;

procedure TFShell.CMWinIniChange( var Message : TWMWinIniChange );
var
  I : integer;
begin
  GetFormatSettings;
  for I := 0 to MDIChildCount - 1 do
    MDIChildren[I].Dispatch(Message);
end;

// Component methods

procedure TFShell.AbrirClick(Sender: TObject);
var
  I : integer;
begin  // Abrir
  with OpenDialog1 do
    begin
      if Sender is TMenuItem
        then Title := (Sender as TMenuItem).Hint
        else Title := (Sender as TControl).Hint;
      case Tag of
        1 : InitialDir := theSettings.TimeSpans;
        2 : InitialDir := theSettings.Ensembles;
        3 : InitialDir := theSettings.Observations;
        4 : InitialDir := theSettings.Products;
        5 : InitialDir := theSettings.Animations;
      end;
      FilterIndex := (Sender as TComponent).Tag;
      if Execute
        then
          for I := 0 to Files.Count - 1 do
            Open(Files[I], wsNormal);
    end;
end;

procedure TFShell.NuevoPeriodoClick(Sender: TObject);
var
  T : TTimeSpan;
begin
  with OpenDialog1 do
    begin
      Title       := 'Crear periodo';
      InitialDir  := theSettings.Observations;
      FilterIndex := 3;
      if Execute
        then
          begin
            T := TTimeSpan.Create;
            T.AddFiles(Files);
            ShowTimeSpan(T, wsNormal);
          end;
    end;
end;

procedure TFShell.NuevoConjuntoClick(Sender: TObject);
var
  E : TEnsemble;
begin
  with OpenDialog1 do
    begin
      Title       := 'Crear conjunto';
      InitialDir  := theSettings.Observations;
      FilterIndex := 3;
      if Execute
        then
          begin
            E := TEnsemble.Create;
            E.AddFiles(Files);
            ShowEnsemble(E);
          end;
    end;
end;

procedure TFShell.Terminar1Click(Sender: TObject);
begin
  Close;
end;

procedure TFShell.FormCreate(Sender: TObject);
var
  I : integer;
begin
  for I := 1 to ParamCount do
    if LowerCase(ParamStr(I)) = '-embedding'
      then WindowState := wsMinimized;
  WindowMenu := Ventana1;
  SetToolPath(theSettings.Tools);
  Application.OnIdle     := ApplicationIdle;
  TreeView1.StateImages  := TreeImages.Images;
  ProfileDisplay1.Clear;
  OpenDialog1.InitialDir := theSettings.Observations;
  OpenDialog1.Filter     := TimeSpanFilter    + '|' +
                            EnsembleFilter    + '|' +
                            ObservationFilter + '|' +
                            ProductFilter     + '|' +
                            AnimationFilter;
  DragAcceptFiles(Handle, true);
  LoadCache;
  CheckBox1.Checked := TheSettings.ActiveAutoPilot;
end;

procedure TFShell.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if BusyCount = 0
    then Action := caFree
    else Action := caNone;
end;

procedure TFShell.FormDestroy(Sender: TObject);
begin
  FCalMov := nil;
  while MDIChildCount > 0 do
    MDIChildren[MDIChildCount - 1].Free;
  SaveCache;
  MainMenu1.Images := nil;
  CoolBar1.Images := nil;
end;

procedure TFShell.Organizar1Click(Sender: TObject);
begin
  ArrangeIcons;
end;

procedure TFShell.Cascada1Click(Sender: TObject);
begin
  Cascade;
end;

procedure TFShell.Azulejo1Click(Sender: TObject);
begin
  TileMode := TTileMode((Sender as TMenuItem).Tag);
  Tile;
end;

procedure TFShell.Zoom1Click(Sender: TObject);
begin
  if assigned(ActiveMDIChild)
    then
      with ActiveMDIChild do
        if WindowState = wsNormal
          then WindowState := wsMaximized
          else WindowState := wsNormal;
end;

procedure TFShell.Cerrar1Click(Sender: TObject);
begin
  if assigned(ActiveMDIChild)
    then ActiveMDIChild.Close;
end;

procedure TFShell.ExecuteMacro(Sender: TObject;
  Msg: TStrings);
var
  I : integer;
  C : TStrings;
  M : TStrings;
begin
  if assigned(Msg)
    then
      begin
        M := TStringList.Create;
        C := TStringList.Create;
        try
          for I := 0 to Msg.Count - 1 do
            SplitMacro(Msg[I], M);
          for I := 0 to M.Count - 1 do
            begin
              SplitCommand(M[I], C);
              ExecuteCommand(Sender, C);
              C.Clear;
            end;
        finally
          FreeAndNil(C);
          FreeAndNil(M);
        end;
      end;
end;

type
  TMethod = record
    Address  : pointer;
    Instance : pointer;
  end;

procedure TFShell.SalvarClick(Sender: TObject);
var
  Salvar : TNotifyEvent;
  Dummy  : TMethod absolute @Salvar;
begin  // Salvar
  if ActiveMDIChild <> nil
    then
      begin
        Salvar := nil;
        Dummy.Address  := ActiveMDIChild.MethodAddress('Salvar1Click');
        Dummy.Instance := ActiveMDIChild;
        if assigned(Salvar)
          then Salvar(ActiveMDIChild);
      end;
end;

procedure TFShell.PrevClick(Sender: TObject);
begin  // Anterior
  Previous;
end;

procedure TFShell.NextClick(Sender: TObject);
begin  // Proxima
  Next;
end;

procedure TFShell.CopiarClick(Sender: TObject);
var
  B : TBitmap;
begin  // Copiar
  if assigned(ActiveMDIChild)
    then
      if ActiveMDIChild is TFGrid
        then B := (ActiveMDIChild as TFGrid).GetFormImage
        else B := ActiveMDIChild.GetFormImage
    else B := GetFormImage;
  try
    Clipboard.Assign(B);
  finally
    B.Free;
  end;
end;

procedure TFShell.Creditos1Click(Sender: TObject);
begin
  with TFAboutDialog.Create(Self) do
    try
      ShowModal;
    finally
      Release;
    end;
end;

procedure TFShell.TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  with Sender as TTreeView do
    if htOnStateIcon in GetHitTestInfoAt(X, Y)
      then
        begin
          if Selected.StateIndex = tiNone
            then SetState(Selected, tiAll)
            else SetState(Selected, tiNone);
          if assigned(ActiveMDIChild) and (ActiveMDIChild is TFGrid)
            then (ActiveMDIChild as TFGrid).UpdateMaskBitmap;
        end;
end;

procedure TFShell.TreeView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  with Sender as TTreeView do
    case Key of
      VK_SPACE :
        begin
          if Selected.StateIndex = tiNone
            then SetState(Selected, tiAll)
            else SetState(Selected, tiNone);
          if assigned(ActiveMDIChild) and (ActiveMDIChild is TFGrid)
            then (ActiveMDIChild as TFGrid).UpdateMaskBitmap;
        end;
      VK_ADD      : Selected.Expand(false);
      VK_SUBTRACT : Selected.Collapse(false);
    end;
end;

procedure TFShell.CacheClick(Sender: TObject);
begin
  Open(fCacheList[(Sender as TMenuItem).Tag], wsNormal);
end;

procedure TFShell.CoolBar2Resize(Sender: TObject);
begin
  with Sender as TCoolBar do
    begin
      RichEdit1.Width       := Width;
      TreeView1.Width       := Width;
      Panel3.Width          := Width;
      ProfileDisplay1.Width := Width;
      SpeedButton1.Down     := Width <> 0;
      Splitter1.Left        := Width;
      Splitter1.Visible     := SpeedButton1.Down;
    end;
end;

var
  SavedWidth : integer = 150;

procedure TFShell.SpeedButton1Click(Sender: TObject);
begin
  if SpeedButton1.Down
    then CoolBar2.Width := SavedWidth
    else
      begin
        SavedWidth := CoolBar2.Width;
        CoolBar2.Width := 0;
      end;
  Splitter1.Visible := SpeedButton1.Down;
  Splitter1.Left    := CoolBar2.Width;
  Areas1.Checked    := SpeedButton1.Down;
  Areas2.Checked    := SpeedButton1.Down;
end;

procedure TFShell.SpeedButton2Click(Sender: TObject);
begin
  with SpeedButton2 do
    begin
      Botones1.Checked := Down;
      Botones2.Checked := Down;
      CoolBar1.Visible := Down;
    end;
end;

procedure TFShell.Botones1Click(Sender: TObject);
begin
  with Sender as TMenuItem do
    begin
      Checked := not Checked;
      Botones1.Checked  := Checked;
      Botones2.Checked  := Checked;
      SpeedButton2.Down := Checked;
      CoolBar1.Visible  := Checked;
    end;
end;

procedure TFShell.Areas1Click(Sender: TObject);
begin
  with Sender as TMenuItem do
    begin
      Checked := not Checked;
      Areas1.Checked := Checked;
      Areas2.Checked := Checked;
      SpeedButton1.Down := Checked;
    end;
  SpeedButton1Click(SpeedButton1);
end;

procedure TFShell.ToolButton13Click(Sender: TObject);
begin  // Anterior
  Previous;
end;

procedure TFShell.ToolButton14Click(Sender: TObject);
begin  // Proxima
  Next;
end;

procedure TFShell.Configuracin1Click(Sender: TObject);
begin
  if FSettings = nil
    then Application.CreateForm(TFSettings, FSettings);
  FSettings.ShowModal;
{  if FConfiguration = nil
    then Application.CreateForm(TFConfiguration, FConfiguration);
  FConfiguration.ShowModal;}
end;

procedure TFShell.DisplayProfile( Prof : TProfileVector );
const
  ProfVars : TMeasureSet = [unDB, unDBZ, unMMH, unMS, unZDR, unPDP, unRho, unKDP, unGCP];
const
  //                                        unNone, unDB, unDBZ, unMMH, unMS, unMM, unM, unKM, unKGM, unZDR, unPDP, unRho, unKDP, unGCP, unTID, unM2S2, unW
  Prof_Ofs   : array[TMeasure] of double = (0,      5,    10,    0,     60,   0,    0,   0,    0,     5,     0,     0,     0,     0,     0,      0,     60 );
  Prof_Scale : array[TMeasure] of double = (0,      2,    1.5,   1,     1,    0,    0,   0,    0,     10,    1,     10,    50,    1,     1,      0,     1  );
  Prof_Mark1 : array[TMeasure] of double = (0,      20,   25,    20,    -10,  0,    0,   0,    0,     -3,    30,    0.9,   1,     50,    0,      0,     -10);
  Prof_Mark2 : array[TMeasure] of double = (0,      40,   50,    50,    10,   0,    0,   0,    0,     3,     60,    0.7,   2,     100,   0,      0,     10 );
var
  Data : TCodeArray;
begin
  if assigned(Prof) and (Prof.Measure in ProfVars)
    then
      begin
        SetLength(Data, Prof.Size);
        Move(Prof.Cells^, Data[0], Prof.Size);
        ProfileDisplay1.Top     := Prof.Top;
        ProfileDisplay1.Bottom  := Prof.Bottom;
        ProfileDisplay1.Measure := Prof.Measure;
        ProfileDisplay1.Offset  := Prof_Ofs  [Prof.Measure];
        ProfileDisplay1.Scale   := Prof_Scale[Prof.Measure];
        ProfileDisplay1.Mark1   := Prof_Mark1[Prof.Measure];
        ProfileDisplay1.Mark2   := Prof_Mark2[Prof.Measure];
        ProfileDisplay1.SetData(Data);
      end
    else ProfileDisplay1.Clear;
end;

procedure TFShell.ToolButton20Click(Sender: TObject);
begin
  if FCalculator = nil
    then Application.CreateForm(TFCalculator, FCalculator);
  FCalculator.Show;
end;

procedure TFShell.Potencial1Click(Sender: TObject);
begin
  if FCalPot = nil
    then Application.CreateForm(TFCalPot, FCalPot);
  FCalPot.Show;
end;

procedure TFShell.ReflectividadyPrecipitacin1Click(Sender: TObject);
begin
  if FCalRef = nil
    then Application.CreateForm(TFCalRef, FCalRef);
  FCalRef.Show;
end;

procedure TFShell.Precipitacin1Click(Sender: TObject);
begin
  if FCalPre = nil
    then Application.CreateForm(TFCalPre, FCalPre);
  FCalPre.Show;
end;

procedure TFShell.Alturadeleco1Click(Sender: TObject);
begin
  if FCalAlt = nil
    then Application.CreateForm(TFCalAlt, FCalAlt);
  FCalAlt.Show;
end;

procedure TFShell.Resolucintangencial1Click(Sender: TObject);
begin
  if FCalRes = nil
    then Application.CreateForm(TFCalRes, FCalRes);
  FCalRes.Show;
end;

procedure TFShell.AcimutyDistancia1Click(Sender: TObject);
begin
  if FCalAcmDis = nil
    then Application.CreateForm(TFCalAcmDis, FCalAcmDis);
  FCalAcmDis.Show;
end;

procedure TFShell.Conversindeunidades1Click(Sender: TObject);
begin
  if FCalCon = nil
    then Application.CreateForm(TFCalCon, FCalCon);
  FCalCon.Show;
end;

procedure TFShell.ToolButton21Click(Sender: TObject);
var
  Prd: TTopDown;
  View: TFGrid;
begin
  with FAutoPilot do
    begin
      Screen.Cursor := crHourGlass;
      WriteForm;
      Screen.Cursor := crArrow;
      if FAutoPilot.ShowModal = mrOk then
        begin
          Screen.Cursor := crHourGlass;
          ReadForm;
          Screen.Cursor := crArrow;
        end;
    end;
end;

procedure TFShell.Timer1Timer(Sender: TObject);
var
  TaskThread: TExecuteTaskThread;
begin
  if not (TaskThreadRunning.WaitFor(0) = wrSignaled) then
    begin
      TaskThreadRunning.SetEvent;
      TaskThread := TExecuteTaskThread.Create(true);
      TaskThread.FreeOnTerminate := true;
      TaskThread.Resume;
    end;
end;

procedure TFShell.ToolButton16Click(Sender: TObject);
begin
  if FSettings = nil
    then Application.CreateForm(TFSettings, FSettings);
  FSettings.ShowModal;
{  if FConfiguration = nil
    then Application.CreateForm(TFConfiguration, FConfiguration);
  FConfiguration.ShowModal;}
end;

procedure TFShell.CheckBox1Click(Sender: TObject);
begin
  Timer1.Enabled := CheckBox1.Checked;
  TheSettings.ActiveAutoPilot := CheckBox1.Checked;
end;

procedure TFShell.ToolButton17Click(Sender: TObject);
var
  Gif: TGifImage;
  bmp: TBitmap;
  DCDesk: HDC;
begin
  bmp := TBitmap.Create;
  DCDesk := GetWindowDC(GetDesktopWindow);
  if WindowState = wsMaximized then
    begin
      bmp.Height := Height + 2*Top;
      bmp.Width := Width + 2*Left;
      BitBlt(bmp.Canvas.Handle, 0, 0, Width + 2*Left, Height + 2*Top, DCDesk, 0, 0, SRCCOPY)
    end
  else
    begin
      bmp.Height := Height;
      bmp.Width := Width;
      BitBlt(bmp.Canvas.Handle, 0, 0, Width, Height, DCDesk, Left, Top, SRCCOPY);
    end;
  with SaveDialog1 do
    begin
      FileName := FormatDateTime('dd"-"mm"-"yyyy_hh"-"nn', Now) + '.gif';
      if Execute then
        begin
          Gif := TGifImage.Create;
          Gif.ColorReduction := rmQuantize;
          Gif.Assign(bmp);
          Gif.SaveToFile(FileName);
          Gif.Free;
        end;
    end;
  ReleaseDC(GetDesktopWindow, DCDesk);
  bmp.Free;
end;


procedure TFShell.ToolButton22Click(Sender: TObject);
var
  S: TFileStream;
  MS: TMemoryStream;
  Obs: TTranslator;
  Obs_Name, Ar2_Name: TStringList;
  i: integer;
begin

// Nexrad .ar2.bz2 -> vcp 11
//  Obs := ObsData('C:\L2\KMLB_1993_03_13_09_26_21.ar2.bz2');
//  S := TFileStream.Create('C:\l2\CCMW_2008_08_08_19_00_00.ar2.bz2', fmCreate);

// Vesta .obs
//  Obs := ObsData('C:\L2\c08g1900.obs');
//  S := TFileStream.Create('C:\L2\c08g1900.ar2.bz2', fmCreate);

  Obs_Name := TStringList.Create;
  with Obs_Name do
    begin
      Add('c28g1600.obs');
{      Add('b30g2115.obs');
      Add('b30g2130.obs');
      Add('b30g2145.obs');
      Add('b30g2200.obs');
      Add('b30g2215.obs');
      Add('b30g2230.obs');
      Add('b30g2245.obs');
      Add('b30g2300.obs');
      Add('b30g2315.obs');
      Add('b30g2330.obs');
      Add('b30g2345.obs');}
    end;

  Ar2_Name := TStringList.Create;
  with Ar2_Name do
    begin
      Add('CCMW_2010_08_28_16_00_00.ar2.bz2');
{      Add('CCSB_2008_08_30_21_15_00.ar2.bz2');
      Add('CCSB_2008_08_30_21_30_00.ar2.bz2');
      Add('CCSB_2008_08_30_21_45_00.ar2.bz2');
      Add('CCSB_2008_08_30_22_00_00.ar2.bz2');
      Add('CCSB_2008_08_30_22_15_00.ar2.bz2');
      Add('CCSB_2008_08_30_22_30_00.ar2.bz2');
      Add('CCSB_2008_08_30_22_45_00.ar2.bz2');
      Add('CCSB_2008_08_30_23_00_00.ar2.bz2');
      Add('CCSB_2008_08_30_23_15_00.ar2.bz2');
      Add('CCSB_2008_08_30_23_30_00.ar2.bz2');
      Add('CCSB_2008_08_30_23_45_00.ar2.bz2');}
    end;

  for i := 0 to Obs_Name.Count - 1 do
    begin
      Obs := ObsData('C:\obs\' + Obs_Name[i]);
      S := TFileStream.Create('C:\obs\' + Ar2_Name[i], fmCreate);
      MS := TMemoryStream.Create;

      with TNexradMessage.Create(Obs, MS) do
        begin
          FillStream;
          Free;
        end;
      Obs.Free;
      with TtsqBZip2.Create(nil) do
        begin
          Compress(MS, S);
          Free;
        end;
      S.Free;
      MS.Free;
    end;
end;

end.

