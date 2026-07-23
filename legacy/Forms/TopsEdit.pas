unit TopsEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  HorzEdit, StdCtrls, Area, Spin, Grids, ComCtrls,
  Measure;

type
  TFTopsEdit = class(TFHorzEdit)
    Label16: TLabel;
    Edit15: TEdit;
  //TabSheet4: TTabSheet;
    TrackBar1: TTrackBar;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    UpDown15: TUpDown;
    procedure UpDown15Click(Sender: TObject; Button: TUDBtnType);
    procedure UpDown3Click(Sender: TObject; Button: TUDBtnType);
  private
    function  GetMin      : TCode;
    function  GetLocation : integer;
    procedure SetMin( aMin : TCode );
    procedure SetLocation( aLocation : integer );
  public
    property Min      : TCode   read GetMin      write SetMin;
    property Location : integer read GetLocation write SetLocation;
  end;

var
  FTopsEdit: TFTopsEdit;

implementation

{$R *.DFM}

  function TFTopsEdit.GetMin : TCode;
  begin
    Result := UpDown15.Position;
  end;

  function TFTopsEdit.GetLocation : integer;
  begin
    Result := 100 - TrackBar1.Position; 
  end;

  procedure TFTopsEdit.SetMin( aMin : TCode );
  begin
    UpDown15.Position := aMin;
    Edit15.Text := FloatToStr( CodeMeasure( Min, Measure ) );
  end;

  procedure TFTopsEdit.SetLocation( aLocation : integer );
  begin
    TrackBar1.Position := 100 - aLocation;
  end;


// Component methods   

procedure TFTopsEdit.UpDown15Click(Sender: TObject; Button: TUDBtnType);
begin
  inherited;
  SetMin( (Sender as TUpDown).Position );
end;

procedure TFTopsEdit.UpDown3Click(Sender: TObject; Button: TUDBtnType);
begin
  inherited;
  SetMin( Min );
end;

end.
