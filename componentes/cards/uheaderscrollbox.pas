unit uHeaderScrollBox;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, Graphics, LCLIntf, LCLType, Types, Math, Dialogs, StdCtrls, uTaskCard;

type
  THeaderScrollBox = class;

  TCardMovedEvent = procedure(Sender: TObject; Card: TTaskCard; SourceList, TargetList: THeaderScrollBox) of object;
  TCardAddedEvent = procedure(Sender: TObject; Card: TTaskCard) of object;

  { TListHeaderPanel }

  TListHeaderPanel = class(TPanel)
  private
    FScrollBox: THeaderScrollBox;
    FHoveredDelete: Boolean;
    function GetDeleteRect: TRect;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
  public
    constructor Create(AOwner: TComponent; AScrollBox: THeaderScrollBox); reintroduce;
  end;

  { TAddCardPanel }

  TAddCardPanel = class(TPanel)
  private
    FScrollBox: THeaderScrollBox;
    FIsHovered: Boolean;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent; AScrollBox: THeaderScrollBox); reintroduce;
  end;

  { THeaderScrollBox }

  THeaderScrollBox = class(TScrollBox)
  private
    FHeaderPanel: TListHeaderPanel;
    FAddCardPanel: TAddCardPanel;
    FListID: Integer;
    FDefaultUserName: string;
    FOnCardMoved: TCardMovedEvent;
    FOnCardCopy: TNotifyEvent;
    FOnCardEdit: TNotifyEvent;
    FOnCardDelete: TNotifyEvent;
    FOnCardAdded: TCardAddedEvent;
    FOnListDelete: TNotifyEvent;
    procedure HeaderPanelDragOver(Sender: TObject; Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure HeaderPanelDragDrop(Sender: TObject; Source: TObject; X, Y: Integer);
    function GetHeaderHeight: Integer;
    procedure SetHeaderHeight(AValue: Integer);
    function GetHeaderColor: TColor;
    procedure SetHeaderColor(AValue: TColor);
    function GetHeaderCaption: string;
    procedure SetHeaderCaption(const AValue: string);
    procedure DeferredFree(Data: PtrInt);
  protected
    procedure Loaded; override;
    procedure CreateWnd; override;
    procedure Resize; override;
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
    procedure Paint; override;
    procedure DragOver(Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure RemoveControl(AControl: TControl); override;
    procedure DragDrop(Source: TObject; X, Y: Integer); override;
    procedure HandleCardDrop(Card: TTaskCard; TargetCard: TTaskCard);
    function GetTaskCount: Integer;
    procedure AddNewCard;
    procedure DeleteList;
  published
    property HeaderPanel: TListHeaderPanel read FHeaderPanel;
    property HeaderHeight: Integer read GetHeaderHeight write SetHeaderHeight default 50;
    property HeaderColor: TColor read GetHeaderColor write SetHeaderColor default clDefault;
    property HeaderCaption: string read GetHeaderCaption write SetHeaderCaption;
    property ListID: Integer read FListID write FListID default 0;
    property DefaultUserName: string read FDefaultUserName write FDefaultUserName;
    property OnCardMoved: TCardMovedEvent read FOnCardMoved write FOnCardMoved;
    property OnCardCopy: TNotifyEvent read FOnCardCopy write FOnCardCopy;
    property OnCardEdit: TNotifyEvent read FOnCardEdit write FOnCardEdit;
    property OnCardDelete: TNotifyEvent read FOnCardDelete write FOnCardDelete;
    property OnCardAdded: TCardAddedEvent read FOnCardAdded write FOnCardAdded;
    property OnListDelete: TNotifyEvent read FOnListDelete write FOnListDelete;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('ConnectTask', [THeaderScrollBox]);
end;

{ TPriorityDialogHelper }

type
  TPriorityButton = class(TPanel)
  protected
    procedure Paint; override;
  end;

  TPriorityDialogHelper = class
  public
    SelectedColor: TColor;
    SelectedPriority: string;
    DialogResult: Boolean;
    Dlg: TForm;
    procedure BtnClick(Sender: TObject);
    procedure BackClick(Sender: TObject);
    procedure DlgPaint(Sender: TObject);
  end;

procedure TPriorityButton.Paint;
begin
  Canvas.AntialiasingMode := amOn;
  Canvas.Brush.Color := Color;
  Canvas.Pen.Style := psClear;
  Canvas.RoundRect(0, 0, Width, Height, 8, 8);

  Canvas.Font := Font;
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(
    (Width - Canvas.TextWidth(Caption)) div 2,
    (Height - Canvas.TextHeight(Caption)) div 2,
    Caption
  );
end;

procedure TPriorityDialogHelper.BtnClick(Sender: TObject);
begin
  SelectedPriority := TPriorityButton(Sender).Caption;
  SelectedColor := TPriorityButton(Sender).Color;
  DialogResult := True;
  Dlg.Close;
end;

procedure TPriorityDialogHelper.BackClick(Sender: TObject);
begin
  DialogResult := False;
  Dlg.Close;
end;

procedure TPriorityDialogHelper.DlgPaint(Sender: TObject);
begin
  Dlg.Canvas.Pen.Color := $D0D0D0;
  Dlg.Canvas.Pen.Width := 1;
  Dlg.Canvas.Brush.Style := bsClear;
  Dlg.Canvas.RoundRect(0, 0, Dlg.Width, Dlg.Height, 16, 16);
end;

function ShowPriorityDialog(out AColor: TColor; out APriorityText: string): Boolean;
var
  Helper: TPriorityDialogHelper;
  TitleLabel: TLabel;
  Btn: TPriorityButton;
  BackBtn: TLabel;
  I: Integer;
  Names: array[0..6] of string;
  Colors: array[0..6] of TColor;
  TextColors: array[0..6] of TColor;
  BtnTop: Integer;
  Rgn: HRGN;
begin
  Names[0] := 'Baixa';        Colors[0] := $0C0C0C;  TextColors[0] := clWhite;
  Names[1] := 'Média';        Colors[1] := $A5F0FF;  TextColors[1] := clBlack;
  Names[2] := 'Alta';         Colors[2] := $5252FF;  TextColors[2] := clWhite;
  Names[3] := 'Observação';   Colors[3] := $7ECE2E;  TextColors[3] := clWhite;
  Names[4] := 'Ideia';        Colors[4] := $DB9834;  TextColors[4] := clWhite;
  Names[5] := 'URGENTE';      Colors[5] := $B6599B;  TextColors[5] := clWhite;
  Names[6] := 'Recuperado';   Colors[6] := $BA6BFF;  TextColors[6] := clWhite;

  Helper := TPriorityDialogHelper.Create;
  try
    Helper.SelectedColor := $0C0C0C;
    Helper.SelectedPriority := 'Baixa';
    Helper.DialogResult := False;

    Helper.Dlg := TForm.Create(nil);
    try
      Helper.Dlg.BorderStyle := bsNone;
      Helper.Dlg.Color := clWhite;
      Helper.Dlg.Width := 240;
      Helper.Dlg.Height := 390;
      Helper.Dlg.Position := poOwnerFormCenter;
      Helper.Dlg.OnPaint := @Helper.DlgPaint;
      
      Helper.Dlg.HandleNeeded;
      Rgn := CreateRoundRectRgn(0, 0, Helper.Dlg.Width, Helper.Dlg.Height, 16, 16);
      SetWindowRgn(Helper.Dlg.Handle, Rgn, True);

      TitleLabel := TLabel.Create(Helper.Dlg);
      TitleLabel.Parent := Helper.Dlg;
      TitleLabel.Align := alTop;
      TitleLabel.Alignment := taCenter;
      TitleLabel.Font.Name := 'Segoe UI';
      TitleLabel.Font.Size := 11;
      TitleLabel.Font.Style := [fsBold];
      TitleLabel.Font.Color := clBlack;
      TitleLabel.Caption := 'Selecione a Prioridade:';
      TitleLabel.BorderSpacing.Top := 16;
      TitleLabel.BorderSpacing.Bottom := 12;

      BtnTop := 50;
      for I := 0 to 6 do
      begin
        Btn := TPriorityButton.Create(Helper.Dlg);
        Btn.Parent := Helper.Dlg;
        Btn.SetBounds(16, BtnTop, Helper.Dlg.Width - 32, 32);
        Btn.Color := Colors[I];
        Btn.Font.Name := 'Segoe UI';
        Btn.Font.Size := 10;
        Btn.Font.Style := [fsBold];
        Btn.Font.Color := TextColors[I];
        Btn.Caption := Names[I];
        Btn.Cursor := crHandPoint;
        Btn.OnClick := @Helper.BtnClick;
        
        BtnTop := BtnTop + 40;
      end;

      BackBtn := TLabel.Create(Helper.Dlg);
      BackBtn.Parent := Helper.Dlg;
      BackBtn.SetBounds(16, BtnTop + 4, Helper.Dlg.Width - 32, 24);
      BackBtn.Alignment := taCenter;
      BackBtn.Font.Name := 'Segoe UI';
      BackBtn.Font.Size := 10;
      BackBtn.Font.Style := [];
      BackBtn.Font.Color := $A08070;
      BackBtn.Caption := 'Voltar';
      BackBtn.Cursor := crHandPoint;
      BackBtn.OnClick := @Helper.BackClick;

      Helper.Dlg.ShowModal;
    finally
      Helper.Dlg.Free;
    end;

    AColor := Helper.SelectedColor;
    APriorityText := Helper.SelectedPriority;
    Result := Helper.DialogResult;
  finally
    Helper.Free;
  end;
end;

{ TListHeaderPanel }

constructor TListHeaderPanel.Create(AOwner: TComponent; AScrollBox: THeaderScrollBox);
begin
  inherited Create(AOwner);
  FScrollBox := AScrollBox;
  Parent := FScrollBox;
  Align := alNone;
  Height := 50;
  BevelOuter := bvNone;
  Caption := '';
  DoubleBuffered := True;
end;

function TListHeaderPanel.GetDeleteRect: TRect;
begin
  Result := Rect(Width - 36, (Height - 24) div 2, Width - 12, (Height + 24) div 2);
end;

procedure TListHeaderPanel.Paint;
var
  TextW: Integer;
  CountStr: string;
  DelRect: TRect;
begin
  // Paint background matching FScrollBox.Color
  Canvas.Brush.Color := FScrollBox.Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  // Draw Title Text
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 11;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clWhite;
  Canvas.Brush.Style := bsClear;
  
  TextW := Canvas.TextWidth(FScrollBox.HeaderCaption);
  Canvas.TextOut(16, (Height - Canvas.TextHeight(FScrollBox.HeaderCaption)) div 2, FScrollBox.HeaderCaption);

  // Draw Task Count Badge
  CountStr := IntToStr(FScrollBox.GetTaskCount);
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [];
  Canvas.Font.Color := $8A8A8A;
  Canvas.TextOut(16 + TextW + 8, (Height - Canvas.TextHeight(CountStr)) div 2, CountStr);

  // Draw Trash Bin Icon
  DelRect := GetDeleteRect;
  if FHoveredDelete then
  begin
    Canvas.Brush.Color := $1A1010;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := $502020;
    Canvas.RoundRect(DelRect.Left, DelRect.Top, DelRect.Right, DelRect.Bottom, 4, 4);
  end;

  Canvas.Brush.Style := bsClear;
  if FHoveredDelete then
    Canvas.Pen.Color := $4444FF // Red in BGR
  else
    Canvas.Pen.Color := $B0B0B0;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;

  Canvas.Line(DelRect.Left + 9, DelRect.Top + 6, DelRect.Left + 13, DelRect.Top + 6);
  Canvas.Line(DelRect.Left + 6, DelRect.Top + 8, DelRect.Right - 6, DelRect.Top + 8);
  Canvas.Line(DelRect.Left + 8, DelRect.Top + 9, DelRect.Left + 8, DelRect.Bottom - 6);
  Canvas.Line(DelRect.Right - 8, DelRect.Top + 9, DelRect.Right - 8, DelRect.Bottom - 6);
  Canvas.Line(DelRect.Left + 8, DelRect.Bottom - 6, DelRect.Right - 8, DelRect.Bottom - 6);
end;

procedure TListHeaderPanel.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  OldHovered: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  OldHovered := FHoveredDelete;
  FHoveredDelete := PtInRect(GetDeleteRect, Point(X, Y));
  if FHoveredDelete <> OldHovered then
  begin
    if FHoveredDelete then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TListHeaderPanel.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and PtInRect(GetDeleteRect, Point(X, Y)) then
    FScrollBox.DeleteList;
end;

procedure TListHeaderPanel.MouseLeave;
begin
  inherited MouseLeave;
  if FHoveredDelete then
  begin
    FHoveredDelete := False;
    Cursor := crDefault;
    Invalidate;
  end;
end;


{ TAddCardPanel }

constructor TAddCardPanel.Create(AOwner: TComponent; AScrollBox: THeaderScrollBox);
begin
  inherited Create(AOwner);
  FScrollBox := AScrollBox;
  Parent := FScrollBox;
  Align := alNone;
  Height := 40;
  BevelOuter := bvNone;
  Caption := '';
  DoubleBuffered := True;
end;

procedure TAddCardPanel.Paint;
begin
  Canvas.Brush.Color := FScrollBox.Color;
  if FIsHovered then
  begin
    Canvas.Brush.Color := TColor(RGB(
      Min(255, Red(FScrollBox.Color) + 15),
      Min(255, Green(FScrollBox.Color) + 15),
      Min(255, Blue(FScrollBox.Color) + 15)
    ));
  end;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [];
  if FIsHovered then
    Canvas.Font.Color := clWhite
  else
    Canvas.Font.Color := $D0D0D0;
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(16, (Height - Canvas.TextHeight('+ Adicionar cartão')) div 2, '+ Adicionar cartão');
end;

procedure TAddCardPanel.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if not FIsHovered then
  begin
    FIsHovered := True;
    Cursor := crHandPoint;
    Invalidate;
  end;
end;

procedure TAddCardPanel.MouseLeave;
begin
  inherited MouseLeave;
  if FIsHovered then
  begin
    FIsHovered := False;
    Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TAddCardPanel.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
    FScrollBox.AddNewCard;
end;


{ THeaderScrollBox }

constructor THeaderScrollBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  DoubleBuffered := True;
  BorderStyle := bsNone;
  Color := $6B4B2D; // Default premium dark slate blue color (BGR)
  FDefaultUserName := 'mauricio abreu';
  
  AutoScroll := False;
  HorzScrollBar.Visible := False;
  HorzScrollBar.Range := 0;
  VertScrollBar.Tracking := True;
  
  FHeaderPanel := TListHeaderPanel.Create(Self, Self);
  FHeaderPanel.Name := 'HeaderPanel';
  FHeaderPanel.OnDragOver := @HeaderPanelDragOver;
  FHeaderPanel.OnDragDrop := @HeaderPanelDragDrop;
  
  FAddCardPanel := TAddCardPanel.Create(Self, Self);
  FAddCardPanel.Name := 'AddCardPanel';
  
  FHeaderPanel.SetSubComponent(True);
  FAddCardPanel.SetSubComponent(True);
end;

procedure THeaderScrollBox.Loaded;
begin
  inherited Loaded;
  if FHeaderPanel <> nil then
    FHeaderPanel.Align := alNone;
  if FAddCardPanel <> nil then
    FAddCardPanel.Align := alNone;
end;

procedure THeaderScrollBox.CreateWnd;
var
  Rgn: HRGN;
begin
  inherited CreateWnd;
  if FHeaderPanel <> nil then
    FHeaderPanel.BringToFront;
    
  if HandleAllocated then
  begin
    Rgn := CreateRoundRectRgn(0, 0, Width, Height, 16, 16);
    SetWindowRgn(Handle, Rgn, True);
  end;
end;

procedure THeaderScrollBox.Resize;
var
  Rgn: HRGN;
begin
  inherited Resize;
  if HandleAllocated then
  begin
    Rgn := CreateRoundRectRgn(0, 0, Width, Height, 16, 16);
    SetWindowRgn(Handle, Rgn, True);
  end;
end;

procedure THeaderScrollBox.RemoveControl(AControl: TControl);
begin
  inherited RemoveControl(AControl);
  if (AControl is TTaskCard) and (FHeaderPanel <> nil) then
    FHeaderPanel.Invalidate;
end;

procedure THeaderScrollBox.AlignControls(AControl: TControl; var ARect: TRect);
var
  TotalHeight: Integer;
  I: Integer;
  Ctrl: TControl;
  NewRange: Integer;
  NewVisible: Boolean;
begin
  // Calculate vertical scroll range manually based on task cards
  TotalHeight := 0;
  for I := 0 to ControlCount - 1 do
  begin
    Ctrl := Controls[I];
    if (Ctrl is TTaskCard) and Ctrl.Visible then
      TotalHeight := TotalHeight + Ctrl.Height;
  end;

  NewRange := TotalHeight + FHeaderPanel.Height + FAddCardPanel.Height;
  if VertScrollBar.Range <> NewRange then
    VertScrollBar.Range := NewRange;

  NewVisible := NewRange > ClientHeight;
  if VertScrollBar.Visible <> NewVisible then
    VertScrollBar.Visible := NewVisible;

  if FHeaderPanel <> nil then
  begin
    FHeaderPanel.Invalidate;
    if (FHeaderPanel.Left <> HorzScrollBar.Position) or
       (FHeaderPanel.Top <> VertScrollBar.Position) or
       (FHeaderPanel.Width <> ClientWidth) then
    begin
      FHeaderPanel.SetBounds(
        HorzScrollBar.Position,
        VertScrollBar.Position,
        ClientWidth,
        FHeaderPanel.Height
      );
    end;
  end;

  if FAddCardPanel <> nil then
  begin
    if (FAddCardPanel.Left <> HorzScrollBar.Position) or
       (FAddCardPanel.Top <> VertScrollBar.Position + ClientHeight - FAddCardPanel.Height) or
       (FAddCardPanel.Width <> ClientWidth) then
    begin
      FAddCardPanel.SetBounds(
        HorzScrollBar.Position,
        VertScrollBar.Position + ClientHeight - FAddCardPanel.Height,
        ClientWidth,
        FAddCardPanel.Height
      );
    end;
  end;

  if FHeaderPanel <> nil then
    ARect.Top := ARect.Top + FHeaderPanel.Height;
  if FAddCardPanel <> nil then
    ARect.Bottom := ARect.Bottom - FAddCardPanel.Height;

  inherited AlignControls(AControl, ARect);
end;

procedure THeaderScrollBox.Paint;
begin
  inherited Paint;
  Canvas.Brush.Color := Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);
end;

function THeaderScrollBox.GetHeaderHeight: Integer;
begin
  Result := FHeaderPanel.Height;
end;

procedure THeaderScrollBox.SetHeaderHeight(AValue: Integer);
begin
  if FHeaderPanel.Height <> AValue then
  begin
    FHeaderPanel.Height := AValue;
    FHeaderPanel.Invalidate;
  end;
end;

function THeaderScrollBox.GetHeaderColor: TColor;
begin
  Result := FHeaderPanel.Color;
end;

procedure THeaderScrollBox.SetHeaderColor(AValue: TColor);
begin
  if FHeaderPanel.Color <> AValue then
  begin
    FHeaderPanel.Color := AValue;
    FHeaderPanel.Invalidate;
  end;
end;

function THeaderScrollBox.GetHeaderCaption: string;
begin
  Result := FHeaderPanel.Caption;
end;

procedure THeaderScrollBox.SetHeaderCaption(const AValue: string);
begin
  if FHeaderPanel.Caption <> AValue then
  begin
    FHeaderPanel.Caption := AValue;
    FHeaderPanel.Invalidate;
  end;
end;

function THeaderScrollBox.GetTaskCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to ControlCount - 1 do
    if Controls[I] is TTaskCard then
      Inc(Result);
end;

procedure THeaderScrollBox.AddNewCard;
var
  NewText: string;
  NewCard: TTaskCard;
  CodeChars: string;
  I: Integer;
  GeneratedCode: string;
  SelectedColor: TColor;
  SelectedPriority: string;
begin
  NewText := '';
  if InputQuery('Novo Cartão', 'Digite a descrição da nova tarefa:', NewText) then
  begin
    NewText := Trim(NewText);
    if NewText = '' then Exit;

    // Show priority selection dialog to set background color
    if not ShowPriorityDialog(SelectedColor, SelectedPriority) then
      Exit;

    NewCard := TTaskCard.Create(Self.Owner);
    NewCard.Parent := Self;
    NewCard.Align := alTop;
    NewCard.TaskText := NewText;
    NewCard.BackgroundColor := SelectedColor;
    NewCard.CardID := 0; // Will be assigned by OnCardAdded handler after DB insert

    CodeChars := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    GeneratedCode := '#';
    for I := 1 to 6 do
      GeneratedCode := GeneratedCode + CodeChars[Random(Length(CodeChars)) + 1];
    NewCard.TaskCode := GeneratedCode;

    NewCard.TaskDate := FormatDateTime('dd/mm/yyyy', Date);

    if FDefaultUserName <> '' then
      NewCard.UserName := FDefaultUserName
    else
      NewCard.UserName := 'Usuário';

    NewCard.OnCopyClick := FOnCardCopy;
    NewCard.OnEditClick := FOnCardEdit;
    NewCard.OnDeleteClick := FOnCardDelete;

    // Fire OnCardAdded so host form can persist to DB and assign CardID
    if Assigned(FOnCardAdded) then
      FOnCardAdded(Self, NewCard);

    HandleCardDrop(NewCard, nil);

    if FHeaderPanel <> nil then
      FHeaderPanel.Invalidate;
  end;
end;

procedure THeaderScrollBox.DeleteList;
begin
  if MessageDlg('Excluir Lista', 'Tem certeza que deseja excluir a lista "' + HeaderCaption + '" e todos os seus cartões?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    // Fire event so host form can delete from DB first
    if Assigned(FOnListDelete) then
      FOnListDelete(Self);
    Application.QueueAsyncCall(@DeferredFree, 0);
  end;
end;

procedure THeaderScrollBox.DeferredFree(Data: PtrInt);
begin
  Self.Free;
end;

procedure SortCardsByTop(AList: TList);
var
  I, J: Integer;
  Temp: Pointer;
begin
  for I := 0 to AList.Count - 2 do
    for J := I + 1 to AList.Count - 1 do
    begin
      if TControl(AList[I]).Top > TControl(AList[J]).Top then
      begin
        Temp := AList[I];
        AList[I] := AList[J];
        AList[J] := Temp;
      end;
    end;
end;

procedure THeaderScrollBox.HeaderPanelDragOver(Sender: TObject; Source: TObject;
  X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := Source is TTaskCard;
end;

procedure THeaderScrollBox.HeaderPanelDragDrop(Sender: TObject; Source: TObject;
  X, Y: Integer);
var
  SortedCards: TList;
  TargetCard: TTaskCard;
  I: Integer;
  Ctrl: TControl;
begin
  if Source is TTaskCard then
  begin
    TargetCard := nil;
    SortedCards := TList.Create;
    try
      for I := 0 to ControlCount - 1 do
      begin
        Ctrl := Controls[I];
        if (Ctrl is TTaskCard) and (Ctrl <> Source) then
          SortedCards.Add(Ctrl);
      end;
      SortCardsByTop(SortedCards);
      if SortedCards.Count > 0 then
        TargetCard := TTaskCard(SortedCards[0]);
    finally
      SortedCards.Free;
    end;
    
    HandleCardDrop(TTaskCard(Source), TargetCard);
  end;
end;

procedure THeaderScrollBox.DragOver(Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  inherited DragOver(Source, X, Y, State, Accept);
  Accept := Source is TTaskCard;
end;

procedure THeaderScrollBox.DragDrop(Source: TObject; X, Y: Integer);
var
  Card: TTaskCard;
  TargetCard: TTaskCard;
  I: Integer;
  Ctrl: TControl;
  SortedCards: TList;
begin
  inherited DragDrop(Source, X, Y);
  if Source is TTaskCard then
  begin
    Card := TTaskCard(Source);
    TargetCard := nil;
    
    SortedCards := TList.Create;
    try
      for I := 0 to ControlCount - 1 do
      begin
        Ctrl := Controls[I];
        if (Ctrl is TTaskCard) and (Ctrl <> Card) then
          SortedCards.Add(Ctrl);
      end;
      SortCardsByTop(SortedCards);
      
      for I := 0 to SortedCards.Count - 1 do
      begin
        Ctrl := TControl(SortedCards[I]);
        if Ctrl.Top + (Ctrl.Height div 2) > Y then
        begin
          TargetCard := TTaskCard(Ctrl);
          Break;
        end;
      end;
    finally
      SortedCards.Free;
    end;
    
    HandleCardDrop(Card, TargetCard);
  end;
end;

procedure THeaderScrollBox.HandleCardDrop(Card: TTaskCard; TargetCard: TTaskCard);
var
  SourceList: THeaderScrollBox;
  I, InsertIdx: Integer;
  SortedCards: TList;
  Ctrl: TControl;
begin
  if Card = nil then Exit;
  
  SourceList := nil;
  if Card.Parent is THeaderScrollBox then
    SourceList := THeaderScrollBox(Card.Parent);

  Card.Parent := Self;

  SortedCards := TList.Create;
  try
    for I := 0 to ControlCount - 1 do
    begin
      Ctrl := Controls[I];
      if (Ctrl is TTaskCard) and (Ctrl <> Card) then
        SortedCards.Add(Ctrl);
    end;
    SortCardsByTop(SortedCards);

    InsertIdx := SortedCards.Count;
    if TargetCard <> nil then
    begin
      InsertIdx := SortedCards.IndexOf(TargetCard);
      if InsertIdx < 0 then
        InsertIdx := SortedCards.Count;
    end;
    
    SortedCards.Insert(InsertIdx, Card);

    DisableAlign;
    try
      for I := SortedCards.Count - 1 downto 0 do
        TControl(SortedCards[I]).BringToFront;
        
      if FHeaderPanel <> nil then
        FHeaderPanel.BringToFront;
    finally
      EnableAlign;
    end;
    
  finally
    SortedCards.Free;
  end;

  if Assigned(FOnCardMoved) then
    FOnCardMoved(Self, Card, SourceList, Self);
end;

end.
