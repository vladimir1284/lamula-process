unit CalMovForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,
  GridForm, Plane, ExtCtrls, jpeg;

type
  TFCalMov = class(TForm)
    Label1: TLabel;
    GroupBox1: TGroupBox;
    Label9: TLabel;
    Panel1: TPanel;
    GroupBox2: TGroupBox;
    Label6: TLabel;
    Edit2: TEdit;
    GroupBox3: TGroupBox;
    Label2: TLabel;
    Edit3: TEdit;
    GroupBox4: TGroupBox;
    Label8: TLabel;
    Edit4: TEdit;
    Panel2: TPanel;
    Image1: TImage;
    Label3: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    function Rumb(TheAngle: single): string;
  end;

function XFromAngle(Radius, TheAngle: single): integer;
function YFromAngle(Radius, TheAngle: single): integer;

var
  RoseBitMap: TBitmap;
  FCalMov: TFCalMov;
  Grid1, Grid2: TFGrid;
  MovMark1, MovMark2: TPoint;
  MovMark1Loc, MovMark2Loc: T2DLocation;

procedure CheckMovMarks;
procedure HideMovMark1;
procedure HideMovMark2;
function MarksAssigned: boolean;
procedure CloseMovWindow;

implementation

{$R *.dfm}

uses
  CalcFunctions,
  ObservationForm, DateUtils;

procedure CheckMovMarks;
begin
  if MarksAssigned then
    begin
      if not Assigned(FCalMov) then
        Application.CreateForm(TFCalMov, FCalMov);
      FCalMov.FormShow(nil);
      FCalMov.Show;
    end
  else if Assigned(FCalMov) then
    CloseMovWindow;
end;

procedure HideMovMark1;
begin
  if Assigned(Grid1) then
    begin
      Grid1.fEnableMovMark1 := false;
      Grid1.UpdateBuffBitmap;
    end;
  CheckMovMarks
end;

procedure HideMovMark2;
begin
  if Assigned(Grid2) then
    begin
      Grid2.fEnableMovMark2 := false;
      Grid2.UpdateBuffBitmap;
    end;
  CheckMovMarks
end;

function MarksAssigned: boolean;
begin
  result := ((Assigned(Grid1) and Grid1.fEnableMovMark1) or
             (Assigned(Grid2) and Grid2.fEnableMovMark1)) and
            ((Assigned(Grid1) and Grid1.fEnableMovMark2) or
             (Assigned(Grid2) and Grid2.fEnableMovMark2))
end;

procedure CloseMovWindow;
begin
  if Assigned(FCalMov) then
    FCalMov.Close;
end;

function XFromAngle;
begin
  result := Round(Radius*cos((TheAngle - 90)*pi/180));
end;

function YFromAngle;
begin
  result := Round(Radius*sin((TheAngle - 90)*pi/180));
end;

function TFCalMov.Rumb;
const
  R: array[0..16] of string = (
    'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
    'S', 'SSO', 'SO', 'OSO', 'O', 'ONO', 'NO', 'NNO', 'N');
begin
  result := R[Trunc((TheAngle + 22.5/2)/22.5)];
end;

procedure TFCalMov.FormShow(Sender: TObject);
const
  PointLength = 8;
  PointAngle  = 35;
  LineLength  = 38;
var
  Range, Azimut, Hours: real;
  Point: TPoint;
begin
  Range := CalcFunctions.Range(MovMark1Loc.Latitude*pi/180, MovMark1Loc.Longitude*pi/180, MovMark2Loc.Latitude*pi/180, MovMark2Loc.Longitude*pi/180);
  Edit2.Text := FloatToStrF(Range, ffFixed, 18, 3);
  Azimut := CalcFunctions.Azimut(MovMark1Loc.Latitude*pi/180, MovMark1Loc.Longitude*pi/180, MovMark2Loc.Latitude*pi/180, MovMark2Loc.Longitude*pi/180, Range);
  Label9.Caption := Rumb(Azimut);
  Label3.Caption := '(' + FloatToStrF(Azimut, ffFixed, 18, 2) + ' grados)';
  Hours := HourSpan(Grid1.Grid.Time, Grid2.Grid.Time);
  Edit3.Text := Format('%.2d:%.2d:%.2d', [Trunc(Hours), Trunc(Frac(Hours)*60), (Trunc(Frac(Hours)*3600) Mod 60)]);
  Edit4.Text := FloatToStrF(Speed(Range, Hours), ffFixed, 18, 2);
  Image1.Picture.Bitmap.Assign(RoseBitMap);
  with Image1.Canvas do
    begin
      Pen.Color := clRed;
      Pen.Width := 3;
      Brush.Style := bsClear;
      MoveTo(Image1.Width div 2, Image1.Height div 2);
      Point.X := Image1.Width  div 2 + XFromAngle(LineLength, Azimut);
      Point.Y := Image1.Height div 2 + YFromAngle(LineLength, Azimut);
      LineTo(Point.X, Point.Y);
      MoveTo(Point.X, Point.Y);
      Azimut := Azimut + 180;
      if Azimut >= 360 then Azimut := Azimut - 360;
      LineTo(Point.X + XFromAngle(PointLength, Azimut + PointAngle), Point.Y + YFromAngle(PointLength, Azimut + PointAngle));
      MoveTo(Point.X, Point.Y);
      LineTo(Point.X + XFromAngle(PointLength, Azimut - PointAngle), Point.Y + YFromAngle(PointLength, Azimut - PointAngle));
    end;
end;

procedure TFCalMov.FormCreate(Sender: TObject);
begin
  RoseBitMap.Assign(Image1.Picture.Bitmap);
end;

procedure TFCalMov.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FCalMov := nil;
  Action := caFree;
end;

initialization
  RoseBitMap := TBitMap.Create;
finalization
  RoseBitMap.Free;
end.
