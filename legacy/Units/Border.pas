unit Border;

interface

uses
  Plane, Description, Classes;

const
  cBorderWord = 'MPB';

type
  TBorderReference = class
  public
    constructor Load( const aFileName : string );  virtual;
  protected
    procedure ReadData( var F : TextFile );  virtual;
  private
    fCenter     : T2DLocation;
    fRange      : integer;
    fLength     : TPlanePoint;
    fDefault    : boolean;
    fName       : string;
    fFileName   : string;
    fReferences : integer;
    fColor      : longint;
  public
    property Center     : T2DLocation read fCenter;
    property Range      : integer     read fRange;
    property Length     : TPlanePoint read fLength;
    property Default    : boolean     read fDefault;
    property Name       : string      read fName;
    property FileName   : string      read fFileName;
    property References : integer     read fReferences write fReferences;
    property Color      : longint     read fColor      write fColor;
  end;

type
  TBorderLine = array of TPlanePoint;
  TLineArray  = array of TBorderLine;
  TCountArray = array of integer;
  TLineNameArray   = array of string[30];

type
  TBorder = class(TBorderReference)
  protected
    procedure ReadData( var F : TextFile );  override;
  protected
    property References;
  private
    fCount  : integer;
    fLines  : TLineArray;
    fCounts : TCountArray;
    fLineNames : TLineNameArray;
    function GetLines ( I : integer ) : TBorderLine;
    function GetCounts( I : integer ) : integer;
    function GetLineName( I : integer ): string;
  public
    property Count : integer read fCount;
    property Lines [I : integer] : TBorderLine read GetLines;  default;
    property Counts[I : integer] : integer     read GetCounts;
    property LineName[I : integer] : string    read GetLineName;
  end;

implementation

uses
  Windows;

// TBorderReference methods

constructor TBorderReference.Load( const aFileName : string );
var
  F : TextFile;
begin
  fFileName := aFileName;
  AssignFile(F, aFileName);
  Reset(F);
  try
    ReadData(F);
  finally
    Close(F);
  end;
end;

procedure TBorderReference.ReadData( var F : TextFile );
var
  R, G, B: byte;
begin
  readln(F, fName);
  readln(F, fCenter.Longitude, fCenter.Latitude);
  readln(F, byte(fDefault));
  with fLength do
    readln(F, X, Y);
  readln(F, fRange);
  readln(F, R, G, B);
  fColor := RGB(R, G, B);
end;

// TBorder methods

function TBorder.GetLineName( I : integer): string;
begin
  Result := fLineNames[I];
end;

procedure TBorder.ReadData( var F : TextFile );
var
  I, J : integer;
  S    : string;
begin
  inherited ReadData(F);
  readln(F, fCount);
  SetLength(fCounts, fCount);
  SetLength(fLines,  fCount);
  SetLength(fLineNames, fCount);
  for I := 0 to fCount - 1 do
    begin
      readln(F, S);
      fLineNames[I] := S;
      readln(F, fCounts[I]);
      SetLength(fLines[I], fCounts[I]);
      for J := 0 to fCounts[I] - 1 do
        with fLines[I][J] do
          readln(F, X, Y);
    end;
end;

function TBorder.GetLines( I : integer ) : TBorderLine;
begin
  Result := fLines[I];
end;

function TBorder.GetCounts( I : integer ) : integer;
begin
  Result := fCounts[I];
end;

end.

