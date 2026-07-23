unit ContributionEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  HorzEdit, Area, StdCtrls, Spin, Grids, ComCtrls;

type
  TFContributionEdit = class(TFHorzEdit)
    TabSheet4: TTabSheet;
    Label17: TLabel;
    Label18: TLabel;
    Edit12: TEdit;
    UpDown12: TUpDown;
    Label24: TLabel;
  private
    function  GetInterval : TDateTime;
    procedure SetInterval( V : TDateTime );
  public
    property Interval : TDateTime read GetInterval write SetInterval;
  end;

var
  FContributionEdit: TFContributionEdit = nil;

implementation

{$R *.DFM}


  function TFContributionEdit.GetInterval : TDateTime;
  begin
    Result := UpDown12.Position/(24 * 60);
  end;

  procedure TFContributionEdit.SetInterval( V : TDateTime );
  begin
    UpDown12.Position := round(V * 24 * 60);
  end;

end.
