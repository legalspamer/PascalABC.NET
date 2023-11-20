uses graphwpf, controls;

type
  blocks = boolean;

type
  figures = array [,] of blocks;

type
  gamefield = array [,] of blocks;

const
  e = false;
  b = true;
  scale = 40; 
  frows = 20;
  fcols = 10;
  rows_offset = 4;
  //bgcolor = RGB(20, 20, 20);
  //fgcolor = RGB(40, 40, 40);
var
  bgcolor := RGB(20, 20, 20);
  fgcolor := RGB(40, 40, 40);

var
  score: integer;

function figurerandom(): array [,] of blocks;
begin
  case random(1, 7) of
    1:
      result := Matr(|e, b, e, e|,
                     |e, b, e, e|,
                     |e, b, e, e|,
                     |e, b, e, e|);
    2:
      result := Matr(|e, e, e, e|,
                     |e, e, e, e|,
                     |b, b, b, e|,
                     |e, b, e, e|);
    3:
      result := Matr(|e, e, e, e|,
                     |e, b, e, e|,
                     |e, b, b, e|,
                     |e, e, b, e|);
    4:
      result := Matr(|e, e, e, e|,
                     |e, e, b, e|,
                     |e, b, b, e|,
                     |e, b, e, e|);
    5:
      result := Matr(|e, e, e, e|,
                     |e, b, e, e|,
                     |e, b, e, e|,
                     |e, b, b, e|);
    6:
      result := Matr(|e, e, e, e|,
                     |e, e, b, e|,
                     |e, e, b, e|,
                     |e, b, b, e|);
    7:
      result := Matr(|e, e, e, e|,
                     |e, b, b, e|,
                     |e, b, b, e|,
                     |e, e, e, e|); 
  end;
end;

function isempty(c, r: integer; var field: gamefield): boolean;
begin
  if (c in 0..fcols - 1) and (r in 0..frows - 1) then
    result := not field[r, c]
  else result := false;
end;

function isvalid(c, r: integer; var field: gamefield; figure: figures): boolean;
begin
  window.Caption := (c, r).ToString;
  result := true;
  for var rr := 0 to figure.RowCount - 1 do
    for var cc := 0 to figure.ColCount - 1 do
      if (figure[cc, rr] and not isempty(c + cc, r + rr, field)) or (r >= 19) then
      begin
        result := false;
        break;
      end;
end;

procedure fielddraw(c, r: integer; var field, figure, nextfigure: figures);
begin
  window.Clear(bgcolor);
  for var rr := 0 to field.RowCount - 1 do
    for var cc := 0 to field.ColCount - 1 do
      rectangle(cc * scale, rr * scale, scale, scale, field[rr, cc] ? colors.white : fgcolor);
  for var rr := 0 to figure.RowCount - 1 do
    for var cc := 0 to figure.ColCount - 1 do
    begin
      if figure[cc, rr] then rectangle((cc + c) * scale, (r + rr) * scale, scale, scale, colors.yellow);
      if nextfigure[rr, cc] then rectangle((11 + rr) * scale, (1 + cc) * scale, scale, scale, colors.yellow);
    end;
end;

procedure figuredraw(c, r: integer; var figure: figures);
begin
  for var rr := 0 to figure.RowCount - 1 do
    for var cc := 0 to figure.ColCount - 1 do
      if figure[cc, rr] then rectangle((r + rr) * scale, (c + cc) * scale, scale, scale, colors.yellow);
end;

procedure figurefix(c, r: integer; var field, figure: figures);
begin
  for var rr := 0 to figure.RowCount - 1 do
    for var cc := 0 to figure.ColCount - 1 do
      if figure[cc, rr] then field[r + rr, c + cc] := b;
end;

function figurerotate(figure: figures): figures;
begin
  result := transpose(figure);
  for var i := 0 to 1 do result.SwapCols(i, 3 - i);
end;

procedure ScanLines(var field: gamefield);
begin
  for var rr := 0 to frows - 1 do  
    if field.Row(rr).CountOf(b) = fcols then
    begin
      field.SetRow(rr, arrgen(fcols, t -> e));
      score += 1;
      for var rrr := rr to 1 step -1 do
      begin
        field.SwapRows(rrr - 1, rrr);
      end;
    end;  
end;
procedure GameProcess(var r, c:integer; var field:gamefield;var figure,nextfigure:figures);
begin
  if isvalid(c, r + 1, field, figure) then r += 1 else 
      begin
        if r = 0 then exit;
        figurefix(c, r, field, figure);
        figure := nextfigure;
        nextfigure := figurerandom;
        c := 3;
        r := 0;
      end;
   scanlines(field);
end;

begin
  window.Caption := 'TETЯS v0.2';
  window.IsFixedSize := true;
  window.Height := frows * scale;
  window.Width := (fcols + 12) * scale;
  leftpanel(scale * 6, bgcolor);
  window.Clear(bgcolor);
  var newgame := button('Начать игру', 32);
  var quit := button('Выйти', 32);
  var skip := false;
  var dtime: real;
  var delay := 0.3;
  var (c, r) := (3, 0);
  var field:gamefield;
  var figure:figures;
  var nextfigure:figures;
  var gameover:=true;
  
  newgame.click := ()->
  begin
    field := new blocks[frows, fcols];
    figure := figurerandom;
    nextfigure := figurerandom;
    gameover:=false;
  end; 
  
  ondrawframe := dt -> 
  begin
    if gameover then exit;
    fielddraw(c, r, field, figure, nextfigure);
    dtime += dt;
    if (dtime > delay) or skip then
    begin
      dtime := 0;
      skip := false;
      gameprocess(r,c,field,figure,nextfigure);
    end;
  end;
  
  onkeydown := k -> 
  begin
    var d := 0;
    var rotate := false;
    case k of
      key.Left: d := -1;
      key.Right: d := 1;
      key.Up: rotate := true;
      key.Down: skip := true;
    else exit;
    end;
    if isvalid(c + d, r, field, figure) then c += d;
    if rotate and isvalid(c, r, field, figurerotate(figure)) then figure := figurerotate(figure);
  end;
  
  quit.Click := ()->
  begin
    window.Close;
  end;
end.