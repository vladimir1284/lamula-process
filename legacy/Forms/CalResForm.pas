unit CalResForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TFCalRes = class(TForm)
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label1: TLabel;
    Edit2: TEdit;
    Edit1: TEdit;
    GroupBox3: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    Edit4: TEdit;
    procedure Edit1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FCalRes: TFCalRes;

implementation

{$R *.dfm}

uses
  CalcFunctions;

procedure TFCalRes.Edit1Change(Sender: TObject);
var
  W, D: real;
begin
  D := Edit2Float(Edit1);
  W := Edit2Float(Edit2);
  Edit4.Text := FloatToStrF(TanRes(D, W), ffFixed, 18, 3);
end;

end.
