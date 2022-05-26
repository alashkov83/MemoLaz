unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  Forms,
  LCLType,
  LazUTF8,
  Dialogs,
  Menus,
  fgl,
  Clipbrd,
  ComCtrls,
  LConvEncoding,
  RegExpr,
  StreamEx;



type

  ThemClass = class(TObject)
    Caption: string;
    records: TStringList;
  public
    procedure Add(rec: string);
    constructor Create(cap: string); reintroduce;
    destructor Destroy; override;
  end;

  TThemList = specialize TFPGList<ThemClass>;

  ABCThemClass = class(TObject)
    Letter: string;
    records: TThemList;
  public
    procedure Add(rec: ThemClass);
    constructor Create(let: string); reintroduce;
    destructor Destroy; override;
  end;

  TABCThemList = specialize TFPGList<ABCThemClass>;

  { TMForm }

  TMForm = class(TForm)
    MainMenu1: TMainMenu;
    FlMenu: TMenuItem;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    AboutFileMenu: TMenuItem;
    SortMenuItem: TMenuItem;
    ReloadMenuItem: TMenuItem;
    StatusBar1: TStatusBar;
    ThemMenu: TMenuItem;
    OpenFDialog: TOpenDialog;
    OpMenu: TMenuItem;
    exitMI: TMenuItem;
    MenuItem5: TMenuItem;
    procedure exitMIClick(Sender: TObject);
    procedure OpMenuClick(Sender: TObject);
    procedure aboutMIClick(Sender: TObject);
    procedure AboutFile(Sender: TObject);
    procedure MenuClickHandler(Sender: TObject);
    procedure ReloadMenuClick(Sender: TObject);
    procedure SortMenuClick(Sender: TObject);
  private
    FileNameField: string;
    ThemList: TThemList;
    re: TRegExpr;
    size: int64;
    function parseFile(fname: string): boolean;
    function sortMemo: TABCThemList;
    procedure ConstructMenu;
    procedure ConstructSortMenu(abcthemlist: TABCThemList);
    procedure ShowError(message: string);
    procedure ShowWarning(message: string);
    procedure ShowInfo(message: string);
  public
    constructor Create(app: TComponent); override;
    destructor Destroy; override;
  end;

function compareThem(const a, b:  ThemClass): Integer;
function compareABCThem(const a, b:  ABCThemClass): Integer;

var
  MForm: TMForm;

implementation

{$R *.lfm}

{ TMForm }

constructor TMForm.Create(app: TComponent);
begin
  inherited Create(app);
  ThemList := TThemList.Create;
  re := TRegExpr.Create('^### (.*?)$');
  if FileExists('Shablon_Memo.txt') then
  begin
    if parseFile('Shablon_Memo.txt') then
    begin
      ConstructMenu;
      FileNameField := 'Shablon_Memo.txt';
      StatusBar1.SimpleText := FileNameField;
    end
    else
      ShowError('Ошибка открытия файла Shablon_Memo.txt');
  end
  else
  begin
    OpMenuClick(self);
  end;
end;

destructor TMForm.Destroy;
begin
  re.Free;
  ThemList.Clear;
  ThemList.Free;
  inherited;
end;

procedure TMForm.OpMenuClick(Sender: TObject);
var
  FName: string;
begin
  if OpenFDialog.Execute then
  begin
    FName := OpenFDialog.Filename;
    if parseFile(FName) then
    begin
      ConstructMenu;
      FileNameField := FName;
      StatusBar1.SimpleText := ExtractFileName(FileNameField);
    end
    else
      ShowError('Ошибка открытия файла: ' + FName);
  end;
end;

procedure TMForm.exitMIClick(Sender: TObject);
begin
  Close;
end;


procedure TMForm.ReloadMenuClick(Sender: TObject);
begin
  if parseFile(FileNameField) then
  begin
    ConstructMenu;
  end
  else
    ShowError('Ошибка открытия файла: ' + FileNameField);
end;

procedure TMForm.SortMenuClick(Sender: TObject);
var
  abcthemlist: TABCThemList;
begin
  abcthemlist := SortMemo;
  if abcthemlist.Count <> 0 then ConstructSortMenu(abcthemlist);
end;

procedure TMForm.ConstructMenu;
var
  them: ThemClass;
  rec: string;
  tm, fm: TMenuItem;
begin
  ThemMenu.Clear;
  for them in themlist do
  begin
    tm := TMenuItem.Create(ThemMenu);
    tm.Caption := StringReplace(them.Caption, '&', '&&', [rfReplaceAll]);
    for rec in them.records do
    begin
      fm := TMenuItem.Create(tm);
      fm.Caption := StringReplace(rec, '&', '&&', [rfReplaceAll]);
      fm.OnClick := @MenuClickHandler;
      tm.Add(fm);
    end;
    ThemMenu.Add(tm);
  end;
end;

procedure TMForm.ConstructSortMenu(abcthemlist: TABCThemList);
var
  them: ThemClass;
  abcthem: ABCThemClass;
  rec: string;
  abcm, tm, fm: TMenuItem;

begin
  ThemMenu.Clear;
  for abcthem in abcthemlist do
  begin
    abcm := TMenuItem.Create(ThemMenu);
    abcm.Caption := abcthem.Letter;
    for them in abcthem.records do
    begin
      tm := TMenuItem.Create(abcm);
      tm.Caption := StringReplace(them.Caption, '&', '&&', [rfReplaceAll]);
      for rec in them.records do
      begin
        fm := TMenuItem.Create(tm);
        fm.Caption := StringReplace(rec, '&', '&&', [rfReplaceAll]);
        fm.OnClick := @MenuClickHandler;
        tm.Add(fm);
      end;
      abcm.Add(tm);
    end;
    ThemMenu.Add(abcm);
  end;
  abcthemlist.Clear;
  abcthemlist.Free;
end;


procedure TMForm.AboutFile(Sender: TObject);
var
  s_size: string;
  path: string;
  fa: longint;
  s_access_time: string;
begin
  if (ExtractFilePath(FileNameField) = '') then
  begin
    path := GetCurrentDir();
  end
  else
  begin
    path := ExtractFilePath(FileNameField);
  end;
  if FileExists(FileNameField) then
  begin
    s_size := IntToStr(size);
    fa := FileAge(FileNameField);
    if Fa <> -1 then
    begin
      s_access_time := DateTimeToStr(FileDateTodateTime(fa));
    end
    else
    begin
      s_access_time := 'Не определено';
    end;
  end
  else
  begin
    s_size := 'Файл недоступен';
    s_access_time := 'Файл недоступен';
  end;
  ShowInfo('Путь: ' + path + sLineBreak + 'Размер: ' +
    s_size + sLineBreak + 'Дата и время изменения: ' + s_access_time);
end;


procedure TMForm.MenuClickHandler(Sender: TObject);
begin
  with Sender as TMenuItem do
    Clipboard.AsText := StringReplace(Caption, '&&', '&', [rfReplaceAll]);
end;

function TMForm.parseFile(fname: string): boolean;
var
  readString: ansistring;
  utfString: string;
  FileStream: TFileStream;
  LineReader: TStreamReader;
  them: ThemClass;
begin
  FileStream := TFileStream.Create(fname, fmOpenRead + fmShareDenyWrite);
  size := FileStream.Size;
  ThemList.Clear;
  them := nil;
  try
    LineReader := TStreamReader.Create(FileStream);
    while not LineReader.EOF do
    begin
      LineReader.ReadLine(readString);
      utfString := CP1251ToUTF8(readString);
      if re.Exec(utfString) then
      begin
        if them <> nil then
          themlist.Add(them);
        them := ThemClass.Create(re.Match[1]);
      end
      else
      if (utfString <> '') and (them <> nil) then
        them.Add(utfString);
    end;
    if them <> nil then
      themlist.Add(them);
    Result := True;
  except
    On E: Exception do
    begin
      Result := False;
      ShowError(E.Message);
    end;
  end;
  FileStream.Free;
end;

function TMForm.sortMemo: TABCThemList;
var
  them, them_copy: ThemClass;
  abcindex: Integer;
  StrList: TStringList;
  letter, rec: string;
  abcthemlist: TABCThemList;
  abcthem: ABCThemClass;
begin
  abcthemlist := TABCThemList.Create;
  StrList:=TStringList.Create;
  StrList.Sorted:=True;
  StrList.Duplicates:=dupIgnore;
  for them in ThemList do
  begin
    them_copy := ThemClass.Create(them.Caption);
    for rec in them.records do
    begin
      them_copy.Add(UTF8Copy(rec,1, MaxInt));
    end;
    letter := UTF8UpperCase(UTF8Copy(them_copy.Caption, 1, 1));
    abcindex := StrList.IndexOf(letter);
    if (abcindex = -1) then
    begin
      StrList.Add(letter);
      abcthem := ABCThemClass.Create(letter);
      abcthem.Add(them_copy);
      abcthemlist.Add(abcthem);
      abcthemlist.Sort(@compareABCThem);
    end else
    begin
      abcthemlist[abcindex].Add(them_copy);
      abcthemlist[abcindex].records.Sort(@compareThem);
    end;
  end;
  StrList.Free;
  result := abcthemlist;
end;

procedure TMForm.ShowError(message: string);
begin
  Application.MessageBox(PChar(message), PChar('Ошибка'), MB_OK + MB_ICONERROR);
end;

procedure TMForm.ShowWarning(message: string);
begin
  Application.MessageBox(PChar(message), PChar('Внимание!'),
    MB_OK + MB_ICONWARNING);
end;

procedure TMForm.ShowInfo(message: string);
begin
  Application.MessageBox(PChar(message), PChar('Информация'),
    MB_OK + MB_ICONINFORMATION);
end;

procedure TMForm.aboutMIClick(Sender: TObject);
var
  about_s: string = 'MemoLaz v. 2.0' + sLineBreak +
  '©2021-2022 Лашков А., Набатов Б.' + sLineBreak +
  'Для разработки использована среда Lazarus и Free Pascal Compiler version 3.0';
begin
  Application.MessageBox(PChar(about_s), PChar('О программе'),
    MB_OK + MB_ICONINFORMATION);
end;

constructor ThemClass.Create(cap: string);
begin
  inherited Create;
  Caption := cap;
  records := TStringList.Create;
end;

destructor ThemClass.Destroy;
begin
  records.Free;
  inherited;
end;

procedure ThemClass.Add(rec: string);
begin
  records.Add(rec);
end;

constructor ABCThemClass.Create(let: string);
begin
  inherited Create;
  Letter := let;
  records := TThemList.Create;
end;

destructor ABCThemClass.Destroy;
begin
  records.Free;
  inherited;
end;

procedure ABCThemClass.Add(rec: ThemClass);
begin
  records.Add(rec);
end;

function compareThem(const a, b:  ThemClass): Integer;
begin
  result := UTF8CompareStr(a.Caption, b.Caption);
end;

function compareABCThem(const a, b:  ABCThemClass): Integer;
begin
  result := UTF8CompareStr(a.Letter, b.Letter);
end;

end.
