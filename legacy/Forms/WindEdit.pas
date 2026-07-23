unit WindEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, HorzEdit, Area, ComCtrls, StdCtrls, Grids;

type
  TFWindEdit = class(TFHorzEdit)
    TabSheet3: TTabSheet;
    TrackBar1: TTrackBar;
    Edit7: TEdit;
    UpDown2: TUpDown;
    Label2: TLabel;
    Edit10: TEdit;
    UpDown3: TUpDown;
    Label12: TLabel;
  private
    function  GetWindHeight: integer;
    function  GetdHeight: single;
    procedure SetWindHeight( aWindHeight : integer );
    procedure SetdHeight( adHeight: single);
  public
    property WindHeight : integer read GetWindHeight write SetWindHeight;
    property dWindHeight : single read GetdHeight write SetdHeight;
  end;

var
  FWindEdit: TFWindEdit = nil;

implementation

{$R *.dfm}

function TFWindEdit.GetWindHeight;
begin
  result := UpDown2.Position;
end;

procedure TFWindEdit.SetWindHeight;
begin
  UpDown2.Position := aWindHeight;
end;

function TFWindEdit.GetdHeight;
begin
  result := UpDown3.Position/2;
end;

procedure TFWindEdit.SetdHeight;
begin
  UpDown3.Position := round(adHeight * 2);
end;

end.
