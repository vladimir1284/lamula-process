unit CircleEditForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, GapForm, StdCtrls, ComCtrls, ExtCtrls, GridForm;

type
  TFCircleEdit = class(TFGapColor)
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Edit3: TEdit;
    UpDown3: TUpDown;
    Label10: TLabel;
    Label11: TLabel;
    AllCircles: TCheckBox;
    CheckBox2: TCheckBox;
    Label12: TLabel;
    ComboBox1: TComboBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    GroupBox1: TGroupBox;
    CheckBox6: TCheckBox;
    ComboBox2: TComboBox;
    Label13: TLabel;
    Label14: TLabel;
    procedure ComboBox1Change(Sender: TObject);
    procedure ComboBox1DropDown(Sender: TObject);
    procedure CheckBox6Click(Sender: TObject);
  private
    fLastCir: integer;
    function GetRadio: integer;
    procedure SetRadio(aRadio: integer);
    function GetShowCenter: boolean;
    procedure SetShowCenter(aBool: boolean);
    function GetShowCir: boolean;
    procedure SetShowCir(aBool: boolean);
    function GetShowNumber: boolean;
    procedure SetShowNumber(aBool: boolean);
    function GetShowRad: boolean;
    procedure SetShowRad(aBool: boolean);
    function GetUseOther: boolean;
    procedure SetUseOther(aBool: boolean);
    function GetOther: integer;
    procedure SetOther(aCirc: integer);
  public
    property Radio: integer read GetRadio write SetRadio;
    property ShowCenter: boolean read GetShowCenter write SetShowCenter;
    property ShowCir: boolean read GetShowCir write SetShowCir;
    property ShowNumber: boolean read GetShowNumber write SetShowNumber;
    property ShowRad: boolean read GetShowRad write SetShowRad;
    property UseOther: boolean read GetUseOther write SetUseOther;
    property Other: integer read GetOther write SetOther;
  end;

var
  FCircleEdit: TFCircleEdit;

implementation

{$R *.dfm}

function TFCircleEdit.GetRadio;
begin
  Result := UpDown3.Position;
end;

procedure TFCircleEdit.SetRadio(aRadio: integer);
begin
  UpDown3.Position := aRadio;
end;

function TFCircleEdit.GetShowCenter: boolean;
begin
  Result := CheckBox2.Checked;
end;

procedure TFCircleEdit.SetShowCenter(aBool: boolean);
begin
  CheckBox2.Checked := aBool;
end;

function TFCircleEdit.GetShowCir: boolean;
begin
  Result := CheckBox3.Checked;
end;

procedure TFCircleEdit.SetShowCir(aBool: boolean);
begin
  CheckBox3.Checked := aBool;
end;

function TFCircleEdit.GetShowNumber: boolean;
begin
  Result := CheckBox4.Checked;
end;

procedure TFCircleEdit.SetShowNumber(aBool: boolean);
begin
  CheckBox4.Checked := aBool;
end;

function TFCircleEdit.GetShowRad: boolean;
begin
  Result := CheckBox5.Checked;
end;

procedure TFCircleEdit.SetShowRad(aBool: boolean);
begin
  CheckBox5.Checked := aBool;
end;

function TFCircleEdit.GetUseOther: boolean;
begin
  Result := CheckBox6.Checked;
end;

procedure TFCircleEdit.SetUseOther(aBool: boolean);
begin
  CheckBox6.Checked := aBool;
end;

function TFCircleEdit.GetOther: integer;
begin
  Result := ComboBox2.ItemIndex;
end;

procedure TFCircleEdit.SetOther;
begin
  ComboBox2.ItemIndex := aCirc;
end;

procedure TFCircleEdit.ComboBox1Change(Sender: TObject);
begin
  Gap        := TFGrid(Owner).fCirCenter[ComboBox1.ItemIndex];
  Color      := TFGrid(Owner).fCirColor[ComboBox1.ItemIndex];
  Radio      := TFGrid(Owner).fCirRad[ComboBox1.ItemIndex];
  ShowCenter := TFGrid(Owner).fCirShowCenter[ComboBox1.ItemIndex];
  ShowCir    := TFGrid(Owner).fCirShow[ComboBox1.ItemIndex];
  ShowNumber := TFGrid(Owner).fCirShowNumber[Combobox1.ItemIndex];
  ShowRad    := TFGrid(Owner).fCirShowRad[Combobox1.ItemIndex];
  UseOther   := TFGrid(Owner).fCirUseOther[Combobox1.ItemIndex];
  Other      := TFGrid(Owner).fCirOther[Combobox1.ItemIndex];
  CheckBox6Click(Sender);
end;

procedure TFCircleEdit.ComboBox1DropDown(Sender: TObject);
begin
  TFGrid(Owner).fCirCenter[ComboBox1.ItemIndex] := Gap;
  TFGrid(Owner).fCirColor[ComboBox1.ItemIndex] := Color;
  TFGrid(Owner).fCirRad[ComboBox1.ItemIndex] := Radio;
  TFGrid(Owner).fCirShowCenter[ComboBox1.ItemIndex] := ShowCenter;
  TFGrid(Owner).fCirShow[ComboBox1.ItemIndex] := ShowCir;
  TFGrid(Owner).fCirShowNumber[Combobox1.ItemIndex] := ShowNumber;
  TFGrid(Owner).fCirShowRad[Combobox1.ItemIndex] := ShowRad;
  TFGrid(Owner).fCirUseOther[Combobox1.ItemIndex] := UseOther;
  TFGrid(Owner).fCirOther[Combobox1.ItemIndex] := Other;
end;

procedure TFCircleEdit.CheckBox6Click(Sender: TObject);
begin
  ComboBox2.Enabled := CheckBox6.Checked;
  Edit1.Enabled := not ComboBox2.Enabled;
  Edit2.Enabled := not ComboBox2.Enabled;
end;

end.
