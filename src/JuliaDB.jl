"""
    JuliaDB

JuliaDB is a package for working with large persistent data sets.

JuliaDB is an all-Julia, end-to-end tool that can

- Load multi-dimensional datasets quickly and incrementally
- Index the data and perform filter, aggregate, sort, and join operations
- Save results and load them efficiently later
- Use Julia's built-in parallelism to fully utilize any machine or cluster

Introduce yourself to JuliaDB's features at [juliadb.org](https://juliadb.org/)
or jump into the documentation [here](https://www.heptazhou.com/JLdb.jl/latest/)!
"""
module JuliaDB

@static if Sys.WORD_SIZE == 32
    import Base.Threads: Threads
    Threads.atomic_add!(x::Base.Threads.Atomic{UInt64}, v::UInt32) = Threads.atomic_add!(x, UInt64(v))
end

import Base: collect, join, keys, values, iterate, broadcast, merge, reduce, mapslices, 
    ==
import Base.Broadcast: broadcasted
import Base.Iterators: PartitionIterator
import IndexedTables: IndexedTable, table, NDSparse, ndsparse, Tup, groupjoin,
    DimName, Columns, column, columns, rows, pkeys, pairs, Tup, namedtuple, flatten,
    naturaljoin, leftjoin, asofjoin, eltypes, astuple, colnames, pkeynames, valuenames,
    showtable, reducedim_vec, _convert, groupreduce, groupby, ApplyColwise, stack, 
    unstack, selectkeys, selectvalues, select, lowerselection, convertdim, excludecols, 
    reindex, ColDict, AbstractIndexedTable, Dataset, promoted_similar, dropmissing,
    convertmissing, transform
import TextParse: csvread
import Dagger: compute, distribute, load, save, DomainBlocks, ArrayDomain, DArray,
    ArrayOp, domainchunks, chunks, Distribute, debug_compute, get_logs!, LocalEventLog,
    chunktype, tochunk, distribute, Context, treereduce, dsort_chunks
import Serialization: serialize, deserialize
import MemPool: mmwrite, mmread, MMSer, approx_size

import IndexedTables: _ismissing, missing_indxs
missing_indxs(v::AbstractVector) = findall(!_ismissing, v)

using IndexedTables, Dagger, OnlineStats, Distributed, Serialization, Nullables, Printf, 
    Statistics, PooledArrays, WeakRefStrings, MemPool, StatsBase, OnlineStatsBase,
    DataValues, RecipesBase, TextParse, Glob


#-----------------------------------------------------------------------# exports
export @cols, @dateformat_str, AbstractNDSparse, All, Between, ColDict, Columns, DColumns, 
    IndexedTable, JuliaDB, Keys, ML, NA, NDSparse, Not, aggregate_stats, 
    asofjoin, chunks, colnames, column, columns, compute, convertdim, 
    csvread, distribute, dropmissing, fetch_timings!, flatten, glob, groupby, groupjoin, 
    groupreduce, ingest, ingest!, innerjoin, insert_row!, insertafter!, insertbefore!, 
    insertcols, insertcolsafter, insertcolsbefore, leftjoin, load, load_table, loadfiles, 
    loadndsparse, loadtable, merge, naturaljoin, ndsparse, pairs, partitionplot, 
    partitionplot!, rechunk, rechunk_together, reducedim_vec, reindex, 
    rename, rows, save, select, selectkeys, selectvalues, stack, 
    start_tracking_time, stop_tracking_time, summarize, table, tracktime, transform, unstack,
    convertmissing

include("util.jl")
include("serialize.jl")
include("interval.jl")
include("table.jl")
include("ndsparse.jl")
include("reshape.jl")

# equality

function (==)(x::DDataset, y::Union{Dataset, DDataset})
    y1 = distribute(y, length.(domainchunks(rows(x))))
    res = delayed(==, get_result=true).(x.chunks, y1.chunks)
    all(collect(delayed((xs...) -> [xs...])(res...)))
end
function (==)(x::DDataset, y::Dataset)
    collect(x) == y
end
(==)(x::Dataset, y::DDataset) = y == x

function Base.isequal(x::DDataset, y::Union{Dataset, DDataset})
    y1 = distribute(y, length.(domainchunks(rows(x))))
    res = delayed(isequal, get_result=true).(x.chunks, y1.chunks)
    all(collect(delayed((xs...) -> [xs...])(res...)))
end
Base.isequal(x::DDataset, y::Dataset) = isequal(collect(x), y)
Base.isequal(x::Dataset, y::DDataset) = isequal(x, collect(y))

include("iteration.jl")
include("sort.jl")

include("io.jl")
include("printing.jl")

include("indexing.jl")
include("selection.jl")
include("reduce.jl")
include("flatten.jl")
include("join.jl")

include("diagnostics.jl")
include("recipes.jl")
include("ml.jl")

end # module
