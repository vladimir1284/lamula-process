unit Raw_Parameters;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls;

type
  TFRaw_Parameters = class(TForm)
    Panel1: TPanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label1: TLabel;
    ComboBox1: TComboBox;
    Label5: TLabel;
    Edit2: TEdit;
    Label6: TLabel;
    Edit3: TEdit;
    Label7: TLabel;
    Edit4: TEdit;
    Label8: TLabel;
    Edit5: TEdit;
    Label9: TLabel;
    Label10: TLabel;
    Edit6: TEdit;
    Edit7: TEdit;
    Label11: TLabel;
    Edit8: TEdit;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Button1: TButton;
    Button2: TButton;
    UpDown1: TUpDown;
    MonthCalendar1: TMonthCalendar;
    DateTimePicker1: TDateTimePicker;
    ComboBox2: TComboBox;
    Label2: TLabel;
    TabSheet3: TTabSheet;
    Label17: TLabel;
    ComboBox6: TComboBox;
    Label3: TLabel;
    Edit1: TEdit;
    Label4: TLabel;
    Edit9: TEdit;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FRaw_Parameters: TFRaw_Parameters;

implementation

uses
  Measure,
  Description,
  Radars,
  Configuration;

{$R *.dfm}

procedure TFRaw_Parameters.FormCreate(Sender: TObject);
var
  R : TRadar;
  M : TMeasure;
begin
  ComboBox1.Items.Clear;
  for R := Low(TRadar) to High(TRadar) do
    ComboBox1.Items.Add(Find(R).Name);
  with theConfiguration do
    begin
      ComboBox1.ItemIndex := Raw_Radar;
      ComboBox2.ItemIndex := Raw_Wavelength;
      UpDown1.Position    := Raw_PPIs;
      Edit3.Text          := Raw_Angles;
      Edit4.Text          := IntToStr(Raw_Cells);
      Edit6.Text          := IntToStr(Raw_Sectors);
      Edit5.Text          := IntToStr(Raw_Size);
      Edit7.Text          := FloatToStr(Raw_Beam);
      Edit8.Text          := FloatToStr(Raw_PotMet);
      ComboBox2.ItemIndex := Raw_Variable;
      Edit1.Text          := FloatToStr(Raw_Slope);
      Edit9.Text          := FloatToStr(Raw_Offset);
    end;
  ComboBox6.Items.Clear;
  for M := Low(TMeasure) to High(TMeasure) do
    ComboBox6.Items.AddObject(MeasureVar(M) + ' [' + MeasureName(M) + ']', pointer(M));
  ComboBox6.ItemIndex := ord(unDBZ);
  PageControl1.ActivePage := TabSheet1;
end;

procedure TFRaw_Parameters.CheckBox1Click(Sender: TObject);
begin
  with Sender as TCheckBox do
    begin
      Label3.   Enabled := not Checked;
      Label4.   Enabled := not Checked;
      Edit1.    Enabled := not Checked;
      Edit9.    Enabled := not Checked;
      CheckBox2.Enabled := not Checked;
    end;
end;

procedure TFRaw_Parameters.Button1Click(Sender: TObject);
begin
  with theConfiguration do
    begin
      Raw_Radar      := ComboBox1.ItemIndex;
      Raw_Wavelength := ComboBox2.ItemIndex;
      Raw_PPIs       := UpDown1.Position;
      Raw_Angles     := Edit3.Text;
      Raw_Cells      := StrToInt(Edit4.Text);
      Raw_Sectors    := StrToInt(Edit6.Text);
      Raw_Size       := StrToInt(Edit5.Text);
      Raw_Beam       := StrToFloat(Edit7.Text);
      Raw_PotMet     := StrToFloat(Edit8.Text);
      Raw_Variable   := ComboBox2.ItemIndex;
      Raw_Slope      := StrToFloat(Edit1.Text);
      Raw_Offset     := StrToFloat(Edit9.Text);
    end;
end;

end.

