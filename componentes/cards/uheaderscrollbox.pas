unit uHeaderScrollBox;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, Graphics, uTaskCard;

type
  THeaderScrollBox = class;

  TCardMovedEvent = procedure(Sender: TObject; Card: TTaskCard; SourceList, TargetList: THeaderScrollBox) of object;

  THeaderScrollBox = class(TScrollBox)
  private
    FHeaderPanel: TPanel;
    FOnCardMoved: TCardMovedEvent;
    procedure HeaderPanelDragOver(Sender: TObject; Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure HeaderPanelDragDrop(Sender: TObject; Source: TObject; X, Y: Integer);
    function GetHeaderHeight: Integer;
    procedure SetHeaderHeight(AValue: Integer);
    function GetHeaderColor: TColor;
    procedure SetHeaderColor(AValue: TColor);
    function GetHeaderCaption: string;
    procedure SetHeaderCaption(const AValue: string);
  protected
    procedure CreateWnd; override;
    procedure DragOver(Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DragDrop(Source: TObject; X, Y: Integer); override;
    procedure HandleCardDrop(Card: TTaskCard; TargetCard: TTaskCard);
  published
    property HeaderPanel: TPanel read FHeaderPanel;
    property HeaderHeight: Integer read GetHeaderHeight write SetHeaderHeight default 50;
    property HeaderColor: TColor read GetHeaderColor write SetHeaderColor default clDefault;
    property HeaderCaption: string read GetHeaderCaption write SetHeaderCaption;
    property OnCardMoved: TCardMovedEvent read FOnCardMoved write FOnCardMoved;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('ConnectTask', [THeaderScrollBox]);
end;

constructor THeaderScrollBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  // Create and configure the header panel
  FHeaderPanel := TPanel.Create(Self);
  FHeaderPanel.Parent := Self;
  FHeaderPanel.Align := alTop;
  FHeaderPanel.Height := 50;
  FHeaderPanel.Caption := '';
  FHeaderPanel.BevelOuter := bvNone;
  FHeaderPanel.Name := 'HeaderPanel';
  
  FHeaderPanel.OnDragOver := @HeaderPanelDragOver;
  FHeaderPanel.OnDragDrop := @HeaderPanelDragDrop;
  
  // Make the sub-component visible and editable in Lazarus IDE Object Inspector
  FHeaderPanel.SetSubComponent(True);
end;

procedure THeaderScrollBox.CreateWnd;
begin
  inherited CreateWnd;
  // Ensure correct Z-order at runtime so the panel stays at the top
  if FHeaderPanel <> nil then
    FHeaderPanel.BringToFront;
end;

function THeaderScrollBox.GetHeaderHeight: Integer;
begin
  Result := FHeaderPanel.Height;
end;

procedure THeaderScrollBox.SetHeaderHeight(AValue: Integer);
begin
  if FHeaderPanel.Height <> AValue then
    FHeaderPanel.Height := AValue;
end;

function THeaderScrollBox.GetHeaderColor: TColor;
begin
  Result := FHeaderPanel.Color;
end;

procedure THeaderScrollBox.SetHeaderColor(AValue: TColor);
begin
  if FHeaderPanel.Color <> AValue then
    FHeaderPanel.Color := AValue;
end;

function THeaderScrollBox.GetHeaderCaption: string;
begin
  Result := FHeaderPanel.Caption;
end;

procedure THeaderScrollBox.SetHeaderCaption(const AValue: string);
begin
  if FHeaderPanel.Caption <> AValue then
    FHeaderPanel.Caption := AValue;
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
