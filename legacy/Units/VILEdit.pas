unit VILEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  HorzEdit, Area, StdCtrls, ComCtrls, Grids;

type
  TFVILEdit = class(TFHorzEdit)
    Label16: TLabel;
    Label17: TLabel;
    Edit7: TEdit;
    Edit10: TEdit;
  private
    function  GetC1 : double;
    function  GetC2 : double;
    procedure SetC1( C : double );
    procedure SetC2( C : double );
  public
    property C1 : double read GetC1 write SetC1;
    property C2 : double read GetC2 write SetC2;
  end;

var
  FVILEdit: TFVILEdit;

implementation

{$R *.DFM}

  function TFVILEdit.GetC1 : double;
  begin
    try
      Result := StrToFloat( Edit7.Text );
    except
      on EConvertError do
        begin
          Edit7.Text := '0.00524';
          Result := 0.00524;
        end;
    end;
  end;

  function TFVILEdit.GetC2 : double;
  begin
    try
      Result := StrToFloat( Edit10.Text );
    except
      on EConvertError do
        begin
          Edit10.Text := '0.57143';
          Result := 0.57143;
        end;
    end;
  end;

  procedure TFVILEdit.SetC1( C : double );
  begin
    Edit7.Text := FloatToStr( C );
  end;

  procedure TFVILEdit.SetC2( C : double );
  begin
    Edit10.Text := FloatToStr( C );
  end;

end.

