unit TimeSpanAuto;

interface

uses
  Variants,
  Forms,
  FormAuto,
  Description;

type
  TTimeSpanAuto = class(TFormAuto)
  automated
    function  GetObservations : integer;
    function  GetChannels     : integer;
    function  GetObservation(       I : integer ) : variant;
    function  GetProduct    ( const S : string  ) : variant;
    function  GetAnimation  ( const S : string  ) : variant;
    function  GetChannel    (       I : integer ) : variant;
  automated
    procedure Load  ( const FileName : string  );
    procedure Save  ( const FileName : string  );
    procedure Insert( const FileName : string  );
    procedure Delete(       Index    : integer );
// Parche para resolver problema con parámetros en TimeSpan
    function CreateAnim_Param(const S: string; North, South, East, West, Bottom, Top,Measure, CellH, MaxRange: integer): variant;
    function CreatePrd_Param(const S: string; North, South, East, West, Bottom, Top,Measure, CellH, MaxRange: integer): variant;
  automated
    property Observations : integer read GetObservations;
    property Channels     : integer read GetChannels;
    property Product    [const S : string ] : variant read GetProduct;
    property Animation  [const S : string ] : variant read GetAnimation;
    property Observation[      I : integer] : variant read GetObservation;
    property Channel    [      I : integer] : variant read GetChannel;       
  protected
    class function FormClass : TFormClass;  override;
  end;

implementation

uses
  TimeSpan,
  Notify,
  Product, ChannelAuto,
  Shell_Process, TimeSpanForm;

// TTimeSpanAuto methods

function TTimeSpanAuto.GetObservations : integer;
begin
  Result := TFTimeSpan(Form).TimeSpan.Observations;
end;

function TTimeSpanAuto.GetChannels : integer;
begin
  Result := TFTimeSpan(Form).TimeSpan.Channels;
end;

function TTimeSpanAuto.GetProduct( const S : string ) : variant;
var
  P : TProduct;
begin
  P := TFTimeSpan(Form).GetProduct(S);
  if assigned(P)
    then
      begin
        Result := P.OleObject;
        // Parche, se crea el producto aquí mismo, rompe el diseño pero resuelve;
        TFTimeSpan(Form).CreateProduct(P);
      end
    else Result := null;
end;

function TTimeSpanAuto.GetAnimation( const S : string ) : variant;
var
  P : TProduct;
begin
  P := TFTimeSpan(Form).GetAnmProduct(S);
  if assigned(P)
    then
      begin
        Result := P.OleObject;
        // Parche, se crea la animación aquí mismo, rompe el diseño pero resuelve;
        TFTimeSpan(Form).CreateAnimation(P);
      end
    else Result := null;
end;

function TTimeSpanAuto.GetObservation( I : integer ) : variant;
begin
  Result := FShell.ShowObservation(TFTimeSpan(Form).TimeSpan[I], wsNormal);
end;

function TTimeSpanAuto.GetChannel( I : integer ) : variant;
var
  ChannelAuto : TChannelAuto;
begin
  ChannelAuto := TChannelAuto.Create;
  ChannelAuto.RadarData := TFTimeSpan(Form).TimeSpan;
  ChannelAuto.Index     := I;
  Result := ChannelAuto.OleObject;
end;

procedure TTimeSpanAuto.Load( const FileName : string );
begin
  TFTimeSpan(Form).TimeSpan := TTimeSpan.Load(FileName);
end;

procedure TTimeSpanAuto.Save( const FileName : string );
begin
  TFTimeSpan(Form).TimeSpan.Save(FileName);
end;

procedure TTimeSpanAuto.Insert( const FileName : string );
begin
  with TFTimeSpan(Form) do
    begin
      TimeSpan.AddFile(FileName);
      UpdateTimeSpanView;
    end;
end;

procedure TTimeSpanAuto.Delete( Index : integer );
begin
  with TFTimeSpan(Form) do
    begin
      TimeSpan.Delete(Index);
      UpdateTimeSpanView;
    end;
end;

function TTimeSpanAuto.CreateAnim_Param;
var
  P : TProduct;
begin
  P := TFTimeSpan(Form).GetAnmProduct(S);
  if assigned(P)
    then
      begin
        Result := P.OleObject;
        Result.Channel := 1;
        Result.North := North;
        Result.South := South;
        Result.East := East;
        Result.West := West;
        Result.Bottom := Bottom;
        Result.Top := Top;
        Result.Measure := Measure;
        Result.CellH := CellH;
        Result.MaxRange := MaxRange;
        TFTimeSpan(Form).CreateAnimation(P);
      end
    else Result := null;
end;

function TTimeSpanAuto.CreatePrd_Param;
var
  P : TProduct;
begin
  P := TFTimeSpan(Form).GetProduct(S);
  if assigned(P)
    then
      begin
        Result := P.OleObject;
        Result.Channel := 1;
        Result.North := North;
        Result.South := South;
        Result.East := East;
        Result.West := West;
        Result.Bottom := Bottom;
        Result.Top := Top;
        Result.Measure := Measure;
        Result.CellH := CellH;
        Result.MaxRange := MaxRange;
        TFTimeSpan(Form).CreateProduct(P);
      end
    else Result := null;
end;

class function TTimeSpanAuto.FormClass : TFormClass;
begin
  Result := TFTimeSpan;
end;

end.
