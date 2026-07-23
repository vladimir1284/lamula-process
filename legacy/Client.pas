unit Client;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    S, T, A, O, P, V : variant;
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

uses
  Variants,
  ComObj;

procedure TForm1.Button1Click(Sender: TObject);
begin
  S := CreateOleObject('Vesta.Process');
  S.Maximize;
  Application.BringToFront;
  T := S.Open('D:\CP2\Vesta\DZ.tms');
  P := T.GetAnimation('PPI');
  P.East  :=  10;
  P.West  := -100;
  P.North :=  100;
  P.South := -100;
  A := P.Animate;
  while not A.Rendered do Application.ProcessMessages;
  V := P.View;
  V.Zoom := 200;
  A.Save('C:\tmp\test.gif');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if not VarIsEmpty(P)
    then P.Close;
  if not VarIsEmpty(O)
    then O.Close;
  if not VarIsEmpty(T)
    then T.Close;
  if not VarIsEmpty(S)
    then S.Close;
end;

end.

