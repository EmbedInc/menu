{   Memory management.
}
module menu_mem;
define menu_mem_alloc;
define menu_mem_string;
%include 'menu2.ins.pas';
{
********************************************************************************
*
*   Subroutine MENU_MEM_ALLOC (TREE, SZ, NEW_P)
*
*   Allocate memory for use with a menu tree.  The new memory can not be
*   separately deallocated.  It will be deallocated with the tree is deleted.
*
*   TREE is the menu tree the memory will be used with.  SZ is the size of the
*   new memory to allocate.  NEW_P is returned pointing to the start of the new
*   memory.
}
procedure menu_mem_alloc (             {allocate memory, can't individually deallocate}
  in out  tree: menu_tree_t;           {tree memory will belong to}
  in      sz: sys_int_adr_t;           {amount of memory to allocate}
  out     new_p: univ_ptr);            {pnt to new mem, will be deallcated when tree del}
  val_param;

var
  stat: sys_err_t;

begin
  util_mem_grab (                      {allocate the memory}
    sz,                                {size of the new memory}
    tree.mem_p^,                       {memory context to allocate under}
    false,                             {not make individually deallocatable}
    new_p);                            {returned pointer to the new memory}

  if new_p = nil then begin            {didn't get the requested memory}
    discard( util_mem_grab_err (new_p, sz, stat) ); {set error status}
    sys_error_abort (stat, '', '', nil, 0); {bomb program with error}
    end;
  end;
{
********************************************************************************
*
*   Subroutine MENU_MEM_STRING (TREE, INSTR, STR_P)
*
*   Put a fixed string in new memory.  INSTR is the text of the string that will
*   be created.  TREE is the menus tree under which the new dynamic memory will
*   be allocated.  STR_P is returned pointing to the new string.
*
*   The new string can not be individually deallocated.  It will only be
*   deallocated when the menus tree TREE is deleted.
}
procedure menu_mem_string (            {allocate and set fixed string}
  in out  tree: menu_tree_t;           {tree memory will belong to}
  in      instr: univ string_var_arg_t; {string text}
  out     str_p: string_var_p_t);      {returned pointer to filled-in string}
  val_param;

begin
  string_alloc (                       {alloc new mem for string, init string}
    instr.len,                         {length of the new string}
    tree.mem_p^,                       {context to allocate new memory under}
    false,                             {will not individually dealloc new mem}
    str_p);                            {returned pointer to new string}
  string_copy (instr, str_p^);         {fill in content of the new string}
  end;
