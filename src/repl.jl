
# various parts of this are adapted from Cxx.jl (MIT Expat License):
#   Copyright (c) 2013-2016: Keno Fischer and other contributors



import REPL
import REPL: LineEdit, REPLCompletions

struct PolymakeCompletions <: LineEdit.CompletionProvider end

function shell_execute_print(s::String)
   res = shell_execute(s)
   if res[1]
      print(Base.stdout, res[2])
      print(Base.stderr, res[3])
      if !isempty(res[4])
          error(res[4])
      end
   else
      if !isempty(res[4])
          error(res[4])
      else
          error("polymake: incomplete statement")
      end
   end
end

function LineEdit.complete_line(c::PolymakeCompletions, s)
   partial = REPL.beforecursor(LineEdit.buffer(s))
   full = LineEdit.input_string(s)
   res = shell_complete(full)
   offset = res[1]
   proposals = res[2:end]
   return proposals, partial[end-offset+1:end], size(proposals,1) > 0
end


function CreatePolymakeREPL(; prompt = "polymake > ", name = :pm, repl = Base.active_repl, main_mode = repl.interface.modes[1])
   mirepl = isdefined(repl,:mi) ? repl.mi : repl
   # Setup polymake panel
   panel = LineEdit.Prompt(prompt;
        # Copy colors from the prompt object
        prompt_prefix=Base.text_colors[:yellow],
        prompt_suffix=Base.text_colors[:white],
        on_enter = REPL.return_callback)
        #on_enter = s->isExpressionComplete(C,push!(copy(LineEdit.buffer(s).data),0)))

   panel.on_done = REPL.respond(repl,panel; pass_empty = false) do line
       if !isempty(line)
           :(Polymake.shell_execute_print($line) )
       else
           :(  )
       end
   end

   panel.complete = PolymakeCompletions()

   main_mode == mirepl.interface.modes[1] &&
       push!(mirepl.interface.modes,panel)

   # 0.7 compat
   if isdefined(main_mode, :repl)
       panel.repl = main_mode.repl
   end

   hp = main_mode.hist
   hp.mode_mapping[name] = panel
   panel.hist = hp

   search_prompt, skeymap = LineEdit.setup_search_keymap(hp)
   mk = REPL.mode_keymap(main_mode)

   b = Dict{Any,Any}[skeymap, mk, LineEdit.history_keymap, LineEdit.default_keymap, LineEdit.escape_defaults]
   panel.keymap_dict = LineEdit.keymap(b)

   panel
end

global function run_polymake_repl(; prompt = "polymake > ", name = :pm, key = '$')
   repl = Base.active_repl
   mirepl = isdefined(repl,:mi) ? repl.mi : repl
   main_mode = mirepl.interface.modes[1]

   panel = CreatePolymakeREPL(; prompt=prompt, name=name, repl=repl)

    # Install this mode into the main mode
    pm_keymap = Dict{Any,Any}(
        key => function (s,args...)
            if isempty(s) || position(LineEdit.buffer(s)) == 0
                buf = copy(LineEdit.buffer(s))
                LineEdit.transition(s, panel) do
                    LineEdit.state(s, panel).input_buffer = buf
                end
            else
                LineEdit.edit_insert(s,key)
            end
        end
    )
    main_mode.keymap_dict = LineEdit.keymap_merge(main_mode.keymap_dict, pm_keymap);
    nothing
end
