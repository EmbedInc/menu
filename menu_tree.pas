{   Routines that manipulate menu tree descriptors.
}
module menu_tree;
define menu_tree_create;
define menu_tree_delete;
define menu_tree_name;
%include 'menu2.ins.pas';
{
********************************************************************************
*
*   Subroutine MENU_TREE_CREATE (MEM, TREE_P)
*
*   Create a menu tree and the top level menu.
*
*   MEM is the parent memory context.  A subordinate context will be created.
*   All dynamic memory for the tree will be allocated under the subordinate
*   context.
*
*   TREE_P is returned pointing to the new menu tree descriptor.  The tree will
*   be initialized to default or benign values to the extent possible.
}
procedure menu_tree_create (           {create new menu tree descriptor}
  in out  mem: util_mem_context_t;     {parent mem context, will make subordinate}
  out     tree_p: menu_tree_p_t);      {returned pointer to new menu tree}
  val_param;

var
  mem_p: util_mem_context_p_t;         {points to new mem context}

begin
  util_mem_context_get (mem, mem_p);   {make mem context for the menu tree}
  util_mem_grab (                      {allocate new menu tree descriptor}
    sizeof(tree_p^), mem_p^, false, tree_p);

  tree_p^.mem_p := mem_p;              {save pointer to memory context}
  tree_p^.tnam_p := nil;               {init to not associated with a file}

  menu_mem_alloc (                     {allocate memory for top level menu}
    tree_p^, sizeof(tree_p^.menu_p^), tree_p^.menu_p);
  tree_p^.menu_p^.tree_p := tree_p;    {point back to the tree}
  tree_p^.menu_p^.ent_par_p := nil;    {top level menu, no parent menu entry}
  tree_p^.menu_p^.ents_p := nil;       {init list of entries to empty}
  end;
{
********************************************************************************
*
*   Subroutine MENU_TREE_DELETE (TREE_P)
*
*   Delete the top level menu tree pointed to by TREE_P, and release any system
*   resources associated with it.  TREE_P is returned NIL.
}
procedure menu_tree_delete (           {delete menu tree, deallocate all resources}
  in out  tree_p: menu_tree_p_t);      {pointer to menu tree, returned NIL}
  val_param;

var
  mem_p: util_mem_context_p_t;         {saved pointer to menu tree mem context}

begin
  mem_p := tree_p^.mem_p;              {save pointer to menu tree mem context}
  util_mem_context_del (mem_p);        {deallocate all the menu tree memory}
  tree_p := nil;                       {return menu tree pointer invalid}
  end;
{
********************************************************************************
*
*   Subroutine MENU_TREE_NAME (TREE, NAME)
*
*   Set the name of the file associated with a menu tree.  TREE is the existing
*   menu tree, and must not already have its file name set.
*
*   NAME is the file name.  It will be exapnded to its full treename, with the
*   mandatory ".menu" suffix.
}
procedure menu_tree_name (             {set menu tree file name}
  in out  tree: menu_tree_t;           {the menu tree}
  in      name: univ string_var_arg_t); {file name}
  val_param;

var
  fnam: string_treename_t;             {file name with suffix}
  tnam: string_treename_t;             {full treename}

begin
  fnam.max := size_char(fnam.str);     {init local var strings}
  tnam.max := size_char(tnam.str);

  if tree.tnam_p <> nil then begin
    writeln ('Menu tree file name already set.');
    sys_bomb;
    end;

  string_fnam_extend (                 {make file name guaranteed to have suffix}
    name, '.menu'(0), fnam);
  string_treename (fnam, tnam);        {make full menu file treename}
  menu_mem_string (                    {alloc and create string}
    tree,                              {menu tree to allocate memory for}
    tnam,                              {string content}
    tree.tnam_p);                      {returned pointer to the new string}
  end;
