unit FormAuto;

interface

{$WARN UNIT_DEPRECATED OFF}

uses
  OleAuto,
  Forms;

type
  TFormAuto = class(TAutoObject)
  automated
    procedure Close;
  automated
    function  GetState : integer;
    procedure SetState( S : integer );
  automated
    property State : integer read GetState write SetState;
  protected
    class function FormClass : TFormClass;  virtual;  abstract;
  private
    fForm : TForm;
    procedure SetForm( F : TForm );
  public
    property Form : TForm read fForm write SetForm;
  end;

implementation

uses
  SysUtils;

// TFormAuto methods

procedure TFormAuto.Close;
begin
  Form.Close;
end;

function TFormAuto.GetState : integer;
begin
  Result := integer(Form.WindowState);
end;

procedure TFormAuto.SetState( S : integer );
begin
  Form.WindowState := TWindowState(S);
end;

procedure TFormAuto.SetForm( F : TForm );
begin
  if F is FormClass
    then fForm := F
    else raise Exception.Create( 'La forma assignada es de una clase invalida' );
end;

end.
