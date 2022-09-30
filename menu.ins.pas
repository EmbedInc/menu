{   Public include file for the MENU library.  This library is used to present a
*   tree-structured menu of choices to the user.
}
const
  menu_subsys_k = -76;                 {MENU library susbystem ID}

type
  menu_tree_p_t = ^menu_tree_t;
  menu_p_t = ^menu_t;
  menu_ent_p_t = ^menu_ent_t;

  menu_entact_k_t = (                  {ID for what happens on menu entry activation}
    menu_entact_unk_k,                 {unknown or not set yet}
    menu_entact_submenu_k,             {brings up submenu}
    menu_entact_cmd_k);                {runs command}

  menu_ent_t = record                  {one entry in a menu node}
    prev_p: menu_ent_p_t;              {to previous sequential entry, NIL at first}
    next_p: menu_ent_p_t;              {to next sequential entry, NIL at last}
    menu_p: menu_p_t;                  {to menu this entry is contained in}
    name_p: string_var_p_t;            {to name shown to user for this entry}
    seq: sys_int_machine_t;            {sort sequence number}
    entact: menu_entact_k_t;           {type of action on activation}
    case menu_entact_k_t of
menu_entact_submenu_k: (               {activation brings up submenu}
      submenu_p: menu_p_t;             {to submenu to show on activation}
      );
menu_entact_cmd_k: (                   {activation runs command}
      cmd_p: string_var_p_t;           {command to run on activation}
      );
    end;

  menu_t = record                      {menu at one tree node}
    tree_p: menu_tree_p_t;             {to state for whole menu tree}
    ent_par_p: menu_ent_p_t;           {to entry in parent menu, NIL at top}
    ents_p: menu_ent_p_t;              {to list of entries in this menu}
    end;

  menu_tree_t = record                 {state for a whole menu tree}
    mem_p: util_mem_context_p_t;       {to context for all dynamic memory}
    tnam_p: string_var_p_t;            {to treename of menu file}
    menu_p: menu_p_t;                  {to top menu of tree}
    end;
{
*   Routines.
}
procedure menu_file_read (             {read menu tree data from file}
  in      fnam: univ string_var_arg_t; {name of menu file}
  in out  mem: util_mem_context_t;     {parent mem context, will make subordinate}
  out     tree_p: menu_tree_p_t;       {returned pointer to menu tree}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure menu_file_write (            {write menu tree data to file}
  in      tree: menu_tree_t;           {menu tree to write}
  in      fnam: univ string_var_arg_t; {name of menu file}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure menu_mem_alloc (             {allocate memory, can't individually deallocate}
  in out  tree: menu_tree_t;           {tree memory will belong to}
  in      sz: sys_int_adr_t;           {amount of memory to allocate}
  out     new_p: univ_ptr);            {pnt to new mem, will be deallcated when tree del}
  val_param; extern;

procedure menu_tree_create (           {create new menu tree and top level menu}
  in out  mem: util_mem_context_t;     {parent mem context, will make subordinate}
  out     tree_p: menu_tree_p_t);      {returned pointer to new menu tree}
  val_param; extern;

procedure menu_tree_delete (           {delete menu tree, deallocate all resources}
  in out  tree_p: menu_tree_p_t);      {pointer to menu tree, returned NIL}
  val_param; extern;
