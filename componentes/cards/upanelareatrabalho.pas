unit uPanelAreaTrabalho;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LCLIntf, LCLType, Types, Forms,
  Dialogs;

type
  TPanelAreaTrabalho = class(TCustomControl)
  private
    FWorkspaceName: string;
    FBadgeText: string;
    FStartColor: TColor;
    FEndColor: TColor;
    FLinkedControl: TControl;
    
    // Hover state
    FHoveredButton: Integer; // 0 = none, 1 = Create Board button (+ Novo Quadro), 2 = Delete button (Trash)
    
    // Events
    FOnCreateBoard: TNotifyEvent;
    FOnDelete: TNotifyEvent;
    
    procedure SetWorkspaceName(const AValue: string);
    procedure SetBadgeText(const AValue: string);
    procedure SetStartColor(AValue: TColor);
    procedure SetEndColor(AValue: TColor);
    
    function GetButtonRect(Index: Integer): TRect;
    
    procedure DoCreateBoard;
    procedure DoDelete;
    
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
  published
    property WorkspaceName: string read FWorkspaceName write SetWorkspaceName;
    property BadgeText: string read FBadgeText write SetBadgeText;
    property StartColor: TColor read FStartColor write SetStartColor default $15110B; // BGR Dark Blue/Grey
    property EndColor: TColor read FEndColor write SetEndColor default $1C160F;     // BGR Lighter Slate
    property LinkedControl: TControl read FLinkedControl write FLinkedControl;
    
    property OnCreateBoard: TNotifyEvent read FOnCreateBoard write FOnCreateBoard;
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
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('ConnectTask', [TPanelAreaTrabalho]);
end;

constructor TPanelAreaTrabalho.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  Height := 50;
  Width := 800;
  DoubleBuffered := True;
  
  FWorkspaceName := 'mauricio abreu''s Workspace';
  FBadgeText := 'Workspace';
  
  FStartColor := $15110B;
  FEndColor := $1C160F;
  FLinkedControl := nil;
  
  FHoveredButton := 0;
end;

destructor TPanelAreaTrabalho.Destroy;
begin
  if FLinkedControl <> nil then
  begin
    FLinkedControl.Free;
    FLinkedControl := nil;
  end;
  inherited Destroy;
end;

procedure TPanelAreaTrabalho.SetWorkspaceName(const AValue: string);
begin
  if FWorkspaceName <> AValue then
  begin
    FWorkspaceName := AValue;
    Invalidate;
  end;
end;

procedure TPanelAreaTrabalho.SetBadgeText(const AValue: string);
begin
  if FBadgeText <> AValue then
  begin
    FBadgeText := AValue;
    Invalidate;
  end;
end;

procedure TPanelAreaTrabalho.SetStartColor(AValue: TColor);
begin
  if FStartColor <> AValue then
  begin
    FStartColor := AValue;
    Invalidate;
  end;
end;

procedure TPanelAreaTrabalho.SetEndColor(AValue: TColor);
begin
  if FEndColor <> AValue then
  begin
    FEndColor := AValue;
    Invalidate;
  end;
end;

function TPanelAreaTrabalho.GetButtonRect(Index: Integer): TRect;
begin
  if Index = 2 then
  begin
    // Delete Button (Rightmost, 32x32, vertically centered)
    Result := Rect(Width - 16 - 32, (Height - 32) div 2, Width - 16, (Height + 32) div 2);
  end
  else
  begin
    // Create Board Button (Left of delete, 130x32, vertically centered)
    Result := Rect(Width - 16 - 32 - 12 - 130, (Height - 32) div 2, Width - 16 - 32 - 12, (Height + 32) div 2);
  end;
end;

procedure TPanelAreaTrabalho.DoCreateBoard;
begin
  if Assigned(FOnCreateBoard) then FOnCreateBoard(Self);
end;

procedure TPanelAreaTrabalho.DoDelete;
begin
  if MessageDlg(
    'Excluir Área de Trabalho',
    'Tem certeza de que deseja excluir a área de trabalho "' + FWorkspaceName + '" e todos os seus quadros?',
    mtConfirmation,
    [mbYes, mbNo],
    0
  ) = mrYes then
  begin
    if Assigned(FOnDelete) then FOnDelete(Self);
    
    // Automatically frees the linked TScrollBoardCards
    if FLinkedControl <> nil then
    begin
      FLinkedControl.Free;
      FLinkedControl := nil;
    end;
    
    // Safely free self
    Free;
  end;
end;

procedure TPanelAreaTrabalho.Paint;
var
  RGN: HRGN;
  BtnRect: TRect;
  BadgeRect: TRect;
  TextW, TextH: Integer;
  BtnText: string;
begin
  inherited Paint;
  
  Canvas.AntialiasingMode := amOn;
  
  // 1. Draw rounded background with horizontal gradient
  RGN := CreateRoundRectRgn(0, 0, Width, Height, 8, 8);
  SelectClipRgn(Canvas.Handle, RGN);
  try
    Canvas.GradientFill(Rect(0, 0, Width, Height), FStartColor, FEndColor, gdHorizontal);
  finally
    SelectClipRgn(Canvas.Handle, 0);
    DeleteObject(RGN);
  end;
  
  // 2. Draw Workspace Name (Left-aligned, vertically centered)
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 11;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clWhite;
  Canvas.Brush.Style := bsClear;
  
  TextH := Canvas.TextHeight(FWorkspaceName);
  TextW := Canvas.TextWidth(FWorkspaceName);
  Canvas.TextOut(16, (Height - TextH) div 2, FWorkspaceName);
  
  // 3. Draw Capsule Badge ("Workspace")
  if FBadgeText <> '' then
  begin
    Canvas.Font.Size := 8;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := $A0A0A0; // Light grey text
    
    BadgeRect := Rect(
      16 + TextW + 10,
      (Height - 18) div 2,
      16 + TextW + 10 + Canvas.TextWidth(FBadgeText) + 12,
      (Height + 18) div 2
    );
    
    Canvas.Brush.Color := $221A15; // Dark grey capsule background
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Style := psClear;
    Canvas.RoundRect(BadgeRect, 10, 10);
    
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(
      BadgeRect.Left + 6,
      BadgeRect.Top + (BadgeRect.Height - Canvas.TextHeight(FBadgeText)) div 2,
      FBadgeText
    );
  end;
  
  // 4. Draw Buttons (Right-aligned)
  // Button 1: Create Board (+ Novo Quadro)
  BtnRect := GetButtonRect(1);
  if FHoveredButton = 1 then
  begin
    Canvas.Brush.Color := $FF6A55; // Lighter blue-violet
    Canvas.Pen.Color := $FF8A75;
  end
  else
  begin
    Canvas.Brush.Color := $E5464F; // Accent Blue-violet
    Canvas.Pen.Color := $EA565F;
  end;
  
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;
  Canvas.RoundRect(BtnRect.Left, BtnRect.Top, BtnRect.Right, BtnRect.Bottom, 6, 6);
  
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 9;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clWhite;
  Canvas.Brush.Style := bsClear;
  BtnText := '+ Novo Quadro';
  Canvas.TextOut(
    BtnRect.Left + (BtnRect.Width - Canvas.TextWidth(BtnText)) div 2,
    BtnRect.Top + (BtnRect.Height - Canvas.TextHeight(BtnText)) div 2,
    BtnText
  );
  
  // Button 2: Delete Workspace (Trash, Red)
  BtnRect := GetButtonRect(2);
  if FHoveredButton = 2 then
  begin
    Canvas.Brush.Color := $5555FF; // Lighter red
    Canvas.Pen.Color := $7575FF;
  end
  else
  begin
    Canvas.Brush.Color := $3535E5; // Red
    Canvas.Pen.Color := $4545F5;
  end;
  
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Style := psSolid;
  Canvas.RoundRect(BtnRect.Left, BtnRect.Top, BtnRect.Right, BtnRect.Bottom, 6, 6);
  
  // Trash can icon
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := clWhite;
  Canvas.Pen.Width := 1;
  
  Canvas.Line(BtnRect.Left + 11, BtnRect.Top + 8,  BtnRect.Left + 19, BtnRect.Top + 8);  // handle
  Canvas.Line(BtnRect.Left + 7,  BtnRect.Top + 10, BtnRect.Right - 7,  BtnRect.Top + 10); // lid
  Canvas.Line(BtnRect.Left + 9,  BtnRect.Top + 11, BtnRect.Left + 9,  BtnRect.Bottom - 8); // left side
  Canvas.Line(BtnRect.Right - 9, BtnRect.Top + 11, BtnRect.Right - 9, BtnRect.Bottom - 8); // right side
  Canvas.Line(BtnRect.Left + 9,  BtnRect.Bottom - 8, BtnRect.Right - 9, BtnRect.Bottom - 8); // bottom
  Canvas.Line(BtnRect.Left + 12, BtnRect.Top + 12, BtnRect.Left + 12, BtnRect.Bottom - 9); // inner lines
  Canvas.Line(BtnRect.Right - 12,BtnRect.Top + 12, BtnRect.Right - 12,BtnRect.Bottom - 9);
end;

procedure TPanelAreaTrabalho.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  OldHovered: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  
  OldHovered := FHoveredButton;
  FHoveredButton := 0;
  
  for I := 1 to 2 do
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

procedure TPanelAreaTrabalho.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  
  if Button = mbLeft then
  begin
    case FHoveredButton of
      1: DoCreateBoard;
      2: DoDelete;
    end;
  end;
end;

procedure TPanelAreaTrabalho.MouseLeave;
begin
  inherited MouseLeave;
  FHoveredButton := 0;
  Cursor := crDefault;
  Invalidate;
end;

end.
