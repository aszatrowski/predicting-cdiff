SELECT
    subject_id,
    hadm_id,
    charttime AS cdiff_charttime,
    org_itemid
FROM
    `physionet-data.mimiciii_clinical.MICROBIOLOGYEVENTS`
WHERE
    org_itemid = 80139  -- code for C. difficile