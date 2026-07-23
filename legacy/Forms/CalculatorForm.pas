unit CalculatorForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Buttons;

type
  TFCalculator = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    ComboBoxStation: TComboBox;
    ComboBoxLoadRadarDefaults: TComboBox;
    PageControl3: TPageControl;
    TabSheet8: TTabSheet;
    TabSheet9: TTabSheet;
    GroupBox12: TGroupBox;
    Label16: TLabel;
    Edit15: TEdit;
    GroupBox13: TGroupBox;
    Label17: TLabel;
    Edit16: TEdit;
    GroupBox14: TGroupBox;
    Label18: TLabel;
    Edit17: TEdit;
    RadioGroup6: TRadioGroup;
    Edit18: TEdit;
    Edit19: TEdit;
    RadioGroup7: TRadioGroup;
    Edit20: TEdit;
    Edit21: TEdit;
    RadioGroup8: TRadioGroup;
    Edit22: TEdit;
    Edit23: TEdit;
    RadioGroup9: TRadioGroup;
    Edit24: TEdit;
    Edit25: TEdit;
    GroupBox15: TGroupBox;
    Label20: TLabel;
    Edit27: TEdit;
    TabSheet10: TTabSheet;
    GroupBox16: TGroupBox;
    RadioGroup10: TRadioGroup;
    RadioGroup11: TRadioGroup;
    RadioGroup12: TRadioGroup;
    RadioGroup13: TRadioGroup;
    Edit26: TEdit;
    Edit28: TEdit;
    Edit29: TEdit;
    Edit30: TEdit;
    Edit31: TEdit;
    Edit32: TEdit;
    Edit33: TEdit;
    Edit34: TEdit;
    GroupBox17: TGroupBox;
    GroupBox18: TGroupBox;
    Label19: TLabel;
    Edit35: TEdit;
    GroupBox19: TGroupBox;
    Label21: TLabel;
    Edit36: TEdit;
    RadioGroup14: TRadioGroup;
    GroupBox20: TGroupBox;
    Label22: TLabel;
    Edit37: TEdit;
    GroupBox21: TGroupBox;
    Label23: TLabel;
    Edit38: TEdit;
    GroupBox22: TGroupBox;
    GroupBox23: TGroupBox;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Edit39: TEdit;
    Edit40: TEdit;
    Edit41: TEdit;
    Edit42: TEdit;
    GroupBox24: TGroupBox;
    Label28: TLabel;
    Edit43: TEdit;
    GroupBox25: TGroupBox;
    Label29: TLabel;
    Edit44: TEdit;
    TabSheet11: TTabSheet;
    GroupBox26: TGroupBox;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Edit45: TEdit;
    Edit46: TEdit;
    Edit47: TEdit;
    Edit48: TEdit;
    DateTimePicker1: TDateTimePicker;
    DateTimePicker2: TDateTimePicker;
    GroupBox27: TGroupBox;
    Label36: TLabel;
    Label37: TLabel;
    Label38: TLabel;
    Label39: TLabel;
    Label40: TLabel;
    Label41: TLabel;
    Edit49: TEdit;
    Edit50: TEdit;
    Edit51: TEdit;
    Edit52: TEdit;
    DateTimePicker3: TDateTimePicker;
    DateTimePicker4: TDateTimePicker;
    TabSheet12: TTabSheet;
    GroupBox28: TGroupBox;
    Label42: TLabel;
    Label43: TLabel;
    Label44: TLabel;
    Label45: TLabel;
    Label46: TLabel;
    Label47: TLabel;
    Edit53: TEdit;
    Edit54: TEdit;
    Edit55: TEdit;
    Edit56: TEdit;
    DateTimePicker5: TDateTimePicker;
    DateTimePicker6: TDateTimePicker;
    GroupBox29: TGroupBox;
    Label48: TLabel;
    Label49: TLabel;
    Label50: TLabel;
    Label51: TLabel;
    Label52: TLabel;
    Label53: TLabel;
    Edit57: TEdit;
    Edit58: TEdit;
    Edit59: TEdit;
    Edit60: TEdit;
    DateTimePicker7: TDateTimePicker;
    DateTimePicker8: TDateTimePicker;
    GroupBox30: TGroupBox;
    Label55: TLabel;
    Edit62: TEdit;
    TabSheet13: TTabSheet;
    GroupBox31: TGroupBox;
    Label54: TLabel;
    Label56: TLabel;
    Label57: TLabel;
    Label58: TLabel;
    Label59: TLabel;
    Label60: TLabel;
    Edit61: TEdit;
    Edit63: TEdit;
    Edit64: TEdit;
    Edit65: TEdit;
    DateTimePicker9: TDateTimePicker;
    DateTimePicker10: TDateTimePicker;
    GroupBox32: TGroupBox;
    Label61: TLabel;
    Label62: TLabel;
    Label63: TLabel;
    Label64: TLabel;
    Label65: TLabel;
    Label66: TLabel;
    Edit66: TEdit;
    Edit67: TEdit;
    Edit68: TEdit;
    Edit69: TEdit;
    DateTimePicker11: TDateTimePicker;
    DateTimePicker12: TDateTimePicker;
    TabSheet14: TTabSheet;
    GroupBoxStation: TGroupBox;
    LabelLatitud: TLabel;
    LabelLongitud: TLabel;
    LabelHeight: TLabel;
    EditLatitud: TEdit;
    EditLongitud: TEdit;
    EditHeight: TEdit;
    GroupBoxPoint: TGroupBox;
    LabelLatitud3: TLabel;
    LabelLongitud3: TLabel;
    LabelHeight3: TLabel;
    EditLatitud3: TEdit;
    EditLongitud3: TEdit;
    EditHeight3: TEdit;
    GroupBox5: TGroupBox;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    RadioGroup3: TRadioGroup;
    RadioGroup4: TRadioGroup;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    GroupBox6: TGroupBox;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label3: TLabel;
    Edit9: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    ComboBox1: TComboBox;
    GroupBox10: TGroupBox;
    Label13: TLabel;
    Label14: TLabel;
    Edit12: TEdit;
    Edit13: TEdit;
    GroupBox11: TGroupBox;
    Label15: TLabel;
    Edit14: TEdit;
    BitBtn1: TBitBtn;
    GroupBox2: TGroupBox;
    Memo1: TMemo;
    procedure Freq_OnChange(Sender: TObject);
    procedure Wave_OnChange(Sender: TObject);
    procedure Dur_OnChange(Sender: TObject);
    procedure Ext_OnChange(Sender: TObject);
    procedure Prf_OnChange(Sender: TObject);
    procedure PrT_OnChange(Sender: TObject);
    procedure PeakPower_OnChange(Sender: TObject);
    procedure AverPower_OnChange(Sender: TObject);
    procedure AngleCellSize_OnChange(Sender: TObject);
    procedure TimeCellSize_OnChange(Sender: TObject);
    procedure RadioGroup_OnClick(Sender: TObject);
  private
    procedure EnableEdits(EditNames: array of TEdit; PassedItemIndex: Integer);
  public
    function Str2Float(S: string):Extended;
  end;

var
  FCalculator: TFCalculator = nil;

implementation

{$R *.dfm}

function TFCalculator.Str2Float;
begin
  if S = '' then Result := 0
  else Result := StrToFloat(S);
end;

procedure TFCalculator.Freq_OnChange(Sender: TObject);
var
  f      : real;   // Transmitter Frequency
  lambda : real;   // Transmitter Wavelength
const
  C = 30000000000;    // Speed of light in cm/s
begin
//  if RadioGroupFreq_Wave.ItemIndex = 0 then
  begin
//    f := Str2Float(EditFrequency.Text);
    if f <> 0 then
      begin
        lambda := C / (f * 1000000);
//        EditWaveLength.Text := FloatToStrF(lambda, ffFixed, 18, 2);
      end
//    else EditWaveLength.Text := '';
  end;
end;

procedure TFCalculator.Wave_OnChange(Sender: TObject);
var
  f      : real;    // Transmitter Frequency
  lambda : real;    // Transmitter Wavelength
const
  C = 30000000000;  // Speed of light in cm/s
begin
//  if RadioGroupFreq_Wave.ItemIndex = 1 then
  begin
//    lambda := Str2Float(EditWaveLength.Text);
    if lambda <> 0 then
      begin
        f := C / (lambda * 1000000);
 //       EditFrequency.Text := FloatToStrF(f, ffFixed, 18, 0);
      end
//    else EditFrequency.Text := '';
  end;
end;

//................Pulse Duration or Extension Input.............................
procedure TFCalculator.Dur_OnChange(Sender: TObject);
var
  tau   : real;   // Pulse Duration.
  h     : real;   // Pulse Extension.
const
  h_unary  = 300;   // Unary Pulse Extension in m.
begin
//  if RadioGroupDur_Ext.ItemIndex = 0 then
    begin
//      tau := Str2Float(EditPulseDuration.Text);
      if tau > 0 then
        begin
          h := h_unary * tau;
//          EditPulseExtension.Text := FloatToStrF(h, ffFixed, 18, 2);
        end
//        else EditPulseExtension.Text := '';
    end;
end;

procedure TFCalculator.Ext_OnChange(Sender: TObject);
var
  tau   : real;   // Pulse Duration
  h     : real;   // Pulse Extension
const
 h_unary  = 300; // Unary Pulse Extension in m.
begin
 //  if RadioGroupDur_Ext.ItemIndex = 1 then
   begin
//     h := Str2Float(EditPulseExtension.Text);
     if h > 0 then
       begin
         tau := h / h_unary ;
//         EditPulseDuration.Text := FloatToStrF(tau, ffFixed, 18, 3);
       end
//     else EditPulseDuration.Text := '';
   end;
end;

//.....................PRF or PRT Input.........................................
procedure TFCalculator.Prf_OnChange(Sender: TObject);
var
  prt   : real;   // Pulse Repetition Period
  prf   : real;   // Pulse Repetition Frequency
const
  sec2milisec  = 1000;   // conversion from seconds to miliseconds
begin
 // if RadioGroupPRF_PRT.ItemIndex = 0 then
  begin
 //   prf := Str2Float(EditPRF.Text);
    if prf <> 0 then
      begin
        prt := sec2milisec / prf ;
 //       EditPRT.Text := FloatToStrF(prt, ffFixed, 18, 2);
      end
 //   else EditPRT.Text := '';
  end;
end;

procedure TFCalculator.PrT_OnChange(Sender: TObject);
var
  prt   : real;   // Pulse Repetition Period
  prf   : real;   // Pulse Repetition Frequency
const
  sec2milisec  = 1000;   // conversion from seconds to miliseconds
begin
//  if RadioGroupPRF_PRT.ItemIndex = 1 then
  begin
 //    prt := Str2Float(EditPRT.Text);
     if prt <> 0 then
       begin
         prf := sec2milisec / prt ;
 //        EditPRF.Text := FloatToStrF(prf, ffFixed, 18, 2);
       end
 //    else EditPRF.Text := '';
  end;
end;
//...................Peak Power or Average Power Input..........................
procedure TFCalculator.PeakPower_OnChange(Sender: TObject);
var
  peakpower   : real;   // Peak Power
  averpower   : real;   // Average Power
  prt         : real;   // Pulse Repetition Period
  tau         : real;   // Pulse Duration
begin
 //  if RadioGroupPeak_Aver.ItemIndex = 0 then
   begin
//     prt := Str2Float(EditPRT.Text);
 //    tau := Str2Float(EditPulseDuration.Text);
 //    peakpower := Str2Float(EditPeakPower.Text);
     if (prt <> 0) and (tau <> 0) and (peakpower <> 0) then
       begin
         averpower := peakpower * (tau / prt);
//         EditAverPower.Text := FloatToStrF(averpower, ffFixed, 18, 2);
       end
 //    else EditAverPower.Text := '';
   end;
end;

procedure TFCalculator.AverPower_OnChange(Sender: TObject);
var
  peakpower   : real;   // Peak Power
  averpower   : real;   // Average Power
  prt         : real;   // Pulse Repetition Period
  tau         : real;   // Pulse Duration
begin
 // if RadioGroupPeak_Aver.ItemIndex = 1 then
    begin
//      prt := Str2Float(EditPRT.Text);
 //     tau := Str2Float(EditPulseDuration.Text);
 //     averpower := Str2Float(EditAverPower.Text);
      if (tau <> 0) and (prt <> 0) and (averpower <> 0) then
        begin
          peakpower := averpower * (prt / tau);
 //         EditPeakPower.Text := FloatToStrF(peakpower, ffFixed, 18, 2);
        end
//      else EditPeakPower.Text := '';
    end;
end;

procedure TFCalculator.RadioGroup_OnClick(Sender: TObject);
//var
// PassedItemIndex : Integer;
begin
{  PassedItemIndex := (Sender as TRadioGroup).ItemIndex;
  case (Sender as TComponent).Tag   of
    0: EnableEdits([EditFrequency, EditWaveLength],
                   PassedItemIndex);
    1: EnableEdits([EditPulseDuration, EditPulseExtension],
                   PassedItemIndex);
    2: EnableEdits([EditPRF, EditPRT],
                   PassedItemIndex);
    3: EnableEdits([EditPeakPower, EditAverPower],
                   PassedItemIndex);
    4: EnableEdits([EditAngleCellSize, EditTimeCellSize],
                   PassedItemIndex);
  {  5: EnableEdits([EditKm, EditMile, EditNautMile, EditFoot],
                   PassedItemIndex);
    6: EnableEdits([EditKmPerH, EditMilePerHour, EditKnot,EditMeterSeg],
                   PassedItemIndex);
    7: EnableEdits([EditLog, EditLin],
                   PassedItemIndex);
    8: EnableEdits([EditDegrees, EditRadians],
                   PassedItemIndex);
  end;}
end;
//............Cell width in angle or in number of pulses Input..................
procedure TFCalculator.AngleCellSize_OnChange(Sender: TObject);
//var
 //Angle  : Real;
 //Pulses : Real;
 //PRT    : Real;
 //Alpha  : Real;
begin
{  if RadioGroupAngleTimeCellSize.ItemIndex = 0 then
    begin
      Angle  := Str2Float(EditAngleCellSize.Text);
      PRT    := Str2Float(EditPRT.Text);
      Alpha  := 6 * Str2Float(EditSpeed.Text);
      if (PRT <> 0) and (Alpha <> 0) and (Angle <> 0) then
        begin
          Pulses := Trunc(Angle  / (Alpha * (PRT / 1000)));
          EditTimeCellSize.Text := FloatToStrF(Pulses, ffFixed, 18, 0);
        end
      else EditTimeCellSize.Text := '';
    end;
}end;

procedure TFCalculator.TimeCellSize_OnChange(Sender: TObject);
//var
  //Angle  : Real;
  //Pulses : Real;
  //PRT    : Real;
  //Alpha  : Real;
begin
{  if RadioGroupAngleTimeCellSize.ItemIndex = 1 then
    begin
      Pulses := Str2Float(EditTimeCellSize.Text);
      PRT    := Str2Float(EditPRT.Text);
      Alpha  := 6 * Str2Float(EditSpeed.Text);
      if (Pulses <> 0) and (PRT <> 0) and (Alpha <> 0) then
        begin
          Angle  := Pulses * Alpha * (PRT / 1000);
          EditAngleCellSize.Text := FloatToStrF(Angle, ffFixed, 18, 3);
        end
      else  EditAngleCellSize.Text := '';
    end;
}end;
//.......Enabling and Disabling mutually exclusive Edits in RadioGroups.........
procedure TFCalculator.EnableEdits;
begin
  case  PassedItemIndex of
   0: begin
        EditNames[0].Enabled  := true;
        EditNames[1].Enabled  := false;
        if High(EditNames) > 1 then
          begin
            EditNames[2].Enabled  := false;
            EditNames[3].Enabled  := false;
          end;
      end;
   1: begin
        EditNames[0].Enabled  := false;
        EditNames[1].Enabled  := true;
        if High(EditNames) > 1 then
          begin
            EditNames[2].Enabled  := false;
            EditNames[3].Enabled  := false;
          end;
      end;
   2: begin
        EditNames[0].Enabled  := false;
        EditNames[1].Enabled  := false;
        EditNames[2].Enabled  := true;
        EditNames[3].Enabled  := false;
      end;
   3: begin
        EditNames[0].Enabled  := false;
        EditNames[1].Enabled  := false;
        EditNames[2].Enabled  := false;
        EditNames[3].Enabled  := true;
      end;
  end;
end;

end.
