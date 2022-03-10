-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_FetchOpportunityDetail									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_FetchOpportunityDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_FetchOpportunityDetail.'
	Drop procedure [dbo].[crm_FetchOpportunityDetail]
End
Print '**** Creating Stored Procedure dbo.crm_FetchOpportunityDetail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.crm_FetchOpportunityDetail
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int 		-- Mandatory
)
as
-- PROCEDURE:	crm_FetchOpportunityDetail
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the CaseDetailData Opportunity dataset

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 17 Jun 2008	AT	RFC5748	1	Procedure created
-- 04 Aug 2008	AT	RFC5749	2	Left Join on Opportunity table.
-- 20 Aug 2008	AT	RFC6894	3	Return local value if no foreign value.
-- 26 Aug 2008	AT	RFC5712	4	Fix return of status.
-- 29 Aug 2008  LP      RFC5751 5       Return IsClient column.
-- 24 Oct 2011	ASH	R11460  6	Cast integer columns as nvarchar(11) data type.
-- 02 Nov 2015	vql	R53910	7	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select

	CAST(C.CASEID as nvarchar(11))	as RowKey,
	C.CASEID			as CaseKey,
	C.IRN				as OpportunityReference,
	isnull(O.POTENTIALVALUE, O.POTENTIALVALUELOCAL)	as PotentialValue,
	O.SOURCE			as Source,
	SOURCE.DESCRIPTION		as SourceDescription,
	STATUS.DESCRIPTION		as StatusDescription,
	O.EXPCLOSEDATE			as ExpCloseDate,
	"+dbo.fn_SqlTranslatedColumn('OPPORTUNITY','REMARKS',null,'O',
					@sLookupCulture,@pbCalledFromCentura)+
	" as Remarks,
	O.POTENTIALWIN			as PotentialWin,
	"+dbo.fn_SqlTranslatedColumn('OPPORTUNITY','NEXTSTEP',null,'O',
					@sLookupCulture,@pbCalledFromCentura)+
	" as NextStep,
--	O.STAGE				as Stage,
	CASE WHEN O.POTENTIALVALUE IS NULL THEN NULL ELSE O.POTENTIALVALCURRENCY END	as PotentialValCurrency,
	CASE WHEN O.POTENTIALVALUE IS NULL THEN NULL ELSE "+dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CUR',
					@sLookupCulture,@pbCalledFromCentura)+ "
		END		as PotentialValCurrencyDesc,
	O.NUMBEROFSTAFF			as NumberOfStaff,
	dbo.fn_FormatNameUsingNameNo(EMP.NAMENO, NULL) as OpportunityOwner,
	EMP.NAMENO as OwnerNameKey,
	EMP.NAMECODE as OwnerNameCode,
	dbo.fn_FormatNameUsingNameNo(PRS.NAMENO, NULL)  as Prospect,
	PRS.NAMENO as ProspectNameKey,
	PRS.NAMECODE as ProspectNameCode,
	CASE WHEN PRS.USEDASFLAG&4=4 THEN 1 ELSE 0 END as IsClient
	from CASES C
	left join OPPORTUNITY O ON (O.CASEID = C.CASEID)
	left join CURRENCY CUR ON (CUR.CURRENCY = O.POTENTIALVALCURRENCY)
	left join TABLECODES SOURCE on (SOURCE.TABLECODE = O.SOURCE)
	left join 
		(select NAME.NAMENO, NAME.NAMECODE, NAME.NAME, NAME.FIRSTNAME, NAME.TITLE, CNEMP.CASEID FROM NAME
		JOIN (SELECT TOP 1 CASEID, NAMENO
			FROM CASENAME 
			WHERE CASEID = @pnCaseKey
			AND NAMETYPE = 'EMP'
			ORDER BY SEQUENCE) as CNEMP ON (CNEMP.NAMENO = NAME.NAMENO)) as EMP
	on (EMP.CASEID = C.CASEID)
	left join 
		(select NAME.NAMENO, NAME.NAMECODE, NAME.NAME, NAME.FIRSTNAME, NAME.TITLE, CNPRS.CASEID, NAME.USEDASFLAG FROM NAME
			JOIN (SELECT TOP 1 CASEID, NAMENO
				FROM CASENAME 
				WHERE CASEID = @pnCaseKey
				AND NAMETYPE = '~PR'
				ORDER BY SEQUENCE) as CNPRS ON (CNPRS.NAMENO = NAME.NAMENO)) as PRS
	on (PRS.CASEID = C.CASEID)
	left join
		(select TOP 1 CCS.CASEID, TCCCS.DESCRIPTION 
		from CRMCASESTATUSHISTORY CCS
		join TABLECODES TCCCS ON (TCCCS.TABLECODE = CCS.CRMCASESTATUS)
		WHERE CCS.CASEID = @pnCaseKey
		ORDER BY CCS.LOGDATETIMESTAMP DESC) as STATUS
	on (STATUS.CASEID = C.CASEID)
	where 
	C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnCaseKey		int',
			@pnCaseKey	 = @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.crm_FetchOpportunityDetail to public
GO