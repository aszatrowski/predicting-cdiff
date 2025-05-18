library(tidyverse)
execution_start <- now(tz = "America/Chicago")
print(paste("start time:", execution_start))
# Data loading and cleaning
## Major settings:
time_delta <- ddays(30) # days
antibiotics_list <- read_csv("predicting-cdiff/hospital-antibiotics.csv")


## Generate sample of unique antibiotic administrations
cat("Loading antibiotics...\n")
antibiotics <- read_csv("physionet.org/files/mimiciii/1.4/PRESCRIPTIONS.csv.gz") |>
    # for reasons passing understanding, the demo dataset has all-lowercase colnames and the full size has all caps
    rename_all(~str_to_lower(.x)) |>
    filter(drug %in% antibiotics_list$Antibiotic) |>
    mutate(
        drug = as.factor(drug),
        antibiotic_key = paste(subject_id, hadm_id, icustay_id, row_id, drug, sep = "_")
    ) |>
    rename(
        ab_startdate = startdate,
        ab_enddate = enddate,
    ) |>
    left_join(
        antibiotics_list,
        by = c("drug" = "Antibiotic")
    ) |>
    pivot_wider(
        id_cols = c(
            subject_id,
            hadm_id, icustay_id, antibiotic_key, ab_startdate, ab_enddate),
        names_from = drug_class,
        values_from = drug_class,
        values_fn = ~ 1,  # Set to 1 when present
        values_fill = 0,   # Set to 0 when absent
        names_prefix = "ab_class_is_"
    )

cat("COMPLETE.\n")
cat("Loading C. diff diagnosis codes...\n")
## Load *C. diff* diagnosis info

cdiff_tests <- read_csv("./physionet.org/files/mimiciii/1.4/MICROBIOLOGYEVENTS.csv.gz") |>
    rename_all(~str_to_lower(.x)) |>
    filter(org_itemid == 80139) |> # code for C. difficile
    rename(
        cdiff_charttime = charttime,
    ) |>
    select(
        subject_id,
        hadm_id,
        cdiff_charttime,
        org_itemid
    )
cdiff_icd9 <- read_csv("./physionet.org/files/mimiciii/1.4/DIAGNOSES_ICD.csv.gz") |>
    rename_all(~str_to_lower(.x)) |>
    filter(icd9_code == "00845") |> # code for C. difficile
    rename(cdiff_icd9 = icd9_code) |>
    select(
        subject_id,
        hadm_id,
        cdiff_icd9
    )

diarrhea_icd9 <- read_csv("./physionet.org/files/mimiciii/1.4/DIAGNOSES_ICD.csv.gz") |>
    rename_all(~str_to_lower(.x)) |>
    filter(icd9_code == "78791") |> # code for C. difficile
    rename(diarrhea_icd9 = icd9_code) |>
    select(
        subject_id,
        hadm_id,
        diarrhea_icd9
    )
cat("COMPLETE.\n")


## Load patient demographics
cat("Loading demographics...\n")
admissions <- read_csv("./physionet.org/files/mimiciii/1.4/ADMISSIONS.csv.gz") |>
    rename_all(~str_to_lower(.x))
patients <- read_csv("./physionet.org/files/mimiciii/1.4/PATIENTS.csv.gz") |>
    rename_all(~str_to_lower(.x))

cat("COMPLETE.\n")
cat("Processing demographics...\n")
demographics <- admissions |>
    left_join(patients, by = c("subject_id")) |>
    mutate(
        is_female = ifelse(
            gender == "F",
            yes = 1,
            no = 0
        )
    ) |>
    select(
        subject_id,
        hadm_id,
        is_female,
        dob,
        admittime,
        dischtime,
        admission_type,
        insurance,
        diagnosis,
    ) |>
    pivot_wider(
        id_cols = c(subject_id:dischtime),
        names_from = c(admission_type),
        values_from = c(admission_type),
        names_prefix = "admit_is_",
        values_fn = ~ 1,
        values_fill = 0
    )
cat("COMPLETE.\n")

##Load ICU status
cat("Loading ICU stays...\n")
icustays <- read_csv("./physionet.org/files/mimiciii/1.4/ICUSTAYS.csv.gz") |>
    rename_all(~str_to_lower(.x)) |>
    rename(icu_intime = intime, icu_outtime = outtime) |>
    select(
        subject_id,
        hadm_id,
        icustay_id,
        icu_intime,
        icu_outtime
    )

cat("COMPLETE.\n")

## Load lab values
cat("Loading lab values...\n")
labvalues <- read_csv("./physionet.org/files/mimiciii/1.4/LABEVENTS.csv.gz",
		      col_types = cols(
			  ROW_ID = col_double(),
			  SUBJECT_ID = col_double(),
			  HADM_ID = col_double(),
			  ITEMID = col_double(),
			  VALUENUM = col_double(),
			  VALUE = col_character(),
			  VALUEUOM = col_character(),
			  FLAG = col_character(),
			  CHARTTIME = col_datetime()
                )) |>
    rename_all(~str_to_lower(.x))
cat("COMPLETE.\n")
### Liver
cat("Processing liver values...")
# item_id dictionary
liver_lab_itemids <- list(
    bilirubin_total = 50885,
    alkaline_phosphatase = 50863,
    alanine_transaminase = 50861,
    aspartate_aminotransferase = 50878,
    gamma_glutamyltransferase = 50927
)
# Set QC thresholds for lab values
lab_qc_thresholds <- c(
    "bilirubin_total" = 20,
    "alkaline_phosphatase" = 600,
    "alanine_transaminase" = 100,
    "aspartate_aminotransferase" = 100,
    "Gamma_glutamyltransferase" = 170
)

liver_labs <- labvalues |>
    filter(itemid %in% liver_lab_itemids) |>
    # Map itemid to iterpretable name using dictionary
    mutate(
        test_name = as.factor(case_when(
            itemid == liver_lab_itemids$bilirubin_total ~ names(liver_lab_itemids)[1],
            itemid == liver_lab_itemids$alkaline_phosphatase ~ names(liver_lab_itemids)[2],
            itemid == liver_lab_itemids$alanine_transaminase ~ names(liver_lab_itemids)[3],
            itemid == liver_lab_itemids$aspartate_aminotransferase ~ names(liver_lab_itemids)[4],
            itemid == liver_lab_itemids$gamma_glutamyltransferase ~ names(liver_lab_itemids)[5]
        ))
    ) |>
    # filter to lab-specific QC thresholds
    filter(valuenum < lab_qc_thresholds[test_name]) |>
    right_join(
        antibiotics,
        by = c("subject_id", "hadm_id"),
        relationship = "many-to-many" # each Ab will be associated with multiple labs, and each lab will be associated with multiple Abs, since eac admission (the key), may contain multiple Abs
    ) |>
    rename(lab_charttime = charttime) |>
    # filter to labs *prior* to admin time
    filter(lab_charttime < ab_startdate) |>
    # Summarize each lab value, grouped by administration instance
    group_by(subject_id, hadm_id, antibiotic_key, test_name) |>
    summarize(
        mean = mean(valuenum, na.rm = TRUE),
        median = median(valuenum, na.rm = TRUE),
        max = max(valuenum, na.rm = TRUE),
        min = min(valuenum, na.rm = TRUE),
        # q10 = quantile(valuenum, 0.1, na.rm = TRUE),
        # q90 = quantile(valuenum, 0.9, na.rm = TRUE),
        range = max(valuenum, na.rm = TRUE) - min(valuenum, na.rm = TRUE),
        sd = replace_na(sd(valuenum, na.rm = TRUE), 0),
        iqr = IQR(valuenum, na.rm = TRUE),
        first = first(valuenum, na_rm = TRUE),
        last = last(valuenum, na_rm = TRUE),
        count = length(valuenum),
        .groups = "drop"
    ) |>
    # WARNING: NAs appear for patients with zero instances of a given lab; these are only implicit in the unpivoted data, since test_name will just skip that lab for that patien
    pivot_wider(
        id_cols = c(subject_id, hadm_id, antibiotic_key),
        names_from = test_name,
        values_from = !(c(subject_id, hadm_id, antibiotic_key, test_name)),
        names_sep = "_"
    )
cat("COMPLETE.\n")
### Renal
# NOTE: I CHOSE THE MOST COMMONLY APPEARING LAB EVENT VALUES AND SPECIFICALLY CHOSE FOR VALUES INSIDE THE BLOOD!
cat("Processing renal labs...")
renal_lab_itemids <- list(
    creatinine = 50912,
    bun = 51006,
    potassium = 50971,
    sodium = 50983,
    chloride = 50902
)

# Set QC thresholds for lab values
renal_qc_thresholds <- c(
    "creatinine" = 15,
    "bun" = 200,
    "potassium" = 10,
    "sodium" = 200,
    "chloride" = 160
)

renal_labs <- labvalues |>
    filter(itemid %in% renal_lab_itemids) |>
    mutate(
        test_name = as.factor(case_when(
            itemid == renal_lab_itemids$creatinine ~ names(renal_lab_itemids)[1],
            itemid == renal_lab_itemids$bun ~ names(renal_lab_itemids)[2],
            itemid == renal_lab_itemids$potassium ~ names(renal_lab_itemids)[3],
            itemid == renal_lab_itemids$sodium ~ names(renal_lab_itemids)[4],
            itemid == renal_lab_itemids$chloride ~ names(renal_lab_itemids)[5]
        ))
    ) |>
    filter(valuenum < renal_qc_thresholds[test_name]) |>
    right_join(
        antibiotics,
        by = c("subject_id", "hadm_id"),
        relationship = "many-to-many") |>
    rename(lab_charttime = charttime) |>
    filter(lab_charttime < ab_startdate) |>
    group_by(subject_id, hadm_id, antibiotic_key, test_name) |>
    summarize(
        mean = mean(valuenum, na.rm = TRUE),
        median = median(valuenum, na.rm = TRUE),
        max = max(valuenum, na.rm = TRUE),
        min = min(valuenum, na.rm = TRUE),
        range = max(valuenum, na.rm = TRUE) - min(valuenum, na.rm = TRUE),
        sd = replace_na(sd(valuenum, na.rm = TRUE), 0),
        iqr = IQR(valuenum, na.rm = TRUE),
        first = first(valuenum, na_rm = TRUE),
        last = last(valuenum, na_rm = TRUE),
        count = length(valuenum),
        .groups = "drop"
    ) |>
    pivot_wider(
        id_cols = c(subject_id, hadm_id, antibiotic_key),
        names_from = test_name,
        values_from = !(c(subject_id, hadm_id, antibiotic_key, test_name)),
        names_sep = "_"
    )
cat("COMPLETE.\n")

### Blood counts
cat("Processing bloods...")
# item_id dictionary
blood_lab_itemids <- list(
    hemoglobin = 51222,
    hematocrit = 51221,
    white_blood_cells = 51300,
    platelets = 51265
)

# Set QC thresholds for lab values
blood_qc_thresholds <- c(
    "hemoglobin" = 25,
    "hematocrit" = 75,
    "white_blood_cells" = 100,
    "platelets" = 1500
)

blood_labs <- labvalues |>
    filter(itemid %in% blood_lab_itemids) |>
    mutate(
        test_name = as.factor(case_when(
            itemid == blood_lab_itemids$hemoglobin ~ names(blood_lab_itemids)[1],
            itemid == blood_lab_itemids$hematocrit ~ names(blood_lab_itemids)[2],
            itemid == blood_lab_itemids$white_blood_cells ~ names(blood_lab_itemids)[3],
            itemid == blood_lab_itemids$platelets ~ names(blood_lab_itemids)[4]
        ))
    ) |>
    filter(valuenum < blood_qc_thresholds[test_name]) |>
    right_join(antibiotics, by = c("subject_id", "hadm_id"), relationship = "many-to-many") |>
    rename(lab_charttime = charttime) |>
    filter(lab_charttime < ab_startdate) |>
    group_by(subject_id, hadm_id, antibiotic_key, test_name) |>
    summarize(
        mean = mean(valuenum, na.rm = TRUE),
        median = median(valuenum, na.rm = TRUE),
        max = max(valuenum, na.rm = TRUE),
        min = min(valuenum, na.rm = TRUE),
        range = max(valuenum, na.rm = TRUE) - min(valuenum, na.rm = TRUE),
        sd = replace_na(sd(valuenum, na.rm = TRUE), 0),
        iqr = IQR(valuenum, na.rm = TRUE),
        first = first(valuenum, na_rm = TRUE),
        last = last(valuenum, na_rm = TRUE),
        count = length(valuenum),
        .groups = "drop"
    ) |>
    pivot_wider(
        id_cols = c(subject_id, hadm_id, antibiotic_key),
        names_from = test_name,
        values_from = !(c(subject_id, hadm_id, antibiotic_key, test_name)),
        names_sep = "_"
    )
cat("COMPLETE.\n")

## Join everything together and compute new columns
cat("Beginning final join...\n")
training_data <- antibiotics |>
    left_join(
        cdiff_tests,
        by = c("subject_id", "hadm_id")
    ) |>
    left_join(
        cdiff_icd9,
        by = c("subject_id", "hadm_id")
    ) |>
    left_join(
        diarrhea_icd9,
        by = c("subject_id", "hadm_id"),
    ) |>
    left_join(
        demographics,
        by = c("subject_id", "hadm_id"),
    ) |>
    left_join(
        icustays,
        by = c("subject_id", "hadm_id", "icustay_id"),
    ) |>
    left_join(
        liver_labs,
        by = c("subject_id", "hadm_id", "antibiotic_key"),
    ) |>
    left_join(
        renal_labs,
        by = c("subject_id", "hadm_id", "antibiotic_key"),
    ) |>
    left_join(
        blood_labs,
        by = c("subject_id", "hadm_id", "antibiotic_key"),
    ) |>
    mutate(
        # generate age column
        age_at_admin = as.numeric(ab_startdate - dob) / 365,
        # generate variable for time since admission at Ab admin, mark 0 if same day since datetimes for Abs are not available
        admin_time_since_admission = as.numeric(pmax(ab_startdate - admittime, 0)),
        in_icu = ifelse(
            ab_startdate >= icu_intime & ab_startdate <= icu_outtime,
            TRUE,
            FALSE
        ),
        admission_time_of_day = as.numeric(hour(admittime)),
        # GENERATE LABEL:
        cdiff_30d_flag = ifelse(
            # OPTION 1: C. diff positive culture after Ab start and less than 30 days after
            (cdiff_charttime >= ab_startdate & cdiff_charttime <= ab_startdate + time_delta)
            # OPTION 2: C. diff ICD (00845) assigned at end of stay, as long as discharge was <30 days after Ab start
            | (cdiff_icd9 == "00845" & dischtime <= ab_startdate + time_delta),
            # Assign TRUE/FALSE accordingly
            yes = 1,
            no = 0
        ),
        # ifelse() returns NA for missing data (non-Cdiff patients will have missing ICDs), so fill missing with FALSE
        cdiff_30d_flag = replace_na(cdiff_30d_flag, 0)
    )  |>
    # couple of QC things:
    filter(
        age_at_admin < 100
    ) |>
    select(
        # remove ID columns
        -antibiotic_key,
        -subject_id,
        -hadm_id,
        -icustay_id,
        # only necessary for generating label/other data:
        -ab_startdate,
        -ab_enddate,
        -cdiff_charttime,
        -org_itemid,
        -cdiff_icd9,
        -diarrhea_icd9,
        -dob,
        -admittime,
        -in_icu,
        -icu_intime,
        -icu_outtime,
        -dischtime
    )
# View(training_data)

cat("COMPLETE.\n")
process_stop <- now()
training_data_coltypes <- training_data  %>%
    summarise_all(class) %>%
    t() |>
    as_tibble()
print(count(training_data_coltypes, V1))
cat("Writing final compressed CSV...\n")
write_csv(training_data, "predicting-cdiff/training_data_full.csv.gz", progress = TRUE)
cat("COMPLETE.\n")
write_stop <- now()
print(paste("Processing time:", format(process_stop - execution_start, digits = 4)))
print(paste("Write time:", format(write_stop - process_stop, digits = 4)))
