SELECT
    subject_id,
    hadm_id,
    seq_num,
    icd9_code AS cdiff_icd9
FROM
    `physionet-data.mimiciii_clinical.DIAGNOSES_ICD`
WHERE
    icd9_code = '00845'  -- code for C. difficile