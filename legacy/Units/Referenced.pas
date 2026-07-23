unit Referenced;

interface

type
  TReferenced = class
  public
    constructor Create;
    destructor  Destroy;  override;
    procedure   AddRef;
    procedure   Release;
  private
    fReferences : integer;
  public
    property References : integer read fReferences;
  end;

implementation

uses
  SysUtils;

// TReferenced method

constructor TReferenced.Create;
begin
  inherited;
  fReferences := 1;
end;

destructor TReferenced.Destroy;
begin
  if (ExceptAddr = nil) and (fReferences > 0)
    then raise Exception.Create( 'Liberando una instancia con referencias' );
  inherited;
end;

procedure TReferenced.AddRef;
begin
  inc(fReferences);
end;

procedure TReferenced.Release;
begin
  dec(fReferences);
  if fReferences = 0
    then Free;
end;

end.


