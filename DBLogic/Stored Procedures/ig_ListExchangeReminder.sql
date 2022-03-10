-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ig_ListExchangeReminder
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ig_ListExchangeReminder]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ig_ListExchangeReminder.'
	Drop procedure [dbo].[ig_ListExchangeReminder]
End
Print '**** Creating Stored Procedure dbo.ig_ListExchangeReminder...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ig_ListExchangeReminder
(
	@pnUserIdentityId	int		= null, 	-- Optional. The User Identity which needs to be synchronised. The following must be passed:
--								-- @pnUserIdentityId OR @pnStaffKey and @pdtDateCreated.
	@pnStaffKey		int		= null,		-- Optional. The EMPLOYEENO held against the reminder. 
	@pdtDateCreated		datetime	= null		-- Optional. The MESSAGESEQ held against the reminder.
)
as
-- PROCEDURE:	ig_ListExchangeReminder
-- VERSION:	14
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	The purpose of this stored procedure is to return the data that is required to create 
--		(or update) Exchange tasks or Appointments.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 31 AUG 2005	TM	RFC2952	1	Procedure created
-- 02 SEP 2005	TM	RFC2952	2	Test the permissions by joining to fn_PermissionsGrantedName.
-- 07 Sep 2005	JEK	RFC2952	3	Do not change date for specific reminder.  Ensure IsInitialised is not null.
-- 07 Sep 2005	JEK	RFC2952	4	Similar changes for Identity.  Exclude time from date range check.
-- 16 Sep 2005	JEK	RFC2952	5	Remove carriage returns from reminder message.
-- 21 Sep 2005	JEK	RFC2952	6	Still having problems with special characters
-- 27 Sep 2005	JEK	RFC3116	7	Remove carriage return from second result set.
-- 12 Jul 2006	SW	RFC3828	8	Pass getdate() to fn_Permission..
-- 19 Jan 2007	SM	RFC4967	9	Change data returned in Comments
-- 11 Dec 2008	MF	17136	10	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 20 Apr 2011	MF	RFC10333 11	Join EMPLOYEEREMINDER to ALERT using new ALERTNAMENO column which caters for Reminders that
--					have been sent to names that are different to the originating Alert.
-- 13 Sep 2011	ASH	R11175	12	Maintain Reminder Message in Foreign Language.
-- 05 Jul 2013	vql	R13629	13	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	14   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)

Declare @bIsIntegrationRequired	bit
Declare @bIsRemindersInExchange	bit

Declare @Date			nchar(2)
Declare @dtToday		datetime

-- Initialise variables
Set @nErrorCode 		= 0
Set @bIsIntegrationRequired 	= 0
Set @bIsRemindersInExchange 	= 0
Set @Date   			='DT'
Set @dtToday			= getdate()

If @nErrorCode = 0
and @pnUserIdentityId is not null
Begin
	-- Check that the user has permission for the exchange integration task:
	Set @sSQLString = "
	Select @bIsIntegrationRequired = 1
	from dbo.fn_PermissionsGranted(@pnUserIdentityId, 'TASK', 51, null, @dtToday) PG
	where PG.CanExecute = 1"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@bIsIntegrationRequired	bit				OUTPUT,
					  @pnUserIdentityId		int,
					  @dtToday			datetime',
					  @bIsIntegrationRequired	= @bIsIntegrationRequired	OUTPUT,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @dtToday			= @dtToday
		
	-- Check that the user has elected to display their reminders in Outlook:
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "	
		Select @bIsRemindersInExchange = 1
		from SETTINGVALUES SVIA	
		where SVIA.SETTINGID = 4
		and SVIA.IDENTITYID = @pnUserIdentityId"
	
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@bIsRemindersInExchange	bit				OUTPUT,
						  @pnUserIdentityId		int',
						  @bIsRemindersInExchange	= @bIsRemindersInExchange	OUTPUT,
						  @pnUserIdentityId		= @pnUserIdentityId
	End

	-- General Message Info result set
	Set @sSQLString = "
	Select 	C.IRN		 	as 'CaseReference',
		A.REFERENCE		as 'AlertReference',
		-- Carriage return causing 400 bad request error in Exchange.
		-- char(13) carriage return
		-- char(10) line feed
		-- char(32) space
		replace(replace(dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER',null,'SHORTMESSAGE','ER',null,0),char(13)+char(10),char(32)),char(10),char(32))
					as 'Message',
		ER.DUEDATE 		as 'DueDate',
		ER.REMINDERDATE		as 'ReminderDate',
		isnull(CO.COUNTRYADJECTIVE, CO.COUNTRY) + 
		CASE WHEN PT.PROPERTYNAME is not null THEN ' ' + replace(replace(PT.PROPERTYNAME,char(13)+char(10),char(32)),char(10),char(32)) END + 
		CASE WHEN C.CURRENTOFFICIALNO is not null THEN ' No: ' + C.CURRENTOFFICIALNO END + 
		CASE WHEN C.TITLE is not null THEN ' ' + replace(replace(C.TITLE,char(13)+char(10),char(32)),char(10),char(32)) END +
		CASE WHEN ER.COMMENTS is not null THEN ' Reminder Comments: ' + replace(replace(ER.COMMENTS, char(13)+char(10),char(32)),char(10),char(32)) END +
		CASE WHEN CE.EVENTTEXT is not null THEN ' Comments: ' + replace(replace(CE.EVENTTEXT,char(13)+char(10),char(32)),char(10),char(32)) END 
		as 'Comments',
		convert(bit, 
		CASE WHEN ISNULL(ISNULL(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL), A.IMPORTANCELEVEL)>=SC.COLINTEGER 
		     THEN 1 
		     ELSE 0 
		END)			as 'IsHighPriority',
		ER.EMPLOYEENO		as 'StaffKey',
		ER.MESSAGESEQ		as 'DateCreated'		
		from EMPLOYEEREMINDER ER		
		join USERIDENTITY UI		on (UI.NAMENO = ER.EMPLOYEENO)
		left join CASES C		on (C.CASEID = ER.CASEID)
		left join COUNTRY CO		on (C.COUNTRYCODE = CO.COUNTRYCODE)
		left join PROPERTYTYPE PT	on (C.PROPERTYTYPE = PT.PROPERTYTYPE)
		left join SITECONTROL SC	on (SC.CONTROLID = 'CRITICAL LEVEL')
		left join CASEEVENT CE		on (CE.CASEID = ER.CASEID
						and CE.EVENTNO = ER.EVENTNO
						and CE.CYCLE = ER.CYCLENO)
 		left join EVENTCONTROL EC	on (EC.EVENTNO = CE.EVENTNO
	 					and EC.CRITERIANO = CE.CREATEDBYCRITERIA)
		left join EVENTS E		on (E.EVENTNO = ER.EVENTNO)
		left join ALERT A		on (A.EMPLOYEENO = ER.ALERTNAMENO
						and A.SEQUENCENO = ER.SEQUENCENO
						and ER.EVENTNO IS NULL)		
	where UI.IDENTITYID = @pnUserIdentityId
	and   ER.REMINDERDATE"+dbo.fn_ConstructOperator(7,@Date,convert(nvarchar,getdate(),112),null,0)+"
	and  (@bIsIntegrationRequired = 1
	and   @bIsRemindersInExchange = 1)"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @bIsIntegrationRequired	bit,
					  @bIsRemindersInExchange	bit',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @bIsIntegrationRequired	= @bIsIntegrationRequired,
					  @bIsRemindersInExchange	= @bIsRemindersInExchange

	-- User Info result set
	If @nErrorCode = 0
	Begin	
		Set @sSQLString = "
		Select 	UI.IDENTITYID			as 'UserIdentityId',
			SVIC.COLCHARACTER		as 'Culture',
			isnull(SVIN.COLBOOLEAN,0) 	as 'IsUserInitialised',
			SVIM.COLCHARACTER		as 'Mailbox',
			isnull(SVIA.COLBOOLEAN,0)	as 'IsAlertRequired',
			convert(datetime, '1899-01-01 ' + cast(cast(ROUND((COALESCE(SVIT.COLDECIMAL, SVDT.COLDECIMAL, 9.00))*60,0) as int)/60 as varchar(10)) + ':' + cast(cast(ROUND((COALESCE(SVIT.COLDECIMAL, SVDT.COLDECIMAL, 9.00))*60,0) as int)%60 as varchar(10)), 120)
							as 'AlertTime'
			from USERIDENTITY UI
			-- Perferred Culture   
			left join SETTINGVALUES SVIC	on (SVIC.SETTINGID = 6
							and SVIC.IDENTITYID = @pnUserIdentityId)
			-- IsUserInitialised setting
			left join SETTINGVALUES SVIN	on (SVIN.SETTINGID = 1
							and SVIN.IDENTITYID = @pnUserIdentityId)
			-- Mailbox setting
			left join SETTINGVALUES SVIM	on (SVIM.SETTINGID = 3
							and SVIM.IDENTITYID = @pnUserIdentityId)
			-- IsAlertRequired
			left join SETTINGVALUES SVIA	on (SVIA.SETTINGID = 2
							and SVIA.IDENTITYID = @pnUserIdentityId)
			-- Extract the AlertTime default settings for the firm as a whole   
			-- if there is not a specific value for the @pnUserIdentityId:
			left join SETTINGVALUES SVIT	on (SVIT.SETTINGID = 5
							and SVIT.IDENTITYID = @pnUserIdentityId)
			left join SETTINGVALUES SVDT	on (SVDT.SETTINGID = 5
							and SVDT.IDENTITYID is null)			
		where UI.IDENTITYID = @pnUserIdentityId
		and  (@bIsIntegrationRequired = 1
		and   @bIsRemindersInExchange = 1)"
	
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnUserIdentityId		int,
						  @bIsIntegrationRequired	bit,
						  @bIsRemindersInExchange	bit',
						  @pnUserIdentityId		= @pnUserIdentityId,
						  @bIsIntegrationRequired	= @bIsIntegrationRequired,
						  @bIsRemindersInExchange	= @bIsRemindersInExchange
	End
End
Else
If  @nErrorCode = 0
and @pnStaffKey is not null
and @pdtDateCreated is not null
Begin
	-- General Message Info result set
	Set @sSQLString = "
	Select 	C.IRN		 	as 'CaseReference',
		A.REFERENCE		as 'AlertReference',
		replace(replace(dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER',null,'SHORTMESSAGE','ER',null,0),char(13)+char(10),char(32)),char(10),char(32))
					as 'Message',
		ER.DUEDATE 		as 'DueDate',
		ER.REMINDERDATE		as 'ReminderDate',
		isnull(CO.COUNTRYADJECTIVE, CO.COUNTRY) + 
		CASE WHEN PT.PROPERTYNAME is not null THEN ' ' + replace(replace(PT.PROPERTYNAME,char(13)+char(10),char(32)),char(10),char(32)) END + 
		CASE WHEN C.CURRENTOFFICIALNO is not null THEN ' No: ' + C.CURRENTOFFICIALNO END + 
		CASE WHEN C.TITLE is not null THEN ' ' + replace(replace(C.TITLE,char(13)+char(10),char(32)),char(10),char(32)) END +
		CASE WHEN ER.COMMENTS is not null THEN ' Reminder Comments: ' + replace(replace(ER.COMMENTS, char(13)+char(10),char(32)),char(10),char(32)) END +
		CASE WHEN CE.EVENTTEXT is not null THEN ' Comments: ' + replace(replace(CE.EVENTTEXT,char(13)+char(10),char(32)),char(10),char(32)) END 
		as 'Comments',
		convert(bit, 
		CASE WHEN ISNULL(ISNULL(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL), A.IMPORTANCELEVEL)>=SC.COLINTEGER 
		     THEN 1 
		     ELSE 0 
		END)			as 'IsHighPriority',
		ER.EMPLOYEENO		as 'StaffKey',
		ER.MESSAGESEQ		as 'DateCreated'		
		from EMPLOYEEREMINDER ER		
		left join CASES C		on (C.CASEID = ER.CASEID)
		left join COUNTRY CO		on (C.COUNTRYCODE = CO.COUNTRYCODE)
		left join PROPERTYTYPE PT	on (C.PROPERTYTYPE = PT.PROPERTYTYPE)
		left join SITECONTROL SC	on (SC.CONTROLID = 'CRITICAL LEVEL')
		left join CASEEVENT CE		on (CE.CASEID = ER.CASEID
						and CE.EVENTNO = ER.EVENTNO
						and CE.CYCLE = ER.CYCLENO)
 		left join EVENTCONTROL EC	on (EC.EVENTNO = CE.EVENTNO
	 					and EC.CRITERIANO = CE.CREATEDBYCRITERIA)
		left join EVENTS E		on (E.EVENTNO = ER.EVENTNO)
		left join ALERT A		on (A.EMPLOYEENO = ER.ALERTNAMENO
						and A.SEQUENCENO = ER.SEQUENCENO
						and ER.EVENTNO IS NULL)		
	where ER.EMPLOYEENO = @pnStaffKey
	and   ER.MESSAGESEQ = @pdtDateCreated
	-- Check that the user has elected to display their reminders in Outlook:
	and exists (Select 1 
		    from SETTINGVALUES SVIRA	
		    join USERIDENTITY UI on (UI.IDENTITYID = SVIRA.IDENTITYID)	
		    -- Check that the staf has permission for the exchange integration task:
		    join dbo.fn_PermissionsGrantedName(@pnStaffKey, 'TASK', 51, null, @dtToday) PG
					 on (PG.CanExecute = 1)
		    where UI.NAMENO = ER.EMPLOYEENO
		    and SVIRA.SETTINGID = 4)"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnStaffKey			int,
					  @pdtDateCreated		datetime,
					  @dtToday			datetime',
					  @pnStaffKey			= @pnStaffKey,
					  @pdtDateCreated		= @pdtDateCreated,
					  @dtToday			= @dtToday

	-- User Info result set
	If @nErrorCode = 0
	Begin	
		Set @sSQLString = "
		Select 	UI.IDENTITYID			as 'UserIdentityId',
			SVIC.COLCHARACTER		as 'Culture',
			isnull(SVIN.COLBOOLEAN,0) 	as 'IsUserInitialised',
			SVIM.COLCHARACTER		as 'Mailbox',
			isnull(SVIA.COLBOOLEAN,0)	as 'IsAlertRequired',
			convert(datetime, '1899-01-01 ' + cast(cast(ROUND((COALESCE(SVIT.COLDECIMAL, SVDT.COLDECIMAL, 9.00))*60,0) as int)/60 as varchar(10)) + ':' + cast(cast(ROUND((COALESCE(SVIT.COLDECIMAL, SVDT.COLDECIMAL, 9.00))*60,0) as int)%60 as varchar(10)), 120)
							as 'AlertTime'
			from USERIDENTITY UI
			-- Check that the user has elected to display their reminders in Outlook:
			join SETTINGVALUES SVIRA	on (SVIRA.IDENTITYID = UI.IDENTITYID
							and SVIRA.SETTINGID = 4)				
			 -- Check that the staff has permission for the exchange integration task:
		    	join dbo.fn_PermissionsGrantedName(@pnStaffKey, 'TASK', 51, null, @dtToday) PG
					 		on (PG.IdentityKey = UI.IDENTITYID
							and PG.CanExecute = 1)
			-- Preferred Culture
			left join SETTINGVALUES SVIC	on (SVIC.SETTINGID = 6
							and SVIC.IDENTITYID = UI.IDENTITYID)
			-- IsUserInitialised setting
			left join SETTINGVALUES SVIN	on (SVIN.SETTINGID = 1
							and SVIN.IDENTITYID = UI.IDENTITYID)
			-- Mailbox setting
			left join SETTINGVALUES SVIM	on (SVIM.SETTINGID = 3
							and SVIM.IDENTITYID = UI.IDENTITYID)
			-- IsAlertRequired
			left join SETTINGVALUES SVIA	on (SVIA.SETTINGID = 2
							and SVIA.IDENTITYID = UI.IDENTITYID)
			-- Extract the AlertTime default settings for the firm as a whole   
			-- if there is not a specific value for the @pnUserIdentityId:
			left join SETTINGVALUES SVIT	on (SVIT.SETTINGID = 5
							and SVIT.IDENTITYID = UI.IDENTITYID)
			left join SETTINGVALUES SVDT	on (SVDT.SETTINGID = 5
							and SVDT.IDENTITYID is null)			
		where UI.NAMENO = @pnStaffKey"
	
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnStaffKey			int,
						  @dtToday			datetime',
						  @pnStaffKey			= @pnStaffKey,
						  @dtToday			= @dtToday
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ig_ListExchangeReminder to public
GO
