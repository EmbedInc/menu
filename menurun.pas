{   Program MENURUN menufile
}
program menurun;
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

var
  fnam:                                {menu file name}
    %include '(cog)lib/string_treename.ins.pas';
  tree_p: menu_tree_p_t;               {to menu tree}
  ent_p: menu_ent_p_t;                 {to current menu entry}
  n: sys_int_machine_t;                {1-N menu entry number}

  dev: gui_rendev_t;                   {GUI lib state for RENDlib device}
  win_root: gui_win_t;                 {root GUI library window}
  menu: gui_menu_t;                    {top level menu}
  selid: sys_int_machine_t;            {ID of selected menu entry}
  sel_p: gui_menent_p_t;               {pointer to selected menu entry}
  ev: rend_event_t;                    {RENDlib event descriptor}
  stat: sys_err_t;                     {completion status}

label
  redo;
{
********************************************************************************
*
*   Local subroutine DRAW_ROOT (WIN_P, APP_P)
*
*   Redraw the main window.
}
procedure draw_root (
  in      win_p: gui_win_p_t;          {pointer to the window to redraw}
  in      app_p: univ_ptr);            {pointer to private app data}
  val_param; internal;

begin
  rend_set.enter_rend^;

  rend_set.rgb^ (0.5, 0.5, 0.5);       {draw background}
  rend_prim.clear_cwind^;

  rend_set.rgb^ (0.0, 0.0, 0.0);       {draw diamond to device edges}
  rend_set.cpnt_2d^ (dev.pixx, dev.pixy/2.0);
  rend_prim.vect_2d^ (dev.pixx/2.0, dev.pixy);
  rend_prim.vect_2d^ (0.0, dev.pixy/2.0);
  rend_prim.vect_2d^ (dev.pixx/2.0, 0.0);
  rend_prim.vect_2d^ (dev.pixx, dev.pixy/2.0);

  dev.tparm.start_org := rend_torg_mid_k; {write "Center" in the center of the square}
  rend_set.text_parms^ (dev.tparm);
  rend_set.cpnt_2d^ (dev.pixx/2.0, dev.pixy/2.0);
  rend_prim.text^ ('Center', 6);

  rend_set.exit_rend^;
  end;
{
********************************************************************************
*
*   Start of main routine.
}
begin
  string_cmline_init;                  {init for reading the command line}
  string_cmline_token (fnam, stat);    {get the menu file name}
  sys_error_abort (stat, '', '', nil, 0);
  string_cmline_end_abort;             {nothing more allowed on command line}

  menu_file_read (fnam, util_top_mem_context, tree_p, stat);
  sys_error_abort (stat, '', '', nil, 0);

  gui_rendev_def (dev);                {init GUI lib REND dev state to defaults}
  rend_start;                          {init RENDlib}
  rend_open (                          {open our graphics device}
    string_v('debug'(0)),              {name of RENDlib device to use}
    dev.id,                            {returned RENDlib device ID}
    stat);                             {error status}
  sys_error_abort (stat, 'rend', 'rend_open', nil, 0);
  gui_rendev_setup (dev);              {set up RENDlib device to GUI requirements}

redo:                                  {back here to re-create the GUI windows}
  gui_win_root (win_root);             {create root GUI library window on curr REND dev}
  gui_menu_create (menu, win_root);    {create top level menu}
  gui_win_set_draw (win_root, univ_ptr(addr(draw_root))); {set draw routine for root window}

  ent_p := tree_p^.menu_p^.ents_p;     {init to first menu entry}
  n := 0;
  while ent_p <> nil do begin          {loop over the menu entries}
    n := n + 1;                        {make 1-N number of this menu entry}
    gui_menu_ent_add (menu, ent_p^.name_p^, 0, n); {create GUI menu entry}
    ent_p := ent_p^.next_p;            {to next menu entry}
    end;

  gui_win_draw_all (win_root);         {draw root window contents}
  gui_menu_place (menu, 0.0, dev.pixy);

  if gui_menu_select (menu, selid, sel_p)
    then begin
      writeln ('Selection = ', selid);
      end
    else begin
      writeln ('No selection, ID = ', selid);
      end
    ;

  rend_event_get_nowait (ev);          {get event on queue, if any}
  case ev.ev_type of                   {what event is it ?}

rend_ev_resize_k,                      {RENDlib device changed size ?}
rend_ev_wiped_resize_k: begin
      gui_win_delete (win_root);       {delete all the GUI windows}
      gui_rendev_resize (dev);         {adjust to the new size}
      goto redo;                       {keep going with the new size}
      end;

    end;                               {end of event type cases}
  end;
