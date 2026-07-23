unit CalConForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  ConvUtils, StdConvs;

type
  TFCalCon = class(TForm)
    RadioGroup2: TRadioGroup;
    RadioGroup1: TRadioGroup;
    RadioGroup4: TRadioGroup;
    RadioGroup3: TRadioGroup;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit13: TEdit;
    Edit14: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit9: TEdit;
    Edit10: TEdit;
    procedure RadioGroup1Click(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure RadioGroup2Click(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure Edit3Change(Sender: TObject);
    procedure Edit4Change(Sender: TObject);
    procedure Edit5Change(Sender: TObject);
    procedure Edit6Change(Sender: TObject);
    procedure Edit7Change(Sender: TObject);
    procedure Edit8Change(Sender: TObject);
    procedure Edit9Change(Sender: TObject);
    procedure Edit10Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RadioGroup3Click(Sender: TObject);
    procedure RadioGroup4Click(Sender: TObject);
    procedure Edit11Change(Sender: TObject);
    procedure Edit12Change(Sender: TObject);
    procedure Edit13Change(Sender: TObject);
    procedure Edit14Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

const
  MetersPerKiloFeet = MetersPerFoot * 1000;

resourcestring
  SKiloFeetDescription = 'KiloFeet';

var
  FCalCon: TFCalCon;
  duKiloFeet: TConvType;

implementation

{$R *.dfm}

uses
  CalcFunctions, Math;

procedure TFCalCon.RadioGroup1Click(Sender: TObject);
begin
  with RadioGroup1 do
    begin
      Edit1.Enabled := ItemIndex = 0;
      Edit2.Enabled := ItemIndex = 1;
      Edit3.Enabled := ItemIndex = 2;
      Edit4.Enabled := ItemIndex = 3;
    end;
end;

procedure TFCalCon.RadioGroup2Click(Sender: TObject);
begin
  with RadioGroup2 do
    begin
      Edit5.Enabled := ItemIndex = 0;
      Edit6.Enabled := ItemIndex = 1;
      Edit7.Enabled := ItemIndex = 2;
      Edit8.Enabled := ItemIndex = 3;
      Edit9.Enabled := ItemIndex = 4;
      Edit10.Enabled := ItemIndex = 5;
    end;
end;

procedure TFCalCon.Edit1Change(Sender: TObject);
begin
  if RadioGroup1.ItemIndex = 0 then
    begin
      Edit2.Text := FloatToStrF(Convert(Edit2Float(Edit1), duKilometers, tuHours, duMiles, tuHours), ffFixed, 18, 3);
      Edit3.Text := FloatToStrF(Convert(Edit2Float(Edit1), duKilometers, tuHours, duNauticalMiles, tuHours), ffFixed, 18, 3);
      Edit4.Text := FloatToStrF(Convert(Edit2Float(Edit1), duKilometers, tuHours, duMeters, tuSeconds), ffFixed, 18, 3);
    end;
end;

procedure TFCalCon.Edit2Change(Sender: TObject);
begin
  if RadioGroup1.ItemIndex = 1 then
    begin
      Edit1.Text := FloatToStrF(Convert(Edit2Float(Edit2), duMiles, tuHours, duKilometers, tuHours), ffFixed, 18, 3);
      Edit3.Text := FloatToStrF(Convert(Edit2Float(Edit2), duMiles, tuHours, duNauticalMiles, tuHours), ffFixed, 18, 3);
      Edit4.Text := FloatToStrF(Convert(Edit2Float(Edit2), duMiles, tuHours, duMeters, tuSeconds), ffFixed, 18, 3);
    end;
end;

procedure TFCalCon.Edit3Change(Sender: TObject);
begin
  if RadioGroup1.ItemIndex = 2 then
    begin
      Edit1.Text := FloatToStrF(Convert(Edit2Float(Edit3), duNauticalMiles, tuHours, duKilometers, tuHours), ffFixed, 18, 3);
      Edit2.Text := FloatToStrF(Convert(Edit2Float(Edit3), duNauticalMiles, tuHours, duMiles, tuHours), ffFixed, 18, 3);
      Edit4.Text := FloatToStrF(Convert(Edit2Float(Edit3), duNauticalMiles, tuHours, duMeters, tuSeconds), ffFixed, 18, 3);
    end;
end;

procedure TFCalCon.Edit4Change(Sender: TObject);
begin
  if RadioGroup1.ItemIndex = 3 then
    begin
      Edit1.Text := FloatToStrF(Convert(Edit2Float(Edit4), duMeters, tuSeconds, duKilometers, tuHours), ffFixed, 18, 3);
      Edit2.Text := FloatToStrF(Convert(Edit2Float(Edit4), duMeters, tuSeconds, duMiles, tuHours), ffFixed, 18, 3);
      Edit3.Text := FloatToStrF(Convert(Edit2Float(Edit4), duMeters, tuSeconds, duNauticalMiles, tuHours), ffFixed, 18, 3);
    end;
end;

procedure TFCalCon.Edit5Change(Sender: TObject);
begin
  if RadioGroup2.ItemIndex = 0 then
    begin
      Edit6.Text := FloatToStrF(Convert(Edit2Float(Edit5), duKiloMeters, duMiles), ffFixed, 18, 3);
      Edit7.Text := FloatToStrF(Convert(Edit2Float(Edit5), duKiloMeters, duNauticalMiles), ffFixed, 18, 3);
      Edit8.Text := FloatToStrF(Convert(Edit2Float(Edit5), duKiloMeters, duKiloFeet), ffFixed, 18, 3);
      Edit9.Text := FloatToStrF(Convert(Edit2Float(Edit5), duKiloMeters, duMeters), ffFixed, 18, 3);
      Edit10.Text := FloatToStrF(Convert(Edit2Float(Edit5), duKiloMeters, duFeet), ffFixed, 18, 3);
    end;
end;

procedure TFCalCon.Edit6Change(Sender: TObject);
begin
  if RadioGroup2.ItemIndex = 1 then
    begin
      Edit5.Text := FloatToStrF(Convert(Edit2Float(Edit6), duMiles, duKilometers), ffFixed, 18, 3);
      Edit7.Text := FloatToStrF(Convert(Edit2Float(Edit6), duMiles, duNauticalMiles), ffFixed, 18, 3);
      Edit8.Text := FloatToStrF(Convert(Edit2Float(Edit6), duMiles, duKiloFeet), ffFixed, 18, 3);
      Edit9.Text := FloatToStrF(Convert(Edit2Float(Edit6), duMiles, duMeters), ffFixed, 18, 3);
      Edit10.Text := FloatToStrF(Convert(Edit2Float(Edit6), duMiles, duFeet), ffFixed, 18, 3);
    end;
end;

procedure TFCalCon.Edit7Change(Sender: TObject);
begin
  if RadioGroup2.ItemIndex = 2 then
    begin
      Edit5.Text := FloatToStrF(Convert(Edit2Float(Edit7), duNauticalMiles, duKilometers), ffFixed, 18, 3);
      Edit6.Text := FloatToStrF(Convert(Edit2Float(Edit7), duNauticalMiles, duMiles), ffFixed, 18, 3);
      Edit8.Text := FloatToStrF(Convert(Edit2Float(Edit7), duNauticalMiles, duKiloFeet), ffFixed, 18, 3);
      Edit9.Text := FloatToStrF(Convert(Edit2Float(Edit7), duNauticalMiles, duMeters), ffFixed, 18, 3);
      Edit10.Text := FloatToStrF(Convert(Edit2Float(Edit7), duNauticalMiles, duFeet), ffFixed, 18, 3);
    end;
end;

procedure TFCalCon.Edit8Change(Sender: TObject);
begin
  if RadioGroup2.ItemIndex = 3 then
    begin
      Edit5.Text := FloatToStrF(Convert(Edit2Float(Edit8), duKiloFeet, duKilometers), ffFixed, 18, 3);
      Edit6.Text := FloatToStrF(Convert(Edit2Float(Edit8), duKiloFeet, duMiles), ffFixed, 18, 3);
      Edit7.Text := FloatToStrF(Convert(Edit2Float(Edit8), duKiloFeet, duNauticalMiles), ffFixed, 18, 3);
      Edit9.Text := FloatToStrF(Convert(Edit2Float(Edit8), duKiloFeet, duMeters), ffFixed, 18, 3);
      Edit10.Text := FloatToStrF(Convert(Edit2Float(Edit8), duKiloFeet, duFeet), ffFixed, 18, 3);
    end;
end;

procedure TFCalCon.Edit9Change(Sender: TObject);
begin
  if RadioGroup2.ItemIndex = 4 then
    begin
      Edit5.Text := FloatToStrF(Convert(Edit2Float(Edit9), duMeters, duKilometers), ffFixed, 18, 3);
      Edit6.Text := FloatToStrF(Convert(Edit2Float(Edit9), duMeters, duMiles), ffFixed, 18, 3);
      Edit7.Text := FloatToStrF(Convert(Edit2Float(Edit9), duMeters, duNauticalMiles), ffFixed, 18, 3);
      Edit8.Text := FloatToStrF(Convert(Edit2Float(Edit9), duMeters, duKiloFeet), ffFixed, 18, 3);
      Edit10.Text := FloatToStrF(Convert(Edit2Float(Edit9), duMeters, duFeet), ffFixed, 18, 3);
    end;
end;

procedure TFCalCon.Edit10Change(Sender: TObject);
begin
  if RadioGroup2.ItemIndex = 5 then
    begin
      Edit5.Text := FloatToStrF(Convert(Edit2Float(Edit10), duFeet, duKilometers), ffFixed, 18, 3);
      Edit6.Text := FloatToStrF(Convert(Edit2Float(Edit10), duFeet, duMiles), ffFixed, 18, 3);
      Edit7.Text := FloatToStrF(Convert(Edit2Float(Edit10), duFeet, duNauticalMiles), ffFixed, 18, 3);
      Edit8.Text := FloatToStrF(Convert(Edit2Float(Edit10), duFeet, duKiloFeet), ffFixed, 18, 3);
      Edit9.Text := FloatToStrF(Convert(Edit2Float(Edit10), duFeet, duMeters), ffFixed, 18, 3);
    end;
end;

procedure TFCalCon.FormShow(Sender: TObject);
begin
  Edit1.OnChange(Sender);
  Edit5.OnChange(Sender);
  Edit11.OnChange(Sender);
  Edit13.OnChange(Sender);
end;

procedure TFCalCon.RadioGroup3Click(Sender: TObject);
begin
  with RadioGroup3 do
    begin
      Edit11.Enabled := ItemIndex = 0;
      Edit12.Enabled := ItemIndex = 1;
    end;
end;

procedure TFCalCon.RadioGroup4Click(Sender: TObject);
begin
  with RadioGroup4 do
    begin
      Edit13.Enabled := ItemIndex = 0;
      Edit14.Enabled := ItemIndex = 1;
    end;
end;

procedure TFCalCon.Edit11Change(Sender: TObject);
begin
  if RadioGroup3.ItemIndex = 0 then
    Edit12.Text := FloatToStrF(Edit2Float(Edit11)*pi/180, ffFixed, 18, 3);
end;

procedure TFCalCon.Edit12Change(Sender: TObject);
begin
  if RadioGroup3.ItemIndex = 1 then
    Edit11.Text := FloatToStrF(Edit2Float(Edit12)*180/pi, ffFixed, 18, 3);
end;

procedure TFCalCon.Edit13Change(Sender: TObject);
var
  lin: real;
begin
  if RadioGroup4.ItemIndex = 0 then
    Edit14.Text := FloatToStrF(Power(10,Edit2Float(Edit13) / 10), ffFixed, 18, 3);
end;

procedure TFCalCon.Edit14Change(Sender: TObject);
begin
  if (RadioGroup4.ItemIndex = 1) and (Edit2Float(Edit14) > 0) then
    Edit13.Text := FloatToStrF(10*log10(Edit2Float(Edit14)), ffFixed, 18, 3);
end;

initialization
  duKiloFeet := RegisterConversionType(cbDistance, SKiloFeetDescription, MetersPerKiloFeet);
end.
