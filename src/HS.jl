using XLSX, DataFrames, FreqTables, GLM, Dates, Statistics, CairoMakie

df = DataFrame(XLSX.readtable("data/data.xlsx", 1))

begin
    df.ip_patient_id .= String.(df.ip_patient_id)
    df.sex           .= String.(df.sex)
    df.derm_ever     .= String.(df.derm_ever)
    df.ethnicity     .= String.(df.ethnicity)
    df.insurance     .= String.(df.insurance)
    df.age           .= Int.(df.age)
    df.insurance[df.insurance .== "HMO", :] .= "Commercial"
    rename!(df, "tx_prior_ocp_spiro" => "tx_prior_ocp-and/or-spiro")
    cols = ["tx_prior_abx", "tx_prior_id", "tx_prior_surg", "tx_prior_topicals", "tx_prior_ocp-and/or-spiro", "tx_prior_metformin", "tx_prior_steroid", "tx_prior_biologic", "tx_prior_retinoid", "tx_prior_zinc", "tx_prior_unspec"]
    storage = Set[]
    for row in 1:size(df, 1)
        tx = Set{String}()
        for col in cols
            if df[row, col] == "yes"
                push!(tx, getindex(split(col, "_"), 3))
            end
        end
        push!(storage, tx)
    end
    df.tx_prior_combined = storage
    df.tx_prior_n = length.(storage)
    [df[!, col] = map(x -> ifelse(x == "yes", 1, 0), df[:, col]) for col in cols]
    df[df.lesion_loc_genitals .== "YES", "lesion_loc_genitals"] .= "yes"
    df[df.lesion_loc_other .!= "no", "lesion_loc_other"] .= "yes"
    cols = ["lesion_loc_axillae", "lesion_loc_breast", "lesion_loc_abd", "lesion_loc_pubic", "lesion_loc_genitals", "lesion_loc_buttocks", "lesion_loc_thigh", "lesion_loc_other"]
    storage = Set[]
    for row in 1:size(df, 1)
        tx = Set{String}()
        for col in cols
            if df[row, col] == "yes"
                push!(tx, getindex(split(col, "_"), 3))
            end
        end
        push!(storage, tx)
    end
    df.lesion_loc_combined = storage
    df.lesion_loc_n = length.(storage)
    [df[!, col] = map(x -> ifelse(x == "yes", 1, 0), df[:, col]) for col in cols]
    df.adi_natrank[df.adi_natrank .== "."] .= missing
    df.adi_natrank = Vector{Union{Missing, Int}}(df.adi_natrank)
    df.adi_staterank[df.adi_staterank .== "."] .= missing
    df.adi_staterank = Vector{Union{Missing, Int}}(df.adi_staterank)
    df.svi_socio_econ[df.svi_socio_econ .== "."] .= missing
    df.svi_socio_econ = Vector{Union{Missing, Float64}}(df.svi_socio_econ)
    df.svi_hcomp[df.svi_hcomp .== "."] .= missing
    df.svi_hcomp = Vector{Union{Missing, Float64}}(df.svi_hcomp)
    df.svi_mino_lang[df.svi_mino_lang .== "."] .= missing
    df.svi_mino_lang = Vector{Union{Missing, Float64}}(df.svi_mino_lang)
    df.svi_htype_trans[df.svi_htype_trans .== "."] .= missing
    df.svi_htype_trans = Vector{Union{Missing, Float64}}(df.svi_htype_trans)
    df.svi_total[df.svi_total .== "."] .= missing
    df.svi_total = Vector{Union{Missing, Float64}}(df.svi_total)
    dict = Dict(
        "."                => missing, 
        "SHRINE|EDU:<10"   => 1, 
        "SHRINE|EDU:10-20" => 2, 
        "SHRINE|EDU:20-30" => 3, 
        "SHRINE|EDU:30-40" => 4,
        "SHRINE|EDU:40-50" => 5,
        "SHRINE|EDU:50-60" => 6,
        "SHRINE|EDU:60-70" => 7,
        "SHRINE|EDU:70-80" => 8,
        )
    storage = Union{Missing, Int}[]
    for row in 1:size(df, 1)
        push!(storage, dict[df.edu[row]])
    end
    df.edu_converted = storage
    dict = Dict(
        "."                    => missing, 
        "SHRINE|INC:25k-35k"   => 1,
        "SHRINE|INC:35k-50k"   => 2, 
        "SHRINE|INC:50k-75k"   => 3, 
        "SHRINE|INC:75k-100k"  => 4, 
        "SHRINE|INC:100k-150k" => 5,
        "SHRINE|INC:150k-200k" => 6,
        "SHRINE|INC:200k-250k" => 7,
        "SHRINE|INC:250k-300k" => 8,
        "SHRINE|INC:>300k"     => 9,
        )
    storage = Union{Missing, Int}[]
    for row in 1:size(df, 1)
        push!(storage, dict[df.income[row]])
    end
    df.income_converted = storage
    dict = Dict(
        "."       => missing, 
        "0-0.1"   => 1,
        "0.1-0.2" => 2, 
        "0.2-0.3" => 3, 
        "0.3-0.4" => 4, 
        "0.4-0.5" => 5,
        "0.5-0.6" => 6,
        "0.6-0.7" => 7,
        "0.7-0.8" => 8,
        "0.8-0.9" => 9,
        "0.9-1"   => 10
        )
    storage = Union{Missing, Int}[]
    for row in 1:size(df, 1)
        push!(storage, dict[df.hpi_percentile[row]])
    end
    df.hpi_percentile_converted = storage
    for i in 1:18
        storage = Vector{Union{Missing, Date}}(missing, size(df, 1))
        ind = df[!, "er$(i)_date"] .!= "."
        storage[ind] .= Date.(df[ind, "er$(i)_date"])
        df[!, "er$(i)_date"] = storage
    end    
end

begin
    df.er_visits_total_ucla .= Int.(df.er_visits_total_ucla)
end

unique(df.ethnicity)
unique(df.insurance)
unique(df.hpi_percentile_converted)
freqtable(df, :hpi_percentile_converted)

glm(@formula(er_visits_total_ucla ~ sex), df, Poisson())
glm(@formula(er_visits_total_ucla ~ derm_ever), df, Poisson())
glm(@formula(er_visits_total_ucla ~ ethnicity), df, Poisson(), contrasts = Dict(:ethnicity => DummyCoding(base = "Not Hispanic or Latino")))
glm(@formula(er_visits_total_ucla ~ insurance), df, Poisson(), contrasts = Dict(:insurance => DummyCoding(base = "Commercial")))
glm(@formula(er_visits_total_ucla ~ age), df, Poisson())
glm(@formula(er_visits_total_ucla ~ tx_prior_n), df, Poisson())
glm(@formula(er_visits_total_ucla ~ lesion_loc_n), df, Poisson())
glm(@formula(er_visits_total_ucla ~ adi_natrank), df, Poisson())
glm(@formula(er_visits_total_ucla ~ adi_staterank), df, Poisson())
glm(@formula(er_visits_total_ucla ~ svi_socio_econ), df, Poisson())
glm(@formula(er_visits_total_ucla ~ svi_hcomp), df, Poisson())
glm(@formula(er_visits_total_ucla ~ svi_mino_lang), df, Poisson())
glm(@formula(er_visits_total_ucla ~ svi_htype_trans), df, Poisson())
glm(@formula(er_visits_total_ucla ~ svi_total), df, Poisson())
glm(@formula(er_visits_total_ucla ~ edu_converted), df, Poisson())
glm(@formula(er_visits_total_ucla ~ income_converted), df, Poisson())
glm(@formula(er_visits_total_ucla ~ hpi_percentile_converted), df, Poisson())

glm(@formula(er_visits_total_ucla ~ sex + insurance + lesion_loc_n + svi_socio_econ + svi_mino_lang + svi_total + edu_converted + income_converted + hpi_percentile_converted), df, Poisson(), contrasts = Dict(:insurance => DummyCoding(base = "Commercial")))
# nobs(glm(@formula(er_visits_total_ucla ~ sex + insurance + lesion_loc_n + svi_socio_econ + svi_mino_lang + svi_total + edu_converted + income_converted + hpi_percentile_converted), df, Poisson(), contrasts = Dict(:insurance => DummyCoding(base = "Commercial"))))
# dropmissing(df, ["sex", "insurance", "lesion_loc_n", "svi_socio_econ", "svi_mino_lang", "svi_total", "edu_converted", "income_converted","hpi_percentile_converted"])

negbin(@formula(er_visits_total_ucla ~ sex), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ derm_ever), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ ethnicity), df, LogLink()) # contrasts not working?
negbin(@formula(er_visits_total_ucla ~ insurance), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ age), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ tx_prior_n), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ lesion_loc_n), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ adi_natrank), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ adi_staterank), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ svi_socio_econ), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ svi_hcomp), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ svi_mino_lang), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ svi_htype_trans), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ svi_total), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ edu_converted), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ income_converted), df, LogLink())
negbin(@formula(er_visits_total_ucla ~ hpi_percentile_converted), df, LogLink())
# glm(@formula(er_visits_total_ucla ~ hpi_percentile_converted), df, NegativeBinomial(), LogLink())

negbin(@formula(er_visits_total_ucla ~ sex + insurance + lesion_loc_n + svi_socio_econ + svi_mino_lang + svi_total + edu_converted + income_converted + hpi_percentile_converted), df, LogLink())

glm(@formula(er_visits_total_ucla ~ tx_prior_combined), df, Poisson())

cols = ["lesion_loc_axillae", "lesion_loc_breast", "lesion_loc_abd", "lesion_loc_pubic", "lesion_loc_genitals", "lesion_loc_buttocks", "lesion_loc_thigh", "lesion_loc_other"]
cols = ["tx_prior_abx", "tx_prior_id", "tx_prior_surg", "tx_prior_topicals", "tx_prior_ocp-and/or-spiro", "tx_prior_metformin", "tx_prior_steroid", "tx_prior_biologic", "tx_prior_retinoid", "tx_prior_zinc", "tx_prior_unspec"]
cor(Matrix(df[!, cols]))

begin
    f = Figure()
    ax = Axis(f[1, 1], title = "Distribution of UCLA ER visits due to HS exacerbations for HS patients")
    hist!(ax, df.er_visits_total_ucla)
    ax.ylabel = "Count"
    ax.xlabel = "Number of ER visits"
    save("distribution.png", f, px_per_unit = 4)
end

begin
    f = Figure()
    ax = Axis(f[1, 1], title = "Number of UCLA ER visits by number of HS lesions")
    rainclouds!(ax, df.lesion_loc_n, df.er_visits_total_ucla, plot_boxplots = false, clouds = nothing, markersize = 10, jitter_width = 0.25)
    ax.ylabel = "Raw or unadjusted number of ER visits"
    ax.xlabel = "Number of HS lesions"
    n1, n2 = extrema(df.lesion_loc_n)
    ax.xticks = (collect(n1:n2), string.(collect(n1:n2)))
    save("lesions.png", f, px_per_unit = 4)
end

begin
    f = Figure()
    ax = Axis(f[1, 1], title = "Number of UCLA ER visits by education level")
    rainclouds!(ax, df.edu_converted, df.er_visits_total_ucla, plot_boxplots = false, clouds = nothing, markersize = 10, jitter_width = 0.25)
    ax.ylabel = "Raw or unadjusted number of ER visits"
    ax.xlabel = "Eudcation level"
    save("education.png", f, px_per_unit = 4)
end

# ignored the following covariates: zip, race, marital_status, sexual_orientation, religion, occupation, dx_duration, hurley_stage, primary_ruci, sec_ruci
# ignored the following outcome variables: er_visits_total_all and management/treatment-related outcomes