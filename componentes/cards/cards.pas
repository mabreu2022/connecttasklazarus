{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit cards;

{$warn 5023 off : no warning about unused units}
interface

uses
  uComponenteCard, uHeaderScrollBox, uTaskCard, uBoardCard, uScrollBoardCards, uPanelAreaTrabalho, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('uHeaderScrollBox', @uHeaderScrollBox.Register);
  RegisterUnit('uTaskCard', @uTaskCard.Register);
  RegisterUnit('uBoardCard', @uBoardCard.Register);
  RegisterUnit('uScrollBoardCards', @uScrollBoardCards.Register);
  RegisterUnit('uPanelAreaTrabalho', @uPanelAreaTrabalho.Register);
end;

initialization
  RegisterPackage('cards', @Register);
end.
