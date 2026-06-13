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
    Edit1: TEdit;
    Panel1: TPanel;
    ScrollBox1: TScrollBox;
    StatusBar1: TStatusBar;
    procedure BoardCard1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
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
    procedure ParseBoardColors(AColorStr: string; out AStart, AEnd: TColor);
  public
    procedure LoadWorkspacesAndBoards;
  end;

var
  Form1: TForm1;

implementation

uses
  uListas, uLogin, udm, db;

{$R *.lfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
end;

procedure TForm1.FormShow(Sender: TObject);
var
  LoginForm: TForm3;
begin
  OnShow := nil;
  LoginForm := TForm3.Create(nil);
  try
    if LoginForm.ShowModal = mrOk then
    begin
      LoadWorkspacesAndBoards;
    end
    else
    begin
      Application.Terminate;
    end;
  finally
    LoginForm.Free;
  end;
end;

procedure TForm1.ParseBoardColors(AColorStr: string; out AStart, AEnd: TColor);
var
  S: string;
  P: Integer;
  FS: TFormatSettings;
  Tokens: TStringList;
  HVal, SVal, LVal: Double;
  HStr, SStr, LStr: string;
  R, G, B: Byte;
  
  function HSLToRGB(H, S, L: Double): TColor;
  var
    C, X, M: Double;
    R1, G1, B1: Double;
    RVal, GVal, BVal: Byte;
    HPrime: Double;
  begin
    if H < 0 then H := 0;
    if H > 360 then H := 360;
    if S < 0 then S := 0;
    if S > 1 then S := 1;
    if L < 0 then L := 0;
    if L > 1 then L := 1;

    C := (1.0 - Abs(2.0 * L - 1.0)) * S;
    HPrime := H / 60.0;
    X := C * (1.0 - Abs(Frac(HPrime / 2.0) * 2.0 - 1.0));
    
    R1 := 0; G1 := 0; B1 := 0;
    if (HPrime >= 0) and (HPrime < 1) then
    begin
      R1 := C; G1 := X; B1 := 0;
    end
    else if (HPrime >= 1) and (HPrime < 2) then
    begin
      R1 := X; G1 := C; B1 := 0;
    end
    else if (HPrime >= 2) and (HPrime < 3) then
    begin
      R1 := 0; G1 := C; B1 := X;
    end
    else if (HPrime >= 3) and (HPrime < 4) then
    begin
      R1 := 0; G1 := X; B1 := C;
    end
    else if (HPrime >= 4) and (HPrime < 5) then
    begin
      R1 := X; G1 := 0; B1 := C;
    end
    else if (HPrime >= 5) and (HPrime <= 6) then
    begin
      R1 := C; G1 := 0; B1 := X;
    end;

    M := L - C / 2.0;
    RVal := Round((R1 + M) * 255);
    GVal := Round((G1 + M) * 255);
    BVal := Round((B1 + M) * 255);
    
    Result := TColor(RVal or (GVal shl 8) or (BVal shl 16));
  end;

begin
  // Set fallback defaults (BGR)
  AStart := $D87A3B; // Vibrant Blue
  AEnd := $35261D;   // Dark Navy
  
  S := Trim(AColorStr);
  if S = '' then Exit;
  
  if Pos('hsl', LowerCase(S)) = 1 then
  begin
    P := Pos('(', S);
    if P > 0 then
    begin
      S := Copy(S, P + 1, Length(S) - P);
      P := Pos(')', S);
      if P > 0 then
        S := Copy(S, 1, P - 1);
      
      Tokens := TStringList.Create;
      try
        Tokens.Delimiter := ',';
        Tokens.StrictDelimiter := True;
        Tokens.DelimitedText := S;
        
        if Tokens.Count >= 3 then
        begin
          HStr := Trim(Tokens[0]);
          SStr := Trim(Tokens[1]);
          LStr := Trim(Tokens[2]);
          
          if (Length(SStr) > 0) and (SStr[Length(SStr)] = '%') then
            SStr := Copy(SStr, 1, Length(SStr) - 1);
          if (Length(LStr) > 0) and (LStr[Length(LStr)] = '%') then
            LStr := Copy(LStr, 1, Length(LStr) - 1);
            
          FS := DefaultFormatSettings;
          FS.DecimalSeparator := '.';
          
          HVal := StrToFloatDef(HStr, 0.0, FS);
          SVal := StrToFloatDef(SStr, 0.0, FS) / 100.0;
          LVal := StrToFloatDef(LStr, 0.0, FS) / 100.0;
          
          AStart := HSLToRGB(HVal, SVal, LVal);
          // Darken lightness to 40% of its value for the end gradient color
          AEnd := HSLToRGB(HVal, SVal, LVal * 0.4);
        end;
      finally
        Tokens.Free;
      end;
    end;
  end
  else
  begin
    if (Length(S) > 0) and (S[1] = '#') then
      Delete(S, 1, 1);
      
    if Length(S) = 6 then
    begin
      try
        R := StrToInt('$' + Copy(S, 1, 2));
        G := StrToInt('$' + Copy(S, 3, 2));
        B := StrToInt('$' + Copy(S, 5, 2));
        
        AStart := TColor(R or (G shl 8) or (B shl 16));
        // Darken the hex color for a beautiful gradient end color
        AEnd := TColor((R div 3) or ((G div 3) shl 8) or ((B div 3) shl 16));
      except
        // Keep defaults
      end;
    end;
  end;
end;

procedure TForm1.LoadWorkspacesAndBoards;
var
  I: Integer;
  Ctrl: TControl;
  CurrentWorkspaceID: Integer;
  LastCardsContainer: TScrollBoardCards;
  LastHeader: TPanelAreaTrabalho;
  WID: Integer;
  WName: string;
  BTitle, BBackground, BPass: string;
  NewCard: TBoardCard;
  CardColor, EndColor: TColor;
begin
  ScrollBox1.DisableAlign;
  try
    // Clear any existing workspace components from ScrollBox1 (e.g. design-time placeholders)
    for I := ScrollBox1.ControlCount - 1 downto 0 do
    begin
      Ctrl := ScrollBox1.Controls[I];
      if (Ctrl is TPanelAreaTrabalho) or (Ctrl is TScrollBoardCards) then
        Ctrl.Free;
    end;

    if LoggedUserID = 0 then 
      Exit;

    try
      if not DataModule1.IBDatabase1.Connected then
        DataModule1.IBDatabase1.Connected := True;
      if not DataModule1.IBTransaction1.Active then
        DataModule1.IBTransaction1.StartTransaction;
    except
      on E: Exception do
      begin
        ShowMessage('Erro de conexão ao banco de dados: ' + E.Message);
        Exit;
      end;
    end;

    try
      DataModule1.IBQ_WorksSpace_E_Boards.Close;
      DataModule1.IBQ_WorksSpace_E_Boards.ParamByName('USERID').DataType := ftInteger;
      DataModule1.IBQ_WorksSpace_E_Boards.ParamByName('USERID').AsInteger := LoggedUserID;
      DataModule1.IBQ_WorksSpace_E_Boards.Open;

      CurrentWorkspaceID := -1;
      LastHeader := nil;
      LastCardsContainer := nil;

      while not DataModule1.IBQ_WorksSpace_E_Boards.Eof do
      begin
        WID := DataModule1.IBQ_WorksSpace_E_Boards.FieldByName('WORKSPACE_ID').AsInteger;
        WName := DataModule1.IBQ_WorksSpace_E_Boards.FieldByName('WORKSPACE_NAME').AsString;

        if WID <> CurrentWorkspaceID then
        begin
          CurrentWorkspaceID := WID;

          // Create ScrollBoardCards container
          LastCardsContainer := TScrollBoardCards.Create(Self);
          LastCardsContainer.Parent := ScrollBox1;
          LastCardsContainer.Align := alTop;
          LastCardsContainer.Height := 140;
          LastCardsContainer.SendToBack;

          // Create Workspace Header Panel
          LastHeader := TPanelAreaTrabalho.Create(Self);
          LastHeader.Parent := ScrollBox1;
          LastHeader.Align := alTop;
          LastHeader.WorkspaceName := WName;
          LastHeader.LinkedControl := LastCardsContainer;
          LastHeader.OnCreateBoard := @WorkspacePanelCreateBoard;
          LastHeader.OnDelete := @WorkspacePanelDelete;
          LastHeader.SendToBack;
        end;

        if not DataModule1.IBQ_WorksSpace_E_Boards.FieldByName('BOARD_ID').IsNull then
        begin
          BTitle := DataModule1.IBQ_WorksSpace_E_Boards.FieldByName('BOARD_TITLE').AsString;
          BBackground := DataModule1.IBQ_WorksSpace_E_Boards.FieldByName('BOARD_BACKGROUND').AsString;
          BPass := DataModule1.IBQ_WorksSpace_E_Boards.FieldByName('BOARD_PASSWORD').AsString;

          NewCard := TBoardCard.Create(Self);
          NewCard.Parent := LastCardsContainer;
          NewCard.BoardTitle := BTitle;
          NewCard.Password := BPass;
          
          if Trim(BBackground) <> '' then
          begin
            ParseBoardColors(BBackground, CardColor, EndColor);
            NewCard.StartColor := CardColor;
            NewCard.EndColor := EndColor;
          end;

          NewCard.OnEdit := @BoardCardEdit;
          NewCard.OnSettings := @BoardCardSettings;
          NewCard.OnDelete := @BoardCardDelete;
          NewCard.OnClick := @BoardCardClick;
        end;

        DataModule1.IBQ_WorksSpace_E_Boards.Next;
      end;
    finally
      DataModule1.IBQ_WorksSpace_E_Boards.Close;
    end;
  finally
    ScrollBox1.EnableAlign;
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
