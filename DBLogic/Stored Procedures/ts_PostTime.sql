-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_PostTime
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_PostTime]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_PostTime.'
	Drop procedure [dbo].[ts_PostTime]
End
Print '**** Creating Stored Procedure dbo.ts_PostTime...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ts_PostTime
(
	@pnRowsPosted		int		= null output,
	@pnIncompleteRows	int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@ptXMLCriteria		ntext,		-- Mandatory
	@pnDebugFlag		tinyint	        = 0, --0=off,1=trace execution,2=dump data
        @pbHasOfficeEntityError bit             = 0 output

)
as
-- PROCEDURE:	ts_PostTime
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Create and post a batch of time entries.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Jun 2005	JEK	R2556	1	Procedure created
-- 18 Nov 2008	MF	S17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 27 Apr 2012	KR	R11414	3	Modified the IsComplete Logic
-- 14 Dec 2012  MS      R12778  4       Modified InComplete logic to display the count of incomplete entries based on the filter criteria
-- 08 Oct 2018  MS      DR40951 5       Do not show Entity mandatory error when Entity Defaults from Case Office site control is false 
-- 14 Nov 2018  AV  75198/DR-45358	6   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare	@nBatchSize		int
declare @sBatchSize		nvarchar(10)
declare	@nBatchRows		int
declare @sSQLString		nvarchar(4000)
declare	@sTimeStamp		nvarchar(24)
declare @sAlertXML		nvarchar(400)

declare @idoc 			int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.

declare @nEntityKey		int
declare @sWhereClause		nvarchar(4000)
declare @nCurrentPeriodID	int
declare @dtDate			datetime
declare @bIsFuture		bit

-- Initialise variables
Set @nErrorCode = 0
Set @pnRowsPosted = 0
Set @pnIncompleteRows = 0
Set @nBatchRows = -1

If  @pnDebugFlag>0
Begin
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ts_PostTime-Commence Processing',0,1,@sTimeStamp ) with NOWAIT
End

If (datalength(@ptXMLCriteria) > 0)
and @nErrorCode = 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s ts_PostTime-Process XML Criteria',0,1,@sTimeStamp ) with NOWAIT
	End
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLCriteria

	-- 1) Retrieve the AnySearch element using element-centric mapping (implement 
	--    Case Insensitive searching)   
	Set @sSQLString = 	
	"Select @nEntityKey			= WipEntityKey"+CHAR(10)+
	"from	OPENXML (@idoc, '/ts_PostTime',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      WipEntityKey		int		'WipEntityKey/text()'"+CHAR(10)+
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nEntityKey 			int			output',
				  @idoc				= @idoc,
				  @nEntityKey 			= @nEntityKey		output			
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s ts_PostTime-EntityKey=%d',0,1,@sTimeStamp,  @nEntityKey) with NOWAIT
	End
End

If @nErrorCode = 0
Begin

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s ts_PostTime-Get Filter Criteria',0,1,@sTimeStamp ) with NOWAIT
	End

	Exec @nErrorCode=ts_FilterDiary
		@psReturnClause			= @sWhereClause output, 
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pbIsExternalUser		= 0,
		@ptXMLFilterCriteria		= @ptXMLCriteria,
		@pbCalledFromCentura		= @pbCalledFromCentura

End

If @nErrorCode = 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s ts_PostTime-Begin Validation',0,1,@sTimeStamp ) with NOWAIT
	End

	If @nEntityKey is null and (Select COLBOOLEAN FROM SITECONTROL WHERE CONTROLID = N'Entity Defaults from Case Office') = 0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('AC14', 'Entity is mandatory but has not been supplied.',
						null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		-- Note: dbo.fn_GetPostPeriod has not been used as it around 100 times slower
		Set @sSQLString="
		select @dtDate=max(STARTTIME)
		from DIARY D
		where not exists
			(select 1
			from PERIOD P
			where 	isnull(P.CLOSEDFOR,0)&2 = 0	-- 2 = Time and Billing subsystem
			-- ignore any time component by checking for > next day
			and	dateadd(d,1,P.ENDDATE) > D.STARTTIME)"

		Set @sSQLString = @sSQLString
		+char(10)+"and exists(Select 1"
		+char(10)+@sWhereClause
		+char(10)+"and XD.EMPLOYEENO = D.EMPLOYEENO"
		+char(10)+"and XD.ENTRYNO = D.ENTRYNO)"

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@dtDate	datetime	OUTPUT',
				  @dtDate	= @dtDate	OUTPUT

		If @nErrorCode = 0
		and @dtDate is not null
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('AC12', 'Unable to locate accounting period for {0:d}.  Either the date is incorrect, or the period has not been defined.',
							convert(nvarchar, @dtDate, 112), null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @nErrorCode = @@ERROR
		End
	End

	If @nErrorCode = 0
	Begin
		-- Get the maximum permissable transaction date
		Set @sSQLString="
		select @dtDate = cast(convert(nvarchar,
						case when P.ENDDATE > getdate() 
						     then P.ENDDATE 
						     else getdate() 
						end, 112)
					as datetime)
		FROM PERIOD P
		WHERE P.PERIODID =
			-- Current accounting period for the subsystem
			(SELECT MIN(P1.PERIODID)
			FROM PERIOD P1
			WHERE isnull(CLOSEDFOR,0)&2=0)"	-- 2 = Time and Billing subsystem

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@dtDate	datetime	OUTPUT',
				  @dtDate	= @dtDate	OUTPUT

		If @nErrorCode = 0
		Begin
			Set @sSQLString="
			select @bIsFuture = 1
			from DIARY D
			-- Add 1 to date to allow for time component
			WHERE D.STARTTIME >= dateadd(d,1,@dtDate)"
	
			Set @sSQLString = @sSQLString
			+char(10)+"and exists(Select 1"
			+char(10)+@sWhereClause
			+char(10)+"and XD.EMPLOYEENO = D.EMPLOYEENO"
			+char(10)+"and XD.ENTRYNO = D.ENTRYNO)"
	
			Exec @nErrorCode=sp_executesql @sSQLString, 
					N'@dtDate	datetime,
					  @bIsFuture	bit		OUTPUT',
					  @dtDate	= @dtDate,
					  @bIsFuture	= @bIsFuture	OUTPUT
		End

		If @nErrorCode = 0
		and @bIsFuture = 1
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('AC13', 'Unable to post future transaction dates.  Dates up to {0:d} may be processed.',
							convert(nvarchar, @dtDate, 112), null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @nErrorCode = @@ERROR
		End
	End
End

If @nErrorCode = 0
Begin
		Set @sSQLString="
		select 	@nBatchSize = S.COLINTEGER
		from SITECONTROL S
		where S.CONTROLID = 'Time Post Batch Size'"

		Exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nBatchSize	int		OUTPUT',
				  @nBatchSize	= @nBatchSize	OUTPUT

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			Set	@sBatchSize = cast(@nBatchSize as nvarchar)
			RAISERROR ('%s ts_PostTime-Time Post Batch Size=%s',0,1,@sTimeStamp,  @sBatchSize) with NOWAIT
		End
End

While @nErrorCode = 0
and @nBatchRows <> 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s ts_PostTime-Start a batch',0,1,@sTimeStamp ) with NOWAIT
	End

	Exec @nErrorCode=ts_PostTimeBatch
		@pnRowsPosted		= @nBatchRows	OUTPUT,
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnEntityKey		= @nEntityKey,
		@psWhereClause		= @sWhereClause,
		@pnBatchSize		= @nBatchSize,
		@pnDebugFlag		= @pnDebugFlag,
                @pbHasOfficeEntityError = @pbHasOfficeEntityError OUTPUT

	If @nErrorCode = 0
	Begin
		Set @pnRowsPosted = @pnRowsPosted+@nBatchRows
	End
End

If @nErrorCode = 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s ts_PostTime-Count incomplete entries',0,1,@sTimeStamp ) with NOWAIT
	End

	Set @sSQLString = "
	select @pnIncompleteRows = count(*)
	from DIARY D
	left join DIARY D1 on (D1.PARENTENTRYNO = D.ENTRYNO and D1.EMPLOYEENO = D.EMPLOYEENO)
	left join SITECONTROL S	on (S.CONTROLID = 'CASEONLY_TIME')
	left join SITECONTROL SR on (SR.CONTROLID = 'Rate mandatory on time items')
		-- Not a timer
	where 	D.ISTIMER=0
		-- incomplete
	and	(((isnull(S.COLBOOLEAN, 0) = 1 OR D.NAMENO is null) and D.CASEID is null) 
		OR D.ACTIVITY is null 
		OR (( D.TOTALTIME is null or D.TOTALUNITS is null or D.TIMEVALUE is null) AND (D1.PARENTENTRYNO is null or D.ENTRYNO != D1.PARENTENTRYNO))
		OR (D.CHARGEOUTRATE is null and isnull(SR.COLBOOLEAN,0) = 1))"

	Set @sSQLString = @sSQLString+
		     +char(10)+"and exists(Select 1"
		     +char(10)+@sWhereClause
		     +char(10)+"and XD.EMPLOYEENO = D.EMPLOYEENO"
		     +char(10)+"and XD.ENTRYNO = D.ENTRYNO)"

	Exec @nErrorCode=sp_executesql @sSQLString, 
			N'@pnIncompleteRows	int			OUTPUT',
			  @pnIncompleteRows	= @pnIncompleteRows	OUTPUT
End

Return @nErrorCode
GO

Grant execute on dbo.ts_PostTime to public
GO
