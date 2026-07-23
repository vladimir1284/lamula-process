unit Settings;

interface

uses
  Classes, Registry,
  Measure;

type
  TSettings = class
  public
    constructor Create;
    destructor  Destroy;  override;
  private
    fSetting: TRegIniFile;
    fFolder: string;
    function  GetPath   (Index: integer): string;
    function  GetPalette(aMsr: TMeasure): string;
    function  GetInteger(Index: integer): integer;
    procedure SetPath   (Index: integer;  Value: string );
    procedure SetPalette(aMsr : TMeasure; Value: string );
    procedure SetInteger(Index: integer;  Value: integer);
    function  GetFloat  (Index: integer): double;
    procedure SetFloat  (Index: integer;  Value: double);
    function  GetBoolean(Index: integer): boolean;
    procedure SetBoolean(Index: integer;  Value: boolean);
  public
    property Folder: string write fFolder;
  public // Setting Paths
    property TimeSpans   : string index 0 read GetPath write SetPath;
    property Observations: string index 1 read GetPath write SetPath;
    property Products    : string index 2 read GetPath write SetPath;
    property Images      : string index 3 read GetPath write SetPath;
    property Animations  : string index 4 read GetPath write SetPath;
    property Reports     : string index 5 read GetPath write SetPath;
    property Ensembles   : string index 6 read GetPath write SetPath;
    property Tools       : string index 7 read GetPath write SetPath;
    property NMEA_ATTEX  : string index 8 read GetPath write SetPath;
  public  // Palettes
    property PaletteTable[Msr: TMeasure]: string read GetPalette write SetPalette;
  public  // Values
    property DefaultCellH     : integer index  0 read GetInteger write SetInteger;
    property DefaultCellV     : integer index  1 read GetInteger write SetInteger;
    property DefaultHorzBot   : integer index  2 read GetInteger write SetInteger;
    property DefaultHorzTop   : integer index  3 read GetInteger write SetInteger;
    property DefaultCAPPIBot  : integer index  4 read GetInteger write SetInteger;
    property DefaultCAPPITop  : integer index  5 read GetInteger write SetInteger;
    property DefaultTopsMin   : integer index  6 read GetInteger write SetInteger;
    property DefaultTopsLoc   : integer index  7 read GetInteger write SetInteger;
    property DefaultVertBot   : integer index  8 read GetInteger write SetInteger;
    property DefaultVertTop   : integer index  9 read GetInteger write SetInteger;
    property DefaultHorzWest  : integer index 10 read GetInteger write SetInteger;
    property DefaultHorzNorth : integer index 11 read GetInteger write SetInteger;
    property DefaultHorzEast  : integer index 12 read GetInteger write SetInteger;
    property DefaultHorzSouth : integer index 13 read GetInteger write SetInteger;
    property DefaultAnmDelay  : integer index 14 read GetInteger write SetInteger;
    property DefaultMaxRange  : integer index 15 read GetInteger write SetInteger;
    property DefaultMeasure   : integer index 16 read GetInteger write SetInteger;
    property DefaultChannel   : integer index 17 read GetInteger write SetInteger;
    property DefaultWindHeight: integer index 18 read GetInteger write SetInteger;
    property NMEA_ATTEX_Format: integer index 19 read GetInteger write SetInteger;
    property RadioHelp        : integer index 20 read GetInteger write SetInteger;
  public  // Float values
    property DefaultVILC1     : float   index  0 read GetFloat   write SetFloat;
    property DefaultVILC2     : float   index  1 read GetFloat   write SetFloat;
  public  // Boolean values
    property ShowExploracion  : boolean index  0 read GetBoolean write SetBoolean;
    property ShowTopografia   : boolean index  1 read GetBoolean write SetBoolean;
    property ShowEscala       : boolean index  2 read GetBoolean write SetBoolean;
    property ShowRadar        : boolean index  3 read GetBoolean write SetBoolean;
    property ShowCuadriculas  : boolean index  4 read GetBoolean write SetBoolean;
    property ShowClimatologia : boolean index  5 read GetBoolean write SetBoolean;
    property ShowRadios       : boolean index  6 read GetBoolean write SetBoolean;
    property ShowGuiaDeCorte  : boolean index  7 read GetBoolean write SetBoolean;
    property ShowImgCaptions  : boolean index  8 read GetBoolean write SetBoolean;
    property ShowImgCopyrights: boolean index  9 read GetBoolean write SetBoolean;
    property ShowImgScale     : boolean index 10 read GetBoolean write SetBoolean;
    property DefaultC_SStatusHorzProduct  : boolean index 11 read GetBoolean write SetBoolean; /////mio******
    property DefaultC_SStatusCAPPI        : boolean index 12 read GetBoolean write SetBoolean; /////mio******
    property DefaultC_SStatusVil          : boolean index 13 read GetBoolean write SetBoolean; /////mio******
    property DefaultC_SStatusVolume       : boolean index 14 read GetBoolean write SetBoolean; /////mio******
    property DefaultC_SStatusContribution : boolean index 15 read GetBoolean write SetBoolean; /////mio******
    property DefaultC_SStatusVertProduct  : boolean index 16 read GetBoolean write SetBoolean; /////mio******
    property DefaultC_SStatusTops         : boolean index 17 read GetBoolean write SetBoolean; /////mio******
    property ShowImgSuavizar : boolean index 18 read GetBoolean write SetBoolean;
    property ShowVerticalGrid: boolean index 19 read GetBoolean write SetBoolean;
    property IncludeZero: boolean index 20 read GetBoolean write SetBoolean;
    property ActiveAutoPilot: boolean index 21 read GetBoolean write SetBoolean;
  end;

type
  TAeronautic_Angle = record
    case byte of
      0: (Deg, Min, Sec: single);
      1: (Val: single);
  end;

  TLocation = record
    Name: string;
    case byte of
     0: (Lat, Lon: TAeronautic_Angle);
     1: (X, Y: integer);
  end;

  TRadioHelpArray = record
    Count: integer;
    Data: array[0..27] of TLocation;
  end;

const
  settings_RH: TRadioHelpArray = (
    Count: 28;
    Data: (
    (Name: 'NDB Baracoa';                Lat: (Deg: 20; Min: 22; Sec: 10.14); Lon: (Deg: 74; Min: 31; Sec: 22.26)),
    (Name: 'NDB Bayamo' ;                Lat: (Deg: 20; Min: 23; Sec: 38.02); Lon: (Deg: 76; Min: 37; Sec: 09.04)),
    (Name: 'VOR/DME Camaguey';           Lat: (Deg: 21; Min: 26; Sec: 14.77); Lon: (Deg: 77; Min: 48; Sec: 03.01)),
    (Name: 'NDB Camaguey';               Lat: (Deg: 21; Min: 23; Sec: 25.28); Lon: (Deg: 77; Min: 55; Sec: 44.66)),
    (Name: 'NDB Cayabo';                 Lat: (Deg: 22; Min: 51; Sec: 29);    Lon: (Deg: 82; Min: 51; Sec: 10)),
    (Name: 'VOR/DME Cayo Largo del Sur'; Lat: (Deg: 21; Min: 36; Sec: 18.07); Lon: (Deg: 81; Min: 31; Sec: 57.71)),
    (Name: 'NDB Cayo Largo del Sur';     Lat: (Deg: 21; Min: 36; Sec: 15.02); Lon: (Deg: 81; Min: 31; Sec: 44.58)),
    (Name: 'VOR/DME Ciego de Avila';     Lat: (Deg: 22; Min: 00; Sec: 54.23); Lon: (Deg: 78; Min: 48; Sec: 56.94)),
    (Name: 'NDB Ciego de Avila';         Lat: (Deg: 21; Min: 59; Sec: 22.01); Lon: (Deg: 78; Min: 52; Sec: 18.88)),
    (Name: 'VOR/DME Cienfuegos';         Lat: (Deg: 22; Min: 09; Sec: 16.84); Lon: (Deg: 80; Min: 24; Sec: 21.81)),
    (Name: 'NDB Cienfuegos';             Lat: (Deg: 22; Min: 06; Sec: 50);    Lon: (Deg: 80; Min: 25; Sec: 31.21)),
    (Name: 'NDB Gerona';                 Lat: (Deg: 21; Min: 45; Sec: 21.21); Lon: (Deg: 82; Min: 52; Sec: 41.37)),
    (Name: 'NDB Guantanamo';             Lat: (Deg: 20; Min: 04; Sec: 44.23); Lon: (Deg: 75; Min: 09; Sec: 29.87)),
    (Name: 'VOR/DME Habana';             Lat: (Deg: 22; Min: 58; Sec: 43.82); Lon: (Deg: 82; Min: 25; Sec: 35.93)),
    (Name: 'VOR/DME Holguin';            Lat: (Deg: 20; Min: 47; Sec: 53.18); Lon: (Deg: 76; Min: 18; Sec: 10.79)),
    (Name: 'NDB Holguin';                Lat: (Deg: 20; Min: 43; Sec: 49.85); Lon: (Deg: 76; Min: 22; Sec: 35.03)),
    (Name: 'VOR/DME Jardines del Rey';   Lat: (Deg: 22; Min: 28; Sec: 02.68); Lon: (Deg: 78; Min: 18; Sec: 43.08)),
    (Name: 'NDB Jardines del Rey';       Lat: (Deg: 22; Min: 28; Sec: 04.41); Lon: (Deg: 78; Min: 18; Sec: 24.64)),
    (Name: 'VOR/DME Manzanillo';         Lat: (Deg: 20; Min: 18; Sec: 10.05); Lon: (Deg: 77; Min: 05; Sec: 58)),
    (Name: 'NDB Moa';                    Lat: (Deg: 20; Min: 38; Sec: 19.90); Lon: (Deg: 74; Min: 57; Sec: 15.58)),
    (Name: 'NDB Nuevas';                 Lat: (Deg: 21; Min: 23; Sec: 58);    Lon: (Deg: 77; Min: 13; Sec: 57)),
    (Name: 'VOR Nuevas';                 Lat: (Deg: 21; Min: 23; Sec: 42);    Lon: (Deg: 77; Min: 13; Sec: 51)),
    (Name: 'NDB Santa Clara';            Lat: (Deg: 22; Min: 28; Sec: 50.56); Lon: (Deg: 79; Min: 59; Sec: 36.33)),
    (Name: 'VOR/DME Santiago de Cuba';   Lat: (Deg: 19; Min: 58; Sec: 40.08); Lon: (Deg: 75; Min: 49; Sec: 21.56)),
    (Name: 'NDB Santiago de Cuba';       Lat: (Deg: 19; Min: 58; Sec: 22.36); Lon: (Deg: 75; Min: 49; Sec: 15.30)),
    (Name: 'VOR/DME Varadero';           Lat: (Deg: 23; Min: 01; Sec: 28.87); Lon: (Deg: 81; Min: 27; Sec: 12.93)),
    (Name: 'NDB Tunas';                  Lat: (Deg: 20; Min: 59; Sec: 19.01); Lon: (Deg: 76; Min: 56; Sec: 19.01)),
    (Name: 'NDB Zarago';                 Lat: (Deg: 22; Min: 56; Sec: 06);    Lon: (Deg: 82; Min: 02; Sec: 19))
  ));

function DegreeToDecDegree(TheDegree: TAeronautic_Angle): single;

var
  theSettings: TSettings;

implementation

uses
  Windows,
  SysUtils, Forms,
  Configuration;

const
  RegistryPath = {HKEY_CURRENTUSER\} 'Software\LDT\Vesta\Process';

const
  PathKey: array[0..8] of string = ('Timespans', 'Observations', 'Products',
                                     'Images', 'Animations', 'Reports',
                                     'Ensembles', 'Tools', 'NMEA_ATTEX');

  ValueKey: array[0..20] of string = ('DefaultCellH', 'DefaultCellV',
                                       'DefaultHorzBot', 'DefaultHorzTop',
                                       'DefaultCAPPIBot', 'DefaultCAPPITop',
                                       'DefaultTopsMin', 'DefaultTopsLocation',
                                       'DefaultCutBot', 'DefaultCutTop',
                                       'DefaultHorzWest',
                                       'DefaultHorzNorth',
                                       'DefaultHorzEast',
                                       'DefaultHorzSouth',
                                       'DefaultAnimationDelay',
                                       'DefaultMaxRange',
                                       'DefaultMeasure',
                                       'DefaultChannel',
                                       'DefaultWindHeight',
                                       'NMEA_ATTEX_Format',
                                       'Aeronautic_RadioHelp');

  ValueDef: array[0..20] of integer = (1000, 200,
                                        0, 20000,
                                        200, 1200,
                                        90, 0,
                                        0, 20000,
                                        -1000, 1000, 1000, -1000,
                                        200,
                                        1000,
                                        ord(unDBZ),
                                        0,
                                        1000,
                                        1,
                                        2);

  FloatKey: array[0..1] of string = ('VIL_C1', 'VIL_C2');
  FloatDef: array[0..1] of string = ('0.00524', '0.57143');

  BoolKey: array[0..21] of string = ('Exploration',
                                      'Topografia',
                                      'Escala',
                                      'Radar',
                                      'Cuadriculas',
                                      'Climatologia',
                                      'Radios',
                                      'Guia_de_corte',
                                      'Imagen_Titulos',
                                      'Imagen_Copyrights',
                                      'Imagen_Escala',
                                      'EcosFijos_Horz',
                                      'EcosFijos_CAPPI',
                                      'EcosFijos_VIL',
                                      'EcosFijos_Volume',
                                      'EcosFijos_Contribution',
                                      'EcosFijos_Vert',
                                      'EcosFijos_Tops',
                                      'Imagen_Suavizar',
                                      'Rejilla_Vertical',
                                      'Includir_Zero',
                                      'Activar_Piloto_Automatico');

  BoolDef: array[0..21] of integer = (1, 1, 0, 1,
                                       0, 0, 0, 0,
                                       1, 1, 1, 1,
                                       1, 1, 1, 1,
                                       1, 1, 1, 1,
                                       0, 0);

  PaletteName: array[TMeasure] of string =
    ('NONE', 'DB', 'DBZ', 'MMH', 'MS', 'MM', 'M', 'KM', 'KGM',
             'ZDR', 'PDP', 'Rho', 'KDP', 'GCP', 'TID', 'M2S2', 'W');

// TSettings methods

constructor TSettings.Create;
begin
  inherited;
  fSetting := TRegIniFile.Create(RegistryPath);
end;

destructor TSettings.Destroy;
begin
  FreeAndNil(fSetting);
  inherited;
end;

function TSettings.GetPath(Index: integer): string;
begin
  Result := fSetting.ReadString('Paths', PathKey[Index], theRunningDir + PathKey[Index]);
end;

procedure TSettings.SetPath(Index: integer; Value: string);
begin
  fSetting.WriteString('Paths', PathKey[Index], Value);
end;

function TSettings.GetPalette(aMsr: TMeasure): string;
begin
  Result := fSetting.ReadString('Palettes', PaletteName[aMsr],
                                theRunningDir + 'Palettes' + PathDelim + PaletteName[aMsr] + '.pal');
end;

procedure TSettings.SetPalette(aMsr: TMeasure; Value: string);
begin
  fSetting.WriteString('Palettes', PaletteName[aMsr], Value);
end;

function TSettings.GetInteger(Index: integer): integer;
begin
  Result := fSetting.ReadInteger(fFolder + 'Values', ValueKey[Index], ValueDef[Index]);
end;

procedure TSettings.SetInteger(Index: integer; Value: integer);
begin
  fSetting.WriteInteger(fFolder + 'Values', ValueKey[Index], Value);
end;

function TSettings.GetFloat(Index: integer): double;
begin
  Result := StrToFloat(fSetting.ReadString(fFolder + 'Values', FloatKey[Index], FloatDef[Index]));
end;

procedure TSettings.SetFloat(Index: integer;  Value: double);
begin
  fSetting.WriteString(fFolder + 'Values', FloatKey[Index], FloatToStr(Value));
end;

function TSettings.GetBoolean(Index: integer): boolean;
begin
  Result := (fSetting.ReadInteger('Show', BoolKey[Index], BoolDef[Index]) <> 0);
end;

procedure TSettings.SetBoolean(Index: integer; Value: boolean);
begin
  fSetting.WriteInteger('Show', BoolKey[Index], ord(Value));
end;

function DegreeToDecDegree;
begin
  with TheDegree do
    result := Deg + Min/60 + Sec/3600;
end;

// Intialization & finalization code

initialization
  theSettings := TSettings.Create;
finalization
  theSettings.Free;
end.
