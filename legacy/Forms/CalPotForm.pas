unit CalPotForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons;

type
  TFCalPot = class(TForm)
    GroupBox5: TGroupBox;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    RadioGroup3: TRadioGroup;
    RadioGroup4: TRadioGroup;
    Edit5: TEdit;
    Edit6: TEdit;
    GroupBox2: TGroupBox;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    ComboBox1: TComboBox;
    Panel1: TPanel;
    GroupBox10: TGroupBox;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    GroupBox6: TGroupBox;
    Label11: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit10: TEdit;
    Edit12: TEdit;
    Edit13: TEdit;
    Edit14: TEdit;
    Label2: TLabel;
    Edit15: TEdit;
    Label3: TLabel;
    Edit9: TEdit;
    LabelMinDiscSignal: TLabel;
    procedure RadioGroup3Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RadioGroup4Click(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure RadioGroup2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure Edit3Change(Sender: TObject);
    procedure Edit4Change(Sender: TObject);
    procedure Edit5Change(Sender: TObject);
    procedure Edit6Change(Sender: TObject);
    procedure Edit7Change(Sender: TObject);
    procedure Edit8Change(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth,
      NewHeight: Integer; var Resize: Boolean);
    procedure Edit9Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FCalPot: TFCalPot;

implementation

{$R *.dfm}

uses
  Radars, Description, CalcFunctions;

procedure TFCalPot.RadioGroup1Click(Sender: TObject);
begin
  Edit1.Enabled := RadioGroup1.ItemIndex = 0;
  Edit2.Enabled := not Edit1.Enabled;
end;

procedure TFCalPot.RadioGroup2Click(Sender: TObject);
begin
  Edit3.Enabled := RadioGroup2.ItemIndex = 0;
  Edit4.Enabled := not Edit3.Enabled;
end;

procedure TFCalPot.RadioGroup3Click(Sender: TObject);
begin
  Edit5.Enabled := RadioGroup3.ItemIndex = 0;
  Edit6.Enabled := not Edit5.Enabled;
end;

procedure TFCalPot.RadioGroup4Click(Sender: TObject);
begin
  Edit7.Enabled := RadioGroup4.ItemIndex = 0;
  Edit8.Enabled := not Edit7.Enabled;
end;

procedure TFCalPot.FormShow(Sender: TObject);
begin
  ComboBox1Change(Sender);
  RadioGroup1Click(Sender);
  RadioGroup2Click(Sender);
  RadioGroup3Click(Sender);
  RadioGroup4Click(Sender);
  Edit9Change(Sender);
end;

procedure TFCalPot.FormCreate(Sender: TObject);
var
  i: TRadar;
begin
  with ComboBox1 do
    begin
      Items.Clear;
      for i:= rdLaBajada to rdGranPiedra do
        Items.Add(Find(i).Name);
      ItemIndex := 4;
    end;
end;

procedure TFCalPot.ComboBox1Change(Sender: TObject);
begin
  with NominalParams(Find(TRadar(ComboBox1.ItemIndex + 1)).Brand) do
    begin
      Edit1. Text := FloatToStrF(Tx. Frecuency,         ffFixed, 18, 0);
      Edit2. Text := FloatToStrF(Tx. Wavelength,        ffFixed, 18, 2);
      Edit3. Text := FloatToStrF(Tx. PulseRepFrecuency, ffFixed, 18, 2);
      Edit4. Text := FloatToStrF(Tx. PulseRepPeriod,    ffFixed, 18, 2);
      Edit5. Text := FloatToStrF(Tx. PeakPower,         ffFixed, 18, 2);
      Edit6. Text := FloatToStrF(Tx. AvePower,          ffFixed, 18, 2);
      Edit7. Text := FloatToStrF(Tx. PulseDuration,     ffFixed, 18, 3);
      Edit8. Text := FloatToStrF(Tx. PulseExtension,    ffFixed, 18, 2);
      Edit9. Text := FloatToStrF(Rx. MinDiscSignal,     ffFixed, 18, 0);
      Edit10.Text := FloatToStrF(Rx. BandWidth,         ffFixed, 18, 2);
      Edit12.Text := FloatToStrF(Ant.Gain,              ffFixed, 18, 1);
      Edit13.Text := FloatToStrF(Ant.BeamWidth,         ffFixed, 18, 1);
      Edit14.Text := FloatToStrF(Ant.Losses,            ffFixed, 18, 1);
    end;
  Edit9Change(Sender);
end;

procedure TFCalPot.Edit1Change(Sender: TObject);
begin
  if RadioGroup1.ItemIndex = 0 then
    Edit2.Text := FloatToStrF(Frecuency2Wavelength(Edit2Float(Edit1)), ffFixed, 18, 2);
  Edit9Change(Sender);
end;

procedure TFCalPot.Edit2Change(Sender: TObject);
begin
  if RadioGroup1.ItemIndex = 1 then
    Edit1.Text := FloatToStrF(Wavelength2Frecuency(Edit2Float(Edit2)), ffFixed, 18, 0);
  Edit9Change(Sender);
end;

procedure TFCalPot.Edit3Change(Sender: TObject);
begin
  if RadioGroup2.ItemIndex = 0 then
    begin
      Edit4.Text := FloatToStrF(PulseRepFrecuency2Period(Edit2Float(Edit3)), ffFixed, 18, 2);
    end;
  Edit9Change(Sender);
end;

procedure TFCalPot.Edit4Change(Sender: TObject);
begin
  if RadioGroup2.ItemIndex = 1 then
    begin
      Edit3.Text := FloatToStrF(PulseRepPeriod2Frecuency(Edit2Float(Edit4)), ffFixed, 18, 2);
    end;
  Edit9Change(Sender);
end;

procedure TFCalPot.Edit5Change(Sender: TObject);
begin
  if RadioGroup3.ItemIndex = 0 then
    Edit6.Text := FloatToStrF(PeakPower2Ave(Edit2Float(Edit4), Edit2Float(Edit7), Edit2Float(Edit5)), ffFixed, 18, 2);
  Edit9Change(Sender);
end;

procedure TFCalPot.Edit6Change(Sender: TObject);
begin
  if RadioGroup3.ItemIndex = 1 then
    Edit5.Text := FloatToStrF(AvePower2Peak(Edit2Float(Edit4), Edit2Float(Edit7), Edit2Float(Edit6)), ffFixed, 18, 2);
  Edit9Change(Sender);
end;

procedure TFCalPot.Edit7Change(Sender: TObject);
begin
  if RadioGroup4.ItemIndex = 0 then
    begin
      Edit8.Text := FloatToStrF(PulseDuration2Extension(Edit2Float(Edit7)), ffFixed, 18, 2);
    end;
  Edit9Change(Sender);
end;

procedure TFCalPot.Edit8Change(Sender: TObject);
begin
  if RadioGroup4.ItemIndex = 1 then
    begin
      Edit7.Text := FloatToStrF(PulseExtension2Duration(Edit2Float(Edit8)), ffFixed, 18, 3);
    end;
  Edit9Change(Sender);
end;

procedure TFCalPot.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  Resize := false;
end;

procedure TFCalPot.Edit9Change(Sender: TObject);
begin
  Edit15.Text := FloatToStrF(MetPotential(Edit2Float(Edit2), Edit2Float(Edit8), Edit2Float(Edit13),
                                          Edit2Float(Edit5), Edit2Float(Edit12), Edit2Float(Edit14),
                                          Edit2Float(Edit10), Edit2Float(Edit9)), ffFixed, 18, 2);
end;

end.
