unit uTaskDetail;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, ComCtrls, LCLIntf, LCLType, Math, IBQuery, DB, Clipbrd, Variants;

type

  { TFormTaskDetail }

  TFormTaskDetail = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    FCardID          : Integer;
    FBoardID         : Integer;
    FListTitle       : string;
    FListID          : Integer;
    FEditingDesc     : Boolean;
    FShowScheduleAI  : Boolean;
    FShowAddAssignee : Boolean;

    // Header
    PnlHeader      : TPanel;
    LblTitle       : TLabel;
    EdtTitle       : TEdit;
    BtnEditTitle   : TSpeedButton;
    BtnSaveTitle   : TSpeedButton;
    BtnCancelTitle : TSpeedButton;
    BtnCopyTitle   : TSpeedButton;
    LblCreator     : TLabel;
    LblListStatus  : TLabel;
    CboPriority    : TComboBox;
    BtnClose       : TSpeedButton;

    // Time bar
    PnlTimeBar   : TPanel;
    PnlTimeChips : TPanel;

    // Columns
    PnlColumns : TPanel;
    PnlLeft    : TPanel;
    PnlRight   : TPanel;
    ScrollLeft : TScrollBox;
    ScrollRight: TScrollBox;

    // Left – Description
    PnlDescHeader  : TPanel;
    MemoDesc       : TMemo;
    LblDescDisplay : TMemo;
    PnlDescActions : TPanel;
    BtnSaveDesc    : TButton;
    BtnCancelDesc  : TButton;

    // Left – Comments
    EdtComment     : TEdit;
    BtnSendComment : TSpeedButton;
    PnlCommentList : TPanel;

    // Right – Assignees
    CboAssignees   : TComboBox;
    PnlAssigneeList: TPanel;

    // Right – Attachments
    PnlAttachList: TPanel;

    // Right – AI Schedule
    BtnScheduleAI  : TButton;
    PnlScheduleAI  : TPanel;
    CboAIModel     : TComboBox;
    EdtAIDate      : TEdit;

    // Right – Move / Copy Board
    CboMoveBoard: TComboBox;
    CboCopyBoard: TComboBox;

    // Right – Related
    EdtRelated    : TEdit;
    PnlRelatedList: TPanel;

    // Right – Activities
    ScrollActivity : TScrollBox;
    PnlActivityLog : TPanel;

    // ---- UI builder ----
    procedure BuildUI;

    // ---- DB ----
    function  RunQuery(const ASQL: string;
                       const ANames: array of string;
                       const AValues: array of Variant): TIBQuery;
    procedure ExecDB(const ASQL: string;
                     const ANames: array of string;
                     const AValues: array of Variant);

    // ---- Loaders ----
    procedure LoadCardData;
    procedure LoadAllUsers;
    procedure LoadAssignees;
    procedure LoadComments;
    procedure LoadAttachments;
    procedure LoadRelatedCards;
    procedure LoadActivities;
    procedure LoadTimeBar;
    procedure LoadBoards;
    procedure LoadSchedules;

    // ---- Builders ----
    procedure BuildAssigneeChips;
    procedure BuildCommentItems;
    procedure BuildAttachmentItems;
    procedure BuildRelatedItems;
    procedure BuildActivityItems;

    // ---- Handlers ----
    procedure BtnCloseClick(Sender: TObject);
    procedure BtnEditTitleClick(Sender: TObject);
    procedure BtnSaveTitleClick(Sender: TObject);
    procedure BtnCancelTitleClick(Sender: TObject);
    procedure BtnCopyTitleClick(Sender: TObject);
    procedure CboPriorityChange(Sender: TObject);
    procedure BtnEditDescClick(Sender: TObject);
    procedure BtnSaveDescClick(Sender: TObject);
    procedure BtnCancelDescClick(Sender: TObject);
    procedure BtnSendCommentClick(Sender: TObject);
    procedure BtnAddAssigneeClick(Sender: TObject);
    procedure CboAssigneesChange(Sender: TObject);
    procedure BtnScheduleAIClick(Sender: TObject);
    procedure BtnSaveScheduleClick(Sender: TObject);
    procedure BtnChooseBoardClick(Sender: TObject);
    procedure BtnCopyCardClick(Sender: TObject);
    procedure BtnLinkCardClick(Sender: TObject);

    // ---- Chip/item remove helpers (need full procedures for event binding) ----
    procedure RemoveAssigneeClick(Sender: TObject);
    procedure DeleteAttachmentClick(Sender: TObject);
    procedure UnlinkCardClick(Sender: TObject);
    procedure OpenAttachmentClick(Sender: TObject);

    // ---- Helpers ----
    procedure ShowTitleEdit(AEdit: Boolean);
    procedure ShowDescEdit(AEdit: Boolean);
    procedure UpdatePriorityColor;
    procedure ClearPanel(APanel: TWinControl);
    function  FormatDuration(AStart, AEnd_: TDateTime): string;
    function  FirstLetter(const AName: string): string;
    function  PriorityColor(const APrio: string): TColor;
    function  PriorityTextColor(const APrio: string): TColor;

    function  MakeLabel(AParent: TWinControl; const AText: string;
                        ASize: Integer; ABold: Boolean; AColor: TColor): TLabel;
    function  MakePanel(AParent: TWinControl; AColor: TColor; AH: Integer): TPanel;
    function  MakeButton(AParent: TWinControl; const ACap: string;
                         ABg, AFg: TColor): TButton;
    function  MakeSepLabel(AParent: TWinControl; const AText: string): TLabel;

  public
    procedure LoadCard(ACardID: Integer);
  end;

var
  FormTaskDetail: TFormTaskDetail;

implementation

uses
  uLogin, udm;

{$R *.lfm}

const
  CLR_BG   = $1A1A2E;
  CLR_CARD = $252540;
  CLR_HDR  = $151527;
  CLR_TEXT = $F0F0FA;
  CLR_MUTE = $8080AA;
  CLR_PRIM = $CC6633;   // blue-violet BGR
  CLR_OK   = $36D362;   // green BGR

  PRIORITIES: array[0..6] of string = (
    'Baixa', 'Média', 'Alta', 'Observação', 'Ideia', 'URGENTE', 'Recuperado');

// ---------------------------------------------------------------------------
// Colour helpers
// ---------------------------------------------------------------------------

function TFormTaskDetail.PriorityColor(const APrio: string): TColor;
var S: string;
begin
  S := LowerCase(Trim(APrio));
  if S = 'alta'         then Result := $6B6BFF
  else if S = 'média'   then Result := $99ECFF
  else if S = 'observação' then Result := $712ECC
  else if S = 'ideia'   then Result := $DB9834
  else if S = 'urgente' then Result := $B659B6
  else if S = 'recuperado' then Result := $B469FF
  else Result := $4A4A4A;
end;

function TFormTaskDetail.PriorityTextColor(const APrio: string): TColor;
begin
  if SameText(Trim(APrio), 'Média') then Result := $222222
  else Result := clWhite;
end;

function TFormTaskDetail.FormatDuration(AStart, AEnd_: TDateTime): string;
var
  Mins, Hrs, Days: Integer;
begin
  Mins := Abs(Round((AEnd_ - AStart) * 1440));
  Hrs  := Mins div 60;
  Days := Hrs  div 24;
  if Days > 0 then
    Result := IntToStr(Days) + 'd ' + IntToStr(Hrs mod 24) + 'h'
  else if Hrs > 0 then
    Result := IntToStr(Hrs) + 'h ' + IntToStr(Mins mod 60) + 'm'
  else
    Result := IntToStr(Mins) + 'm';
end;

function TFormTaskDetail.FirstLetter(const AName: string): string;
begin
  if Length(AName) > 0 then Result := UpperCase(Copy(AName, 1, 1))
  else Result := '?';
end;

// ---------------------------------------------------------------------------
// Widget factory helpers
// ---------------------------------------------------------------------------

function TFormTaskDetail.MakeLabel(AParent: TWinControl; const AText: string;
  ASize: Integer; ABold: Boolean; AColor: TColor): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent      := AParent;
  Result.Caption     := AText;
  Result.Font.Name   := 'Segoe UI';
  Result.Font.Size   := ASize;
  Result.Font.Color  := AColor;
  Result.ParentColor := False;
  Result.Color       := AParent.Color;
  if ABold then Result.Font.Style := [fsBold];
end;

function TFormTaskDetail.MakePanel(AParent: TWinControl; AColor: TColor;
  AH: Integer): TPanel;
begin
  Result := TPanel.Create(Self);
  Result.Parent     := AParent;
  Result.Color      := AColor;
  Result.BevelOuter := bvNone;
  Result.BevelInner := bvNone;
  Result.Height     := AH;
  Result.AutoSize   := False;
end;

function TFormTaskDetail.MakeButton(AParent: TWinControl; const ACap: string;
  ABg, AFg: TColor): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent      := AParent;
  Result.Caption     := ACap;
  Result.Height      := 30;
  Result.Color       := ABg;
  Result.Font.Color  := AFg;
  Result.Font.Name   := 'Segoe UI';
  Result.Font.Size   := 9;
  Result.Font.Style  := [fsBold];
end;

function TFormTaskDetail.MakeSepLabel(AParent: TWinControl; const AText: string): TLabel;
begin
  Result := MakeLabel(AParent, AText, 9, True, CLR_MUTE);
  Result.Align := alTop;
  Result.AutoSize := True;
  Result.BorderSpacing.Top    := 14;
  Result.BorderSpacing.Bottom := 4;
end;

// ---------------------------------------------------------------------------
// ClearPanel
// ---------------------------------------------------------------------------

procedure TFormTaskDetail.ClearPanel(APanel: TWinControl);
var I: Integer;
begin
  APanel.DisableAlign;
  try
    for I := APanel.ControlCount - 1 downto 0 do
      APanel.Controls[I].Free;
  finally
    APanel.EnableAlign;
  end;
end;

// ---------------------------------------------------------------------------
// DB helpers
// ---------------------------------------------------------------------------

function TFormTaskDetail.RunQuery(const ASQL: string;
  const ANames: array of string; const AValues: array of Variant): TIBQuery;
var
  Q: TIBQuery;
  I: Integer;
begin
  Q := TIBQuery.Create(nil);
  Q.Database    := DataModule1.IBDatabase1;
  Q.Transaction := DataModule1.IBTransaction1;
  Q.SQL.Text    := ASQL;
  for I := 0 to High(ANames) do
    case VarType(AValues[I]) and varTypeMask of
      varSmallint, varInteger, varShortInt,
      varByte, varWord, varLongWord, varInt64:
        Q.ParamByName(ANames[I]).AsInteger := Integer(AValues[I]);
      varDate:
        Q.ParamByName(ANames[I]).AsDateTime := TDateTime(AValues[I]);
      varBoolean:
        Q.ParamByName(ANames[I]).AsBoolean := Boolean(AValues[I]);
      else
        Q.ParamByName(ANames[I]).AsString := VarToStr(AValues[I]);
    end;
  Q.Open;
  Result := Q;
end;

procedure TFormTaskDetail.ExecDB(const ASQL: string;
  const ANames: array of string; const AValues: array of Variant);
var
  Q: TIBQuery;
  I: Integer;
begin
  Q := TIBQuery.Create(nil);
  try
    Q.Database    := DataModule1.IBDatabase1;
    Q.Transaction := DataModule1.IBTransaction1;
    Q.SQL.Text    := ASQL;
    for I := 0 to High(ANames) do
      case VarType(AValues[I]) and varTypeMask of
        varSmallint, varInteger, varShortInt,
        varByte, varWord, varLongWord, varInt64:
          Q.ParamByName(ANames[I]).AsInteger := Integer(AValues[I]);
        varDate:
          Q.ParamByName(ANames[I]).AsDateTime := TDateTime(AValues[I]);
        varBoolean:
          Q.ParamByName(ANames[I]).AsBoolean := Boolean(AValues[I]);
        else
          Q.ParamByName(ANames[I]).AsString := VarToStr(AValues[I]);
      end;
    Q.ExecSQL;
    DataModule1.IBTransaction1.CommitRetaining;
  finally
    Q.Free;
  end;
end;

// ===========================================================================
// BuildUI
// ===========================================================================

procedure TFormTaskDetail.BuildUI;
var
  P, PRow: TPanel;
  Sep: TBevel;
  Lbl: TLabel;
  I: Integer;
begin
  Color          := CLR_BG;
  BorderStyle    := bsSizeable;
  Position       := poScreenCenter;
  KeyPreview     := True;

  // ── Header ───────────────────────────────────────────────────────────────
  PnlHeader := MakePanel(Self, CLR_HDR, 100);
  PnlHeader.Align := alTop;
  { padding removed - use BorderSpacing on children }

  // Close button
  BtnClose := TSpeedButton.Create(Self);
  BtnClose.Parent    := PnlHeader;
  BtnClose.Caption   := '✕';
  BtnClose.Width     := 30;
  BtnClose.Height    := 30;
  BtnClose.Flat      := True;
  BtnClose.Anchors   := [akTop, akRight];
  BtnClose.Font.Size := 14;
  BtnClose.Font.Color:= CLR_MUTE;
  BtnClose.Top       := 8;
  BtnClose.OnClick   := @BtnCloseClick;

  // Title row
  P := MakePanel(PnlHeader, CLR_HDR, 36);
  P.Align := alTop;

  LblTitle := TLabel.Create(Self);
  LblTitle.Parent     := P;
  LblTitle.Align      := alClient;
  LblTitle.Caption    := 'Carregando...';
  LblTitle.Font.Name  := 'Segoe UI';
  LblTitle.Font.Size  := 14;
  LblTitle.Font.Style := [fsBold];
  LblTitle.Font.Color := CLR_TEXT;
  LblTitle.Layout     := tlCenter;
  LblTitle.ParentColor:= False;
  LblTitle.Color      := CLR_HDR;

  EdtTitle := TEdit.Create(Self);
  EdtTitle.Parent    := P;
  EdtTitle.Align     := alClient;
  EdtTitle.Color     := CLR_CARD;
  EdtTitle.Font.Color:= CLR_TEXT;
  EdtTitle.Font.Name := 'Segoe UI';
  EdtTitle.Font.Size := 13;
  EdtTitle.Font.Style:= [fsBold];
  EdtTitle.Visible   := False;

  BtnSaveTitle := TSpeedButton.Create(Self);
  BtnSaveTitle.Parent     := P;
  BtnSaveTitle.Align      := alRight;
  BtnSaveTitle.Width      := 28;
  BtnSaveTitle.Caption    := '✓';
  BtnSaveTitle.Flat       := True;
  BtnSaveTitle.Font.Color := $71CC4A;
  BtnSaveTitle.Visible    := False;
  BtnSaveTitle.OnClick    := @BtnSaveTitleClick;

  BtnCancelTitle := TSpeedButton.Create(Self);
  BtnCancelTitle.Parent    := P;
  BtnCancelTitle.Align     := alRight;
  BtnCancelTitle.Width     := 28;
  BtnCancelTitle.Caption   := '✕';
  BtnCancelTitle.Flat      := True;
  BtnCancelTitle.Font.Color:= $6666FF;
  BtnCancelTitle.Visible   := False;
  BtnCancelTitle.OnClick   := @BtnCancelTitleClick;

  BtnEditTitle := TSpeedButton.Create(Self);
  BtnEditTitle.Parent    := P;
  BtnEditTitle.Align     := alRight;
  BtnEditTitle.Width     := 28;
  BtnEditTitle.Caption   := '✎';
  BtnEditTitle.Flat      := True;
  BtnEditTitle.Font.Color:= CLR_MUTE;
  BtnEditTitle.OnClick   := @BtnEditTitleClick;

  BtnCopyTitle := TSpeedButton.Create(Self);
  BtnCopyTitle.Parent    := P;
  BtnCopyTitle.Align     := alRight;
  BtnCopyTitle.Width     := 28;
  BtnCopyTitle.Caption   := '⎘';
  BtnCopyTitle.Flat      := True;
  BtnCopyTitle.Font.Color:= CLR_MUTE;
  BtnCopyTitle.OnClick   := @BtnCopyTitleClick;

  // Creator + priority row
  PRow := MakePanel(PnlHeader, CLR_HDR, 28);
  PRow.Align := alTop;

  LblCreator := TLabel.Create(Self);
  LblCreator.Parent    := PRow;
  LblCreator.Align     := alLeft;
  LblCreator.AutoSize  := True;
  LblCreator.Caption   := '';
  LblCreator.Font.Name := 'Segoe UI';
  LblCreator.Font.Size := 9;
  LblCreator.Font.Color:= CLR_MUTE;
  LblCreator.Layout    := tlCenter;
  LblCreator.ParentColor:= False;
  LblCreator.Color     := CLR_HDR;

  LblListStatus := TLabel.Create(Self);
  LblListStatus.Parent    := PRow;
  LblListStatus.Align     := alLeft;
  LblListStatus.AutoSize  := True;
  LblListStatus.Caption   := '';
  LblListStatus.Font.Name := 'Segoe UI';
  LblListStatus.Font.Size := 9;
  LblListStatus.Font.Color:= CLR_OK;
  LblListStatus.Font.Style:= [fsBold];
  LblListStatus.Layout    := tlCenter;
  LblListStatus.ParentColor:= False;
  LblListStatus.Color     := CLR_HDR;
  LblListStatus.BorderSpacing.Left := 12;

  CboPriority := TComboBox.Create(Self);
  CboPriority.Parent     := PRow;
  CboPriority.Align      := alRight;
  CboPriority.Width      := 110;
  CboPriority.Style      := csDropDownList;
  CboPriority.Color      := $4A4A4A;
  CboPriority.Font.Color := clWhite;
  CboPriority.Font.Name  := 'Segoe UI';
  CboPriority.Font.Size  := 9;
  CboPriority.Font.Style := [fsBold];
  for I := 0 to High(PRIORITIES) do
    CboPriority.Items.Add(PRIORITIES[I]);
  CboPriority.OnChange := @CboPriorityChange;

  Lbl := MakeLabel(PRow, 'Prioridade: ', 9, True, CLR_MUTE);
  Lbl.Align  := alRight;
  Lbl.Layout := tlCenter;

  // ── Time bar ──────────────────────────────────────────────────────────────
  PnlTimeBar := MakePanel(Self, CLR_HDR, 46);
  PnlTimeBar.Align := alTop;
  { padding removed - use BorderSpacing on children }

  Lbl := MakeLabel(PnlTimeBar, '⏱  Tempo em cada etapa:', 9, True, CLR_MUTE);
  Lbl.Align := alTop;

  PnlTimeChips := MakePanel(PnlTimeBar, CLR_HDR, 0);
  PnlTimeChips.Align := alClient;

  Sep := TBevel.Create(Self);
  Sep.Parent := Self;
  Sep.Align  := alTop;
  Sep.Height := 1;
  Sep.Shape  := bsTopLine;

  // ── Two columns ───────────────────────────────────────────────────────────
  PnlColumns := MakePanel(Self, CLR_BG, 0);
  PnlColumns.Align := alClient;

  // Right column
  PnlRight := MakePanel(PnlColumns, CLR_BG, 0);
  PnlRight.Align := alRight;
  PnlRight.Width := 380;

  ScrollRight := TScrollBox.Create(Self);
  ScrollRight.Parent            := PnlRight;
  ScrollRight.Align             := alClient;
  ScrollRight.Color             := CLR_BG;
  ScrollRight.BorderStyle       := bsNone;
  ScrollRight.HorzScrollBar.Visible := False;
  ScrollRight.AutoScroll        := True;
  { padding removed - use BorderSpacing on children }

  // Left column
  PnlLeft := MakePanel(PnlColumns, CLR_BG, 0);
  PnlLeft.Align := alClient;

  ScrollLeft := TScrollBox.Create(Self);
  ScrollLeft.Parent            := PnlLeft;
  ScrollLeft.Align             := alClient;
  ScrollLeft.Color             := CLR_BG;
  ScrollLeft.BorderStyle       := bsNone;
  ScrollLeft.HorzScrollBar.Visible := False;
  ScrollLeft.AutoScroll        := True;
  { padding removed - use BorderSpacing on children }

  // ── LEFT: Description ──────────────────────────────────────────────────
  PnlDescHeader := MakePanel(ScrollLeft, CLR_BG, 28);
  PnlDescHeader.Align := alTop;
  PnlDescHeader.BorderSpacing.Top := 4;

  Lbl := MakeLabel(PnlDescHeader, 'Descrição', 11, True, CLR_TEXT);
  Lbl.Align  := alLeft;
  Lbl.Layout := tlCenter;

  with TSpeedButton.Create(Self) do
  begin
    Parent    := PnlDescHeader;
    Align     := alLeft;
    Width     := 28;
    Caption   := ' ✎';
    Flat      := True;
    Font.Color:= CLR_MUTE;
    OnClick   := @BtnEditDescClick;
  end;


  // Display (read-only)
  LblDescDisplay := TMemo.Create(Self);
  LblDescDisplay.Parent      := ScrollLeft;
  LblDescDisplay.Align       := alTop;
  LblDescDisplay.Height      := 80;
  LblDescDisplay.ReadOnly    := True;
  LblDescDisplay.ScrollBars  := ssNone;
  LblDescDisplay.WordWrap    := True;
  LblDescDisplay.Color       := CLR_BG;
  LblDescDisplay.Font.Color  := CLR_MUTE;
  LblDescDisplay.Font.Name   := 'Segoe UI';
  LblDescDisplay.Font.Size   := 10;
  LblDescDisplay.Font.Style  := [fsItalic];
  LblDescDisplay.BorderStyle := bsNone;
  LblDescDisplay.Text        := 'Nenhuma descrição fornecida.';
  LblDescDisplay.OnClick     := @BtnEditDescClick;

  // Edit area
  MemoDesc := TMemo.Create(Self);
  MemoDesc.Parent     := ScrollLeft;
  MemoDesc.Align      := alTop;
  MemoDesc.Height     := 160;
  MemoDesc.WordWrap   := True;
  MemoDesc.ScrollBars := ssVertical;
  MemoDesc.Color      := CLR_CARD;
  MemoDesc.Font.Color := CLR_TEXT;
  MemoDesc.Font.Name  := 'Segoe UI';
  MemoDesc.Font.Size  := 10;
  MemoDesc.Visible    := False;
  MemoDesc.BorderSpacing.Top := 4;

  PnlDescActions := MakePanel(ScrollLeft, CLR_BG, 34);
  PnlDescActions.Align   := alTop;
  PnlDescActions.Visible := False;

  BtnSaveDesc := MakeButton(PnlDescActions, '✓ Salvar', CLR_PRIM, clWhite);
  BtnSaveDesc.Align   := alLeft;
  BtnSaveDesc.Width   := 90;
  BtnSaveDesc.OnClick := @BtnSaveDescClick;

  BtnCancelDesc := MakeButton(PnlDescActions, 'Cancelar', CLR_CARD, CLR_MUTE);
  BtnCancelDesc.Align   := alLeft;
  BtnCancelDesc.Width   := 90;
  BtnCancelDesc.OnClick := @BtnCancelDescClick;

  // ── LEFT: Comments ─────────────────────────────────────────────────────
  MakeSepLabel(ScrollLeft, 'Observações e Comentários').Font.Color := CLR_TEXT;

  P := MakePanel(ScrollLeft, CLR_BG, 34);
  P.Align := alTop;

  EdtComment := TEdit.Create(Self);
  EdtComment.Parent    := P;
  EdtComment.Align     := alClient;
  EdtComment.TextHint  := 'Escreva uma observação...';
  EdtComment.Color     := CLR_CARD;
  EdtComment.Font.Color:= CLR_TEXT;
  EdtComment.Font.Name := 'Segoe UI';
  EdtComment.Font.Size := 10;

  BtnSendComment := TSpeedButton.Create(Self);
  BtnSendComment.Parent    := P;
  BtnSendComment.Align     := alRight;
  BtnSendComment.Width     := 40;
  BtnSendComment.Caption   := '▶';
  BtnSendComment.Flat      := True;
  BtnSendComment.Color     := CLR_PRIM;
  BtnSendComment.Font.Color:= clWhite;
  BtnSendComment.Font.Size := 12;
  BtnSendComment.OnClick   := @BtnSendCommentClick;

  PnlCommentList := MakePanel(ScrollLeft, CLR_BG, 8);
  PnlCommentList.Align    := alTop;
  PnlCommentList.AutoSize := True;

  // ── RIGHT: Assignees ───────────────────────────────────────────────────
  P := MakePanel(ScrollRight, CLR_BG, 28);
  P.Align := alTop;

  Lbl := MakeLabel(P, 'Responsáveis', 10, True, CLR_MUTE);
  Lbl.Align  := alLeft;
  Lbl.Layout := tlCenter;

  with TSpeedButton.Create(Self) do
  begin
    Parent    := P;
    Align     := alRight;
    Width     := 28;
    Caption   := '+';
    Flat      := True;
    Font.Color:= CLR_PRIM;
    Font.Size := 14;
    Font.Style:= [fsBold];
    OnClick   := @BtnAddAssigneeClick;
  end;

  CboAssignees := TComboBox.Create(Self);
  CboAssignees.Parent    := ScrollRight;
  CboAssignees.Align     := alTop;
  CboAssignees.Height    := 28;
  CboAssignees.Style     := csDropDownList;
  CboAssignees.Color     := CLR_CARD;
  CboAssignees.Font.Color:= CLR_TEXT;
  CboAssignees.Font.Name := 'Segoe UI';
  CboAssignees.Visible   := False;
  CboAssignees.OnChange  := @CboAssigneesChange;

  PnlAssigneeList := MakePanel(ScrollRight, CLR_BG, 8);
  PnlAssigneeList.Align    := alTop;
  PnlAssigneeList.AutoSize := True;

  // ── RIGHT: Attachments ──────────────────────────────────────────────────
  MakeSepLabel(ScrollRight, 'Anexos e Vídeos');

  PnlAttachList := MakePanel(ScrollRight, CLR_BG, 8);
  PnlAttachList.Align    := alTop;
  PnlAttachList.AutoSize := True;

  // ── RIGHT: Actions ──────────────────────────────────────────────────────
  MakeSepLabel(ScrollRight, 'Ações');

  with MakeButton(ScrollRight, '📎  Anexar Arquivo (.pdf, .docx, .txt...)', CLR_PRIM, clWhite) do
  begin
    Align := alTop;
    BorderSpacing.Bottom := 4;
  end;

  with MakeButton(ScrollRight, '💬  Compartilhar no QAP', CLR_OK, clWhite) do
  begin
    Align := alTop;
    BorderSpacing.Bottom := 4;
  end;

  BtnScheduleAI := MakeButton(ScrollRight, '⚙  Agendar Tarefa IA', CLR_PRIM, clWhite);
  BtnScheduleAI.Align := alTop;
  BtnScheduleAI.BorderSpacing.Bottom := 4;
  BtnScheduleAI.OnClick := @BtnScheduleAIClick;

  // AI schedule sub-panel
  PnlScheduleAI := MakePanel(ScrollRight, CLR_CARD, 0);
  PnlScheduleAI.Align    := alTop;
  PnlScheduleAI.AutoSize := True;
  PnlScheduleAI.Visible  := False;
  { padding removed - use BorderSpacing on children }
  PnlScheduleAI.BorderSpacing.Bottom := 6;

  MakeLabel(PnlScheduleAI, 'Modelo de IA', 9, True, CLR_MUTE).Align := alTop;

  CboAIModel := TComboBox.Create(Self);
  CboAIModel.Parent    := PnlScheduleAI;
  CboAIModel.Align     := alTop;
  CboAIModel.Height    := 26;
  CboAIModel.Style     := csDropDownList;
  CboAIModel.Color     := CLR_BG;
  CboAIModel.Font.Color:= CLR_TEXT;
  CboAIModel.Font.Name := 'Segoe UI';
  CboAIModel.Items.Add('GPT-4o');
  CboAIModel.Items.Add('Claude 3.5 Sonnet');
  CboAIModel.Items.Add('Claude 3 Opus');
  CboAIModel.Items.Add('Gemini 1.5 Pro');
  CboAIModel.Items.Add('Llama 3 70B');
  CboAIModel.ItemIndex := 0;

  with MakeLabel(PnlScheduleAI, 'Data e Hora (AAAA-MM-DD HH:MM)', 9, True, CLR_MUTE) do
  begin
    Align := alTop;
    BorderSpacing.Top := 6;
  end;

  EdtAIDate := TEdit.Create(Self);
  EdtAIDate.Parent    := PnlScheduleAI;
  EdtAIDate.Align     := alTop;
  EdtAIDate.Height    := 26;
  EdtAIDate.TextHint  := 'AAAA-MM-DD HH:MM';
  EdtAIDate.Color     := CLR_BG;
  EdtAIDate.Font.Color:= CLR_TEXT;
  EdtAIDate.Font.Name := 'Segoe UI';

  with MakeButton(PnlScheduleAI, 'Salvar Agendamento', CLR_PRIM, clWhite) do
  begin
    Align := alTop;
    BorderSpacing.Top := 6;
    OnClick := @BtnSaveScheduleClick;
  end;

  // ── RIGHT: Move Board ──────────────────────────────────────────────────
  MakeSepLabel(ScrollRight, 'Mover para outro Board');

  with MakeButton(ScrollRight, 'Escolher Board', CLR_PRIM, clWhite) do
  begin
    Align := alTop;
    BorderSpacing.Bottom := 4;
    OnClick := @BtnChooseBoardClick;
  end;

  CboMoveBoard := TComboBox.Create(Self);
  CboMoveBoard.Parent    := ScrollRight;
  CboMoveBoard.Align     := alTop;
  CboMoveBoard.Height    := 26;
  CboMoveBoard.Style     := csDropDownList;
  CboMoveBoard.Color     := CLR_CARD;
  CboMoveBoard.Font.Color:= CLR_TEXT;
  CboMoveBoard.Font.Name := 'Segoe UI';
  CboMoveBoard.Visible   := False;

  // ── RIGHT: Copy Board ──────────────────────────────────────────────────
  MakeSepLabel(ScrollRight, 'Copiar para outro Board');

  with MakeButton(ScrollRight, 'Copiar Card', CLR_PRIM, clWhite) do
  begin
    Align := alTop;
    BorderSpacing.Bottom := 4;
    OnClick := @BtnCopyCardClick;
  end;

  CboCopyBoard := TComboBox.Create(Self);
  CboCopyBoard.Parent    := ScrollRight;
  CboCopyBoard.Align     := alTop;
  CboCopyBoard.Height    := 26;
  CboCopyBoard.Style     := csDropDownList;
  CboCopyBoard.Color     := CLR_CARD;
  CboCopyBoard.Font.Color:= CLR_TEXT;
  CboCopyBoard.Font.Name := 'Segoe UI';
  CboCopyBoard.Visible   := False;

  // ── RIGHT: Related ─────────────────────────────────────────────────────
  MakeSepLabel(ScrollRight, 'Tarefas Relacionadas');

  P := MakePanel(ScrollRight, CLR_BG, 30);
  P.Align := alTop;
  P.BorderSpacing.Bottom := 4;

  EdtRelated := TEdit.Create(Self);
  EdtRelated.Parent    := P;
  EdtRelated.Align     := alClient;
  EdtRelated.TextHint  := '#TicketID';
  EdtRelated.Color     := CLR_CARD;
  EdtRelated.Font.Color:= CLR_TEXT;
  EdtRelated.Font.Name := 'Segoe UI';

  with TSpeedButton.Create(Self) do
  begin
    Parent    := P;
    Align     := alRight;
    Width     := 32;
    Caption   := '🔗';
    Flat      := True;
    Font.Color:= CLR_PRIM;
    OnClick   := @BtnLinkCardClick;
  end;

  PnlRelatedList := MakePanel(ScrollRight, CLR_BG, 8);
  PnlRelatedList.Align    := alTop;
  PnlRelatedList.AutoSize := True;
  PnlRelatedList.BorderSpacing.Bottom := 4;

  // ── RIGHT: Activities ──────────────────────────────────────────────────
  MakeSepLabel(ScrollRight, 'Atividades');

  ScrollActivity := TScrollBox.Create(Self);
  ScrollActivity.Parent       := ScrollRight;
  ScrollActivity.Align        := alTop;
  ScrollActivity.Height       := 220;
  ScrollActivity.Color        := $0D0D1E;
  ScrollActivity.BorderStyle  := bsSingle;
  ScrollActivity.HorzScrollBar.Visible := False;
  ScrollActivity.AutoScroll   := True;
  { padding removed - use BorderSpacing on children }

  PnlActivityLog := MakePanel(ScrollActivity, $0D0D1E, 8);
  PnlActivityLog.Align    := alTop;
  PnlActivityLog.AutoSize := True;
end;

// ===========================================================================
// FormCreate / Destroy / KeyDown / Show
// ===========================================================================

procedure TFormTaskDetail.FormCreate(Sender: TObject);
begin
  FCardID          := 0;
  FBoardID         := 0;
  FListID          := 0;
  FListTitle       := '';
  FEditingDesc     := False;
  FShowScheduleAI  := False;
  FShowAddAssignee := False;
  Width  := 1100;
  Height := 750;
  BuildUI;
end;

procedure TFormTaskDetail.FormDestroy(Sender: TObject);
begin
  // nothing
end;

procedure TFormTaskDetail.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then Close;
end;

procedure TFormTaskDetail.FormShow(Sender: TObject);
begin
  if FCardID > 0 then
  begin
    try LoadCardData; except on E: Exception do begin ShowMessage('Erro em LoadCardData: ' + E.Message); raise; end; end;
    try LoadAllUsers; except on E: Exception do begin ShowMessage('Erro em LoadAllUsers: ' + E.Message); raise; end; end;
    try LoadAssignees; except on E: Exception do begin ShowMessage('Erro em LoadAssignees: ' + E.Message); raise; end; end;
    try LoadComments; except on E: Exception do begin ShowMessage('Erro em LoadComments: ' + E.Message); raise; end; end;
    try LoadAttachments; except on E: Exception do begin ShowMessage('Erro em LoadAttachments: ' + E.Message); raise; end; end;
    try LoadRelatedCards; except on E: Exception do begin ShowMessage('Erro em LoadRelatedCards: ' + E.Message); raise; end; end;
    try LoadActivities; except on E: Exception do begin ShowMessage('Erro em LoadActivities: ' + E.Message); raise; end; end;
    try LoadTimeBar; except on E: Exception do begin ShowMessage('Erro em LoadTimeBar: ' + E.Message); raise; end; end;
    try LoadBoards; except on E: Exception do begin ShowMessage('Erro em LoadBoards: ' + E.Message); raise; end; end;
    try LoadSchedules; except on E: Exception do begin ShowMessage('Erro em LoadSchedules: ' + E.Message); raise; end; end;
  end;
end;

// ===========================================================================
// LoadCard (public entry point)
// ===========================================================================

procedure TFormTaskDetail.LoadCard(ACardID: Integer);
begin
  FCardID := ACardID;
  Caption := 'Detalhamento da Tarefa';
  ShowModal;
end;

// ===========================================================================
// Data loaders
// ===========================================================================

procedure TFormTaskDetail.LoadCardData;
var
  Q: TIBQuery;
  I, PrIdx: Integer;
  Desc: string;
begin
  if FCardID = 0 then Exit;
  Q := RunQuery(
    'SELECT c.ID, c.TITLE, c.DESCRIPTION, c.PRIORITY, c.TICKETID, ' +
    '       c.CREATEDAT, c.CREATORID, c.LISTID, ' +
    '       u.USERNAME AS CNAME, ' +
    '       l.TITLE AS LTITLE, l.BOARDID ' +
    'FROM "Card" c ' +
    'LEFT JOIN "User" u ON u.ID = c.CREATORID ' +
    'LEFT JOIN "List" l ON l.ID = c.LISTID ' +
    'WHERE c.ID = :CID',
    ['CID'], [FCardID]);
  try
    if Q.Eof then Exit;

    LblTitle.Caption := Q.FieldByName('TITLE').AsString;
    EdtTitle.Text    := Q.FieldByName('TITLE').AsString;
    FListID    := Q.FieldByName('LISTID').AsInteger;
    FListTitle := Q.FieldByName('LTITLE').AsString;
    FBoardID   := Q.FieldByName('BOARDID').AsInteger;
    Caption    := Q.FieldByName('TICKETID').AsString + ' — ' +
                  Q.FieldByName('TITLE').AsString;

    // Show current list
    if FListTitle <> '' then
      LblListStatus.Caption := '▶  ' + FListTitle
    else
      LblListStatus.Caption := '';

    if not Q.FieldByName('CNAME').IsNull then
      LblCreator.Caption := 'Criado por ' + Q.FieldByName('CNAME').AsString + ' em ' +
        FormatDateTime('dd/mm/yyyy', Q.FieldByName('CREATEDAT').AsDateTime)
    else
      LblCreator.Caption := 'Criado em ' +
        FormatDateTime('dd/mm/yyyy', Q.FieldByName('CREATEDAT').AsDateTime);

    // Priority
    PrIdx := 0;
    for I := 0 to High(PRIORITIES) do
      if SameText(PRIORITIES[I], Q.FieldByName('PRIORITY').AsString) then
      begin
        PrIdx := I;
        Break;
      end;
    CboPriority.OnChange := nil;        // evita OnChange durante carga
    CboPriority.ItemIndex := PrIdx;
    CboPriority.OnChange := @CboPriorityChange;
    UpdatePriorityColor;

    // Description
    Desc := '';
    if not Q.FieldByName('DESCRIPTION').IsNull then
      Desc := Trim(Q.FieldByName('DESCRIPTION').AsString);
    if Desc <> '' then
    begin
      LblDescDisplay.Text       := Desc;
      LblDescDisplay.Font.Style := [];
      LblDescDisplay.Font.Color := CLR_TEXT;
      MemoDesc.Text             := Desc;
    end
    else
    begin
      LblDescDisplay.Text       := 'Nenhuma descrição fornecida.';
      LblDescDisplay.Font.Style := [fsItalic];
      LblDescDisplay.Font.Color := CLR_MUTE;
      MemoDesc.Text             := '';
    end;
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------

procedure TFormTaskDetail.LoadAllUsers;
var Q: TIBQuery;
begin
  CboAssignees.Items.Clear;
  CboAssignees.Items.Add('-- Selecione um responsável --');
  Q := RunQuery('SELECT ID, USERNAME FROM "User" ORDER BY USERNAME', [], []);
  try
    while not Q.Eof do
    begin
      CboAssignees.Items.AddObject(
        Q.FieldByName('USERNAME').AsString,
        TObject(PtrInt(Q.FieldByName('ID').AsInteger)));
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  CboAssignees.ItemIndex := 0;
end;

// ---------------------------------------------------------------------------

procedure TFormTaskDetail.LoadAssignees;
begin
  BuildAssigneeChips;
end;

procedure TFormTaskDetail.BuildAssigneeChips;
var
  Q: TIBQuery;
  Chip, Av: TPanel;
  Lbl: TLabel;
  Btn: TSpeedButton;
begin
  ClearPanel(PnlAssigneeList);
  PnlAssigneeList.AutoSize := True;

  Q := RunQuery(
    'SELECT u.ID, u.USERNAME FROM "User" u ' +
    'JOIN "_CardAssignees" ca ON ca.B = u.ID ' +
    'WHERE ca.A = :CID ORDER BY u.USERNAME',
    ['CID'], [FCardID]);
  try
    if Q.Eof then
    begin
      Lbl := MakeLabel(PnlAssigneeList, 'Ninguém atribuído', 9, False, CLR_MUTE);
      Lbl.Align := alTop;
      Lbl.BorderSpacing.Top := 4;
      Exit;
    end;
    while not Q.Eof do
    begin
      Chip := MakePanel(PnlAssigneeList, $3A3A5C, 30);
      Chip.Align := alTop;
      Chip.Tag   := Q.FieldByName('ID').AsInteger;
      Chip.BorderSpacing.Bottom := 4;

      Av := MakePanel(Chip, CLR_PRIM, 0);
      Av.Align  := alLeft;
      Av.Width  := 30;

      Lbl := MakeLabel(Av, FirstLetter(Q.FieldByName('USERNAME').AsString), 11, True, clWhite);
      Lbl.Align     := alClient;
      Lbl.Alignment := taCenter;
      Lbl.Layout    := tlCenter;

      Lbl := MakeLabel(Chip, Q.FieldByName('USERNAME').AsString, 9, False, CLR_TEXT);
      Lbl.Align  := alClient;
      Lbl.Layout := tlCenter;

      Btn := TSpeedButton.Create(Self);
      Btn.Parent    := Chip;
      Btn.Align     := alRight;
      Btn.Width     := 26;
      Btn.Caption   := '✕';
      Btn.Flat      := True;
      Btn.Font.Color:= CLR_MUTE;
      Btn.Tag       := Q.FieldByName('ID').AsInteger;
      Btn.OnClick   := @RemoveAssigneeClick;

      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------

procedure TFormTaskDetail.LoadComments;
begin
  BuildCommentItems;
end;

procedure TFormTaskDetail.BuildCommentItems;
var
  Q: TIBQuery;
  Item, Av: TPanel;
  LblU, LblD, LblC: TLabel;
  Lbl: TLabel;
  Works: Boolean;
begin
  ClearPanel(PnlCommentList);
  PnlCommentList.AutoSize := True;

  Q := RunQuery(
    'SELECT cm.ID, cm.CONTENT, CASE WHEN cm.WORKS = TRUE THEN 1 ELSE 0 END AS WORKS, cm.CREATEDAT, u.USERNAME ' +
    'FROM "Comment" cm ' +
    'LEFT JOIN "User" u ON u.ID = cm.USERID ' +
    'WHERE cm.CARDID = :CID ORDER BY cm.CREATEDAT DESC',
    ['CID'], [FCardID]);
  try
    if Q.Eof then
    begin
      Lbl := MakeLabel(PnlCommentList, 'Nenhuma observação ainda.', 10, False, CLR_MUTE);
      Lbl.Align      := alTop;
      Lbl.Font.Style := [fsItalic];
      Lbl.BorderSpacing.Top := 8;
      Exit;
    end;
    while not Q.Eof do
    begin
      Works := Q.FieldByName('WORKS').AsBoolean;

      Item := MakePanel(PnlCommentList,
        IfThen(Works, $051F05, CLR_CARD), 0);
      Item.Align    := alTop;
      Item.AutoSize := True;
      Item.BorderSpacing.Bottom := 6;
      { padding removed - use BorderSpacing on children }
      { padding removed - use BorderSpacing on children }
      { padding removed - use BorderSpacing on children }
      { padding removed - use BorderSpacing on children }

      Av := MakePanel(Item, CLR_PRIM, 0);
      Av.Align  := alLeft;
      Av.Width  := 30;

      Lbl := MakeLabel(Av, FirstLetter(Q.FieldByName('USERNAME').AsString), 11, True, clWhite);
      Lbl.Align     := alTop;
      Lbl.Alignment := taCenter;
      Lbl.Height    := 30;

      // Right side
      if Works then
      begin
        LblU := MakeLabel(Item, Q.FieldByName('USERNAME').AsString + ' ✓', 9, True, CLR_OK);
      end
      else
      begin
        LblU := MakeLabel(Item, Q.FieldByName('USERNAME').AsString, 9, True, CLR_TEXT);
      end;
      LblU.Align := alTop;
      LblU.BorderSpacing.Left := 38;

      LblD := MakeLabel(Item,
        FormatDateTime('dd/mm/yyyy hh:nn', Q.FieldByName('CREATEDAT').AsDateTime),
        8, False, CLR_MUTE);
      LblD.Align := alTop;
      LblD.BorderSpacing.Left := 38;

      LblC := MakeLabel(Item, Q.FieldByName('CONTENT').AsString, 10, False, CLR_TEXT);
      LblC.Align    := alTop;
      LblC.WordWrap := True;
      LblC.AutoSize := True;
      LblC.BorderSpacing.Left := 38;
      LblC.BorderSpacing.Top  := 2;

      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------

procedure TFormTaskDetail.LoadAttachments;
begin
  BuildAttachmentItems;
end;

procedure TFormTaskDetail.BuildAttachmentItems;
var
  Q: TIBQuery;
  Item: TPanel;
  LblN, LblI: TLabel;
  Btn: TSpeedButton;
  Lbl: TLabel;
begin
  ClearPanel(PnlAttachList);
  PnlAttachList.AutoSize := True;

  Q := RunQuery(
    'SELECT ID, FILENAME, URL, "SIZE", CREATEDAT FROM "Attachment" ' +
    'WHERE CARDID = :CID ORDER BY CREATEDAT DESC',
    ['CID'], [FCardID]);
  try
    if Q.Eof then
    begin
      Lbl := MakeLabel(PnlAttachList, 'Nenhum anexo', 9, False, CLR_MUTE);
      Lbl.Align      := alTop;
      Lbl.Font.Style := [fsItalic];
      Exit;
    end;
    while not Q.Eof do
    begin
      Item := MakePanel(PnlAttachList, CLR_CARD, 44);
      Item.Align := alTop;
      Item.BorderSpacing.Bottom := 4;
      { padding removed - use BorderSpacing on children }
      Item.Tag := Q.FieldByName('ID').AsInteger;

      LblN := MakeLabel(Item, Q.FieldByName('FILENAME').AsString, 9, True, CLR_TEXT);
      LblN.Align := alTop;

      LblI := MakeLabel(Item,
        FormatFloat('0.0', Q.FieldByName('SIZE').AsInteger / 1024) + ' KB  •  ' +
        FormatDateTime('dd/mm/yyyy', Q.FieldByName('CREATEDAT').AsDateTime),
        8, False, CLR_MUTE);
      LblI.Align := alTop;

      Btn := TSpeedButton.Create(Self);
      Btn.Parent    := Item;
      Btn.Align     := alRight;
      Btn.Width     := 28;
      Btn.Caption   := '↗';
      Btn.Flat      := True;
      Btn.Font.Color:= CLR_PRIM;
      Btn.Tag       := Q.FieldByName('ID').AsInteger;
      Btn.Hint      := Q.FieldByName('URL').AsString;
      Btn.ShowHint  := True;
      Btn.OnClick   := @OpenAttachmentClick;

      Btn := TSpeedButton.Create(Self);
      Btn.Parent    := Item;
      Btn.Align     := alRight;
      Btn.Width     := 28;
      Btn.Caption   := '🗑';
      Btn.Flat      := True;
      Btn.Font.Color:= $4444FF;
      Btn.Tag       := Q.FieldByName('ID').AsInteger;
      Btn.OnClick   := @DeleteAttachmentClick;

      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------

procedure TFormTaskDetail.LoadRelatedCards;
begin
  BuildRelatedItems;
end;

procedure TFormTaskDetail.BuildRelatedItems;
var
  Q: TIBQuery;
  Item: TPanel;
  LblT, LblN: TLabel;
  Btn: TSpeedButton;
  Lbl: TLabel;
begin
  ClearPanel(PnlRelatedList);
  PnlRelatedList.AutoSize := True;

  Q := RunQuery(
    'SELECT c.ID, c.TITLE, c.TICKETID FROM "Card" c ' +
    'WHERE c.ID IN (' +
    '  SELECT B FROM "_CardRelations" WHERE A = :CID ' +
    '  UNION ' +
    '  SELECT A FROM "_CardRelations" WHERE B = :CID ' +
    ')',
    ['CID'], [FCardID]);
  try
    if Q.Eof then
    begin
      Lbl := MakeLabel(PnlRelatedList, 'Nenhuma vinculada.', 9, False, CLR_MUTE);
      Lbl.Align      := alTop;
      Lbl.Alignment  := taCenter;
      Lbl.Font.Style := [fsItalic];
      Lbl.BorderSpacing.Top := 4;
      Exit;
    end;
    while not Q.Eof do
    begin
      Item := MakePanel(PnlRelatedList, CLR_CARD, 44);
      Item.Align := alTop;
      Item.BorderSpacing.Bottom := 4;
      { padding removed - use BorderSpacing on children }
      Item.Tag := Q.FieldByName('ID').AsInteger;

      LblT := MakeLabel(Item, Q.FieldByName('TICKETID').AsString, 9, True, CLR_PRIM);
      LblT.Align := alTop;

      LblN := MakeLabel(Item, Q.FieldByName('TITLE').AsString, 9, False, CLR_TEXT);
      LblN.Align    := alTop;
      LblN.WordWrap := True;
      LblN.AutoSize := True;

      Btn := TSpeedButton.Create(Self);
      Btn.Parent    := Item;
      Btn.Align     := alRight;
      Btn.Width     := 28;
      Btn.Caption   := '✕';
      Btn.Flat      := True;
      Btn.Font.Color:= $4444FF;
      Btn.Tag       := Q.FieldByName('ID').AsInteger;
      Btn.OnClick   := @UnlinkCardClick;

      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------

procedure TFormTaskDetail.LoadActivities;
begin
  BuildActivityItems;
end;

procedure TFormTaskDetail.BuildActivityItems;
var
  Q: TIBQuery;
  Item: TPanel;
  L1, L2, L3: TLabel;
  Lbl: TLabel;
begin
  ClearPanel(PnlActivityLog);
  PnlActivityLog.AutoSize := True;

  Q := RunQuery(
    'SELECT cm.ID, cm.CREATEDAT, ' +
    '       lt.TITLE AS TO_TITLE, u.USERNAME ' +
    'FROM "CardMovement" cm ' +
    'LEFT JOIN "List" lt ON lt.ID = cm.TOLISTID ' +
    'LEFT JOIN "User" u  ON u.ID  = cm.USERID ' +
    'WHERE cm.CARDID = :CID ORDER BY cm.CREATEDAT DESC',
    ['CID'], [FCardID]);
  try
    if Q.Eof then
    begin
      Lbl := MakeLabel(PnlActivityLog, 'Nenhuma atividade recente.', 9, False, CLR_MUTE);
      Lbl.Align     := alTop;
      Lbl.Alignment := taCenter;
      Lbl.BorderSpacing.Top := 8;
      Exit;
    end;
    while not Q.Eof do
    begin
      Item := MakePanel(PnlActivityLog, $0D0D1E, 0);
      Item.Align    := alTop;
      Item.AutoSize := True;
      Item.BorderSpacing.Bottom := 8;
      { padding removed - use BorderSpacing on children }

      L1 := MakeLabel(Item, Q.FieldByName('TO_TITLE').AsString, 9, True, CLR_TEXT);
      L1.Align := alTop;

      L2 := MakeLabel(Item,
        FormatDateTime('dd/mm/yyyy hh:nn:ss', Q.FieldByName('CREATEDAT').AsDateTime),
        8, False, CLR_MUTE);
      L2.Align := alTop;

      L3 := MakeLabel(Item, Q.FieldByName('USERNAME').AsString, 8, False, CLR_MUTE);
      L3.Align      := alTop;
      L3.Font.Style := [fsItalic];

      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

// ---------------------------------------------------------------------------

procedure TFormTaskDetail.LoadTimeBar;
var
  Q: TIBQuery;
  Chip: TPanel;
  Lbl: TLabel;
  CreatedAt, PrevTS, Now_: TDateTime;
  ListName, TStr: string;
begin
  ClearPanel(PnlTimeChips);

  Now_ := SysUtils.Now;

  Q := RunQuery('SELECT CREATEDAT FROM "Card" WHERE ID = :CID', ['CID'], [FCardID]);
  try
    if Q.Eof then Exit;
    CreatedAt := Q.FieldByName('CREATEDAT').AsDateTime;
  finally
    Q.Free;
  end;

  PrevTS   := CreatedAt;
  ListName := FListTitle;

  Q := RunQuery(
    'SELECT cm.CREATEDAT, lt.TITLE AS TO_TITLE ' +
    'FROM "CardMovement" cm ' +
    'JOIN "List" lt ON lt.ID = cm.TOLISTID ' +
    'WHERE cm.CARDID = :CID ORDER BY cm.CREATEDAT ASC',
    ['CID'], [FCardID]);
  try
    while not Q.Eof do
    begin
      TStr := FormatDuration(PrevTS, Q.FieldByName('CREATEDAT').AsDateTime);

      Chip := MakePanel(PnlTimeChips, CLR_CARD, 22);
      Chip.Align := alLeft;
      Chip.Width := Max(80, (Length(ListName) + Length(TStr) + 3) * 7);
      Chip.Top   := 4;
      Chip.BorderSpacing.Right := 6;

      Lbl := MakeLabel(Chip, ListName + ': ' + TStr, 8, True, CLR_MUTE);
      Lbl.Align     := alClient;
      Lbl.Alignment := taCenter;
      Lbl.Layout    := tlCenter;

      ListName := Q.FieldByName('TO_TITLE').AsString;
      PrevTS   := Q.FieldByName('CREATEDAT').AsDateTime;
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  // Current stage chip (green)
  TStr := FormatDuration(PrevTS, Now_);
  Chip := MakePanel(PnlTimeChips, $2F4027, 22);
  Chip.Align := alLeft;
  Chip.Width := Max(80, (Length(ListName) + Length(TStr) + 3) * 7);
  Chip.Top   := 4;
  Chip.BorderSpacing.Right := 6;
  Lbl := MakeLabel(Chip, ListName + ': ' + TStr, 8, True, $71CC4A);
  Lbl.Align     := alClient;
  Lbl.Alignment := taCenter;
  Lbl.Layout    := tlCenter;

  // Total chip
  TStr := FormatDuration(CreatedAt, Now_);
  Chip := MakePanel(PnlTimeChips, CLR_PRIM, 22);
  Chip.Align := alLeft;
  Chip.Width := Max(70, (7 + Length(TStr)) * 7);
  Chip.Top   := 4;
  Lbl := MakeLabel(Chip, 'Total: ' + TStr, 8, True, clWhite);
  Lbl.Align     := alClient;
  Lbl.Alignment := taCenter;
  Lbl.Layout    := tlCenter;
end;

// ---------------------------------------------------------------------------

procedure TFormTaskDetail.LoadBoards;
var Q: TIBQuery;
begin
  CboMoveBoard.Items.Clear;
  CboCopyBoard.Items.Clear;
  CboMoveBoard.Items.Add('-- Selecione um board --');
  CboCopyBoard.Items.Add('-- Selecione um board --');

  Q := RunQuery('SELECT ID, TITLE FROM "Board" WHERE ID <> :BID ORDER BY TITLE',
                ['BID'], [FBoardID]);
  try
    while not Q.Eof do
    begin
      CboMoveBoard.Items.AddObject(Q.FieldByName('TITLE').AsString,
        TObject(PtrInt(Q.FieldByName('ID').AsInteger)));
      CboCopyBoard.Items.AddObject(Q.FieldByName('TITLE').AsString,
        TObject(PtrInt(Q.FieldByName('ID').AsInteger)));
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  CboMoveBoard.ItemIndex := 0;
  CboCopyBoard.ItemIndex := 0;
end;

// ---------------------------------------------------------------------------

procedure TFormTaskDetail.LoadSchedules;
var
  Q: TIBQuery;
  TicketID: string;
  Item: TPanel;
  L1, L2: TLabel;
  Notified: Boolean;
begin
  Q := RunQuery('SELECT TICKETID FROM "Card" WHERE ID = :CID', ['CID'], [FCardID]);
  try
    if Q.Eof then Exit;
    TicketID := Q.FieldByName('TICKETID').AsString;
  finally
    Q.Free;
  end;

  if TicketID = '' then Exit;

  Q := RunQuery(
    'SELECT ID, MODEL_NAME, SCHEDULED_AT, CASE WHEN IS_NOTIFIED = TRUE THEN 1 ELSE 0 END AS IS_NOTIFIED FROM "ModelSchedule" ' +
    'WHERE TICKET_ID = :TID ORDER BY SCHEDULED_AT',
    ['TID'], [TicketID]);
  try
    while not Q.Eof do
    begin
      Notified := Q.FieldByName('IS_NOTIFIED').AsBoolean;

      Item := MakePanel(ScrollRight, CLR_CARD, 0);
      Item.Align    := alTop;
      Item.AutoSize := True;
      Item.BorderSpacing.Bottom := 4;
      { padding removed - use BorderSpacing on children }

      L1 := MakeLabel(Item, Q.FieldByName('MODEL_NAME').AsString, 9, True, clWhite);
      L1.Align := alTop;

      if Notified then
        L2 := MakeLabel(Item,
          FormatDateTime('dd/mm/yyyy hh:nn', Q.FieldByName('SCHEDULED_AT').AsDateTime) + '  ✓ Notificado',
          8, False, CLR_OK)
      else
        L2 := MakeLabel(Item,
          FormatDateTime('dd/mm/yyyy hh:nn', Q.FieldByName('SCHEDULED_AT').AsDateTime) + '  Aguardando',
          8, False, $15FACC);
      L2.Align := alTop;

      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

// ===========================================================================
// Event handlers
// ===========================================================================

procedure TFormTaskDetail.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFormTaskDetail.BtnEditTitleClick(Sender: TObject);
begin
  ShowTitleEdit(True);
  EdtTitle.SetFocus;
end;

procedure TFormTaskDetail.BtnSaveTitleClick(Sender: TObject);
var S: string;
begin
  S := Trim(EdtTitle.Text);
  if S = '' then begin ShowMessage('O título não pode ser vazio.'); Exit; end;
  ExecDB('UPDATE "Card" SET TITLE = :T, UPDATEDAT = CURRENT_TIMESTAMP WHERE ID = :CID',
         ['T', 'CID'], [S, FCardID]);
  LblTitle.Caption := S;
  Caption          := S;
  ShowTitleEdit(False);
end;

procedure TFormTaskDetail.BtnCancelTitleClick(Sender: TObject);
begin
  EdtTitle.Text := LblTitle.Caption;
  ShowTitleEdit(False);
end;

procedure TFormTaskDetail.BtnCopyTitleClick(Sender: TObject);
begin
  Clipboard.AsText := LblTitle.Caption;
  ShowMessage('Título copiado.');
end;

procedure TFormTaskDetail.ShowTitleEdit(AEdit: Boolean);
begin
  LblTitle.Visible      := not AEdit;
  BtnEditTitle.Visible  := not AEdit;
  BtnCopyTitle.Visible  := not AEdit;
  EdtTitle.Visible      := AEdit;
  BtnSaveTitle.Visible  := AEdit;
  BtnCancelTitle.Visible:= AEdit;
end;

procedure TFormTaskDetail.CboPriorityChange(Sender: TObject);
var S: string;
begin
  S := CboPriority.Items[CboPriority.ItemIndex];
  ExecDB('UPDATE "Card" SET PRIORITY = :P, UPDATEDAT = CURRENT_TIMESTAMP WHERE ID = :CID',
         ['P', 'CID'], [S, FCardID]);
  UpdatePriorityColor;
end;

procedure TFormTaskDetail.UpdatePriorityColor;
var S: string;
begin
  S := CboPriority.Items[CboPriority.ItemIndex];
  CboPriority.Color     := PriorityColor(S);
  CboPriority.Font.Color:= PriorityTextColor(S);
end;

procedure TFormTaskDetail.BtnEditDescClick(Sender: TObject);
begin
  ShowDescEdit(True);
  MemoDesc.SetFocus;
end;

procedure TFormTaskDetail.BtnSaveDescClick(Sender: TObject);
var S: string;
begin
  S := MemoDesc.Text;
  ExecDB('UPDATE "Card" SET DESCRIPTION = :D, UPDATEDAT = CURRENT_TIMESTAMP WHERE ID = :CID',
         ['D', 'CID'], [S, FCardID]);
  if Trim(S) <> '' then
  begin
    LblDescDisplay.Text       := S;
    LblDescDisplay.Font.Style := [];
    LblDescDisplay.Font.Color := CLR_TEXT;
  end
  else
  begin
    LblDescDisplay.Text       := 'Nenhuma descrição fornecida.';
    LblDescDisplay.Font.Style := [fsItalic];
    LblDescDisplay.Font.Color := CLR_MUTE;
  end;
  ShowDescEdit(False);
end;

procedure TFormTaskDetail.BtnCancelDescClick(Sender: TObject);
begin
  ShowDescEdit(False);
end;

procedure TFormTaskDetail.ShowDescEdit(AEdit: Boolean);
begin
  FEditingDesc           := AEdit;
  LblDescDisplay.Visible := not AEdit;
  MemoDesc.Visible       := AEdit;
  PnlDescActions.Visible := AEdit;
end;

procedure TFormTaskDetail.BtnSendCommentClick(Sender: TObject);
var Txt: string;
begin
  Txt := Trim(EdtComment.Text);
  if Txt = '' then Exit;
  ExecDB(
    'INSERT INTO "Comment" (CONTENT, CARDID, USERID, WORKS) VALUES (:C, :CID, :UID, FALSE)',
    ['C', 'CID', 'UID'], [Txt, FCardID, LoggedUserID]);
  EdtComment.Text := '';
  BuildCommentItems;
end;

procedure TFormTaskDetail.BtnAddAssigneeClick(Sender: TObject);
begin
  FShowAddAssignee := not FShowAddAssignee;
  CboAssignees.Visible := FShowAddAssignee;
  if FShowAddAssignee then CboAssignees.SetFocus;
end;

procedure TFormTaskDetail.CboAssigneesChange(Sender: TObject);
var
  UID: Integer;
  Q: TIBQuery;
  N: Integer;
begin
  if CboAssignees.ItemIndex <= 0 then Exit;
  UID := PtrInt(CboAssignees.Items.Objects[CboAssignees.ItemIndex]);

  Q := RunQuery(
    'SELECT COUNT(*) FROM "_CardAssignees" WHERE A = :CID AND B = :UID',
    ['CID', 'UID'], [FCardID, UID]);
  N := Q.Fields[0].AsInteger;
  Q.Free;

  if N > 0 then
  begin
    ShowMessage('Este usuário já é responsável por esta tarefa.');
    CboAssignees.ItemIndex := 0;
    Exit;
  end;

  ExecDB('INSERT INTO "_CardAssignees" (A, B) VALUES (:CID, :UID)',
         ['CID', 'UID'], [FCardID, UID]);
  CboAssignees.ItemIndex := 0;
  CboAssignees.Visible   := False;
  FShowAddAssignee       := False;
  BuildAssigneeChips;
end;

procedure TFormTaskDetail.RemoveAssigneeClick(Sender: TObject);
var UID: Integer;
begin
  UID := TComponent(Sender).Tag;
  if MessageDlg('Remover responsável?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ExecDB('DELETE FROM "_CardAssignees" WHERE A = :CID AND B = :UID',
           ['CID', 'UID'], [FCardID, UID]);
    BuildAssigneeChips;
  end;
end;

procedure TFormTaskDetail.DeleteAttachmentClick(Sender: TObject);
var AID: Integer;
begin
  AID := TComponent(Sender).Tag;
  if MessageDlg('Excluir este anexo?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ExecDB('DELETE FROM "Attachment" WHERE ID = :AID', ['AID'], [AID]);
    BuildAttachmentItems;
  end;
end;

procedure TFormTaskDetail.OpenAttachmentClick(Sender: TObject);
begin
  OpenURL(TSpeedButton(Sender).Hint);
end;

procedure TFormTaskDetail.UnlinkCardClick(Sender: TObject);
var RID: Integer;
begin
  RID := TComponent(Sender).Tag;
  if MessageDlg('Desvincular esta tarefa?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ExecDB('DELETE FROM "_CardRelations" WHERE (A=:CID1 AND B=:RID1) OR (B=:CID2 AND A=:RID2)',
           ['CID1', 'RID1', 'CID2', 'RID2'], [FCardID, RID, FCardID, RID]);
    BuildRelatedItems;
  end;
end;

procedure TFormTaskDetail.BtnScheduleAIClick(Sender: TObject);
begin
  FShowScheduleAI := not FShowScheduleAI;
  PnlScheduleAI.Visible := FShowScheduleAI;
  if FShowScheduleAI then
    BtnScheduleAI.Caption := '⚙  Ocultar Opções'
  else
    BtnScheduleAI.Caption := '⚙  Agendar Tarefa IA';
end;

procedure TFormTaskDetail.BtnSaveScheduleClick(Sender: TObject);
var
  Model, DateStr, TicketID: string;
  SchedDT: TDateTime;
  Q: TIBQuery;
begin
  Model   := CboAIModel.Items[CboAIModel.ItemIndex];
  DateStr := Trim(EdtAIDate.Text);
  if DateStr = '' then
  begin
    ShowMessage('Informe a data e hora (AAAA-MM-DD HH:MM).');
    Exit;
  end;
  DateStr := StringReplace(DateStr, 'T', ' ', [rfReplaceAll]);
  try
    SchedDT := StrToDateTime(DateStr);
  except
    ShowMessage('Formato inválido. Use AAAA-MM-DD HH:MM.');
    Exit;
  end;

  Q := RunQuery('SELECT TICKETID, TITLE FROM "Card" WHERE ID = :CID', ['CID'], [FCardID]);
  try
    if Q.Eof then Exit;
    TicketID := Q.FieldByName('TICKETID').AsString;
    ExecDB(
      'INSERT INTO "ModelSchedule" (MODEL_NAME, TICKET_ID, TITLE, SCHEDULED_AT, USER_ID) ' +
      'VALUES (:M, :TID, :TITLE, :SCHED, :UID)',
      ['M', 'TID', 'TITLE', 'SCHED', 'UID'],
      [Model, TicketID, Q.FieldByName('TITLE').AsString, SchedDT, LoggedUserID]);
  finally
    Q.Free;
  end;

  EdtAIDate.Text := '';
  PnlScheduleAI.Visible := False;
  FShowScheduleAI := False;
  BtnScheduleAI.Caption := '⚙  Agendar Tarefa IA';
  ShowMessage('Agendamento criado com sucesso!');
  LoadSchedules;
end;

procedure TFormTaskDetail.BtnChooseBoardClick(Sender: TObject);
begin
  CboMoveBoard.Visible := not CboMoveBoard.Visible;
  if CboMoveBoard.Visible then CboMoveBoard.SetFocus;
end;

procedure TFormTaskDetail.BtnCopyCardClick(Sender: TObject);
begin
  CboCopyBoard.Visible := not CboCopyBoard.Visible;
  if CboCopyBoard.Visible then CboCopyBoard.SetFocus;
end;

procedure TFormTaskDetail.BtnLinkCardClick(Sender: TObject);
var
  TID: string;
  Q: TIBQuery;
  RelID, N: Integer;
begin
  TID := Trim(EdtRelated.Text);
  if TID = '' then begin ShowMessage('Digite o TicketID.'); Exit; end;

  Q := RunQuery('SELECT ID FROM "Card" WHERE TICKETID = :TID', ['TID'], [TID]);
  try
    if Q.Eof then
    begin
      ShowMessage('Tarefa "' + TID + '" não encontrada.');
      Exit;
    end;
    RelID := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;

  if RelID = FCardID then begin ShowMessage('Não pode vincular a si mesma.'); Exit; end;

  Q := RunQuery(
    'SELECT COUNT(*) FROM "_CardRelations" ' +
    'WHERE (A=:CID1 AND B=:RID1) OR (B=:CID2 AND A=:RID2)',
    ['CID1', 'RID1', 'CID2', 'RID2'], [FCardID, RelID, FCardID, RelID]);
  N := Q.Fields[0].AsInteger;
  Q.Free;

  if N > 0 then begin ShowMessage('Já vinculada.'); Exit; end;

  ExecDB('INSERT INTO "_CardRelations" (A, B) VALUES (:CID, :RID)',
         ['CID', 'RID'], [FCardID, RelID]);
  EdtRelated.Text := '';
  BuildRelatedItems;
end;

end.



