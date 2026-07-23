unit TranslatorPercentForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls;

type
  TFTranslatorPercent = class(TForm)
    ProgressBar1: TProgressBar;
  private
    { Private declarations }
  public
    procedure TranslatorProgress(Sender: TObject; percent: integer);
  end;

var
  FTranslatorPercent: TFTranslatorPercent;

implementation

{$R *.dfm}

procedure TFTranslatorPercent.TranslatorProgress(Sender: TObject; percent: integer);
begin
  if percent < 100 then
    begin
      ProgressBar1.Position := percent;
      Show;
    end
  else
    Hide;
end;

end.
