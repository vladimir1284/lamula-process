unit CalRefForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TFCalRef = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    ComboBox1: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    GroupBox3: TGroupBox;
    Label4: TLabel;
    Edit4: TEdit;
    Label5: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    procedure FormCanResize(Sender: TObject; var NewWidth,
      NewHeight: Integer; var Resize: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FCalRef: TFCalRef;

implementation

{$R *.dfm}

uses
  Radars, Description, CalcFunctions;

procedure TFCalRef.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  Resize := false;
end;

procedure TFCalRef.FormCreate(Sender: TObject);
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
  ComboBox1Change(Sender);
end;

procedure TFCalRef.ComboBox1Change(Sender: TObject);
begin
  with NominalParams(Find(TRadar(ComboBox1.ItemIndex + 1)).Brand) do
    Edit1. Text := FloatToStrF(MetPotential(Tx. Wavelength, Tx.PulseExtension, Ant.BeamWidth, Tx.PeakPower, Ant.Gain, Ant.Losses, Rx.BandWidth, Rx.MinDiscSignal), ffFixed, 18, 2);
end;

procedure TFCalRef.Edit1Change(Sender: TObject);
begin
  Edit4.Text := FloatToStrF(Reflectivity(Edit2Float(Edit1), Edit2Float(Edit2), Edit2Float(Edit3)), ffFixed, 18, 2);
end;

end.
