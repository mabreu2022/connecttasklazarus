program connecttasktrello;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Controls, Forms, uprincipal, uLogin, udm;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TForm3, Form3);
  if Form3.ShowModal = mrOk then
  begin
    Application.CreateForm(TForm1, Form1);
    Application.Run;
  end
  else
    Application.Terminate;
end.

