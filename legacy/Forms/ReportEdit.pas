unit ReportEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Area, ComCtrls, Grids, ExtCtrls, IniFiles,
  Measure;

type
  TFReportEdit = class(TForm)
    PageControl1: TPageControl;
    Button1: TButton;
    Button2: TButton;
    TabSheet2: TTabSheet;
    TabSheet1: TTabSheet;
    TreeView1: TTreeView;
    Edit1: TEdit;
    Label1: TLabel;
    UpDown1: TUpDown;
    TabSheet3: TTabSheet;
    GroupBox1: TGroupBox;
    CheckBox10: TCheckBox;
    CheckBox11: TCheckBox;
    CheckBox12: TCheckBox;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    CheckBox7: TCheckBox;
    CheckBox8: TCheckBox;
    CheckBox9: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure UpDown1Click(Sender: TObject; Button: TUDBtnType);
    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    fIniFile: TIniFile;
    fMeasure : TMeasure;
    function  GetThreshold : TCode;
    procedure SetMeasure  ( M : TMeasure );
    procedure SetThreshold( V : TCode );
    procedure SaveData;
    procedure LoadData;
  public
    property Measure   : TMeasure read fMeasure     write SetMeasure;
    property Threshold : TCode    read GetThreshold write SetThreshold;
  end;

var
  FReportEdit: TFReportEdit = nil;

implementation

uses
  TreeImages;

{$R *.DFM}

// Private procedures & functions

procedure CheckState( Node : TTreeNode );
var
  N : TTreeNode;
begin
  if Node <> nil
    then
      with Node do
        begin
          if Node.StateIndex <> tiAll
            then
              begin
                N := GetFirstChild;
                while N <> nil do
                  begin
                    if N.StateIndex <> tiNone
                      then break;
                    N := GetNextChild(N);
                  end;
                if N = nil
                  then StateIndex := tiNone
                  else StateIndex := tiPartial;
              end;
          CheckState(Parent);
        end;
end;

// TFReportEdit methods

function TFReportEdit.GetThreshold : TCode;
begin
  Result := Updown1.Position;
end;

procedure TFReportEdit.SetMeasure( M : TMeasure );
begin
  CheckBox3.Caption := CheckBox3.Caption + '(' + MeasureName(M) + ')';
  CheckBox4.Caption := CheckBox4.Caption + '(' + MeasureName(M) + ')';
  CheckBox5.Caption := CheckBox5.Caption + '(' + MeasureName(M) + ')';
  CheckBox6.Caption := CheckBox6.Caption + '(' + MeasureName(M) + ')';
  CheckBox7.Caption := CheckBox7.Caption + '(' + MeasureName(M) + ')';
  CheckBox8.Visible := M = unMM;
  CheckBox9.Caption := CheckBox9.Caption + '(' + MeasureName(M) + ')';
  fMeasure := M;
end;

procedure TFReportEdit.SetThreshold( V : TCode );
begin
  Edit1.Text := FloatToStr(CodeMeasure(V, Measure)) + ' ' + MeasureName(Measure);
  Updown1.Position := V;
end;

procedure TFReportEdit.SaveData;
begin
  with fIniFile do
    begin
      WriteBool('Reporte', '1', CheckBox1.Checked);
      WriteBool('Reporte', '2', CheckBox2.Checked);
      WriteBool('Reporte', '3', CheckBox3.Checked);
      WriteBool('Reporte', '4', CheckBox4.Checked);
      WriteBool('Reporte', '5', CheckBox5.Checked);
      WriteBool('Reporte', '6', CheckBox6.Checked);
      WriteBool('Reporte', '7', CheckBox7.Checked);
      WriteBool('Reporte', '8', CheckBox8.Checked);
      WriteBool('Reporte', '9', CheckBox9.Checked);
    end;
end;

procedure TFReportEdit.LoadData;
begin
  with fIniFile do
    begin
      CheckBox1.Checked := ReadBool('Reporte', '1', false);
      CheckBox2.Checked := ReadBool('Reporte', '2', true);
      CheckBox3.Checked := ReadBool('Reporte', '3', true);
      CheckBox4.Checked := ReadBool('Reporte', '4', false);
      CheckBox5.Checked := ReadBool('Reporte', '5', false);
      CheckBox6.Checked := ReadBool('Reporte', '6', true);
      CheckBox7.Checked := ReadBool('Reporte', '7', false);
      CheckBox8.Checked := ReadBool('Reporte', '8', false);
      CheckBox9.Checked := ReadBool('Reporte', '9', true);
    end;
end;

// Component methods

procedure TFReportEdit.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet2;
  fIniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'Report.ini');
end;

procedure TFReportEdit.TreeView1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  with Sender as TTreeView do
    if htOnStateIcon in GetHitTestInfoAt(X, Y)
      then
        begin
          if Selected.StateIndex = tiAll
            then Selected.StateIndex := tiNone
            else Selected.StateIndex := tiAll;
          CheckState(Selected);
        end;
end;

procedure TFReportEdit.UpDown1Click(Sender: TObject; Button: TUDBtnType);
begin
  Threshold := (Sender as TUpdown).Position;
end;

procedure TFReportEdit.FormResize(Sender: TObject);
begin
  Button2.Left := ClientWidth - Button2.Width - 5;
  Button1.Left := Button2.Left - Button1.Width - 5;
  Button1.Top  := ClientHeight - Button1.Height - 5;
  Button2.Top  := Button1.Top;
  PageControl1.Width  := ClientWidth - 10;
  PageControl1.Height := Button1.Top - PageControl1.Top - 5;
  // Areas
  with TabSheet2 do
    if Showing
      then
        begin
          TreeView1.Width  := Width - 20;
          TreeView1.Height := Height - 20;
        end;
end;

procedure TFReportEdit.FormDestroy(Sender: TObject);
begin
  fIniFile.Free;
end;

procedure TFReportEdit.FormShow(Sender: TObject);
begin
  LoadData;
end;

procedure TFReportEdit.Button1Click(Sender: TObject);
begin
  SaveData;
end;

end.
