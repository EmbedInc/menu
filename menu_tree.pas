{   Routines that manipulate menu tree descriptors.
}
module menu_tree;
define menu_tree_create;
define menu_tree_delete;
%include 'menu2.ins.pas';
{
********************************************************************************
*
*   Subroutine MENU_TREE_CREATE (MEM, TREE_P)
*
*   Create a new top level menu tree.  MEM is the parent memory context.  A
*   subordinate context will be created.  All dynamic memory for the tree will
*   be allocated under the subordinate context.  TREE_P is returned pointing to
*   the new menu tree descriptor.  The tree will be initialized to default or
*   benign values to the extent possible.
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
  tree_p^.menu_p := nil;               {init to no top level menu}
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
