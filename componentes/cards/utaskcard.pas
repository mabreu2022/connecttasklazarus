unit uTaskCard;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Controls, Graphics, LCLIntf, LCLType, Types, Forms,
  Clipbrd, Dialogs, StdCtrls;

type
  TTaskCard = class(TCustomControl)
  private
    FCardID: Integer;
    FTaskCode: string;
    FTaskText: string;
    FTaskDate: string;
    FUserName: string;
    FUserColor: TColor;

    FBackgroundColor: TColor;
    FBorderColor: TColor;
    FTextColor: TColor;
    FDateColor: TColor;
    FCodeColor: TColor;

    // Hover states for drawing
    FHoveredButton: integer; // 0 = none, 1 = copy, 2 = edit, 3 = delete
    FIsHovered: boolean;
    FIsDragTarget: boolean;

    // Events
    FOnCopyClick: TNotifyEvent;
    FOnEditClick: TNotifyEvent;
    FOnDeleteClick: TNotifyEvent;

    procedure SetTaskCode(AValue: string);
    procedure SetTaskText(AValue: string);
    procedure SetTaskDate(AValue: string);
    procedure SetUserName(AValue: string);
    procedure SetUserColor(AValue: TColor);
    procedure SetBackgroundColor(AValue: TColor);
    procedure SetBorderColor(AValue: TColor);
    procedure SetTextColor(AValue: TColor);
    procedure SetDateColor(AValue: TColor);
    procedure SetCodeColor(AValue: TColor);

    function GetButtonRect(Index: integer): TRect;
    function GetAvatarRect: TRect;

    // Built-in default actions
    procedure DoCopy;
    procedure DoEdit;
    procedure DoDelete;
    procedure DeferredFree(Data: PtrInt);

  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: integer); override;
    procedure MouseLeave; override;
    procedure MouseEnter; override;
    procedure DragOver(Source: TObject; X, Y: integer; State: TDragState;
      var Accept: boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure DragDrop(Source: TObject; X, Y: integer); override;

  published
    property CardID: Integer read FCardID write FCardID default 0;
    property TaskCode: string read FTaskCode write SetTaskCode;
    property TaskText: string read FTaskText write SetTaskText;
    property TaskDate: string read FTaskDate write SetTaskDate;
    property UserName: string read FUserName write SetUserName;
    property UserColor: TColor read FUserColor write SetUserColor default $E5464F;
    // Premium Violet/Indigo

    property BackgroundColor: TColor read FBackgroundColor
      write SetBackgroundColor default $0C0C0C; // Modern zinc-950
    property BorderColor: TColor read FBorderColor write SetBorderColor default $27272A;
    // zinc-800
    property TextColor: TColor read FTextColor write SetTextColor default $FAFAFA;
    // zinc-50
    property DateColor: TColor read FDateColor write SetDateColor default $71717A;
    // zinc-500
    property CodeColor: TColor read FCodeColor write SetCodeColor default $A1A1AA;
    // zinc-400

    property OnCopyClick: TNotifyEvent read FOnCopyClick write FOnCopyClick;
    property OnEditClick: TNotifyEvent read FOnEditClick write FOnEditClick;
    property OnDeleteClick: TNotifyEvent read FOnDeleteClick write FOnDeleteClick;

    // Re-expose standard properties
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Enabled;
    property Font;
    property Visible;
    property OnClick;
    property OnDblClick;

    // Drag properties
    property DragCursor;
    property DragMode;
    property DragKind;
    property OnDragOver;
    property OnDragDrop;
    property OnEndDrag;
    property OnStartDrag;
  end;

procedure Register;

implementation

uses
  uHeaderScrollBox;

procedure Register;
begin
  RegisterComponents('ConnectTask', [TTaskCard]);
end;

constructor TTaskCard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // Default sizes and options
  Width := 280;
  Height := 240;
  DoubleBuffered := True;

  FTaskCode := '#6F4895';
  FTaskText := 'quando movemos uma tarefa para outra';
  FTaskDate := '22/01/2026';
  FUserName := 'mauricio abreu';
  FUserColor := $E5464F; // Blue-violet color for badge

  FBackgroundColor := $0C0C0C; // Very dark grey (almost black)
  FBorderColor := $27272A;     // Zinc 800 subtle border
  FTextColor := $FAFAFA;       // Soft white
  FDateColor := $71717A;       // Muted gray
  FCodeColor := $A1A1AA;       // Lighter gray for task code

  FHoveredButton := 0;
  FIsHovered := False;
end;

procedure TTaskCard.SetTaskCode(AValue: string);
begin
  if FTaskCode <> AValue then
  begin
    FTaskCode := AValue;
    Invalidate;
  end;
end;

procedure TTaskCard.SetTaskText(AValue: string);
begin
  if FTaskText <> AValue then
  begin
    FTaskText := AValue;
    Invalidate;
  end;
end;

procedure TTaskCard.SetTaskDate(AValue: string);
begin
  if FTaskDate <> AValue then
  begin
    FTaskDate := AValue;
    Invalidate;
  end;
end;

procedure TTaskCard.SetUserName(AValue: string);
begin
  if FUserName <> AValue then
  begin
    FUserName := AValue;
    Invalidate;
  end;
end;

procedure TTaskCard.SetUserColor(AValue: TColor);
begin
  if FUserColor <> AValue then
  begin
    FUserColor := AValue;
    Invalidate;
  end;
end;

procedure TTaskCard.SetBackgroundColor(AValue: TColor);
var
  R, G, B: Byte;
  L: Double;
begin
  if FBackgroundColor <> AValue then
  begin
    FBackgroundColor := AValue;
    
    // Calculate luminance (0.299*R + 0.587*G + 0.114*B) for text contrast
    R := Red(AValue);
    G := Green(AValue);
    B := Blue(AValue);
    L := 0.299 * R + 0.587 * G + 0.114 * B;
    
    if L > 128 then
    begin
      // Light background: dark text
      FTextColor := $222222;
      FDateColor := $555555;
      FCodeColor := $666666;
    end
    else
    begin
      // Dark background: light text
      FTextColor := $FAFAFA;
      FDateColor := $71717A;
      FCodeColor := $A1A1AA;
    end;
    
    Invalidate;
  end;
end;

procedure TTaskCard.SetBorderColor(AValue: TColor);
begin
  if FBorderColor <> AValue then
  begin
    FBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TTaskCard.SetTextColor(AValue: TColor);
begin
  if FTextColor <> AValue then
  begin
    FTextColor := AValue;
    Invalidate;
  end;
end;

procedure TTaskCard.SetDateColor(AValue: TColor);
begin
  if FDateColor <> AValue then
  begin
    FDateColor := AValue;
    Invalidate;
  end;
end;

procedure TTaskCard.SetCodeColor(AValue: TColor);
begin
  if FCodeColor <> AValue then
  begin
    FCodeColor := AValue;
    Invalidate;
  end;
end;

function TTaskCard.GetButtonRect(Index: integer): TRect;
var
  RightOffset: integer;
begin
  // Index: 1 = Copy, 2 = Edit, 3 = Delete (from right to left)
  RightOffset := 16 + (3 - Index) * 28;
  Result := Rect(Width - RightOffset - 22, 12, Width - RightOffset, 34);
end;

function TTaskCard.GetAvatarRect: TRect;
var
  BadgeWidth, BadgeHeight: integer;
  TextW: integer;
begin
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 9;
  Canvas.Font.Style := [fsBold];
  TextW := Canvas.TextWidth(FUserName);

  BadgeHeight := 28;
  BadgeWidth := 10 + 20 + 8 + TextW + 12;
  // padding left + circle + spacing + text + padding right

  Result := Rect(16, Height - 16 - BadgeHeight, 16 + BadgeWidth, Height - 16);
end;

procedure TTaskCard.Paint;
var
  TextR: TRect;
  BtnRect: TRect;
  BadgeRect: TRect;
  AvatarCircRect: TRect;
  Letter: string;
begin
  inherited Paint;

  Canvas.AntialiasingMode := amOn;

  // 1. Draw rounded background
  Canvas.Brush.Color := FBackgroundColor;
  if FIsDragTarget then
  begin
    Canvas.Pen.Color := FUserColor;
    Canvas.Pen.Width := 2;
  end
  else
  begin
    Canvas.Pen.Width := 1;
    if FIsHovered then
      Canvas.Pen.Color := TColor(RGB(Min(255, Red(FBorderColor) + 30),
        Min(255, Green(FBorderColor) + 30), Min(255,
        Blue(FBorderColor) + 30)))
    else
      Canvas.Pen.Color := FBorderColor;
  end;

  Canvas.Pen.Style := psSolid;
  if FIsDragTarget then
    Canvas.RoundRect(1, 1, Width - 1, Height - 1, 16, 16)
  else
    Canvas.RoundRect(0, 0, Width, Height, 16, 16);

  // 2. Draw Task Code (Top-Left)
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 9;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := FCodeColor;
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(16, 16, FTaskCode);

  // 3. Draw Action Buttons (Top-Right)
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;

  // --- Button 1: Copy icon (two offset outlined rectangles, lines only) ---
  BtnRect := GetButtonRect(1);
  if FHoveredButton = 1 then
  begin
    Canvas.Brush.Color := $2A2A2A;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := $3F3F3F;
    Canvas.RoundRect(BtnRect.Left, BtnRect.Top, BtnRect.Right, BtnRect.Bottom, 6, 6);
  end;
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := $AAAAAA;
  // Back page (top-right offset) - just 4 lines
  Canvas.Line(BtnRect.Left + 9, BtnRect.Top + 5, BtnRect.Left + 16, BtnRect.Top + 5);
  Canvas.Line(BtnRect.Left + 16, BtnRect.Top + 5, BtnRect.Left + 16, BtnRect.Top + 14);
  Canvas.Line(BtnRect.Left + 9, BtnRect.Top + 5, BtnRect.Left + 9, BtnRect.Top + 8);
  // Front page (bottom-left offset) - 4 lines
  Canvas.Line(BtnRect.Left + 6, BtnRect.Top + 8, BtnRect.Left + 14, BtnRect.Top + 8);
  Canvas.Line(BtnRect.Left + 14, BtnRect.Top + 8, BtnRect.Left + 14, BtnRect.Top + 17);
  Canvas.Line(BtnRect.Left + 14, BtnRect.Top + 17, BtnRect.Left + 6, BtnRect.Top + 17);
  Canvas.Line(BtnRect.Left + 6, BtnRect.Top + 17, BtnRect.Left + 6, BtnRect.Top + 8);

  // --- Button 2: Edit icon (pencil) ---
  BtnRect := GetButtonRect(2);
  if FHoveredButton = 2 then
  begin
    Canvas.Brush.Color := $2A2A2A;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := $3F3F3F;
    Canvas.RoundRect(BtnRect.Left, BtnRect.Top, BtnRect.Right, BtnRect.Bottom, 6, 6);
  end;
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := $AAAAAA;
  Canvas.Line(BtnRect.Left + 7, BtnRect.Bottom - 6, BtnRect.Right - 7, BtnRect.Top + 6);
  Canvas.Line(BtnRect.Left + 9, BtnRect.Bottom - 6, BtnRect.Right - 5, BtnRect.Top + 6);
  Canvas.Line(BtnRect.Left + 5, BtnRect.Bottom - 5, BtnRect.Left +
    7, BtnRect.Bottom - 6);
  Canvas.Line(BtnRect.Left + 5, BtnRect.Bottom - 5, BtnRect.Left +
    6, BtnRect.Bottom - 3);
  Canvas.Line(BtnRect.Right - 7, BtnRect.Top + 5, BtnRect.Right - 5, BtnRect.Top + 7);

  // --- Button 3: Delete icon (trash) ---
  BtnRect := GetButtonRect(3);
  if FHoveredButton = 3 then
  begin
    Canvas.Brush.Color := $1A1010;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := $502020;
    Canvas.RoundRect(BtnRect.Left, BtnRect.Top, BtnRect.Right, BtnRect.Bottom, 6, 6);
  end;
  Canvas.Brush.Style := bsClear;
  if FHoveredButton = 3 then
    Canvas.Pen.Color := $4444FF
  else
    Canvas.Pen.Color := $AAAAAA;
  Canvas.Line(BtnRect.Left + 9, BtnRect.Top + 5, BtnRect.Left + 13, BtnRect.Top + 5);
  // handle
  Canvas.Line(BtnRect.Left + 5, BtnRect.Top + 7, BtnRect.Right - 5, BtnRect.Top + 7);
  // lid
  Canvas.Line(BtnRect.Left + 7, BtnRect.Top + 8, BtnRect.Left + 7,
    BtnRect.Bottom - 5);
  // left side
  Canvas.Line(BtnRect.Right - 7, BtnRect.Top + 8, BtnRect.Right -
    7, BtnRect.Bottom - 5);
  // right side
  Canvas.Line(BtnRect.Left + 7, BtnRect.Bottom - 5, BtnRect.Right -
    7, BtnRect.Bottom - 5); // bottom
  Canvas.Line(BtnRect.Left + 10, BtnRect.Top + 9, BtnRect.Left + 10,
    BtnRect.Bottom - 6);
  // inner line L
  Canvas.Line(BtnRect.Right - 10, BtnRect.Top + 9, BtnRect.Right -
    10, BtnRect.Bottom - 6);
  // inner line R

  // 4. Draw Task Description Text (Middle, wrapped)
  // Leave enough room: 72px from bottom for date(~12px) + gap(18px) + badge(28px) + margin(14px)
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := FTextColor;
  Canvas.Brush.Style := bsClear;
  TextR := Rect(16, 46, Width - 16, Height - 76);
  DrawText(Canvas.Handle, PChar(FTaskText), -1, TextR, DT_WORDBREAK or DT_NOPREFIX);

  // 5. Draw Date with Clock Icon — sits 46px above bottom (badge=28, margin=14, gap=4)
  Canvas.Font.Size := 8;
  Canvas.Font.Style := [];
  Canvas.Font.Color := FDateColor;
  Canvas.Pen.Color := FDateColor;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsClear;
  Canvas.Ellipse(14, Height - 68, 26, Height - 56);  // clock circle
  Canvas.Line(20, Height - 65, 20, Height - 62);     // vertical hand
  Canvas.Line(20, Height - 62, 23, Height - 62);     // horizontal hand
  Canvas.TextOut(30, Height - 68, FTaskDate);

  // 6. Draw User Avatar Badge (Bottom) — always 14px from bottom
  BadgeRect := GetAvatarRect;
  Canvas.Brush.Color := $EAEAEA;
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Style := psClear;
  Canvas.RoundRect(BadgeRect.Left, BadgeRect.Top, BadgeRect.Right,
    BadgeRect.Bottom, 8, 8);

  AvatarCircRect := Rect(BadgeRect.Left + 5, BadgeRect.Top + 4,
    BadgeRect.Left + 25, BadgeRect.Bottom - 4);
  Canvas.Brush.Color := FUserColor;
  Canvas.Pen.Style := psClear;
  Canvas.Ellipse(AvatarCircRect);

  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 9;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clWhite;
  Canvas.Brush.Style := bsClear;
  if Length(FUserName) > 0 then
    Letter := UpperCase(Copy(FUserName, 1, 1))
  else
    Letter := '?';
  Canvas.TextOut(
    AvatarCircRect.Left + (AvatarCircRect.Width - Canvas.TextWidth(Letter)) div 2,
    AvatarCircRect.Top + (AvatarCircRect.Height - Canvas.TextHeight(Letter)) div 2,
    Letter
    );

  Canvas.Font.Color := $222222;
  Canvas.Font.Style := [fsBold];
  Canvas.TextOut(
    BadgeRect.Left + 32,
    BadgeRect.Top + (BadgeRect.Height - Canvas.TextHeight(FUserName)) div 2,
    FUserName
    );
end;

procedure TTaskCard.MouseMove(Shift: TShiftState; X, Y: integer);
var
  I: integer;
  OldHovered: integer;
begin
  inherited MouseMove(Shift, X, Y);

  OldHovered := FHoveredButton;
  FHoveredButton := 0;

  for I := 1 to 3 do
  begin
    if PtInRect(GetButtonRect(I), Point(X, Y)) then
    begin
      FHoveredButton := I;
      Break;
    end;
  end;

  if FHoveredButton <> OldHovered then
  begin
    if FHoveredButton > 0 then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TTaskCard.DoCopy;
begin
  // Copy TaskCode to clipboard
  Clipboard.AsText := FTaskCode;
  // Fire the optional user event too
  if Assigned(FOnCopyClick) then FOnCopyClick(Self);
end;

procedure TTaskCard.DoEdit;
var
  NewText: string;
begin
  // Open an input dialog so the user can edit the task text inline
  NewText := FTaskText;
  if InputQuery('Editar Tarefa', 'Altere o texto da tarefa:', NewText) then
  begin
    TaskText := NewText;  // uses the setter so it Invalidates
  end;
  // Fire the optional user event too
  if Assigned(FOnEditClick) then FOnEditClick(Self);
end;

procedure TTaskCard.DeferredFree(Data: PtrInt);
begin
  Self.Free;
end;

procedure TTaskCard.DoDelete;
begin
  // Ask for confirmation before removing the component
  if MessageDlg('Excluir tarefa', 'Tem certeza que deseja excluir a tarefa "' +
    FTaskCode + '"?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    // Fire the optional user event first so the host can clean up references
    if Assigned(FOnDeleteClick) then FOnDeleteClick(Self);
    // Schedule free via Application.QueueAsyncCall to avoid destroying self
    // while still inside an event chain
    Application.QueueAsyncCall(@DeferredFree, 0);
  end;
end;

procedure TTaskCard.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
var
  ClickedButton: integer;
  I: integer;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if Button = mbLeft then
  begin
    ClickedButton := 0;
    for I := 1 to 3 do
    begin
      if PtInRect(GetButtonRect(I), Point(X, Y)) then
      begin
        ClickedButton := I;
        Break;
      end;
    end;

    case ClickedButton of
      1: DoCopy;
      2: DoEdit;
      3: DoDelete;
      else
        BeginDrag(False);
    end;
  end;
end;

procedure TTaskCard.MouseEnter;
begin
  inherited MouseEnter;
  FIsHovered := True;
  Invalidate;
end;

procedure TTaskCard.MouseLeave;
begin
  inherited MouseLeave;
  FIsHovered := False;
  FHoveredButton := 0;
  Cursor := crDefault;
  Invalidate;
end;

procedure TTaskCard.DragOver(Source: TObject; X, Y: integer;
  State: TDragState; var Accept: boolean);
begin
  inherited DragOver(Source, X, Y, State, Accept);
  Accept := (Source is TTaskCard) and (Source <> Self);

  if Accept then
  begin
    case State of
      dsDragEnter:
      begin
        FIsDragTarget := True;
        Invalidate;
      end;
      dsDragLeave:
      begin
        FIsDragTarget := False;
        Invalidate;
      end;
    end;
  end;
end;

procedure TTaskCard.DragDrop(Source: TObject; X, Y: integer);
begin
  inherited DragDrop(Source, X, Y);
  FIsDragTarget := False;
  Invalidate;

  if (Source is TTaskCard) and (Parent <> nil) then
  begin
    if Parent is THeaderScrollBox then
      THeaderScrollBox(Parent).HandleCardDrop(TTaskCard(Source), Self);
  end;
end;

end.
