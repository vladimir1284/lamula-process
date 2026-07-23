unit CalAltForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TFCalAlt = class(TForm)
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
  FCalAlt: TFCalAlt;

implementation

{$R *.dfm}

uses
  CalcFunctions;

procedure TFCalAlt.Edit1Change(Sender: TObject);
var
  D, E: real;
begin
  D := Edit2Float(Edit1);
  E := Edit2Float(Edit2);
  Edit4.Text := FloatToStrF(CalcFunctions.Height(D, E), ffFixed, 18, 2);
end;

end.
