{   Perform menu selection within MENURUN program.
}
module menurun_select;
define menurun_select;
%include 'menurun.ins.pas';
{
********************************************************************************
*
*   Function MENURUN_SELECT (MENU, TLX, TLY)
*
*   Create a GUI library menu according to MENU and return the user selection
*   result.  TLX,TLY is the preferred coordinate of the top left menu corner
*   within the window.  This coordinate is in units of pixels with the lower
*   left window corner being 0,0.
*
*   Subordinate menus are handled recursively.
}
function menurun_select (              {make GUI menu, get user selection}
  in      menu: menu_t;                {source menu}
  in      tlx, tly: real)              {preferred top left menu corner within window}
  :menurun_sel_k_t;                    {result of selection}
  val_param;

var
  gmen: gui_menu_t;                    {GUI library menu corresponding to MENU}
  selid: sys_int_machine_t;            {1-N selected entry or GUI_MENSEL_xxx_K}
  sel_p: gui_menent_p_t;               {pointer to selected GUI lib menu entry}
  ent_p: menu_ent_p_t;                 {pointer to selected MENU lib menu entry}
  mensel: menurun_sel_k_t;             {selection result of subordinate menu}
  subx, suby: real;                    {top left corner of any submenu}

label
  redo, leave;

begin
  gui_menu_create (gmen, win_root);    {create the GUI library menu}
  menurun_menu_build (menu, gmen);     {fill in the GUI menu}
  gui_menu_place (gmen, tlx, tly);     {position the menu within the window}

redo:                                  {back here to re-do selection from this menu}
  discard( gui_menu_select (gmen, selid, sel_p) ); {get menu selection result}
  case selid of                        {check for special handling cases}
gui_mensel_cancel_k: begin             {user wants to cancel whole menu selection}
      menurun_select := menurun_sel_cancel_k;
      goto leave;
      end;
gui_mensel_prev_k: begin               {user wants to go back to previous menu}
      menurun_select := menurun_sel_prev_k;
      goto leave;
      end;
gui_mensel_resize_k: begin             {windows resized, need to adjust to new config}
      menurun_select := menurun_sel_event_k; {need to handle RENDlib event in queue}
      goto leave;
      end;
otherwise                              {should only be entry was selected}
    if selid < 1 then begin            {invalid selection ID ?}
      menurun_select := menurun_sel_cancel_k; {something went wrong, cancel selection}
      goto leave;
      end;
    end;                               {end of selection result cases}
{
*   SELID is the 1-N ID of the menu entry that was selected, and SEL_P points to
*   the GUI menu entry descriptor of the selected entry.
}
  menu_ent_n (menu, selid, ent_p);     {get pointer to selected MENU lib entry}
  if ent_p = nil then begin            {no such entry (shouldn't happen)}
    menurun_select := menurun_sel_cancel_k; {cancel the whole mess}
    goto leave;
    end;

  case ent_p^.entact of                {what kind of action to take for this entry ?}

menu_entact_submenu_k: begin           {bring up submenu}
      subx :=                          {make preferred left X of submenu}
        gmen.win.rect.x +              {left edge of this menu within window}
        sel_p^.xr +                    {right edge of selection button within menu}
        1;                             {offset to make outer menu borders overlap}
      suby :=                          {make preferred top Y of submenu}
        gmen.win.rect.y +              {bottom edge of this menu within window}
        sel_p^.yt +                    {top edge of selection button within menu}
        2;                             {offset to align submenu entries with this menu}
      mensel := menurun_select (       {get selection from the subordinate menu}
        ent_p^.submenu_p^,             {the submenu}
        subx, suby);                   {preferred menu top left coordinate}
      if mensel = menurun_sel_prev_k then begin {user wants back to this menu ?}
        goto redo;                     {get new selection from this menu}
        end;
      menurun_select := mensel;        {otherwise pass back subordinate selection}
      end;

menu_entact_cmd_k: begin               {run command}
      string_copy (ent_p^.cmd_p^, command); {save command line to run}
      menurun_select := menurun_sel_cmd_k; {indicate to run command}
      end;

otherwise                              {unexpected menu entry action}
    menurun_select := menurun_sel_cancel_k; {abort the whole menu selection}
    end;                               {end of menu entry action cases}
{
*   Clean up and leave.  The function return value is already set.
}
leave:
  gui_menu_delete (gmen);              {delete the GUI menu, release resources}
  end;
