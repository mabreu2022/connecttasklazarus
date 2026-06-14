unit udm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IBDatabase, IBQuery;

type

  { TDataModule1 }

  TDataModule1 = class(TDataModule)
    IBDatabase1: TIBDatabase;
    IBTransaction1: TIBTransaction;
    IBQ_Workspace: TIBQuery;
    IBQ_workspacepoidusuairo: TIBQuery;
    IBQ_WorksSpace_E_Boards: TIBQuery;
    IBQ_Login: TIBQuery;
    IBQ_List: TIBQuery;
    IBQ_Card: TIBQuery;
    procedure DataModuleCreate(Sender: TObject);
  private

  public

  end;

var
  DataModule1: TDataModule1;

implementation

{$R *.lfm}

procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin
  IBDatabase1.Connected := False;
  IBDatabase1.LoginPrompt := False;
  
  // Configure parameters explicitly to prevent runtime login prompts
  IBDatabase1.Params.Clear;
  IBDatabase1.Params.Add('user_name=SYSDBA');
  IBDatabase1.Params.Add('password=ZmrL9W79B48nUeUBOPK0');
  IBDatabase1.Params.Add('lc_ctype=UTF8');
end;

end.

