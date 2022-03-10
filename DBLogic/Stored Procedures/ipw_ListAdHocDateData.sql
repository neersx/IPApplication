-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListAdHocDateData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListAdHocDateData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListAdHocDateData.'
	Drop procedure [dbo].[ipw_ListAdHocDateData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListAdHocDateData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListAdHocDateData
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int		= null,		
	@pdtDateCreated		datetime	= null,
	@psAdHocTemplateCode	nvarchar(10)	= null,
	@pdtDueDate		datetime	= null	
)
as
-- PROCEDURE:	ipw_ListAdHocDateData
-- VERSION:	13
-- DESCRIPTION:	Populates the AdHocDateData dataset 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Oct 2004	TM	RFC1327	1	Procedure created.
-- 14 Oct 2004  TM	RFC1327	2	Correct the AddHocMessage column name to be AdHocMessage.
-- 14 Jul 2005	TM	RFC2743	3	If OccuredFlag is 0 (false) then return Null.
-- 17 Aug 2005	TM	RFC2938	4	Add new importance level column.
-- 30 Nov 2005	TM	RFC2939	5	Default some columns from template.
-- 01 Sep 2006	LP	RFC4328	6	Add RowKey column to result set.
-- 02 Feb 2007	LP	RFC5076	7	Add OccurredReasonDescription column to result set.
-- 12 Feb 2009  LP	RFC6047 8	Add NameReferenceKey,NameReference and NameReferenceCode columns.
-- 27 May 2011	LP	R10718	9	Add Checksum to the RowKey
-- 02 Dec 2011	DV	RFC9946	10	Add logic to return additional fields from ALERT table.
-- 31 Jan 2011  DV	R11857  11	Return Event Description along with Due Event
-- 11 Apr 2013	DV	R13270	12	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	13	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(max)
declare @sLookupCulture	nvarchar(10)
declare @sAdHocChecksumColumns	nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If  @nErrorCode = 0
Begin
	exec dbo.ip_GetComparableColumns
	@psColumns 	= @sAdHocChecksumColumns output, 
	@psTableName 	= 'ALERT',
	@psAlias 	= 'A'
	
	Set @nErrorCode = @@Error
End

-- Populating AdHocDate result set
If  @nErrorCode = 0
and @pnNameKey is not null
and @pdtDateCreated is not null
Begin
	Set @sSQLString = " 
	Select  @pnNameKey 		as NameKey,
		A.ALERTSEQ		as DateCreated,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL) 
					as Name,
		N.NAMECODE		as NameCode,
		A.CASEID 		as CaseKey,
		C.IRN			as CaseReference,
		A.NAMENO                as NameReferenceKey,
		dbo.fn_FormatNameUsingNameNo(NR.NAMENO, NULL) 
					as NameReference,
		NR.NAMECODE		as NameReferenceCode,
		A.ALERTMESSAGE		as AdHocMessage,
		A.REFERENCE		as AdHocReference,
		A.DUEDATE		as DueDate,
		A.TRIGGEREVENTNO	as EventDue,
		"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)
				+ " as EventDescription,                      
		A.DATEOCCURRED		as DateOccurred,
		CASE 	WHEN A.OCCURREDFLAG = 0 
			THEN NULL
			ELSE A.OCCURREDFLAG 
			END	as OccurredReasonKey,
		CASE 	WHEN A.OCCURREDFLAG = 0 
			THEN NULL
			ELSE TC.DESCRIPTION 
			END	as OccurredReasonDescription,
		A.DELETEDATE		as DeleteDate,
		A.STOPREMINDERSDATE 	as StopRemindersDate,
		A.DAYSLEAD		as DaysLead,
		A.DAILYFREQUENCY 	as RepeatIntervalDays,
		A.MONTHSLEAD		as MonthsLead,
		A.MONTHLYFREQUENCY	as RepeatIntervalMonths,
		A.SEQUENCENO		as SequenceNo,
		CAST(A.SENDELECTRONICALLY as bit)
					as IsElectronicReminder,
		A.EMAILSUBJECT		as EmailSubject,
		A.IMPORTANCELEVEL	as ImportanceLevelKey, 
		"+dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)
				+ " 			as ImportanceLevelDescription,
		A.EMPLOYEEFLAG		as IsStaff,
		A.CRITICALFLAG		as IsCriticalList,
		A.SIGNATORYFLAG		as IsSignatory,
		A.NAMETYPE			as NameTypeKey,
		"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
				+ " as NameType,
		A.RELATIONSHIP		as RelationshipKey, 
		'A^' + cast(@pnNameKey as nvarchar(11)) + '^'
		+ CONVERT(nvarchar(25),@pdtDateCreated,126) + '^' 
		+ CONVERT(nvarchar(20),CHECKSUM("+@sAdHocChecksumColumns+"))	 as RowKey
	from ALERT A
	join NAME N			on (N.NAMENO = @pnNameKey)	
	left join NAME NR		on (NR.NAMENO = A.NAMENO)	
	left join CASES C		on (C.CASEID = A.CASEID)	
	left join IMPORTANCE I		on (I.IMPORTANCELEVEL = A.IMPORTANCELEVEL)
	left join TABLECODES TC		on (TC.USERCODE = ISNULL(A.OCCURREDFLAG,0) AND TC.TABLETYPE = 131)
	left join NAMETYPE NT	on (NT.NAMETYPE = A.NAMETYPE)
	left join EVENTS E on (E.EVENTNO = A.TRIGGEREVENTNO)
	where A.EMPLOYEENO = @pnNameKey
	and   A.ALERTSEQ = @pdtDateCreated"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pdtDateCreated	datetime',
					  @pnNameKey		= @pnNameKey,
					  @pdtDateCreated	= @pdtDateCreated

	Set @pnRowCount = @@RowCount
End
-- Populate the dataset with the default values from the identified template.  
Else If @nErrorCode = 0
and  @psAdHocTemplateCode is not null
Begin
	Set @sSQLString = " 
	Select  A.EMPLOYEENO		as NameKey,
		null			as DateCreated,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL) 
					as Name,
		null			as NameCode,
		null			as CaseKey,
		null			as CaseReference,
		null			as NameReferenceKey,
		null			as NameReference,
		A.ALERTMESSAGE		as AdHocMessage,
		null			as AdHocReference,
		@pdtDueDate		as DueDate,
		null			as EventDue,
		null			as EventDescription,
		null			as DateOccurred,
		null			as OccurredReasonKey,
		null			as OccurredReasonDescription,
		CASE 	WHEN @pdtDueDate is not null and A.DELETEALERT is not null
			THEN DATEADD(dd,A.DELETEALERT,@pdtDueDate) 
		END			as DeleteDate,
		CASE	WHEN @pdtDueDate is not null and A.STOPALERT is not null
			THEN DATEADD(dd,A.STOPALERT,@pdtDueDate)
		END			as StopRemindersDate,
		A.DAYSLEAD		as DaysLead,
		A.DAILYFREQUENCY 	as RepeatIntervalDays,
		A.MONTHSLEAD		as MonthsLead,
		A.MONTHLYFREQUENCY	as RepeatIntervalMonths,
		null			as SequenceNo,
		A.SENDELECTRONICALLY 	as IsElectronicReminder,
		A.EMAILSUBJECT		as EmailSubject,
		A.IMPORTANCELEVEL	as ImportanceLevelKey, 
		A.EMPLOYEEFLAG		as IsStaff,
		A.CRITICALFLAG		as IsCriticalList,
		A.SIGNATORYFLAG		as IsSignatory,
		A.NAMETYPE			as NameTypeKey,
		"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
				+ " as NameType,
		A.RELATIONSHIP		as RelationshipKey, 
		"+dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)
				    + " as ImportanceLevelDescription
	from ALERTTEMPLATE A
	left join IMPORTANCE I		on (I.IMPORTANCELEVEL = A.IMPORTANCELEVEL)
	left join NAME	N			on (N.NAMENO = A.EMPLOYEENO)
	left join NAMETYPE NT	on (NT.NAMETYPE = A.NAMETYPE)
	where A.ALERTTEMPLATECODE = @psAdHocTemplateCode"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psAdHocTemplateCode	nvarchar(10),
					  @pdtDueDate		datetime',
					  @psAdHocTemplateCode	= @psAdHocTemplateCode,
					  @pdtDueDate		= @pdtDueDate

	Set @pnRowCount = @@RowCount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListAdHocDateData to public
GO
