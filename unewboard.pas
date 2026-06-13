unit uNewBoard;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls, Dialogs, udm, uLogin, IBQuery;

type
  TFormNewBoard = class(TForm)
  private
    edtBoardTitle: TEdit;
    cbWorkspace: TComboBox;
    rbPublic: TRadioButton;
    rbPrivate: TRadioButton;
    lblPublic: TLabel;
    lblPrivate: TLabel;
    cbSector: TComboBox;
    btnCreatePanel: TPanel;
    btnCancelPanel: TPanel;
    procedure btnCreateClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure lblPublicClick(Sender: TObject);
    procedure lblPrivateClick(Sender: TObject);
  public
    SelectedWorkspaceID: Integer;
    SelectedPrivacyPublic: Boolean;
    SelectedSector: string;
    BoardTitleText: string;
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
    procedure PopulateWorkspaces(CurrentWorkspaceID: Integer);
  end;

implementation

constructor TFormNewBoard.CreateNew(AOwner: TComponent; Num: Integer = 0);
var
  lblTitle: TLabel;
  lblBoardTitle: TLabel;
  lblWorkspace: TLabel;
  lblPrivacy: TLabel;
  lblSector: TLabel;
begin
  inherited CreateNew(AOwner, Num);
  
  Caption := 'Novo Quadro';
  Position := poOwnerFormCenter;
  BorderStyle := bsDialog;
  ClientWidth := 380;
  ClientHeight := 470;
  Color := $141212; // Premium dark slate/black (BGR)
  Font.Name := 'Segoe UI';
  Font.Color := clWhite;
  
  // 1. Header Title
  lblTitle := TLabel.Create(Self);
  lblTitle.Parent := Self;
  lblTitle.Caption := 'New Board';
  lblTitle.Font.Size := 16;
  lblTitle.Font.Style := [fsBold];
  lblTitle.SetBounds(24, 24, 300, 30);
  
  // 2. Board Title label & edit
  lblBoardTitle := TLabel.Create(Self);
  lblBoardTitle.Parent := Self;
  lblBoardTitle.Caption := 'Board Title';
  lblBoardTitle.Font.Size := 9;
  lblBoardTitle.Font.Color := $A0A0A0;
  lblBoardTitle.SetBounds(24, 70, 300, 15);
  
  edtBoardTitle := TEdit.Create(Self);
  edtBoardTitle.Parent := Self;
  edtBoardTitle.Text := '';
  edtBoardTitle.Color := $252222; // Dark input background
  edtBoardTitle.Font.Size := 10;
  edtBoardTitle.Font.Color := clWhite;
  edtBoardTitle.BorderStyle := bsSingle;
  edtBoardTitle.SetBounds(24, 90, 332, 28);
  
  // 3. Workspace label & combobox
  lblWorkspace := TLabel.Create(Self);
  lblWorkspace.Parent := Self;
  lblWorkspace.Caption := 'Select Workspace:';
  lblWorkspace.Font.Size := 9;
  lblWorkspace.Font.Color := $A0A0A0;
  lblWorkspace.SetBounds(24, 135, 300, 15);
  
  cbWorkspace := TComboBox.Create(Self);
  cbWorkspace.Parent := Self;
  cbWorkspace.Style := csDropDownList;
  cbWorkspace.Color := $252222;
  cbWorkspace.Font.Size := 10;
  cbWorkspace.Font.Color := clWhite;
  cbWorkspace.SetBounds(24, 155, 332, 28);
  
  // 4. Privacy label & radiobuttons
  lblPrivacy := TLabel.Create(Self);
  lblPrivacy.Parent := Self;
  lblPrivacy.Caption := 'Privacidade';
  lblPrivacy.Font.Size := 9;
  lblPrivacy.Font.Color := $A0A0A0;
  lblPrivacy.SetBounds(24, 205, 300, 15);
  
  rbPublic := TRadioButton.Create(Self);
  rbPublic.Parent := Self;
  rbPublic.Caption := '';
  rbPublic.Checked := True;
  rbPublic.SetBounds(24, 225, 20, 20);
  
  lblPublic := TLabel.Create(Self);
  lblPublic.Parent := Self;
  lblPublic.Caption := 'Público';
  lblPublic.Font.Size := 10;
  lblPublic.Font.Color := clWhite;
  lblPublic.SetBounds(48, 227, 70, 20);
  lblPublic.Cursor := crHandPoint;
  lblPublic.OnClick := @lblPublicClick;
  
  rbPrivate := TRadioButton.Create(Self);
  rbPrivate.Parent := Self;
  rbPrivate.Caption := '';
  rbPrivate.SetBounds(130, 225, 20, 20);
  
  lblPrivate := TLabel.Create(Self);
  lblPrivate.Parent := Self;
  lblPrivate.Caption := 'Privado';
  lblPrivate.Font.Size := 10;
  lblPrivate.Font.Color := clWhite;
  lblPrivate.SetBounds(154, 227, 70, 20);
  lblPrivate.Cursor := crHandPoint;
  lblPrivate.OnClick := @lblPrivateClick;
  
  // 5. Sector label & combobox
  lblSector := TLabel.Create(Self);
  lblSector.Parent := Self;
  lblSector.Caption := 'Setor';
  lblSector.Font.Size := 9;
  lblSector.Font.Color := $A0A0A0;
  lblSector.SetBounds(24, 265, 300, 15);
  
  cbSector := TComboBox.Create(Self);
  cbSector.Parent := Self;
  cbSector.Style := csDropDownList;
  cbSector.Color := $252222;
  cbSector.Font.Size := 10;
  cbSector.Font.Color := clWhite;
  cbSector.SetBounds(24, 285, 332, 28);
  cbSector.Items.Add('Desenvolvimento');
  cbSector.Items.Add('Técnico');
  cbSector.Items.Add('Implantação');
  cbSector.Items.Add('Comercial');
  cbSector.Items.Add('Administrativo');
  cbSector.Items.Add('Marketing');
  cbSector.ItemIndex := 0;
  
  // 6. Action buttons (Styled as panels)
  btnCreatePanel := TPanel.Create(Self);
  btnCreatePanel.Parent := Self;
  btnCreatePanel.Caption := 'Create Board';
  btnCreatePanel.Color := $E5464F; // Vibrant Purple-blue (BGR)
  btnCreatePanel.Font.Size := 10;
  btnCreatePanel.Font.Style := [fsBold];
  btnCreatePanel.Font.Color := clWhite;
  btnCreatePanel.BevelOuter := bvNone;
  btnCreatePanel.SetBounds(24, 380, 156, 40);
  btnCreatePanel.Cursor := crHandPoint;
  btnCreatePanel.OnClick := @btnCreateClick;
  
  btnCancelPanel := TPanel.Create(Self);
  btnCancelPanel.Parent := Self;
  btnCancelPanel.Caption := 'Cancelar';
  btnCancelPanel.Color := $252222; // Dark charcoal
  btnCancelPanel.Font.Size := 10;
  btnCancelPanel.Font.Color := clWhite;
  btnCancelPanel.BevelOuter := bvNone;
  btnCancelPanel.SetBounds(200, 380, 156, 40);
  btnCancelPanel.Cursor := crHandPoint;
  btnCancelPanel.OnClick := @btnCancelClick;
end;

procedure TFormNewBoard.PopulateWorkspaces(CurrentWorkspaceID: Integer);
var
  Q: TIBQuery;
  WorkspaceName: string;
  WID: Integer;
  Idx: Integer;
begin
  cbWorkspace.Items.Clear;
  
  Q := TIBQuery.Create(nil);
  try
    Q.Database := DataModule1.IBDatabase1;
    Q.Transaction := DataModule1.IBTransaction1;
    Q.SQL.Text := 'SELECT W.ID, W.NAME FROM "Workspace" W ' +
                  'INNER JOIN "WorkspaceMember" M ON W.ID = M.WORKSPACEID ' +
                  'WHERE M.USERID = :USERID ORDER BY W.NAME';
    Q.ParamByName('USERID').AsInteger := LoggedUserID;
    Q.Open;
    
    while not Q.Eof do
    begin
      WID := Q.FieldByName('ID').AsInteger;
      WorkspaceName := Q.FieldByName('NAME').AsString;
      cbWorkspace.Items.AddObject(WorkspaceName, TObject(PtrInt(WID)));
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
  
  if cbWorkspace.Items.Count > 0 then
  begin
    cbWorkspace.ItemIndex := 0;
    for Idx := 0 to cbWorkspace.Items.Count - 1 do
    begin
      if Integer(PtrInt(cbWorkspace.Items.Objects[Idx])) = CurrentWorkspaceID then
      begin
        cbWorkspace.ItemIndex := Idx;
        Break;
      end;
    end;
  end;
end;

procedure TFormNewBoard.btnCreateClick(Sender: TObject);
begin
  BoardTitleText := Trim(edtBoardTitle.Text);
  if BoardTitleText = '' then
  begin
    ShowMessage('Por favor, preencha o título do Quadro.');
    Exit;
  end;
  
  if cbWorkspace.ItemIndex = -1 then
  begin
    ShowMessage('Por favor, selecione uma Área de Trabalho.');
    Exit;
  end;
  
  SelectedWorkspaceID := Integer(PtrInt(cbWorkspace.Items.Objects[cbWorkspace.ItemIndex]));
  SelectedPrivacyPublic := rbPublic.Checked;
  SelectedSector := cbSector.Text;
  
  ModalResult := mrOk;
end;

procedure TFormNewBoard.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFormNewBoard.lblPublicClick(Sender: TObject);
begin
  rbPublic.Checked := True;
end;

procedure TFormNewBoard.lblPrivateClick(Sender: TObject);
begin
  rbPrivate.Checked := True;
end;

end.
