{   Memory management.
}
module menu_mem;
define menu_mem_alloc;
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
