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
    WHERE message_type = 'pain.001'
),

parsed_xml AS (
    SELECT
        PaymentSystemId,
        PaymentSystemName,
        msg_direction,
        source_system,
        message_type,
        from_xml(clean_xml, 'STRUCT<CstmrCdtTrfInitn: STRUCT<GrpHdr: STRUCT<MsgId: STRING, CreDtTm: STRING, BtchBookg: STRING, NbOfTxs: STRING, CtrlSum: DECIMAL(18,5), InitgPty: STRUCT<Nm: STRING, PstlAdr: STRUCT<StrtNm: STRING, BldgNb: STRING, PstCd: STRING, TwnNm: STRING, Ctry: STRING>, Id: STRUCT<OrgId: STRUCT<AnyBIC: STRING, LEI: STRING, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, PrvtId: STRUCT<DtAndPlcOfBrt: STRUCT<BirthDt: STRING, PrvcOfBrt: STRING, CityOfBrt: STRING, CtryOfBrt: STRING>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>>, CtryOfRes: STRING, CtctDtls: STRUCT<Nm: STRING, PhneNb: STRING, EmailAdr: STRING>>, FwdgAgt: STRUCT<FinInstnId: STRUCT<BICFI: STRING, ClrSysMmbId: STRUCT<ClrSysId: STRUCT<Cd: STRING, Prtry: STRING>, MmbId: STRING>, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<StrtNm: STRING, BldgNb: STRING, PstCd: STRING, TwnNm: STRING, Ctry: STRING>, Othr: STRUCT<Id: STRING, SchmeNm: STRUCT<Cd: STRING, Prtry: STRING>, Issr: STRING>>, BrnchId: STRUCT<Id: STRING, LEI: STRING, Nm: STRING, PstlAdr: STRUCT<StrtNm: STRING, BldgNb: STRING, PstCd: STRING, TwnNm: STRING, Ctry: STRING>>>>>', map('rowTag', 'Document')) AS xml_struct
    FROM base
)

SELECT
    PaymentSystemId,
    PaymentSystemName,
    msg_direction,
    source_system,
    message_type,
    xml_struct.CstmrCdtTrfInitn.GrpHdr.MsgId AS cstmr_cdt_trf_initn_grp_hdr_msg_id, -- '/Document/CstmrCdtTrfInitn/GrpHdr/MsgId'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.CreDtTm AS cstmr_cdt_trf_initn_grp_hdr_cre_dt_tm, -- '/Document/CstmrCdtTrfInitn/GrpHdr/CreDtTm'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.BtchBookg AS cstmr_cdt_trf_initn_grp_hdr_btch_bookg, -- '/Document/CstmrCdtTrfInitn/GrpHdr/BtchBookg'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.NbOfTxs AS cstmr_cdt_trf_initn_grp_hdr_nb_of_txs, -- '/Document/CstmrCdtTrfInitn/GrpHdr/NbOfTxs'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.CtrlSum AS cstmr_cdt_trf_initn_grp_hdr_ctrl_sum, -- '/Document/CstmrCdtTrfInitn/GrpHdr/CtrlSum'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.Nm AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_nm, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/Nm'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.PstlAdr.StrtNm AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_pstl_adr_strt_nm, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/PstlAdr/StrtNm'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.PstlAdr.BldgNb AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_pstl_adr_bldg_nb, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/PstlAdr/BldgNb'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.PstlAdr.PstCd AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_pstl_adr_pst_cd, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/PstlAdr/PstCd'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.PstlAdr.TwnNm AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_pstl_adr_twn_nm, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/PstlAdr/TwnNm'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.PstlAdr.Ctry AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_pstl_adr_ctry, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/PstlAdr/Ctry'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.Id.OrgId.AnyBIC AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_id_org_id_any_bic, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/Id/OrgId/AnyBIC'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.Id.OrgId.LEI AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_id_org_id_lei, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/Id/OrgId/LEI'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.Id.OrgId.Othr.Id AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_id_org_id_othr_id, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/Id/OrgId/Othr/Id'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.Id.PrvtId.DtAndPlcOfBrt.BirthDt AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_id_prvt_id_dt_and_plc_of_brt_birth_dt, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/Id/PrvtId/DtAndPlcOfBrt/BirthDt'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.Id.PrvtId.DtAndPlcOfBrt.PrvcOfBrt AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_id_prvt_id_dt_and_plc_of_brt_prvc_of_brt, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/Id/PrvtId/DtAndPlcOfBrt/PrvcOfBrt'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.Id.PrvtId.DtAndPlcOfBrt.CityOfBrt AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_id_prvt_id_dt_and_plc_of_brt_city_of_brt, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/Id/PrvtId/DtAndPlcOfBrt/CityOfBrt'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.Id.PrvtId.DtAndPlcOfBrt.CtryOfBrt AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_id_prvt_id_dt_and_plc_of_brt_ctry_of_brt, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/Id/PrvtId/DtAndPlcOfBrt/CtryOfBrt'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.InitgPty.Id.PrvtId.Othr.Id AS cstmr_cdt_trf_initn_grp_hdr_initg_pty_id_prvt_id_othr_id, -- '/Document/CstmrCdtTrfInitn/GrpHdr/InitgPty/Id/PrvtId/Othr/Id'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.FwdgAgt.FinInstnId.BICFI AS cstmr_cdt_trf_initn_grp_hdr_fwdg_agt_fin_instn_id_bicfi, -- '/Document/CstmrCdtTrfInitn/GrpHdr/FwdgAgt/FinInstnId/BICFI'
    xml_struct.CstmrCdtTrfInitn.GrpHdr.FwdgAgt.FinInstnId.LEI AS cstmr_cdt_trf_initn_grp_hdr_fwdg_agt_fin_instn_id_lei, -- '/Document/CstmrCdtTrfInitn/GrpHdr/FwdgAgt/FinInstnId/LEI'
    tx.PmtInfId AS pmt_inf_pmt_inf_id, -- '/Document/CstmrCdtTrfInitn/PmtInf/PmtInfId'
    tx.PmtMtd AS pmt_inf_pmt_mtd, -- '/Document/CstmrCdtTrfInitn/PmtInf/PmtMtd'
    tx.BtchBookg AS pmt_inf_btch_bookg, -- '/Document/CstmrCdtTrfInitn/PmtInf/BtchBookg'
    tx.NbOfTxs AS pmt_inf_nb_of_txs, -- '/Document/CstmrCdtTrfInitn/PmtInf/NbOfTxs'
    tx.CtrlSum AS pmt_inf_ctrl_sum, -- '/Document/CstmrCdtTrfInitn/PmtInf/CtrlSum'
    tx.PmtTpInf.InstrPrty AS pmt_inf_pmt_tp_inf_instr_prty, -- '/Document/CstmrCdtTrfInitn/PmtInf/PmtTpInf/InstrPrty'
    tx.PmtTpInf.ClrChanl AS pmt_inf_pmt_tp_inf_clr_chanl, -- '/Document/CstmrCdtTrfInitn/PmtInf/PmtTpInf/ClrChanl'
    tx.PmtTpInf.SvcLvl.Cd AS pmt_inf_pmt_tp_inf_svc_lvl_cd, -- '/Document/CstmrCdtTrfInitn/PmtInf/PmtTpInf/SvcLvl/Cd'
    tx.PmtTpInf.SvcLvl.Prtry AS pmt_inf_pmt_tp_inf_svc_lvl_prtry, -- '/Document/CstmrCdtTrfInitn/PmtInf/PmtTpInf/SvcLvl/Prtry'
    tx.PmtTpInf.LclInstrm.Cd AS pmt_inf_pmt_tp_inf_lcl_instrm_cd, -- '/Document/CstmrCdtTrfInitn/PmtInf/PmtTpInf/LclInstrm/Cd'
    tx.PmtTpInf.LclInstrm.Prtry AS pmt_inf_pmt_tp_inf_lcl_instrm_prtry, -- '/Document/CstmrCdtTrfInitn/PmtInf/PmtTpInf/LclInstrm/Prtry'
    tx.PmtTpInf.SeqTp AS pmt_inf_pmt_tp_inf_seq_tp, -- '/Document/CstmrCdtTrfInitn/PmtInf/PmtTpInf/SeqTp'
    tx.PmtTpInf.CtgyPurp.Cd AS pmt_inf_pmt_tp_inf_ctgy_purp_cd, -- '/Document/CstmrCdtTrfInitn/PmtInf/PmtTpInf/CtgyPurp/Cd'
    tx.PmtTpInf.CtgyPurp.Prtry AS pmt_inf_pmt_tp_inf_ctgy_purp_prtry, -- '/Document/CstmrCdtTrfInitn/PmtInf/PmtTpInf/CtgyPurp/Prtry'
    tx.ReqdExctnDt.Dt AS pmt_inf_reqd_exctn_dt_dt, -- '/Document/CstmrCdtTrfInitn/PmtInf/ReqdExctnDt/Dt'
    tx.ReqdExctnDt.DtTm AS pmt_inf_reqd_exctn_dt_dt_tm, -- '/Document/CstmrCdtTrfInitn/PmtInf/ReqdExctnDt/DtTm'
    tx.Dbtr.Nm AS pmt_inf_dbtr_nm, -- '/Document/CstmrCdtTrfInitn/PmtInf/Dbtr/Nm'
    tx.Dbtr.PstlAdr.StrtNm AS pmt_inf_dbtr_pstl_adr_strt_nm, -- '/Document/CstmrCdtTrfInitn/PmtInf/Dbtr/PstlAdr/StrtNm'
    tx.Dbtr.PstlAdr.BldgNb AS pmt_inf_dbtr_pstl_adr_bldg_nb, -- '/Document/CstmrCdtTrfInitn/PmtInf/Dbtr/PstlAdr/BldgNb'
    tx.Dbtr.PstlAdr.PstCd AS pmt_inf_dbtr_pstl_adr_pst_cd, -- '/Document/CstmrCdtTrfInitn/PmtInf/Dbtr/PstlAdr/PstCd'
    tx.Dbtr.PstlAdr.TwnNm AS pmt_inf_dbtr_pstl_adr_twn_nm, -- '/Document/CstmrCdtTrfInitn/PmtInf/Dbtr/PstlAdr/TwnNm'
    tx.Dbtr.PstlAdr.Ctry AS pmt_inf_dbtr_pstl_adr_ctry, -- '/Document/CstmrCdtTrfInitn/PmtInf/Dbtr/PstlAdr/Ctry'
    tx.DbtrAcct.Id.IBAN AS pmt_inf_dbtr_acct_id_iban, -- '/Document/CstmrCdtTrfInitn/PmtInf/DbtrAcct/Id/IBAN'
    tx.DbtrAcct.Id.Othr.Id AS pmt_inf_dbtr_acct_id_othr_id, -- '/Document/CstmrCdtTrfInitn/PmtInf/DbtrAcct/Id/Othr/Id'
    tx.DbtrAgt.FinInstnId.BICFI AS pmt_inf_dbtr_agt_fin_instn_id_bicfi, -- '/Document/CstmrCdtTrfInitn/PmtInf/DbtrAgt/FinInstnId/BICFI'
    tx.DbtrAgt.FinInstnId.LEI AS pmt_inf_dbtr_agt_fin_instn_id_lei, -- '/Document/CstmrCdtTrfInitn/PmtInf/DbtrAgt/FinInstnId/LEI'
    tx.UltmtDbtr.Nm AS pmt_inf_ultmt_dbtr_nm, -- '/Document/CstmrCdtTrfInitn/PmtInf/UltmtDbtr/Nm'
    tx.ChrgBr AS pmt_inf_chrg_br, -- '/Document/CstmrCdtTrfInitn/PmtInf/ChrgBr'
    tx.CdtTrfTxInf[0].PmtId.InstrId AS pmt_inf_cdt_trf_tx_inf_pmt_id_instr_id, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/PmtId/InstrId'
    tx.CdtTrfTxInf[0].PmtId.EndToEndId AS pmt_inf_cdt_trf_tx_inf_pmt_id_end_to_end_id, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/PmtId/EndToEndId'
    tx.CdtTrfTxInf[0].PmtId.UETR AS pmt_inf_cdt_trf_tx_inf_pmt_id_uetr, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/PmtId/UETR'
    tx.CdtTrfTxInf[0].Amt.InstdAmt._VALUE AS pmt_inf_cdt_trf_tx_inf_amt_instd_amt, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Amt/InstdAmt'
    tx.CdtTrfTxInf[0].Amt.InstdAmt._Ccy AS pmt_inf_cdt_trf_tx_inf_amt_instd_amt_ccy, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Amt/InstdAmt/@Ccy'
    tx.CdtTrfTxInf[0].Amt.EqvtAmt.Amt._VALUE AS pmt_inf_cdt_trf_tx_inf_amt_eqvt_amt_amt, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Amt/EqvtAmt/Amt'
    tx.CdtTrfTxInf[0].Amt.EqvtAmt.Amt._Ccy AS pmt_inf_cdt_trf_tx_inf_amt_eqvt_amt_amt_ccy, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Amt/EqvtAmt/Amt/@Ccy'
    tx.CdtTrfTxInf[0].Amt.EqvtAmt.CcyOfTrf AS pmt_inf_cdt_trf_tx_inf_amt_eqvt_amt_ccy_of_trf, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Amt/EqvtAmt/CcyOfTrf'
    tx.CdtTrfTxInf[0].CdtrAgt.FinInstnId.BICFI AS pmt_inf_cdt_trf_tx_inf_cdtr_agt_fin_instn_id_bicfi, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/CdtrAgt/FinInstnId/BICFI'
    tx.CdtTrfTxInf[0].CdtrAgt.FinInstnId.LEI AS pmt_inf_cdt_trf_tx_inf_cdtr_agt_fin_instn_id_lei, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/CdtrAgt/FinInstnId/LEI'
    tx.CdtTrfTxInf[0].Cdtr.Nm AS pmt_inf_cdt_trf_tx_inf_cdtr_nm, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Cdtr/Nm'
    tx.CdtTrfTxInf[0].Cdtr.PstlAdr.StrtNm AS pmt_inf_cdt_trf_tx_inf_cdtr_pstl_adr_strt_nm, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/StrtNm'
    tx.CdtTrfTxInf[0].Cdtr.PstlAdr.BldgNb AS pmt_inf_cdt_trf_tx_inf_cdtr_pstl_adr_bldg_nb, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/BldgNb'
    tx.CdtTrfTxInf[0].Cdtr.PstlAdr.PstCd AS pmt_inf_cdt_trf_tx_inf_cdtr_pstl_adr_pst_cd, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/PstCd'
    tx.CdtTrfTxInf[0].Cdtr.PstlAdr.TwnNm AS pmt_inf_cdt_trf_tx_inf_cdtr_pstl_adr_twn_nm, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/TwnNm'
    tx.CdtTrfTxInf[0].Cdtr.PstlAdr.Ctry AS pmt_inf_cdt_trf_tx_inf_cdtr_pstl_adr_ctry, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Cdtr/PstlAdr/Ctry'
    tx.CdtTrfTxInf[0].CdtrAcct.Id.IBAN AS pmt_inf_cdt_trf_tx_inf_cdtr_acct_id_iban, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/CdtrAcct/Id/IBAN'
    tx.CdtTrfTxInf[0].CdtrAcct.Id.Othr.Id AS pmt_inf_cdt_trf_tx_inf_cdtr_acct_id_othr_id, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/CdtrAcct/Id/Othr/Id'
    tx.CdtTrfTxInf[0].UltmtCdtr.Nm AS pmt_inf_cdt_trf_tx_inf_ultmt_cdtr_nm, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/UltmtCdtr/Nm'
    tx.CdtTrfTxInf[0].Purp.Cd AS pmt_inf_cdt_trf_tx_inf_purp_cd, -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Purp/Cd'
    tx.CdtTrfTxInf[0].Purp.Prtry AS pmt_inf_cdt_trf_tx_inf_purp_prtry -- '/Document/CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf/Purp/Prtry'
FROM parsed_xml
LATERAL VIEW EXPLODE(xml_struct.CstmrCdtTrfInitn.PmtInf) t AS tx
