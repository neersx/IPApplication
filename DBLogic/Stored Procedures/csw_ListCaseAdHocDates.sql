-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseAdHocDates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseAdHocDates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseAdHocDates.'
	Drop procedure [dbo].[csw_ListCaseAdHocDates]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseAdHocDates...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseAdHocDates
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pnCaseKey				int,			-- Mandatory
	@pbCalledFromCentura	bit = 0
)
as
-- PROCEDURE:	csw_ListCaseAdHocDates
-- VERSION:	10
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 JAN 2010	SF		RFC4996	1	Procedure created
-- 08 JAN 2010	SF		RFC4996	2	Continuation
-- 24 JUN 2010	AS		RFC8878	3	Added ImportanceLevel, StopDate, DeleteDate and ResolvedReason columns in select command.
-- 02 Aug 2010  PA		R100317 4	Return ALERT.EMPLOYEENO in RecipientNameKey column instead of ALERT.NAMENO.
-- 24 JAN 2011	MF		R10184 	5	Only show Ad Hocs that meet the user's minimum importance level
--						or the Ad Hoc belongs to the user.
-- 02 May 2012	vql		R100635 6	Name Presentation not always used when displaying a name.
-- 15 Jun 2011	LP			7	Return checksum as part of the RowKey.
-- 08 Jan 2013	MS		R13100  8	Return A.EMPLOYEENO in RecipientNameKey column instead of A.NAMENO
-- 11 Apr 2013	DV		R13270	9	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql		R53910		Adjust formatted names logic (DR-15543).
-- 07 Sep 2018	AV	74738	10	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare	@nErrorCode	int
declare @nImportanceLevel	int
declare @sAdHocChecksumColumns	nvarchar(max)
declare @sSQLString nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0
---------------------------
-- Get the Importance Level
-- of interest to the user.
---------------------------
If @nErrorCode=0
Begin	
	Select @nImportanceLevel=dbo.fn_GetEventImportanceLevel(@pnUserIdentityId,DEFAULT)
End

If  @nErrorCode = 0
Begin
	exec dbo.ip_GetComparableColumns
	@psColumns 	= @sAdHocChecksumColumns output, 
	@psTableName 	= 'ALERT',
	@psAlias 	= 'A'	
	Set @nErrorCode = @@Error
End

If  @nErrorCode = 0
Begin
	If @nImportanceLevel is null
	Begin
		Set @sSQLString = "
	Select	'A^'
			+cast(ALERT.EMPLOYEENO as nvarchar(11)) + '^' +
			+convert(nvarchar(25),ALERT.ALERTSEQ, 126) + '^' 
			+CONVERT(nvarchar(20),CHECKSUM("+@sAdHocChecksumColumns+")) as RowKey,
			CASEID				as CaseKey,
			ALERT.EMPLOYEENO	as RecipientNameKey,
			N.NAMECODE			as RecipientNameCode,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO,COALESCE(N.NAMESTYLE, CN.NAMESTYLE, 7101)) as RecipientDisplayName,
			ALERTMESSAGE		as Message, 
			DUEDATE				as DueDate,  
			ALERTDATE			as NextReminderDate, 
			DATEOCCURRED  	    as DateOccurred,
			STOPREMINDERSDATE   as StopDate,
			I.IMPORTANCEDESC			as ImportanceLevel,
			DELETEDATE					as DeleteDate,
			CASE 	WHEN OCCURREDFLAG = 0 
				THEN NULL
			 ELSE TC.DESCRIPTION 
			 END	as ResolvedReason                                                                                                        	 
	from	ALERT 	
	left join IMPORTANCE I	on (I.IMPORTANCELEVEL = ALERT.IMPORTANCELEVEL)
	left join TABLECODES TC		on (TC.USERCODE = ISNULL(ALERT.OCCURREDFLAG,0) AND TC.TABLETYPE = 131)
	join	NAME N on (ALERT.EMPLOYEENO = N.NAMENO)
	left join COUNTRY CN on (CN.COUNTRY=N.NATIONALITY)
	where	ALERT.CASEID = @pnCaseKey  	 
	order by  DUEDATE"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int',
					  @pnCaseKey		= @pnCaseKey
	
	End
	Else Begin
		----------------------------------
		-- RFC10184
		-- Return only Ad Hoc Alerts that
		-- meet the users Importance Level
		-- or belong to the user.
		----------------------------------
		Set @sSQLString = "
		Select	'A^'
				+cast(A.EMPLOYEENO as nvarchar(11)) + '^' +
				+convert(nvarchar(25),A.ALERTSEQ, 126) + '^' 
				+CONVERT(nvarchar(20),CHECKSUM("+@sAdHocChecksumColumns+"))  as RowKey,
				A.CASEID		as CaseKey,
				A.EMPLOYEENO		as RecipientNameKey,
				N.NAMECODE		as RecipientNameCode,
				dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL) as RecipientDisplayName,
				A.ALERTMESSAGE		as Message, 
				A.DUEDATE		as DueDate,  
				A.ALERTDATE		as NextReminderDate, 
				A.DATEOCCURRED  	as DateOccurred                                                                                                   	 
		from	ALERT A
		join	NAME N on (A.EMPLOYEENO = N.NAMENO)
		left join USERIDENTITY UI on (UI.IDENTITYID=@pnUserIdentityId)
		where	A.CASEID = @pnCaseKey
		and (   A.IMPORTANCELEVEL>=@nImportanceLevel
		 or	A.IMPORTANCELEVEL is null
		 or     A.EMPLOYEENO = UI.NAMENO)
		order by  DUEDATE" 

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @pnCaseKey		int,
					  @nImportanceLevel	int',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pnCaseKey		= @pnCaseKey,
					  @nImportanceLevel	= @nImportanceLevel
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseAdHocDates to public
GO
