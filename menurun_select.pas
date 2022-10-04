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
  sel_p: gui_menent_p_t;               {pointer to selected menu entry}

label
  leave;

begin
  gui_menu_create (gmen, win_root);    {create the GUI library menu}
  menurun_menu_build (tree_p^.menu_p^, gmen); {fill in the GUI menu}
  gui_menu_place (gmen, tlx, tly);     {position the menu within the window}

  discard( gui_menu_select (gmen, selid, sel_p) ); {get menu selection result}
  gui_menu_delete (gmen);              {delete the GUI menu, release resources}
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
*   SELID is the 1-N ID of the menu entry that was selected.
}


  writeln ('SELID = ', selid);
  menurun_select := menurun_sel_cancel_k; {TEMP DEBUG}



{
*   Clean up and leave.  The function return value is already set.
}
leave:
  end;
