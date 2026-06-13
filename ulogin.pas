unit uLogin;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  IBDatabase, IBQuery, udm, uBCrypt;

type

  { TForm3 }

  TForm3 = class(TForm)
    btnLogin: TPanel;
    edtEmail: TEdit;
    edtPassword: TEdit;
    lblForgot: TLabel;
    lblLogin: TLabel;
    lblRegister: TLabel;
    lblTitle: TLabel;
    pnlCard: TPanel;
    pnlEmail: TPanel;
    pnlPassword: TPanel;
    procedure btnLoginClick(Sender: TObject);
    procedure lblRegisterClick(Sender: TObject);
  private

  public

  end;

var
  Form3: TForm3;
  LoggedUserID: Integer = 0;
  LoggedUserName: string = '';
  LoggedUserEmail: string = '';

implementation

{$R *.lfm}

{ TForm3 }

procedure TForm3.btnLoginClick(Sender: TObject);
var
  EmailVal, PassVal: string;
begin
  EmailVal := Trim(edtEmail.Text);
  PassVal := edtPassword.Text;

  if (EmailVal = '') or (PassVal = '') then
  begin
    ShowMessage('Por favor, preencha todos os campos.');
    Exit;
  end;

  // Ensure database is connected
  try
    if not DataModule1.IBDatabase1.Connected then
      DataModule1.IBDatabase1.Connected := True;
  except
    on E: Exception do
    begin
      ShowMessage('Erro de conexão ao banco de dados: ' + E.Message);
      Exit;
    end;
  end;

  // Perform query to search for the user
  try
    DataModule1.IBQ_Login.Close;
    DataModule1.IBQ_Login.ParamByName('EMAIL').AsString := EmailVal;
    DataModule1.IBQ_Login.Open;

    if DataModule1.IBQ_Login.Eof then
    begin
      ShowMessage('Usuário não cadastrado!');
      Exit;
    end;

    // Check BCrypt password hash
    if checkPassword(PassVal, DataModule1.IBQ_Login.FieldByName('PASSWORD').AsString) then
    begin
      // Save session info
      LoggedUserID := DataModule1.IBQ_Login.FieldByName('ID').AsInteger;
      LoggedUserName := DataModule1.IBQ_Login.FieldByName('USERNAME').AsString;
      LoggedUserEmail := DataModule1.IBQ_Login.FieldByName('EMAIL').AsString;

      ModalResult := mrOk;
    end
    else
    begin
      ShowMessage('Senha incorreta! Tente novamente.');
    end;

  finally
    DataModule1.IBQ_Login.Close;
  end;
end;

procedure TForm3.lblRegisterClick(Sender: TObject);
begin
  ShowMessage('Funcionalidade de Registro em desenvolvimento!');
end;

end.
