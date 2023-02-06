import Random

if haskey(ENV, "JULIA_PKGEVAL") ||
    get(ENV, "CI", "") == "true" ||
    haskey(ENV, "OSCAR_RANDOM_SEED")
  seed = parse(UInt32, get(ENV, "OSCAR_RANDOM_SEED", "42"))
  @info string(@__FILE__)*" -- fixed SEED $seed"
else
  seed = rand(UInt32)
  @info string(@__FILE__)*" -- SEED $seed"
end
rng = Random.MersenneTwister(seed)

using Oscar
using Test
using Documenter

GC.enable_logging(true)
using Printf: @printf


function meminfo_julia()
  # @printf "GC total:  %9.3f MiB\n" Base.gc_total_bytes(Base.gc_num())/2^20
  # Total bytes (above) usually underreports, thus I suggest using live bytes (below)
  @printf "GC live:   %9.3f MiB\n" Base.gc_live_bytes()/2^20
  @printf "JIT:       %9.3f MiB\n" Base.jit_total_bytes()/2^20
  @printf "Max. RSS:  %9.3f MiB\n" Sys.maxrss()/2^20
  @printf "Free mem:  %9.3f MiB\n" Sys.free_memory()/2^20
  @printf "Free pmem: %9.3f MiB\n" Sys.free_physical_memory()/2^20
end

function meminfo_procfs(pid=getpid())
  smaps = "/proc/$pid/smaps_rollup"
  if !isfile(smaps)
    error("`$smaps` not found. Maybe you are using an OS without procfs support or with an old kernel.")
  end

  rss = pss = shared = private = 0
  for line in eachline(smaps)
    s = split(line)
    if s[1] == "Rss:"
      rss += parse(Int64, s[2])
    elseif s[1] == "Pss:"
      pss += parse(Int64, s[2])
    elseif s[1] == "Shared_Clean:" || s[1] == "Shared_Dirty:"
      shared += parse(Int64, s[2])
    elseif s[1] == "Private_Clean:" || s[1] == "Private_Dirty:"
      private += parse(Int64, s[2])
    end
  end

  @printf "RSS:       %9.3f MiB\n" rss/2^10
  @printf "┝ shared:  %9.3f MiB\n" shared/2^10
  @printf "┕ private: %9.3f MiB\n" private/2^10
  @printf "PSS:       %9.3f MiB\n" pss/2^10
end

function setup_memuse_tracker()
  tracker = Ref(0)
  function mem_use(tracker)
    finalizer(mem_use, tracker)
    @printf "Current memory (gc-live):  %9.3f MiB\n" Base.gc_live_bytes()/2^20
    @printf "Free      memory:          %9.3f MiB\n" Sys.free_memory()/2^20
    @printf "Free phys memory:          %9.3f MiB\n" Sys.free_physical_memory()/2^20
    nothing
  end

  finalizer(mem_use, tracker)
  nothing
end

#setup_memuse_tracker()

function include(str::String)
  @time Base._include(identity, Main, str)
  meminfo_julia()
  #meminfo_procfs()
end

import Oscar.Nemo.AbstractAlgebra
include(joinpath(pathof(AbstractAlgebra), "..", "..", "test", "Rings-conformance-tests.jl"))

# Used in both Rings/slpolys-test.jl and StraightLinePrograms/runtests.jl
const SLP = Oscar.StraightLinePrograms
include("printing.jl")

include("PolyhedralGeometry/runtests.jl")
include("Combinatorics/runtests.jl")
GC.gc()

include("GAP/runtests.jl")
include("Groups/runtests.jl")

include("Rings/runtests.jl")

include("NumberTheory/nmbthy-test.jl")

if Oscar.is_dev
  include("Experimental/GITFans-test.jl")
end

include("Experimental/PlaneCurve-test.jl")
include("Experimental/galois-test.jl")
include("Experimental/gmodule-test.jl")
include("Experimental/ModStdQt-test.jl")
include("Experimental/ModStdNF-test.jl")
include("Experimental/MPolyRingSparse-test.jl")
include("Experimental/MatrixGroups-test.jl")

include("Geometry/K3Auto.jl")

include("Modules/UngradedModules.jl")
include("Modules/FreeModElem-orderings-test.jl")
include("Modules/ModulesGraded.jl")
include("Modules/module-localizations.jl")
include("Modules/local_rings.jl")
include("Modules/MPolyQuo.jl")
include("Modules/homological-algebra_test.jl")

include("InvariantTheory/runtests.jl")

include("ToricVarieties/runtests.jl")

include("Modules/ProjectiveModules.jl")
include("Schemes/runtests.jl")

include("TropicalGeometry/runtests.jl")
include("Serialization/runtests.jl")

include("StraightLinePrograms/runtests.jl")

# Doctests

# We want to avoid running the doctests twice so we skip them when
# "oscar_run_doctests" is set by OscarDevTools.jl
if v"1.6.0" <= VERSION < v"1.7.0" && !haskey(ENV,"oscar_run_doctests")
  @info "Running doctests (Julia version is 1.6)"
  DocMeta.setdocmeta!(Oscar, :DocTestSetup, :(using Oscar, Oscar.Graphs); recursive = true)
  doctest(Oscar)
else
  @info "Not running doctests (Julia version must be 1.6)"
end
