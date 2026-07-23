unit PPIEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  HorzEdit, Antenna, StdCtrls, Area, Spin, Grids, ComCtrls;

type
  TFPPIEdit = class(TFHorzEdit)
    TabSheet4: TTabSheet;
    Label17: TLabel;
    Elevation1: TElevation;
    Label16: TLabel;
    Edit10: TEdit;
    procedure Elevation1NewDesired(Sender: TObject; Position: Smallint);
    procedure Edit10Change(Sender: TObject);
  end;

var
  FPPIEdit: TFPPIEdit = nil;

implementation

{$R *.DFM}

uses
  Angle;

procedure TFPPIEdit.Elevation1NewDesired(Sender: TObject;
  Position: Smallint);
begin
  inherited;
  (Sender as TElevation).Position := Position;
  if not Edit10.Focused
    then Edit10.Text := FloatToStrF(CodeAngle(Position), ffFixed, 5, 1);
end;

procedure TFPPIEdit.Edit10Change(Sender: TObject);
begin
  inherited;
  with Elevation1 do
    try
      Desired  := AngleCode(StrToFloat((Sender as TEdit).Text));
      Position := Desired;
    except
      on EConvertError do
        Desired := Position;
    end;
end;

end.
