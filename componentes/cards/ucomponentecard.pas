unit uComponenteCard;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons;

type
  TTaskCard = class(TFrame)
  private
    FHeaderPanel: TPanel;
    FButtonPanel: TPanel;
  public
    FEditTitle: TEdit;
    FMemoDesc: TMemo;
    FBtn1, FBtn2, FBtn3: TBitBtn;
    constructor Create(AOwner: TComponent); override;
  end;

implementation

constructor TTaskCard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // Configurações básicas do Frame Container principal
  Self.Width := 320;
  Self.Height := 200;
  Self.Constraints.MinHeight := 120;
  Self.Constraints.MinWidth := 250;

  // 1. Painel do Cabeçalho (Top)
  FHeaderPanel := TPanel.Create(Self);
  FHeaderPanel.Parent := Self;
  FHeaderPanel.Align := alTop;
  FHeaderPanel.Height := 32;
  FHeaderPanel.BevelOuter := bvNone;
  FHeaderPanel.BorderWidth := 2;

  // 2. Painel Invisível para os Botões (Alinhado à Direita do Cabeçalho)
  FButtonPanel := TPanel.Create(FHeaderPanel);
  FButtonPanel.Parent := FHeaderPanel;
  FButtonPanel.Align := alRight;
  FButtonPanel.Width := 110; // Largura suficiente para os 3 botões pequenos
  FButtonPanel.BevelOuter := bvNone;

  // 3. Criando os Botões de Ação (Da direita para a esquerda)
  FBtn1 := TBitBtn.Create(FButtonPanel);
  FBtn1.Parent := FButtonPanel;
  FBtn1.Align := alRight;
  FBtn1.Width := 32;
  FBtn1.Caption := 'B1';

  FBtn2 := TBitBtn.Create(FButtonPanel);
  FBtn2.Parent := FButtonPanel;
  FBtn2.Align := alRight;
  FBtn2.Width := 32;
  FBtn2.Caption := 'B2';

  FBtn3 := TBitBtn.Create(FButtonPanel);
  FBtn3.Parent := FButtonPanel;
  FBtn3.Align := alRight;
  FBtn3.Width := 32;
  FBtn3.Caption := 'B3';

  // 4. Campo de Entrada de Texto (Preenche o resto do Cabeçalho)
  FEditTitle := TEdit.Create(FHeaderPanel);
  FEditTitle.Parent := FHeaderPanel;
  FEditTitle.Align := alClient;
  FEditTitle.Text := 'Nova Tarefa...';

  // 5. Corpo do Card - Memo para Descrição (Preenche o resto do Frame)
  FMemoDesc := TMemo.Create(Self);
  FMemoDesc.Parent := Self;
  FMemoDesc.Align := alClient;
  FMemoDesc.ScrollBars := ssAutoVertical;
  FMemoDesc.Text := 'Insira os detalhes aqui...';
end;

end.
