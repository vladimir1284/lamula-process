{$DEFINE NMEA_2010}

unit EditNMEAForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Buttons;

type
  TFEditNMEA = class(TForm)
    GroupBox3: TGroupBox;
    TrackBar1: TTrackBar;
    DateTimePicker2: TDateTimePicker;
    GroupBox2: TGroupBox;
    TrackBar2: TTrackBar;
    DateTimePicker4: TDateTimePicker;
    Panel2: TPanel;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    ColorDialog1: TColorDialog;
    Label3: TLabel;
    Label4: TLabel;
    procedure TrackBar1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Panel2Click(Sender: TObject);
    procedure Panel1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure DateTimePicker2Change(Sender: TObject);
    procedure DateTimePicker4Change(Sender: TObject);
  private
    fStrings: TStringList;
  public
    procedure Reload;
    procedure Draw;
    function GetTime(ind: integer): TDateTime;
    function SetTime(aTime: TDateTime): integer;
  end;

var
  FEditNMEA: TFEditNMEA;

procedure ValidateNMEAStringList(S: TStringList);

implementation

uses
  Settings, Shell_Process, GridForm, UtStr, DateUtils, TimeUtils;

{$R *.dfm}

procedure ValidateNMEAStringList(S: TStringList);
var
  i: integer;
  tmp: string;
begin
  with S do
    begin
      while i < Count do
        begin
          {$IFDEF NMEA_2010}
          if (Pos('$GPS', Strings[i]) = 0) then
          {$ELSE}
          if (Pos('$GPRMC', Strings[i]) = 0) and
             (Pos('$GPGGA', Strings[i]) = 0) then
          {$ENDIF}
            Delete(i)
          else
            begin
               tmp := Strings[i];
               while Pos('''', tmp) > 0  do
                 System.Delete(tmp, Pos('''', tmp), 1);
               Strings[i] := tmp;
              Inc(i);
            end;
        end;
      i := 0;
      while  i < Count - 1 do
        if (Pos('INVALID', Strings[i    ]) > 0) or
           (Pos('INVALID', Strings[i + 1]) > 0) then
          Delete(i)
        else
          Inc(i, 2);
    end;
end;

function TFEditNMEA.GetTime;
var
  ts: string;
  fs: TFormatSettings;
begin
  {$IFDEF NMEA_2010}
  while Pos('$GPS', fStrings[ind]) = 0 do
  {$ELSE}
  while Pos('$GPGGA', fStrings[ind]) = 0 do
  {$ENDIF}
    Inc(ind);
  ts := GetStringItem(fStrings[ind], ',', 1);
  Result := 0;
  Result := RecodeDate(Result, 2007, 1, 1);
  Result := ZTimetoLocalTime(RecodeTime(Result, StrToInt(Copy(ts, 1, 2)), StrToInt(Copy(ts, 3, 2)), StrToInt(Copy(ts, 5, 2)), 0));
end;

function TFEditNMEA.SetTime;
var
  i: integer;
  secdif, tmp, tmp1: Int64;
  dtmp: TDateTime;
begin
  i := 1;
  secdif := maxint;
  Result := 0;
  while i < fStrings.Count do
    begin
      dtmp := GetTime(i);
      tmp := SecondsBetween(aTime, dtmp);
      tmp1 := SecondsBetween(dtmp, aTime);
      if tmp < secdif then
        begin
          secdif := tmp;
          Result := i;
        end;
      Inc(i, 2);
    end;
end;

procedure TFEditNMEA.Draw;
var
  i: integer;
begin
  with FShell do
    for i := 0 to MDIChildCount - 1 do
      if (MDIChildren[i] is TFGrid) and
         (TFGrid(MDIChildren[i]).ReconstruirTrayectoria1.Checked) then
        TFGrid(FShell.MDIChildren[i]).UpdateBuffBitmap;
end;

procedure TFEditNMEA.Reload;
begin
  if not FileExists(TheSettings.NMEA_ATTEX) then
    ShowMessage('NMEA ATETEX Rusia: No se encuentra el archivo res')
  else
    begin
      fStrings := TStringList.Create;
      fStrings.LoadFromFile(TheSettings.NMEA_ATTEX);
    end;
  ValidateNMEAStringList(fStrings);
  with TrackBar1 do
    begin
      Max := fStrings.Count - 1;
      Position := 0;
      SelStart := 0;
      SelEnd := Max - 2;
    end;
  with TrackBar2 do
    begin
      Max := fStrings.Count - 1;
      Position := Max - 2;
      SelStart := 2;
      SelEnd := Max;
    end;
end;

procedure TFEditNMEA.TrackBar1Change(Sender: TObject);
begin
  TrackBar1.SelEnd := TrackBar2.Position - 2;
  if TrackBar1.Position > Trackbar1.SelEnd
    then Trackbar1.Position := TrackBar1.SelEnd;
  TrackBar2.SelStart := TrackBar1.Position + 2;
  if TrackBar2.Position < TrackBar2.SelStart
    then TrackBar2.Position := TrackBar2.SelStart;
  DateTimePicker2.Time := GetTime(TrackBar1.Position);
  DateTimePicker4.Time := GetTime(TrackBar2.Position);
  Draw;
end;

procedure TFEditNMEA.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i: integer;
begin
  with FShell do
    for i := 0 to MDIChildCount - 1 do
      if (MDIChildren[i] is TFGrid) and
         (TFGrid(MDIChildren[i]).ReconstruirTrayectoria1.Checked) then
        begin
          TFGrid(FShell.MDIChildren[i]).ReconstruirTrayectoria1.Checked := false;
          TFGrid(FShell.MDIChildren[i]).UpdateBuffBitmap;
        end;
end;

procedure TFEditNMEA.Panel2Click(Sender: TObject);
begin
  with ColorDialog1 do
    begin
      Color := Panel2.Color;
      if Execute then
      Panel2.Color := Color;
    end;
  Draw;
end;

procedure TFEditNMEA.Panel1Click(Sender: TObject);
begin
  with ColorDialog1 do
    begin
      Color := Panel1.Color;
      if Execute then
      Panel1.Color := Color;
    end;
  Draw;
end;

procedure TFEditNMEA.Button1Click(Sender: TObject);
begin
  Reload;
  Draw;
end;

procedure TFEditNMEA.DateTimePicker2Change(Sender: TObject);
var
  tmp: TNotifyEvent;
begin
  tmp := TrackBar1.OnChange;
  TrackBar1.OnChange := nil;
  TrackBar1.Position := SetTime(DateTimePicker2.DateTime);
  TrackBar1.OnChange := tmp;
end;

procedure TFEditNMEA.DateTimePicker4Change(Sender: TObject);
var
  tmp: TNotifyEvent;
begin
  tmp := TrackBar2.OnChange;
  TrackBar2.OnChange := nil;
  TrackBar2.Position := SetTime(DateTimePicker4.DateTime);
  TrackBar2.OnChange := tmp;
end;

end.
