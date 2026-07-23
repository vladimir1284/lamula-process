unit AccumulateEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  HorzEdit, Area, StdCtrls, ComCtrls, Grids,
  Measure;

type
  TFAccumulateEdit = class(TFHorzEdit)
    TabSheet4: TTabSheet;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Edit10: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit13: TEdit;
    Label22: TLabel;
    Edit7: TEdit;
    UpDown12: TUpDown;
    Label23: TLabel;
    Label21: TLabel;
    Label24: TLabel;
  private
    function  GetInterval  : TDateTime;
    function  GetStartTime : TDateTime;
    function  GetStopTime  : TDateTime;
    procedure SetInterval ( DT : TDateTime );
    procedure SetStartTime( DT : TDateTime );
    procedure SetStopTime ( DT : TDateTime );
  public
    property Interval  : TDateTime read GetInterval  write SetInterval;
    property StartTime : TDateTime read GetStartTime write SetStartTime;
    property StopTime  : TDateTime read GetStopTime  write SetStopTime;
  end;

var
  FAccumulateEdit: TFAccumulateEdit = nil;

implementation

{$R *.DFM}


  function TFAccumulateEdit.GetInterval : TDateTime;
  begin
    Result := EncodeTime( 0, UpDown12.Position, 0, 0 );
  end;

  function TFAccumulateEdit.GetStartTime : TDateTime;
  begin
    Result := StrToDate( Edit10.Text ) + StrToTime( Edit12.Text );
  end;

  function TFAccumulateEdit.GetStopTime : TDateTime;
  begin
    Result := StrToDate( Edit11.Text ) + StrToTime( Edit13.Text );
  end;

  procedure TFAccumulateEdit.SetInterval( DT : TDateTime );
  var
    M : integer;
  begin
    M := round(DT * 24 * 60);
    Edit7.Text := IntToStr( M );
    UpDown12.Position := M;
  end;

  procedure TFAccumulateEdit.SetStartTime( DT : TDateTime );
  begin
    Edit10.Text := DateToStr( DT );
    Edit12.Text := TimeToStr( DT );
  end;

  procedure TFAccumulateEdit.SetStopTime( DT : TDateTime );
  begin
    Edit11.Text := DateToStr( DT );
    Edit13.Text := TimeToStr( DT );
  end;

// Component methods

end.
