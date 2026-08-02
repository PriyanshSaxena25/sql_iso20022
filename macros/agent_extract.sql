-- =============================================================================
-- agent_extract.sql — BranchAndFinancialInstitutionIdentification8 macro
-- Reusable across: InstgAgt, InstdAgt, DbtrAgt, CdtrAgt, IntrmyAgt1-3,
--                  PrvsInstgAgt1-3, UltmtDbtr/Cdtr (in pacs.009)
-- =============================================================================

{% macro extract_agent(xml_col, base_xpath, prefix) %}
  -- Financial Institution Identification
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/BICFI') }} AS {{ prefix }}_bicfi,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/ClrSysMmbId/ClrSysId/Cd') }} AS {{ prefix }}_clr_sys_cd,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/ClrSysMmbId/ClrSysId/Prtry') }} AS {{ prefix }}_clr_sys_prtry,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/ClrSysMmbId/MmbId') }} AS {{ prefix }}_clr_mmb_id,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/LEI') }} AS {{ prefix }}_lei,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/Nm') }} AS {{ prefix }}_nm,

  -- Financial Institution Postal Address
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/PstlAdr/AdrTp/Cd') }} AS {{ prefix }}_adr_tp_cd,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/PstlAdr/StrtNm') }} AS {{ prefix }}_street_nm,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/PstlAdr/BldgNb') }} AS {{ prefix }}_bldg_nb,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/PstlAdr/PstCd') }} AS {{ prefix }}_pst_cd,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/PstlAdr/TwnNm') }} AS {{ prefix }}_twn_nm,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/PstlAdr/Ctry') }} AS {{ prefix }}_ctry,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/PstlAdr/AdrLine') }} AS {{ prefix }}_adr_line,

  -- Other Financial Institution ID
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/Othr/Id') }} AS {{ prefix }}_othr_id,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/Othr/SchmeNm/Cd') }} AS {{ prefix }}_othr_schme_cd,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/Othr/SchmeNm/Prtry') }} AS {{ prefix }}_othr_schme_prtry,
  {{ xml_extract(xml_col, base_xpath ~ '/FinInstnId/Othr/Issr') }} AS {{ prefix }}_othr_issr,

  -- Branch Identification
  {{ xml_extract(xml_col, base_xpath ~ '/BrnchId/Id') }} AS {{ prefix }}_brnch_id,
  {{ xml_extract(xml_col, base_xpath ~ '/BrnchId/LEI') }} AS {{ prefix }}_brnch_lei,
  {{ xml_extract(xml_col, base_xpath ~ '/BrnchId/Nm') }} AS {{ prefix }}_brnch_nm
{% endmacro %}
