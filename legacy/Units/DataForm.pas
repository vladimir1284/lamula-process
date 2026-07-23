unit DataForm;

interface

  uses
    Forms;

  type
    TDataForm = class;
    CDataForm = class of TDataForm;

    TDataForm = class(TForm)
    private
      fModified : boolean;
    published
      property Modified : boolean read fModified write fModified;
    end;

implementation

end.
