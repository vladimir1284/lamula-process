unit ConfigurationForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, IniFiles;

type
  TFConfiguration = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet6: TTabSheet;
    Label19: TLabel;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit9: TEdit;
    Edit10: TEdit;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    GroupBox2: TGroupBox;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Label4: TLabel;
    Label6: TLabel;
    Label3: TLabel;
    TabSheet2: TTabSheet;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit13: TEdit;
    GroupBox3: TGroupBox;
    Label5: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Edit3: TEdit;
    Edit4: TEdit;
    TabSheet3: TTabSheet;
    Label14: TLabel;
    Edit14: TEdit;
    UpDown1: TUpDown;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    procedure ReadRegistry;
    procedure WriteRegistry;
  end;

var
  FConfiguration: TFConfiguration = nil;

implementation

{$R *.DFM}

uses
  Registry,
  Configuration, Measure,
  TimeSpan, Ensemble, Observation, Product, Animation,
  Borders, Regions;

const
  TimeSpanKey    = 'VestaTimespan';
  EnsembleKey    = 'VestaEnsemble';
  ObservationKey = 'VestaObservation';
  ProductKey     = 'VestaProduct';
  AnimationKey   = 'VestaAnimation';

// Private procedures & functions

procedure AssociateTimespans( Associate : boolean; const Desc, Action : string );
begin
  with TRegistry.Create do
    try
      RootKey := HKEY_CLASSES_ROOT;
      if Associate
        then
          begin
            OpenKey('\' + TimeSpanKey, true);
            WriteString('', Desc);
            OpenKey('\' + TimeSpanKey + '\DefaultIcon', true);
            WriteString('', Application.ExeName + ',1');
            OpenKey('\' + TimeSpanKey + '\QuickView', true);
            WriteString('', '*');
            OpenKey('\' + TimeSpanKey + '\Shell', true);
            WriteString('', 'Open');
            OpenKey('Open', true);
            WriteString('', Action);
            OpenKey('\' + TimeSpanKey + '\Shell\Open\command', true);
            WriteString('', Application.ExeName + ' %1');
            OpenKey('\' + TimeSpanKey + '\Shell\Open\ddeexec', true);
            WriteString('', '[open("%1")]');
            OpenKey('\' + TimeSpanKey + '\Shell\Open\ddeexec\ifexec', true);
            WriteString('', '[open("%1")]');
            OpenKey('\' + TimeSpanKey + '\Shell\Open\ddeexec\topic', true);
            WriteString('', 'Vesta');
            OpenKey('\' + TimeSpanExt, true);
            WriteString('', TimespanKey);
            OpenKey('ShellNew', true);
            WriteString('NullFile', '');
          end
        else
          begin
            DeleteKey('\' + TimeSpanExt);
            DeleteKey('\' + TimespanKey);
          end;
    finally
      Free;
    end;
end;

procedure AssociateEnsembles( Associate : boolean; const Desc, Action : string );
begin
  with TRegistry.Create do
    try
      RootKey := HKEY_CLASSES_ROOT;
      if Associate
        then
          begin
            OpenKey('\' + EnsembleKey, true);
            WriteString('', Desc);
            OpenKey('\' + EnsembleKey + '\DefaultIcon', true);
            WriteString('', Application.ExeName + ',5');
            OpenKey('\' + EnsembleKey + '\QuickView', true);
            WriteString('', '*');
            OpenKey('\' + EnsembleKey + '\Shell', true);
            WriteString('', 'Open');
            OpenKey('Open', true);
            WriteString('', Action);
            OpenKey('\' + EnsembleKey + '\Shell\Open\command', true);
            WriteString('', Application.ExeName + ' %1');
            OpenKey('\' + EnsembleKey + '\Shell\Open\ddeexec', true);
            WriteString('', '[open("%1")]');
            OpenKey('\' + EnsembleKey + '\Shell\Open\ddeexec\ifexec', true);
            WriteString('', '[open("%1")]');
            OpenKey('\' + EnsembleKey + '\Shell\Open\ddeexec\topic', true);
            WriteString('', 'Vesta');
            OpenKey('\' + EnsembleExt, true);
            WriteString('', EnsembleKey);
            OpenKey('ShellNew', true);
            WriteString('NullFile', '');
          end
        else
          begin
            DeleteKey('\' + EnsembleExt);
            DeleteKey('\' + EnsembleKey);
          end;
    finally
      Free;
    end;
end;

procedure AssociateObservations( Associate : boolean; const Desc, Action : string );
var
  I : integer;
begin
  with TRegistry.Create do
    try
      RootKey := HKEY_CLASSES_ROOT;
      if Associate
        then
          begin
            OpenKey('\' + ObservationKey, true);
            WriteString('', Desc);
            WriteString('AlwaysShowExt', '');
            OpenKey('\' + ObservationKey + '\DefaultIcon', true);
            WriteString('', Application.ExeName + ',2');
            OpenKey('\' + ObservationKey + '\Shell', true);
            WriteString('', 'Open');
            OpenKey('Open', true);
            WriteString('', Action);
            OpenKey('\' + ObservationKey + '\Shell\Open\command', true);
            WriteString('', Application.ExeName + ' %1');
            OpenKey('\' + ObservationKey + '\Shell\Open\ddeexec', true);
            WriteString('', '[open("%1")]');
            OpenKey('\' + ObservationKey + '\Shell\Open\ddeexec\ifexec', true);
            WriteString('', '[open("%1")]');
            OpenKey('\' + ObservationKey + '\Shell\Open\ddeexec\topic', true);
            WriteString('', 'Vesta');
            with Observation.ObservationExts do
              try
                for I := 0 to Count - 1 do
                  begin
                    OpenKey('\' + Strings[I], true);
                    WriteString('', ObservationKey);
                  end;
              finally
                Free;
              end;
          end
        else
          begin
            with Observation.ObservationExts do
              try
                for I := 0 to Count - 1 do
                  DeleteKey('\' + Strings[I]);
              finally
                Free;
              end;
            DeleteKey('\' + ObservationKey);
          end;
    finally
      Free;
    end;
end;

procedure AssociateProducts( Associate : boolean; const Desc, Action : string );
begin
  with TRegistry.Create do
    try
      RootKey := HKEY_CLASSES_ROOT;
      if Associate
        then
          begin
            OpenKey('\' + ProductKey, true);
            WriteString('', Desc);
            OpenKey('\' + ProductKey + '\DefaultIcon', true);
            WriteString('', Application.ExeName + ',3');
            OpenKey('\' + ProductKey + '\Shell', true);
            WriteString('', 'Open');
            OpenKey('Open', true);
            WriteString('', Action);
            OpenKey('\' + ProductKey + '\Shell\Open\command', true);
            WriteString('', Application.ExeName + ' %1');
            OpenKey('\' + ProductKey + '\Shell\Open\ddeexec', true);
            WriteString('', '[open("%1")]');
            OpenKey('\' + ProductKey + '\Shell\Open\ddeexec\ifexec', true);
            WriteString('', '[open("%1")]');
            OpenKey('\' + ProductKey + '\Shell\Open\ddeexec\topic', true);
            WriteString('', 'Vesta');
            OpenKey('\' + ProductExt, true);
            WriteString('', ProductKey);
          end
        else
          begin
            DeleteKey('\' + ProductExt);
            DeleteKey('\' + ProductKey);
          end;
    finally
      Free;
    end;
end;

procedure AssociateAnimations( Associate : boolean; const Desc, Action : string );
begin
  with TRegistry.Create do
    try
      RootKey := HKEY_CLASSES_ROOT;
      if Associate
        then
          begin
            OpenKey('\' + AnimationKey, true);
            WriteString('', Desc);
            OpenKey('\' + AnimationKey + '\DefaultIcon', true);
            WriteString('', Application.ExeName + ',4');
            OpenKey('\' + AnimationKey + '\Shell', true);
            WriteString('', 'Open');
            OpenKey('Open', true);
            WriteString('', Action);
            OpenKey('\' + AnimationKey + '\Shell\Open\command', true);
            WriteString('', Application.ExeName + ' %1');
            OpenKey('\' + AnimationKey + '\Shell\Open\ddeexec', true);
            WriteString('', '[open("%1")]');
            OpenKey('\' + AnimationKey + '\Shell\Open\ddeexec\ifexec', true);
            WriteString('', '[open("%1")]');
            OpenKey('\' + AnimationKey + '\Shell\Open\ddeexec\topic', true);
            WriteString('', 'Vesta');
            OpenKey('\' + AnimationExt, true);
            WriteString('', AnimationKey);
          end
        else
          begin
            DeleteKey('\' + AnimationExt);
            DeleteKey('\' + AnimationKey);
          end;
    finally
      Free;
    end;
end;

// TFConfiguration methods

procedure TFConfiguration.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet1;
  ReadRegistry;
end;

procedure TFConfiguration.FormDestroy(Sender: TObject);
begin
  FConfiguration := nil;
end;

procedure TFConfiguration.ReadRegistry;
begin
  with theConfiguration do
    begin
      // Z-R
      Edit1.Text := FloatToStr(RainA);
      Edit2.Text := FloatToStr(RainB);
      // Kdp-R
      Edit3.Text := FloatToStr(KDP_A);
      Edit4.Text := FloatToStr(KDP_B);
      // Archivos
      Edit11.Text := BorderTables;
      Edit12.Text := RegionTables;
      Edit13.Text := TopographyMaps;
      // Speckler
      UpDown1.Position := RadialSpeckler;
      // Asociacion
      with TRegistry.Create do
        try
          RootKey := HKEY_CLASSES_ROOT;
          CheckBox1.Checked := KeyExists('\' + TimespanKey);
          CheckBox2.Checked := KeyExists('\' + ObservationKey);
          CheckBox3.Checked := KeyExists('\' + ProductKey);
          CheckBox4.Checked := KeyExists('\' + AnimationKey);
          CheckBox5.Checked := KeyExists('\' + EnsembleKey);
          if CheckBox1.Checked and OpenKey('\' + TimespanKey, false)
            then Edit5.Text := ReadString('')
            else Edit5.Text := 'Periodo de radar';
          if CheckBox2.Checked and OpenKey('\' + ObservationKey, false)
            then Edit6.Text := ReadString('')
            else Edit6.Text := 'Observacion de radar';
          if CheckBox3.Checked and OpenKey('\' + ProductKey, false)
            then Edit7.Text := ReadString('')
            else Edit7.Text := 'Producto de radar';
          if CheckBox4.Checked and OpenKey('\' + AnimationKey, false)
            then Edit8.Text := ReadString('')
            else Edit8.Text := 'Animacion de radar';
          if CheckBox5.Checked and OpenKey('\' + EnsembleKey, false)
            then Edit9.Text := ReadString('')
            else Edit9.Text := 'Conjunto de radar';
          Edit10.Text := '';
          if CheckBox1.Checked and OpenKey('\VestaTimespan\Shell\Open', false)
            then Edit10.Text := ReadString('');
          if CheckBox1.Checked and OpenKey('\VestaObservation\Shell\Open', false)
            then Edit10.Text := ReadString('');
          if CheckBox1.Checked and OpenKey('\VestaProduct\Shell\Open', false)
            then Edit10.Text := ReadString('');
          if CheckBox1.Checked and OpenKey('\VestaAnimation\Shell\Open', false)
            then Edit10.Text := ReadString('');
          if Edit10.Text = ''
            then Edit10.Text := 'Abrir';
        finally
          Free;
        end;
    end;
end;

procedure TFConfiguration.WriteRegistry;
begin
  with theConfiguration do
    try
      // Z-R
      RainA := StrToFloat(Edit1.Text);
      RainB := StrToFloat(Edit2.Text);
      // Kdp-R
      KDP_A := StrToFloat(Edit3.Text);
      KDP_B := StrToFloat(Edit4.Text);
      // Archivos
      BorderTables   := Edit11.Text;
      RegionTables   := Edit12.Text;
      TopographyMaps := Edit13.Text;
      // Speckler
      RadialSpeckler := UpDown1.Position;
      // Asociacion
      try
        AssociateTimespans   (CheckBox1.Checked, Edit5.Text, Edit10.Text);
        AssociateObservations(CheckBox2.Checked, Edit6.Text, Edit10.Text);
        AssociateProducts    (CheckBox3.Checked, Edit7.Text, Edit10.Text);
        AssociateAnimations  (CheckBox4.Checked, Edit8.Text, Edit10.Text);
        AssociateEnsembles   (CheckBox5.Checked, Edit9.Text, Edit10.Text);
      except
        on E : ERegistryException do
          begin
            E.Message := 'No se pudo actualizar el registro. Probablemente necesite privilegios de administrador';
            raise;
          end;
      end;
    finally
      ReadRegistry;
    end;
end;

procedure TFConfiguration.Button3Click(Sender: TObject);
begin
  WriteRegistry;
  Borders.Update;
  Regions.Update;
end;

{initialization
  try
    AssociateTimespans   (true, TimeSpanKey, 'Abrir');
    AssociateObservations(true, ObservationKey, 'Abrir');
    AssociateProducts    (true, ProductKey, 'Abrir');
    AssociateAnimations  (true, AnimationKey, 'Abrir');
    AssociateEnsembles   (true, EnsembleKey, 'Abrir');
  except
    on E : ERegistryException do
      begin
        E.Message := 'No se pudo actualizar el registro. Probablemente necesite privilegios de administrador';
        raise;
      end;
  end;}
end.
