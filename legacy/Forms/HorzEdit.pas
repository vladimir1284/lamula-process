unit HorzEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  EditForm, StdCtrls, Spin, Area, Grids, ComCtrls;

type
  TFHorzEdit = class(TFEdit)
    Label7: TLabel;
    Label9: TLabel;
    Label8: TLabel;
    Label10: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label15: TLabel;
    Edit1: TEdit;
    UpDown10: TUpDown;
    Edit2: TEdit;
    UpDown11: TUpDown;
    procedure UpDown10Click(Sender: TObject; Button: TUDBtnType);
    procedure UpDown11Click(Sender: TObject; Button: TUDBtnType);
  private
    function  GetBottom: integer;
    function  GetTop   : integer;
    procedure SetBottom(V: integer);
    procedure SetTop   (V: integer);
  public
    property Bottom: integer read GetBottom write SetBottom;
    property Top   : integer read GetTop    write SetTop;
  end;

var
  FHorzEdit: TFHorzEdit;

implementation

{$R *.DFM}

uses
  RadarData;

// TFHorzEdit

function TFHorzEdit.GetBottom: integer;
begin
  Result := UpDown10.Position;
end;

function TFHorzEdit.GetTop: integer;
begin
  Result := UpDown11.Position;
end;

procedure TFHorzEdit.SetBottom(V: integer);
begin
  UpDown10.Position := V;
  UpDown11.Min := UpDown10.Position;
end;

procedure TFHorzEdit.SetTop(V: integer);
begin
  UpDown11.Position := V;
  UpDown10.Max := UpDown11.Position;
end;

// Component methods

procedure TFHorzEdit.UpDown10Click(Sender: TObject; Button: TUDBtnType);
begin
  inherited;
  SetBottom(UpDown10.Position);
end;

procedure TFHorzEdit.UpDown11Click(Sender: TObject; Button: TUDBtnType);
begin
  inherited;
  SetTop(UpDown11.Position);
end;

end.
