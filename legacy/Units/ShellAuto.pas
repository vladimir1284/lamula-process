unit ShellAuto;

interface

{$WARN UNIT_DEPRECATED OFF}

uses
  OleAuto;

type
  TShellAuto = class(TAutoObject)
  automated
    procedure Close;
    procedure Minimize;
    procedure Restore;
    procedure Maximize;
  automated
    function Open( const FileName : string ) : variant;
    function NewTimeSpan                     : variant;
    function NewEnsemble                     : variant;
    procedure Tile;
  end;

implementation

uses
  Forms, SysUtils,
  TimeSpan, Ensemble,
  Shell_Process, ObservationForm;

// TShellAuto methods

procedure TShellAuto.Close;
begin
  Application.MainForm.Close;
end;

procedure TShellAuto.Minimize;
begin
  Application.Minimize;
end;

procedure TShellAuto.Restore;
begin
  Application.Restore;
end;

procedure TShellAuto.Maximize;
begin
  with Application do
    begin
      if MainForm.WindowState = wsMinimized
        then Restore;
      MainForm.WindowState := wsMaximized;
    end;
end;

function TShellAuto.Open( const FileName : string ) : variant;
var
  i: integer;
begin
  with FShell do
  Result := FShell.Open(FileName, wsMinimized);
end;

function TShellAuto.NewTimeSpan : variant;
begin
  Result := FShell.ShowTimeSpan(TTimeSpan.Create, wsMinimized);
end;

function TShellAuto.NewEnsemble : variant;
begin
  Result := FShell.ShowEnsemble(TEnsemble.Create);
end;

procedure TShellAuto.Tile;
begin
  FShell.TileMode := tbVertical;
  FShell.Tile;
end;

// Initialization & finalization code

procedure RegisterShellAuto;
const
  AutoClassInfo: TAutoClassInfo =
  ( AutoClass: TShellAuto;
    ProgID: 'Vesta.Process';
    ClassID: '{70705860-3E24-11D0-8794-444553540000}';
    Description: 'Vesta Processor';
    Instancing: acMultiInstance);
begin
  Automation.RegisterClass(AutoClassInfo);
end;

initialization
  RegisterShellAuto;
end.

