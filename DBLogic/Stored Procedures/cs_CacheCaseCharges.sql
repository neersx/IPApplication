-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_CacheCaseCharges
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_CacheCaseCharges]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_CacheCaseCharges.'
	drop procedure dbo.cs_CacheCaseCharges
end
print '**** Creating Stored Procedure dbo.cs_CacheCaseCharges...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_CacheCaseCharges
	@pnBackgroundCount	int		= 0	output,	-- Case charge rows sent to background calculation
	@psEmailAddress		nvarchar(100)	= Null	output, -- Email address to be notified on completion of background fee calculation
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@psGlobalTempTable	nvarchar(60),		-- name of temporary table of CASEIDs to be reported on.
	@pdtFromDate		datetime	= null,	-- Starting date range to filter on
	@pdtUntilDate		datetime	= null, -- Ending date range to filter on
	@pbPrintSQL		bit		= 0,	-- When set to 1, the executed SQL statement is printed out.
	@ptXMLOutputRequests	nvarchar(max)	= null, -- The columns and sorting required in the result set. 
	@ptXMLFilterCriteria	nvarchar(max)	= null  -- Contains filtering to be applied to the selected columns

AS
-- PROCEDURE :	cs_CacheCaseCharges
-- VERSION :	10
-- DESCRIPTION:	Gets additional details for each Case being enquired/reported on.  This caters for column
--		requests that cannot easily be incorporated into a single SELECT statement.
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who	Number	Version	Change
-- ------------ --- ------	-------	------------------------------------------ 
-- 10 Oct 2009	MF  RFC8260	1	Procedure created
-- 21 Jan 2010	MF	RFC8830	2	When creating a row in QUERY table, include the current seconds
--								from the time to avoid
-- 08 Feb 2010	MF	RFC8883	3	Allow user control over the wording used on email generated to indicate that 
--								fee calculations are being done in background and change the format of the address
--								used in the name of the saved query.
-- 17 Mar 2010  LP	RFC8801 4	Use a variable for the return value of the OLE method call.
-- 24 Aug 2010	MF	RFC9676	5	Fees are being recalculated when date filter is for a future date range because the
--								fees previously calculated in background have a FROMDATE set to the date they were
--								calculated.  The date filter is really intended for determining which Cases are eligbible
--								to have their fees calculated.  Solution is to remove the filter by date against the
--								CASECHARGESCACHE table.
-- 28 May 2013	DL	10030	6	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 05 Jul 2013	vql	R13629	7	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Oct 2014	DL	R39102	8	Use service broker instead of OLE Automation to run the command asynchronoulsly
-- 15 Dec 2017	AK	R72645	9	Make compatible with case sensitive server with case insensitive database.
-- 07 Sep 2018	AV	74738	10	Set isolation level to read uncommited.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
--------------------------------------------
-- @tblOutputRequests table variable is used 
-- to load the presentation columns
--------------------------------------------
declare @tblOutputRequests table 
	 (	ROWNUMBER	int 		not null,
    		ID		nvarchar(100)	collate database_default not null,
    		SORTORDER	tinyint		null,
    		SORTDIRECTION	nvarchar(1)	collate database_default null,
		PUBLISHNAME	nvarchar(100)	collate database_default null,
		QUALIFIER	nvarchar(100)	collate database_default null
	  )

declare @ErrorCode		int
declare	@nRowCount		int
declare @nCaseThreshold		int
declare @nMaxRowNumber		int
declare @nStartRowNumber	int
declare @nSpid			int
declare	@nObject		int
declare	@nQueryContextKey	int
declare	@nQueryId		int
declare	@nPresentationId	int
declare @nGroupId		int
declare @idoc 			int 		-- Document handle of the XML document in memory that is created by sp_xml_preparedocument
declare	@nObjectExist		tinyint
declare	@sResultTable		nvarchar(60)
declare @sQueryName		nvarchar(50)
declare	@sCommand		nvarchar(max)
declare @sSQLString		nvarchar(max)
declare @sInsert		nvarchar(1000)
declare @sColumnList		nvarchar(1000)
declare @sSelectList		nvarchar(1000)
declare @sSelectList2		nvarchar(1000)
declare @sQuote			char(1)
declare	@sDoubleQuote		char(1)
declare @dtNow			datetime
Declare @nTempOAReturn          int             -- used as a variable to contain the returnValue of the OLE method

-----------------------
-- Initialise variables
-----------------------
Set @ErrorCode=0
set @sDoubleQuote='"'
set @sQuote      ="'"

--------------------------------------------
-- String together the column to be inserted
-- for the extended Case details
--------------------------------------------
If @ErrorCode=0
Begin
	select @sColumnList=ISNULL(NULLIF(@sColumnList + ',', ','),'') + COLUMN_NAME
	From tempdb.INFORMATION_SCHEMA.COLUMNS 
	Where TABLE_NAME = @psGlobalTempTable
	and COLUMN_NAME<>'ROWNUMBER'
	
	Set @ErrorCode=@@Error
End
--------------------------------
-- Save the highest ROWNUMBER in
-- the global temporary table
--------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @nMaxRowNumber=max(ROWNUMBER)
	from "+@psGlobalTempTable

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nMaxRowNumber	int	OUTPUT',
				  @nMaxRowNumber=@nMaxRowNumber	OUTPUT
End

--------------------------------------------
-- Remove any rows from the CASECHARGESCACHE
-- that were calculated over 24 hours ago.
--------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Delete CASECHARGESCACHE
	where datediff(hour,WHENCALCULATED,getdate())>=24"
	
	exec @ErrorCode=sp_executesql @sSQLString
End

------------------------------------------------
-- Get the Site Control that determines how many 
-- Cases requiring fees should trigger the fee
-- calculation to occur in background.
------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	select @nCaseThreshold=COLINTEGER
	from SITECONTROL
	where CONTROLID='Case Fees Calc Limit'"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCaseThreshold	int		output',
				  @nCaseThreshold=@nCaseThreshold	output
End

------------------------------------------------------
-- Copy rows into the global temporary table from 
-- CASECHARGESCACHE which holds the calculation.  There 
-- may be multiple rows for each CASEID and CHARGETYPE
-- if due date or year are to be returned.
------------------------------------------------------

If  @ErrorCode=0
Begin
	Set @sSelectList='T.'+replace(@sColumnList,',',',T.')
	Set @sSelectList=     replace(@sSelectList,'T.FeeYearNoAny', 'C.YEARNO')
	Set @sSelectList=     replace(@sSelectList,'T.FeeDueDateAny','C.FROMDATE')
	Set @sSelectList=     replace(@sSelectList,'T.FeeBillCurrencyAny','C.BILLCURRENCY')
	Set @sSelectList=     replace(@sSelectList,'T.InstructionBillCurrencyAny','C.BILLCURRENCY')
	Set @sSelectList=     replace(@sSelectList,'T.FeeBilledPerYearAny','C.TOTALYEARVALUE')
	Set @sSelectList=     replace(@sSelectList,'T.InstructionFeeBilledAny','C.TOTALYEARVALUE')
	Set @sSelectList=     replace(@sSelectList,'T.FeeBilledAmountAny','C.TOTALVALUE')
	Set @sSelectList2='C.'+replace(@sColumnList,',',',C.')

	Set @sSQLString="
	insert into "+@psGlobalTempTable+"("+@sColumnList+")
	select distinct "+@sSelectList+"
	from "+@psGlobalTempTable+" T
	join CASECHARGESCACHE C on (C.CASEID=T.CASEID
				and C.CHARGETYPENO=T.CHARGETYPENO"
				
-- RFC9676 Comment out this block of code
	--If  @pdtFromDate  is not null
	--and @pdtUntilDate is not null
	--	set @sSQLString=@sSQLString+"
	--			and C.FROMDATE between @pdtFromDate and @pdtUntilDate"
	--Else If @pdtFromDate is not null
	--	set @sSQLString=@sSQLString+"
	--			and C.FROMDATE >=@pdtFromDate"
	--Else If @pdtUntilDate is not null
	--	set @sSQLString=@sSQLString+"
	--			and C.FROMDATE <=@pdtUntilDate"
-- RFC9676 Comment out this block of code
				
	Set @sSQLString=@sSQLString+')
	where C.SPIDREQUEST is null'

	Exec @ErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@@Rowcount

	---------------------------------------
	-- If no previously saved fee values
	-- are available then use the current
	-- temporary table of Cases to get the
	-- fees.
	---------------------------------------
	If @ErrorCode=0
	and @nRowCount=0
	Begin
		Set @sResultTable=@psGlobalTempTable
		
		Set @sSQLString="
		select @nRowCount=count(1)
		from "+@psGlobalTempTable
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nRowCount	int	OUTPUT',
					  @nRowCount=@nRowCount	OUTPUT
	End
	---------------------------------------
	-- If previously saved fee values exist
	-- then we need to identify what Cases 
	-- still require a fee to be calculated
	---------------------------------------
	Else If  @ErrorCode=0
	     and @nRowCount>0
	Begin
		Set @nStartRowNumber=@nMaxRowNumber+@nRowCount+1
		------------------------------------
		-- Remove the pre-existing rows from 
		-- the global temporary table where
		-- a row with the fee values has
		-- been inserted.
		------------------------------------
		Set @sSQLString="
		Delete "+@psGlobalTempTable+"
		from "+@psGlobalTempTable+" T
		where T.ROWNUMBER<=@nMaxRowNumber
		and exists
		(select 1 from "+@psGlobalTempTable+" T1
		 where T1.ROWNUMBER>@nMaxRowNumber
		 and T1.CASEID=T.CASEID
		 and T1.CHARGETYPENO=T.CHARGETYPENO)"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nMaxRowNumber	int',
					  @nMaxRowNumber=@nMaxRowNumber

		--------------------------------------------
		-- Now generate a new global temporary table
		-- with the Case rows that still require a 
		-- fee to be calculated.
		--------------------------------------------
		Set @sResultTable=@psGlobalTempTable+'_FEES'
		
		If exists (SELECT 1 FROM tempdb.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @sResultTable)
		Begin
			Set @sSQLString="
			drop table "+@sResultTable
			
			exec @ErrorCode=sp_executesql @sSQLString
		End
		
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			select T.* into "+@sResultTable+"
			from "+@psGlobalTempTable+" T
			left join CASECHARGESCACHE C	on (C.CASEID=T.CASEID
							and C.CHARGETYPENO=T.CHARGETYPENO"

-- RFC9676 Comment out this block of code
			--If  @pdtFromDate  is not null
			--and @pdtUntilDate is not null
			--	set @sSQLString=@sSQLString+"
			--				and C.FROMDATE between @pdtFromDate and @pdtUntilDate"
			--Else If @pdtFromDate is not null
			--	set @sSQLString=@sSQLString+"
			--				and C.FROMDATE >=@pdtFromDate"
			--Else If @pdtUntilDate is not null
			--	set @sSQLString=@sSQLString+"
			--				and C.FROMDATE <=@pdtUntilDate"
-- RFC9676 Comment out this block of code
						
			Set @sSQLString=@sSQLString+")
			Where C.CASEID is null"

			Exec @ErrorCode=sp_executesql @sSQLString
			
			Set @nRowCount=@@Rowcount
		End
		
		-----------------------------------------
		-- If no rows have been loaded into 
		-- the new temporary table then there
		-- are no more fees that need calculating
		-----------------------------------------
		If  @nRowCount>0
		and @ErrorCode=0
		Begin
			-----------------------------------------------
			-- Need to change the ROWNUMBER column to be an
			-- identity column starting after the highest 
			-- RowNumber in @psGlobalTempTable
			-----------------------------------------------
			Set @sSQLString="
			Alter Table "+@sResultTable+" drop column ROWNUMBER
			Alter Table "+@sResultTable+" add ROWNUMBER int identity("+cast(@nStartRowNumber as varchar)+",1)"
		
			exec @ErrorCode=sp_executesql @sSQLString
		End
		Else If @ErrorCode=0
		Begin
			---------------------------------
			-- Cleanup global temporary table
			-- by dropping it from database.
			---------------------------------
			Set @sSQLString="drop table "+@sResultTable
			
			exec @ErrorCode=sp_executesql @sSQLString
			
			set @sResultTable=null
		End
	End
End
-----------------------------------------------
-- If rows exist in the temporary table whose
-- name is in @sResultTable then fees need to
-- be calculated.
-----------------------------------------------
If @sResultTable is not null
and @ErrorCode=0
Begin
	------------------------------------------
	-- If the number of Cases requiring fee
	-- calculations is less than the threshold
	-- that triggers a background calculation,
	-- then call the procedure immediately and
	-- wait for a result.
	-- A threshhold of zero will also cause 
	-- fees to calculate immediately.
	------------------------------------------
	If @nRowCount<@nCaseThreshold
	or @nCaseThreshold=0
	Begin
		Exec @ErrorCode=dbo.cs_ListCaseCharges
				@pnUserIdentityId	=@pnUserIdentityId,
				@psCulture		=@psCulture,
				@psGlobalTempTable	=@sResultTable,
				@pdtFromDate		=@pdtFromDate,
				@pdtUntilDate		=@pdtUntilDate,
				@pbCalledFromCentura	=0,		-- must be set to 0 even if this procedure was called from Centura
				@pbDyamicChargeType	=1,
				@pbPrintSQL		=@pbPrintSQL
			
		----------------------------------		
		-- if the name of the result table
		-- is different to original global
		-- temporary table then we need to
		-- merge the result in. 
		----------------------------------
		If @sResultTable<>@psGlobalTempTable
		and @ErrorCode=0
		Begin
			Set @sSQLString="
			insert into "+@psGlobalTempTable+"("+@sColumnList+")
			select distinct "+@sSelectList2+"
			from "+@psGlobalTempTable+" T
			join "+@sResultTable+" C	on (C.CASEID=T.CASEID
							and C.CHARGETYPENO=T.CHARGETYPENO)"

			Exec @ErrorCode=sp_executesql @sSQLString
			Set @nRowCount=@@Rowcount
			
			If @nRowCount>0
			and @ErrorCode=0
			Begin
				------------------------------------
				-- Remove the pre-existing rows from 
				-- the global temporary table where
				-- a row with the fee values has
				-- just been inserted.
				------------------------------------
				Set @sSQLString="
				Delete "+@psGlobalTempTable+"
				from "+@psGlobalTempTable+" T
				where T.ROWNUMBER<=@nMaxRowNumber
				and exists
				(select 1 from "+@psGlobalTempTable+" T1
				 where T1.ROWNUMBER>@nMaxRowNumber
				 and T1.CASEID=T.CASEID
				 and T1.CHARGETYPENO=T.CHARGETYPENO)"

				Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nMaxRowNumber	int',
							  @nMaxRowNumber=@nMaxRowNumber
			End
		End
	End
	
	------------------------------------------
	-- If the Cases requiring a fee calculation
	-- has exceeded the threshold set then the
	-- calculations will be performed as a 
	-- background process.  On completion the
	-- user will be informed by email.
	------------------------------------------
	Else Begin
		--------------------------------------
		-- A row will need to be inserted into
		-- the CASECHARGESCACHE table to tell
		-- the background process what Cases
		-- and charges are to be calculated. 
		--------------------------------------
		Set @dtNow=getdate()
		Set @nSpid=@@SPID
		
		Set @sInsert="
		insert into CASECHARGESCACHE(CASEID,CHARGETYPENO,WHENCALCULATED,SPIDREQUEST"
		
		Set @sSQLString="
		select distinct CASEID,CHARGETYPENO,@dtNow,@nSpid"
		
		If @sColumnList like '%DEFINITIONID%'
		Begin
			Set @sInsert  =@sInsert    +',DEFINITIONID'
			Set @sSQLString=@sSQLString+',DEFINITIONID'
		End
		
		If @sColumnList like '%InstructionCycleAny%'
		Begin
			Set @sInsert  =@sInsert    +',INSTRUCTIONCYCLEANY'
			Set @sSQLString=@sSQLString+',InstructionCycleAny'
		End
		
		If @sColumnList like '%FeeYearNoAny%'
		Begin
			Set @sInsert  =@sInsert    +',FEEYEARNOANY'
			Set @sSQLString=@sSQLString+',1'
		End
		
		If @sColumnList like '%FeeDueDateAny%'
		Begin
			Set @sInsert  =@sInsert    +',FEEDUEDATEANY'
			Set @sSQLString=@sSQLString+',1'
		End
		
		
		Set @sSQLString=@sInsert+')'+@sSQLString+"
		from  "+@sResultTable
		
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@dtNow	datetime,
						  @nSpid	int',
						  @dtNow=@dtNow,
						  @nSpid=@nSpid
		Set @pnBackgroundCount=@@Rowcount
		
		If @pnBackgroundCount>0
		and @ErrorCode=0
		Begin
			-------------------------------------
			-- Get the email address that will be
			-- used to inform the user when the
			-- background fee calculations are
			-- completed.
			-------------------------------------
			If @pnUserIdentityId is not null
			Begin
				Set @sSQLString="
				Select @psEmailAddress  =E.TELECOMNUMBER,
				       @nGroupId        =CASE WHEN(UID.ISEXTERNALUSER=1) THEN -331 ELSE -330 END,
				       @nQueryContextKey=CASE WHEN(UID.ISEXTERNALUSER=1) THEN  331 ELSE  330 END
				From USERIDENTITY UID
				join NAME N on N.NAMENO = UID.NAMENO 
				join TELECOMMUNICATION E on (E.TELECODE = N.MAINEMAIL) 
				WHERE UID.IDENTITYID=@pnUserIdentityId"
				
				exec @ErrorCode=sp_executesql @sSQLString,
							N'@psEmailAddress	nvarchar(100)	OUTPUT,
							  @nGroupId		int		OUTPUT,
							  @nQueryContextKey	int		OUTPUT,
							  @pnUserIdentityId	int',
							  @psEmailAddress  =@psEmailAddress	OUTPUT,
							  @nGroupId        =@nGroupId		OUTPUT,
							  @nQueryContextKey=@nQueryContextKey	OUTPUT,
							  @pnUserIdentityId=@pnUserIdentityId
			End
			
			-----------------------------------------------
			-- Save the Query so that when the background
			-- process completes the email can refer to 
			-- the saved query.
			-----------------------------------------------			
			If @ErrorCode=0
			Begin
				select @sQueryName = '** Calculation Running ** '
						+substring(convert(nvarchar,getdate(),106),8,4)+'-'
						+substring(convert(nvarchar,getdate(),106),4,3)+'-'
						+substring(convert(nvarchar,getdate(),106),1,2)+' ('
						+substring(convert(nvarchar,getdate(),114),1,8)+')'
				-------------------------------------------------
				-- Call procedure to load the QUERY, QUERYFILTER,
				-- and QUERYPRESENTATION tables
				-------------------------------------------------
				Exec @ErrorCode=dbo.qr_InsertQuery
							@pnQueryKey			= @nQueryId	output,
							@pnUserIdentityId		= @pnUserIdentityId,
							@psCulture			= @psCulture,
							@psQueryName			= @sQueryName,
							@psQueryDescription		= 'Query saved by system during asynchronous fee calculation. Delete when no longer required.',
							@pnContextKey			= @nQueryContextKey,
							@ptXMLFilterCriteria		= @ptXMLFilterCriteria,
							@pbUsesDefaultPresentation	= 1,		-- use the default presentation
							@pbIsPublic			= 0,
							@pbIsClientServer 		= 0,
							@pnGroupKey			= @nGroupId,	-- Saved query will appear beneath sub menu	
							@pbIsDefaultSearch		= 0,
							@pbIsReadOnly			= 1,
							@pbReturnNewKey                 = 0
							
			End
			-----------------------------------------------
			-- Build command line to run cs_ListCaseCharges 
			-- using service broker (rfc39102) 
			-----------------------------------------------
			Set @sCommand = 'dbo.cs_ListCaseCharges ' +
					'@pnUserIdentityId='+convert(varchar,@pnUserIdentityId)

			If @psCulture is not null
				Set @sCommand=@sCommand+",@psCulture='" +@psCulture+"'"

			If @pdtFromDate is not null
				Set @sCommand=@sCommand+",@pdtFromDate='" + convert(varchar,@pdtFromDate,121)+"'"

			If @pdtUntilDate is not null
				Set @sCommand=@sCommand+",@pdtUntilDate='" + convert(varchar,@pdtUntilDate,121)+"'"
				
			Set @sCommand = @sCommand + ",@pbCalledFromCentura=0,@pbDyamicChargeType=1"
			
			Set @sCommand=@sCommand+",@pdtWhenRequested='" + convert(varchar,@dtNow,121)+"'"
			
			Set @sCommand=@sCommand+",@pnSPID=" + convert(varchar,@nSpid)
			
			If @psEmailAddress is not null
				Set @sCommand=@sCommand+",@psEmailAddress='" + @psEmailAddress+"'"
				
			If @nQueryId is not null
				Set @sCommand=@sCommand+",@pnQueryId="+ convert(varchar,@nQueryId)
			
			Set @sCommand=@sCommand 
			
			---------------------------------------------------------------
			-- Run the command asynchronously using service broker
			--------------------------------------------------------------- 
			exec @ErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				

			--If @ErrorCode = 0
			--Begin
			--        -- Use local variable to prevent return value from being returned as a result set
			--        exec @ErrorCode = ipu_OAMethod @nObject, 'run', @nTempOAReturn Output, @sCommand
			--End
		End
	End
End 

If @ErrorCode=0
and @sResultTable<>@psGlobalTempTable
Begin
	---------------------------------
	-- Cleanup global temporary table
	-- by dropping it from database.
	---------------------------------
	Set @sSQLString="drop table "+@sResultTable
	
	exec @ErrorCode=sp_executesql @sSQLString
End

RETURN @ErrorCode
go

grant execute on dbo.cs_CacheCaseCharges  to public
go
