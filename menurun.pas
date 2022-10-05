{   Program MENURUN menufile
}
program menurun;
%include 'menurun.ins.pas';
define menurun_com;                    {common block defined in include file}

var
  fnam:                                {menu file name}
    %include '(cog)lib/string_treename.ins.pas';
  devnam:                              {name of RENDlib device to open}
    %include '(cog)lib/string80.ins.pas';
  tree_p: menu_tree_p_t;               {to menu tree}
  gdev: gui_rendev_t;                  {GUI lib state for RENDlib device}
  ev: rend_event_t;                    {RENDlib event descriptor}
  stat: sys_err_t;                     {completion status}

label
  recreate, leave;

begin
{
*   Initialize common block state.
}
  command.max := size_char(command.str);
{
*   Process the command line.
}
  string_cmline_init;                  {init for reading the command line}
  string_cmline_token (fnam, stat);    {get the menu file name}
  sys_error_abort (stat, '', '', nil, 0);
  string_cmline_end_abort;             {nothing more allowed on command line}
{
*   Read the menu file.  TREE_P will point to the resulting menu tree.
}
  menu_file_read (fnam, util_top_mem_context, tree_p, stat); {read menu file}
  sys_error_abort (stat, '', '', nil, 0);
{
*   Start up RENDlib.  Create the device the GUI windows will be drawn within.
}
  devnam.len := 0;                     {init to let OS choose window size/location}
  if debugging then begin              {program built for debugging ?}
    string_vstring (devnam, 'debug'(0), -1); {RENDlib device name to use when debugging}
    end;

  rend_start;                          {init RENDlib}
  rend_open (                          {open our graphics device}
    devnam,                            {name of RENDlib device to use}
    gdev.id,                           {returned RENDlib device ID}
    stat);                             {error status}
  sys_error_abort (stat, 'rend', 'rend_open', nil, 0);
{
*   Initialize the GUI library.
}
  gui_rendev_def (gdev);               {init GUI lib REND dev state to defaults}
  gui_rendev_setup (gdev);             {set up RENDlib device to GUI requirements}
{
*   Create or re-create the GUI library windows.  The GUI windows are deleted
*   when the drawing device changes.  In that case, execution comes back here to
*   re-create the GUI windows according to the new drawing device dimensions.
}
recreate:                              {back here to re-create the GUI windows}
  gui_win_root (win_root);             {create root GUI library window}
  gui_win_set_draw (win_root, univ_ptr(addr(draw_root))); {set draw routine for root window}
  gui_win_draw_all (win_root);         {draw root window contents}

  case menurun_select (tree_p^.menu_p^, 0.0, gdev.pixy) of {what user action ?}
{
*   No selection was made, but a RENDlib event needs to be handled.  The only
*   case we handle is if the window got resized.  Otherwise, we act as if the
*   user aborted the whole menu selection.
}
menurun_sel_event_k: begin             {need to process RENDlib event}
      rend_event_get_nowait (ev);      {get event on queue, if any}
      case ev.ev_type of               {what event is it ?}
rend_ev_resize_k,                      {RENDlib device changed size ?}
rend_ev_wiped_resize_k: begin
          gui_win_delete (win_root);   {delete all the GUI windows}
          gui_rendev_resize (gdev);    {adjust to the new size}
          goto recreate;               {keep going with the new size}
          end;
        end;                           {end of RENDlib event cases we handle}
      goto leave;                      {clean up and leave}
      end;
{
*   All other menu selection result cases are handled as if the user wants to
*   abort the whole process.  These are the fall-thru case with no special
*   handling.
}
    end;                               {end of menu selection result cases}

leave:                                 {clean up and leave}
  gui_win_delete (win_root);           {delete all GUI windows}
  rend_end;                            {stop RENDlib}

  if command.len > 0 then begin        {menu selection resulted in command to run ?}
    writeln ('Running: ', command.str:command.len); {TEMP DEBUG}
    sys_run_shell (command, stat);     {run the command}
    sys_error_abort (stat, '', '', nil, 0);
    end;
  end.
