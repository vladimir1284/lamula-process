unit VolumeEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  VertEdit, Area, StdCtrls, Spin, Grids, ComCtrls;

type
  TFVolumeEdit = class(TFVertEdit)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FVolumeEdit: TFVolumeEdit = nil;

implementation

{$R *.DFM}

end.
