-- Assuming antibiotics_list is a table in your database
-- If not, you'll need to create this table or use a CTE for the list

SELECT
    p.row_id,
    p.subject_id,
    p.hadm_id,
    p.icustay_id,
    CONCAT(p.subject_id, '_', p.hadm_id, '_', COALESCE(p.icustay_id, 'NULL'), '_', p.row_id, '_', p.drug) AS antibiotic_key,
    p.drug,u
    a.drug_class,
    p.startdate AS ab_startdate,
    p.enddate AS ab_enddate,
    p.dose_val_rx,
    p.dose_unit_rx
FROM 
    `physionet-data.mimiciii_clinical.PRESCRIPTIONS` p
LEFT JOIN
    antibiotics_list a ON p.drug = a.Antibiotic
WHERE
    p.drug IN (SELECT Antibiotic FROM antibiotics_list)
    -- Note: We're using CASE instead of ifelse for the in_icu field, but not selecting it since it's not in the final selection