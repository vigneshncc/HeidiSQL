unit selectdbobject;

interface

uses
  Windows, Classes, Controls, Forms, StdCtrls, VirtualTrees,
  mysql_connection;

type
  TfrmSelectDBObject = class(TForm)
    TreeDBO: TVirtualStringTree;
    btnOK: TButton;
    btnCancel: TButton;
    lblSelect: TLabel;
    editDB: TEdit;
    editTable: TEdit;
    editCol: TEdit;
    lblDB: TLabel;
    lblTable: TLabel;
    lblCol: TLabel;
    lblHint: TLabel;
    procedure editChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TreeDBOFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode;
        Column: TColumnIndex);
    procedure TreeDBOGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
        Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var
        ImageIndex: Integer);
    procedure TreeDBOGetNodeDataSize(Sender: TBaseVirtualTree; var NodeDataSize:
        Integer);
    procedure TreeDBOGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column:
        TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure TreeDBOInitChildren(Sender: TBaseVirtualTree; Node: PVirtualNode; var
        ChildCount: Cardinal);
    procedure TreeDBOInitNode(Sender: TBaseVirtualTree; ParentNode, Node:
        PVirtualNode; var InitialStates: TVirtualNodeInitStates);
  private
    { Private declarations }
    FColumns: Array of Array of TStringList;
    function GetSelectedObject: TStringList;
  public
    { Public declarations }
    property SelectedObject: TStringList read GetSelectedObject;
  end;

function SelectDBO: TStringList;

implementation

uses main, helpers;

{$R *.dfm}

function SelectDBO: TStringList;
begin
  if Mainform.SelectDBObjectForm = nil then
    Mainform.SelectDBObjectForm := TfrmSelectDBObject.Create(Mainform);
  Result := nil;
  if Mainform.SelectDBObjectForm.ShowModal = mrOK then
    Result := Mainform.SelectDBObjectForm.SelectedObject;
end;


procedure TfrmSelectDBObject.FormCreate(Sender: TObject);
begin
  Width := GetRegValue(REGNAME_SELECTDBO_WINWIDTH, Width);
  Height := GetRegValue(REGNAME_SELECTDBO_WINHEIGHT, Height);
  SetWindowSizeGrip( Self.Handle, True );
  InheritFont(Font);
  TreeDBO.TreeOptions := MainForm.DBtree.TreeOptions;
  FixVT(TreeDBO);
end;

procedure TfrmSelectDBObject.FormDestroy(Sender: TObject);
begin
  OpenRegistry;
  MainReg.WriteInteger( REGNAME_SELECTDBO_WINWIDTH, Width );
  MainReg.WriteInteger( REGNAME_SELECTDBO_WINHEIGHT, Height );
end;

procedure TfrmSelectDBObject.FormResize(Sender: TObject);
var
  EditWidth: Integer;
const
  space = 3;
begin
  // Calculate width for 1 TEdit
  EditWidth := (TreeDBO.Width - 2*space) div 3;
  // Set widths
  editDb.Width := EditWidth;
  editTable.Width := EditWidth;
  editCol.Width := EditWidth;
  // Set position of TEdits
  editDb.Left := TreeDBO.Left;
  editTable.Left := TreeDBO.Left + EditWidth + space;
  editCol.Left := TreeDBO.Left + 2*(EditWidth + space);
  // Set position of TLabels
  lblDB.Left := editDB.Left;
  lblTable.Left := editTable.Left;
  lblCol.Left := editCol.Left;
end;

procedure TfrmSelectDBObject.FormShow(Sender: TObject);
begin
  TreeDBO.Clear;
  TreeDBO.RootNodeCount := Mainform.DBtree.RootNodeCount;
  SetLength(FColumns, Mainform.ActiveConnection.AllDatabases.Count);
//  TreeDBO.OnFocusChanged(TreeDBO, TreeDBO.FocusedNode, 0);
  editDB.Clear;
  editTable.Clear;
  editCol.Clear;
  editChange(Sender);
end;


function TfrmSelectDBObject.GetSelectedObject: TStringList;
begin
  Result := nil;
  if editDb.Text <> '' then begin
    Result := TStringList.Create;
    Result.Add(editDb.Text);
    if editTable.Text <> '' then Result.Add(editTable.Text);
    if editCol.Text <> '' then Result.Add(editCol.Text);
  end;
  // Let the result be nil to indicate we have no selected node
end;

procedure TfrmSelectDBObject.TreeDBOFocusChanged(Sender: TBaseVirtualTree;
    Node: PVirtualNode; Column: TColumnIndex);
begin
  editDB.Clear;
  editTable.Clear;
  editCol.Clear;
  if Assigned(Node) then case TreeDBO.GetNodeLevel(Node) of
    1: editDB.Text := TreeDBO.Text[Node, 0];
    2: begin
      editDB.Text := TreeDBO.Text[Node.Parent, 0];
      editTable.Text := TreeDBO.Text[Node, 0];
    end;
    3: begin
      editDB.Text := TreeDBO.Text[Node.Parent.Parent, 0];
      editTable.Text := TreeDBO.Text[Node.Parent, 0];
      editCol.Text := TreeDBO.Text[Node, 0];
    end;
  end;
end;


procedure TfrmSelectDBObject.editChange(Sender: TObject);
begin
  // DB must be filled
  btnOK.Enabled := editDB.Text <> '';
  // If col given, check if table is also given
  if editCol.Text <> '' then
    btnOK.Enabled := editTable.Text <> '';
end;


procedure TfrmSelectDBObject.TreeDBOGetImageIndex(Sender: TBaseVirtualTree;
    Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted:
    Boolean; var ImageIndex: Integer);
begin
  Mainform.DBtreeGetImageIndex(Sender, Node, Kind, Column, Ghosted, ImageIndex);
end;


procedure TfrmSelectDBObject.TreeDBOGetNodeDataSize(Sender: TBaseVirtualTree;
    var NodeDataSize: Integer);
begin
  MainForm.DBtreeGetNodeDataSize(Sender, NodeDataSize);
end;


procedure TfrmSelectDBObject.TreeDBOInitChildren(Sender: TBaseVirtualTree;
    Node: PVirtualNode; var ChildCount: Cardinal);
begin
  // Fetch sub nodes
  Mainform.DBtreeInitChildren(Sender, Node, ChildCount);
end;


procedure TfrmSelectDBObject.TreeDBOGetText(Sender: TBaseVirtualTree; Node:
    PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText:
    String);
begin
  Mainform.DBtreeGetText(Sender, Node, Column, TextType, CellText);
end;


procedure TfrmSelectDBObject.TreeDBOInitNode(Sender: TBaseVirtualTree;
    ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
var
  DBObj: PDBObject;
begin
  Mainform.DBtreeInitNode(Sender, ParentNode, Node, InitialStates);
  DBObj := Sender.GetNodeData(Node);
  if DBObj.Connection <> MainForm.ActiveConnection then begin
    Include(InitialStates, ivsDisabled);
    Exclude(InitialStates, ivsHasChildren);
  end else if DBObj.NodeType = lntNone then
    Include(InitialStates, ivsExpanded);
end;

end.
