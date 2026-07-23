unit TopDownEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  HorzEdit, Area, StdCtrls, Spin, Grids, ComCtrls;

type
  TFTopDownEdit = class(TFHorzEdit)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FTopDownEdit: TFTopDownEdit = nil;

implementation

{$R *.DFM}

end.
