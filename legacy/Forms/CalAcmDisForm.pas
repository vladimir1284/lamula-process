unit CalAcmDisForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TFCalAcmDis = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    ComboBox1: TComboBox;
    GroupBox3: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    Edit4: TEdit;
    Label1: TLabel;
    Label6: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Label7: TLabel;
    GroupBox4: TGroupBox;
    Label8: TLabel;
    Label9: TLabel;
    Edit6: TEdit;
    Edit7: TEdit;
    Label2: TLabel;
    Edit5: TEdit;
    Label3: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FCalAcmDis: TFCalAcmDis;

implementation

{$R *.dfm}

uses
  Radars, Description, CalcFunctions;

procedure TFCalAcmDis.FormCreate(Sender: TObject);
var
  i: TRadar;
begin
  with ComboBox1 do
    begin
      Items.Clear;
      for i:= rdLaBajada to rdGranPiedra do
        Items.Add(Find(i).Name);
      ItemIndex := 4;
    end;
  ComboBox1Change(Sender);
end;

procedure TFCalAcmDis.ComboBox1Change(Sender: TObject);
begin
  Edit1.OnChange := nil;
  Edit2.OnChange := nil;
  Edit6.OnChange := nil;
  Edit7.OnChange := nil;
  with Find(TRadar(ComboBox1.ItemIndex + 1)).Location do
    begin
      Edit1.Text := FloatToStrF(Latitude , ffFixed, 18, 2);
      Edit2.Text := FloatToStrF(Longitude, ffFixed, 18, 2);
    end;
  Edit1.OnChange := Edit1Change;
  Edit2.OnChange := Edit1Change;
  Edit6.OnChange := Edit1Change;
  Edit7.OnChange := Edit1Change;
  Edit1Change(Sender);
end;

procedure TFCalAcmDis.Edit1Change(Sender: TObject);
var
  Lt1, Lt2, Ln1, Ln2, Range: real;
begin
  Lt1 := Edit2Float(Edit1) * pi/180;
  Ln1 := Edit2Float(Edit2) * pi/180;
  Lt2 := Edit2Float(Edit6) * pi/180;
  Ln2 := Edit2Float(Edit7) * pi/180;
  Range := CalcFunctions.Range(Lt1, Ln1, Lt2, Ln2);
  Edit5.Text := FloatToStrF(Range, ffFixed, 18, 2);
  Edit4.Text := FloatToStrF(Azimut(Lt1, Ln1, Lt2, Ln2, Range), ffFixed, 18, 2);
end;

end.
