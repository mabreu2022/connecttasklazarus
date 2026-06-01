{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit cards;

{$warn 5023 off : no warning about unused units}
interface

uses
  uComponenteCard, uHeaderScrollBox, uTaskCard, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('uHeaderScrollBox', @uHeaderScrollBox.Register);
  RegisterUnit('uTaskCard', @uTaskCard.Register);
end;

initialization
  RegisterPackage('cards', @Register);
end.
