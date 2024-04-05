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
end

begin
    df.er_visits_total_ucla .= Int.(df.er_visits_total_ucla)
end

unique(df.adi_natrank)
freqtable(df, "adi_natrank")
