-- =============================================================================
-- xml_utils.sql — Core XML extraction macros
-- Strips ISO 20022 namespaces before XPath evaluation.
-- =============================================================================

-- Extract a single text value from XML, namespace-stripped.
-- Returns NULL if element is absent or empty.
{% macro xml_extract(xml_col, xpath_expr) %}
  NULLIF(
    TRIM(
      xpath_string(
        regexp_replace({{ xml_col }}, ' xmlns="[^"]*"', ''),
        '{{ xpath_expr }}'
      )
    ),
    ''
  )
{% endmacro %}

-- Extract a decimal amount value from XML.
-- Returns NULL if element is absent.
{% macro xml_extract_amount(xml_col, xpath_expr) %}
  CASE
    WHEN NULLIF(TRIM(xpath_string(
      regexp_replace({{ xml_col }}, ' xmlns="[^"]*"', ''),
      '{{ xpath_expr }}'
    )), '') IS NOT NULL
    THEN CAST(xpath_string(
      regexp_replace({{ xml_col }}, ' xmlns="[^"]*"', ''),
      '{{ xpath_expr }}'
    ) AS DECIMAL(18,5))
  END
{% endmacro %}

-- Extract a currency attribute (@Ccy) from an amount element.
{% macro xml_extract_ccy(xml_col, xpath_expr) %}
  NULLIF(
    TRIM(
      xpath_string(
        regexp_replace({{ xml_col }}, ' xmlns="[^"]*"', ''),
        '{{ xpath_expr }}/@Ccy'
      )
    ),
    ''
  )
{% endmacro %}

-- Extract a raw XML fragment (for blob columns like RmtInf).
-- Returns the inner XML of the matched element as a string.
{% macro xml_extract_blob(xml_col, xpath_expr) %}
  NULLIF(
    TRIM(
      xpath_string(
        regexp_replace({{ xml_col }}, ' xmlns="[^"]*"', ''),
        '{{ xpath_expr }}'
      )
    ),
    ''
  )
{% endmacro %}
