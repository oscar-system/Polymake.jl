module GraphvizExt

using Polymake

using BinaryWrappers
import Graphviz_jll

function __init__()
   binpath = @generate_wrappers(Graphviz_jll)
   # this makes sure the variable exists
   Polymake.shell_execute(raw"""application("graph")->reconfigure("graphviz.rules");""")
   Polymake.shell_execute("""\$Graphviz::dot = "$binpath/dot";""")
   # this runs the configure block with the correct path
   Polymake.shell_execute(raw"""application("graph")->reconfigure("graphviz.rules");""")

   nothing
end

end
