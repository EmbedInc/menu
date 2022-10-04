{   Private include file for the MENURUN program.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'img.ins.pas';
%include 'math.ins.pas';
%include 'vect.ins.pas';
%include 'rend.ins.pas';
%include 'gui.ins.pas';
%include 'menu.ins.pas';
%include 'builddate.ins.pas';
%include 'debug_switches.ins.pas';

type
  menurun_sel_k_t = (                  {action resulting from menu selection}
    menurun_sel_event_k,               {handle RENDlib event from top level}
    menurun_sel_prev_k,                {go back to previous menu in tree}
    menurun_sel_cancel_k,              {cancel the menu selection}
    menurun_sel_cmd_k);                {run the command in COMMAND}

var (menurun_com)
  tree_p: menu_tree_p_t;               {to menu tree}
  gdev: gui_rendev_t;                  {GUI lib state for RENDlib device}
  win_root: gui_win_t;                 {root GUI library window}
  command: string_var8192_t;           {command to execute as result of menu selection}

procedure draw_root (                  {draw routine for WIN_ROOT window}
  in      win_p: gui_win_p_t;          {pointer to the window to redraw}
  in      app_p: univ_ptr);            {pointer to private app data}
  val_param; extern;

procedure menurun_menu_build (         {build GUI menu from MENU menu}
  in      menu: menu_t;                {source menu}
  in out  gmen: gui_menu_t);           {GUI library menu to build}
  val_param; extern;

function menurun_select (              {make GUI menu, get user selection}
  in      menu: menu_t;                {source menu}
  in      tlx, tly: real)              {preferred top left menu corner within window}
  :menurun_sel_k_t;                    {result of selection}
  val_param; extern;
