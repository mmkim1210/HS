using XLSX, DataFrames, FreqTables

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
end

begin
    df.er_visits_total_ucla .= Int.(df.er_visits_total_ucla)
end

show(unique(df.svi_total))
freqtable(df, "income")

# ignored the following covariates: zip, race, marital_status, sexual_orientation, religion, occupation, dx_duration, hurley_stage, primary_ruci, sec_ruci
# ignored the following outcome variables: er_visits_total_all and management/treatment-related outcomes