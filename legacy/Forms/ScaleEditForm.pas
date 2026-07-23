unit ScaleEditForm;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, Spin, StdCtrls,
  Measure, ComCtrls, ExtCtrls;

type
  TFScaleEdit = class(TForm)
    Button1: TButton;
    Button2: TButton;
    ColorDialog1: TColorDialog;
    Label1: TLabel;
    Label2: TLabel;
    Panel1: TPanel;
    Edit1: TEdit;
    Edit2: TEdit;
    UpDown1: TUpDown;
    procedure Panel1Click(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
  public
    ScaleMeasure : TMeasure;
    procedure DrawValue;
  end;

//var
//  FScaleEdit: TFScaleEdit;

implementation

{$R *.DFM}

procedure TFScaleEdit.DrawValue;
begin
  Edit2.Text := FloatToStr( CodeMeasure( UpDown1.Position, ScaleMeasure ) ) +
                ' ' + MeasureName( ScaleMeasure );
end;

procedure TFScaleEdit.Panel1Click(Sender: TObject);
begin
  with ColorDialog1 do
    begin
      Color := Panel1.Color;
      if Execute
        then Panel1.Color := Color;
    end;
end;

procedure TFScaleEdit.Edit2Change(Sender: TObject);
begin
  DrawValue;
end;

end.

