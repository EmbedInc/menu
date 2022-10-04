{   Drawing routines of the MENURUN program.
}
module menurun_draw;
define draw_root;
%include 'menurun.ins.pas';
{
********************************************************************************
*
*   Local subroutine DRAW_ROOT (WIN_P, APP_P)
*
*   Redraw the main window.  This routine is installed as the redraw routine of
*   the main GUI library window, WIN_ROOT.
}
procedure draw_root (                  {draw routine for WIN_ROOT window}
  in      win_p: gui_win_p_t;          {pointer to the window to redraw}
  in      app_p: univ_ptr);            {pointer to private app data}
  val_param;

begin
  rend_set.enter_rend^;

  rend_set.rgb^ (0.5, 0.5, 0.5);       {draw background}
  rend_prim.clear_cwind^;

  rend_set.exit_rend^;
  end;
