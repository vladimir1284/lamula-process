unit EditAutoPilotForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, Antenna, StdCtrls, Area, Spin, Angle;

type
  TFEditAutoPilot = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    SpinEdit1: TSpinEdit;
    SpinEdit2: TSpinEdit;
    ComboBox1: TComboBox;
    GroupBox2: TGroupBox;
    Label32: TLabel;
    SpinEdit21: TSpinEdit;
    GroupBox3: TGroupBox;
    Label4: TLabel;
    SpinEdit3: TSpinEdit;
    TabSheet2: TTabSheet;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    SpinEdit7: TSpinEdit;
    SpinEdit8: TSpinEdit;
    SpinEdit9: TSpinEdit;
    SpinEdit10: TSpinEdit;
    SpinEdit11: TSpinEdit;
    TabSheet3: TTabSheet;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label20: TLabel;
    Area2: TArea;
    SpinEdit13: TSpinEdit;
    SpinEdit14: TSpinEdit;
    SpinEdit15: TSpinEdit;
    SpinEdit16: TSpinEdit;
    SpinEdit17: TSpinEdit;
    SpinEdit19: TSpinEdit;
    TabSheet4: TTabSheet;
    Label21: TLabel;
    Elevation1: TElevation;
    Edit1: TEdit;
    TabSheet5: TTabSheet;
    Label23: TLabel;
    Azimut1: TAzimut;
    Edit2: TEdit;
    TabSheet6: TTabSheet;
    Label25: TLabel;
    Label26: TLabel;
    SpinEdit20: TSpinEdit;
    TabSheet7: TTabSheet;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    TrackBar1: TTrackBar;
    Button1: TButton;
    Button2: TButton;
    Label24: TLabel;
    Label22: TLabel;
    Label31: TLabel;
    SpinEdit23: TSpinEdit;
    Area1: TArea;
    procedure Elevation1NewDesired(Sender: TObject; Position: Smallint);
    procedure Edit1Change(Sender: TObject);
    procedure Azimut1NewDesired(Sender: TObject; Position: Smallint);
    procedure Edit2Change(Sender: TObject);
    procedure Area1Change(Sender: TObject);
    procedure SpinEdit7Change(Sender: TObject);
    procedure SpinEdit8Change(Sender: TObject);
    procedure SpinEdit9Change(Sender: TObject);
    procedure SpinEdit10Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FEditAutoPilot: TFEditAutoPilot;

implementation

{$R *.dfm}

procedure TFEditAutoPilot.Elevation1NewDesired(Sender: TObject;
  Position: Smallint);
begin
  inherited;
  (Sender as TElevation).Position := Position;
  if not Edit1.Focused
    then Edit1.Text := FloatToStrF(CodeAngle(Position), ffFixed, 5, 1);
end;

procedure TFEditAutoPilot.Edit1Change(Sender: TObject);
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

procedure TFEditAutoPilot.Azimut1NewDesired(Sender: TObject;
  Position: Smallint);
begin
  inherited;
  (Sender as TAzimut).Position := Position;
  if not Edit2.Focused
    then Edit2.Text := FloatToStrF( CodeAngle(Position), ffFixed, 5, 1 );
end;

procedure TFEditAutoPilot.Edit2Change(Sender: TObject);
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

procedure TFEditAutoPilot.Area1Change(Sender: TObject);
begin
  with Sender as TArea do
    begin
      SpinEdit7.Value := East;
      SpinEdit8.Value := West;
      SpinEdit9.Value := North;
      SpinEdit10.Value := South;
    end;
end;

procedure TFEditAutoPilot.SpinEdit7Change(Sender: TObject);
begin
  Area1.East := SpinEdit7.Value;
end;

procedure TFEditAutoPilot.SpinEdit8Change(Sender: TObject);
begin
  Area1.West := SpinEdit8.Value;
end;

procedure TFEditAutoPilot.SpinEdit9Change(Sender: TObject);
begin
  Area1.North := SpinEdit9.Value;
end;

procedure TFEditAutoPilot.SpinEdit10Change(Sender: TObject);
begin
  Area1.South := SpinEdit10.Value;
end;

end.
