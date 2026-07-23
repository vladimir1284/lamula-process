unit TXTReportForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, StdCtrls;

type
  TFTXTReport = class(TForm)
    Memo1: TMemo;
    MainMenu1: TMainMenu;
    SaveDialog1: TSaveDialog;
    Reporte1: TMenuItem;
    Salvar1: TMenuItem;
    Copiar1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Salvar1Click(Sender: TObject);
    procedure Copiar1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FTXTReport: TFTXTReport;

implementation

{$R *.DFM}

  uses
    Clipbrd,
    Settings;

procedure TFTXTReport.FormCreate(Sender: TObject);
begin
  SaveDialog1.InitialDir := theSettings.Reports;
end;

procedure TFTXTReport.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (Memo1.Modified) and
     (Application.MessageBox( '¿Desea salvar el reporte?',
                              'Reporte',
                              MB_ICONQUESTION or MB_YESNO ) = ID_YES)
     then Salvar1Click( Salvar1 );
  Action := caFree;
end;

procedure TFTXTReport.Salvar1Click(Sender: TObject);
begin
  with SaveDialog1 do
    if Execute
      then Memo1.Lines.SaveToFile( FileName );
end;

procedure TFTXTReport.Copiar1Click(Sender: TObject);
begin
  Clipboard.SetTextBuf( pchar(Memo1.Text) );
end;

end.
