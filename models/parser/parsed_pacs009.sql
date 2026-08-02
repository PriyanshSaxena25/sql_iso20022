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
    WHERE message_type = 'pacs.009'
),

parsed_xml AS (
    SELECT
        PaymentSystemId,
        PaymentSystemName,
        msg_direction,
        source_system,
        message_type,
        from_xml(clean_xml, 'STRUCT<FICdtTrf: STRUCT<GrpHdr: STRUCT<MsgId: STRING, CreDtTm: STRING, BtchBookg: STRING, NbOfTxs: STRING, CtrlSum: DECIMAL(18,5), TtlIntrBkSttlmAmt: STRUCT<_VALUE: DECIMAL(18,5), _Ccy: STRING>, IntrBkSttlmDt: STRING, SttlmInf: STRUCT<SttlmMtd: STRING, SttlmAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, ClrSys: STRUCT<Cd: STRING, Prtry: STRING>, InstgRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstgRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, InstdRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstdRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, ThrdRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, ThrdRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>>, PmtTpInf: STRUCT<InstrPrty: STRING, ClrChanl: STRING, SvcLvl: STRUCT<Cd: STRING, Prtry: STRING>, LclInstrm: STRUCT<Cd: STRING, Prtry: STRING>, SeqTp: STRING, CtgyPurp: STRUCT<Cd: STRING, Prtry: STRING>>, InstgAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstdAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>>', map('rowTag', 'Document')) AS xml_struct
    FROM base
)

SELECT
    PaymentSystemId,
    PaymentSystemName,
    msg_direction,
    source_system,
    message_type,
    xml_struct.FICdtTrf.GrpHdr.MsgId AS fi_cdt_trf_grp_hdr_msg_id, -- '/Document/FICdtTrf/GrpHdr/MsgId'
    xml_struct.FICdtTrf.GrpHdr.CreDtTm AS fi_cdt_trf_grp_hdr_cre_dt_tm, -- '/Document/FICdtTrf/GrpHdr/CreDtTm'
    xml_struct.FICdtTrf.GrpHdr.BtchBookg AS fi_cdt_trf_grp_hdr_btch_bookg, -- '/Document/FICdtTrf/GrpHdr/BtchBookg'
    xml_struct.FICdtTrf.GrpHdr.NbOfTxs AS fi_cdt_trf_grp_hdr_nb_of_txs, -- '/Document/FICdtTrf/GrpHdr/NbOfTxs'
    xml_struct.FICdtTrf.GrpHdr.CtrlSum AS fi_cdt_trf_grp_hdr_ctrl_sum, -- '/Document/FICdtTrf/GrpHdr/CtrlSum'
    xml_struct.FICdtTrf.GrpHdr.TtlIntrBkSttlmAmt._VALUE AS fi_cdt_trf_grp_hdr_ttl_intr_bk_sttlm_amt, -- '/Document/FICdtTrf/GrpHdr/TtlIntrBkSttlmAmt'
    xml_struct.FICdtTrf.GrpHdr.TtlIntrBkSttlmAmt._Ccy AS fi_cdt_trf_grp_hdr_ttl_intr_bk_sttlm_amt_ccy, -- '/Document/FICdtTrf/GrpHdr/TtlIntrBkSttlmAmt/@Ccy'
    xml_struct.FICdtTrf.GrpHdr.IntrBkSttlmDt AS fi_cdt_trf_grp_hdr_intr_bk_sttlm_dt, -- '/Document/FICdtTrf/GrpHdr/IntrBkSttlmDt'
    xml_struct.FICdtTrf.GrpHdr.SttlmInf.SttlmMtd AS fi_cdt_trf_grp_hdr_sttlm_inf_sttlm_mtd, -- '/Document/FICdtTrf/GrpHdr/SttlmInf/SttlmMtd'
    xml_struct.FICdtTrf.GrpHdr.SttlmInf.SttlmAcct.Id.IBAN AS fi_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_id_iban, -- '/Document/FICdtTrf/GrpHdr/SttlmInf/SttlmAcct/Id/IBAN'
    xml_struct.FICdtTrf.GrpHdr.SttlmInf.SttlmAcct.Id.Othr.Id AS fi_cdt_trf_grp_hdr_sttlm_inf_sttlm_acct_id_othr_id, -- '/Document/FICdtTrf/GrpHdr/SttlmInf/SttlmAcct/Id/Othr/Id'
    xml_struct.FICdtTrf.GrpHdr.SttlmInf.ClrSys.Cd AS fi_cdt_trf_grp_hdr_sttlm_inf_clr_sys_cd, -- '/Document/FICdtTrf/GrpHdr/SttlmInf/ClrSys/Cd'
    xml_struct.FICdtTrf.GrpHdr.SttlmInf.ClrSys.Prtry AS fi_cdt_trf_grp_hdr_sttlm_inf_clr_sys_prtry, -- '/Document/FICdtTrf/GrpHdr/SttlmInf/ClrSys/Prtry'
    xml_struct.FICdtTrf.GrpHdr.PmtTpInf.InstrPrty AS fi_cdt_trf_grp_hdr_pmt_tp_inf_instr_prty, -- '/Document/FICdtTrf/GrpHdr/PmtTpInf/InstrPrty'
    xml_struct.FICdtTrf.GrpHdr.PmtTpInf.ClrChanl AS fi_cdt_trf_grp_hdr_pmt_tp_inf_clr_chanl, -- '/Document/FICdtTrf/GrpHdr/PmtTpInf/ClrChanl'
    xml_struct.FICdtTrf.GrpHdr.PmtTpInf.SvcLvl.Cd AS fi_cdt_trf_grp_hdr_pmt_tp_inf_svc_lvl_cd, -- '/Document/FICdtTrf/GrpHdr/PmtTpInf/SvcLvl/Cd'
    xml_struct.FICdtTrf.GrpHdr.PmtTpInf.SvcLvl.Prtry AS fi_cdt_trf_grp_hdr_pmt_tp_inf_svc_lvl_prtry, -- '/Document/FICdtTrf/GrpHdr/PmtTpInf/SvcLvl/Prtry'
    xml_struct.FICdtTrf.GrpHdr.PmtTpInf.LclInstrm.Cd AS fi_cdt_trf_grp_hdr_pmt_tp_inf_lcl_instrm_cd, -- '/Document/FICdtTrf/GrpHdr/PmtTpInf/LclInstrm/Cd'
    xml_struct.FICdtTrf.GrpHdr.PmtTpInf.LclInstrm.Prtry AS fi_cdt_trf_grp_hdr_pmt_tp_inf_lcl_instrm_prtry, -- '/Document/FICdtTrf/GrpHdr/PmtTpInf/LclInstrm/Prtry'
    xml_struct.FICdtTrf.GrpHdr.PmtTpInf.SeqTp AS fi_cdt_trf_grp_hdr_pmt_tp_inf_seq_tp, -- '/Document/FICdtTrf/GrpHdr/PmtTpInf/SeqTp'
    xml_struct.FICdtTrf.GrpHdr.PmtTpInf.CtgyPurp.Cd AS fi_cdt_trf_grp_hdr_pmt_tp_inf_ctgy_purp_cd, -- '/Document/FICdtTrf/GrpHdr/PmtTpInf/CtgyPurp/Cd'
    xml_struct.FICdtTrf.GrpHdr.PmtTpInf.CtgyPurp.Prtry AS fi_cdt_trf_grp_hdr_pmt_tp_inf_ctgy_purp_prtry, -- '/Document/FICdtTrf/GrpHdr/PmtTpInf/CtgyPurp/Prtry'
    xml_struct.FICdtTrf.GrpHdr.InstgAgt.FinInstnId.BICFI AS fi_cdt_trf_grp_hdr_instg_agt_fin_instn_id_bicfi, -- '/Document/FICdtTrf/GrpHdr/InstgAgt/FinInstnId/BICFI'
    xml_struct.FICdtTrf.GrpHdr.InstgAgt.FinInstnId.LEI AS fi_cdt_trf_grp_hdr_instg_agt_fin_instn_id_lei, -- '/Document/FICdtTrf/GrpHdr/InstgAgt/FinInstnId/LEI'
    xml_struct.FICdtTrf.GrpHdr.InstgAgt.FinInstnId.Nm AS fi_cdt_trf_grp_hdr_instg_agt_fin_instn_id_nm, -- '/Document/FICdtTrf/GrpHdr/InstgAgt/FinInstnId/Nm'
    xml_struct.FICdtTrf.GrpHdr.InstdAgt.FinInstnId.BICFI AS fi_cdt_trf_grp_hdr_instd_agt_fin_instn_id_bicfi, -- '/Document/FICdtTrf/GrpHdr/InstdAgt/FinInstnId/BICFI'
    xml_struct.FICdtTrf.GrpHdr.InstdAgt.FinInstnId.LEI AS fi_cdt_trf_grp_hdr_instd_agt_fin_instn_id_lei, -- '/Document/FICdtTrf/GrpHdr/InstdAgt/FinInstnId/LEI'
    xml_struct.FICdtTrf.GrpHdr.InstdAgt.FinInstnId.Nm AS fi_cdt_trf_grp_hdr_instd_agt_fin_instn_id_nm, -- '/Document/FICdtTrf/GrpHdr/InstdAgt/FinInstnId/Nm'
    tx.PmtId.InstrId AS cdt_trf_tx_inf_pmt_id_instr_id, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtId/InstrId'
    tx.PmtId.EndToEndId AS cdt_trf_tx_inf_pmt_id_end_to_end_id, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtId/EndToEndId'
    tx.PmtId.UETR AS cdt_trf_tx_inf_pmt_id_uetr, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtId/UETR'
    tx.PmtId.ClrSysRef AS cdt_trf_tx_inf_pmt_id_clr_sys_ref, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtId/ClrSysRef'
    tx.PmtTpInf.InstrPrty AS cdt_trf_tx_inf_pmt_tp_inf_instr_prty, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtTpInf/InstrPrty'
    tx.PmtTpInf.ClrChanl AS cdt_trf_tx_inf_pmt_tp_inf_clr_chanl, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtTpInf/ClrChanl'
    tx.PmtTpInf.SvcLvl.Cd AS cdt_trf_tx_inf_pmt_tp_inf_svc_lvl_cd, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtTpInf/SvcLvl/Cd'
    tx.PmtTpInf.SvcLvl.Prtry AS cdt_trf_tx_inf_pmt_tp_inf_svc_lvl_prtry, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtTpInf/SvcLvl/Prtry'
    tx.PmtTpInf.LclInstrm.Cd AS cdt_trf_tx_inf_pmt_tp_inf_lcl_instrm_cd, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtTpInf/LclInstrm/Cd'
    tx.PmtTpInf.LclInstrm.Prtry AS cdt_trf_tx_inf_pmt_tp_inf_lcl_instrm_prtry, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtTpInf/LclInstrm/Prtry'
    tx.PmtTpInf.SeqTp AS cdt_trf_tx_inf_pmt_tp_inf_seq_tp, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtTpInf/SeqTp'
    tx.PmtTpInf.CtgyPurp.Cd AS cdt_trf_tx_inf_pmt_tp_inf_ctgy_purp_cd, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtTpInf/CtgyPurp/Cd'
    tx.PmtTpInf.CtgyPurp.Prtry AS cdt_trf_tx_inf_pmt_tp_inf_ctgy_purp_prtry, -- '/Document/FICdtTrf/CdtTrfTxInf/PmtTpInf/CtgyPurp/Prtry'
    tx.IntrBkSttlmAmt._VALUE AS cdt_trf_tx_inf_intr_bk_sttlm_amt, -- '/Document/FICdtTrf/CdtTrfTxInf/IntrBkSttlmAmt'
    tx.IntrBkSttlmAmt._Ccy AS cdt_trf_tx_inf_intr_bk_sttlm_amt_ccy, -- '/Document/FICdtTrf/CdtTrfTxInf/IntrBkSttlmAmt/@Ccy'
    tx.IntrBkSttlmDt AS cdt_trf_tx_inf_intr_bk_sttlm_dt, -- '/Document/FICdtTrf/CdtTrfTxInf/IntrBkSttlmDt'
    tx.SttlmPrty AS cdt_trf_tx_inf_sttlm_prty, -- '/Document/FICdtTrf/CdtTrfTxInf/SttlmPrty'
    tx.SttlmTimeInd.CLSTm AS cdt_trf_tx_inf_sttlm_time_ind_cls_tm, -- '/Document/FICdtTrf/CdtTrfTxInf/SttlmTimeInd/CLSTm'
    tx.SttlmTimeInd.TillTm AS cdt_trf_tx_inf_sttlm_time_ind_till_tm, -- '/Document/FICdtTrf/CdtTrfTxInf/SttlmTimeInd/TillTm'
    tx.SttlmTimeInd.REJTm AS cdt_trf_tx_inf_sttlm_time_ind_rej_tm, -- '/Document/FICdtTrf/CdtTrfTxInf/SttlmTimeInd/REJTm'
    tx.SttlmTimeInd.FrTm AS cdt_trf_tx_inf_sttlm_time_ind_fr_tm, -- '/Document/FICdtTrf/CdtTrfTxInf/SttlmTimeInd/FrTm'
    tx.SttlmTimeInd.ToTm AS cdt_trf_tx_inf_sttlm_time_ind_to_tm, -- '/Document/FICdtTrf/CdtTrfTxInf/SttlmTimeInd/ToTm'
    tx.SttlmTimeReq.CLSTm AS cdt_trf_tx_inf_sttlm_time_req_cls_tm, -- '/Document/FICdtTrf/CdtTrfTxInf/SttlmTimeReq/CLSTm'
    tx.SttlmTimeReq.TillTm AS cdt_trf_tx_inf_sttlm_time_req_till_tm, -- '/Document/FICdtTrf/CdtTrfTxInf/SttlmTimeReq/TillTm'
    tx.SttlmTimeReq.REJTm AS cdt_trf_tx_inf_sttlm_time_req_rej_tm, -- '/Document/FICdtTrf/CdtTrfTxInf/SttlmTimeReq/REJTm'
    tx.SttlmTimeReq.FrTm AS cdt_trf_tx_inf_sttlm_time_req_fr_tm, -- '/Document/FICdtTrf/CdtTrfTxInf/SttlmTimeReq/FrTm'
    tx.SttlmTimeReq.ToTm AS cdt_trf_tx_inf_sttlm_time_req_to_tm, -- '/Document/FICdtTrf/CdtTrfTxInf/SttlmTimeReq/ToTm'
    tx.AccptncDtTm AS cdt_trf_tx_inf_accptnc_dt_tm, -- '/Document/FICdtTrf/CdtTrfTxInf/AccptncDtTm'
    tx.PoolgAdjstmntDt AS cdt_trf_tx_inf_poolg_adjstmnt_dt, -- '/Document/FICdtTrf/CdtTrfTxInf/PoolgAdjstmntDt'
    tx.InstdAmt._VALUE AS cdt_trf_tx_inf_instd_amt, -- '/Document/FICdtTrf/CdtTrfTxInf/InstdAmt'
    tx.InstdAmt._Ccy AS cdt_trf_tx_inf_instd_amt_ccy, -- '/Document/FICdtTrf/CdtTrfTxInf/InstdAmt/@Ccy'
    tx.XchgRate AS cdt_trf_tx_inf_xchg_rate, -- '/Document/FICdtTrf/CdtTrfTxInf/XchgRate'
    tx.ChrgBr AS cdt_trf_tx_inf_chrg_br, -- '/Document/FICdtTrf/CdtTrfTxInf/ChrgBr'
    tx.Dbtr.FinInstnId.BICFI AS cdt_trf_tx_inf_dbtr_fin_instn_id_bicfi, -- '/Document/FICdtTrf/CdtTrfTxInf/Dbtr/FinInstnId/BICFI'
    tx.Dbtr.FinInstnId.LEI AS cdt_trf_tx_inf_dbtr_fin_instn_id_lei, -- '/Document/FICdtTrf/CdtTrfTxInf/Dbtr/FinInstnId/LEI'
    tx.Dbtr.FinInstnId.Nm AS cdt_trf_tx_inf_dbtr_fin_instn_id_nm, -- '/Document/FICdtTrf/CdtTrfTxInf/Dbtr/FinInstnId/Nm'
    tx.DbtrAcct.Id.IBAN AS cdt_trf_tx_inf_dbtr_acct_id_iban, -- '/Document/FICdtTrf/CdtTrfTxInf/DbtrAcct/Id/IBAN'
    tx.DbtrAcct.Id.Othr.Id AS cdt_trf_tx_inf_dbtr_acct_id_othr_id, -- '/Document/FICdtTrf/CdtTrfTxInf/DbtrAcct/Id/Othr/Id'
    tx.DbtrAgt.FinInstnId.BICFI AS cdt_trf_tx_inf_dbtr_agt_fin_instn_id_bicfi, -- '/Document/FICdtTrf/CdtTrfTxInf/DbtrAgt/FinInstnId/BICFI'
    tx.DbtrAgt.FinInstnId.LEI AS cdt_trf_tx_inf_dbtr_agt_fin_instn_id_lei, -- '/Document/FICdtTrf/CdtTrfTxInf/DbtrAgt/FinInstnId/LEI'
    tx.CdtrAgt.FinInstnId.BICFI AS cdt_trf_tx_inf_cdtr_agt_fin_instn_id_bicfi, -- '/Document/FICdtTrf/CdtTrfTxInf/CdtrAgt/FinInstnId/BICFI'
    tx.CdtrAgt.FinInstnId.LEI AS cdt_trf_tx_inf_cdtr_agt_fin_instn_id_lei, -- '/Document/FICdtTrf/CdtTrfTxInf/CdtrAgt/FinInstnId/LEI'
    tx.Cdtr.FinInstnId.BICFI AS cdt_trf_tx_inf_cdtr_fin_instn_id_bicfi, -- '/Document/FICdtTrf/CdtTrfTxInf/Cdtr/FinInstnId/BICFI'
    tx.Cdtr.FinInstnId.LEI AS cdt_trf_tx_inf_cdtr_fin_instn_id_lei, -- '/Document/FICdtTrf/CdtTrfTxInf/Cdtr/FinInstnId/LEI'
    tx.Cdtr.FinInstnId.Nm AS cdt_trf_tx_inf_cdtr_fin_instn_id_nm, -- '/Document/FICdtTrf/CdtTrfTxInf/Cdtr/FinInstnId/Nm'
    tx.CdtrAcct.Id.IBAN AS cdt_trf_tx_inf_cdtr_acct_id_iban, -- '/Document/FICdtTrf/CdtTrfTxInf/CdtrAcct/Id/IBAN'
    tx.CdtrAcct.Id.Othr.Id AS cdt_trf_tx_inf_cdtr_acct_id_othr_id, -- '/Document/FICdtTrf/CdtTrfTxInf/CdtrAcct/Id/Othr/Id'
    tx.UltmtDbtr.FinInstnId.BICFI AS cdt_trf_tx_inf_ultmt_dbtr_fin_instn_id_bicfi, -- '/Document/FICdtTrf/CdtTrfTxInf/UltmtDbtr/FinInstnId/BICFI'
    tx.UltmtCdtr.FinInstnId.BICFI AS cdt_trf_tx_inf_ultmt_cdtr_fin_instn_id_bicfi, -- '/Document/FICdtTrf/CdtTrfTxInf/UltmtCdtr/FinInstnId/BICFI'
    tx.Purp.Cd AS cdt_trf_tx_inf_purp_cd, -- '/Document/FICdtTrf/CdtTrfTxInf/Purp/Cd'
    tx.Purp.Prtry AS cdt_trf_tx_inf_purp_prtry -- '/Document/FICdtTrf/CdtTrfTxInf/Purp/Prtry'
FROM parsed_xml
LATERAL VIEW EXPLODE(xml_struct.FICdtTrf.CdtTrfTxInf) t AS tx
