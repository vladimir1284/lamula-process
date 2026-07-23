unit SpatialAnimation;

interface

uses
  Windows,
  Classes, Forms,
  Product,
  Animation,
  PPI,
  DataSource, Measure, Plane, Scan, HeightTable, PRTable, Angle,
  EditForm;

type
  TSpatialAnimation = class(TPPI)
  public
    class function  Name        : string;                 override;
    class function  Description : string;                 override;
    class function  ImageIndex  : integer;                override;
    class function  EditForm    : TFEdit;                 override;
    class function  Accept( D : CDataSource ) : boolean;  override;
    class function  CanAnimate  : boolean;                override;
  protected
    function  GetBrief : string;  override;
    procedure GetEditData;        override;
  public
    procedure Render;  override;
    procedure Show;    override;
  private
    fAnimation : TAnimation;
  end;

implementation

uses
  SysUtils,
  Settings,
  RadarData, Observation, Notify,
  Radars,
  VestaPlane,
  SpatialEdit;

// TVolume methods

class function TSpatialAnimation.Name : string;
begin
  Result := 'Espacial';
end;

class function TSpatialAnimation.Description : string;
begin
  Result := 'Animacion espacial';
end;

class function TSpatialAnimation.ImageIndex : integer;
begin
  Result := 16;
end;

class function TSpatialAnimation.EditForm : TFEdit;
begin
  if FSpatialEdit = nil
    then Application.CreateForm(TFSpatialEdit, FSpatialEdit);
  Result := FSpatialEdit;
end;

class function TSpatialAnimation.Accept( D : CDataSource ) : boolean;
begin
  Result := inherited Accept(D);
end;

class function TSpatialAnimation.CanAnimate : boolean;
begin
  Result := false;
end;

procedure TSpatialAnimation.Render;
var
  I     : integer;
  Frame : integer;
begin
  Notify.Declare([0, 100]);
  with Observation do
    try
      Frame := 0;
      for I := 0 to Movements - 1 do
        with MoveDesc[I] do
          if (Channel = Self.Channel) and (Kind = pkHorizontal) and SameMeasureSet(Measure, Self.Measure)
            then inc(Frame);  // Count frames
      fAnimation := TAnimation.Create(Owner);
      fAnimation.Product := Self;
      fAnimation.Frames := Frame;
      StartNotify(fAnimation.Frames);
      Frame := 0;
      for I := 0 to Movements - 1 do
        with MoveDesc[I] do
          if (Channel = Self.Channel) and (Kind = pkHorizontal) and SameMeasureSet(Measure, Self.Measure)
            then // Create frame
              try
                Notify.Disable;
                ScanIndex := I;
                inherited Render;
                Notify.Enable;
                DoNotify;
                if Rendered
                  then fAnimation.Frame[Frame] := Self as TPPI
                  else raise Exception.Create('');
                inc(Frame);
              except
                on E : Exception do
                  begin
                    FreeAndNil(fAnimation);
                    E.Message := Format('No se pudo crear PPI numero %d, elevacion %.1f°:'#13#10'%s',
                                        [succ(I), CodeAngle(Elevation), E.Message]);
                    raise;
                  end;
              end;
    finally
      EndNotify;
    end;
end;

procedure TSpatialAnimation.Show;
begin
//...
  fAnimation.Position := 0;
end;

function TSpatialAnimation.GetBrief : string;
begin
  Result := Format('%s, %s a %.1f°',
                   [inherited Name, MeasureVar(Measure), CodeAngle(Elevation)]);
end;

procedure TSpatialAnimation.GetEditData;
begin
  inherited;
  Bottom := 0;
  Top    := 20000;
end;

end.

