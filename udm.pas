unit udm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IBDatabase, IBQuery;

type

  { TDataModule1 }

  TDataModule1 = class(TDataModule)
    IBDatabase1: TIBDatabase;
    IBQ_Workspace: TIBQuery;
    IBQ_workspacepoidusuairo: TIBQuery;
    IBQ_WorksSpace_E_Boards: TIBQuery;
  private

  public

  end;

var
  DataModule1: TDataModule1;

implementation

{$R *.lfm}

end.

