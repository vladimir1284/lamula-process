unit GapForm;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Spin, ExtCtrls, ComCtrls;

type
  TFGapColor = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Label2: TLabel;
    Label1: TLabel;
    ColorDialog1: TColorDialog;
    Label3: TLabel;
    Label5: TLabel;
    Label4: TLabel;
    UpDown1: TUpDown;
    UpDown2: TUpDown;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    Edit2: TEdit;
    procedure Panel2Click(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
  private
    function  GetGap : TPoint;
    procedure SetGap( aGap : TPoint );
    function  GetColor : TColor;
    procedure SetColor( aColor : TColor );
  public
    property Gap   : TPoint read GetGap   write SetGap;
    property Color : TColor read GetColor write SetColor;
  end;

//var
//  FGapColor: TFGapColor;

implementation

{$R *.DFM}

function TFGapColor.GetGap : TPoint;
begin
  Result.X := UpDown1.Position;
  Result.Y := UpDown2.Position;
end;

procedure TFGapColor.SetGap( aGap : TPoint );
begin
  UpDown1.Position := aGap.X;
  UpDown2.Position := aGap.Y;
end;

function TFGapColor.GetColor : TColor;
begin
  Result := Panel2.Color;
end;

procedure TFGapColor.SetColor( aColor : TColor );
begin
  Panel2.Color := aColor;
end;

procedure TFGapColor.Panel2Click(Sender: TObject);
begin
  with Sender as TPanel do
    begin
      BevelOuter := bvLowered;
      ColorDialog1.Color := Color;
      if ColorDialog1.Execute
        then Color := ColorDialog1.Color;
      BevelOuter := bvRaised;
    end;
end;

procedure TFGapColor.Edit1Change(Sender: TObject);
begin
  if CheckBox1.Checked
    then Edit2.Text := Edit1.Text;
end;

procedure TFGapColor.CheckBox1Click(Sender: TObject);
begin
  Edit2.Enabled   := not CheckBox1.Checked;
  UpDown2.Enabled := Edit2.Enabled;
end;

end.

