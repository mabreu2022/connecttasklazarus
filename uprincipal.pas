unit uprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, uTaskCard,
  uHeaderScrollBox;

type

  { TForm1 }

  TForm1 = class(TForm)
    HeaderScrollBox1: THeaderScrollBox;
    HeaderScrollBox2: THeaderScrollBox;
    TaskCard1: TTaskCard;
    TaskCard2: TTaskCard;
    TaskCard3: TTaskCard;
    TaskCard4: TTaskCard;
    TaskCard5: TTaskCard;
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

end.

