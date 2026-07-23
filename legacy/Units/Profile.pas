unit Profile;

interface

uses
  Types, Forms,
  Product, Observation, Measure, Plane, Vector,
  EditForm;

type
  TProfile     = class;
  TProfileAuto = class;

  TProfile = class(TProduct)
  public
    class function Name        : string;        override;
    class function Description : string;        override;
    class function ImageIndex  : integer;       override;
    class function EditForm    : TFEdit;        override;
    class function AutoClass   : CProductAuto;  override;
  private
    fTop     : integer;
    fBottom  : integer;
    fChannel : integer;
    fMeasure : TMeasure;
    fPoint   : TPoint;
    fHeight  : TCoord;
  public
    property Top        : integer  read fTop     write fTop;
    property Bottom     : integer  read fBottom  write fBottom;
    property Channel    : integer  read fChannel write fChannel;
    property Measure    : TMeasure read fMeasure write fMeasure;
    property Point      : TPoint   read fPoint   write fPoint;
    property CellHeight : TCoord   read fHeight  write fHeight;
  public
    function  Default : boolean;  override;
    procedure Render;             override;
    procedure Update;             override;
    procedure Show;               override;
  protected
    procedure GetEditData;  override;
    procedure SetEditData;  override;
  private
    fVector : TVector;
  end;

  TProfileAuto = class(TProductAuto)
  automated
    function  GetChannel : integer;
    function  GetMeasure : integer;
    function  GetTop     : integer;
    function  GetBottom  : integer;
    function  GetCellH   : integer;
    procedure SetChannel( Ch : integer );
    procedure SetMeasure( M  : integer );
    procedure SetTop    ( T  : integer );
    procedure SetBottom ( B  : integer );
    procedure SetCellH  ( CH : integer );
  automated
    property Channel : integer read GetChannel write SetChannel;
    property Measure : integer read GetMeasure write SetMeasure;
    property CellH   : integer read GetCellH   write SetCellH;
    property Top     : integer read GetTop     write SetTop;
    property Bottom  : integer read GetBottom  write SetBottom;
  end;

implementation

uses
  Settings,
  Windows,
  SysUtils,
  Angle, Notify,
  ProfileVector,
  ProfileEdit;

// TProfile methods

class function TProfile.Name : string;
begin
  Result := 'Perfil';
end;

class function TProfile.Description : string;
begin
  Result := 'Perfil vertical';
end;

class function TProfile.ImageIndex : integer;
begin
  Result := 12;
end;

class function TProfile.EditForm : TFEdit;
begin
  if FProfileEdit = nil
    then FProfileEdit := FProfileEdit.Create(Application.MainForm);
  Result := FProfileEdit;
end;

class function TProfile.AutoClass : CProductAuto;
begin
  Result := TProfileAuto;
end;

function TProfile.Default : boolean;
begin
  Top     := 20000;
  Bottom  := 0;
  Channel := 0;
  Measure := unDBZ;
  fPoint.X := 0;
  fPoint.Y := 0;
  CellHeight := theSettings.DefaultCellH;
  Result := true;
end;

procedure TProfile.Render;
begin
  Notify.Declare([0, 100]);
  fVector := TProfileVector.Initialize(Point, CellHeight, Bottom, Top);
  try
    TProfileVector(fVector).Render(Observation, Channel, Measure);
    //... Show profile vector ...
  except
    FreeAndNil(fVector);
    raise;
  end;
  inherited;
end;

procedure TProfile.Update;
begin
//...
end;

procedure TProfile.Show;
begin
//...
end;

procedure TProfile.GetEditData;
begin
  with EditForm as TFProfileEdit do
    begin
      fBottom  := UpDown10.Position;
      fTop     := UpDown11.Position;
      fChannel := StringGrid1.Row - 1;
      fMeasure := Measure;
      fHeight  := CellH;
      fPoint.X := Area1.West;
      fPoint.Y := Area1.South;
    end;
end;

procedure TProfile.SetEditData;
begin
  with EditForm as TFProfileEdit do
    begin
      UpDown10.Position := fBottom;
      UpDown11.Position := fTop;
      StringGrid1.Row   := fChannel + 1;
      Measure           := fMeasure;
      CellH             := fHeight;
      with Area1 do
        begin
          West  := fPoint.X;
          South := fPoint.Y;
        end;
    end;
end;

// TProfileAuto methods

function TProfileAuto.GetChannel : integer;
begin
  Result := (Product as TProfile).Channel;
end;

function TProfileAuto.GetMeasure : integer;
begin
  Result := ord((Product as TProfile).Measure);
end;

function TProfileAuto.GetTop : integer;
begin
  Result := (Product as TProfile).Top;
end;

function TProfileAuto.GetBottom : integer;
begin
  Result := (Product as TProfile).Bottom;
end;

function TProfileAuto.GetCellH : integer;
begin
  Result := (Product as TProfile).CellHeight;
end;

procedure TProfileAuto.SetChannel( Ch : integer );
begin
  (Product as TProfile).Channel := Ch;
end;

procedure TProfileAuto.SetMeasure( M : integer );
begin
  (Product as TProfile).Measure := TMeasure(M);
end;

procedure TProfileAuto.SetTop( T : integer );
begin
  (Product as TProfile).Top := T;
end;

procedure TProfileAuto.SetBottom( B : integer );
begin
  (Product as TProfile).Bottom := B;
end;

procedure TProfileAuto.SetCellH( CH : integer );
begin
  (Product as TProfile).CellHeight := CH;
end;

end.

