/*
v_risk_latest.sql
Latest VaR/ES by confidence level
*/

CREATE OR REPLACE VIEW v_risk_latest AS
SELECT DISTINCT ON (confidence)
       date,
       confidence,
       var_1d,
       es_1d
FROM   risk_metrics
ORDER  BY confidence,       -- group within each \alpha
          date DESC;        -- keep most-recent row