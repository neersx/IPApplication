-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ValidatePostDates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_ValidatePostDates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_ValidatePostDates.'
	Drop procedure [dbo].[wp_ValidatePostDates]
End
Print '**** Creating Stored Procedure dbo.wp_ValidatePostDates...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.wp_ValidatePostDates
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pdtPostDate		datetime	= null,
	@psXmlCriteria		ntext		= null
)
as
-- PROCEDURE:	wp_ValidatePostDates
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Validates the dates against selected Timesheet entries before posting

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 Oct 2014	LP	R26713	1	Procedure created
-- 03 Nov 2014	LP	R41122	2	Strip time before comparing PostDate with Period dates
-- 24 Oct 2017	AK	R72645	3	Make compatible with case sensitive server with case insensitive database.
-- 03 Nov 2014	LP	R41122	4	Strip time before comparing PostDate with Period dates
-- 16 Jan 2018  AK  R63269  5   added additional logic to to check wip creation in future date
-- 14 Nov 2018  AV  75198/DR-45358	6   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @sWhereClause	nvarchar(max)
declare @dtDate		datetime
declare @sAlertXML	nvarchar(2000)
declare @bIsFuture	bit
declare	@nPostPeriod	int
declare @pnModule	int
declare @dtWipEndDate datetime

-- Initialise variables
Set @nErrorCode = 0
Set @pnModule = 2
Set @dtDate = @pdtPostDate

If @nErrorCode = 0
and DATALENGTH(@psXMLCriteria) > 0
and @dtDate is null
Begin
	Exec @nErrorCode=ts_FilterDiary
		@psReturnClause			= @sWhereClause output, 
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbIsExternalUser		= 0,
		@ptXMLFilterCriteria		= @psXmlCriteria,
		@pbCalledFromCentura		= @pbCalledFromCentura
		
	If @nErrorCode = 0
	Begin
		Set @sSQLString="
		select @dtDate=max(STARTTIME)
		from DIARY D"
		Set @sSQLString = @sSQLString
		+char(10)+"where exists(Select 1"
		+char(10)+@sWhereClause
		+char(10)+"and XD.EMPLOYEENO = D.EMPLOYEENO"
		+char(10)+"and XD.ENTRYNO = D.ENTRYNO)"

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@dtDate	datetime	OUTPUT',
				  @dtDate	= @dtDate	OUTPUT
	End
End

If @dtDate is not null
Begin
	Set @dtDate = dbo.fn_DateOnly(@dtDate)
	
	If (@nErrorCode = 0)
	Begin
		-- Set the period to the currently open period
		Select @nPostPeriod = OP.PERIODID
		From (Select TOP 1 PERIODID, ENDDATE, CLOSEDFOR
			From PERIOD 
			Where @dtDate > POSTINGCOMMENCED -- Currently open period
			and POSTINGCOMMENCED IS NOT NULL
			Order by POSTINGCOMMENCED DESC) AS OP
		WHERE @dtDate <= OP.ENDDATE -- item date is within the period
		and (OP.CLOSEDFOR & @pnModule != @pnModule OR OP.CLOSEDFOR is null) -- and the period is not closed for Time/Billing"
	End

	If (@nErrorCode = 0 and @nPostPeriod is null)
	Begin
		-- if the current period could not be used, use the transaction period instead.
		Select @nPostPeriod = PERIODID
		FROM PERIOD
		WHERE @dtDate between STARTDATE AND ENDDATE
		and (CLOSEDFOR & @pnModule != @pnModule or CLOSEDFOR is null) -- Not closed for the period"
	End

	If (@nErrorCode = 0 and @nPostPeriod is null)
	Begin
		-- if the period of the transaction could not be used, use the next open period.
		Select @nPostPeriod = PERIODID
		FROM (SELECT MIN(P.PERIODID) AS PERIODID
			FROM (SELECT PERIODID FROM PERIOD
				WHERE @dtDate between STARTDATE AND ENDDATE) AS TRANSPERIOD
			JOIN PERIOD P ON (P.PERIODID > TRANSPERIOD.PERIODID)
			WHERE (P.CLOSEDFOR & @pnModule != @pnModule or P.CLOSEDFOR is null)
			) AS MINPERIOD
	End


	If (@nErrorCode=0)
	Begin
		If (@nPostPeriod is null)
		Begin
			-- Could not determine the post period
			Set @sAlertXML = dbo.fn_GetAlertXML('AC126', 'An accounting period could not be determined for the given date. Please check the period definitions and try again.',
												null, null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @nErrorCode = @@ERROR
		End
		Else Begin
			If exists(SELECT TOP 1 ENDDATE
									FROM PERIOD WHERE POSTINGCOMMENCED IS NOT NULL
									ORDER BY POSTINGCOMMENCED DESC)
			Begin
				set @sSQLString = "SELECT TOP 1 @dtWipEndDate = ENDDATE
									FROM PERIOD WHERE POSTINGCOMMENCED IS NOT NULL
									ORDER BY POSTINGCOMMENCED DESC"

				Exec @nErrorCode=sp_executesql @sSQLString, 
						N'@dtWipEndDate		datetime	OUTPUT',
						  @dtWipEndDate		= @dtWipEndDate	OUTPUT
					  			
				If @nErrorCode = 0			
				and @pdtPostDate > getdate()			
				and @pdtPostDate > @dtWipEndDate 			
				Begin
					Set @sAlertXML = dbo.fn_GetAlertXML('AC208', 'The item date cannot be in the future. It must be within the current accounting period or up to and including the current date.',
									convert(nvarchar, @pdtPostDate, 112), null, null, null, null)
					RAISERROR(@sAlertXML, 14, 1)
					Set @nErrorCode = @@ERROR
				End	
			End
			Else
			Begin
				If not exists(Select 1 from PERIOD where PERIODID = @nPostPeriod and @dtDate between STARTDATE and ENDDATE)
				Begin
					Select 'AC124' as WarningCode, 'The item date is not within the period it will be posted to.  Please check that the transaction is dated correctly.' as WarningMessage
				End
			End
		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.wp_ValidatePostDates to public
GO
