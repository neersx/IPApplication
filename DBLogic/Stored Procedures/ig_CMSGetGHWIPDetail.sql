-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ig_CMSGetGHWIPDetail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ig_CMSGetGHWIPDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ig_CMSGetGHWIPDetail.'
	Drop procedure [dbo].[ig_CMSGetGHWIPDetail]
End
Print '**** Creating Stored Procedure dbo.ig_CMSGetGHWIPDetail...'
Print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.ig_CMSGetGHWIPDetail
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pnEntityNo		int,
	@pnTransNo		int,
	@pnWIPSeqNo		smallint

)
as
-- PROCEDURE :	ig_CMSGetGHWIPDetail
-- VERSION :	6
-- DESCRIPTION:	Returns WorkInProgress details to be used in Integration with CMS
-- COPYRIGHT:	Copyright 1993 - 2005 CPA Software Solutions (Australia) Pty Limited
--
--		The following details will be returned :
--			ClientCode	NAME via CASENAME where NAMETYPE='D'	NAMECODE	From the associated name with name type = "debtor"
--			IRN		CASES via CASEID			IRN	
--			DIEmplCode	NAME via CASENAME where NAMETYPE='EMP'	NAMECODE	Staff Responsible
--			BLEmplCode	NAME via CASENAME where NAMETYPE='SIG'	NAMECODE	If no signatory, use the staff responsible
--			WIPCode		WORKHISTORY				WIPCODE		"Will need to map to either a disbursement type code or an Action code:Gov Fees = Disbursment Scale Charge = Action code"
--			DIOfficeCode	OFFICE via CASES.OFFICEID via CASEID	DESCRIPTION	
--			CurrencyCode	WORKHISTORY	if FOREIGNCURRENCY is NULL then 'AUD' else FOREIGNCURRENCY	
--			TransDate	WORKHISTORY				TRANSDATE	Format as YYMMDD
--			BaseQty		"1"
--			BillQty		"1"
--			LocalValue	WORKHISTORY				LOCALVALUE	
--			CallInfoReqd	"N"
--			ReferenceNo	NAME via CASENAME where NAMETYPE = 'D'	REFERENCENO	From the associated name with name type = "debtor"
--			PrebillComments WORKHISTORY				SHORTNARRATIVE	May want to attach a std prebill comment of "Inprotech Generated" to assist staff when invoicing.
--			DataRetrievalStatus 'I'



-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Nov 2005	MF	11022	1	Procedure created
-- 05 Dec 2005	PK	11022	2	Added DataRetrievalStatus return value
-- 01 Mar 2006	DJP	12294	3	Various corrections and additions reported from initial testing
-- 28 Jun 2006	PK	3897	4	Return null string as empty string
-- 04 Mar 2009	PK	7646	5	Use WorkHistory staff for DIEmplCode instead if Case staff for PD and SC Category only
-- 11 Dec 2008	MF	17136	6	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
		
set nocount on
set concat_null_yields_null off

Declare		@ErrorCode	int
Declare		@nRowCount	int

Declare		@sSQLString	nvarchar(4000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	top 1
		NI.NAMECODE 				as [ClientCode],
		C.IRN 					as [IRN],
		isnull(NDI.NAMECODE,EMP.NAMECODE)	as [DIEmplCode],
		isnull(SIG.NAMECODE,EMP.NAMECODE)
							as [BLEmplCode],
		WT.CATEGORYCODE				as [WIPCategory],
		W.WIPCODE 				as [WIPCode],
		O.USERCODE				as [DIOfficeCode],
		isnull(W.FOREIGNCURRENCY,S.COLCHARACTER) 
							as [CurrencyCode],
		W.TRANSDATE	 			as [TransDate],
		'1' 					as [BaseQty],
		'1' 					as [BillQty],
		isnull(W.FOREIGNTRANVALUE,W.LOCALTRANSVALUE)
							as [Amount],
		'N' 					as [CallInfoReqd],
		isnull(CND.REFERENCENO,'') 	as [ReferenceNo],
		isnull(W.SHORTNARRATIVE,'')	as [PrebillComments],
		'I'					as [DataRetrievalStatus]
	From WORKHISTORY W
	left join CASES C	on (C.CASEID=W.CASEID)
	left join OFFICE O	on (O.OFFICEID=C.OFFICEID)
	left join SITECONTROL S on (S.CONTROLID='CURRENCY')

	left join CASENAME CNS	on (CNS.CASEID=C.CASEID
				and CNS.NAMETYPE='SIG'
				and CNS.EXPIRYDATE is null)
	left join NAME SIG	on (SIG.NAMENO=CNS.NAMENO)

	left join CASENAME CNE	on (CNE.CASEID=C.CASEID
				and CNE.NAMETYPE='EMP'
				and CNE.EXPIRYDATE is null)
	left join NAME EMP	on (EMP.NAMENO=CNE.NAMENO)

	left join CASENAME CNI	on (CNI.CASEID=C.CASEID
				and CNI.NAMETYPE='I'
				and CNI.EXPIRYDATE is null)
	left join NAME NI	on (NI.NAMENO=CNI.NAMENO)
	left join CASENAME CND	on (CND.CASEID=C.CASEID
				and CND.NAMETYPE='D'
				and CND.EXPIRYDATE is null)
	left join NAME NDI	on (NDI.NAMENO = W.EMPLOYEENO)
	left join WIPTEMPLATE T	on (T.WIPCODE = W.WIPCODE)
	left join WIPTYPE WT	on (WT.WIPTYPEID = T.WIPTYPEID)
	Where W.ENTITYNO=@pnEntityNo
	and W.TRANSNO   =@pnTransNo
	and W.WIPSEQNO  =@pnWIPSeqNo
	and W.HISTORYLINENO=1
	and WT.CATEGORYCODE IN ('PD','SC')"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnEntityNo	int,
				  @pnTransNo	int,
				  @pnWIPSeqNo	smallint',
				  @pnEntityNo=@pnEntityNo,
				  @pnTransNo=@pnTransNo,
				  @pnWIPSeqNo=@pnWIPSeqNo
End

return @ErrorCode
go

grant execute on dbo.ig_CMSGetGHWIPDetail to public
go
