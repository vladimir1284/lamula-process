unit RTFReportForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, StdCtrls, ComCtrls;

type
  TFRTFReport = class(TForm)
    RichEdit1: TRichEdit;
    MainMenu1: TMainMenu;
    Reporte1: TMenuItem;
    Salvar1: TMenuItem;
    SaveDialog1: TSaveDialog;
    procedure Salvar1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Copiar1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FRTFReport: TFRTFReport;

implementation

{$R *.DFM}

  uses
    Clipbrd,
    Settings;

procedure TFRTFReport.FormCreate(Sender: TObject);
begin
  SaveDialog1.InitialDir := theSettings.Reports;
end;

procedure TFRTFReport.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (RichEdit1.Modified) and
     (Application.MessageBox( '¿Desea salvar el reporte?',
                              'Reporte',
                              MB_ICONQUESTION or MB_YESNO ) = ID_YES)
     then Salvar1Click( Salvar1 );
  Action := caFree;
end;

procedure TFRTFReport.Salvar1Click(Sender: TObject);
begin
  with SaveDialog1 do
    if Execute
      then RichEdit1.Lines.SaveToFile( FileName );
end;

procedure TFRTFReport.Copiar1Click(Sender: TObject);
begin
  Clipboard.SetTextBuf( pchar(RichEdit1.Text) );
end;

end.
