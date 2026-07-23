unit EditForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Spin, StdCtrls, ExtCtrls,
  Measure, DataSource, RadarData, Observation, ComCtrls, Grids, Area;

type
  TFEdit = class(TForm)
    Button1: TButton;
    Button2: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label1: TLabel;
    StringGrid1: TStringGrid;
    Label3: TLabel;
    Area1: TArea;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    UpDown4: TUpDown;
    UpDown5: TUpDown;
    UpDown6: TUpDown;
    UpDown7: TUpDown;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Label13: TLabel;
    Edit8: TEdit;
    UpDown8: TUpDown;
    Label14: TLabel;
    Label11: TLabel;
    Edit9: TEdit;
    UpDown1: TUpDown;
    ComboBox1: TComboBox;
    CheckBox3: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Area1Change(Sender: TObject);
    procedure UpDown3Click(Sender: TObject; Button: TUDBtnType);
    procedure UpDown4Click(Sender: TObject; Button: TUDBtnType);
    procedure UpDown5Click(Sender: TObject; Button: TUDBtnType);
    procedure UpDown6Click(Sender: TObject; Button: TUDBtnType);
    procedure UpDown7Click(Sender: TObject; Button: TUDBtnType);
    procedure StringGrid1SelectCell(Sender: TObject; Col, Row: Longint;
      var CanSelect: Boolean);
    procedure Edit3Change(Sender: TObject);
    procedure Edit4Change(Sender: TObject);
    procedure Edit5Change(Sender: TObject);
    procedure Edit6Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    fDataSource: TDataSource;
    procedure AdjustMargins;
  protected
    function  GetDefault : boolean;
    function  GetRemember: boolean;
    procedure SetDataSource(D: TDataSource);  virtual;
    function  GetMeasure: TMeasure;
    procedure SetMeasure(Msr: TMeasure);
    function  GetChannel: integer;
    procedure SetChannel(V: integer);
    function  GetCellH: integer;
    procedure SetCellH(V: integer);
    function  GetMaxRange: integer;
    procedure SetMaxRange(V: integer);
    procedure SetSupressStatus (B: Boolean);//mio
    function  GetSupressStatus: Boolean; ///mio
  public
    property SetDefault: boolean     read GetDefault;
    property Remember  : boolean     read GetRemember;
    property DataSource: TDataSource read fDataSource write SetDataSource;
    property Measure   : TMeasure    read GetMeasure  write SetMeasure;
    property Channel   : integer     read GetChannel  write SetChannel;
    property CellH     : integer     read GetCellH    write SetCellH;
    property MaxRange  : integer     read GetMaxRange write SetMaxRange;
    property Supressing: boolean     read GetSupressStatus  write SetSupressStatus;//mio******
  private
    fValidMeasure: TMeasureSet;
    procedure UpdateObsMeasure(Obs: TObservation);
    procedure UpdateCombo;
  end;

var
  FEdit: TFEdit;

implementation

{$R *.DFM}

uses
  Math,
  FormUtils,
  Settings,
  Description,
  SupressStatus;

const
  StringGrid1Widths: array[0..6] of integer = (20, 40, 30, 40, 35, 45, 45);

// Private procedures & functions

function ChannelCaption(const Channel: TChannelDesc): string;
begin
  try
    with Channel do
      begin
        case Wave of
          wl3cm : Result := '3 cm';
          wl10cm: Result := '10 cm';
        end;
        case Pulse of
          plLong : Result := Result + ', largo, ';
          plShort: Result := Result + ', corto, ';
        end;
        Result := Result + IntToStr(Cells) + 'x' + IntToStr(Length);
      end;
  except
    on EConvertError do
      Result := '';
  end;
end;

// EditForm methods

procedure TFEdit.AdjustMargins;
var
  B: boolean;
begin
  with StringGrid1 do
    if assigned(OnSelectCell)
      then
        begin
          B := true;
          OnSelectCell(StringGrid1, Col, Row, B);
        end;
end;

function TFEdit.GetDefault: boolean;
begin
  Result := CheckBox1.Checked;
end;

function TFEdit.GetRemember: boolean;
begin
  Result := CheckBox2.Checked;
end;

function TFEdit.GetMeasure: TMeasure;
begin
  with ComboBox1 do
    Result := TMeasure(Items.Objects[ItemIndex]);
end;

procedure TFEdit.SetMeasure(Msr: TMeasure);
var
  I: integer;
begin
  with ComboBox1.Items do
    for I := Count - 1 downto 0 do
      if TMeasure(ComboBox1.Items.Objects[I]) = Msr then break;
  if I < 0 then I := 0;
  ComboBox1.ItemIndex := I;
end;

function TFEdit.GetChannel: integer;
begin
  Result := pred(StringGrid1.Row);
end;

procedure TFEdit.SetChannel(V: integer);
begin
  if V < (StringGrid1.RowCount - 1)
    then StringGrid1.Row := V + 1
    else StringGrid1.Row := StringGrid1.RowCount - 1;
end;

function TFEdit.GetCellH: integer;
begin
  Result := UpDown8.Position;
end;

procedure TFEdit.SetCellH(V: integer);
begin
  UpDown8.Position := V;
  Edit8.Text := IntToStr(V);
end;

function TFEdit.GetMaxRange: integer;
begin
  Result := UpDown1.Position;
end;

procedure TFEdit.SetMaxRange(V: integer);
begin
  UpDown1.Position := V;
  Edit9.Text := IntToStr(V);
end;

procedure TFEdit.SetDataSource(D: TDataSource);
var
  I: integer;
  O: TDataSource;
begin
  fDataSource := D;
  // Canales
  StringGrid1.Visible  := D.InheritsFrom(TRadarData);
  TabSheet2.TabVisible := StringGrid1.Visible;
  if StringGrid1.Visible
    then
      with StringGrid1, D as TRadarData do
        begin
          RowCount := Channels + 1;
          for I := 0 to Channels - 1 do
            FillChannelRow(Rows[I + 1], Channel[I]);
          SetRelColWidths(StringGrid1, StringGrid1Widths);
          Row := 1;
          AdjustMargins;
        end;
  O := D.Source[0];
  if O is TObservation
    then UpdateObsMeasure(O as TObservation);
end;

procedure TFEdit.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet1;
  with StringGrid1.Rows[0] do
    begin
      Strings[0] := 'No.';
      Strings[1] := 'Lambda';
      Strings[2] := 'Pulso';
      Strings[3] := 'Angulo';
      Strings[4] := 'Celdas';
      Strings[5] := 'Tamaño';
      Strings[6] := 'Alcance';
    end;
  SetRelColWidths(StringGrid1, StringGrid1Widths);
  fValidMeasure := [unDB, unDBZ, unMMH, unMS, unZDR, unPDP, unRho, unKDP, unGCP, unTID];
  UpdateCombo;
end;

procedure TFEdit.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TFEdit.Area1Change(Sender: TObject);
begin
  with Sender as TArea do
    begin
      UpDown4.Position := East;
      UpDown5.Position := West;
      UpDown6.Position := North;
      UpDown7.Position := South;
      Edit3.Text := IntToStr(East);
      Edit4.Text := IntToStr(West);
      Edit5.Text := IntToStr(North);
      Edit6.Text := IntToStr(South);
    end;
end;

procedure TFEdit.UpDown3Click(Sender: TObject; Button: TUDBtnType);
begin
  SetMeasure(TMeasure((Sender as TUpDown).Position));
end;

procedure TFEdit.UpDown4Click(Sender: TObject; Button: TUDBtnType);
begin
  Area1.East := (Sender as TUpDown).Position;
end;

procedure TFEdit.UpDown5Click(Sender: TObject; Button: TUDBtnType);
begin
  Area1.West := (Sender as TUpDown).Position;
end;

procedure TFEdit.UpDown6Click(Sender: TObject; Button: TUDBtnType);
begin
  Area1.North := (Sender as TUpDown).Position;
end;

procedure TFEdit.UpDown7Click(Sender: TObject; Button: TUDBtnType);
begin
  Area1.South := (Sender as TUpDown).Position;
end;

procedure TFEdit.StringGrid1SelectCell(Sender: TObject; Col, Row: Longint;
  var CanSelect: Boolean);
var
  MR: integer;
begin
  if CanSelect
    then
      if DataSource.InheritsFrom(TRadarData)
        then
          with (DataSource as TRadarData).Channel[Row - 1], Area1, theSettings do
            begin
            //CellH    := Length;
              MR := (Cells) * Length div 1000;
              MaxEast  :=  MR;
              MaxWest  := -MR;
              MaxNorth :=  MR;
              MaxSouth := -MR;
              UpDown4.Min := MaxWest;
              UpDown4.Max := MaxEast;
              UpDown5.Min := MaxWest;
              UpDown5.Max := MaxEast;
              UpDown6.Min := MaxSouth;
              UpDown6.Max := MaxNorth;
              UpDown7.Min := MaxSouth;
              UpDown7.Max := MaxNorth;
              Area1.East  := Min(MaxEast, DefaultHorzEast);
              Area1.West  := Max(MaxWest, DefaultHorzWest);
              Area1.North := Min(MaxNorth, DefaultHorzNorth);
              Area1.South := Max(MaxSouth, DefaultHorzSouth);
              UpDown1.Min := 10;
              UpDown1.Max := MR;
              UpDown1.Position := DefaultMaxRange;
//              MaxRange := DefaultMaxRange;
            end;
end;

procedure TFEdit.Edit3Change(Sender: TObject);
begin
  Area1.East := UpDown4.Position;
end;

procedure TFEdit.Edit4Change(Sender: TObject);
begin
  Area1.West := UpDown5.Position;
end;

procedure TFEdit.Edit5Change(Sender: TObject);
begin
  Area1.North := UpDown6.Position;
end;

procedure TFEdit.Edit6Change(Sender: TObject);
begin
  Area1.South := UpDown7.Position;
end;

procedure TFEdit.FormShow(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet1;
  CheckBox1.Checked := true;
  CheckBox2.Checked := true;
  CheckBox3.Checked := theSupressStatus; ///mio**analizar
end;

procedure TFEdit.UpdateObsMeasure(Obs: TObservation);
var
  I: integer;
begin
  if assigned(Obs)
    then
      begin
        fValidMeasure := [];
        with Obs do
          for I := 0 to Movements - 1 do
            Include(fValidMeasure, MoveDesc[I].Measure);
{        fValidMeasure := [unDBZ];}
        if unDB  in fValidMeasure then Include(fValidMeasure, unDBZ);
        if unDBZ in fValidMeasure then Include(fValidMeasure, unMMH);
        if unKDP in fValidMeasure then Include(fValidMeasure, unMMH);
        UpdateCombo;
      end;
end;

procedure TFEdit.UpdateCombo;
var
  M: TMeasure;
begin
  ComboBox1.Items.Clear;
  for M := Low(TMeasure) to High(TMeasure) do
    if M in fValidMeasure
      then ComboBox1.Items.AddObject(MeasureVar(M) + ' [' + MeasureName(M) + ']', pointer(M));
  ComboBox1.ItemIndex := 0;
end;

///mio****************
procedure  TFEdit.SetSupressStatus (B: Boolean);
begin
 CheckBox3.Checked := B;
end;

function TFEdit.GetSupressStatus: Boolean;
begin
  Result := CheckBox3.Checked ;
end;
//***************************

end.
