unit AnimationAuto;

interface

uses
  Forms,
  GridAuto;

type
  TAnimationAuto = class(TGridAuto)
  automated
    function  GetRendered  : wordbool;
    function  GetFrames    : integer;
    function  GetPosition  : integer;
    procedure SetPosition( P : integer  );
  automated
    procedure Load( const FileName : string );
    procedure Save( const FileName : string );
    procedure Play;
    procedure Pause;
    procedure First;
    procedure Last;
  automated
    property Rendered  : wordbool read GetRendered;
    property Frames    : integer  read GetFrames;
    property Position  : integer  read GetPosition write SetPosition;
  end;

implementation

uses
  Animation,
  GridForm;

// TAnimationAuto methods

function TAnimationAuto.GetRendered : wordbool;
begin
  with Form as TFGrid do
    Result := assigned(Animation);
end;

function TAnimationAuto.GetFrames : integer;
begin
  Result := (Form as TFGrid).Animation.Frames;
end;

function TAnimationAuto.GetPosition : integer;
begin
  Result := (Form as TFGrid).Animation.Position;
end;

procedure TAnimationAuto.SetPosition( P : integer );
begin
  (Form as TFGrid).Animation.Position := P;
end;

procedure TAnimationAuto.Load( const FileName : string );
begin
  (Form as TFGrid).Animation := TAnimation.Load(FileName);
end;

procedure TAnimationAuto.Save( const FileName : string );
begin
  (Form as TFGrid).SaveData(FileName);
end;

procedure TAnimationAuto.Play;
begin
  with Form as TFGrid do
    if not Playing
      then ToolButton1Click(ToolButton1);
end;

procedure TAnimationAuto.Pause;
begin
  with Form as TFGrid do
    if Playing
      then ToolButton1Click(ToolButton1);
end;

procedure TAnimationAuto.First;
begin
  Position := 0;
end;

procedure TAnimationAuto.Last;
begin
  Position := Frames - 1;
end;

end.

