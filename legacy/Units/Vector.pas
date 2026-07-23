unit Vector;

interface

uses
  Classes,
  Plane;

type
  TVector = class(TPersistent)
  public
    constructor Initialize( anOrigin, anEnding : integer );
    destructor  Destroy;  override;
  public
    procedure Assign( Source : TPersistent );  override;
  private
    fSize   : integer;
    fCells  : PCellArray;
    fOrigin : integer;
    fEnding : integer;
    function  GetCell  ( I : TCoord ) : TCell;
    procedure SetCell  ( I : TCoord; Value : TCell );
    procedure SetSize  ( S : integer );
    procedure SetOrigin( O : integer );
    procedure SetEnding( E : integer );
  public
    property Cell[I : TCoord] : TCell      read GetCell write SetCell;  default;
    property Cells            : PCellArray read fCells;
    property Size             : integer    read fSize;
    property Origin           : integer    read fOrigin write SetOrigin;
    property Ending           : integer    read fEnding write SetEnding;
  public
    procedure ReadState ( Reader : TReader );  virtual;
    procedure WriteState( Writer : TWriter );  virtual;
    procedure Clear;
  end;

implementation

// TVector methods

constructor TVector.Initialize( anOrigin, anEnding : integer );
begin
  inherited Create;
  fOrigin := anOrigin;
  fEnding := anEnding;
  SetSize(succ(anEnding - anOrigin));
end;

destructor TVector.Destroy;
begin
  inherited;
  ReallocMem(fCells, 0);
end;

procedure TVector.Assign( Source : TPersistent );
begin
  if Source is TVector
    then
      begin
        SetSize(TVector(Source).Size);
        move(TVector(Source).Cells, fCells^, Size * sizeof(TCell));
      end
    else inherited;
end;

function TVector.GetCell( I : TCoord ) : TCell;
begin
  Result := fCells[I];
end;

procedure TVector.SetCell( I : TCoord; Value : TCell );
begin
  fCells[I] := Value;
end;

procedure TVector.SetSize( S : integer );
begin
  ReallocMem(fCells, S * sizeof(TCell));
  fSize   := S;
  fEnding := pred(fOrigin + S);
end;

procedure TVector.SetOrigin( O : integer );
begin
  fOrigin := O;
  SetSize(succ(fEnding - O));
end;

procedure TVector.SetEnding( E : integer );
begin
  fEnding := E;
  SetSize(succ(E - fOrigin));
end;

procedure TVector.ReadState( Reader : TReader );
begin
  SetSize(Reader.ReadInteger);
  if assigned(fCells)
    then Reader.Read(fCells^, Size * sizeof(TCell));
end;

procedure TVector.WriteState( Writer : TWriter );
begin
  Writer.WriteInteger(Size);
  if assigned(fCells)
    then Writer.Write(fCells^, Size * sizeof(TCell));
end;

procedure TVector.Clear;
begin
  if assigned(fCells)
    then FillChar(fCells^, Size * sizeof(TCell), 0);
end;

end.
