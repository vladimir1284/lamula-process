unit DataSource;

interface

uses
  Referenced, Plane, Description;

type
  TDataSource = class;
  CDataSource = class of TDataSource;

  TDataSource = class(TReferenced)
  private
    fLocation : T2DLocation;
  protected
    function GetSystem  : string;                     virtual;  abstract;
    function GetSources : integer;                    virtual;  abstract;
    function GetSource( I : integer ) : TDataSource;  virtual;  abstract;
  public
    property Location            : T2DLocation read fLocation write fLocation;
    property System              : string      read GetSystem;
    property Sources             : integer     read GetSources;
    property Source[I : integer] : TDataSource read GetSource;
  public
    function Contains( Radar : TRadar ) : boolean;  virtual;  abstract;
  end;

implementation

end.
