unit ObsViewer;

interface

  uses
    Windows,
    ActiveX,
    ShlObj,
    ComObj,
    ComServ,
    Observation,
    Graphics;

  const
    CLSID_ObsViewer : TGUID = '{36692540-4b37-11d1-a807-444553540000}';

  type
    TObsViewer = class( TComObject, IPersistFile, IFileViewer )
    protected  // IFileViewer
      function ShowInitialize(fsi: IFileViewerSite): HResult; stdcall;
      function Show(var pvsi: TFVShowInfo): HResult; stdcall;
      function PrintTo(pszDriver: PAnsiChar; fSuppressUI: BOOL): HResult; stdcall;
    protected  // IPersist
      function GetClassID(out classID: TCLSID): HResult;  stdcall;
    protected  // IPersistFile
      function IsDirty: HResult; stdcall;
      function Load(pszFileName: POleStr; dwMode: Longint): HResult; stdcall;
      function Save(pszFileName: POleStr; fRemember: BOOL): HResult; stdcall;
      function SaveCompleted(pszFileName: POleStr): HResult; stdcall;
      function GetCurFile(out pszFileName: POleStr): HResult; stdcall;
    private
      fFileName    : POleStr;
      fObservation : TObservation;
      fGraphic     : TGraphic;
      procedure SetObservation( O : TObservation );
      function  ObsGraphic : TGraphic;
    public
      property Observation : TObservation read fObservation write SetObservation;
      property Graphic     : TGraphic     read fGraphic;
    end;

implementation

  uses
    SysUtils;


// TObsViewer methods

  procedure TObsViewer.SetObservation( O : TObservation );
  begin
    fObservation := O;
    fGraphic     := ObsGraphic;
  end;

  function TObsViewer.ObsGraphic : TGraphic;
  begin
    Result := nil;
  end;
  
  // IFileViewer

  function TObsViewer.ShowInitialize( fsi : IFileViewerSite ) : HResult;
  begin
    if assigned(fGraphic)
      then
        try
          fGraphic.SaveToFile( 'e:\test' );
          Result := S_OK;
        except
          Result := E_FAIL;
        end
      else Result := E_FAIL;
  end;

  function TObsViewer.Show( var pvsi : TFVShowInfo ) : HResult;
  begin
    if pvsi.dwFlags and FVSIF_NEWFAILED = 0
      then
        begin
          pvsi.dwFlags    := FVSIF_NEWFILE;
          pvsi.punkRel    := Self as IUnknown;
          StringToWideChar( 'e:\orlando\fotos\dr.bmp',
                            @pvsi.strNewFile, sizeof(pvsi.strNewFile) );
        end;
    Result := S_OK;
  end;

  function TObsViewer.PrintTo( pszDriver : PAnsiChar; fSuppressUI : BOOL ) : HResult;
  begin
    Result := E_NOTIMPL;
  end;

  // IPersist

  function TObsViewer.GetClassID( out classID : TCLSID ) : HResult;
  begin
    classID := CLSID_ObsViewer;
    Result  := S_OK;
  end;

  // IPersistFile

  function TObsViewer.IsDirty : HResult;
  begin
    Result := S_FALSE;
  end;

  function TObsViewer.Load( pszFileName : POleStr; dwMode : Longint ) : HResult;
  begin
    fFileName := pszFileName;
    try
      Observation := TObservation.Load( OleStrToString( fFileName ) );
      Result      := S_OK;
    except
      on EOutOfMemory do Result := E_OUTOFMEMORY
      else               Result := E_FAIL;
    end;
  end;

  function TObsViewer.Save( pszFileName : POleStr; fRemember : BOOL ) : HResult;
  begin
    Result := E_NOTIMPL;
  end;

  function TObsViewer.SaveCompleted( pszFileName : POleStr ) : HResult;
  begin
    Result := E_NOTIMPL;
  end;

  function TObsViewer.GetCurFile( out pszFileName : POleStr ) : HResult;
  begin
    pszFileName := fFileName;
    if assigned(fFileName)
      then Result := S_OK
      else Result := E_UNEXPECTED;
  end;

end.

