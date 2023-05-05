#
# Copyright © 2023 University of Strasbourg. All Rights Reserved.
#

module MimiqVisual

using PyPlot
using Printf
using PrettyTables
using MimiqCircuits

# define colors for plots
const qp_color1 = "#0c7e8f"
const qp_color2 = "#EC7016"
const qp_color3 = "#A4598D"
const qp_color4 = "#006E51"
const qp_color5 = "#96694A"
const qp_color6 = "#7E6A98"

function __init__()
    cssfile = joinpath(@__DIR__, "../assets/custom.css")
    style = open(cssfile) do io
        read(io, String)
    end

    display(Docs.HTML("$style"))
end

""" 
    ptime(time::Number)

print `time` with appropriate units
"""
function ptime(time::Number)
    if time < 1e-6
        @printf "%.3g ns \n" time * 1e9
        return
    end
    if time < 1e-3
        @printf "%.3g µs \n" time * 1e6
        return
    end
    if time < 1e0
        @printf "%.3g ms \n" time * 1e3
        return
    end
    @printf "%.3g s \n" time
end

"""
    printreport(res::MimiqCircuits.Results; kwargs)

Print a report on the MIMIQ simulation results `res`

## Keyword Arguments

* `max_outcomes`: the maximum number of unique measurement outcomes to display (default 8)
"""
function printreport(res::MimiqCircuits.Results; max_outcomes::Int=8)

    # pretty_table format
    tf = TextFormat(up_right_corner='=',
        up_left_corner='=',
        bottom_left_corner='=',
        bottom_right_corner='=',
        up_intersection=' ',
        left_intersection='=',
        right_intersection='=',
        middle_intersection=' ',
        bottom_intersection=' ',
        column=' ',
        row='=',
        hlines=[:begin, :header])

    @printf "===========================\n"
    @printf "Simulation report\n"
    @printf "===========================\n"
    @printf "Algorithm: \t %s \n" res.results["algorithm"]

    @printf "Execution time \t "
    ptime(res.results["time"]["apply"])
    @printf "Sampling time \t "
    ptime(res.results["time"]["sampling"])
    @printf "Fidelity est. \t %.2f (avg. gate error %.4f) \n" res.results["fidelity"] res.results["averageGateError"]

    if length(res.samples) > 0
        outcomes = sort(collect(res.samples), by=x -> x.second, rev=true)[1:min(end, max_outcomes)]

        @printf "\n"
        @printf "Measurement results\n"

        table = permutedims(hcat([[to01(k), v] for (k, v) in outcomes]...))
        pretty_table(table, header=["state", "samples"], tf=tf)
        if length(outcomes) >= max_outcomes
            @printf "results limited to %i items, see `res.samples` for a full list\n" max_outcomes
        end
    end

    if length(res.amplitudes) > 0
        @printf "\n"
        @printf "Statevector amplitudes\n"

        table = permutedims(hcat([[to01(k), v] for (k, v) in res.amplitudes]...))
        pretty_table(table, header=["state", "amplitude"], tf=tf)
    end
end

"""
    hist(res; kwargs)

Plot a histogram of the MIMIQ simulation results `res`

## Keyword Arguments

- `max_outcomes`: the maximum number of unique measurement outcomes to display (default 15)
"""
function hist(res::Results; max_outcomes::Int=15)
    n_samples = 0
    for (_, v) in res.samples
        n_samples += v
    end
    outcomes = sort(collect(res.samples), by=x -> x.second, rev=true)[1:min(end, max_outcomes)]
    labels = [to01(bs) for (bs, _) in outcomes]
    counts = [v for (_, v) in outcomes]
    n_bars = length(outcomes)

    # calculate automatic scaling of the plot size
    w = 1 + sqrt(n_bars) * 1
    h = 2 + 6.5 * length(labels[1]) / 100

    plt = PyPlot.figure(figsize=(w, h))
    PyPlot.svg(true)
    PyPlot.bar(labels, counts, color=qp_color1)
    PyPlot.xlim(0, n_bars + 1)
    PyPlot.ylabel("counts / " * string(n_samples))
    PyPlot.xticks(rotation=90, fontsize=8)
    PyPlot.tight_layout()

    return plt
end

end # module MimiqVisual
