{   Program MENUADD
}
program menuadd;
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

const
  max_msg_args = 2;                    {max arguments we can pass to a message}

type
  name_p_t = ^name_t;
  name_t = record                      {one name in hierarchy}
    name: string_var80_t;              {menu entry name}
    seq: sys_int_conv32_t;             {sort sequence number}
    shcut: sys_int_machine_t;          {1-N name char is shorcut, 0 = none}
    next_p: name_p_t;                  {to next lower level in menu tree}
    end;

var
  fnam:                                {menu file name}
    %include '(cog)lib/string_treename.ins.pas';
  tree_p: menu_tree_p_t;               {points to whole menu tree}
  name_first_p: name_p_t;              {to hierarchy of menu entry names}
  name_last_p: name_p_t;               {to last menu entry name in list}
  rundir:                              {directory to run the command in}
    %include '(cog)lib/string_treename.ins.pas';
  command:                             {command to run when leaf-node entry selected}
    %include '(cog)lib/string8192.ins.pas';
  name_p: name_p_t;                    {points to current names list entry}
  menu_p: menu_p_t;                    {points to current menu in hierarchy}
  ent_p: menu_ent_p_t;                 {points to current entry within menu}

  opt:                                 {upcased command line option}
    %include '(cog)lib/string80.ins.pas';
  parm:                                {command line option parameter}
    %include '(cog)lib/string_treename.ins.pas';
  pick: sys_int_machine_t;             {number of token picked from list}
  msg_parm:                            {references arguments passed to a message}
    array[1..max_msg_args] of sys_parm_msg_t;
  stat: sys_err_t;                     {completion status code}

label
  next_opt, err_parm, parm_bad, done_opts,
  next_name;
{
********************************************************************************
*
*   Start of main routine.
}
begin
{
*   Get the fixed command line option.
}
  string_cmline_init;                  {init for reading the command line}

  string_cmline_token (fnam, stat);    {get the menu file name}
  sys_error_abort (stat, '', '', nil, 0);

  menu_file_read (                     {read the menu file, build tree in memory}
    fnam,                              {menu file name}
    util_top_mem_context,              {parent mem context, will make subordinate}
    tree_p,                            {returned pointing to menu tree description}
    stat);
  if file_not_found(stat)
    then begin                         {menu file doesn't exist, same as empty}
      menu_tree_create (               {create empty menu tree}
        util_top_mem_context,          {parnet mem context, will make subordinate}
        tree_p);                       {returned pointer to new menu tree}
      menu_tree_name (tree_p^, fnam);  {set name of file to save menu tree in}
      end
    else begin                         {other than not-found error}
      sys_error_abort (stat, '', '', nil, 0);
      end
    ;

  name_first_p := nil;                 {init to no menu entry names specified}
  name_last_p := nil;
{
*   Back here each new command line option.
}
next_opt:
  string_cmline_token (opt, stat);     {get next command line option name}
  if string_eos(stat) then goto done_opts; {exhausted command line ?}
  sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
  string_upcase (opt);                 {make upper case for matching list}
  string_tkpick80 (opt,                {pick command line option name from list}
    '-N -SH -IN -CMD',
    pick);                             {number of keyword picked from list}
  case pick of                         {do routine for specific option}
{
*   -N seq name
}
1: begin
  menu_mem_alloc (tree_p^, sizeof(name_p^), name_p); {alloc mem for new name}
  name_p^.name.max := size_char(name_p^.name.str); {init fixed fields}

  string_cmline_token_int (name_p^.seq, stat); {get sort sequence number}
  if sys_error(stat) then goto parm_bad;
  string_cmline_token (name_p^.name, stat); {get menu entry name}
  if sys_error(stat) then goto parm_bad;

  name_p^.shcut := 0;                  {init to no shortcut character}
  name_p^.next_p := nil;               {init to last name in list}

  if name_last_p = nil
    then begin                         {no previous names list entry}
      name_first_p := name_p;
      end
    else begin                         {link to after last entry}
      name_last_p^.next_p := name_p;
      end
    ;
  name_last_p := name_p;               {update pointer to last names entry}
  end;
{
*   -SH n
}
2: begin
  if name_last_p = nil then begin      {there is no current name to apply shortcut to ?}
    writeln ('No name to apply shortcut to.');
    sys_bomb;
    end;
  string_cmline_token_int (name_last_p^.shcut, stat); {get the shortcut char number}
  end;
{
*   -IN dir
}
3: begin
  string_cmline_token (rundir, stat);
  end;
{
*   -CMD command
}
4: begin
  while true do begin                  {loop over the remaining command line tokens}
    string_cmline_token (parm, stat);
    if string_eos(stat) then goto done_opts;
    sys_error_abort (stat, 'string', 'cmline_opt_err', nil, 0);
    string_append_token (command, parm); {add this token to command to run}
    end;
  end;
{
*   Unrecognized command line option.
}
otherwise
    string_cmline_opt_bad;             {unrecognized command line option}
    end;                               {end of command line option case statement}

err_parm:                              {jump here on error with parameter}
  string_cmline_parm_check (stat, opt); {check for bad command line option parameter}
  goto next_opt;                       {back for next command line option}

parm_bad:                              {jump here on got illegal parameter}
  string_cmline_reuse;                 {re-read last command line token next time}
  string_cmline_token (parm, stat);    {re-read the token for the bad parameter}
  sys_msg_parm_vstr (msg_parm[1], parm);
  sys_msg_parm_vstr (msg_parm[2], opt);
  sys_message_bomb ('string', 'cmline_parm_bad', msg_parm, 2);

done_opts:                             {done with all the command line options}
{
*   Done reading the command line.
}
  if name_first_p = nil then begin
    writeln ('No menu entry names specified.');
    sys_bomb;
    end;
  if command.len <= 0 then begin
    writeln ('No command specified for when menu entry is selected.');
    sys_bomb;
    end;
{
*   Create the new menu entries, or verify they already exist.
}
  name_p := name_first_p;              {init to highest level name path component}
  menu_p := tree_p^.menu_p;            {init pointer to menu this path component in}

  while name_p <> nil do begin         {loop over name path components, global to local}
    menu_ent_find (menu_p^, name_p^.name, ent_p); {look for existing entry with this name}

    if ent_p <> nil then begin         {entry of this name already exists ?}
      if name_p^.next_p <> nil
        then begin                     {this name is for submenu}
          if ent_p^.entact <> menu_entact_submenu_k then begin {existing isn't submenu ?}
            writeln ('Existing entry "', ent_p^.name_p^.str:ent_p^.name_p^.len,
              '" is not a submenu.');
            sys_bomb;
            end;
          goto next_name;              {re-use existing submenu entry}
          end
        else begin                     {this name is for leaf-node entry}
          if                           {check for mismatch with existing entry}
              (ent_p^.shcut <> name_p^.shcut) or {shortcut char mismatch ?}
              (ent_p^.seq <> name_p^.seq) or {sort sequence mismatch ?}
              (ent_p^.entact <> menu_entact_cmd_k) or else {existing ent not command ?}
              (not string_equal (ent_p^.cmd_p^, command)) {not the same command ?}
              then begin
            writeln ('Menu entry "', name_p^.name.str:name_p^.name.len,
              '" does not match existing entry.');
            sys_bomb;
            end;
          goto next_name;              {re-use existing menu entry}
          end
        ;
      end;

    menu_ent_new (menu_p^, ent_p);     {create new blank menu entry}
    menu_ent_name (ent_p^, name_p^.name, stat); {set entry name}
    sys_error_abort (stat, '', '', nil, 0);
    menu_ent_seq (ent_p^, name_p^.seq, stat); {set sort sequence number}
    sys_error_abort (stat, '', '', nil, 0);
    menu_ent_shcut (ent_p^, name_p^.shcut, stat); {set shortcut character}
    sys_error_abort (stat, '', '', nil, 0);
    if name_p^.next_p <> nil
      then begin                       {this name is for a submenu}
        menu_ent_act_sub (ent_p^, stat); {make it a submenu}
        sys_error_abort (stat, '', '', nil, 0);
        end
      else begin                       {this name is for leaf-node entry}
        menu_ent_act_run (ent_p^, command, stat);
        sys_error_abort (stat, '', '', nil, 0);
        end
      ;
    menu_ent_add (ent_p^, stat);       {add new entry to list for this menu}
    sys_error_abort (stat, '', '', nil, 0);

next_name:                             {advance to next name in menu entries hierarchy}
    name_p := name_p^.next_p;          {to next name in hierarchy}
    if name_p = nil then exit;         {done with the names hierarchy ?}
    menu_p := ent_p^.submenu_p;        {to the submenu represented by this name}
    end;                               {back to handle next lower name path component}

  menu_file_write (tree_p^, stat);     {write modified tree back to file}
  sys_error_abort (stat, '', '', nil, 0);
  end.
