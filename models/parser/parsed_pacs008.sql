{{ config(materialized='table', cluster_by=['PaymentSystemId', 'PaymentSystemName']) }}

WITH base AS (
    SELECT
        PaymentSystemId,
        PaymentSystemName,
        msg_direction,
        source_system,
        message_type,
        clean_xml
    FROM {{ ref('stg_xml_router') }}
    WHERE message_type = 'pacs.008'
),

parsed_xml AS (
    SELECT
        PaymentSystemId,
        PaymentSystemName,
        msg_direction,
        source_system,
        message_type,
        from_xml(clean_xml, 'STRUCT<FIToFICstmrCdtTrf: STRUCT<GrpHdr: STRUCT<MsgId: STRING, CreDtTm: STRING, BtchBookg: STRING, NbOfTxs: STRING, CtrlSum: DECIMAL(18,5), TtlIntrBkSttlmAmt: STRUCT<_VALUE: DECIMAL(18,5), _Ccy: STRING>, IntrBkSttlmDt: STRING, SttlmInf: STRUCT<SttlmMtd: STRING, SttlmAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, ClrSys: STRUCT<Cd: STRING, Prtry: STRING>, InstgRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstgRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, InstdRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstdRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, ThrdRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, ThrdRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>>, PmtTpInf: STRUCT<InstrPrty: STRING, ClrChanl: STRING, SvcLvl: STRUCT<Cd: STRING, Prtry: STRING>, LclInstrm: STRUCT<Cd: STRING, Prtry: STRING>, SeqTp: STRING, CtgyPurp: STRUCT<Cd: STRING, Prtry: STRING>>, InstgAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstdAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>>', map('rowTag', 'Document')) AS xml_struct
    FROM base
)

SELECT
    PaymentSystemId,
    PaymentSystemName,
    msg_direction,
    source_system,
    message_type,
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.MsgId AS fi_to_fi_cstmr_cdt_trf_grp_hdr_msg_id, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/MsgId'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.CreDtTm AS fi_to_fi_cstmr_cdt_trf_grp_hdr_cre_dt_tm, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/CreDtTm'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.BtchBookg AS fi_to_fi_cstmr_cdt_trf_grp_hdr_btch_bookg, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/BtchBookg'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.NbOfTxs AS fi_to_fi_cstmr_cdt_trf_grp_hdr_nb_of_txs, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/NbOfTxs'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.CtrlSum AS fi_to_fi_cstmr_cdt_trf_grp_hdr_ctrl_sum, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/CtrlSum'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.TtlIntrBkSttlmAmt._VALUE AS fi_to_fi_cstmr_cdt_trf_grp_hdr_ttl_intr_bk_sttlm_amt, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/TtlIntrBkSttlmAmt'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.TtlIntrBkSttlmAmt._Ccy AS fi_to_fi_cstmr_cdt_trf_grp_hdr_ttl_intr_bk_sttlm_amt_ccy, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/TtlIntrBkSttlmAmt/@Ccy'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.IntrBkSttlmDt AS fi_to_fi_cstmr_cdt_trf_grp_hdr_intr_bk_sttlm_dt, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/IntrBkSttlmDt'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmMtd AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_mtd, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmMtd'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Id.IBAN AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_id_iban, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Id/IBAN'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Id.Othr.Id AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_id_othr_id, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Id/Othr/Id'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Id.Othr.SchmeNm.Cd AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_id_othr_schme_nm_cd, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Id/Othr/SchmeNm/Cd'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Id.Othr.SchmeNm.Prtry AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_id_othr_schme_nm_prtry, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Id/Othr/SchmeNm/Prtry'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Id.Othr.Issr AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_id_othr_issr, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Id/Othr/Issr'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Tp.Cd AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_tp_cd, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Tp/Cd'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Tp.Prtry AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_tp_prtry, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Tp/Prtry'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Ccy AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_ccy, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Ccy'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Nm AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_nm, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Nm'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Prxy.Tp.Cd AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_prxy_tp_cd, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Prxy/Tp/Cd'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Prxy.Tp.Prtry AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_prxy_tp_prtry, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Prxy/Tp/Prtry'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.SttlmAcct.Prxy.Id AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_prxy_id, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/SttlmAcct/Prxy/Id'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.ClrSys.Cd AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_clr_sys_cd, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/ClrSys/Cd'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.SttlmInf.ClrSys.Prtry AS fi_to_fi_cstmr_cdt_trf_grp_hdr_sttlm_inf_clr_sys_prtry, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/SttlmInf/ClrSys/Prtry'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.PmtTpInf.InstrPrty AS fi_to_fi_cstmr_cdt_trf_grp_hdr_pmt_tp_inf_instr_prty, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/PmtTpInf/InstrPrty'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.PmtTpInf.ClrChanl AS fi_to_fi_cstmr_cdt_trf_grp_hdr_pmt_tp_inf_clr_chanl, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/PmtTpInf/ClrChanl'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.PmtTpInf.SvcLvl.Cd AS fi_to_fi_cstmr_cdt_trf_grp_hdr_pmt_tp_inf_svc_lvl_cd, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/PmtTpInf/SvcLvl/Cd'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.PmtTpInf.SvcLvl.Prtry AS fi_to_fi_cstmr_cdt_trf_grp_hdr_pmt_tp_inf_svc_lvl_prtry, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/PmtTpInf/SvcLvl/Prtry'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.PmtTpInf.LclInstrm.Cd AS fi_to_fi_cstmr_cdt_trf_grp_hdr_pmt_tp_inf_lcl_instrm_cd, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/PmtTpInf/LclInstrm/Cd'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.PmtTpInf.LclInstrm.Prtry AS fi_to_fi_cstmr_cdt_trf_grp_hdr_pmt_tp_inf_lcl_instrm_prtry, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/PmtTpInf/LclInstrm/Prtry'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.PmtTpInf.SeqTp AS fi_to_fi_cstmr_cdt_trf_grp_hdr_pmt_tp_inf_seq_tp, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/PmtTpInf/SeqTp'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.PmtTpInf.CtgyPurp.Cd AS fi_to_fi_cstmr_cdt_trf_grp_hdr_pmt_tp_inf_ctgy_purp_cd, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/PmtTpInf/CtgyPurp/Cd'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.PmtTpInf.CtgyPurp.Prtry AS fi_to_fi_cstmr_cdt_trf_grp_hdr_pmt_tp_inf_ctgy_purp_prtry, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/PmtTpInf/CtgyPurp/Prtry'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstgAgt.FinInstnId.BICFI AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instg_agt_fin_instn_id_bicfi, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstgAgt/FinInstnId/BICFI'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstgAgt.FinInstnId.ClrSysMmbId.ClrSysId.Cd AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instg_agt_fin_instn_id_clr_sys_mmb_id_clr_sys_id_cd, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstgAgt/FinInstnId/ClrSysMmbId/ClrSysId/Cd'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstgAgt.FinInstnId.ClrSysMmbId.ClrSysId.Prtry AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instg_agt_fin_instn_id_clr_sys_mmb_id_clr_sys_id_prtry, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstgAgt/FinInstnId/ClrSysMmbId/ClrSysId/Prtry'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstgAgt.FinInstnId.ClrSysMmbId.MmbId AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instg_agt_fin_instn_id_clr_sys_mmb_id_mmb_id, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstgAgt/FinInstnId/ClrSysMmbId/MmbId'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstgAgt.FinInstnId.LEI AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instg_agt_fin_instn_id_lei, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstgAgt/FinInstnId/LEI'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstgAgt.FinInstnId.Nm AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instg_agt_fin_instn_id_nm, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstgAgt/FinInstnId/Nm'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstdAgt.FinInstnId.BICFI AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instd_agt_fin_instn_id_bicfi, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstdAgt/FinInstnId/BICFI'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstdAgt.FinInstnId.ClrSysMmbId.ClrSysId.Cd AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instd_agt_fin_instn_id_clr_sys_mmb_id_clr_sys_id_cd, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstdAgt/FinInstnId/ClrSysMmbId/ClrSysId/Cd'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstdAgt.FinInstnId.ClrSysMmbId.ClrSysId.Prtry AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instd_agt_fin_instn_id_clr_sys_mmb_id_clr_sys_id_prtry, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstdAgt/FinInstnId/ClrSysMmbId/ClrSysId/Prtry'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstdAgt.FinInstnId.ClrSysMmbId.MmbId AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instd_agt_fin_instn_id_clr_sys_mmb_id_mmb_id, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstdAgt/FinInstnId/ClrSysMmbId/MmbId'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstdAgt.FinInstnId.LEI AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instd_agt_fin_instn_id_lei, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstdAgt/FinInstnId/LEI'
    xml_struct.FIToFICstmrCdtTrf.GrpHdr.InstdAgt.FinInstnId.Nm AS fi_to_fi_cstmr_cdt_trf_grp_hdr_instd_agt_fin_instn_id_nm, -- '/Document/FIToFICstmrCdtTrf/GrpHdr/InstdAgt/FinInstnId/Nm'
    tx.PmtId.InstrId AS cdt_trf_tx_inf_pmt_id_instr_id, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtId/InstrId'
    tx.PmtId.EndToEndId AS cdt_trf_tx_inf_pmt_id_end_to_end_id, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtId/EndToEndId'
    tx.PmtId.UETR AS cdt_trf_tx_inf_pmt_id_uetr, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtId/UETR'
    tx.PmtId.ClrSysRef AS cdt_trf_tx_inf_pmt_id_clr_sys_ref, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtId/ClrSysRef'
    tx.PmtTpInf.InstrPrty AS cdt_trf_tx_inf_pmt_tp_inf_instr_prty, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtTpInf/InstrPrty'
    tx.PmtTpInf.ClrChanl AS cdt_trf_tx_inf_pmt_tp_inf_clr_chanl, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtTpInf/ClrChanl'
    tx.PmtTpInf.SvcLvl.Cd AS cdt_trf_tx_inf_pmt_tp_inf_svc_lvl_cd, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtTpInf/SvcLvl/Cd'
    tx.PmtTpInf.SvcLvl.Prtry AS cdt_trf_tx_inf_pmt_tp_inf_svc_lvl_prtry, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtTpInf/SvcLvl/Prtry'
    tx.PmtTpInf.LclInstrm.Cd AS cdt_trf_tx_inf_pmt_tp_inf_lcl_instrm_cd, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtTpInf/LclInstrm/Cd'
    tx.PmtTpInf.LclInstrm.Prtry AS cdt_trf_tx_inf_pmt_tp_inf_lcl_instrm_prtry, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtTpInf/LclInstrm/Prtry'
    tx.PmtTpInf.SeqTp AS cdt_trf_tx_inf_pmt_tp_inf_seq_tp, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtTpInf/SeqTp'
    tx.PmtTpInf.CtgyPurp.Cd AS cdt_trf_tx_inf_pmt_tp_inf_ctgy_purp_cd, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtTpInf/CtgyPurp/Cd'
    tx.PmtTpInf.CtgyPurp.Prtry AS cdt_trf_tx_inf_pmt_tp_inf_ctgy_purp_prtry, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PmtTpInf/CtgyPurp/Prtry'
    tx.IntrBkSttlmAmt._VALUE AS cdt_trf_tx_inf_intr_bk_sttlm_amt, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/IntrBkSttlmAmt'
    tx.IntrBkSttlmAmt._Ccy AS cdt_trf_tx_inf_intr_bk_sttlm_amt_ccy, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/IntrBkSttlmAmt/@Ccy'
    tx.IntrBkSttlmDt AS cdt_trf_tx_inf_intr_bk_sttlm_dt, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/IntrBkSttlmDt'
    tx.SttlmPrty AS cdt_trf_tx_inf_sttlm_prty, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/SttlmPrty'
    tx.SttlmTimeInd.CLSTm AS cdt_trf_tx_inf_sttlm_time_ind_cls_tm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/SttlmTimeInd/CLSTm'
    tx.SttlmTimeInd.TillTm AS cdt_trf_tx_inf_sttlm_time_ind_till_tm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/SttlmTimeInd/TillTm'
    tx.SttlmTimeInd.REJTm AS cdt_trf_tx_inf_sttlm_time_ind_rej_tm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/SttlmTimeInd/REJTm'
    tx.SttlmTimeInd.FrTm AS cdt_trf_tx_inf_sttlm_time_ind_fr_tm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/SttlmTimeInd/FrTm'
    tx.SttlmTimeInd.ToTm AS cdt_trf_tx_inf_sttlm_time_ind_to_tm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/SttlmTimeInd/ToTm'
    tx.SttlmTimeReq.CLSTm AS cdt_trf_tx_inf_sttlm_time_req_cls_tm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/SttlmTimeReq/CLSTm'
    tx.SttlmTimeReq.TillTm AS cdt_trf_tx_inf_sttlm_time_req_till_tm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/SttlmTimeReq/TillTm'
    tx.SttlmTimeReq.REJTm AS cdt_trf_tx_inf_sttlm_time_req_rej_tm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/SttlmTimeReq/REJTm'
    tx.SttlmTimeReq.FrTm AS cdt_trf_tx_inf_sttlm_time_req_fr_tm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/SttlmTimeReq/FrTm'
    tx.SttlmTimeReq.ToTm AS cdt_trf_tx_inf_sttlm_time_req_to_tm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/SttlmTimeReq/ToTm'
    tx.AccptncDtTm AS cdt_trf_tx_inf_accptnc_dt_tm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/AccptncDtTm'
    tx.PoolgAdjstmntDt AS cdt_trf_tx_inf_poolg_adjstmnt_dt, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/PoolgAdjstmntDt'
    tx.InstdAmt._VALUE AS cdt_trf_tx_inf_instd_amt, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/InstdAmt'
    tx.InstdAmt._Ccy AS cdt_trf_tx_inf_instd_amt_ccy, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/InstdAmt/@Ccy'
    tx.XchgRate AS cdt_trf_tx_inf_xchg_rate, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/XchgRate'
    tx.ChrgBr AS cdt_trf_tx_inf_chrg_br, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/ChrgBr'
    tx.ChrgsInf[0].Amt._VALUE AS cdt_trf_tx_inf_chrgs_inf_amt, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/ChrgsInf/Amt'
    tx.ChrgsInf[0].Amt._Ccy AS cdt_trf_tx_inf_chrgs_inf_amt_ccy, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/ChrgsInf/Amt/@Ccy'
    tx.ChrgsInf[0].Agt.FinInstnId.BICFI AS cdt_trf_tx_inf_chrgs_inf_agt_fin_instn_id_bicfi, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/ChrgsInf/Agt/FinInstnId/BICFI'
    tx.ChrgsInf[0].Agt.FinInstnId.LEI AS cdt_trf_tx_inf_chrgs_inf_agt_fin_instn_id_lei, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/ChrgsInf/Agt/FinInstnId/LEI'
    tx.ChrgsInf[0].Agt.FinInstnId.Nm AS cdt_trf_tx_inf_chrgs_inf_agt_fin_instn_id_nm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/ChrgsInf/Agt/FinInstnId/Nm'
    tx.Dbtr.Nm AS cdt_trf_tx_inf_dbtr_nm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Dbtr/Nm'
    tx.Dbtr.PstlAdr.StrtNm AS cdt_trf_tx_inf_dbtr_pstl_adr_strt_nm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Dbtr/PstlAdr/StrtNm'
    tx.Dbtr.PstlAdr.BldgNb AS cdt_trf_tx_inf_dbtr_pstl_adr_bldg_nb, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Dbtr/PstlAdr/BldgNb'
    tx.Dbtr.PstlAdr.PstCd AS cdt_trf_tx_inf_dbtr_pstl_adr_pst_cd, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Dbtr/PstlAdr/PstCd'
    tx.Dbtr.PstlAdr.TwnNm AS cdt_trf_tx_inf_dbtr_pstl_adr_twn_nm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Dbtr/PstlAdr/TwnNm'
    tx.Dbtr.PstlAdr.Ctry AS cdt_trf_tx_inf_dbtr_pstl_adr_ctry, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Dbtr/PstlAdr/Ctry'
    tx.DbtrAcct.Id.IBAN AS cdt_trf_tx_inf_dbtr_acct_id_iban, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/DbtrAcct/Id/IBAN'
    tx.DbtrAcct.Id.Othr.Id AS cdt_trf_tx_inf_dbtr_acct_id_othr_id, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/DbtrAcct/Id/Othr/Id'
    tx.DbtrAgt.FinInstnId.BICFI AS cdt_trf_tx_inf_dbtr_agt_fin_instn_id_bicfi, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/DbtrAgt/FinInstnId/BICFI'
    tx.DbtrAgt.FinInstnId.LEI AS cdt_trf_tx_inf_dbtr_agt_fin_instn_id_lei, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/DbtrAgt/FinInstnId/LEI'
    tx.CdtrAgt.FinInstnId.BICFI AS cdt_trf_tx_inf_cdtr_agt_fin_instn_id_bicfi, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/CdtrAgt/FinInstnId/BICFI'
    tx.CdtrAgt.FinInstnId.LEI AS cdt_trf_tx_inf_cdtr_agt_fin_instn_id_lei, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/CdtrAgt/FinInstnId/LEI'
    tx.Cdtr.Nm AS cdt_trf_tx_inf_cdtr_nm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Cdtr/Nm'
    tx.Cdtr.PstlAdr.StrtNm AS cdt_trf_tx_inf_cdtr_pstl_adr_strt_nm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Cdtr/PstlAdr/StrtNm'
    tx.Cdtr.PstlAdr.BldgNb AS cdt_trf_tx_inf_cdtr_pstl_adr_bldg_nb, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Cdtr/PstlAdr/BldgNb'
    tx.Cdtr.PstlAdr.PstCd AS cdt_trf_tx_inf_cdtr_pstl_adr_pst_cd, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Cdtr/PstlAdr/PstCd'
    tx.Cdtr.PstlAdr.TwnNm AS cdt_trf_tx_inf_cdtr_pstl_adr_twn_nm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Cdtr/PstlAdr/TwnNm'
    tx.Cdtr.PstlAdr.Ctry AS cdt_trf_tx_inf_cdtr_pstl_adr_ctry, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Cdtr/PstlAdr/Ctry'
    tx.CdtrAcct.Id.IBAN AS cdt_trf_tx_inf_cdtr_acct_id_iban, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/CdtrAcct/Id/IBAN'
    tx.CdtrAcct.Id.Othr.Id AS cdt_trf_tx_inf_cdtr_acct_id_othr_id, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/CdtrAcct/Id/Othr/Id'
    tx.UltmtDbtr.Nm AS cdt_trf_tx_inf_ultmt_dbtr_nm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/UltmtDbtr/Nm'
    tx.UltmtCdtr.Nm AS cdt_trf_tx_inf_ultmt_cdtr_nm, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/UltmtCdtr/Nm'
    tx.Purp.Cd AS cdt_trf_tx_inf_purp_cd, -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Purp/Cd'
    tx.Purp.Prtry AS cdt_trf_tx_inf_purp_prtry -- '/Document/FIToFICstmrCdtTrf/CdtTrfTxInf/Purp/Prtry'
FROM parsed_xml
LATERAL VIEW EXPLODE(xml_struct.FIToFICstmrCdtTrf.CdtTrfTxInf) t AS tx
