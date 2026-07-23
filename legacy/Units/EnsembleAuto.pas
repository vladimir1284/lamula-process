unit EnsembleAuto;

interface

uses
  Variants,
  Forms,
  FormAuto,
  Description;

type
  TEnsembleAuto = class(TFormAuto)
  automated
    function GetObservations : integer;
    function GetObservation(       I : integer ) : variant;
    function GetProduct    ( const S : string  ) : variant;
    function GetAnimation  ( const S : string  ) : variant;
  automated
    procedure Load  ( const FileName : string  );
    procedure Save  ( const FileName : string  );
    procedure Insert( const FileName : string  );
    procedure Delete(       Index    : integer );
  automated
    property Observations : integer read GetObservations;
    property Product    [const S : string ] : variant read GetProduct;
    property Animation  [const S : string ] : variant read GetAnimation;
    property Observation[      I : integer] : variant read GetObservation;
  protected
    class function FormClass : TFormClass;  override;
  end;

implementation

  uses
    Ensemble,
    Notify,
    Product, ChannelAuto,
    Shell_Process, EnsembleForm;


// TEnsembleAuto methods

  function TEnsembleAuto.GetObservations : integer;
  begin
    Result := TFEnsemble(Form).Ensemble.Observations;
  end;

  function TEnsembleAuto.GetProduct( const S : string ) : variant;
  var
    P : TProduct;
  begin
    P := TFEnsemble(Form).GetStpProduct( S );
    if assigned(P)
      then Result := P.OleObject
      else Result := null;
  end;

  function TEnsembleAuto.GetAnimation( const S : string ) : variant;
  var
    P : TProduct;
  begin
    P := TFEnsemble(Form).GetAnmProduct( S );
    if assigned(P)
      then Result := P.OleObject
      else Result := null;
  end;

  function TEnsembleAuto.GetObservation( I : integer ) : variant;
  begin
    Result := FShell.ShowObservation( TFEnsemble(Form).Ensemble[I], wsNormal );
  end;

  procedure TEnsembleAuto.Load( const FileName : string );
  begin
    TFEnsemble(Form).Ensemble := TEnsemble.Load( FileName );
  end;

  procedure TEnsembleAuto.Save( const FileName : string );
  begin
    TFEnsemble(Form).Ensemble.Save( FileName );
  end;

  procedure TEnsembleAuto.Insert( const FileName : string );
  begin
    with TFEnsemble(Form) do
      begin
        Ensemble.AddFile( FileName );
        UpdateEnsembleView;
      end;
  end;

  procedure TEnsembleAuto.Delete( Index : integer );
  begin
    with TFEnsemble(Form) do
      begin
        Ensemble.Delete( Index );
        UpdateEnsembleView;
      end;
  end;

  class function TEnsembleAuto.FormClass : TFormClass;
  begin
    Result := TFEnsemble;
  end;


end.
