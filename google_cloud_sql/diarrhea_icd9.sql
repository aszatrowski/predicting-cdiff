SELECT
    subject_id,
    hadm_id,
    seq_num,
    icd9_code AS diarrhea_icd9
FROM
    `physionet-data.mimiciii_clinical.DIAGNOSES_ICD`
WHERE
    icd9_code = '78791'  -- code for diarrhea