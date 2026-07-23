unit AnimationForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, ExtCtrls, StdCtrls, ComCtrls, Menus,
  Animation, FormAuto;

type
  TFAnimation = class(TForm)
    SpeedButton4: TSpeedButton;
    SpeedButton7: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton1: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton3: TSpeedButton;
    Timer1: TTimer;
    Label2: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    UpDown2: TUpDown;
    CheckBox1: TCheckBox;
    SaveDialog1: TSaveDialog;
    TrackBar1: TTrackBar;
    PopupMenu1: TPopupMenu;
    Salvar1: TMenuItem;
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Salvar1Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure UpDown2Click(Sender: TObject; Button: TUDBtnType);
  private
    fAnimation : TAnimation;
    fFormAuto  : TFormAuto;
    function  GetFormAuto  : TFormAuto;
    function  GetOleObject : variant;
    procedure SetAnimation( A : TAnimation );
    function  GetPosition  : integer;
    function  GetDelay     : integer;
    procedure SetPosition ( P : integer );
    procedure SetDelay    ( D : integer );
    procedure AnimationDestroy ( Sender : TObject );
    procedure CheckAnimationSave;
  public
    property Animation : TAnimation read fAnimation   write SetAnimation;
    property Position  : integer    read GetPosition  write SetPosition;
    property Delay     : integer    read GetDelay     write SetDelay;
    property FormAuto  : TFormAuto  read GetFormAuto  write fFormAuto;
    property OleObject : variant    read GetOleObject;
  end;

var
  FAnimation: TFAnimation;

implementation

{$R *.DFM}

  uses
    Settings,
    Products,
    AnimationAuto;


// TFAnimation methods

  function TFAnimation.GetFormAuto : TFormAuto;
  begin
    if fFormAuto = nil
      then
        begin
          fFormAuto := TAnimationAuto.Create;
          fFormAuto.Form := Self
        end;
    Result := fFormAuto;
  end;

  function TFAnimation.GetOleObject : variant;
  begin
    Result := FormAuto.OleObject;
  end;

  procedure TFAnimation.SetAnimation( A : TAnimation );
  var
    P : TPoint;
  begin
    if assigned(fAnimation) and (A <> fAnimation)
      then
        begin
          CheckAnimationSave;
          fAnimation.OnDestroy := nil;
          fAnimation.Free;
        end;
    fAnimation := A;
    if assigned(fAnimation)
      then
        begin
          TrackBar1.Min := 1;
          TrackBar1.Max := Animation.Frames;
          Animation.Ondestroy := AnimationDestroy;
          Position := 1;
          //GetProductLargeIcon( Animation.Product, Icon );
          P := Animation.Product.Position;
          SetBounds( P.X, P.Y, Width, Height );
          WindowState := wsNormal;
          Enabled     := true;
        end
      else
        begin
          TrackBar1.Min := 0;
          TrackBar1.Max := 0;
        end;
  end;

  function TFAnimation.GetPosition : integer;
  begin
    Result := succ(Animation.Position);
  end;

  procedure TFAnimation.SetPosition( P : integer );
  begin
    with TrackBar1 do
      if (P >= Min) and (P <= Max)
        then
          begin
            Animation.Position := pred(P);
            Edit1.Text := IntToStr(P);
            Caption := Animation.Product.Brief;
            TrackBar1.Position := P;
          end;
  end;

  function TFAnimation.GetDelay : integer;
  begin
    Result := UpDown2.Position;
  end;

  procedure TFAnimation.SetDelay( D : integer );
  begin
    Edit2.Text       := IntToStr(D);
    UpDown2.Position := D;
    Timer1.Interval  := D;
  end;

  procedure TFAnimation.AnimationDestroy( Sender : TObject );
  begin
    SpeedButton3Click( SpeedButton3 );
    CheckAnimationSave;
    fAnimation := nil;
    Release;
  end;

  procedure TFAnimation.CheckAnimationSave;
  begin
    if not Application.Terminated and
       (UpperCase(ExtractFileExt(Animation.FileName)) = '.TMP') and
       (Application.MessageBox( '¿Desea salvar la animación?',
                                'Animación',
                                 MB_ICONQUESTION or MB_YESNO ) = IDYES)
      then Salvar1Click( Salvar1 );
  end;


// Component methods

procedure TFAnimation.SpeedButton1Click(Sender: TObject);
begin  // Play
  with Sender as TSpeedButton do
    begin
      SpeedButton2.Down    := false;
      SpeedButton2.Enabled :=     Down;
      SpeedButton3.Enabled :=     Down;
      SpeedButton4.Enabled := not Down;
      SpeedButton5.Enabled := not Down;
      SpeedButton6.Enabled := not Down;
      SpeedButton7.Enabled := not Down;
      Timer1.Enabled := Down;
    end;
end;

procedure TFAnimation.SpeedButton2Click(Sender: TObject);
begin  // Pause
  with Sender as TSpeedButton do
    begin
      SpeedButton4.Enabled := Down;
      SpeedButton5.Enabled := Down;
      SpeedButton6.Enabled := Down;
      SpeedButton7.Enabled := Down;
      Timer1.Enabled := not Down;
    end;
end;

procedure TFAnimation.SpeedButton3Click(Sender: TObject);
begin  // Stop
  Timer1.Enabled := false;
  SpeedButton1.Down    := false;
  SpeedButton2.Down    := false;
  SpeedButton2.Enabled := false;
  SpeedButton3.Enabled := false;
  SpeedButton4.Enabled := true;
  SpeedButton5.Enabled := true;
  SpeedButton6.Enabled := true;
  SpeedButton7.Enabled := true;
end;

procedure TFAnimation.SpeedButton4Click(Sender: TObject);
begin  // Previous frame
  with TrackBar1 do
    if Position > Min
      then Self.Position := pred(Position);
end;

procedure TFAnimation.SpeedButton5Click(Sender: TObject);
begin  // Next frame
  with TrackBar1 do
    if Position < Max
      then Self.Position := succ(Position);
end;

procedure TFAnimation.SpeedButton6Click(Sender: TObject);
begin  // Go to first frame
  Position := TrackBar1.Min;
end;

procedure TFAnimation.SpeedButton7Click(Sender: TObject);
begin  // Go to last frame
  Position := TrackBar1.Max;
end;

procedure TFAnimation.Timer1Timer(Sender: TObject);
begin
  with TrackBar1 do
    if Position = Max
      then
        if CheckBox1.Checked
          then Self.Position := Min
          else SpeedButton3.Click
      else Self.Position := succ(Position);
end;

procedure TFAnimation.FormCreate(Sender: TObject);
begin
//Parent := Application.MainForm;
  Timer1.Interval := UpDown2.Position;
  SaveDialog1.InitialDir := theSettings.Animations;
  SaveDialog1.Filter     := AnimationFilter;
end;

procedure TFAnimation.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFAnimation.FormDestroy(Sender: TObject);
begin
  SpeedButton3Click( SpeedButton3 );
  if assigned(fFormAuto)
    then fFormAuto.Release;
  if assigned(fAnimation)
    then
      begin
        CheckAnimationSave;
        fAnimation.OnDestroy := nil;
        fAnimation.Free;
        fAnimation := nil;
      end;
end;

procedure TFAnimation.Salvar1Click(Sender: TObject);
begin
  with SaveDialog1 do
    if Execute
      then Animation.Save( FileName );
end;

procedure TFAnimation.TrackBar1Change(Sender: TObject);
begin
  Position := (Sender as TTrackBar).Position;
end;

procedure TFAnimation.Edit1Change(Sender: TObject);
begin
  try
    Position := StrToInt((Sender as TEdit).Text);
  except
    on EConvertError do (Sender as TEdit).Text := IntToStr(Position);
  end;
end;

procedure TFAnimation.Edit2Change(Sender: TObject);
begin
  try
    Delay := StrToInt( (Sender as TEdit).Text );
  except
    on EConvertError do (Sender as TEdit).Text := IntToStr(Delay);
  end;
end;

procedure TFAnimation.UpDown2Click(Sender: TObject; Button: TUDBtnType);
begin
  Delay := (Sender as TUpDown).Position;
end;

end.
