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
    WHERE message_type = 'pacs.002'
),

parsed_xml AS (
    SELECT
        PaymentSystemId,
        PaymentSystemName,
        msg_direction,
        source_system,
        message_type,
        from_xml(clean_xml, 'STRUCT<FIToFIPmtStsRpt: STRUCT<GrpHdr: STRUCT<MsgId: STRING, CreDtTm: STRING, InstgAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>, InstdAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<AdrTp: STRUCT<Cd: STRING, Prtry: STRING>, Dept: STRING, SubDept: STRING, StrtNm: STRING, BldgNb: STRING, BldgNm: STRING, PstCd: STRING, TwnNm: STRING, TwnLctnNm: STRING, DstrctNm: STRING, CtrySubDvsn: STRING, Ctry: STRING, AdrLine: ARRAY<STRING>>>>>, OrgnlGrpInfAndSts: STRUCT<OrgnlMsgId: STRING, OrgnlMsgNmId: STRING, OrgnlCreDtTm: STRING, OrgnlNbOfTxs: STRING, OrgnlCtrlSum: DECIMAL(18,5), GrpSts: STRING, StsRsnInf: ARRAY<STRUCT<StsReas: STRUCT<Cd: STRING, Prtry: STRING>, AddtlInf: ARRAY<STRING>>>>>>', map('rowTag', 'Document')) AS xml_struct
    FROM base
)

SELECT
    PaymentSystemId,
    PaymentSystemName,
    msg_direction,
    source_system,
    message_type,
    xml_struct.FIToFIPmtStsRpt.GrpHdr.MsgId AS fi_to_fi_pmt_sts_rpt_grp_hdr_msg_id, -- '/Document/FIToFIPmtStsRpt/GrpHdr/MsgId'
    xml_struct.FIToFIPmtStsRpt.GrpHdr.CreDtTm AS fi_to_fi_pmt_sts_rpt_grp_hdr_cre_dt_tm, -- '/Document/FIToFIPmtStsRpt/GrpHdr/CreDtTm'
    xml_struct.FIToFIPmtStsRpt.GrpHdr.InstgAgt.FinInstnId.BICFI AS fi_to_fi_pmt_sts_rpt_grp_hdr_instg_agt_fin_instn_id_bicfi, -- '/Document/FIToFIPmtStsRpt/GrpHdr/InstgAgt/FinInstnId/BICFI'
    xml_struct.FIToFIPmtStsRpt.GrpHdr.InstgAgt.FinInstnId.LEI AS fi_to_fi_pmt_sts_rpt_grp_hdr_instg_agt_fin_instn_id_lei, -- '/Document/FIToFIPmtStsRpt/GrpHdr/InstgAgt/FinInstnId/LEI'
    xml_struct.FIToFIPmtStsRpt.GrpHdr.InstdAgt.FinInstnId.BICFI AS fi_to_fi_pmt_sts_rpt_grp_hdr_instd_agt_fin_instn_id_bicfi, -- '/Document/FIToFIPmtStsRpt/GrpHdr/InstdAgt/FinInstnId/BICFI'
    xml_struct.FIToFIPmtStsRpt.GrpHdr.InstdAgt.FinInstnId.LEI AS fi_to_fi_pmt_sts_rpt_grp_hdr_instd_agt_fin_instn_id_lei, -- '/Document/FIToFIPmtStsRpt/GrpHdr/InstdAgt/FinInstnId/LEI'
    xml_struct.FIToFIPmtStsRpt.OrgnlGrpInfAndSts[0].OrgnlMsgId AS fi_to_fi_pmt_sts_rpt_orgnl_grp_inf_and_sts_orgnl_msg_id, -- '/Document/FIToFIPmtStsRpt/OrgnlGrpInfAndSts/OrgnlMsgId'
    xml_struct.FIToFIPmtStsRpt.OrgnlGrpInfAndSts[0].OrgnlMsgNmId AS fi_to_fi_pmt_sts_rpt_orgnl_grp_inf_and_sts_orgnl_msg_nm_id, -- '/Document/FIToFIPmtStsRpt/OrgnlGrpInfAndSts/OrgnlMsgNmId'
    xml_struct.FIToFIPmtStsRpt.OrgnlGrpInfAndSts[0].OrgnlCreDtTm AS fi_to_fi_pmt_sts_rpt_orgnl_grp_inf_and_sts_orgnl_cre_dt_tm, -- '/Document/FIToFIPmtStsRpt/OrgnlGrpInfAndSts/OrgnlCreDtTm'
    xml_struct.FIToFIPmtStsRpt.OrgnlGrpInfAndSts[0].OrgnlNbOfTxs AS fi_to_fi_pmt_sts_rpt_orgnl_grp_inf_and_sts_orgnl_nb_of_txs, -- '/Document/FIToFIPmtStsRpt/OrgnlGrpInfAndSts/OrgnlNbOfTxs'
    xml_struct.FIToFIPmtStsRpt.OrgnlGrpInfAndSts[0].OrgnlCtrlSum AS fi_to_fi_pmt_sts_rpt_orgnl_grp_inf_and_sts_orgnl_ctrl_sum, -- '/Document/FIToFIPmtStsRpt/OrgnlGrpInfAndSts/OrgnlCtrlSum'
    xml_struct.FIToFIPmtStsRpt.OrgnlGrpInfAndSts[0].GrpSts AS fi_to_fi_pmt_sts_rpt_orgnl_grp_inf_and_sts_grp_sts, -- '/Document/FIToFIPmtStsRpt/OrgnlGrpInfAndSts/GrpSts'
    tx.StsId AS tx_inf_and_sts_sts_id, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/StsId'
    tx.OrgnlGrpInf.OrgnlMsgId AS tx_inf_and_sts_orgnl_grp_inf_orgnl_msg_id, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/OrgnlGrpInf/OrgnlMsgId'
    tx.OrgnlGrpInf.OrgnlMsgNmId AS tx_inf_and_sts_orgnl_grp_inf_orgnl_msg_nm_id, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/OrgnlGrpInf/OrgnlMsgNmId'
    tx.OrgnlGrpInf.OrgnlCreDtTm AS tx_inf_and_sts_orgnl_grp_inf_orgnl_cre_dt_tm, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/OrgnlGrpInf/OrgnlCreDtTm'
    tx.OrgnlInstrId AS tx_inf_and_sts_orgnl_instr_id, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/OrgnlInstrId'
    tx.OrgnlEndToEndId AS tx_inf_and_sts_orgnl_end_to_end_id, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/OrgnlEndToEndId'
    tx.OrgnlTxId AS tx_inf_and_sts_orgnl_tx_id, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/OrgnlTxId'
    tx.OrgnlUETR AS tx_inf_and_sts_orgnl_uetr, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/OrgnlUETR'
    tx.TxSts AS tx_inf_and_sts_tx_sts, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/TxSts'
    tx.StsRsnInf[0].Rsn.Cd AS tx_inf_and_sts_sts_rsn_inf_rsn_cd, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/StsRsnInf/Rsn/Cd'
    tx.StsRsnInf[0].Rsn.Prtry AS tx_inf_and_sts_sts_rsn_inf_rsn_prtry, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/StsRsnInf/Rsn/Prtry'
    tx.StsRsnInf[0].AddtlInf[0] AS tx_inf_and_sts_sts_rsn_inf_addtl_inf, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/StsRsnInf/AddtlInf'
    tx.AccptncDtTm AS tx_inf_and_sts_accptnc_dt_tm, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/AccptncDtTm'
    tx.ClrSysRef AS tx_inf_and_sts_clr_sys_ref, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/ClrSysRef'
    tx.InstgAgt.FinInstnId.BICFI AS tx_inf_and_sts_instg_agt_fin_instn_id_bicfi, -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/InstgAgt/FinInstnId/BICFI'
    tx.InstdAgt.FinInstnId.BICFI AS tx_inf_and_sts_instd_agt_fin_instn_id_bicfi -- '/Document/FIToFIPmtStsRpt/TxInfAndSts/InstdAgt/FinInstnId/BICFI'
FROM parsed_xml
LATERAL VIEW EXPLODE(xml_struct.FIToFIPmtStsRpt.TxInfAndSts) t AS tx
