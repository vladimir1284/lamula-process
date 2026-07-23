unit Macro;

interface

  uses
    SysUtils, Classes;

  function SplitMacro(   const aMacro   : string; S : TStrings ) : integer;
  function SplitCommand( const aCommand : string; S : TStrings ) : integer;


implementation

uses
  utStr;


{ Public procedures & functions }

function SplitMacro( const aMacro : string; S : TStrings ) : integer;
var
  P : string;
  C : integer;
begin
  P := Trim(aMacro);
  if assigned(S) and (P <> '') and (P[1] = '[') and (P[length(P)] =']')
    then
      begin
        C := S.Count;
        repeat
          S.Add(Trim(AfterStr('[', BeforeStr(']', P))));
          P := Trim(AfterStr(']', P));
        until P ='';
        Result := S.Count - C;
      end
    else Result := 0;
end;

function SplitCommand( const aCommand : string; S : TStrings ) : integer;
var
  P : string;
  C : integer;
begin
  P := Trim(aCommand);
  if assigned(S) and (P <> '')
    then
      begin
        S.Add(Trim(BeforeStr('(', aCommand)));
        P := Trim(AfterStr('(', aCommand));
        if P[length(P)] = ')'
          then delete(P, length(P), 1);
        C := S.Count;
        repeat
          S.Add(Trim(BeforeStr(',', P)));
          P := Trim(AfterStr(',', P));
        until P = '';
        Result := S.Count - C;
      end
    else
      Result := 0;
end;

end.

