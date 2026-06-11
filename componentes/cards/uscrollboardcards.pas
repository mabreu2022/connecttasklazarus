unit uScrollBoardCards;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, LCLIntf, LCLType, Types;

type
  TScrollBoardCards = class(TScrollBox)
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
  
  Color := $222222;
  ParentColor := False;
  AutoScroll := True;
  
  Width := 600;
  Height := 400;
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
    
    // Auto-adjust container height to show all rows if aligned to alTop
    if Align = alTop then
    begin
      NewHeight := CurY + MaxRowHeight + Margin;
      if Height <> NewHeight then
        Height := NewHeight;
    end;
  finally
    EnableAlign;
  end;
end;

end.
