using Distributed
include("testenv.jl")
addprocs_with_testenv(2)

using JuliaDB, Test, TextParse, IndexedTables, PooledArrays, Dagger, OnlineStats,
    Statistics, MemPool, Random, Serialization, Dagger, Dates, WeakRefStrings, DataValues

include("test_iteration.jl")
include("test_util.jl")

println("<HEARTBEAT>")

include("test_table.jl")
include("test_query.jl")
include("test_join.jl")
include("test_misc.jl")
include("test_rechunk.jl")
@static Sys.WORD_SIZE == 32 ||
include("test_readwrite.jl")
include("test_onlinestats.jl")
include("test_ml.jl")
@static Sys.WORD_SIZE == 32 ||
include("test_weakrefstrings.jl")
