-- =============================================================================
-- account_extract.sql — CashAccount40 extraction macro
-- Reusable across: DbtrAcct, CdtrAcct, DbtrAgtAcct, CdtrAgtAcct,
--                  IntrmyAgt1-3Acct, PrvsInstgAgt1-3Acct, SttlmAcct, ChrgsAcct
-- =============================================================================

{% macro extract_account(xml_col, base_xpath, prefix) %}
  -- Account Identification
  {{ xml_extract(xml_col, base_xpath ~ '/Id/IBAN') }} AS {{ prefix }}_iban,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/Othr/Id') }} AS {{ prefix }}_othr_id,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/Othr/SchmeNm/Cd') }} AS {{ prefix }}_othr_schme_cd,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/Othr/SchmeNm/Prtry') }} AS {{ prefix }}_othr_schme_prtry,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/Othr/Issr') }} AS {{ prefix }}_othr_issr,

  -- Account Type
  {{ xml_extract(xml_col, base_xpath ~ '/Tp/Cd') }} AS {{ prefix }}_tp_cd,
  {{ xml_extract(xml_col, base_xpath ~ '/Tp/Prtry') }} AS {{ prefix }}_tp_prtry,

  -- Currency, Name, Proxy
  {{ xml_extract(xml_col, base_xpath ~ '/Ccy') }} AS {{ prefix }}_ccy,
  {{ xml_extract(xml_col, base_xpath ~ '/Nm') }} AS {{ prefix }}_nm,
  {{ xml_extract(xml_col, base_xpath ~ '/Prxy/Tp/Cd') }} AS {{ prefix }}_prxy_tp_cd,
  {{ xml_extract(xml_col, base_xpath ~ '/Prxy/Tp/Prtry') }} AS {{ prefix }}_prxy_tp_prtry,
  {{ xml_extract(xml_col, base_xpath ~ '/Prxy/Id') }} AS {{ prefix }}_prxy_id
{% endmacro %}
