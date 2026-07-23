unit OViewer;

interface

  uses
    Windows,
    ActiveX, ShlObj;

  const
    CLSID_ObsViewer : TGUID = '{36692540-4b37-11d1-a807-444553540000}';

  type
    TObsViewerClassFactory = class( TInterfacedObject, IClassFactory )
    protected  // IClassFactory
      function CreateInstance(const unkOuter: IUnknown; const iid: TIID; out obj): HResult; stdcall;
      function LockServer(fLock: BOOL): HResult; stdcall;
    end;

    TObsViewer = class( TInterfacedObject, IPersistFile, IFileViewer )
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
      fFileName : POleStr;
    end;

implementation


// TObsViewerClassFactory methods

  // IClassFactory

  function TObsViewerClassFactory.CreateInstance(const unkOuter: IUnknown; const iid: TIID; out obj): HResult; stdcall;
  begin
    if unkOuter = nil
      then Result := (TObsViewer.Create as IUnknown).QueryInterface( IID, Obj )
      else Result := CLASS_E_NOAGGREGATION;
  end;

  function TObsViewerClassFactory.LockServer(fLock: BOOL): HResult; stdcall;
  begin
    Result := CoLockObjectExternal( Self, fLock, TRUE );
  end;


// TObsViewer methods

  // IFileViewer

  function TObsViewer.ShowInitialize( fsi : IFileViewerSite ) : HResult;
  begin
    try
      //fObservation := TObservation.Load( OleStrToString( fFileName ) );
      Result := S_OK;
    except
      Result := E_FAIL;
    end;
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
    Result    := S_OK;
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

