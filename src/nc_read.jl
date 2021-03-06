# - return: data with the dimension of `[lon, lat, ntime]`

"""
    nc_read(file; band = nothing, period = nothing, raw = false)

# Parameters
- `raw`: boolean. It `true`, not replace na values.
- `period`: `[year_start, year_end]`
"""
function nc_read(file, band = nothing; type = nothing, period = nothing, raw = false)

    ds = Dataset(path_mnt(file))
    if band === nothing
        band = nc_bands(file)[1]
    end

    # @time data = ds[band].var[:] # not replace na values at here
    data = raw ? ds[band].var : ds[band]
    @time if period === nothing
        data = data[:]
    else
        if length(period) == 1; period = repeat([period], 2); end
        # change NC into Raster
        dates = ds["time"]
        years = Dates.year.(dates)
        ind = (years .>= period[1] .&& years .<= period[2]) |> findall
        # `ind` is continuous, but reading speed is faster when converting to `unitRange`
        # https://alexander-barth.github.io/NCDatasets.jl/stable/performance/
        ind = ind[1]:ind[end]
        # @show ind
        data = data[:, :, ind]
        # data = length(dates) != length(ind) ?  data[:, :, ind] : data
    end
    close(ds)

    if type !== nothing && eltype(data) != type
        data = @.(type(data))
    end
    data
    # data = SharedArray(data)
end
