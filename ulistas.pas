unit uListas;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  Buttons, StdCtrls, uHeaderScrollBox, uTaskCard, db, IBQuery, uTaskDetail;

type

  { TForm2 }

  TForm2 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    BitBtn6: TBitBtn;
    Edit1: TEdit;
    Edit3: TEdit;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    ScrollBox1: TScrollBox;
    ScrollBox2: TScrollBox;
    Shape1: TShape;
    StatusBar1: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn6Click(Sender: TObject);
  private
    FBoardID: Integer;
    FBoardColor: TColor;

    // Blends Color1 towards Color2 by Factor (0.0=Color1, 1.0=Color2)
    function BlendColor(Color1, Color2: TColor; Factor: Single): TColor;
    // Converts a hex color string like '#FF5252' to TColor (BGR for LCL/Windows)
    function HexColorToTColor(const AHex: string): TColor;
    function PriorityToColor(const APriority: string): TColor;
    function CardDisplayColor(const AHexStr, APriority: string): TColor;

    // Card persistence handlers
    procedure TaskCardAdded(Sender: TObject; Card: TTaskCard);
    procedure TaskCardEdit(Sender: TObject);
    procedure TaskCardDelete(Sender: TObject);
    procedure TaskCardMoved(Sender: TObject; Card: TTaskCard;
      SourceList, TargetList: THeaderScrollBox);
    procedure ListDelete(Sender: TObject);

    // Card copy/status handlers
    procedure TaskCardCopy(Sender: TObject);
    procedure TaskCardDetail(Sender: TObject);

  public
    // Called from TForm1 when the user clicks a board card
    procedure LoadBoard(ABoardID: Integer; const ABoardTitle: string;
      ABoardColor: TColor);
  end;

var
  Form2: TForm2;

implementation

uses
  uLogin, udm, LCLIntf;

{$R *.lfm}

// ---------------------------------------------------------------------------
// Colour helpers
// ---------------------------------------------------------------------------

function TForm2.BlendColor(Color1, Color2: TColor; Factor: Single): TColor;
var
  R1, G1, B1, R2, G2, B2: Byte;
begin
  // LCL stores colors as BGR
  R1 := Color1 and $FF;
  G1 := (Color1 shr 8) and $FF;
  B1 := (Color1 shr 16) and $FF;

  R2 := Color2 and $FF;
  G2 := (Color2 shr 8) and $FF;
  B2 := (Color2 shr 16) and $FF;

  Result := TColor(
    Round(R1 + (R2 - R1) * Factor) or
    (Round(G1 + (G2 - G1) * Factor) shl 8) or
    (Round(B1 + (B2 - B1) * Factor) shl 16)
  );
end;

function TForm2.HexColorToTColor(const AHex: string): TColor;
var
  S: string;
  R, G, B: Byte;
begin
  Result := $0C0C0C; // default: near-black
  S := Trim(AHex);
  if (Length(S) > 0) and (S[1] = '#') then
    Delete(S, 1, 1);
  if Length(S) <> 6 then Exit;
  try
    R := StrToInt('$' + Copy(S, 1, 2));
    G := StrToInt('$' + Copy(S, 3, 2));
    B := StrToInt('$' + Copy(S, 5, 2));
    // LCL Windows BGR order
    Result := TColor(R or (G shl 8) or (B shl 16));
  except
    // Keep default
  end;
end;

// Returns the priority colour matching EXACTLY the web React component (SortableCard.jsx)
// Web source: client/src/components/SortableCard.jsx -> getPriorityStyles()
function TForm2.PriorityToColor(const APriority: string): TColor;
var
  S: string;
begin
  S := AnsiLowerCase(Trim(APriority));
  // 'Alta' -> #ff6b6b (red-orange)
  if S = 'alta' then
    Result := HexColorToTColor('#ff6b6b')
  // 'Média' / 'Media' -> #ffec99 (yellow)
  else if (Pos('dia', S) > 0) and (S[1] = 'm') then
    Result := HexColorToTColor('#ffec99')
  // 'Observação' -> #2ecc71 (green)
  else if (Pos('serva', S) > 0) then
    Result := HexColorToTColor('#2ecc71')
  // 'Ideia' -> #3498db (blue)
  else if S = 'ideia' then
    Result := HexColorToTColor('#3498db')
  // 'URGENTE' -> #9b59b6 (purple)
  else if S = 'urgente' then
    Result := HexColorToTColor('#9b59b6')
  // 'Recuperado' -> #ff69b4 (pink)
  else if S = 'recuperado' then
    Result := HexColorToTColor('#ff69b4')
  else
    // 'Baixa' and default -> black (#000000), same as web
    Result := HexColorToTColor('#000000');
end;

// Returns the best colour for a card: hexColor from DB when valid, otherwise priority colour
function TForm2.CardDisplayColor(const AHexStr, APriority: string): TColor;
var
  S: string;
begin
  S := Trim(AHexStr);
  // A valid stored colour must be exactly '#RRGGBB' (7 chars) and contain only hex digits
  if (Length(S) = 7) and (S[1] = '#') then
  begin
    try
      StrToInt('$' + Copy(S, 2, 2));
      StrToInt('$' + Copy(S, 4, 2));
      StrToInt('$' + Copy(S, 6, 2));
      // All three converted OK → it is a real hex colour
      Result := HexColorToTColor(S);
      Exit;
    except
      // Fall through to priority colour
    end;
  end;
  Result := PriorityToColor(APriority);
end;

// ---------------------------------------------------------------------------
// Form events
// ---------------------------------------------------------------------------

procedure TForm2.FormCreate(Sender: TObject);
begin
  FBoardID := 0;
  FBoardColor := $2D2D2D;
end;

procedure TForm2.BitBtn1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm2.BitBtn6Click(Sender: TObject);
var
  ListName: string;
  Q: TIBQuery;
  NewListID: Integer;
  NewBox: THeaderScrollBox;
  ListColor: TColor;
begin
  ListName := Trim(Edit3.Text);
  if ListName = '' then
  begin
    ShowMessage('Digite o nome da nova lista.');
    Edit3.SetFocus;
    Exit;
  end;

  if FBoardID = 0 then
  begin
    ShowMessage('Nenhum quadro carregado.');
    Exit;
  end;

  // Count existing lists to determine IDX_POSITION
  Q := TIBQuery.Create(nil);
  try
    Q.Database := DataModule1.IBDatabase1;
    Q.Transaction := DataModule1.IBTransaction1;

    Q.SQL.Text := 'SELECT COUNT(*) FROM "List" WHERE BOARDID = :BOARDID';
    Q.ParamByName('BOARDID').DataType := ftInteger;
    Q.ParamByName('BOARDID').AsInteger := FBoardID;
    Q.Open;
    NewListID := Q.Fields[0].AsInteger; // will be used as IDX_POSITION
    Q.Close;

    Q.SQL.Text :=
      'INSERT INTO "List" (TITLE, IDX_POSITION, BOARDID) VALUES (:TITLE, :IDX, :BOARDID)';
    Q.ParamByName('TITLE').DataType := ftString;
    Q.ParamByName('TITLE').AsString := ListName;
    Q.ParamByName('IDX').DataType := ftInteger;
    Q.ParamByName('IDX').AsInteger := NewListID;
    Q.ParamByName('BOARDID').DataType := ftInteger;
    Q.ParamByName('BOARDID').AsInteger := FBoardID;
    Q.ExecSQL;

    Q.SQL.Text := 'SELECT MAX(ID) FROM "List" WHERE BOARDID = :BOARDID';
    Q.ParamByName('BOARDID').DataType := ftInteger;
    Q.ParamByName('BOARDID').AsInteger := FBoardID;
    Q.Open;
    NewListID := Q.Fields[0].AsInteger;
    Q.Close;

    DataModule1.IBTransaction1.CommitRetaining;
  except
    on E: Exception do
    begin
      Q.Free;
      ShowMessage('Erro ao criar lista: ' + E.Message);
      Exit;
    end;
  end;
  Q.Free;

  // Compute list panel colour (same formula as LoadBoard)
  ListColor := BlendColor(FBoardColor, $FFFFFF, 0.60);
  ListColor := BlendColor(ListColor, $000000, 0.12);

  // Create the new column dynamically
  NewBox := THeaderScrollBox.Create(Self);
  NewBox.Parent := ScrollBox2;
  NewBox.Align := alLeft;
  NewBox.Left := NewListID * 300;
  NewBox.BringToFront;
  NewBox.Width := 220;
  NewBox.BorderSpacing.Left := 10;
  NewBox.BorderSpacing.Right := 4;
  NewBox.Color := ListColor;
  NewBox.HeaderColor := ListColor;
  NewBox.HeaderCaption := ListName;
  NewBox.ListID := NewListID;
  NewBox.DefaultUserName := LoggedUserName;
  NewBox.OnCardAdded := @TaskCardAdded;
  NewBox.OnCardCopy := @TaskCardCopy;
  NewBox.OnCardEdit := @TaskCardEdit;
  NewBox.OnCardDelete := @TaskCardDelete;
  NewBox.OnCardMoved := @TaskCardMoved;
  NewBox.OnListDelete := @ListDelete;

  Edit3.Text := '';
  StatusBar1.SimpleText := 'Lista "' + ListName + '" criada com sucesso.';
end;

// ---------------------------------------------------------------------------
// Main loader
// ---------------------------------------------------------------------------

procedure TForm2.LoadBoard(ABoardID: Integer; const ABoardTitle: string;
  ABoardColor: TColor);
var
  I, K: Integer;
  Ctrl: TControl;
  HaveFree: Boolean;
  BgColor, ListColor: TColor;
  Q_List, Q_Card: TIBQuery;
  ListID: Integer;
  ListTitle: string;
  NewBox: THeaderScrollBox;
  NewCard: TTaskCard;
  HexStr: string;
  ColumnsList: TList;
  CardsList: TList;
begin
  FBoardID := ABoardID;
  FBoardColor := ABoardColor;
  Caption := ABoardTitle;

  // ---------- clear existing columns ----------
  ScrollBox2.DisableAlign;
  try
    HaveFree := True;
    while HaveFree do
    begin
      HaveFree := False;
      for I := 0 to ScrollBox2.ControlCount - 1 do
      begin
        Ctrl := ScrollBox2.Controls[I];
        if Ctrl is THeaderScrollBox then
        begin
          Ctrl.Free;
          HaveFree := True;
          Break;
        end;
      end;
    end;
  finally
    ScrollBox2.EnableAlign;
  end;

  // ---------- compute colours ----------
  // Background: blend board colour heavily towards white → pastel
  BgColor := BlendColor(ABoardColor, $FFFFFF, 0.78);
  ScrollBox2.Color := BgColor;

  // List headers: a bit darker than the background
  ListColor := BlendColor(ABoardColor, $FFFFFF, 0.60);
  ListColor := BlendColor(ListColor, $000000, 0.12);

  // ---------- load lists from DB ----------
  if ABoardID = 0 then Exit;

  try
    if not DataModule1.IBDatabase1.Connected then
      DataModule1.IBDatabase1.Connected := True;
    if DataModule1.IBTransaction1.Active then
      DataModule1.IBTransaction1.Commit;
    DataModule1.IBTransaction1.StartTransaction;
  except
    on E: Exception do
    begin
      ShowMessage('Erro de conexão: ' + E.Message);
      Exit;
    end;
  end;

  ColumnsList := TList.Create;
  CardsList := TList.Create;
  Q_List := TIBQuery.Create(nil);
  Q_Card := TIBQuery.Create(nil);
  try
    Q_List.Database := DataModule1.IBDatabase1;
    Q_List.Transaction := DataModule1.IBTransaction1;
    Q_Card.Database := DataModule1.IBDatabase1;
    Q_Card.Transaction := DataModule1.IBTransaction1;

    Q_List.SQL.Text :=
      'SELECT ID, TITLE, IDX_POSITION FROM "List" WHERE BOARDID = :BOARDID ORDER BY IDX_POSITION';
    Q_List.ParamByName('BOARDID').DataType := ftInteger;
    Q_List.ParamByName('BOARDID').AsInteger := ABoardID;
    Q_List.Open;

    ScrollBox2.DisableAlign;
    try
      while not Q_List.Eof do
      begin
        ListID := Q_List.FieldByName('ID').AsInteger;
        ListTitle := Q_List.FieldByName('TITLE').AsString;

        // Create column
        NewBox := THeaderScrollBox.Create(Self);
        NewBox.Parent := ScrollBox2;
        NewBox.Align := alLeft;
        NewBox.Left := Q_List.FieldByName('IDX_POSITION').AsInteger * 300;
        NewBox.Width := 220;
        NewBox.BorderSpacing.Left := 10;
        NewBox.BorderSpacing.Right := 4;
        NewBox.Color := ListColor;
        NewBox.HeaderColor := ListColor;
        NewBox.HeaderCaption := ListTitle;
        NewBox.ListID := ListID;
        NewBox.DefaultUserName := LoggedUserName;
        NewBox.OnCardAdded := @TaskCardAdded;
        NewBox.OnCardCopy := @TaskCardCopy;
        NewBox.OnCardEdit := @TaskCardEdit;
        NewBox.OnCardDelete := @TaskCardDelete;
        NewBox.OnCardMoved := @TaskCardMoved;
        NewBox.OnListDelete := @ListDelete;
        
        ColumnsList.Add(NewBox);

        // Load cards for this list
        CardsList.Clear;
        Q_Card.SQL.Text :=
          'SELECT ID, TITLE, TICKETID, CREATEDAT, "hexColor", PRIORITY, IDX_POSITION ' +
          'FROM "Card" WHERE LISTID = :LISTID ORDER BY IDX_POSITION';
        Q_Card.ParamByName('LISTID').DataType := ftInteger;
        Q_Card.ParamByName('LISTID').AsInteger := ListID;
        Q_Card.Open;

        while not Q_Card.Eof do
        begin
          NewCard := TTaskCard.Create(Self);
          NewCard.Parent := NewBox;
          NewCard.Align := alTop;
          NewCard.Top := Q_Card.FieldByName('IDX_POSITION').AsInteger * 250;
          NewCard.CardID := Q_Card.FieldByName('ID').AsInteger;
          NewCard.TaskText := Q_Card.FieldByName('TITLE').AsString;
          NewCard.TaskCode := Q_Card.FieldByName('TICKETID').AsString;
          if not Q_Card.FieldByName('CREATEDAT').IsNull then
            NewCard.TaskDate :=
              FormatDateTime('dd/mm/yyyy', Q_Card.FieldByName('CREATEDAT').AsDateTime)
          else
            NewCard.TaskDate := '';
          NewCard.UserName := LoggedUserName;

          // Resolve card colour: prefer hexColor from DB, fall back to PRIORITY palette
          HexStr := '';
          if not Q_Card.FieldByName('hexColor').IsNull then
            HexStr := Trim(Q_Card.FieldByName('hexColor').AsString);
          NewCard.BackgroundColor :=
            CardDisplayColor(HexStr, Q_Card.FieldByName('PRIORITY').AsString);

          NewCard.OnCopyClick := @TaskCardCopy;
          NewCard.OnEditClick := @TaskCardEdit;
          NewCard.OnDeleteClick := @TaskCardDelete;
          NewCard.OnCardDetail := @TaskCardDetail;

          CardsList.Add(NewCard);
          Q_Card.Next;
        end;
        Q_Card.Close;

        // Force explicit card ordering from top to bottom
        NewBox.CardsScrollBox.DisableAlign;
        try
          for K := 0 to CardsList.Count - 1 do
            TControl(CardsList[K]).BringToFront;
        finally
          NewBox.CardsScrollBox.EnableAlign;
        end;

        Q_List.Next;
      end;
    finally
      ScrollBox2.EnableAlign;
    end;

    Q_List.Close;

    // Force explicit column ordering from left to right
    ScrollBox2.DisableAlign;
    try
      for I := 0 to ColumnsList.Count - 1 do
        TControl(ColumnsList[I]).BringToFront;
    finally
      ScrollBox2.EnableAlign;
    end;

  finally
    ColumnsList.Free;
    CardsList.Free;
    Q_List.Free;
    Q_Card.Free;
  end;

  StatusBar1.SimpleText := 'Quadro "' + ABoardTitle + '" carregado.';
end;

// ---------------------------------------------------------------------------
// DB persistence handlers
// ---------------------------------------------------------------------------

procedure TForm2.TaskCardAdded(Sender: TObject; Card: TTaskCard);
var
  Q: TIBQuery;
  Box: THeaderScrollBox;
  MaxPos: Integer;
  HexColor: string;
  R, G, B: Byte;
begin
  if not (Sender is THeaderScrollBox) then Exit;
  Box := THeaderScrollBox(Sender);

  // Convert the card's BackgroundColor (BGR) to hex string (#RRGGBB)
  R := Card.BackgroundColor and $FF;
  G := (Card.BackgroundColor shr 8) and $FF;
  B := (Card.BackgroundColor shr 16) and $FF;
  HexColor := '#' + IntToHex(R, 2) + IntToHex(G, 2) + IntToHex(B, 2);

  Q := TIBQuery.Create(nil);
  try
    Q.Database := DataModule1.IBDatabase1;
    Q.Transaction := DataModule1.IBTransaction1;

    // Get max position in this list
    Q.SQL.Text := 'SELECT COUNT(*) FROM "Card" WHERE LISTID = :LISTID';
    Q.ParamByName('LISTID').DataType := ftInteger;
    Q.ParamByName('LISTID').AsInteger := Box.ListID;
    Q.Open;
    MaxPos := Q.Fields[0].AsInteger;
    Q.Close;

    Q.SQL.Text :=
      'INSERT INTO "Card" (TITLE, PRIORITY, TICKETID, IDX_POSITION, LISTID, CREATORID, "hexColor") ' +
      'VALUES (:TITLE, :PRIORITY, :TICKETID, :IDX, :LISTID, :CREATORID, :HEXCOLOR)';
    Q.ParamByName('TITLE').DataType := ftString;
    Q.ParamByName('TITLE').AsString := Card.TaskText;
    Q.ParamByName('PRIORITY').DataType := ftString;
    Q.ParamByName('PRIORITY').AsString := 'Baixa';
    Q.ParamByName('TICKETID').DataType := ftString;
    Q.ParamByName('TICKETID').AsString := Card.TaskCode;
    Q.ParamByName('IDX').DataType := ftInteger;
    Q.ParamByName('IDX').AsInteger := MaxPos;
    Q.ParamByName('LISTID').DataType := ftInteger;
    Q.ParamByName('LISTID').AsInteger := Box.ListID;
    Q.ParamByName('CREATORID').DataType := ftInteger;
    if LoggedUserID > 0 then
      Q.ParamByName('CREATORID').AsInteger := LoggedUserID
    else
      Q.ParamByName('CREATORID').Clear;
    Q.ParamByName('HEXCOLOR').DataType := ftString;
    Q.ParamByName('HEXCOLOR').AsString := HexColor;
    Q.ExecSQL;

    // Retrieve the generated ID
    Q.SQL.Text :=
      'SELECT MAX(ID) FROM "Card" WHERE LISTID = :LISTID';
    Q.ParamByName('LISTID').DataType := ftInteger;
    Q.ParamByName('LISTID').AsInteger := Box.ListID;
    Q.Open;
    Card.CardID := Q.Fields[0].AsInteger;
    Q.Close;

    DataModule1.IBTransaction1.CommitRetaining;
    StatusBar1.SimpleText := 'Tarefa "' + Card.TaskCode + '" adicionada.';
  except
    on E: Exception do
    begin
      Q.Free;
      ShowMessage('Erro ao salvar tarefa: ' + E.Message);
      Exit;
    end;
  end;
  Q.Free;
end;

procedure TForm2.TaskCardCopy(Sender: TObject);
begin
  if Sender is TTaskCard then
    StatusBar1.SimpleText :=
      'Código "' + TTaskCard(Sender).TaskCode + '" copiado para a área de transferência.';
end;

procedure TForm2.TaskCardDetail(Sender: TObject);
var
  Card: TTaskCard;
begin
  if not (Sender is TTaskCard) then Exit;
  Card := TTaskCard(Sender);
  if Card.CardID = 0 then Exit;

  if FormTaskDetail = nil then
    FormTaskDetail := TFormTaskDetail.Create(Application);

  FormTaskDetail.LoadCard(Card.CardID);
end;

procedure TForm2.TaskCardEdit(Sender: TObject);
var
  Q: TIBQuery;
  Card: TTaskCard;
begin
  if not (Sender is TTaskCard) then Exit;
  Card := TTaskCard(Sender);
  if Card.CardID = 0 then Exit;

  Q := TIBQuery.Create(nil);
  try
    Q.Database := DataModule1.IBDatabase1;
    Q.Transaction := DataModule1.IBTransaction1;
    Q.SQL.Text := 'UPDATE "Card" SET TITLE = :TITLE, UPDATEDAT = CURRENT_TIMESTAMP WHERE ID = :ID';
    Q.ParamByName('TITLE').DataType := ftString;
    Q.ParamByName('TITLE').AsString := Card.TaskText;
    Q.ParamByName('ID').DataType := ftInteger;
    Q.ParamByName('ID').AsInteger := Card.CardID;
    Q.ExecSQL;
    DataModule1.IBTransaction1.CommitRetaining;
    StatusBar1.SimpleText := 'Tarefa "' + Card.TaskCode + '" atualizada.';
  except
    on E: Exception do
    begin
      Q.Free;
      ShowMessage('Erro ao editar tarefa: ' + E.Message);
      Exit;
    end;
  end;
  Q.Free;
end;

procedure TForm2.TaskCardDelete(Sender: TObject);
var
  Q: TIBQuery;
  Card: TTaskCard;
begin
  if not (Sender is TTaskCard) then Exit;
  Card := TTaskCard(Sender);
  if Card.CardID = 0 then Exit;

  Q := TIBQuery.Create(nil);
  try
    Q.Database := DataModule1.IBDatabase1;
    Q.Transaction := DataModule1.IBTransaction1;
    Q.SQL.Text := 'DELETE FROM "Card" WHERE ID = :ID';
    Q.ParamByName('ID').DataType := ftInteger;
    Q.ParamByName('ID').AsInteger := Card.CardID;
    Q.ExecSQL;
    DataModule1.IBTransaction1.CommitRetaining;
    StatusBar1.SimpleText := 'Tarefa "' + Card.TaskCode + '" excluída.';
  except
    on E: Exception do
    begin
      Q.Free;
      ShowMessage('Erro ao excluir tarefa: ' + E.Message);
      Exit;
    end;
  end;
  Q.Free;
end;

procedure TForm2.TaskCardMoved(Sender: TObject; Card: TTaskCard;
  SourceList, TargetList: THeaderScrollBox);
var
  Q: TIBQuery;
  CardsList: TList;
  I: Integer;
  C: TTaskCard;
begin
  if Card.CardID = 0 then Exit;
  if TargetList = nil then Exit;

  Q := TIBQuery.Create(nil);
  CardsList := TList.Create;
  try
    Q.Database := DataModule1.IBDatabase1;
    Q.Transaction := DataModule1.IBTransaction1;

    // If lists are different, update the LISTID of the card first
    if SourceList <> TargetList then
    begin
      Q.SQL.Text := 'UPDATE "Card" SET LISTID = :LISTID, UPDATEDAT = CURRENT_TIMESTAMP WHERE ID = :ID';
      Q.ParamByName('LISTID').DataType := ftInteger;
      Q.ParamByName('LISTID').AsInteger := TargetList.ListID;
      Q.ParamByName('ID').DataType := ftInteger;
      Q.ParamByName('ID').AsInteger := Card.CardID;
      Q.ExecSQL;
    end;

    // Now re-index cards in the target list
    TargetList.GetSortedCards(CardsList);
    for I := 0 to CardsList.Count - 1 do
    begin
      C := TTaskCard(CardsList[I]);
      if C.CardID <> 0 then
      begin
        Q.SQL.Text := 'UPDATE "Card" SET IDX_POSITION = :IDX WHERE ID = :ID';
        Q.ParamByName('IDX').DataType := ftInteger;
        Q.ParamByName('IDX').AsInteger := I;
        Q.ParamByName('ID').DataType := ftInteger;
        Q.ParamByName('ID').AsInteger := C.CardID;
        Q.ExecSQL;
      end;
    end;

    // If source list was different, also re-index cards in the source list to close the gap
    if (SourceList <> nil) and (SourceList <> TargetList) then
    begin
      CardsList.Clear;
      SourceList.GetSortedCards(CardsList);
      for I := 0 to CardsList.Count - 1 do
      begin
        C := TTaskCard(CardsList[I]);
        if C.CardID <> 0 then
        begin
          Q.SQL.Text := 'UPDATE "Card" SET IDX_POSITION = :IDX WHERE ID = :ID';
          Q.ParamByName('IDX').DataType := ftInteger;
          Q.ParamByName('IDX').AsInteger := I;
          Q.ParamByName('ID').DataType := ftInteger;
          Q.ParamByName('ID').AsInteger := C.CardID;
          Q.ExecSQL;
        end;
      end;
    end;

    DataModule1.IBTransaction1.CommitRetaining;
    
    if SourceList <> TargetList then
      StatusBar1.SimpleText := 'Tarefa "' + Card.TaskCode + '" movida de "' + SourceList.HeaderCaption + '" para "' + TargetList.HeaderCaption + '".'
    else
      StatusBar1.SimpleText := 'Tarefa "' + Card.TaskCode + '" reordenada em "' + TargetList.HeaderCaption + '".';
      
  except
    on E: Exception do
    begin
      DataModule1.IBTransaction1.RollbackRetaining;
      ShowMessage('Erro ao atualizar posições no banco de dados: ' + E.Message);
    end;
  end;
  
  CardsList.Free;
  Q.Free;
end;

procedure TForm2.ListDelete(Sender: TObject);
var
  Q: TIBQuery;
  Box: THeaderScrollBox;
begin
  if not (Sender is THeaderScrollBox) then Exit;
  Box := THeaderScrollBox(Sender);
  if Box.ListID = 0 then Exit;

  Q := TIBQuery.Create(nil);
  try
    Q.Database := DataModule1.IBDatabase1;
    Q.Transaction := DataModule1.IBTransaction1;

    // Delete all cards in this list
    Q.SQL.Text := 'DELETE FROM "Card" WHERE LISTID = :LISTID';
    Q.ParamByName('LISTID').DataType := ftInteger;
    Q.ParamByName('LISTID').AsInteger := Box.ListID;
    Q.ExecSQL;

    // Delete the list itself
    Q.SQL.Text := 'DELETE FROM "List" WHERE ID = :ID';
    Q.ParamByName('ID').DataType := ftInteger;
    Q.ParamByName('ID').AsInteger := Box.ListID;
    Q.ExecSQL;

    DataModule1.IBTransaction1.CommitRetaining;
    StatusBar1.SimpleText := 'Lista "' + Box.HeaderCaption + '" excluída.';
  except
    on E: Exception do
    begin
      Q.Free;
      ShowMessage('Erro ao excluir lista: ' + E.Message);
      Exit;
    end;
  end;
  Q.Free;
end;

end.
