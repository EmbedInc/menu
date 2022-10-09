{   Routines that manipulate menu entries.
*
*   Menu entries are always associated with a particular menu.  However, they
*   are not "known" to that menu until they are "added".  Adding an entry to its
*   menu adds it to the list of entries for that menu.  Only the entries in the
*   list are shown to the user, can be selected, and can be acted upon.
*
*   The procedure for an application to create a new menu entry is:
*
*     1 - Create the new menu entry with MENU_ENT_NEW.  The new entry will be
*         associated with its menu, but not yet in the list of menu entries.
*
*     2 - Set the various entry parameters, such as name, action, etc.
*
*     3 - Add the fully filled-in entry to its menu with MENU_ENT_ADD.  After
*         this step, the entry parameters are not allowed to be changed anymore.
}
module menu_ent;
define menu_ent_new;
define menu_ent_name;
define menu_ent_shcut;
define menu_ent_seq;
define menu_ent_act_sub;
define menu_ent_act_run;
define menu_ent_run_dir;
define menu_ent_add;
define menu_ent_n;
define menu_ent_find;
%include 'menu2.ins.pas';
{
********************************************************************************
*
*   Subroutine MENU_ENT_NEW (MENU, ENT_P)
*
*   Create a new menu entry associated with the menu MENU.  ENT_P is returned
*   pointing to the new entry.  The new entry is initialized to default or
*   benign settings to the extent possible.  The new entry will be associated
*   with the menu MENU, but not "added" to the menu.
}
procedure menu_ent_new (               {create new blank menu entry}
  in var  menu: menu_t;                {menu the new entry will belong to}
  out     ent_p: menu_ent_p_t);        {new entry, initialized, unlinked}
  val_param;

begin
  menu_mem_alloc (                     {allocate memory for the new entry}
    menu.tree_p^, sizeof(ent_p^), ent_p);

  ent_p^.prev_p := nil;                {not linked to entries list yet}
  ent_p^.next_p := nil;
  ent_p^.menu_p := addr(menu);         {save pointer to menu entry is within}
  ent_p^.name_p := nil;                {entry name not set yet}
  ent_p^.shcut := 0;                   {init to no shortcut key}
  ent_p^.seq := lastof(ent_p^.seq);    {init to cause add at end of menu}
  ent_p^.entact := menu_entact_unk_k;  {init to menu action type not known}
  end;
{
********************************************************************************
*
*   Local function MENU_ENT_ADDED (ENT)
*
*   Returns TRUE iff the menu entry ENT has already been added to its menu.
}
function menu_ent_added (              {check for entry added to its menu}
  in var  ent: menu_ent_t)             {the entry to check}
  :boolean;                            {entry has been added to its menu}
  val_param; internal;

begin
  menu_ent_added := true;              {init to entry has been added}
  if ent.prev_p <> nil then return;    {linked after a previous entry ?}
  if ent.next_p <> nil then return;    {linked before a following entry ?}
{
*   The entry is not linked to a previous or following entry in a linked list.
*   It is therefore either not added to its menu, or is the only entry in the
*   menu's list.
}
  if ent.menu_p^.ents_p = addr(ent) then return; {is first entry in menu's list ?}

  menu_ent_added := false;             {indicate entry not added to menu}
  end;
{
********************************************************************************
*
*   Subroutine MENU_ENT_NAME (ENT, NAME, STAT)
*
*   Set the name of the menu entry ENT to NAME.  The name must not have been
*   previously set.
*
*   The entry name is the text shown to the user for the choice represented by
*   the menu entry.
}
procedure menu_ent_name (              {set name of menu entry, not already set}
  in out  ent: menu_ent_t;             {entry to set name of}
  in      name: univ string_var_arg_t; {menu entry name}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if ent.name_p <> nil then begin      {name was previously set ?}
    sys_stat_set (menu_subsys_k, menu_name_set_k, stat);
    sys_stat_parm_vstr (ent.name_p^, stat);
    sys_stat_parm_vstr (name, stat);
    return;
    end;
  sys_error_none (stat);

  menu_mem_string (                    {create name string in dynamic memory}
    ent.menu_p^.tree_p^,               {tree the new memory will belong to}
    name,                              {text of string to create}
    ent.name_p);                       {returned pointer to the new string}
  end;
{
********************************************************************************
*
*   Subroutine MENU_ENT_SHCUT (ENT, SHCUT, STAT)
*
*   Set the shortcut key for the menu entry ENT.  SHCUT is the 1-N number of the
*   name character to use for the shortcut.  For example, if the name is
*   "Abcdef" then SHCUT of 3 indicates "c" is the shortcut key.  The SHCUT value
*   of 0 indicates that this menu entry has no shortcut key.  That is also the
*   default when the menu entry was first created.
}
procedure menu_ent_shcut (             {set menu entry shortcut key}
  in out  ent: menu_ent_t;             {entry to set sort sequence number of}
  in      shcut: sys_int_machine_t;    {1-N shortcut char within name, 0 = none}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  sys_error_none (stat);               {init to no error}
  ent.shcut := shcut;                  {set the shortcut character number}
  end;
{
********************************************************************************
*
*   Subroutine MENU_ENT_SEQ (ENT, SEQ, STAT)
*
*   Set the sort sequence number of the menu entry ENT to SEQ.  The entry must
*   not already be added to the menu.
*
*   Entries are added to the menu in ascending sequence number order.  Sequence
*   numbers are otherwise arbitrary and chosen by the application.  The default
*   sequence number when the entry is created is the largest possible value.
*   That means the new entry will be added to the end of the menu unless its
*   sequence number is changed.
}
procedure menu_ent_seq (               {set menu entry sort seq, not already added to menu}
  in out  ent: menu_ent_t;             {entry to set sort sequence number of}
  in      seq: sys_int_machine_t;      {sort sequence number}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if menu_ent_added(ent) then begin    {entry already added to menu ?}
    sys_stat_set (menu_subsys_k, menu_added_seq_k, stat);
    sys_stat_parm_vstr (ent.name_p^, stat);
    return;
    end;
  sys_error_none (stat);

  ent.seq := seq;                      {set the new sort sequence number}
  end;
{
********************************************************************************
*
*   Subroutine MENU_ENT_ACT_SUB (ENT, STAT)
*
*   Set the action of the menu entry to bring up a subordinate menu.  An empty
*   menu is created and set as the action of the menu entry.
*
*   The menu entry action must not be set already.
}
procedure menu_ent_act_sub (           {set entry action to bring up submenu}
  in out  ent: menu_ent_t;             {menu entry to set action of}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if ent.entact <> menu_entact_unk_k then begin {action is already set ?}
    sys_stat_set (menu_subsys_k, menu_act_set_k, stat);
    return;
    end;
  sys_error_none (stat);

  ent.entact := menu_entact_submenu_k; {action is to bring up submenu}

  menu_mem_alloc (                     {allocate memory for sub-menu descriptor}
    ent.menu_p^.tree_p^,               {tree the new memory will belong to}
    sizeof(ent.submenu_p^),            {size of memory to allocate}
    ent.submenu_p);                    {returned pointer to the new memory}

  ent.submenu_p^.tree_p := ent.menu_p^.tree_p; {set pointer to tree menu is within}
  ent.submenu_p^.ent_par_p := addr(ent); {point to entry bringing up this submenu}
  ent.submenu_p^.ents_p := nil;        {init list of submenu entries to empty}
  end;
{
********************************************************************************
*
*   Subroutine MENU_ENT_ACT_RUN (ENT, CMD, STAT)
*
*   Set the action of menu entry ENT to run a command.  CMD is the command line
*   to run when the menu entry is activated.
*
*   The menu entry action must not be set already.
}
procedure menu_ent_act_run (           {set entry action to run command}
  in out  ent: menu_ent_t;             {menu entry to set action of}
  in      cmd: univ string_var_arg_t;  {the command to run when entry activated}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if ent.entact <> menu_entact_unk_k then begin {action is already set ?}
    sys_stat_set (menu_subsys_k, menu_act_set_k, stat);
    return;
    end;
  sys_error_none (stat);

  ent.entact := menu_entact_cmd_k;     {action is to run command}
  menu_mem_string (                    {create command string in dynamic memory}
    ent.menu_p^.tree_p^,               {tree the new memory will belong to}
    cmd,                               {text of string to create}
    ent.cmd_p);                        {returned pointer to the new string}
  ent.cmd_dir_p := nil;                {init to directory to run in not specified}
  end;
{
********************************************************************************
*
*   Subroutine MENU_ENT_RUN_DIR (ENT, DIR, STAT)
*
*   Set DIR as the directory to run the menu entry command in.  The menu entry
*   must have been previously set up to run a command, and the directory to run
*   that command in must not already be set.
}
procedure menu_ent_run_dir (           {set directory to run command in}
  in out  ent: menu_ent_t;             {menu entry to set action of}
  in      dir: univ string_var_arg_t;  {directory to run command in, empty = don't care}
  out     stat: sys_err_t);            {completion status}
  val_param;

begin
  if ent.entact <> menu_entact_cmd_k then begin {entry doesn't run command ?}
    sys_stat_set (menu_subsys_k, menu_stat_ncmd_k, stat);
    sys_stat_parm_vstr (ent.name_p^, stat);
    return;
    end;
  if ent.cmd_dir_p <> nil then begin   {directory previously set ?}
    sys_stat_set (menu_subsys_k, menu_stat_dirset_k, stat);
    sys_stat_parm_vstr (ent.name_p^, stat);
    return;
    end;
  sys_error_none (stat);

  if dir.len <= 0 then return;         {no dir specified, leave NIL pointer ?}

  menu_mem_string (                    {create directory name in dynamic memory}
    ent.menu_p^.tree_p^,               {tree the new memory will belong to}
    dir,                               {text of string to create}
    ent.cmd_dir_p);                    {returned pointer to the new string}
  end;
{
********************************************************************************
*
*   Subroutine MENU_ENT_ADD (ENT, STAT)
*
*   Add the menu entry ENT to the menu it is associated with.  Menu entries must
*   be added to a menu for them to be displayable, selected, and acted upon.
*
*   The entry will be added to the existing entries list by ascending sort
*   sequence number.  If the new entry has the same sequence number as an
*   existing list entry, then the new entry will be added to the list after the
*   existing entry.
*
*   Parameters of a menu entry generally become fixed after the entry is added
*   to its menu.
}
procedure menu_ent_add (               {add menu entry to its menu according to sequence}
  in out  ent: menu_ent_t;             {entry to add to its parent menu}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  ent_p: menu_ent_p_t;                 {pointer to current list entry}
  last_p: menu_ent_p_t;                {pointer to last list entry checked}

begin
  if menu_ent_added(ent) then begin    {entry already added to menu ?}
    sys_stat_set (menu_subsys_k, menu_added_add_k, stat);
    sys_stat_parm_vstr (ent.name_p^, stat);
    return;
    end;
  if ent.name_p = nil then begin       {name not set ?}
    sys_stat_set (menu_subsys_k, menu_add_nname_k, stat);
    return;
    end;
  if ent.entact = menu_entact_unk_k then begin {action not set ?}
    sys_stat_set (menu_subsys_k, menu_add_nact_k, stat);
    sys_stat_parm_vstr (ent.name_p^, stat);
    return;
    end;
  sys_error_none (stat);

  last_p := nil;                       {init to no previous list entry checked}
  ent_p := ent.menu_p^.ents_p;         {init to first list entry}
  while ent_p <> nil do begin          {scan the list of existing menu entries}
    if ent_p^.seq > ent.seq then exit; {link new entry before this one ?}
    last_p := ent_p;                   {save pointer to last existing entry checked}
    ent_p := ent_p^.next_p;            {advance to next existing list entry}
    end;                               {back to check new list entry}

  if last_p = nil
    then begin                         {link new entry to start of list}
      ent.prev_p := nil;               {set backward link}
      ent.next_p := ent.menu_p^.ents_p; {set forward link}
      ent.menu_p^.ents_p := addr(ent); {update start of list pointer}
      end
    else begin                         {link after entry pointed to by LAST_P}
      ent.prev_p := last_p;            {set backward link}
      ent.next_p := last_p^.next_p;    {set forward link}
      last_p^.next_p := addr(ent);     {update forward link in previous entry}
      end
    ;
  if ent.next_p <> nil then begin      {there is a following entry ?}
    ent.next_p^.prev_p := addr(ent);   {update backward link in next entry}
    end;
  end;
{
********************************************************************************
*
*   Subroutine MENU_ENT_N (MENU, N, ENT_P)
*
*   Find the Nth entry in the menu MENU.  Menu entries are numbered starting
*   with 1.  ENT_P is returned pointing to the Nth entry, or NIL if there is no
*   Nth entry in MENU.
}
procedure menu_ent_n (                 {find Nth menu entry}
  in      menu: menu_t;                {menu to find entry within}
  in      n: sys_int_machine_t;        {1-N number of entry to find}
  out     ent_p: menu_ent_p_t);        {returned pointer to Nth entry, NIL if not exist}
  val_param;

var
  ii: sys_int_machine_t;

begin
  ent_p := menu.ents_p;                {init pointer to first entry}
  ii := 1;                             {init number of entry pointed to by ENT_P}

  while ent_p <> nil do begin          {sequentially scan the list of entries}
    if ii = n then return;             {this is the Nth entry ?}
    ent_p := ent_p^.next_p;            {no, advance to next}
    ii := ii + 1;                      {update sequential number for new entry}
    end;
  end;
{
********************************************************************************
*
*   Subroutine MENU_ENT_FIND (MENU, NAME, ENT_P)
*
*   Find the entry of name NAME within the menu MENU.  ENT_P is returned
*   pointing to the entry if found, NIL otherwise.
}
procedure menu_ent_find (              {find entry of particular name}
  in      menu: menu_t;                {menu to look for entry in}
  in      name: univ string_var_arg_t; {entry name to look for}
  out     ent_p: menu_ent_p_t);        {points to found entry, NIL for not found}
  val_param;

begin
  ent_p := menu.ents_p;                {init to first entry in list}

  while ent_p <> nil do begin          {scan the menu entries}
    if string_equal(ent_p^.name_p^, name) then begin {found it ?}
      return;
      end;
    ent_p := ent_p^.next_p;            {to next entry in the menu}
    end;
  end;
