unit Report;

interface

uses
  Classes,
  Variants,
  Product, Grid, Region, Measure;

type
  TReportFlag    = (rfArea, rfCoating, rfAverage, rfMax, rfMin, rfMean, rfMedian, rfVolume, rfStdDev);
  TReportFlagSet = set of TReportFlag;

  TReport = class
  public
    constructor Create( Product : TProduct; Grid : TGrid; Areas : TList;
                        Threshold : TCode; Flags : TReportFlagSet );
    destructor  Destroy;  override;
  private
    fProduct   : TProduct;
    fGrid      : TGrid;
    fAreas     : TList;
    fThreshold : TCode;
    fFlags     : TReportFlagSet;
    fHeader    : string;
    fMeasures  : string;
    fTables    : TList;
    fTabCount  : integer;
    function GetTable( I : integer ) : TStrings;
    function GetHeader( I : integer) : string;
  public
    property Header[I : integer] : string read GetHeader;
    property Measures : string read fMeasures;
    property Tables   : TList  read fTables;
    property Table[I : integer] : TStrings read GetTable;  default;
  public
    procedure MicrosoftWordShow;
    procedure RichEditShow;
    procedure PlainTextShow;
  private
    procedure EnglishVersion;
    procedure SpanishVersion;
  private
    function GetMeasures                    : string;
    function CreateTable( Index : integer ) : TStringList;
    function TableEntry ( Area  : TArea )   : string;
  private  // used by TableEntry
    EntryArea : TArea;
    Tagged    : integer;
    Max, Min  : TCode;
    Sum, SSq  : extended;
    Tag       : extended;
    Msr       : TMeasure;
    Count     : integer;
    RemFlag   : boolean;
    Codes     : TList;
    procedure ProcessArea( Area : TArea );
    function  AreaKM2 : string;
    function  Coating : string;
    function  Average : string;
    function  Maximum : string;
    function  Minimum : string;
    function  Volume  : string;
    function  Mean    : string;
    function  Median  : string;
    function  StdDev  : string;
  end;

implementation

{$WARN UNIT_DEPRECATED OFF}

uses
  SysUtils, Graphics, OleAuto, ComCtrls,
  UtStr,
  Plane,
  RTFReportForm, TXTReportForm;

const
  Tab = #9;

const
  Normal   = 10;
  Heading1 = 12;
  Heading2 = 11;
  Heading3 = 10;

const
  RemarkStr  = '*';
  NoDataStr  = 's/d';
  MinimumStr = '-';

  RemarkComment  = 'No existen datos en algunas celdas';
  NoDataComment  = 'Sin datos en el area';
  MinimumComment = 'Por debajo del minimo de sensibilidad';

type
  TLanguage = (lgNone, lgEnglish, lgSpanish);

var
  MSWord : variant;

const
  MSWordTabPos : array[0..9] of single = (0.25, 7.0, 8.8, 10.6, 12.4, 14.2, 16.0, 17.8, 19.6, 21.4);

// TReport methods

constructor TReport.Create( Product : TProduct; Grid : TGrid; Areas : TList;
                            Threshold : TCode; Flags : TReportFlagSet );
var
  I : integer;
  F : TReportFlag;
begin
  Codes := TList.Create;
  if Grid.Kind <> pkHorizontal
    then raise Exception.Create('La rejilla debe ser horizontal');
  inherited Create;
  fProduct   := Product;
  fGrid      := Grid;
  fAreas     := Areas;
  fThreshold := Threshold;
  fFlags     := Flags;
//  fHeader    := GetHeader;
  fMeasures  := GetMeasures;
  fTabCount  := 0;
  for F := low(TReportFlag) to high(TReportFlag) do
    if F in Flags
      then inc(fTabCount);
  fTables := TList.Create;
  for I := 0 to fAreas.Count - 1 do
    fTables.Add(CreateTable(I));
end;

destructor TReport.Destroy;
var
  I : integer;
begin
  Codes.Free;
  for I := fTables.Count - 1 downto 0 do
    TStrings(fTables[I]).Free;
  FreeAndNil(fTables);
  FreeAndNil(fAreas);
  inherited;
end;

function TReport.GetTable( I : integer ) : TStrings;
begin
  Result := fTables[I];
end;

function TReport.GetHeader;
begin
  Result := '';
  case I of
    0: begin
         Result := Tab + '   ';
         if rfArea    in fFlags then Result := Result + Tab + 'Área de';
         if rfCoating in fFlags then Result := Result + Tab + 'Área';
         if rfAverage in fFlags then Result := Result + Tab + 'Promedio';
         if rfMax     in fFlags then Result := Result + Tab + 'Máximo';
         if rfMin     in fFlags then Result := Result + Tab + 'Mínimo';
         if rfMean    in fFlags then Result := Result + Tab + 'Promedio';
         if rfMedian  in fFlags then Result := Result + Tab + 'Mediana';
         if rfVolume  in fFlags then Result := Result + Tab + 'Volumen';
         if rfStdDev  in fFlags then Result := Result + Tab + 'Desviación';
       end;
    1: begin
         Result := Tab + '   ';
         if rfArea    in fFlags then Result := Result + Tab + 'la Región';
         if rfCoating in fFlags then Result := Result + Tab + 'cubierta';
         if rfAverage in fFlags then Result := Result + Tab + 'en la';
         if rfMax     in fFlags then Result := Result + Tab + ' ' ;
         if rfMin     in fFlags then Result := Result + Tab + ' ';
         if rfMean    in fFlags then Result := Result + Tab + 'en el área';
         if rfMedian  in fFlags then Result := Result + Tab + ' ';
         if rfVolume  in fFlags then Result := Result + Tab + ' ';
         if rfStdDev  in fFlags then Result := Result + Tab + 'estándar';
       end;
    2: begin
         Result := Tab + 'Nombre del area';
         if rfArea    in fFlags then Result := Result + Tab + ' ';
         if rfCoating in fFlags then Result := Result + Tab + ' ';
         if rfAverage in fFlags then Result := Result + Tab + 'Región';
         if rfMax     in fFlags then Result := Result + Tab + ' ';
         if rfMin     in fFlags then Result := Result + Tab + ' ';
         if rfMean    in fFlags then Result := Result + Tab + 'cubierta';
         if rfMedian  in fFlags then Result := Result + Tab + ' ';
         if rfVolume  in fFlags then Result := Result + Tab + ' ';
         if rfStdDev  in fFlags then Result := Result + Tab + ' ';
       end;
   end;
end;

function TReport.GetMeasures : string;
begin
  Result := Tab;
  if rfArea    in fFlags then Result := Result + Tab + 'km²';
  if rfCoating in fFlags then Result := Result + Tab + '%';
  if rfAverage in fFlags then Result := Result + Tab + MeasureName(fGrid.Measure);
  if rfMax     in fFlags then Result := Result + Tab + MeasureName(fGrid.Measure);
  if rfMin     in fFlags then Result := Result + Tab + MeasureName(fGrid.Measure);
  if rfMean    in fFlags then Result := Result + Tab + MeasureName(fGrid.Measure);
  if rfMedian  in fFlags then Result := Result + Tab + MeasureName(fGrid.Measure);
  if rfVolume  in fFlags then Result := Result + Tab + 'Mill. m³';
  if rfStdDev  in fFlags then Result := Result + Tab + MeasureName(fGrid.Measure);
end;

function TReport.CreateTable( Index : integer ) : TStringList;
var
  Area  : TArea;
  I     : integer;
  Entry : string;
begin
  Result := TStringList.Create;
  Area   := TArea(fAreas[Index]);
  for I := 0 to Area.AreaCount - 1 do
    begin
      Entry := TableEntry(Area.Areas[I]);
      if Entry <> ''
        then Result.Add(Entry);
    end;
  Result.Add(TableEntry(Area));
end;

procedure TReport.ProcessArea( Area : TArea );
var
  I : integer;
  C : TCode;
  L : extended;
  XX, YY : integer;
  PC: ^TCode;
begin
  for I := 0 to Area.AreaCount - 1 do
    ProcessArea(Area.Areas[I]);
  for I := 0 to Area.PointCount - 1 do
    with Area[I] do
      begin
        XX := round(X * Area.Region.Length.X / fGrid.Length.X);
        YY := round(Y * Area.Region.Length.Y / fGrid.Length.Y);
        if fGrid.InBounds(XX, YY)
          then
            begin
              C := fGrid[XX, YY];
              if C <= MaxCode
                then
                  begin
                    if C > Max then Max := C;
                    if C < Min then Min := C;
                    L := CodeLineal(C, Msr);
                    if C > fThreshold
                      then
                        begin
                          inc(Tagged);
                          Tag := Tag + L;
                          new(PC);
                          PC^ := C;
                          Codes.Add(PC);
                        end;
                    Sum := Sum + L;
                    SSq := SSq + Sqr(L);
                    inc(Count);
                  end
                else RemFlag := true;
            end
          else RemFlag := true;
      end;
end;

function TReport.AreaKM2 : string;
begin
  if Count > 0
    then
      with EntryArea.Region.Length do
        Result := IntToStr(round(Count * (X/1000) * (Y/1000)))
    else Result := NoDataStr;
end;

function TReport.Coating : string;
begin
  if Count > 0
    then Result := IntToStr(round(100*Tagged/Count))
    else Result := NoDataStr;
end;

function TReport.Average : string;
begin
  if Count > 0
    then
      if (Msr = unDB) or (Msr = unDBZ)
        then
          if Tagged > 0
            then Result := FloatToStrF(ValueToDB(Sum/Count), ffFixed, 5, 2)
            else Result := MinimumStr
        else Result := FloatToStrF(Sum/Count, ffFixed, 5, 2)
    else Result := NoDataStr;
end;

function TReport.Maximum : string;
begin
  if Count > 0
    then
      if ((Msr = unDB) or (Msr = unDBZ)) and (Max = MinCode)
        then Result := MinimumStr
        else Result := FloatToStrF(CodeMeasure(Max, Msr), ffFixed, 5, 2)
    else Result := NoDataStr;
end;

function TReport.Minimum : string;
begin
  if Count > 0
    then
      if ((Msr = unDB) or (Msr = unDBZ)) and (Min = MinCode)
        then Result := MinimumStr
        else Result := FloatToStrF(CodeMeasure(Min, Msr), ffFixed, 5, 2)
    else Result := NoDataStr;
end;

function TReport.Volume : string;
begin
  if Tagged > 0
    then
      with EntryArea.Region.Length do
        Result := FloatToStrF(X * Y * Tag * 1e-9, ffFixed, 5, 3)
    else Result := MinimumStr;
end;

function TReport.Mean : string;
begin
  if Tagged > 0
    then
      if (Msr = unDB) or (Msr = unDBZ)
        then Result := FloatToStrF(ValueToDB(Tag/Tagged), ffFixed, 5, 2)
        else Result := FloatToStrF(Tag/Tagged,            ffFixed, 5, 2)
    else Result := MinimumStr;
end;

function TReport.Median : string;

function CodeCompare(Item1, Item2: pointer): Integer;
begin
  if TCode(Item1^) = TCode(Item2^) then
    result := 0
  else if TCode(Item1^) > TCode(Item2^) then
    result := 1
  else result := -1  
end;

var
  C, M : integer;
  V    : Measure.float;
begin
  if Tagged > 0
    then
      begin
        M := Codes.Count div 2;
        Codes.Sort(@CodeCompare);
        if odd(Codes.Count)
          then V := CodeMeasure(LinealCode((CodeLineal(TCode(Codes[M]^),     Msr) +
                                            CodeLineal(TCode(Codes[M + 1]^), Msr))/2, Msr), Msr )
          else V := CodeMeasure(TCode(Codes[M]^), Msr);
        if V = -80 then
          Result := '< Senb'
        else
          Result := FloatToStrF(V, ffFixed, 5, 2)
      end
    else Result := MinimumStr;
end;

function TReport.StdDev : string;
var
  Dev : extended;
begin
  if Count > 0
    then
      begin
        if Count > 1
          then Dev := sqrt((SSq - sqr(Sum)/Count)/(Count - 1))
          else Dev := 0;
        if (Msr = unDB) or (Msr = unDBZ)
          then
            if Tagged > 0
              then Result := FloatToStrF(ValueToDB(Dev), ffFixed, 5, 2)
              else Result := MinimumStr
          else Result := FloatToStrF(Dev, ffFixed, 5, 2)
      end
    else Result := NoDataStr;
end;

function TReport.TableEntry( Area : TArea ) : string;
begin
  EntryArea := Area;
  Tagged    := 0;
  Max       := MinCode;
  Min       := MaxCode;
  Sum       := 0.0;
  SSq       := 0.0;
  Tag       := 0.0;
  RemFlag   := false;
  Msr       := fGrid.Measure;
  Count     := 0;
  Codes.Clear;
  ProcessArea(Area);
  if (Count > 0) and (Tagged > 0)
    then
      begin
        Result := Tab + Area.Name;
        if rfArea    in fFlags then Result := Result + Tab + AreaKM2;
        if rfCoating in fFlags then Result := Result + Tab + Coating;
        if rfAverage in fFlags then Result := Result + Tab + Average;
        if rfMax     in fFlags then Result := Result + Tab + Maximum;
        if rfMin     in fFlags then Result := Result + Tab + Minimum;
        if rfMean    in fFlags then Result := Result + Tab + Mean;
        if rfMedian  in fFlags then Result := Result + Tab + Median;
        if rfVolume  in fFlags then Result := Result + Tab + Volume;
        if rfStdDev  in fFlags then Result := Result + Tab + StdDev;
        if RemFlag then Result := RemarkStr + Result;
      end
    else Result := '';
end;

procedure TReport.MicrosoftWordShow;
var
  S : string;
  L : TLanguage;
begin
  L := lgNone;
  try
    MSWord := CreateOleObject('Word.Basic');
  except
    on E : EOleError do
      begin
        E.Message := 'No se pudo ejecutar Microsoft Word: ' + E.Message;
        raise;
      end;
  end;
  try
    S := MSWord.AppInfo(16);
    if Pos('english', LowerCase(S)) > 0
      then L := lgEnglish;
  except
    on EOleError do
      try
        S := MSWord.ApInfo(16);
        if Pos('español', LowerCase(S)) > 0
          then L := lgSpanish;
      except
        on E : EOleError do
      end;
  end;
  case L of
    lgEnglish : EnglishVersion;
    lgSpanish : SpanishVersion;
    else
      begin
        MSWord := unassigned;
        raise Exception.Create('Microsoft Word debe ser version Ingles o Español');
      end;
  end;
end;

procedure TReport.RichEditShow;
var
  I : integer;
begin
  with TFRTFReport.Create(nil) do
    try
      with RichEdit1 do
        begin
          Paragraph.TabCount := 12;
          Paragraph.Tab[ 0] :=  20;
          Paragraph.Tab[ 1] := 200;
          Paragraph.Tab[ 2] := 250;
          Paragraph.Tab[ 3] := 300;
          Paragraph.Tab[ 4] := 350;
          Paragraph.Tab[ 5] := 400;
          Paragraph.Tab[ 6] := 450;
          Paragraph.Tab[ 7] := 500;
          Paragraph.Tab[ 8] := 550;
          Paragraph.Tab[ 9] := 600;
          Paragraph.Tab[10] := 650;
          Paragraph.Tab[11] := 700;
          DefAttributes.Name := 'Arial';
          DefAttributes.Size := Normal;
          SelAttributes.Name := 'Arial';
          SelAttributes.Style := [fsBold];
          SelAttributes.Size  := Heading1;
          Lines.Add('Reporte de ' + MeasureText(fGrid.Measure));
          Lines.Add('');
          SelAttributes.Style := [];
          SelAttributes.Size  := Normal;
          Lines.Add('Creado ' + FormatDateTime('dddddd; t', Now) + ', a partir del producto:');
          SelAttributes.Style := [fsItalic];
          Lines.Add(fProduct.Brief);
          SelAttributes.Style := [];
          Lines.Add('');
          SelAttributes.Style := [fsBold];
          SelAttributes.Size  := Heading2;
          Lines.Add('Region(es):');
          SelAttributes.Style := [];
          SelAttributes.Size  := Normal;
          Paragraph.Numbering := nsBullet;
          for I := 0 to fAreas.Count - 1 do
            Lines.Add(TArea(fAreas[I]).Name);
          Paragraph.Numbering := nsNone;
          for I := 0 to fTables.Count - 1 do
            if Table[I].Text <> #$D#$A then
              begin
                Lines.Add('');
                SelAttributes.Style := [fsBold];
                SelAttributes.Size  := Heading2;
                Lines.Add(TArea(fAreas[I]).Name + ':');
                SelAttributes.Size  := Heading3;
                Lines.Add(Header[0]);
                Lines.Add(Header[1]);
                Lines.Add(Header[2]);
                SelAttributes.Style := [fsBold, fsItalic];
                Lines.Add(Measures);
                SelAttributes.Style := [];
                SelAttributes.Size  := Normal;
                Lines.AddStrings(Table[I]);
              end;
          Lines.Add('');
          SelAttributes.Style := [fsBold];
          Lines.Add(RemarkStr  + Tab + RemarkComment);
//          Lines.Add(NoDataStr  + Tab + NoDataComment);
//          Lines.Add(MinimumStr + Tab + MinimumComment);
          SelAttributes.Style := [];
        end;
    except
      Free;
      raise;
    end;
end;

procedure TReport.PlainTextShow;

  function FixTabs( const S : string ) : string;
  const
    TabStops : array[0..9] of integer = (2, 30, 40, 50, 60, 70, 80, 90, 100, 110);
  var
    P, T : integer;
  begin
    Result := S;
    T      := 0;
    P      := pos(Tab, Result);
    while P > 0 do
      begin
        Delete(Result, P, 1);
        Insert(Spaces(TabStops[T] - P), Result, P);
        P := pos(Tab, Result);
        inc(T);
      end;
  end;

var
  I, J : integer;
begin
  with TFTXTReport.Create(nil) do
    try
      with Memo1 do
        begin
          Font.Name  := 'Courier New';
          Font.Pitch := fpFixed;
          Font.Size  := 11;
          Lines.Add('Reporte de ' + MeasureVar(fGrid.Measure));
          Lines.Add('');
          Lines.Add('Creado ' + FormatDateTime('dddddd; t', Now) + ', a partir del producto:');
          Lines.Add(fProduct.Brief);
          Lines.Add('con fecha de creacion ' + FormatDateTime('dddddd; t', fGrid.Time) + '.');
          Lines.Add('');
          Lines.Add('Region(es):');
          for I := 0 to fAreas.Count - 1 do
            Lines.Add('- ' + TArea(fAreas[I]).Name);
          for I := 0 to fTables.Count - 1 do
            begin
              Lines.Add('');
              Lines.Add(TArea(fAreas[I]).Name + ':');
              Lines.Add(FixTabs(Header[0]));
              Lines.Add(FixTabs(Header[1]));
              Lines.Add(FixTabs(Header[2]));
              Lines.Add(FixTabs(Measures));
              for J := 0 to Table[I].Count - 1 do
                Lines.Add(FixTabs(Table[I][J]));
            end;
          Lines.Add('');
          Lines.Add(RemarkStr  + Tab + RemarkComment);
          Lines.Add(NoDataStr  + Tab + NoDataComment);
          Lines.Add(MinimumStr + Tab + MinimumComment);
        end;
    finally
      Free;
    end;
end;

procedure TReport.EnglishVersion;
var
  I, J : integer;
begin
  MSWord.FileNew;
  MSWord.DocMaximize(1);
  MSWord.ViewPage;
  MSWord.ViewZoomPageWidth;
  //
  MSWord.FormatStyle(Name := 'Normal', Define := 1);
  MSWord.FormatDefineStyleLang(Language := '0'{'Español'});
  MSWord.FormatDefineStyleFont(Font := 'Arial', Points := Normal);
  MSWord.FormatDefineStylePara(Before := 3, After := 3,
                               LineSpacingRule := 0,
                               Alignment := 3,
                               WidowControl := 1);
  MSWord.FormatDefineStyleTabs(Position := FloatToStr(MSWordTabPos[0]) + 'cm', Align := 0);
  for I := 1 to fTabCount do
    MSWord.FormatDefineStyleTabs(Position := FloatToStr(MSWordTabPos[I]) + 'cm', Align := 1);
  MSWord.FormatDefineStyleTabs(Position := FloatToStr(MSWordTabPos[fTabCount] + 0.8) + 'cm', Align := 2);
  MSWord.FormatStyle(Name := 'Heading 1', Define := 1);
  MSWord.FormatDefineStyleFont(Points := Heading1, Bold := 1, Italic := 0);
  MSWord.FormatDefineStylePara(Before := 6, After := 18, Alignment := 0, WidowControl := 1, KeepWithNext := 1);
  MSWord.FormatStyle(Name := 'Heading 2', Define := 1);
  MSWord.FormatDefineStyleFont(Points := Heading2, Bold := 1, Italic := 0);
  MSWord.FormatDefineStylePara(Before := 18, After := 6, Alignment := 0, WidowControl := 1, KeepWithNext := 1);
  MSWord.FormatStyle(Name := 'Heading 3', Define := 1);
  MSWord.FormatDefineStyleFont(Points := Heading3, Bold := 1, Italic := 0);
  MSWord.FormatDefineStylePara(Before := 0, After := 6, Alignment := 0, WidowControl := 1, KeepWithNext := 1);
  MSWord.FormatStyle(Name := 'Remark', Define := 1);
  MSWord.FormatDefineStylePara(KeepWithNext := 1);
  MSWord.FormatDefineStyleTabs(ClearAll := 1);
  MSWord.FormatDefineStyleTabs(Position := '0.75cm', Align := 0);
  //
  MSWord.AppMaximize(1);
  MSWord.AppShow;
  //
  MSWord.Style('Heading 1');
  MSWord.Insert('Reporte de ' + MeasureVar(fGrid.Measure));
  MSWord.InsertPara;
  //
  MSWord.NormalStyle;
  MSWord.Insert('Creado ' + FormatDateTime('dddddd; t', Now) + ', a partir del producto:');
  MSWord.InsertPara;
  MSWord.FormatFont(Italic := 1);
  MSWord.Insert(fProduct.Brief);
  MSWord.FormatFont(Italic := 0);
  MSWord.InsertPara;
  MSWord.Insert('con fecha de creacion ' + FormatDateTime('dddddd; t', fGrid.Time) + '.');
  MSWord.InsertPara;
  //
  MSWord.Style('Heading 2');
  MSWord.Insert('Region(es):');
  MSWord.InsertPara;
  MSWord.NormalStyle;
  MSWord.FormatBulletDefault;
  for I := 0 to fAreas.Count - 1 do
    begin
      MSWord.Insert(TArea(fAreas[I]).Name);
      MSWord.InsertPara;
    end;
  MSWord.FormatBulletDefault;
  //
  for I := 0 to fTables.Count - 1 do
    begin
      MSWord.Style('Heading 2');
      MSWord.Insert(TArea(fAreas[I]).Name + ':');
      MSWord.InsertPara;
      MSWord.Style('Heading 3');
      MSWord.Insert(Header[0]);
      MSWord.Insert(Header[1]);
      MSWord.Insert(Header[2]);
      MSWord.InsertPara;
      MSWord.FormatFont(Italic := 1);
      MSWord.Insert(Measures);
      MSWord.FormatFont(Italic := 0);
      MSWord.InsertPara;
      MSWord.NormalStyle;
      for J := 0 to Table[I].Count - 1 do
        begin
          MSWord.Insert(Table[I][J]);
          MSWord.InsertPara;
        end;
    end;
  //
  MSWord.Style('Heading 2');
  MSWord.Insert('Leyenda:');
  MSWord.InsertPara;
  MSWord.Style('Remark');
  MSWord.FormatFont(Bold := 0);
  MSWord.Insert(RemarkStr + Tab);
  MSWord.FormatFont(Bold := 1);
  MSWord.Insert(RemarkComment);
  MSWord.InsertPara;
  MSWord.FormatFont(Bold := 0);
  MSWord.Insert(NoDataStr + Tab);
  MSWord.FormatFont(Bold := 1);
  MSWord.Insert(NoDataComment);
  MSWord.InsertPara;
  MSWord.FormatFont(Bold := 0);
  MSWord.Insert(MinimumStr + Tab);
  MSWord.FormatFont(Bold := 1);
  MSWord.Insert(MinimumComment);
  MSWord.InsertPara;
  MSWord.NormalStyle;
  //
  //MSWord.StartOfDocument;
end;

procedure TReport.SpanishVersion;
var
  I, J : integer;
begin
  MSWord.ArchivoNuevo;
  MSWord.DocMaximizar(1);
  MSWord.VerPágina;
  MSWord.VerZoomAnchoPágina;
  //
  MSWord.FormatoEstilo(Nombre := 'Normal', Definir := 1);
  MSWord.FormatoDefinirEstiloIdioma(Idioma := '0'{'Español'});
  MSWord.FormatoDefinirEstiloFuente(Fuente := 'Arial', Puntos := Normal);
  MSWord.FormatoDefinirEstiloPárrafo(Antes := 3, Después := 3,
                                     InterlineadoRegla := 0,
                                     Alineación := 3,
                                     ControlDeLíneasViudas := 1);
  MSWord.FormatoDefinirEstiloTabs(Posición := FloatToStr(MSWordTabPos[0]) + 'cm', Alinear := 0);
  for I := 1 to fTabCount do
    MSWord.FormatoDefinirEstiloTabs(Posición := FloatToStr(MSWordTabPos[I]) + 'cm', Alinear := 1);
  MSWord.FormatoDefinirEstiloTabs(Posición := FloatToStr(MSWordTabPos[fTabCount] + 0.8) + 'cm', Alinear := 2);
  MSWord.FormatoEstilo(Nombre := 'Título 1', Definir := 1);
  MSWord.FormatoDefinirEstiloFuente(Puntos := Heading1, Negrita := 1, Cursiva := 0);
  MSWord.FormatoDefinirEstiloPárrafo(Antes := 6, Después := 18, Alineación := 0, ControlDeLíneasViudas := 1, ConservarConElSiguiente := 1);
  MSWord.FormatoEstilo(Nombre := 'Título  2', Definir := 1);
  MSWord.FormatoDefinirEstiloFuente(Puntos := Heading2, Negrita := 1, Cursiva := 0);
  MSWord.FormatoDefinirEstiloPárrafo(Antes := 18, Después := 6, Alineación := 0, ControlDeLíneasViudas := 1, ConservarConElSiguiente := 1);
  MSWord.FormatoEstilo(Nombre := 'Título  3', Definir := 1);
  MSWord.FormatoDefinirEstiloFuente(Puntos := Heading3, Negrita := 1, Cursiva := 0);
  MSWord.FormatoDefinirEstiloPárrafo(Antes := 0, Después := 6, Alineación := 0, ControlDeLíneasViudas := 1, ConservarConElSiguiente := 1);
  MSWord.FormatoEstilo(Nombre := 'Comentario', Definir := 1);
  MSWord.FormatoDefinirEstiloPárrafo(ConservarConElSiguiente := 1);
  MSWord.FormatoDefinirEstiloTabs(BorrarTodas := 1);
  MSWord.FormatoDefinirEstiloTabs(Posición := '0.75cm', Alinear := 0);
  //
  MSWord.ApMaximizar(1);
  MSWord.ApMostrar;
  //
  MSWord.Estilo('Título 1');
  MSWord.Insertar('Reporte de ' + MeasureVar(fGrid.Measure));
  MSWord.InsertarPárra;
  //
  MSWord.EstiloNormal;
  MSWord.Insertar('Creado ' + FormatDateTime('dddddd; t', Now) + ', a partir del producto:');
  MSWord.InsertarPárra;
  MSWord.FormatoFuente(Cursiva := 1);
  MSWord.Insertar(fProduct.Brief);
  MSWord.FormatoFuente(Cursiva := 0);
  MSWord.InsertarPárra;
  MSWord.Insertar('con fecha de creacion ' + FormatDateTime('dddddd; t', fGrid.Time) + '.');
  MSWord.InsertarPárra;
  //
  MSWord.Estilo('Título 2');
  MSWord.Insertar('Region(es):');
  MSWord.InsertarPárra;
  MSWord.EstiloNormal;
  MSWord.FormatoViñetaPredeter;
  for I := 0 to fAreas.Count - 1 do
    begin
      MSWord.Insertar(TArea(fAreas[I]).Name);
      MSWord.InsertarPárra;
    end;
  MSWord.FormatoViñetaPredeter;
  //
  for I := 0 to fTables.Count - 1 do
    begin
      MSWord.Estilo('Título 2');
      MSWord.Insertar(TArea(fAreas[I]).Name + ':');
      MSWord.InsertarPárra;
      MSWord.Estilo('Título 3');
      MSWord.Insertar(Header[0]);
      MSWord.Insertar(Header[1]);
      MSWord.Insertar(Header[2]);
      MSWord.InsertarPárra;
      MSWord.FormatoFuente(Cursiva := 1);
      MSWord.Insertar(Measures);
      MSWord.FormatoFuente(Cursiva := 0);
      MSWord.InsertarPárra;
      MSWord.EstiloNormal;
      for J := 0 to Table[I].Count - 1 do
        begin
          MSWord.Insertar(Table[I][J]);
          MSWord.InsertarPárra;
        end;
    end;
  //
  MSWord.Estilo('Título 2');
  MSWord.Insertar('Leyenda:');
  MSWord.InsertarPárra;
  MSWord.Estilo('Commentario');
  MSWord.FormatoFuente(Negrita := 0);
  MSWord.Insertar(RemarkStr + Tab);
  MSWord.FormatoFuente(Negrita := 1);
  MSWord.Insertar(RemarkComment);
  MSWord.InsertarPárra;
  MSWord.FormatoFuente(Negrita := 0);
  MSWord.Insertar(NoDataStr + Tab);
  MSWord.FormatoFuente(Negrita := 1);
  MSWord.Insertar(NoDataComment);
  MSWord.InsertarPárra;
  MSWord.FormatoFuente(Negrita := 0);
  MSWord.Insertar(MinimumStr + Tab);
  MSWord.FormatoFuente(Negrita := 1);
  MSWord.Insertar(MinimumComment);
  MSWord.InsertarPárra;
  MSWord.EstiloNormal;
  //
  //MSWord.PrincipioDeDocumento;
end;

end.
