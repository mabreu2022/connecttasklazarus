unit uScrollBoardCards;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, LCLIntf, LCLType, Types;

type
  TScrollBoardCards = class(TScrollBox)
  private
    FAllocatingHeight: Integer;
    procedure SetHeightAsync(Data: PtrInt);
  protected
    procedure AlignControls(AControl: TControl; var ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Align;
    property Anchors;
    property AutoScroll default True;
    property Color default $222222; // Premium charcoal dark background
    property ParentColor default False;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('ConnectTask', [TScrollBoardCards]);
end;

constructor TScrollBoardCards.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAllocatingHeight := 0;
  
  Color := $222222;
  ParentColor := False;
  AutoScroll := False;
  HorzScrollBar.Visible := False;
  VertScrollBar.Visible := False;
  
  Width := 600;
  Height := 140;
end;

procedure TScrollBoardCards.SetHeightAsync(Data: PtrInt);
begin
  if Height <> Data then
    Height := Data;
  FAllocatingHeight := 0;
end;

procedure TScrollBoardCards.AlignControls(AControl: TControl; var ARect: TRect);
var
  I: Integer;
  Ctrl: TControl;
  CurX, CurY: Integer;
  MaxRowHeight: Integer;
  Margin: Integer;
  NewHeight: Integer;
begin
  inherited AlignControls(AControl, ARect);
  
  Margin := 10;
  CurX := Margin;
  CurY := Margin;
  MaxRowHeight := 0;
  
  DisableAlign;
  try
    for I := 0 to ControlCount - 1 do
    begin
      Ctrl := Controls[I];
      if (Ctrl = nil) or (not Ctrl.Visible) or (Ctrl.Align <> alNone) then
        Continue;
        
      // Wrap to the next line if the control exceeds ClientWidth
      if (CurX > Margin) and (CurX + Ctrl.Width + Margin > ClientWidth) then
      begin
        CurX := Margin;
        CurY := CurY + MaxRowHeight + Margin;
        MaxRowHeight := 0;
      end;
      
      Ctrl.SetBounds(CurX, CurY, Ctrl.Width, Ctrl.Height);
      
      if Ctrl.Height > MaxRowHeight then
        MaxRowHeight := Ctrl.Height;
        
      CurX := CurX + Ctrl.Width + Margin;
    end;
    
    if ControlCount > 0 then
      NewHeight := CurY + MaxRowHeight + Margin
    else
      NewHeight := 140;
      
    if (NewHeight <> Height) and (NewHeight <> FAllocatingHeight) then
    begin
      FAllocatingHeight := NewHeight;
      Application.QueueAsyncCall(@SetHeightAsync, NewHeight);
    end;
  finally
    EnableAlign;
  end;
end;

end.
