unit CalPreForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TFCalPre = class(TForm)
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Edit2: TEdit;
    Edit3: TEdit;
    GroupBox3: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    Edit4: TEdit;
    Label1: TLabel;
    Edit1: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FCalPre: TFCalPre;

implementation

{$R *.dfm}

uses
  Configuration, CalcFunctions;

procedure TFCalPre.FormCreate(Sender: TObject);
begin
  with theConfiguration do
    begin
      Edit2.Text := FloatToStrF(RainA, ffFixed, 18, 2);
      Edit3.Text := FloatToStrF(RainB, ffFixed, 18, 2);
    end;
end;

procedure TFCalPre.Edit1Change(Sender: TObject);
var
  A, B, Z: single;
begin
  Z := Edit2Float(Edit1);
  A := Edit2Float(Edit2);
  B := Edit2Float(Edit3);
  Edit4.Text := FloatToStrF(Rain(A, B, Z), ffFixed, 18, 2);
end;

end.
