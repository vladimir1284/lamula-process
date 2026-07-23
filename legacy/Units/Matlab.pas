{$A8,B-,C+,D+,E-,F-,G+,H+,I+,J-,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$MINSTACKSIZE $00004000}
{$MAXSTACKSIZE $00100000}
{$IMAGEBASE $00400000}
{$APPTYPE GUI}
{$WARN SYMBOL_DEPRECATED ON}
{$WARN SYMBOL_LIBRARY ON}
{$WARN SYMBOL_PLATFORM ON}
{$WARN UNIT_LIBRARY ON}
{$WARN UNIT_PLATFORM ON}
{$WARN UNIT_DEPRECATED ON}
{$WARN HRESULT_COMPAT ON}
{$WARN HIDING_MEMBER ON}
{$WARN HIDDEN_VIRTUAL ON}
{$WARN GARBAGE ON}
{$WARN BOUNDS_ERROR ON}
{$WARN ZERO_NIL_COMPAT ON}
{$WARN STRING_CONST_TRUNCED ON}
{$WARN FOR_LOOP_VAR_VARPAR ON}
{$WARN TYPED_CONST_VARPAR ON}
{$WARN ASG_TO_TYPED_CONST ON}
{$WARN CASE_LABEL_RANGE ON}
{$WARN FOR_VARIABLE ON}
{$WARN CONSTRUCTING_ABSTRACT ON}
{$WARN COMPARISON_FALSE ON}
{$WARN COMPARISON_TRUE ON}
{$WARN COMPARING_SIGNED_UNSIGNED ON}
{$WARN COMBINING_SIGNED_UNSIGNED ON}
{$WARN UNSUPPORTED_CONSTRUCT ON}
{$WARN FILE_OPEN ON}
{$WARN FILE_OPEN_UNITSRC ON}
{$WARN BAD_GLOBAL_SYMBOL ON}
{$WARN DUPLICATE_CTOR_DTOR ON}
{$WARN INVALID_DIRECTIVE ON}
{$WARN PACKAGE_NO_LINK ON}
{$WARN PACKAGED_THREADVAR ON}
{$WARN IMPLICIT_IMPORT ON}
{$WARN HPPEMIT_IGNORED ON}
{$WARN NO_RETVAL ON}
{$WARN USE_BEFORE_DEF ON}
{$WARN FOR_LOOP_VAR_UNDEF ON}
{$WARN UNIT_NAME_MISMATCH ON}
{$WARN NO_CFG_FILE_FOUND ON}
{$WARN MESSAGE_DIRECTIVE ON}
{$WARN IMPLICIT_VARIANTS ON}
{$WARN UNICODE_TO_LOCALE ON}
{$WARN LOCALE_TO_UNICODE ON}
{$WARN IMAGEBASE_MULTIPLE ON}
{$WARN SUSPICIOUS_TYPECAST ON}
{$WARN PRIVATE_PROPACCESSOR ON}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
unit MatLab;

interface

uses
  SysUtils;

const
  Libmx    = 'libmx.dll';
  Libmatlb = 'libmatlb.dll';
  Libmex   = 'libmex.dll';

type
  PmxArray = pointer;
  TAPmxArray = array of PmxArray;

  TmxComplexty = (mxREAL, mxCOMPLEX);
  TmxClassID = (mxUNKNOWN_CLASS, mxCELL_CLASS, mxSTRUCT_CLASS, mxLOGICAL_CLASS, mxCHAR_CLASS, mxVOID_CLASS,
                mxDOUBLE_CLASS, mxSINGLE_CLASS, mxINT8_CLASS, mxUINT8_CLASS, mxINT16_CLASS, mxUINT16_CLASS,
                mxINT32_CLASS, mxUINT32_CLASS, mxINT64_CLASS, mxUINT64_CLASS, mxFUNCTION_CLASS, mxOPAQUE_CLASS, mxOBJECT_CLASS);

// MatLab routines

function  mxCreateDoubleMatrix(m, n: integer; cmplx_flag: TmxComplexty): PmxArray; cdecl; external Libmx;
function  mxCreateNumericMatrix(m, n: integer; mxClassID: TmxClassID; cmplx_flag: TmxComplexty): PmxArray; cdecl; external Libmx;
function  mxCreateDoubleScalar(value: real): PmxArray; cdecl; external Libmx;
function  mxCreateString(const s: pchar): PmxArray; cdecl; external Libmx;
function  mxCreateStringFromNChars(s: pchar; n: integer): PmxArray; cdecl; external Libmx;
function  mxCreateStructMatrix(m, n, fields: integer; var names: pchar): PmxArray; cdecl; external Libmx;
function  mxCreateCharMatrixFromStrings(m: integer; var s: pchar): PmxArray; cdecl; external Libmx;

function  mxGetM(pa: PmxArray): integer; cdecl; external Libmx;
function  mxGetN(pa: PmxArray): integer; cdecl; external Libmx;
function  mxGetPr(pa: PmxArray): Pdouble; cdecl; external Libmx;
function  mxGetScalar(pa: PmxArray): real; cdecl; external Libmx;
function  mxGetString(pa: PmxArray; str: pchar; len: integer): integer; cdecl; external Libmx;
function  mxGetNumberOfFields(const pa: PmxArray): integer; cdecl; external Libmx;
function  mxGetFieldNameByNumber(const pa: PmxArray; n: integer): pchar; cdecl; external Libmx;
function  mxGetFieldNumber(const pa: PmxArray; const name: pchar): integer; cdecl; external Libmx;
function  mxGetFieldByNumber(const pa: PmxArray; i: integer; fieldnum: integer): PmxArray; cdecl; external Libmx;
function  mxGetField(const pa: PmxArray; i: integer; const fieldname: pchar): PmxArray; cdecl; external Libmx;

procedure mxSetFieldByNumber(sa: PmxArray; ind, field_number: integer; value: PmxArray); cdecl; external Libmx;

function  mlfInv(X: PmxArray): PmxArray; cdecl; external Libmatlb;

procedure mexErrMsgTxt(msg: pchar); cdecl; external Libmex;
function mexPrintf(s: pchar): integer; cdecl; external Libmex;

implementation

end.


