unit VestaChildForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

type
  TFVestaChild = class(TForm)
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
  private
    fZoomed : boolean;
    fNormal : TRect;
  public
    procedure DoZoom;
    procedure UnZoom;
  published
    property Zoomed : boolean read fZoomed;
  end;

//var
//  FVestaChild: TFVestaChild;

implementation

{$R *.DFM}

  procedure TFVestaChild.DoZoom;
  begin
    fNormal := BoundsRect;
    with Application.MainForm do
      Self.SetBounds( 0, 0, ClientWidth, ClientHeight - 32 );
    fZoomed := true;
  end;

  procedure TFVestaChild.UnZoom;
  begin
    with fNormal do
      SetBounds( Left, Top, Right - Left, Bottom - Top );
    fZoomed := false;
  end;

procedure TFVestaChild.FormActivate(Sender: TObject);
begin
  if assigned(Menu)
    then Application.MainForm.Menu.Merge( Menu );
end;

procedure TFVestaChild.FormDeactivate(Sender: TObject);
begin
  if assigned(Menu)
    then Application.MainForm.Menu.UnMerge( Menu );
end;

end.
