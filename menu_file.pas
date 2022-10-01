{   Routines to read/write menu trees from/to files.
}
module menu_file;
define menu_file_read;
%include 'menu2.ins.pas';
%include 'hier.ins.pas';

procedure menu_file_read_entry (       {read and processes subcommands for an entry}
  in out  hrd: hier_read_t;            {hierarchy reading state}
  in out  ent: menu_ent_t;             {entry to fill in with data from subcommands}
  out     stat: sys_err_t);            {completion status, initialized to no err}
  val_param; internal; forward;

procedure menu_file_read_ents (        {read menu entries from hierarchy file}
  in out  hrd: hier_read_t;            {hierarchy reading state}
  in out  menu: menu_t;                {menu to read entries of}
  out     stat: sys_err_t);            {completion status, initialized to no err}
  val_param; internal; forward;
{
********************************************************************************
*
*   Local subroutine MENU_FILE_READ_ENTRY (HRD, ENT, STAT)
*
*   Read the subcommands of an ENTRY command, and fill in data about the entry
*   ENT accordingly.
}
procedure menu_file_read_entry (       {read and processes subcommands for an entry}
  in out  hrd: hier_read_t;            {hierarchy reading state}
  in out  ent: menu_ent_t;             {entry to fill in with data from subcommands}
  out     stat: sys_err_t);            {completion status, initialized to no err}
  val_param; internal;

var
  cmd: string_var8192_t;               {command to run on menu activation}

begin
  cmd.max := size_char(cmd.str);       {init local var string}

  while hier_read_line (hrd, stat) do begin {loop over commands}
    case hier_read_keyw_pick (hrd, 'SEQ MENU RUN', stat) of
{
*   SEQ number
}
1: begin
  hier_read_int (hrd, ent.seq, stat);  {get the sort sequence number}
  if sys_error(stat) then return;
  if not hier_read_eol (hrd, stat)     {no more command parameters allowed}
    then return;
  end;
{
*   MENU
}
2: begin
  if not hier_read_eol (hrd, stat)     {no command parameters allowed}
    then return;
  menu_ent_act_sub (ent, stat);        {set menu entry action to be submenu}
  if sys_error(stat) then return;
  menu_file_read_ents (hrd, ent.submenu_p^, stat); {build the submenu}
  if sys_error(stat) then return;
  end;
{
*   RUN command
}
3: begin
  hier_read_string (hrd, cmd);         {rest of line is the command}
  menu_ent_act_run (ent, cmd, stat);   {set menu action to run the command}
  if sys_error(stat) then return;
  end;
{
*   Unrecognized command.
}
otherwise
      return;                          {return with error}
      end;                             {end of command cases}
    end;                               {back to get next command}
  end;
{
********************************************************************************
*
*   Local subroutine MENU_FILE_READ_ENTS (HRD, MENU, STAT)
*
*   Read the definition of the menu MENU from the file open for hierarchical
*   reading on HRD.
*
*   This routine calls itself recursively to read sub-menus.
}
procedure menu_file_read_ents (        {read menu entries from hierarchy file}
  in out  hrd: hier_read_t;            {hierarchy reading state}
  in out  menu: menu_t;                {menu to read entries of}
  out     stat: sys_err_t);            {completion status, initialized to no err}
  val_param; internal;

var
  name: string_var80_t;                {menu entry name}
  ent_p: menu_ent_p_t;                 {pointer to menu entry being built}

begin
  name.max := size_char(name.str);     {init local var string}

  while hier_read_line (hrd, stat) do begin {loop over commands}
    case hier_read_keyw_pick (hrd, 'ENTRY', stat) of
{
*   ENTRY name
}
1: begin
  if not hier_read_tk_req (hrd, name, stat) {get menu entry name}
    then return;
  if not hier_read_eol (hrd, stat)     {no more command parameters allowed}
    then return;

  menu_ent_new (menu, ent_p);          {create the new menu entry}
  menu_ent_name (ent_p^, name, stat);  {set the entry name}
  if sys_error(stat) then return;

  hier_read_block_start (hrd);         {down into ENTRY subcommands}
  menu_file_read_entry (hrd, ent_p^, stat); {process ENTRY subcommands}
  if sys_error(stat) then return;

  menu_ent_add (ent_p^, stat);         {add finished entry to this menu}
  if sys_error(stat) then return;
  end;
{
*   Unrecognized command.
}
otherwise
      return;                          {return with error}
      end;                             {end of command cases}
    end;                               {back to get next command}
  end;
{
********************************************************************************
*
*   Subroutine MENU_FILE_READ (FNAM, MEM, TREE_P, STAT)
*
*   Read a menu tree definition from a file, and build the corresponding data
*   structures in memory.
*
*   FNAM is the name of the file to read from.  The mandatory ".menu" suffix may
*   be omitted from FNAM.
*
*   MEM is the parent memory context.  A subordinate memory context will be
*   created exclusively for all new dynamic memory assciated with the menu tree.
*
*   TREE_P is returned pointing to the resulting menu tree.  When done with the
*   tree, the application should call MENU_TREE_DELETE.  This will deallocate
*   all dynamic memory associated with the tree, including the top tree
*   structure itself and its private memory context.
}
procedure menu_file_read (             {read menu tree data from file}
  in      fnam: univ string_var_arg_t; {name of menu file}
  in out  mem: util_mem_context_t;     {parent mem context, will make subordinate}
  out     tree_p: menu_tree_p_t;       {returned pointer to menu tree}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  hrd: hier_read_t;                    {hierarchy reading state}
  stat2: sys_err_t;                    {to avoid corrupting STAT}

label
  abort;

begin
  tree_p :=  nil;                      {init to tree not created}
  hier_read_open (fnam, '.menu', hrd, stat); {open input file}
  if sys_error(stat) then return;

  menu_tree_create (mem, tree_p);      {create empty menu tree}
  menu_mem_string (                    {save source file full name}
    tree_p^, hrd.conn.tnam, tree_p^.tnam_p);

  menu_file_read_ents (                {read top level menu and submenus}
    hrd, tree_p^.menu_p^, stat);
  if sys_error(stat) then goto abort;  {error reading file ?}

  hier_read_close (hrd, stat);         {close the input file}
  return;                              {normal return point}

abort:                                 {file open, tree created, STAT indicates err}
  menu_tree_delete (tree_p);           {delete the tree, deallocate resources}
  hier_read_close (hrd, stat2);        {close connection to input file}
  end;
