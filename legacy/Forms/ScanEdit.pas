unit ScanEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  EditForm, StdCtrls, Spin, Area, Grids, ComCtrls;

type
  TFScanEdit = class(TFEdit)
    Label7: TLabel;
    Label9: TLabel;
    Label8: TLabel;
    Label10: TLabel;
    SpinEdit9: TSpinEdit;
    SpinEdit8: TSpinEdit;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label15: TLabel;
    procedure SpinEdit8Change(Sender: TObject);
    procedure SpinEdit9Change(Sender: TObject);
    procedure StringGrid1SelectCell(Sender: TObject; Col, Row: Longint;
      var CanSelect: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FScanEdit: TFScanEdit;

implementation

{$R *.DFM}

procedure TFScanEdit.SpinEdit8Change(Sender: TObject);
begin
  inherited;
  if SpinEdit9.Value < (Sender as TSpinEdit).Value
    then SpinEdit9.Value := (Sender as TSpinEdit).Value;
end;

procedure TFScanEdit.SpinEdit9Change(Sender: TObject);
begin
  inherited;
  if SpinEdit8.Value > (Sender as TSpinEdit).Value
    then SpinEdit8.Value := (Sender as TSpinEdit).Value;
end;

procedure TFScanEdit.StringGrid1SelectCell(Sender: TObject; Col,
  Row: Longint; var CanSelect: Boolean);
begin
  inherited;
  if CanSelect
    then
      with Observation.Channel[Row - 1], Area1 do
        begin
          MaxEast  := (Cells - 1) * Length div 1000;
          MaxWest  := (1 - Cells) * Length div 1000;
          MaxNorth := (Cells - 1) * Length div 1000;
          MaxSouth := (1 - Cells) * Length div 1000;
          SpinEdit2.MinValue := MaxWest;
          SpinEdit2.MaxValue := MaxEast;
          SpinEdit3.MinValue := MaxSouth;
          SpinEdit3.MaxValue := MaxNorth;
          SpinEdit4.MinValue := MaxWest;
          SpinEdit4.MaxValue := MaxEast;
          SpinEdit5.MinValue := MaxSouth;
          SpinEdit5.MaxValue := MaxNorth;
        end;
end;

end.
