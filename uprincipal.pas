unit uprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls, ComCtrls, uTaskCard, uHeaderScrollBox, uBoardCard,
  uScrollBoardCards, uPanelAreaTrabalho;

type

  { TForm1 }

  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BoardCard1: TBoardCard;
    BoardCard10: TBoardCard;
    BoardCard11: TBoardCard;
    BoardCard2: TBoardCard;
    BoardCard3: TBoardCard;
    BoardCard4: TBoardCard;
    BoardCard5: TBoardCard;
    BoardCard6: TBoardCard;
    BoardCard7: TBoardCard;
    BoardCard8: TBoardCard;
    BoardCard9: TBoardCard;
    Edit1: TEdit;
    Panel1: TPanel;
    ScrollBoardCards1: TScrollBoardCards;
    ScrollBox1: TScrollBox;
    StatusBar1: TStatusBar;
    WorkspaceHeader1: TPanelAreaTrabalho;
    procedure BoardCard1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure WorkspacePanelCreateBoard(Sender: TObject);
    procedure WorkspacePanelDelete(Sender: TObject);
    
    // Board card handlers
    procedure BoardCardEdit(Sender: TObject);
    procedure BoardCardSettings(Sender: TObject);
    procedure BoardCardDelete(Sender: TObject);
    procedure BoardCardClick(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

uses
  uListas;

{$R *.lfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  I: Integer;
  Ctrl: TControl;
begin
  WorkspaceHeader1.LinkedControl := ScrollBoardCards1;
  WorkspaceHeader1.OnCreateBoard := @WorkspacePanelCreateBoard;
  WorkspaceHeader1.OnDelete := @WorkspacePanelDelete;
  
  for I := 0 to ScrollBoardCards1.ControlCount - 1 do
  begin
    Ctrl := ScrollBoardCards1.Controls[I];
    if Ctrl is TBoardCard then
    begin
      TBoardCard(Ctrl).OnEdit := @BoardCardEdit;
      TBoardCard(Ctrl).OnSettings := @BoardCardSettings;
      TBoardCard(Ctrl).OnDelete := @BoardCardDelete;
      TBoardCard(Ctrl).OnClick := @BoardCardClick;
    end;
  end;
end;

procedure TForm1.BoardCard1Click(Sender: TObject);
begin

end;

procedure TForm1.BitBtn3Click(Sender: TObject);
var
  WorkspaceName: string;
  NewHeader: TPanelAreaTrabalho;
  NewCards: TScrollBoardCards;
begin
  WorkspaceName := '';
  if InputQuery('Nova Área de Trabalho', 'Digite o nome da área de trabalho:', WorkspaceName) then
  begin
    if Trim(WorkspaceName) = '' then Exit;
    
    // Create ScrollBoardCards container first
    NewCards := TScrollBoardCards.Create(Self);
    NewCards.Parent := ScrollBox1;
    NewCards.Align := alTop;
    NewCards.Height := 140; // Height of 1 row of cards + margins
    NewCards.SendToBack;    // Move to bottom visual position
    
    // Create Workspace Header Panel
    NewHeader := TPanelAreaTrabalho.Create(Self);
    NewHeader.Parent := ScrollBox1;
    NewHeader.Align := alTop;
    NewHeader.WorkspaceName := WorkspaceName;
    NewHeader.LinkedControl := NewCards;
    NewHeader.OnCreateBoard := @WorkspacePanelCreateBoard;
    NewHeader.OnDelete := @WorkspacePanelDelete;
    NewHeader.SendToBack;   // Move to bottom visual position (above NewCards)
  end;
end;

procedure TForm1.BitBtn4Click(Sender: TObject);
var
  I: Integer;
  LastHeader: TPanelAreaTrabalho;
  Ctrl: TControl;
begin
  LastHeader := nil;
  for I := 0 to ScrollBox1.ControlCount - 1 do
  begin
    Ctrl := ScrollBox1.Controls[I];
    if Ctrl is TPanelAreaTrabalho then
    begin
      LastHeader := TPanelAreaTrabalho(Ctrl);
      Break;
    end;
  end;
  
  if LastHeader <> nil then
    WorkspacePanelCreateBoard(LastHeader)
  else
    ShowMessage('Por favor, crie uma Área de Trabalho primeiro!');
end;

procedure TForm1.WorkspacePanelCreateBoard(Sender: TObject);
var
  Workspace: TPanelAreaTrabalho;
  CardsContainer: TScrollBoardCards;
  NewCard: TBoardCard;
  BoardTitle: string;
begin
  Workspace := TPanelAreaTrabalho(Sender);
  if (Workspace.LinkedControl <> nil) and (Workspace.LinkedControl is TScrollBoardCards) then
  begin
    CardsContainer := TScrollBoardCards(Workspace.LinkedControl);
    BoardTitle := '';
    if InputQuery('Novo Quadro', 'Digite o título do Quadro:', BoardTitle) then
    begin
      if Trim(BoardTitle) = '' then Exit;
      NewCard := TBoardCard.Create(Self);
      NewCard.Parent := CardsContainer;
      NewCard.BoardTitle := BoardTitle;
      NewCard.OnEdit := @BoardCardEdit;
      NewCard.OnSettings := @BoardCardSettings;
      NewCard.OnDelete := @BoardCardDelete;
      NewCard.OnClick := @BoardCardClick;
      
      CardsContainer.Invalidate;
    end;
  end;
end;

procedure TForm1.WorkspacePanelDelete(Sender: TObject);
begin
  // Custom delete hook
end;

procedure TForm1.BoardCardEdit(Sender: TObject);
begin
end;

procedure TForm1.BoardCardSettings(Sender: TObject);
begin
end;

procedure TForm1.BoardCardDelete(Sender: TObject);
begin
end;

procedure TForm1.BoardCardClick(Sender: TObject);
begin
  if Form2 = nil then
    Application.CreateForm(TForm2, Form2);
  Form2.Caption := TBoardCard(Sender).BoardTitle;
  Form2.Show;
end;

end.
