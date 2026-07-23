unit RHIEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  VertEdit, Antenna, StdCtrls, Area, Spin, Grids, ComCtrls;

type
  TFRHIEdit = class(TFVertEdit)
    TabSheet4: TTabSheet;
    Azimut1: TAzimut;
    Label17: TLabel;
    Label18: TLabel;
    Edit10: TEdit;
    procedure Azimut1NewDesired(Sender: TObject; Position: Smallint);
    procedure Edit10Change(Sender: TObject);
  end;

var
  FRHIEdit: TFRHIEdit;

implementation

{$R *.DFM}

  uses
    Angle;

procedure TFRHIEdit.Azimut1NewDesired(Sender: TObject; Position: Smallint);
begin
  inherited;
  (Sender as TAzimut).Position := Position;
  if not Edit10.Focused
    then Edit10.Text := FloatToStrF( CodeAngle(Position), ffFixed, 5, 1 );
end;

procedure TFRHIEdit.Edit10Change(Sender: TObject);
begin
  inherited;
  with Azimut1 do
    try
      Desired  := AngleCode(StrToFloat((Sender as TEdit).Text));
      Position := Desired;
    except
      on EConvertError do
        Desired := Position; 
    end;
end;

end.
