-- =============================================================================
-- party_extract.sql — PartyIdentification272 extraction macro
-- Reusable across: Dbtr, Cdtr, UltmtDbtr, UltmtCdtr, InitgPty
-- =============================================================================

{% macro extract_party(xml_col, base_xpath, prefix) %}
  -- Party Name
  {{ xml_extract(xml_col, base_xpath ~ '/Nm') }} AS {{ prefix }}_nm,

  -- Postal Address
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/AdrTp/Cd') }} AS {{ prefix }}_adr_tp_cd,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/CareOf') }} AS {{ prefix }}_care_of,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/Dept') }} AS {{ prefix }}_dept,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/SubDept') }} AS {{ prefix }}_sub_dept,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/StrtNm') }} AS {{ prefix }}_street_nm,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/BldgNb') }} AS {{ prefix }}_bldg_nb,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/BldgNm') }} AS {{ prefix }}_bldg_nm,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/Flr') }} AS {{ prefix }}_flr,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/UnitNb') }} AS {{ prefix }}_unit_nb,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/PstBx') }} AS {{ prefix }}_pst_bx,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/Room') }} AS {{ prefix }}_room,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/PstCd') }} AS {{ prefix }}_pst_cd,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/TwnNm') }} AS {{ prefix }}_twn_nm,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/TwnLctnNm') }} AS {{ prefix }}_twn_lctn_nm,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/DstrctNm') }} AS {{ prefix }}_dstrct_nm,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/CtrySubDvsn') }} AS {{ prefix }}_ctry_sub_dvsn,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/Ctry') }} AS {{ prefix }}_ctry,
  {{ xml_extract(xml_col, base_xpath ~ '/PstlAdr/AdrLine') }} AS {{ prefix }}_adr_line,

  -- Organisation Identification
  {{ xml_extract(xml_col, base_xpath ~ '/Id/OrgId/AnyBIC') }} AS {{ prefix }}_org_any_bic,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/OrgId/LEI') }} AS {{ prefix }}_org_lei,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/OrgId/Othr/Id') }} AS {{ prefix }}_org_othr_id,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/OrgId/Othr/SchmeNm/Cd') }} AS {{ prefix }}_org_othr_schme_cd,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/OrgId/Othr/SchmeNm/Prtry') }} AS {{ prefix }}_org_othr_schme_prtry,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/OrgId/Othr/Issr') }} AS {{ prefix }}_org_othr_issr,

  -- Private Identification
  {{ xml_extract(xml_col, base_xpath ~ '/Id/PrvtId/DtAndPlcOfBirth/BirthDt') }} AS {{ prefix }}_prvt_birth_dt,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/PrvtId/DtAndPlcOfBirth/PrvcOfBirth') }} AS {{ prefix }}_prvt_prvc_of_birth,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/PrvtId/DtAndPlcOfBirth/CityOfBirth') }} AS {{ prefix }}_prvt_city_of_birth,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/PrvtId/DtAndPlcOfBirth/CtryOfBirth') }} AS {{ prefix }}_prvt_ctry_of_birth,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/PrvtId/Othr/Id') }} AS {{ prefix }}_prvt_othr_id,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/PrvtId/Othr/SchmeNm/Cd') }} AS {{ prefix }}_prvt_othr_schme_cd,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/PrvtId/Othr/SchmeNm/Prtry') }} AS {{ prefix }}_prvt_othr_schme_prtry,
  {{ xml_extract(xml_col, base_xpath ~ '/Id/PrvtId/Othr/Issr') }} AS {{ prefix }}_prvt_othr_issr,

  -- Country of Residence
  {{ xml_extract(xml_col, base_xpath ~ '/CtryOfRes') }} AS {{ prefix }}_ctry_of_res,

  -- Contact Details
  {{ xml_extract(xml_col, base_xpath ~ '/CtctDtls/NmPrfx') }} AS {{ prefix }}_ctct_nm_prfx,
  {{ xml_extract(xml_col, base_xpath ~ '/CtctDtls/Nm') }} AS {{ prefix }}_ctct_nm,
  {{ xml_extract(xml_col, base_xpath ~ '/CtctDtls/PhneNb') }} AS {{ prefix }}_ctct_phne_nb,
  {{ xml_extract(xml_col, base_xpath ~ '/CtctDtls/MobNb') }} AS {{ prefix }}_ctct_mob_nb,
  {{ xml_extract(xml_col, base_xpath ~ '/CtctDtls/FaxNb') }} AS {{ prefix }}_ctct_fax_nb,
  {{ xml_extract(xml_col, base_xpath ~ '/CtctDtls/URLAdr') }} AS {{ prefix }}_ctct_url_adr,
  {{ xml_extract(xml_col, base_xpath ~ '/CtctDtls/EmailAdr') }} AS {{ prefix }}_ctct_email_adr
{% endmacro %}
