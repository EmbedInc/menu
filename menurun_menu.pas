{   Menu manipulation routines within program MENURUN.
}
module menurun_menu;
define menurun_menu_build;
%include 'menurun.ins.pas';
{
********************************************************************************
*
*   Subroutine MENURUN_MENU_BUILD (MENU, GMEN)
*
*   Create the GUI library menu GMEN from the MENU library menu MENU.
}
procedure menurun_menu_build (         {build GUI menu from MENU menu}
  in      menu: menu_t;                {source menu}
  in out  gmen: gui_menu_t);           {GUI library menu to build}
  val_param;

var
  ent_p: menu_ent_p_t;                 {to current menu entry}
  n: sys_int_machine_t;                {1-N menu entry number}
  name: string_var80_t;                {menu entry name (string shown to user)}

begin
  name.max := size_char(name.str);     {init local var string}

  ent_p := tree_p^.menu_p^.ents_p;     {init to first menu entry}
  n := 0;                              {init to before first entry}

  while ent_p <> nil do begin          {loop over the menu entries}
    n := n + 1;                        {make 1-N number of this menu entry}

    string_copy (ent_p^.name_p^, name); {init name of this entry}
    if ent_p^.entact = menu_entact_submenu_k then begin {brings up submenu ?}
      string_appends (name, ' ...'(0)); {add sub-menu indicator}
      end;

    gui_menu_ent_add (                 {add this menu entry}
      gmen,                            {GUI menu to add entry to}
      name,                            {entry name to display to user}
      ent_p^.shcut,                    {shortcut key char within name, 0 = none}
      n);                              {ID to return when this entry picked}

    ent_p := ent_p^.next_p;            {to next source menu entry}
    end;
  end;
