unit uListas;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  Buttons, StdCtrls, uHeaderScrollBox, uTaskCard;

type

  { TForm2 }

  TForm2 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    Edit1: TEdit;
    HeaderScrollBox1: THeaderScrollBox;
    HeaderScrollBox2: THeaderScrollBox;
    HeaderScrollBox3: THeaderScrollBox;
    HeaderScrollBox4: THeaderScrollBox;
    HeaderScrollBox5: THeaderScrollBox;
    HeaderScrollBox6: THeaderScrollBox;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    ScrollBox1: TScrollBox;
    ScrollBox2: TScrollBox;
    Shape1: TShape;
    StatusBar1: TStatusBar;
    TaskCard1: TTaskCard;
    TaskCard2: TTaskCard;
    TaskCard3: TTaskCard;
    procedure FormCreate(Sender: TObject);
    procedure TaskCardCopy(Sender: TObject);
    procedure TaskCardEdit(Sender: TObject);
    procedure TaskCardDelete(Sender: TObject);
  private

  public

  end;

var
  Form2: TForm2;

implementation

{$R *.lfm}

procedure TForm2.FormCreate(Sender: TObject);
var
  I, J: Integer;
  Box: THeaderScrollBox;
  Ctrl: TControl;
begin
  // Set up events for all existing task cards in any HeaderScrollBox
  for I := 0 to ComponentCount - 1 do
  begin
    if Components[I] is THeaderScrollBox then
    begin
      Box := THeaderScrollBox(Components[I]);
      for J := 0 to Box.ControlCount - 1 do
      begin
        Ctrl := Box.Controls[J];
        if Ctrl is TTaskCard then
        begin
          TTaskCard(Ctrl).OnCopyClick := @TaskCardCopy;
          TTaskCard(Ctrl).OnEditClick := @TaskCardEdit;
          TTaskCard(Ctrl).OnDeleteClick := @TaskCardDelete;
        end;
      end;
    end;
  end;
end;

procedure TForm2.TaskCardCopy(Sender: TObject);
begin
  if Sender is TTaskCard then
    StatusBar1.SimpleText := 'Código da tarefa "' + TTaskCard(Sender).TaskCode + '" copiado para a área de transferência.';
end;

procedure TForm2.TaskCardEdit(Sender: TObject);
begin
  if Sender is TTaskCard then
    StatusBar1.SimpleText := 'Tarefa "' + TTaskCard(Sender).TaskCode + '" editada com sucesso.';
end;

procedure TForm2.TaskCardDelete(Sender: TObject);
begin
  if Sender is TTaskCard then
    StatusBar1.SimpleText := 'Tarefa "' + TTaskCard(Sender).TaskCode + '" excluída.';
end;

end.

