
# various parts of this are adapted from Cxx.jl (MIT Expat License):
#   Copyright (c) 2013-2016: Keno Fischer and other contributors



import REPL
import REPL: LineEdit, REPLCompletions

struct ShellHelper end
const Shell = ShellHelper()

Base.getproperty(::ShellHelper, name::Symbol) = Polymake.call_function(:User, :get_shell_scalar, String(name))

Base.setproperty!(::ShellHelper, name::Symbol, value) = Polymake.call_function(:User, :set_shell_scalar, String(name), value)

const polymakerepl = Ref{LineEdit.Prompt}()

struct PolymakeCompletions <: LineEdit.CompletionProvider end

_color(str, magic_number=69) = Base.text_colors[(sum(Int, str) + magic_number) % 0xff]
_get_app() = Polymake.get_current_app()
_get_prompt_prefix(str = _get_app()) = _color(str)
_get_prompt(app = _get_app()) = "polymake ($app) > "
_get_prompt_suffix() = Base.text_colors[:default]

function shell_execute_print(s::String, panel::LineEdit.Prompt)
   res = convert(Tuple{Bool, String, String, String}, _shell_execute(s))
   app = _get_app()
   panel.prompt=_get_prompt(app)
   panel.prompt_prefix=_get_prompt_prefix(app)

   if res[1]
      print(Base.stdout, res[2])
      # make sure there is a newline in between if both are nonempty
      if !isempty(res[2]) && !isempty(res[3]) && last(res[2]) != '\n'
         println()
      end
      print(Base.stderr, res[3])
      if !isempty(res[4])
          error(res[4])
      end
   else
      if !isempty(res[4])
          error(res[4])
      else
          error("polymake: incomplete statement, try Alt+Enter for multi-line input")
      end
   end
end

function LineEdit.complete_line(c::PolymakeCompletions, s; kwargs...)
   try
      partial = REPL.beforecursor(LineEdit.buffer(s))
      full = LineEdit.input_string(s)
      pmres = shell_complete(full)
      res = convert(Tuple{Int, Base.Array{String}}, pmres)
      offset = first(res)
      proposals = res[2]
      return proposals, partial[end-offset+1:end], size(proposals,1) > 0
   catch
      @debug "error completing polymake line" exception=current_exceptions()
      return String[], "", true
   end
end


function CreatePolymakeREPL(; prompt = _get_prompt(), name = :pm, repl = Base.active_repl, main_mode = repl.interface.modes[1])
   mirepl = isdefined(repl,:mi) ? repl.mi : repl
   # Setup polymake panel
   panel = LineEdit.Prompt(prompt;
        # Copy colors from the prompt object
        prompt_prefix=_get_prompt_prefix(),
        prompt_suffix=_get_prompt_suffix(),
        on_enter = (_) -> true,
        sticky = true)
        #on_enter = s->isExpressionComplete(C,push!(copy(LineEdit.buffer(s).data),0)))

   panel.on_done = REPL.respond(repl,panel; pass_empty = false) do line
       if !isempty(line)
           :( Polymake.shell_execute_print($line, $panel) )
       else
          :(  )
       end
   end

   panel.complete = PolymakeCompletions()

   main_mode == mirepl.interface.modes[1] &&
       push!(mirepl.interface.modes,panel)

   hp = main_mode.hist
   hp.mode_mapping[name] = panel
   panel.hist = hp

   search_prompt, skeymap = LineEdit.setup_search_keymap(hp)
   mk = REPL.mode_keymap(main_mode)

   b = Dict{Any,Any}[skeymap, mk, LineEdit.history_keymap, LineEdit.default_keymap, LineEdit.escape_defaults]
   panel.keymap_dict = LineEdit.keymap(b)

   panel
end

function run_polymake_repl(repl = Base.active_repl;
                     prompt = _get_prompt(),
                     name = :pm,
                     key = '$',
                     nothrow = false)
   try
      repl isa REPL.LineEditREPL || error("only minimal REPL active, cannot add REPL mode, check DEPOT_PATH for stdlib path")
      mirepl = isdefined(repl,:mi) ? repl.mi : repl
      # skip repl init if it is not fully loaded
      isdefined(mirepl, :interface) && isdefined(mirepl.interface, :modes) || return nothing
      main_mode = mirepl.interface.modes[1]

      panel = CreatePolymakeREPL(; prompt=prompt, name=name, repl=repl)
      global polymakerepl[] = panel

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
      main_mode.keymap_dict = LineEdit.keymap_merge(main_mode.keymap_dict, pm_keymap)
   catch ex
      if nothrow
         # failing to initialize the repl should not be fatal during initialization
         @warn ex
      else
         rethrow()
      end
   end
end

function try_init_polymake_repl()
   if isdefined(Base, :active_repl)
      if Base.active_repl isa REPL.LineEditREPL
         run_polymake_repl(nothrow=true)
      end
   else
      atreplinit() do repl
         if isinteractive() && repl isa REPL.LineEditREPL
            run_polymake_repl(nothrow=true)
         end
      end
   end
end

function prompt()
   if !isassigned(polymakerepl)
      run_polymake_repl()
   end
   mist = Base.active_repl.mistate
   pmr = polymakerepl[]
   # hide prompt to avoid duplicate prompt printout during transition
   pmr.prompt=""
   REPL.transition(mist, pmr) do
      LineEdit.state(mist, pmr).input_buffer = IOBuffer()
   end
   pmr.prompt=_get_prompt()
   return nothing
end
