unit SowForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, Buttons, StdCtrls, ExtCtrls;

type
  TFSow = class(TForm)
    GroupBox1: TGroupBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ColorBox1: TColorBox;
    Button1: TButton;
    GroupBox2: TGroupBox;
    Edit4: TEdit;
    Label5: TLabel;
    SpeedButton1: TSpeedButton;
    ListView1: TListView;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FSow: TFSow;

implementation

{$R *.dfm}

procedure TFSow.Button1Click(Sender: TObject);
var
  temp: TlistItem;
  n: single;
begin
  try
    n := StrToFloat(Edit1.Text);
    n := StrToFloat(Edit2.Text);
    n := StrToFloat(Edit3.Text);
  except
    on E: Exception do
      begin
        ShowMessage('Error en entrada de datos !!!');
        exit;
      end;
  end;
  with ListView1 do
    begin
      temp := Items.Add;
      temp.Caption := DateTimeToStr(Now);
      temp.Checked := true;
      with temp.SubItems do
        begin
          Add(Edit1.Text);
          Add(Edit2.Text);
          Add(Edit3.Text);
          Add(ColorBox1.ColorNames[ColorBox1.ItemIndex]);
        end;
    end;
end;

end.
