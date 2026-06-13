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
  private

  public

  end;

var
  DataModule1: TDataModule1;

implementation

{$R *.lfm}

end.

