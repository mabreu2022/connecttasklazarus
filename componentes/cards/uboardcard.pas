unit uBoardCard;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LCLIntf, LCLType, Types, Forms,
  Dialogs;

type
  TBoardCard = class(TCustomControl)
  private
    FBoardID: Integer;
    FBoardTitle: string;
    FStartColor: TColor;
    FEndColor: TColor;
    FPassword: string;
    
    // Hover state
    FHoveredButton: Integer; // 0 = none, 1 = edit, 2 = settings, 3 = delete
    FIsHovered: Boolean;
    
    // Events
    FOnEdit: TNotifyEvent;
    FOnSettings: TNotifyEvent;
    FOnDelete: TNotifyEvent;
    
    procedure SetBoardTitle(const AValue: string);
    procedure SetStartColor(AValue: TColor);
    procedure SetEndColor(AValue: TColor);
    procedure SetPassword(const AValue: string);
    
    function GetButtonRect(Index: Integer): TRect;
    
    procedure DoEdit;
    procedure DoSettings;
    procedure DoDelete;
    procedure DeferredFree(Data: PtrInt);
    
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure MouseEnter; override;
    procedure Click; override;
    
  public
    constructor Create(AOwner: TComponent); override;
    
  published
    property BoardID: Integer read FBoardID write FBoardID;
    property BoardTitle: string read FBoardTitle write SetBoardTitle;
    property StartColor: TColor read FStartColor write SetStartColor default $D87A3B; // Vibrant Blue (BGR)
    property EndColor: TColor read FEndColor write SetEndColor default $35261D;   // Dark Navy/Slate (BGR)
    property Password: string read FPassword write SetPassword;
    
    property OnEdit: TNotifyEvent read FOnEdit write FOnEdit;
    property OnSettings: TNotifyEvent read FOnSettings write FOnSettings;
    property OnDelete: TNotifyEvent read FOnDelete write FOnDelete;
    
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

procedure Register;
begin
  RegisterComponents('ConnectTask', [TBoardCard]);
end;

constructor TBoardCard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  FBoardID := 0;
  Width := 300;
  Height := 120;
  DoubleBuffered := True;
  
  FBoardTitle := 'Lazarus ConnectTask';
  FStartColor := $D87A3B; // Vibrant Blue (BGR)
  FEndColor := $35261D;   // Dark Navy/Slate (BGR)
  FPassword := '';
  
  FHoveredButton := 0;
  FIsHovered := False;
end;

procedure TBoardCard.SetBoardTitle(const AValue: string);
begin
  if FBoardTitle <> AValue then
  begin
    FBoardTitle := AValue;
    Invalidate;
  end;
end;

procedure TBoardCard.SetStartColor(AValue: TColor);
begin
  if FStartColor <> AValue then
  begin
    FStartColor := AValue;
    Invalidate;
  end;
end;

procedure TBoardCard.SetEndColor(AValue: TColor);
begin
  if FEndColor <> AValue then
  begin
    FEndColor := AValue;
    Invalidate;
  end;
end;

procedure TBoardCard.SetPassword(const AValue: string);
begin
  if FPassword <> AValue then
  begin
    FPassword := AValue;
    Invalidate;
  end;
end;

function TBoardCard.GetButtonRect(Index: Integer): TRect;
var
  RightOffset: Integer;
begin
  // Index: 1 = Edit (Pencil), 2 = Settings (Gear), 3 = Delete (Trash)
  // Stacked right-to-left
  RightOffset := 16 + (3 - Index) * 32;
  Result := Rect(Width - RightOffset - 26, 16, Width - RightOffset, 42);
end;

procedure TBoardCard.DoEdit;
var
  NewTitle: string;
begin
  NewTitle := FBoardTitle;
  if InputQuery('Editar Board', 'Novo título do Board:', NewTitle) then
  begin
    BoardTitle := NewTitle;
  end;
  if Assigned(FOnEdit) then FOnEdit(Self);
end;

procedure TBoardCard.DoSettings;
var
  NewPass: string;
begin
  NewPass := FPassword;
  if InputQuery('Configurar Senha', 'Defina a senha para este Board (deixe em branco para remover):', NewPass) then
  begin
    Password := NewPass;
  end;
  if Assigned(FOnSettings) then FOnSettings(Self);
end;

procedure TBoardCard.DeferredFree(Data: PtrInt);
begin
  Self.Free;
end;

procedure TBoardCard.DoDelete;
begin
  if MessageDlg(
    'Excluir Board',
    'Tem certeza que deseja excluir o Board "' + FBoardTitle + '"?',
    mtConfirmation,
    [mbYes, mbNo],
    0
  ) = mrYes then
  begin
    if Assigned(FOnDelete) then FOnDelete(Self);
  end;
end;

procedure TBoardCard.Paint;
var
  RGN: HRGN;
  BtnRect: TRect;
  TextR: TRect;
  I: Integer;
  CX, CY: Integer;
  Angle: Double;
  Rad: Integer;
begin
  inherited Paint;
  
  Canvas.AntialiasingMode := amOn;
  
  // 1. Draw rounded background with horizontal gradient
  RGN := CreateRoundRectRgn(0, 0, Width, Height, 16, 16);
  SelectClipRgn(Canvas.Handle, RGN);
  try
    Canvas.GradientFill(Rect(0, 0, Width, Height), FStartColor, FEndColor, gdHorizontal);
  finally
    SelectClipRgn(Canvas.Handle, 0);
    DeleteObject(RGN);
  end;
  
  // 2. Draw subtle border
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := $403024; // Subtle dark border
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;
  Canvas.RoundRect(0, 0, Width, Height, 16, 16);
  
  // 3. Draw Lock Icon if Password is Set (Top-Left)
  if FPassword <> '' then
  begin
    Canvas.Pen.Color := $A0A0A0; // Silver/grey
    Canvas.Pen.Width := 1;
    Canvas.Pen.Style := psSolid;
    
    // Lock shackle
    Canvas.Line(17, 21, 17, 18);
    Canvas.Line(17, 18, 23, 18);
    Canvas.Line(23, 18, 23, 21);
    
    // Lock body
    Canvas.Brush.Color := $403024;
    Canvas.Brush.Style := bsSolid;
    Canvas.RoundRect(14, 21, 26, 29, 2, 2);
  end;
  
  // 4. Draw buttons (1 = Edit, 2 = Settings, 3 = Delete)
  for I := 1 to 3 do
  begin
    BtnRect := GetButtonRect(I);
    
    // Draw button background
    if FHoveredButton = I then
    begin
      // Hover background (dark translucent, highlighted)
      if I = 3 then
        Canvas.Brush.Color := $1A1010 // Redish tint for delete hover
      else
        Canvas.Brush.Color := $352A20; // Slate tint
      Canvas.Pen.Color := $504030;
    end
    else
    begin
      // Normal background
      Canvas.Brush.Color := $251F19;
      Canvas.Pen.Color := $302620;
    end;
    
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Width := 1;
    Canvas.Pen.Style := psSolid;
    Canvas.RoundRect(BtnRect.Left, BtnRect.Top, BtnRect.Right, BtnRect.Bottom, 6, 6);
    
    // Draw icons inside button
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Color := $EAEAEA; // Light grey icon color
    
    case I of
      1: // Edit (Pencil)
        begin
          Canvas.Line(BtnRect.Left + 8,  BtnRect.Bottom - 8, BtnRect.Right - 8, BtnRect.Top + 8);
          Canvas.Line(BtnRect.Left + 10, BtnRect.Bottom - 8, BtnRect.Right - 6, BtnRect.Top + 8);
          Canvas.Line(BtnRect.Left + 7,  BtnRect.Bottom - 7, BtnRect.Left + 9,  BtnRect.Bottom - 8);
          Canvas.Line(BtnRect.Left + 7,  BtnRect.Bottom - 7, BtnRect.Left + 8,  BtnRect.Bottom - 5);
        end;
        
      2: // Settings (Gear)
        begin
          CX := BtnRect.Left + (BtnRect.Width div 2);
          CY := BtnRect.Top + (BtnRect.Height div 2);
          
          // Outer teeth
          for Rad := 0 to 7 do
          begin
            Angle := Rad * (2 * Pi / 8);
            Canvas.Line(
              Round(CX + 4 * Cos(Angle)), Round(CY + 4 * Sin(Angle)),
              Round(CX + 7 * Cos(Angle)), Round(CY + 7 * Sin(Angle))
            );
          end;
          
          // Inner hub
          Canvas.Ellipse(CX - 4, CY - 4, CX + 4, CY + 4);
        end;
        
      3: // Delete (Trash)
        begin
          if FHoveredButton = 3 then
            Canvas.Pen.Color := $4444FF // Highlight red in BGR
          else
            Canvas.Pen.Color := $EAEAEA;
            
          Canvas.Line(BtnRect.Left + 9,  BtnRect.Top + 7,  BtnRect.Left + 13, BtnRect.Top + 7);  // handle
          Canvas.Line(BtnRect.Left + 6,  BtnRect.Top + 9,  BtnRect.Right - 6, BtnRect.Top + 9);  // lid
          Canvas.Line(BtnRect.Left + 8,  BtnRect.Top + 10,  BtnRect.Left + 8,  BtnRect.Bottom - 7); // left side
          Canvas.Line(BtnRect.Right - 8, BtnRect.Top + 10,  BtnRect.Right - 8, BtnRect.Bottom - 7); // right side
          Canvas.Line(BtnRect.Left + 8,  BtnRect.Bottom - 7, BtnRect.Right - 8, BtnRect.Bottom - 7); // bottom
        end;
    end;
  end;
  
  // 5. Draw Board Title (Centered)
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 14;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clWhite;
  
  // Leave top margin for buttons, and bottom margin
  TextR := Rect(16, 44, Width - 16, Height - 16);
  DrawText(Canvas.Handle, PChar(FBoardTitle), -1, TextR, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
end;

procedure TBoardCard.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  OldHovered: Integer;
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

procedure TBoardCard.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ClickedButton: Integer;
  I: Integer;
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
      1: DoEdit;
      2: DoSettings;
      3: DoDelete;
    else
      BeginDrag(False);
    end;
  end;
end;

procedure TBoardCard.Click;
var
  InputPass: string;
begin
  // If clicking on the action buttons, do NOT trigger the main Click event
  if FHoveredButton <> 0 then
    Exit;

  // If password is configured, request it before continuing
  if FPassword <> '' then
  begin
    InputPass := '';
    if not InputQuery('Acesso Restrito', 'Digite a senha para acessar este Board:', InputPass) then
      Exit; // Canceled
      
    if InputPass <> FPassword then
    begin
      ShowMessage('Senha incorreta! Acesso negado.');
      Exit; // Wrong password, block event
    end;
  end;

  inherited Click;
end;

procedure TBoardCard.MouseEnter;
begin
  inherited MouseEnter;
  FIsHovered := True;
  Invalidate;
end;

procedure TBoardCard.MouseLeave;
begin
  inherited MouseLeave;
  FIsHovered := False;
  FHoveredButton := 0;
  Cursor := crDefault;
  Invalidate;
end;

end.
