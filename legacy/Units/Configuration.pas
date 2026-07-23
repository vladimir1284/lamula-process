unit Configuration;

interface

uses
  Classes, Registry, IniFiles;

type
  TConfiguration = class
  public
    constructor Create;
    destructor  Destroy;  override;
  private
    fConfiguration : TRegIniFile;
    function  GetPath ( Index : integer ) : string;
    procedure SetPath ( Index : integer;  Value : string );
    function  GetStr  ( Index : integer ) : string;
    procedure SetStr  ( Index : integer;  Value : string );
    function  GetFloat( Index : integer ) : double;
    procedure SetFloat( Index : integer;  Value : double );
    function  GetInt  ( Index : integer ) : integer;
    procedure SetInt  ( Index : integer;  Value : integer );
  public  // Configuration Paths
    property BorderTables   : string  index  0 read GetPath  write SetPath;
    property RegionTables   : string  index  1 read GetPath  write SetPath;
    property TopographyMaps : string  index  2 read GetPath  write SetPath;
    property Cache0         : string  index  3 read GetPath  write SetPath;
    property Cache1         : string  index  4 read GetPath  write SetPath;
    property Cache2         : string  index  5 read GetPath  write SetPath;
    property Cache3         : string  index  6 read GetPath  write SetPath;
    property Cache4         : string  index  7 read GetPath  write SetPath;
    property Cache5         : string  index  8 read GetPath  write SetPath;
    property Cache6         : string  index  9 read GetPath  write SetPath;
    property Cache7         : string  index 10 read GetPath  write SetPath;
    property Cache8         : string  index 11 read GetPath  write SetPath;
    property Cache9         : string  index 12 read GetPath  write SetPath;
  public  // Configuration Strings
    property Raw_Angles     : string  index  0 read GetStr   write SetStr;
  public  // Configuration Values
    property RainA          : double  index  0 read GetFloat write SetFloat;
    property RainB          : double  index  1 read GetFloat write SetFloat;
    property Kdp_A          : double  index  2 read GetFloat write SetFloat;
    property Kdp_B          : double  index  3 read GetFloat write SetFloat;
    property Raw_Slope      : double  index  4 read GetFloat write SetFloat;
    property Raw_Offset     : double  index  5 read GetFloat write SetFloat;
    property Raw_Beam       : double  index  6 read GetFloat write SetFloat;
    property Raw_PotMet     : double  index  7 read GetFloat write SetFloat;
  public  // Configuration Values, integer & ordinal
    property Raw_PPIs       : integer index  0 read GetInt   write SetInt;
    property Raw_Cells      : integer index  1 read GetInt   write SetInt;
    property Raw_Sectors    : integer index  2 read GetInt   write SetInt;
    property Raw_Size       : integer index  3 read GetInt   write SetInt;
    property Raw_Variable   : integer index  4 read GetInt   write SetInt;
    property Raw_Radar      : integer index  5 read GetInt   write SetInt;
    property Raw_Wavelength : integer index  6 read GetInt   write SetInt;
    property RadialSpeckler : integer index  7 read GetInt   write SetInt;
  end;

var
  theConfiguration : TConfiguration;
  theRunningDir    : string;

implementation

uses
  Windows,
  SysUtils,
  Measure, Description, Forms;

const
  RegistryPath = {HKEY_LOCALMACHINE\} 'Software\LDT\Vesta\Process';

const
  PathKey : array[0..12] of string = ('Borders', 'Regions',
                                      'Maps',
                                      'Cache0',
                                      'Cache1',
                                      'Cache2',
                                      'Cache3',
                                      'Cache4',
                                      'Cache5',
                                      'Cache6',
                                      'Cache7',
                                      'Cache8',
                                      'Cache9');

  PathDef : array[0..12] of string = ('Borders', 'Regions', 'Maps',
                                      '', '', '', '', '', '', '', '', '', '');

  StrKey : array[0..0] of string = ('Raw_Angles');

  StrDef : array[0..0] of string = ('0.5, 0.6, 0.7, 0.9, 1.1, 1.4, 1.8, 2.2, 2.7, 3.4, 4.1, 4.9, 5.9, 7.1, 8.6, 10.3, 12.3, 14.6, 17.2, 20.3, 24, 28, 32, 34');

  FloatKey : array[0..7] of string = ('Rain_A', 'Rain_B', 'Rain_Kdp_A', 'Rain_Kdp_B',
                                      'Raw_Slope', 'Raw_Offset',
                                      'Raw_Beam', 'Raw_PotMet');

  FloatDef : array[0..7] of string = ('300.0',  '1.4', '40.7', '0.866',
                                      '1.0', '0.0',
                                      '0.86', '0.0');

  IntKey : array[0..7] of string = ('Raw_PPIs', 'Raw_Cells', 'Raw_Sectors', 'Raw_Size',
                                    'Raw_Variable', 'Raw_Radar', 'Raw_Wavelength', 'Radial_Speckle');

  IntDef : array[0..7] of integer = (24, 180, 360, 1000,
                                     ord(unDBZ), ord(rdMcGill), ord(wl10cm), 1500);

// TConfiguration methods

constructor TConfiguration.Create;
begin
  inherited;
  fConfiguration := TRegIniFile.Create('');
  fConfiguration.RootKey := HKEY_LOCAL_MACHINE;
  fConfiguration.OpenKey(RegistryPath, true);
end;

destructor TConfiguration.Destroy;
begin
  FreeAndNil(fConfiguration);
  inherited;
end;

function TConfiguration.GetPath( Index : integer ) : string;
begin
  Result := fConfiguration.ReadString('Paths', PathKey[Index], theRunningDir + PathDef[Index]);
end;

procedure TConfiguration.SetPath( Index : integer; Value : string );
begin
  fConfiguration.WriteString('Paths', PathKey[Index], Value);
end;

function TConfiguration.GetFloat( Index : integer ) : double;
begin
  Result := StrToFloat(fConfiguration.ReadString('Values', FloatKey[Index], FloatDef[Index]));
end;

procedure TConfiguration.SetFloat( Index : integer; Value : double );
begin
  fConfiguration.WriteString('Values', FloatKey[Index], FloatToStr(Value));
end;

function  TConfiguration.GetStr( Index : integer ) : string;
begin
  Result := fConfiguration.ReadString('Values', StrKey[Index], StrDef[Index]);
end;

procedure TConfiguration.SetStr( Index : integer;  Value : string );
begin
  fConfiguration.WriteString('Values', StrKey[Index], Value);
end;

function  TConfiguration.GetInt( Index : integer ) : integer;
begin
  Result := fConfiguration.ReadInteger('Values', IntKey[Index], IntDef[Index]);
end;

procedure TConfiguration.SetInt( Index : integer; Value : integer );
begin
  fConfiguration.WriteInteger('Values', IntKey[Index], Value);
end;

// Intialization & finalization code

initialization
  theConfiguration := TConfiguration.Create;
  theRunningDir    := IncludeTrailingPathDelimiter(ExtractFileDir(paramstr(0)));
finalization
  theConfiguration.Free;
end.
