unit TranslatorMod;

interface

uses
  SysUtils, Classes, xmldom, XMLIntf, msxmldom, XMLDoc;

type
  TDataModule1 = class(TDataModule)
    fHeader: TXMLDocument;
    fBlob: TXMLDocument;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModule1: TDataModule1;

implementation

{$R *.dfm}

end.
