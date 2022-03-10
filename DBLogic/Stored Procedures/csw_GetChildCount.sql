-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetChildCount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetChildCount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetChildCount.'
	Drop procedure [dbo].[csw_GetChildCount]
End
Print '**** Creating Stored Procedure dbo.csw_GetChildCount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetChildCount
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnDocumentControlKey	int,		-- Mandatory
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	csw_GetChildCount
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the number of records for each distinct tabs/topics included in 
--		the given screen control rule for the case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 OCT 2011	SF	R10553	1	Procedure created; Sample impl only, incomplete.
-- 22 Feb 2012  MS      R11186  2       Added Journal tab count
-- 17 Apr 2012  MS      R11154  3       Modified Case Text tab count

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(max)
declare @sLookupCulture	nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

create table #TEMPTOPICCOUNT
		(	
			ROW		int	identity(1,1) not null,
			TOPICNAME	nvarchar(100) collate database_default not null,
			FILTERNAME	nvarchar(100) collate database_default null,
			FILTERVALUE	nvarchar(508) collate database_default null,
			[COUNT]		int default 0
		)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- get all topics which should have a count associated with the topic
	-- exclude all topics where count does not makes sense to be displayed on tab header
	Set @sSQLString="
		insert into #TEMPTOPICCOUNT (TOPICNAME, FILTERNAME, FILTERVALUE)
		select	TOPICNAME, FILTERNAME, FILTERVALUE
		from	TOPICCONTROL 
		where	WINDOWCONTROLNO = @pnDocumentControlKey
		and	TOPICNAME not in 
		(
			'CaseOtherDetails_Component',
			'Actions_Component',
			'PTA_Component',
			'CaseRenewals_Component',
			'ContactActivitySummary_Component',
			'WIP_Component',
			'Events_Component',
			'MarketingActivities_HeaderTopic',
			'BillingInstructions_Component',
			'CaseBilling_Component',
			'CriticalDates_Component',
			'CaseFirstUse_Component'
		)
	"
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnDocumentControlKey	int',
				@pnDocumentControlKey	= @pnDocumentControlKey
End

If @nErrorCode = 0
Begin
	Update #TEMPTOPICCOUNT
		SET [COUNT] =	
			CASE TOPICNAME
				WHEN 'OfficialNumbers_Component' THEN 
					(Select COUNT(*) from OFFICIALNUMBERS where CASEID = @pnCaseKey) 
						
				WHEN 'Images_Component' THEN 
					(Select COUNT(*) from CASEIMAGE where CASEID = @pnCaseKey)
					
				WHEN 'Attributes_Component' THEN  
					(Select COUNT(*)
						from TABLEATTRIBUTES T
						join TABLETYPE TY 	on (TY.TABLETYPE = T.TABLETYPE)
						left join TABLECODES A 	on (A.TABLECODE = T.TABLECODE)
						left join OFFICE O	on (O.OFFICEID = T.TABLECODE)
						where 	T.PARENTTABLE = 'CASES'
						and	T.GENERICKEY  = CAST(@pnCaseKey as nvarchar(15)))
	
				WHEN 'RelatedCases_Component' THEN 
					(Select COUNT(*) 
						from RELATEDCASE RC
						join CASERELATION CR	on (CR.RELATIONSHIP = RC.RELATIONSHIP)
						where RC.CASEID = @pnCaseKey
						and   CR.SHOWFLAG = 1)
						
				WHEN 'PriorArt_Component' THEN 
					(Select COUNT(*) 
						from CASESEARCHRESULT CSR
						join SEARCHRESULTS SR on (SR.PRIORARTID = CSR.PRIORARTID)
						where CSR.CASEID = @pnCaseKey)
						
				WHEN 'DesignatedCountries_Component' THEN 
					(Select COUNT(*)	
						from CASES C                                                           
						join RELATEDCASE R		on (R.CASEID = C.CASEID
										and R.RELATIONSHIP = 'DC1')
						join COUNTRY CT			on (CT.COUNTRYCODE = R.COUNTRYCODE)
						left join COUNTRYFLAGS CF	on (CF.COUNTRYCODE = C.COUNTRYCODE
										and CF.FLAGNUMBER = R.CURRENTSTATUS)
						join COUNTRYGROUP G             ON (G.MEMBERCOUNTRY = R.COUNTRYCODE)
					where G.TREATYCODE = CF.COUNTRYCODE and C.CASEID=@pnCaseKey)
	
				
				WHEN 'DesignElement_Component' THEN 
					(Select COUNT(*) from DESIGNELEMENT D where D.CASEID = @pnCaseKey)
					
				-- where appropriate, look at the FILTERNAME/FILTERVALUE
				-- when filtering by TextTYPE is implemented, review the following
				WHEN 'Case_TextTopic' THEN 
					(Select dbo.fn_GetCaseTextCount(@pnUserIdentityId, 
					                @psCulture, 
				                        @pnDocumentControlKey, 
				                        @pnCaseKey, 
				                        FILTERVALUE))
				
				-- the following to be reviewed/implemented; 
				-- some of them could take as much time to count as to return the data
				WHEN 'RecentContacts_Component' THEN 0
				WHEN 'CaseStandingInstructions_Component' THEN 	0
				WHEN 'CRMCaseStatusHistory_Component' THEN 0
				WHEN 'Names_Component' THEN 0
				WHEN 'Classes_Component' THEN 0
				WHEN 'CaseJournal_Component' THEN 
					(Select COUNT(*) from JOURNAL where CASEID = @pnCaseKey) 
			END
End

If @nErrorCode = 0
Begin

	Set @sSQLString="
		Select	TOPICNAME	as TopicName, 
			FILTERNAME	as FilterName, 
			FILTERVALUE	as FilterValue,
			[COUNT]		as Count
		from	#TEMPTOPICCOUNT 
	"
	exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetChildCount to public
GO
