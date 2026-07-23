unit Topography;

interface

uses
  Windows,
  Graphics,
  Plane;

function  MapAvailable ( const MapCenter : T2DLocation ) : boolean;
procedure MapTopography( const MapCenter : T2DLocation; BM : TBitmap; Area : TRect; PPMW, PPMH : double );
function  TopographyMap( const MapCenter : T2DLocation; Area : TRect; PPMW, PPMH : double; Back : TColor ) : TBitmap;
function MapFileName( const MapCenter : T2DLocation ) : string;

implementation

uses
  SysUtils,
  Math,
  GifImage,
  Configuration,
  Description,
  Radars,
  UtStr;

// Private procedures & functions

function MapFileName( const MapCenter : T2DLocation ) : string;
var
  R : TRadar;
begin
  R := Low(TRadar);
  while R <= High(TRadar) do
    begin
      with Radars.Find(R).Location do
        if (MapCenter.Longitude = Longitude) and
           (MapCenter.Latitude  = Latitude)
          then break;
      inc(R);
    end;
  if R <= High(TRadar)
    then Result := IncludeTrailingPathDelimiter(theConfiguration.TopographyMaps) +
                   TrimBlanks(Radars.Find(R).Name) + '.map'
    else Result := '';
end;

// Public procedures & functions

function MapAvailable ( const MapCenter : T2DLocation ) : boolean;
begin
  Result := FileExists(MapFileName(MapCenter));
end;

procedure MapTopography( const MapCenter : T2DLocation; BM : TBitmap; Area : TRect; PPMW, PPMH : double );
var
  X1, Y1 : integer;
  X2, Y2 : integer;
  W1, H1 : integer;
  W2, H2 : integer;
  SM     : integer;
begin
  if MapAvailable(MapCenter)
    then
      with TGifImage.Create do
        try
          LoadFromFile(MapFileName(MapCenter));  // <--- Optimize !!!
          W2 := Min(1000, Area.Right - Area.Left + 2);
          H2 := Min(1000, Area.Top - Area.Bottom + 2);
          W1 := round(1000 * W2 * PPMW);
          H1 := round(1000 * H2 * PPMH);
          X1 := round((BM.Width  - W1)/2);
          Y1 := round((BM.Height - H1)/2);
          X2 := Max(0, 500 + Area.Left);
          Y2 := Max(0, 500 - Area.Top );
          SM := SetStretchBltMode(BM.Canvas.Handle, COLORONCOLOR);
          StretchBlt(BM.Canvas.Handle,  X1, Y1, W1, H1,
                     Bitmap.Canvas.Handle, X2, Y2, W2, H2, SRCCOPY);
          if SM <> 0 then SetStretchBltMode(BM.Canvas.Handle, SM);
        finally
          Free;
        end;
end;

function TopographyMap( const MapCenter : T2DLocation; Area : TRect; PPMW, PPMH : double; Back : TColor ) : TBitmap;
var
  X1, Y1 : integer;
  X2, Y2 : integer;
  W1, H1 : integer;
  W2, H2 : integer;
  SM     : integer;
begin
  Result := nil;
  if MapAvailable(MapCenter)
    then
      with TGifImage.Create do
        try
          LoadFromFile(MapFileName(MapCenter));  // <--- Optimize !!!
          Result := TBitmap.Create;
          W2 := Min(1000, Area.Right - Area.Left + 2);
          H2 := Min(1000, Area.Top - Area.Bottom + 2);
          W1 := round(1000 * W2 * PPMW);
          H1 := round(1000 * H2 * PPMH);
          with Result do
            begin
              Width  := W1;
              Height := H1;
              Canvas.Brush.Color := Back;
              Canvas.Brush.Style := bsSolid;
              Canvas.Rectangle(0, 0, Width, Height);
            end;
          X1 := round((W1 - (W2 * 1000) * PPMW) / 2);
          Y1 := round((H1 - (H2 * 1000) * PPMH) / 2);
          X2 := Max(0, 500 + Area.Left);
          Y2 := Max(0, 500 - Area.Top );
          SM := SetStretchBltMode(Result.Canvas.Handle, COLORONCOLOR);
          StretchBlt(Result.Canvas.Handle, X1, Y1, W1, H1,
                     Bitmap.Canvas.Handle, X2, Y2, W2, H2, SRCCOPY);
          if SM <> 0 then SetStretchBltMode(Result.Canvas.Handle, SM);
        finally
          Free;
        end;
end;

end.

