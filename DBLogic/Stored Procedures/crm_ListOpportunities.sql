-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_ListOpportunities
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_ListOpportunities]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_ListOpportunities.'
	Drop procedure [dbo].[crm_ListOpportunities]
End
Print '**** Creating Stored Procedure dbo.crm_ListOpportunities...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_ListOpportunities
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,	-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	crm_ListOpportunities
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List Opportunities where the current name (or with lead for relationship) is being targetted for work

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 June 2008	SF	6535	1	Procedure created
-- 03 July 2008	SF	6535	2	Join Opportunity to Case
-- 17 July 2008	SF	6508	3	Stage has been removed. Return Status instead.
-- 24 Oct 2011	ASH	R11460  4	Cast integer columns as nvarchar(11) data type.
-- 15 Apr 2013	DV	R13270	5	Increase the length of nvarchar to 11 when casting or declaring integer
-- 04 Nov 2015	KR	R53910	6	Adjust formatted names logic (DR-15543)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode				int
Declare @sLookupCulture			nvarchar(10)
Declare @sSQLString 			nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select 
		cast(C.CASEID as nvarchar(11))+'^'+cast(@pnNameKey as nvarchar(11))
										as 'RowKey',
		@pnNameKey						as 'NameKey',
		C.CASEID						as 'OpportunityKey',
		C.IRN							as 'OpportunityReference',
		N.NAMENO						as 'ProspectNameKey',
		N.NAMECODE						as 'ProspectNameCode',"+char(10)+
		-- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
		-- fn_FormatName, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last)   
		"dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+CHAR(10)+  	
		"			as 'ProspectName',"+CHAR(10)+  
		"O.POTENTIALVALUE	as 'PotentialValue',
		ISNULL(O.POTENTIALVALCURRENCY, SC.COLCHARACTER)	as 'PotentialValueCurrency',"+CHAR(10)+
		+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCCST',
							@sLookupCulture,@pbCalledFromCentura) +
		"					as Status,"+char(10)+
		dbo.fn_SqlTranslatedColumn('OPPORTUNITY','NEXTSTEP',null,'O',@sLookupCulture,@pbCalledFromCentura)+
		"					as NextStep,
		CE.EVENTDATE		as 'LastModified'
		from CASES C
		join SITECONTROL SCPROP on (			UPPER(SCPROP.CONTROLID) = 'PROPERTY TYPE OPPORTUNITY' and 
												C.PROPERTYTYPE = SCPROP.COLCHARACTER)
		left join ASSOCIATEDNAME LeadFor on (	LeadFor.RELATEDNAME = @pnNameKey and
												LeadFor.RELATIONSHIP = 'LEA')
		join CASENAME CN on (					C.CASEID = CN.CASEID and 
												((CN.NAMETYPE = '~PR' and CN.NAMENO = LeadFor.NAMENO) or
												(CN.NAMETYPE = '~PR' and CN.NAMENO = @pnNameKey))) 
		left join NAME N on (N.NAMENO = CN.NAMENO)
		left join OPPORTUNITY O on (O.CASEID = C.CASEID)
		join SITECONTROL SC on (UPPER(SC.CONTROLID) = 'CURRENCY')
		left join CASEEVENT CE on (CE.CASEID = C.CASEID and CE.EVENTNO = -14)
		left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY) 		
		--- get the latest CRM Case Status for the Opportunity
		left join (	select	CASEID, 
							MAX( convert(nvarchar(24),LOGDATETIMESTAMP, 21)+cast(CRMCASESTATUS as nvarchar(11)) ) as [DATE]
				from CRMCASESTATUSHISTORY
				group by CASEID	
				) LASTMODIFIED on (LASTMODIFIED.CASEID = O.CASEID)
		left join CRMCASESTATUSHISTORY	CSH	on (CSH.CASEID = O.CASEID
			and ( (convert(nvarchar(24),CSH.LOGDATETIMESTAMP, 21)+cast(CSH.CRMCASESTATUS as nvarchar(11))) = LASTMODIFIED.[DATE]
				or LASTMODIFIED.[DATE] is null ))
		left join TABLECODES TCCST 	on (TCCST.TABLECODE 	= CSH.CRMCASESTATUS)
		and C.CASETYPE = 'O'"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey			int',
				@pnNameKey			= @pnNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.crm_ListOpportunities to public
GO
