-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_FetchMarketingDetail									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_FetchMarketingDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_FetchMarketingDetail.'
	Drop procedure [dbo].[crm_FetchMarketingDetail]
End
Print '**** Creating Stored Procedure dbo.crm_FetchMarketingDetail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_FetchMarketingDetail
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int -- Mandatory
)
as
-- PROCEDURE:	crm_FetchMarketingDetail
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Marketing business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 22 Aug 2008	AT	RFC5712	1	Procedure created.
-- 03 Oct 2008	AT	RFC7118	2	Added Staff/Contacts Attended.
-- 14 Feb 2011	ASH	RFC9876	3	Added ContactsSent Column in result set.
-- 24 Oct 2011	ASH	R11460 	4	Cast integer columns as nvarchar(11) data type.
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0

Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
	CAST(M.CASEID as nvarchar(11))	as RowKey,
	M.CASEID			as CaseKey,
	C.IRN				as MarketingReference,
	MAN.NAMENO 			as ManagerNameKey,
	MAN.NAMECODE 			as ManagerNameCode,
	dbo.fn_FormatNameUsingNameNo(MAN.NAMENO, NULL) as Manager,
	VC.CASECATEGORY			as CaseCategory,
	"+dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',
					@sLookupCulture,@pbCalledFromCentura)+
	"				as CaseCategoryDescription,
	STATUS.DESCRIPTION		as StatusDescription,
	C.BUDGETAMOUNT			as BudgetAmount,
	isnull(M.ACTUALCOST,M.ACTUALCOSTLOCAL) as ActualCost,
	CASE WHEN M.ACTUALCOST IS NULL THEN NULL ELSE M.ACTUALCOSTCURRENCY END	as ActualCostCurrency,
	isnull(CC.CONTACTSCOUNT,0) 	as Contacted,
	M.EXPECTEDRESPONSES		as ExpectedResponses,
	isnull(CR.CONTACTSRESPONDED,0)	as ActualResponses,
	ISNULL(OPS.OPPORTUNITYCOUNT,0)	as NewOpportunities,
	M.STAFFATTENDED			as StaffAttended,
	M.CONTACTSATTENDED		as ContactsAttended,
	isnull(CN.CONTACTSEND,0)  as ContactsSent
	from CASES C
	left join MARKETING M on (M.CASEID = C.CASEID)
	left join (select NAME.NAMENO, NAME.NAMECODE, NAME.NAME, NAME.FIRSTNAME, NAME.TITLE, CNMAN.CASEID FROM NAME
			JOIN (SELECT TOP 1 CASEID, NAMENO
				FROM CASENAME 
				WHERE CASEID = @pnCaseKey
				AND NAMETYPE = 'EMP'
				ORDER BY SEQUENCE) as CNMAN ON (CNMAN.NAMENO = NAME.NAMENO)) as MAN
	on (MAN.CASEID = C.CASEID)
	left join VALIDCATEGORY VC on (VC.PROPERTYTYPE=C.PROPERTYTYPE
				and VC.CASETYPE=C.CASETYPE
				and VC.CASECATEGORY=C.CASECATEGORY
				and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)
						from VALIDCATEGORY VC1
						where VC1.PROPERTYTYPE=C.PROPERTYTYPE
						and VC1.CASETYPE=C.CASETYPE
						and VC1.CASECATEGORY=C.CASECATEGORY
						and VC1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
	left join
		(select TOP 1 CCS.CASEID, TCCCS.DESCRIPTION 
		from CRMCASESTATUSHISTORY CCS
		join TABLECODES TCCCS ON (TCCCS.TABLECODE = CCS.CRMCASESTATUS)
		WHERE CCS.CASEID = @pnCaseKey
		ORDER BY CCS.LOGDATETIMESTAMP DESC) as STATUS
	on (STATUS.CASEID = C.CASEID)
	left join (select CASEID, COUNT(NAMENO) as CONTACTSCOUNT
			from CASENAME 
			WHERE NAMETYPE = '~CN'
			AND CASEID = @pnCaseKey
			GROUP BY CASEID) as CC on (CC.CASEID = C.CASEID)
	left join (select CASEID, COUNT(CORRESPSENT) as CONTACTSEND
			from CASENAME 
			WHERE NAMETYPE = '~CN'
			AND CASEID = @pnCaseKey and CORRESPSENT =1
			GROUP BY CASEID) as CN on (CN.CASEID = C.CASEID)
	left join (SELECT CASEID, COUNT(RELATEDCASEID) as OPPORTUNITYCOUNT
			FROM RELATEDCASE 
			WHERE RELATIONSHIP = '~OP'
			AND CASEID = @pnCaseKey
			GROUP BY CASEID) as OPS on (OPS.CASEID = C.CASEID)
	left join (select CASEID, COUNT(NAMENO) as CONTACTSRESPONDED
			from CASENAME 
			WHERE CORRESPRECEIVED IS NOT NULL
			AND CASEID = @pnCaseKey
			GROUP BY CASEID) as CR on (CR.CASEID = C.CASEID)
	where
	M.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnCaseKey		int',
			@pnCaseKey	 = @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.crm_FetchMarketingDetail to public
GO
