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
    WHERE message_type = 'pacs.003'
),

parsed_xml AS (
    SELECT
        PaymentSystemId,
        PaymentSystemName,
        msg_direction,
        source_system,
        message_type,
        from_xml(clean_xml, 'STRUCT<FIToFICstmrDrctDbt: STRUCT<GrpHdr: STRUCT<MsgId: STRING, CreDtTm: STRING, BtchBookg: STRING, NbOfTxs: STRING, CtrlSum: DECIMAL(18,5), TtlIntrBkSttlmAmt: STRUCT<_VALUE: DECIMAL(18,5), _Ccy: STRING>, IntrBkSttlmDt: STRING, SttlmInf: STRUCT<SttlmMtd: STRING, SttlmAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, ClrSys: STRUCT<Cd: STRING, Prtry: STRING>, InstgRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstgRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, InstdRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstdRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, ThrdRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, ThrdRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>>, PmtTpInf: STRUCT<InstrPrty: STRING, ClrChanl: STRING, SvcLvl: STRUCT<Cd: STRING, Prtry: STRING>, LclInstrm: STRUCT<Cd: STRING, Prtry: STRING>, SeqTp: STRING, CtgyPurp: STRUCT<Cd: STRING, Prtry: STRING>>, InstgAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstdAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>>', map('rowTag', 'Document')) AS xml_struct
    FROM base
)

SELECT
    PaymentSystemId,
    PaymentSystemName,
    msg_direction,
    source_system,
    message_type,
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.MsgId AS fi_to_fi_cstmr_drct_dbt_grp_hdr_msg_id, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/MsgId'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.CreDtTm AS fi_to_fi_cstmr_drct_dbt_grp_hdr_cre_dt_tm, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/CreDtTm'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.BtchBookg AS fi_to_fi_cstmr_drct_dbt_grp_hdr_btch_bookg, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/BtchBookg'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.NbOfTxs AS fi_to_fi_cstmr_drct_dbt_grp_hdr_nb_of_txs, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/NbOfTxs'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.CtrlSum AS fi_to_fi_cstmr_drct_dbt_grp_hdr_ctrl_sum, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/CtrlSum'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.TtlIntrBkSttlmAmt._VALUE AS fi_to_fi_cstmr_drct_dbt_grp_hdr_ttl_intr_bk_sttlm_amt, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/TtlIntrBkSttlmAmt'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.TtlIntrBkSttlmAmt._Ccy AS fi_to_fi_cstmr_drct_dbt_grp_hdr_ttl_intr_bk_sttlm_amt_ccy, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/TtlIntrBkSttlmAmt/@Ccy'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.IntrBkSttlmDt AS fi_to_fi_cstmr_drct_dbt_grp_hdr_intr_bk_sttlm_dt, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/IntrBkSttlmDt'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.SttlmInf.SttlmMtd AS fi_to_fi_cstmr_drct_dbt_grp_hdr_sttlm_inf_sttlm_mtd, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/SttlmInf/SttlmMtd'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.SttlmInf.SttlmAcct.Id.IBAN AS fi_to_fi_cstmr_drct_dbt_grp_hdr_sttlm_inf_sttlm_acct_id_iban, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/SttlmInf/SttlmAcct/Id/IBAN'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.SttlmInf.SttlmAcct.Id.Othr.Id AS fi_to_fi_cstmr_drct_dbt_grp_hdr_sttlm_inf_sttlm_acct_id_othr_id, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/SttlmInf/SttlmAcct/Id/Othr/Id'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.InstgAgt.FinInstnId.BICFI AS fi_to_fi_cstmr_drct_dbt_grp_hdr_instg_agt_fin_instn_id_bicfi, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/InstgAgt/FinInstnId/BICFI'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.InstgAgt.FinInstnId.LEI AS fi_to_fi_cstmr_drct_dbt_grp_hdr_instg_agt_fin_instn_id_lei, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/InstgAgt/FinInstnId/LEI'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.InstdAgt.FinInstnId.BICFI AS fi_to_fi_cstmr_drct_dbt_grp_hdr_instd_agt_fin_instn_id_bicfi, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/InstdAgt/FinInstnId/BICFI'
    xml_struct.FIToFICstmrDrctDbt.GrpHdr.InstdAgt.FinInstnId.LEI AS fi_to_fi_cstmr_drct_dbt_grp_hdr_instd_agt_fin_instn_id_lei, -- '/Document/FIToFICstmrDrctDbt/GrpHdr/InstdAgt/FinInstnId/LEI'
    tx.PmtId.InstrId AS drct_dbt_tx_inf_pmt_id_instr_id, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtId/InstrId'
    tx.PmtId.EndToEndId AS drct_dbt_tx_inf_pmt_id_end_to_end_id, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtId/EndToEndId'
    tx.PmtId.UETR AS drct_dbt_tx_inf_pmt_id_uetr, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtId/UETR'
    tx.PmtId.ClrSysRef AS drct_dbt_tx_inf_pmt_id_clr_sys_ref, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtId/ClrSysRef'
    tx.PmtTpInf.InstrPrty AS drct_dbt_tx_inf_pmt_tp_inf_instr_prty, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtTpInf/InstrPrty'
    tx.PmtTpInf.ClrChanl AS drct_dbt_tx_inf_pmt_tp_inf_clr_chanl, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtTpInf/ClrChanl'
    tx.PmtTpInf.SvcLvl.Cd AS drct_dbt_tx_inf_pmt_tp_inf_svc_lvl_cd, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtTpInf/SvcLvl/Cd'
    tx.PmtTpInf.SvcLvl.Prtry AS drct_dbt_tx_inf_pmt_tp_inf_svc_lvl_prtry, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtTpInf/SvcLvl/Prtry'
    tx.PmtTpInf.LclInstrm.Cd AS drct_dbt_tx_inf_pmt_tp_inf_lcl_instrm_cd, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtTpInf/LclInstrm/Cd'
    tx.PmtTpInf.LclInstrm.Prtry AS drct_dbt_tx_inf_pmt_tp_inf_lcl_instrm_prtry, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtTpInf/LclInstrm/Prtry'
    tx.PmtTpInf.SeqTp AS drct_dbt_tx_inf_pmt_tp_inf_seq_tp, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtTpInf/SeqTp'
    tx.PmtTpInf.CtgyPurp.Cd AS drct_dbt_tx_inf_pmt_tp_inf_ctgy_purp_cd, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtTpInf/CtgyPurp/Cd'
    tx.PmtTpInf.CtgyPurp.Prtry AS drct_dbt_tx_inf_pmt_tp_inf_ctgy_purp_prtry, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/PmtTpInf/CtgyPurp/Prtry'
    tx.IntrBkSttlmAmt._VALUE AS drct_dbt_tx_inf_intr_bk_sttlm_amt, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/IntrBkSttlmAmt'
    tx.IntrBkSttlmAmt._Ccy AS drct_dbt_tx_inf_intr_bk_sttlm_amt_ccy, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/IntrBkSttlmAmt/@Ccy'
    tx.IntrBkSttlmDt AS drct_dbt_tx_inf_intr_bk_sttlm_dt, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/IntrBkSttlmDt'
    tx.InstdAmt._VALUE AS drct_dbt_tx_inf_instd_amt, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/InstdAmt'
    tx.InstdAmt._Ccy AS drct_dbt_tx_inf_instd_amt_ccy, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/InstdAmt/@Ccy'
    tx.XchgRate AS drct_dbt_tx_inf_xchg_rate, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/XchgRate'
    tx.ChrgBr AS drct_dbt_tx_inf_chrg_br, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/ChrgBr'
    tx.DrctDbtTx.MndtRltdInf.MndtId AS drct_dbt_tx_inf_drct_dbt_tx_mndt_rltd_inf_mndt_id, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/DrctDbtTx/MndtRltdInf/MndtId'
    tx.DrctDbtTx.MndtRltdInf.DtOfSgntr AS drct_dbt_tx_inf_drct_dbt_tx_mndt_rltd_inf_dt_of_sgntr, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/DrctDbtTx/MndtRltdInf/DtOfSgntr'
    tx.DrctDbtTx.MndtRltdInf.AmdmntInd AS drct_dbt_tx_inf_drct_dbt_tx_mndt_rltd_inf_amdmnt_ind, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/DrctDbtTx/MndtRltdInf/AmdmntInd'
    tx.Dbtr.Nm AS drct_dbt_tx_inf_dbtr_nm, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/Dbtr/Nm'
    tx.DbtrAcct.Id.IBAN AS drct_dbt_tx_inf_dbtr_acct_id_iban, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/DbtrAcct/Id/IBAN'
    tx.DbtrAcct.Id.Othr.Id AS drct_dbt_tx_inf_dbtr_acct_id_othr_id, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/DbtrAcct/Id/Othr/Id'
    tx.DbtrAgt.FinInstnId.BICFI AS drct_dbt_tx_inf_dbtr_agt_fin_instn_id_bicfi, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/DbtrAgt/FinInstnId/BICFI'
    tx.CdtrAgt.FinInstnId.BICFI AS drct_dbt_tx_inf_cdtr_agt_fin_instn_id_bicfi, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/CdtrAgt/FinInstnId/BICFI'
    tx.Cdtr.Nm AS drct_dbt_tx_inf_cdtr_nm, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/Cdtr/Nm'
    tx.CdtrAcct.Id.IBAN AS drct_dbt_tx_inf_cdtr_acct_id_iban, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/CdtrAcct/Id/IBAN'
    tx.CdtrAcct.Id.Othr.Id AS drct_dbt_tx_inf_cdtr_acct_id_othr_id, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/CdtrAcct/Id/Othr/Id'
    tx.UltmtDbtr.Nm AS drct_dbt_tx_inf_ultmt_dbtr_nm, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/UltmtDbtr/Nm'
    tx.UltmtCdtr.Nm AS drct_dbt_tx_inf_ultmt_cdtr_nm, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/UltmtCdtr/Nm'
    tx.Purp.Cd AS drct_dbt_tx_inf_purp_cd, -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/Purp/Cd'
    tx.Purp.Prtry AS drct_dbt_tx_inf_purp_prtry -- '/Document/FIToFICstmrDrctDbt/DrctDbtTxInf/Purp/Prtry'
FROM parsed_xml
LATERAL VIEW EXPLODE(xml_struct.FIToFICstmrDrctDbt.DrctDbtTxInf) t AS tx
