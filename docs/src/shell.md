# Polymake REPL

This section shows how to use the embedded polymake shell. For more details on the polymake shell please see the [polymake documentation](https://polymake.org/doku.php/user_guide/shell).

To access it type the dollar `$` symbol in an empty line or call `Polymake.prompt()`. The julia prompt should transition to `polymake (common) >`, indicating the currently active polymake application.

There are a few differences to the proper polymake shell:
- For technical reasons the default application is `common` instead of `polytope`. Thus most calls from other applications should be prefixed with the corresponding application, e.g. `$c = polytope::cube(3)`. The currently active application can also be changed with `application "someapplication";` (this will be indicated in the prompt).
- Incomplete input will be executed (and fail) immediately on pressing return. To enter multi-line input please use `Alt+Enter`.

## Passing data back and forth

Objects that are known to polymake can be assigned to and retrieved from the special module `Polymake.Shell`. The variable name in that module corresponds to a polymake shell variable of that name.

```julia
julia> c = polytope.cube(3);

julia> Polymake.Shell.cc = c;

polymake (common) > print $cc->F_VECTOR;
8 12 6

julia> Polymake.Shell.cc.H_VECTOR
pm::Vector<pm::Integer>
1 5 5 1
```

!!! warning
    This feature is considered experimental!
    There are very little checks on the data being passed around, so please avoid passing temporaries or incompatible objects.
