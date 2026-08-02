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
    WHERE message_type = 'pacs.004'
),

parsed_xml AS (
    SELECT
        PaymentSystemId,
        PaymentSystemName,
        msg_direction,
        source_system,
        message_type,
        from_xml(clean_xml, 'STRUCT<PmtRtn: STRUCT<GrpHdr: STRUCT<MsgId: STRING, CreDtTm: STRING, BtchBookg: STRING, NbOfTxs: STRING, CtrlSum: DECIMAL(18,5), TtlRtnIntrBkSttlmAmt: STRUCT<_VALUE: DECIMAL(18,5), _Ccy: STRING>, IntrBkSttlmDt: STRING, SttlmInf: STRUCT<SttlmMtd: STRING, SttlmAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, ClrSys: STRUCT<Cd: STRING, Prtry: STRING>, InstgRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstgRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, InstdRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstdRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>, ThrdRmbrsmntAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, ThrdRmbrsmntAgtAcct: STRUCT<Id: STRUCT<IBAN: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, Tp: STRUCT<Cd: STRING, Prtry: STRING>, Ccy: STRING, Nm: STRING, Prxy: STRUCT<Tp: STRUCT<Cd: STRING, Prtry: STRING>, Id: STRING>>>, InstgAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstdAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>>', map('rowTag', 'Document')) AS xml_struct
    FROM base
)

SELECT
    PaymentSystemId,
    PaymentSystemName,
    msg_direction,
    source_system,
    message_type,
    xml_struct.PmtRtn.GrpHdr.MsgId AS pmt_rtn_grp_hdr_msg_id, -- '/Document/PmtRtn/GrpHdr/MsgId'
    xml_struct.PmtRtn.GrpHdr.CreDtTm AS pmt_rtn_grp_hdr_cre_dt_tm, -- '/Document/PmtRtn/GrpHdr/CreDtTm'
    xml_struct.PmtRtn.GrpHdr.BtchBookg AS pmt_rtn_grp_hdr_btch_bookg, -- '/Document/PmtRtn/GrpHdr/BtchBookg'
    xml_struct.PmtRtn.GrpHdr.NbOfTxs AS pmt_rtn_grp_hdr_nb_of_txs, -- '/Document/PmtRtn/GrpHdr/NbOfTxs'
    xml_struct.PmtRtn.GrpHdr.CtrlSum AS pmt_rtn_grp_hdr_ctrl_sum, -- '/Document/PmtRtn/GrpHdr/CtrlSum'
    xml_struct.PmtRtn.GrpHdr.TtlRtnIntrBkSttlmAmt._VALUE AS pmt_rtn_grp_hdr_ttl_rtn_intr_bk_sttlm_amt, -- '/Document/PmtRtn/GrpHdr/TtlRtnIntrBkSttlmAmt'
    xml_struct.PmtRtn.GrpHdr.TtlRtnIntrBkSttlmAmt._Ccy AS pmt_rtn_grp_hdr_ttl_rtn_intr_bk_sttlm_amt_ccy, -- '/Document/PmtRtn/GrpHdr/TtlRtnIntrBkSttlmAmt/@Ccy'
    xml_struct.PmtRtn.GrpHdr.IntrBkSttlmDt AS pmt_rtn_grp_hdr_intr_bk_sttlm_dt, -- '/Document/PmtRtn/GrpHdr/IntrBkSttlmDt'
    xml_struct.PmtRtn.GrpHdr.SttlmInf.SttlmMtd AS pmt_rtn_grp_hdr_sttlm_inf_sttlm_mtd, -- '/Document/PmtRtn/GrpHdr/SttlmInf/SttlmMtd'
    xml_struct.PmtRtn.GrpHdr.SttlmInf.SttlmAcct.Id.IBAN AS pmt_rtn_grp_hdr_sttlm_inf_sttlm_acct_id_iban, -- '/Document/PmtRtn/GrpHdr/SttlmInf/SttlmAcct/Id/IBAN'
    xml_struct.PmtRtn.GrpHdr.SttlmInf.SttlmAcct.Id.Othr.Id AS pmt_rtn_grp_hdr_sttlm_inf_sttlm_acct_id_othr_id, -- '/Document/PmtRtn/GrpHdr/SttlmInf/SttlmAcct/Id/Othr/Id'
    xml_struct.PmtRtn.GrpHdr.InstgAgt.FinInstnId.BICFI AS pmt_rtn_grp_hdr_instg_agt_fin_instn_id_bicfi, -- '/Document/PmtRtn/GrpHdr/InstgAgt/FinInstnId/BICFI'
    xml_struct.PmtRtn.GrpHdr.InstgAgt.FinInstnId.LEI AS pmt_rtn_grp_hdr_instg_agt_fin_instn_id_lei, -- '/Document/PmtRtn/GrpHdr/InstgAgt/FinInstnId/LEI'
    xml_struct.PmtRtn.GrpHdr.InstdAgt.FinInstnId.BICFI AS pmt_rtn_grp_hdr_instd_agt_fin_instn_id_bicfi, -- '/Document/PmtRtn/GrpHdr/InstdAgt/FinInstnId/BICFI'
    xml_struct.PmtRtn.GrpHdr.InstdAgt.FinInstnId.LEI AS pmt_rtn_grp_hdr_instd_agt_fin_instn_id_lei, -- '/Document/PmtRtn/GrpHdr/InstdAgt/FinInstnId/LEI'
    tx.RtnId AS tx_inf_rtn_id, -- '/Document/PmtRtn/TxInf/RtnId'
    tx.OrgnlGrpInf.OrgnlMsgId AS tx_inf_orgnl_grp_inf_orgnl_msg_id, -- '/Document/PmtRtn/TxInf/OrgnlGrpInf/OrgnlMsgId'
    tx.OrgnlGrpInf.OrgnlMsgNmId AS tx_inf_orgnl_grp_inf_orgnl_msg_nm_id, -- '/Document/PmtRtn/TxInf/OrgnlGrpInf/OrgnlMsgNmId'
    tx.OrgnlGrpInf.OrgnlCreDtTm AS tx_inf_orgnl_grp_inf_orgnl_cre_dt_tm, -- '/Document/PmtRtn/TxInf/OrgnlGrpInf/OrgnlCreDtTm'
    tx.OrgnlInstrId AS tx_inf_orgnl_instr_id, -- '/Document/PmtRtn/TxInf/OrgnlInstrId'
    tx.OrgnlEndToEndId AS tx_inf_orgnl_end_to_end_id, -- '/Document/PmtRtn/TxInf/OrgnlEndToEndId'
    tx.OrgnlTxId AS tx_inf_orgnl_tx_id, -- '/Document/PmtRtn/TxInf/OrgnlTxId'
    tx.OrgnlUETR AS tx_inf_orgnl_uetr, -- '/Document/PmtRtn/TxInf/OrgnlUETR'
    tx.OrgnlClrSysRef AS tx_inf_orgnl_clr_sys_ref, -- '/Document/PmtRtn/TxInf/OrgnlClrSysRef'
    tx.OrgnlIntrBkSttlmAmt._VALUE AS tx_inf_orgnl_intr_bk_sttlm_amt, -- '/Document/PmtRtn/TxInf/OrgnlIntrBkSttlmAmt'
    tx.OrgnlIntrBkSttlmAmt._Ccy AS tx_inf_orgnl_intr_bk_sttlm_amt_ccy, -- '/Document/PmtRtn/TxInf/OrgnlIntrBkSttlmAmt/@Ccy'
    tx.OrgnlIntrBkSttlmDt AS tx_inf_orgnl_intr_bk_sttlm_dt, -- '/Document/PmtRtn/TxInf/OrgnlIntrBkSttlmDt'
    tx.RtndIntrBkSttlmAmt._VALUE AS tx_inf_rtnd_intr_bk_sttlm_amt, -- '/Document/PmtRtn/TxInf/RtndIntrBkSttlmAmt'
    tx.RtndIntrBkSttlmAmt._Ccy AS tx_inf_rtnd_intr_bk_sttlm_amt_ccy, -- '/Document/PmtRtn/TxInf/RtndIntrBkSttlmAmt/@Ccy'
    tx.IntrBkSttlmDt AS tx_inf_intr_bk_sttlm_dt, -- '/Document/PmtRtn/TxInf/IntrBkSttlmDt'
    tx.RtndInstdAmt._VALUE AS tx_inf_rtnd_instd_amt, -- '/Document/PmtRtn/TxInf/RtndInstdAmt'
    tx.RtndInstdAmt._Ccy AS tx_inf_rtnd_instd_amt_ccy, -- '/Document/PmtRtn/TxInf/RtndInstdAmt/@Ccy'
    tx.XchgRate AS tx_inf_xchg_rate, -- '/Document/PmtRtn/TxInf/XchgRate'
    tx.CompstnAmt._VALUE AS tx_inf_compstn_amt, -- '/Document/PmtRtn/TxInf/CompstnAmt'
    tx.CompstnAmt._Ccy AS tx_inf_compstn_amt_ccy, -- '/Document/PmtRtn/TxInf/CompstnAmt/@Ccy'
    tx.ChrgBr AS tx_inf_chrg_br, -- '/Document/PmtRtn/TxInf/ChrgBr'
    tx.ChrgsInf[0].Amt._VALUE AS tx_inf_chrgs_inf_amt, -- '/Document/PmtRtn/TxInf/ChrgsInf/Amt'
    tx.ChrgsInf[0].Amt._Ccy AS tx_inf_chrgs_inf_amt_ccy, -- '/Document/PmtRtn/TxInf/ChrgsInf/Amt/@Ccy'
    tx.ChrgsInf[0].Agt.FinInstnId.BICFI AS tx_inf_chrgs_inf_agt_fin_instn_id_bicfi, -- '/Document/PmtRtn/TxInf/ChrgsInf/Agt/FinInstnId/BICFI'
    tx.RtnRsnInf[0].Rsn.Cd AS tx_inf_rtn_rsn_inf_rsn_cd, -- '/Document/PmtRtn/TxInf/RtnRsnInf/Rsn/Cd'
    tx.RtnRsnInf[0].Rsn.Prtry AS tx_inf_rtn_rsn_inf_rsn_prtry, -- '/Document/PmtRtn/TxInf/RtnRsnInf/Rsn/Prtry'
    tx.RtnRsnInf[0].AddtlInf[0] AS tx_inf_rtn_rsn_inf_addtl_inf, -- '/Document/PmtRtn/TxInf/RtnRsnInf/AddtlInf'
    tx.InstgAgt.FinInstnId.BICFI AS tx_inf_instg_agt_fin_instn_id_bicfi, -- '/Document/PmtRtn/TxInf/InstgAgt/FinInstnId/BICFI'
    tx.InstdAgt.FinInstnId.BICFI AS tx_inf_instd_agt_fin_instn_id_bicfi -- '/Document/PmtRtn/TxInf/InstdAgt/FinInstnId/BICFI'
FROM parsed_xml
LATERAL VIEW EXPLODE(xml_struct.PmtRtn.TxInf) t AS tx
