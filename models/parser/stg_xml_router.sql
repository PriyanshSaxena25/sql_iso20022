-- =============================================================================
-- stg_xml_router.sql — Message Type Router
-- Reads all payment_staging_* tables, extracts RawMsg_in and RawMsg_out
-- as separate rows, and detects ISO 20022 message type from XML root element.
--
-- Output columns:
--   PaymentSystemId, PaymentSystemName, raw_xml, msg_direction,
--   source_system, message_type
-- =============================================================================

{% set staging_systems = ['gppuk', 'swift', 'sepa'] %}  {# Add system names here #}

WITH raw_messages AS (
  {% for sys in staging_systems %}
  SELECT
    PaymentSystemId,
    PaymentSystemName,
    RawMsg_in  AS raw_xml,
    'IN'       AS msg_direction,
    '{{ sys }}' AS source_system
  FROM cds_prod.stg_paymentsdata.payment_staging_{{ sys }}
  WHERE RawMsg_in IS NOT NULL AND TRIM(RawMsg_in) != ''

  UNION ALL

  SELECT
    PaymentSystemId,
    PaymentSystemName,
    RawMsg_out AS raw_xml,
    'OUT'      AS msg_direction,
    '{{ sys }}' AS source_system
  FROM cds_prod.stg_paymentsdata.payment_staging_{{ sys }}
  WHERE RawMsg_out IS NOT NULL AND TRIM(RawMsg_out) != ''

  {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
)

SELECT
  PaymentSystemId,
  PaymentSystemName,
  raw_xml,
  regexp_replace(raw_xml, ' xmlns="[^"]*"', '') AS clean_xml,
  msg_direction,
  source_system,
  CASE
    WHEN raw_xml LIKE '%FIToFICstmrCdtTrf%'    THEN 'pacs.008'
    WHEN raw_xml LIKE '%FICdtTrf%'
     AND raw_xml NOT LIKE '%FIToFICstmrCdtTrf%' THEN 'pacs.009'
    WHEN raw_xml LIKE '%PmtRtr%'                THEN 'pacs.004'
    WHEN raw_xml LIKE '%FIToFICstmrDrctDbt%'    THEN 'pacs.003'
    WHEN raw_xml LIKE '%FIToFIPmtStsRpt%'       THEN 'pacs.002'
    WHEN raw_xml LIKE '%CstmrCdtTrfInitn%'      THEN 'pain.001'
    ELSE 'UNKNOWN'
  END AS message_type
FROM raw_messages
