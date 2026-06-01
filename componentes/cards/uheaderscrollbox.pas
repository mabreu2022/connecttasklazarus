unit uHeaderScrollBox;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, Graphics;

type
  THeaderScrollBox = class(TScrollBox)
  private
    FHeaderPanel: TPanel;
    function GetHeaderHeight: Integer;
    procedure SetHeaderHeight(AValue: Integer);
    function GetHeaderColor: TColor;
    procedure SetHeaderColor(AValue: TColor);
    function GetHeaderCaption: string;
    procedure SetHeaderCaption(const AValue: string);
  protected
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property HeaderPanel: TPanel read FHeaderPanel;
    property HeaderHeight: Integer read GetHeaderHeight write SetHeaderHeight default 50;
    property HeaderColor: TColor read GetHeaderColor write SetHeaderColor default clDefault;
    property HeaderCaption: string read GetHeaderCaption write SetHeaderCaption;
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

end.
