-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_ListMarketingActivities
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_ListMarketingActivities]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_ListMarketingActivities.'
	Drop procedure [dbo].[crm_ListMarketingActivities]
End
Print '**** Creating Stored Procedure dbo.crm_ListMarketingActivities...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_ListMarketingActivities
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,	-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	crm_ListMarketingActivities
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List cases where the current name is a Contact (Invitees) in any
--				Marketing Activities cases

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 June 2008	SF	6535	1	Procedure created
-- 24 Oct 2011	ASH	R11460  2	Cast integer columns as nvarchar(11) data type.
-- 15 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer
-- 04 Nov 2015	KR	R53910	4	Adjust formatted names logic (DR-15543)


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
		C.CASEID						as 'MarketingActivityKey',
		C.IRN							as 'MarketingActivityReference',
		N.NAMENO						as 'ManagerNameKey',
		N.NAMECODE						as 'ManagerNameCode',"+char(10)+
		-- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
		-- fn_FormatName, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last)   
		"dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+CHAR(10)+  	
		"			as 'ManagerName',"+CHAR(10)+  
		+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCCST',
							@sLookupCulture,@pbCalledFromCentura) +
		"					as StatusDescription,"+char(10)+
		dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)+" as TypeDescription,"+char(10)+
		dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,@pbCalledFromCentura)+" as CategoryDescription,"+char(10)+
		"CE.EVENTDATE		as 'LastModified'
		from CASES C"+char(10)+
		-- get valid description of the kind of Marketing Activities --
		"join CASETYPE CS on (CS.CASETYPE=C.CASETYPE)"+char(10)+
		"join COUNTRY CT on (CT.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
		"join VALIDPROPERTY VP on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				"and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)"+char(10)+
				"from VALIDPROPERTY VP1"+char(10)+
				"where VP1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				"and VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+	
		"left join PROPERTY P		on (P.CASEID = C.CASEID)"+char(10)+
		"left join VALIDCATEGORY VC on (VC.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				"and VC.CASETYPE=C.CASETYPE"+char(10)+
				"and VC.CASECATEGORY=C.CASECATEGORY"+char(10)+
				"and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)"+char(10)+
				"from VALIDCATEGORY VC1"+char(10)+
				"where VC1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				"and VC1.CASETYPE=C.CASETYPE"+char(10)+
				"and VC1.CASECATEGORY=C.CASECATEGORY"+char(10)+
				"and VC1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
		-- only return cases where the @pnNameKey is a Contact
		"join CASENAME Contact on (C.CASEID = Contact.CASEID and Contact.NAMETYPE = '~CN' and Contact.NAMENO = @pnNameKey)"+char(10)+
		-- get the manager of the marketing activity (EMP)
		"left join CASENAME Manager on (C.CASEID = Manager.CASEID and Manager.NAMETYPE = 'EMP')
		left join NAME N on (N.NAMENO = Manager.NAMENO)
		left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)"+char(10)+
		-- get last modified date
		"left join CASEEVENT CE on (CE.CASEID = C.CASEID and CE.EVENTNO = -14)"+char(10)+
		-- get the last status of the marketing activity
		"left join (	select	CASEID, 
							MAX( convert(nvarchar(24),LOGDATETIMESTAMP, 21)+cast(STATUSID as nvarchar(11)) ) as [DATE]
				from CRMCASESTATUSHISTORY
				group by CASEID	
				) LASTMODIFIED on (LASTMODIFIED.CASEID = C.CASEID)
		left join CRMCASESTATUSHISTORY	CSH	on (CSH.CASEID = C.CASEID
			and ( (convert(nvarchar(24),CSH.LOGDATETIMESTAMP, 21)+cast(CSH.STATUSID as nvarchar(11))) = LASTMODIFIED.[DATE]
				or LASTMODIFIED.[DATE] is null ))
		left join TABLECODES TCCST 	on (TCCST.TABLECODE 	= CSH.CRMCASESTATUS)"+char(10)+
		"where C.CASETYPE = 'M'"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey			int',
				@pnNameKey			= @pnNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.crm_ListMarketingActivities to public
GO
