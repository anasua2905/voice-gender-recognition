-- ============================================================
-- Voice Gender Recognition — SQL Analysis Queries
-- Database: voice_gender.db

-- ============================================================

-- 1. Schema overview
PRAGMA table_info(voice_samples);

-- 2. Total records and class balance
SELECT
    label,
    COUNT(*) AS sample_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM voice_samples), 2) AS pct_of_total
FROM voice_samples
GROUP BY label;

-- 3. Summary statistics for the strongest predictor (meanfun) by gender
SELECT
    label,
    ROUND(AVG(meanfun), 4)                         AS avg_meanfun,
    ROUND(MIN(meanfun), 4)                         AS min_meanfun,
    ROUND(MAX(meanfun), 4)                         AS max_meanfun,
    ROUND(AVG(meanfun) - (SELECT AVG(meanfun) FROM voice_samples), 4) AS diff_from_overall_avg
FROM voice_samples
GROUP BY label;

-- 4. Summary statistics across all key acoustic features by gender
SELECT
    label,
    ROUND(AVG(meanfreq), 4)  AS avg_meanfreq,
    ROUND(AVG(sd), 4)        AS avg_sd,
    ROUND(AVG(meanfun), 4)   AS avg_meanfun,
    ROUND(AVG(IQR), 4)       AS avg_IQR,
    ROUND(AVG("sp.ent"), 4)  AS avg_spectral_entropy
FROM voice_samples
GROUP BY label;

-- 5. Highest-pitched 10 samples (lowest meanfun = typically male register
--    in this feature's convention is reversed — verify against label)
SELECT id, label, meanfun, meanfreq
FROM voice_samples
ORDER BY meanfun DESC
LIMIT 10;

-- 6. Lowest-pitched 10 samples
SELECT id, label, meanfun, meanfreq
FROM voice_samples
ORDER BY meanfun ASC
LIMIT 10;

-- 7. Bucket samples by meanfun range and show the gender split in each
--    bucket — demonstrates how cleanly meanfun separates the classes
SELECT
    CASE
        WHEN meanfun < 0.12 THEN '< 0.12 (low)'
        WHEN meanfun < 0.16 THEN '0.12 - 0.16'
        WHEN meanfun < 0.20 THEN '0.16 - 0.20'
        ELSE '>= 0.20 (high)'
    END AS meanfun_bucket,
    label,
    COUNT(*) AS sample_count
FROM voice_samples
GROUP BY meanfun_bucket, label
ORDER BY meanfun_bucket, label;

-- 8. Outlier check — samples more than 3 standard deviations from the
--    mean on meanfreq (simple anomaly screen)
WITH stats AS (
    SELECT AVG(meanfreq) AS mean_val,
           (SELECT AVG((meanfreq - (SELECT AVG(meanfreq) FROM voice_samples)) *
                       (meanfreq - (SELECT AVG(meanfreq) FROM voice_samples)))
            FROM voice_samples) AS variance
    FROM voice_samples
)
SELECT v.id, v.label, v.meanfreq
FROM voice_samples v, stats s
WHERE ABS(v.meanfreq - s.mean_val) > 3 * SQRT(s.variance)
ORDER BY v.meanfreq;

-- 9. Correlation proxy — co-occurrence of high IQR and high meanfun
--    (both commonly flagged as top predictors in the ML models)
SELECT
    label,
    ROUND(AVG(IQR), 4)     AS avg_IQR,
    ROUND(AVG(meanfun), 4) AS avg_meanfun,
    COUNT(*)               AS n
FROM voice_samples
GROUP BY label;

-- 10. Create a view for reuse in BI tools / further queries
DROP VIEW IF EXISTS v_gender_summary;
CREATE VIEW v_gender_summary AS
SELECT
    label,
    COUNT(*)                AS sample_count,
    ROUND(AVG(meanfreq), 4) AS avg_meanfreq,
    ROUND(AVG(meanfun), 4)  AS avg_meanfun,
    ROUND(AVG(IQR), 4)      AS avg_IQR,
    ROUND(AVG(sfm), 4)      AS avg_sfm
FROM voice_samples
GROUP BY label;

SELECT * FROM v_gender_summary;
