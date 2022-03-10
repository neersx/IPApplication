-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_CaseNameGlobalUpdates 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ede_CaseNameGlobalUpdates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ede_CaseNameGlobalUpdates.'
	drop procedure dbo.ede_CaseNameGlobalUpdates
end
go
print '**** Creating procedure dbo.ede_CaseNameGlobalUpdates...'
print ''

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ede_CaseNameGlobalUpdates
			@pnUserIdentityId	int,			-- Mandatory
			@pnBatchNo		int,			-- Mandatory
			@pnTransNo		int		=null,
			@pbPoliceImmediately	bit		=1,	-- Option to run Police Immediately
			@pbUseFutureNameType	bit		=1	-- Use the FutureNameType if it is available
as
-- PROCEDURE :	ede_CaseNameGlobalUpdates
-- VERSION :	10
-- DESCRIPTION:	CaseName changes will be applied to the database by utilising the Global
--		Name Change functionality which encapsulates all of the rules associated
--		with name changes such as :
--			Update of Event
--			Trigger other inherited NameType changes
--			Standing Instruction changes
-- COPYRIGHT: 	Copyright CPA Software Solutions (Australia) Pty Limited
-- Date		Who	SQA#	Version	Change
-- ------------	---	-------	-------	----------------------------------------------- 
-- 10 Apr 2007	MF		1	Procedure created
-- 22 May 2008	MF	16430	2	Global Name change requests are to be loaded into a table in the database and 
--					the request started asynchronously.
-- 02 Jul 2008	MF	16610	3	Extension to 16430 to call Global Name Change to process all of the requests
--					for this one transaction no by calling cs_GlobalNameChangeByTransNo
-- 28 Aug 2008	DL		4	Fix merge problem and correct typo for variable @pnTransNo to make it compilable on case sensitive database.
-- 11 Dec 2008	MF	17136	5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 28 May 2013	DL	10030	6	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 09 Jul 2013	MF	21426	7	Global name changes that are applying an UPDATE or an INSERT for a given NameType
--					should use the FUTURENAMETYPE if it is available and UPDATEs should switch to an INSERT.
-- 14 Apr 2014	MF	21426	8	Revisit of 21426.
-- 14 Oct 2014	DL	R39102	9	Use service broker instead of OLE Automation to run the command asynchronoulsly
-- 19 Jul 2017	MF	71968	10	When determining the default Case program, first consider the Profile of the User.


set nocount on


-- A temporary table to load all of the distinct possible global name changes 
-- ignoring the Cases that the change will be applied to.

Create table dbo.#TEMPGLOBALNAMECHANGES(
	TYPE			nvarchar(10)	collate database_default NOT NULL,
	NAMETYPE		nvarchar(3)	collate database_default NOT NULL,
	OLDNAMENO		int		null, 
	NAMENO			int		null, 
	OLDCORRESPONDNAME	int		null, 
	CORRESPONDNAME		int		null, 
	OLDREFERENCENO		nvarchar(80)	collate database_default NULL,
	REFERENCENO		nvarchar(80)	collate database_default NULL,
	OLDADDRESSCODE		int		null,
	ADDRESSCODE		int		null,
	COMMENCEDATE		datetime	null,
	ORDERBY			tinyint		not null,
	ORIGINALTYPE		nvarchar(10)	collate database_default NOT NULL,
	ORIGINALNAMETYPE	nvarchar(3)	collate database_default NOT NULL,
	SEQUENCENO		int		identity(1,1)
)

-- A temporary table to store the Cases that are to have the global name change applied
CREATE TABLE #TEMPCASESFORNAMECHANGE(
	CASEID			int		NOT NULL
 )


-- Declare working variables
Declare	@sSQLString 		nvarchar(4000)
Declare @TranCountStart		int
Declare @nErrorCode 		int
Declare	@nTransNo		int
Declare @nGlobalChanges		int
Declare @nCaseCount		int
Declare @nSequenceNo		int

-- Declare variables for Global Name Change
declare @sChangeType		nvarchar(10)
declare @sNameType		nvarchar(3)
declare @sOriginalType		nvarchar(10)
declare @sOriginalNameType	nvarchar(3)
declare @nOldNameNo		int
declare @nNewNameNo		int
declare @nOldAttn		int
declare @nNewAttn		int
declare @sOldRef		nvarchar(80)
declare @sNewRef		nvarchar(80)
declare @nOldAddress		int
declare @nNewAddress		int
declare @dtCommenceDate		datetime
declare	@sProgramId		nvarchar(8)
declare @nRequestNo		int

-- Variables for background processing
declare	@nObject		int
declare	@nObjectExist		tinyint
declare	@sCommand		varchar(255)

-----------------------
-- Initialise Variables
-----------------------
Set @nErrorCode = 0

If @nErrorCode=0
Begin
	------------------------------------------------------------
	-- Get a unique set of Name changes that will form the basis 
	-- of the Case global name change.
	-- If the NameType being modified has a Future Name Type 
	-- defined against it then swap in the Future Name Type.
	-- This approach will allow multiple Cases that are being
	-- updated with the same CASENAME details to be processed
	-- together in bulk.
	------------------------------------------------------------

	Set @sSQLString="
	insert into #TEMPGLOBALNAMECHANGES(TYPE,ORIGINALTYPE,NAMETYPE,ORIGINALNAMETYPE,OLDNAMENO,NAMENO,OLDCORRESPONDNAME,CORRESPONDNAME,OLDREFERENCENO,REFERENCENO,OLDADDRESSCODE,ADDRESSCODE,COMMENCEDATE,ORDERBY)
	select distinct CASE WHEN(T.TYPE='UPDATE' and NT.FUTURENAMETYPE is not null) THEN 'INSERT' ELSE T.TYPE END,T.TYPE,
			CASE WHEN(@pbUseFutureNameType=0 OR T.TYPE ='DELETE' )
				Then T.NAMETYPE
				Else isnull(NT.FUTURENAMETYPE,T.NAMETYPE)
			END, T.NAMETYPE,
			CASE WHEN(T.TYPE='UPDATE' and NT.FUTURENAMETYPE is not null) THEN NULL ELSE T.OLDNAMENO END,
			T.NAMENO,T.OLDCORRESPONDNAME,T.CORRESPONDNAME,T.OLDREFERENCENO,T.REFERENCENO,T.OLDADDRESSCODE,T.ADDRESSCODE,T.COMMENCEDATE,
			CASE(T.TYPE)
				WHEN('DELETE')	THEN 1
				WHEN('UPDATE')	THEN 2
						ELSE 3
			END
	from #TEMPCASENAME T
	join NAMETYPE NT on (NT.NAMETYPE=T.NAMETYPE)
	where 
	-- Ignore UPDATE entries where the change has already been applied
	not exists
	(select 1 from CASENAME CN
	 where CN.CASEID=T.CASEID
	 and CN.NAMETYPE=isnull(NT.FUTURENAMETYPE,T.NAMETYPE)
	 and CN.NAMENO=T.NAMENO
	 and checksum(CN.CORRESPONDNAME,CN.REFERENCENO,CN.ADDRESSCODE,CN.COMMENCEDATE)
		=  checksum(T.CORRESPONDNAME,T.REFERENCENO,T.ADDRESSCODE,T.COMMENCEDATE)
	 and CN.EXPIRYDATE is null
	 and T.TYPE='UPDATE')
	order by 12,2"

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@pbUseFutureNameType	bit',
					  @pbUseFutureNameType=@pbUseFutureNameType
	Set @nGlobalChanges=@@RowCount
End

If  @nGlobalChanges>0
and @nErrorCode=0
Begin
	------------------------------------------------------
	-- Use Global Name Change to apply all inheritance and
	-- standing instruction rules
	------------------------------------------------------

	------------------------------------------------------
	-- Get a default Case program which is required 
	-- by Global Name Change to determine what inherited 
	-- Name types are allowed
	------------------------------------------------------
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Select @sProgramId=left(isnull(PA.ATTRIBUTEVALUE,S.COLCHARACTER),8)
		from SITECONTROL S
		     join USERIDENTITY U        on (U.IDENTITYID=@pnUserIdentityId)
		left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=U.PROFILEID
						and PA.ATTRIBUTEID=2)	-- Default Cases Program
		where S.CONTROLID='Case Screen Default Program'"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sProgramId		nvarchar(8)	OUTPUT,
					  @pnUserIdentityId	int',
					  @sProgramId      =@sProgramId		OUTPUT,
					  @pnUserIdentityId=@pnUserIdentityId
	End

	---------------------------------------------------------
	-- Now loop through each unique set of Case Name Changes.
	-- These will be matched against the Cases they are to be
	-- applied to and the Global Name Change procedure will 
	-- be used to apply the changes.
	---------------------------------------------------------
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	Set @nSequenceNo=0
	
	While @nSequenceNo<@nGlobalChanges
	  and @nErrorCode=0
	Begin
		-- Increment the sequence to get each Global Name Change to be performed
		Set @nSequenceNo=@nSequenceNo+1

		Set @sSQLString="
		Select	@sChangeType	=TYPE,
			@sOriginalType	  =ORIGINALTYPE,
			@sNameType	=NAMETYPE,
			@sOriginalNameType=ORIGINALNAMETYPE,
			@nOldNameNo	=OLDNAMENO,
			@nNewNameNo	=NAMENO,
			@nOldAttn	=OLDCORRESPONDNAME,
			@nNewAttn	=CORRESPONDNAME,
			@sOldRef	=OLDREFERENCENO,
			@sNewRef	=REFERENCENO,
			@nOldAddress	=OLDADDRESSCODE,
			@nNewAddress	=ADDRESSCODE,
			@dtCommenceDate =COMMENCEDATE
		from #TEMPGLOBALNAMECHANGES
		where SEQUENCENO=@nSequenceNo"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nSequenceNo		int,
					  @sChangeType		nvarchar(10)		OUTPUT,
					  @sNameType		nvarchar(3)		OUTPUT,
					  @sOriginalType	nvarchar(10)		OUTPUT,
					  @sOriginalNameType	nvarchar(3)		OUTPUT,
					  @nOldNameNo		int			OUTPUT,
					  @nNewNameNo		int			OUTPUT,
					  @nOldAttn		int			OUTPUT,
					  @nNewAttn		int			OUTPUT,
					  @sOldRef		nvarchar(80)		OUTPUT,
					  @sNewRef		nvarchar(80)		OUTPUT,
					  @nOldAddress		int			OUTPUT,
					  @nNewAddress		int			OUTPUT,
					  @dtCommenceDate	datetime		OUTPUT',
					  @nSequenceNo		=@nSequenceNo,
					  @sChangeType		=@sChangeType		OUTPUT,
					  @sNameType		=@sNameType		OUTPUT,
					  @sOriginalType	=@sOriginalType		OUTPUT,
					  @sOriginalNameType	=@sOriginalNameType	OUTPUT,
					  @nOldNameNo		=@nOldNameNo		OUTPUT,
					  @nNewNameNo		=@nNewNameNo		OUTPUT,
					  @nOldAttn		=@nOldAttn		OUTPUT,
					  @nNewAttn		=@nNewAttn		OUTPUT,
					  @sOldRef		=@sOldRef		OUTPUT,
					  @sNewRef		=@sNewRef		OUTPUT,
					  @nOldAddress		=@nOldAddress		OUTPUT,
					  @nNewAddress		=@nNewAddress		OUTPUT,
					  @dtCommenceDate	=@dtCommenceDate	OUTPUT

		-- Now we need to load a temporary table with the Cases that
		-- are to be updated by the global name change
		If @nErrorCode=0
		Begin
			Set @sSQLString="
			insert into #TEMPCASESFORNAMECHANGE(CASEID)
			select distinct T.CASEID
			from #TEMPCASENAME T
			join NAMETYPE NT on (NT.NAMETYPE=T.NAMETYPE)
			where T.TYPE	=@sOriginalType
			and  T.NAMETYPE	=@sOriginalNameType
			and (T.OLDNAMENO	=@nOldNameNo	or (T.OLDNAMENO		is null and @nOldNameNo	is null) or @sOriginalType<>@sChangeType)
			and (T.NAMENO		=@nNewNameNo	or (T.NAMENO		is null and @nNewNameNo	is null))
			and (T.OLDCORRESPONDNAME=@nOldAttn	or (T.OLDCORRESPONDNAME	is null and @nOldAttn	is null))
			and (T.CORRESPONDNAME	=@nNewAttn	or (T.CORRESPONDNAME	is null and @nNewAttn	is null))
			and (T.OLDREFERENCENO	=@sOldRef	or (T.OLDREFERENCENO	is null and @sOldRef	is null))
			and (T.REFERENCENO	=@sNewRef	or (T.REFERENCENO	is null and @sNewRef	is null))
			and (T.OLDADDRESSCODE	=@nOldAddress	or (T.OLDADDRESSCODE	is null and @nOldAddress is null))
			and (T.ADDRESSCODE	=@nNewAddress	or (T.ADDRESSCODE	is null and @nNewAddress is null))
			and (T.COMMENCEDATE	=@dtCommenceDate or (T.COMMENCEDATE	is null and @dtCommenceDate is null)) 
			-- Ignore UPDATE entries where the change has already been applied
			and not exists
			(select 1 from CASENAME CN
			 where CN.CASEID=T.CASEID
			 and CN.NAMETYPE=isnull(NT.FUTURENAMETYPE,T.NAMETYPE)
			 and CN.NAMENO=T.NAMENO
			 and checksum(CN.CORRESPONDNAME,CN.REFERENCENO,CN.ADDRESSCODE,CN.COMMENCEDATE)
				=  checksum(@nNewAttn,@sNewRef,@nNewAddress,@dtCommenceDate)
			 and CN.EXPIRYDATE is null
			 and T.TYPE='UPDATE')"
		
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@sOriginalType	nvarchar(10),
					  @sOriginalNameType	nvarchar(3),
					  @sChangeType		nvarchar(10),
					  @nOldNameNo		int,
					  @nNewNameNo		int,
					  @nOldAttn		int,
					  @nNewAttn		int,
					  @sOldRef		nvarchar(80),
					  @sNewRef		nvarchar(80),
					  @nOldAddress		int,
					  @nNewAddress		int,
					  @dtCommenceDate	datetime',
					  @sOriginalType	=@sOriginalType,
					  @sOriginalNameType	=@sOriginalNameType,
					  @sChangeType		=@sChangeType,
					  @nOldNameNo		=@nOldNameNo,
					  @nNewNameNo		=@nNewNameNo,
					  @nOldAttn		=@nOldAttn,
					  @nNewAttn		=@nNewAttn,
					  @sOldRef		=@sOldRef,
					  @sNewRef		=@sNewRef,
					  @nOldAddress		=@nOldAddress,
					  @nNewAddress		=@nNewAddress,
					  @dtCommenceDate	=@dtCommenceDate

			Set @nCaseCount=@@Rowcount
		End

		-- Load the details for the global name change into the
		-- database to ensure that they are processed to completion.
		If @nCaseCount>0
		and @nErrorCode=0
		Begin
			Set @nRequestNo=null

			Set @sSQLString="
			insert into CASENAMEREQUEST(PROGRAMID,NAMETYPE,CURRENTNAMENO,CURRENTATTENTION,NEWNAMENO,NEWATTENTION,
						    UPDATEFLAG,INSERTFLAG,DELETEFLAG,
						    KEEPREFERENCEFLAG,
						    KEEPATTENTIONFLAG,INHERITANCEFLAG,NEWREFERENCE,COMMENCEDATE,ADDRESSCODE,ONHOLDFLAG,
						    EDEBATCHNO, LOGTRANSACTIONNO)
			values(	@sProgramId,@sNameType,@nOldNameNo,@nOldAttn,@nNewNameNo,@nNewAttn,
				CASE(@sChangeType) -- for UpdateFlag
					WHEN('UPDATE') THEN 1
					WHEN('DELETE') THEN 0
					WHEN('INSERT') THEN 0
				END,
				CASE(@sChangeType) -- for InsertFlag
					WHEN('UPDATE') THEN 0
					WHEN('DELETE') THEN 0
					WHEN('INSERT') THEN 1
				END,
				CASE(@sChangeType) -- for DeleteFlag
					WHEN('UPDATE') THEN 0
					WHEN('DELETE') THEN 1
					WHEN('INSERT') THEN 0
				END,
				CASE(@sChangeType) --for KeepReferenceFlag
					WHEN('UPDATE') THEN 3
					WHEN('DELETE') THEN 0
					WHEN('INSERT') THEN 3
				END,
				0,1,@sNewRef,@dtCommenceDate,@nNewAddress,0,@pnBatchNo,@pnTransNo)

			set @nRequestNo=SCOPE_IDENTITY()"
			
			exec @nErrorCode=sp_executesql @sSQLString,
					N'@sProgramId		nvarchar(8),
					  @sChangeType		nvarchar(10),
					  @sNameType		nvarchar(3),
					  @nOldNameNo		int,
					  @nNewNameNo		int,
					  @nOldAttn		int,
					  @nNewAttn		int,
					  @sOldRef		nvarchar(80),
					  @sNewRef		nvarchar(80),
					  @nNewAddress		int,
					  @dtCommenceDate	datetime,
					  @pnBatchNo		int,
					  @pnTransNo		int,
					  @nRequestNo		int		OUTPUT',
					  @sProgramId		=@sProgramId,
					  @sChangeType		=@sChangeType,
					  @sNameType		=@sNameType,
					  @nOldNameNo		=@nOldNameNo,
					  @nNewNameNo		=@nNewNameNo,
					  @nOldAttn		=@nOldAttn,
					  @nNewAttn		=@nNewAttn,
					  @sOldRef		=@sOldRef,
					  @sNewRef		=@sNewRef,
					  @nNewAddress		=@nNewAddress,
					  @dtCommenceDate	=@dtCommenceDate,
					  @pnBatchNo		=@pnBatchNo,
					  @pnTransNo		=@pnTransNo,
					  @nRequestNo		=@nRequestNo	OUTPUT

			If @nRequestNo is not null
			and @nErrorCode=0
			Begin
				Set @sSQLString="
				insert into CASENAMEREQUESTCASES(REQUESTNO,CASEID,LOGTRANSACTIONNO)
				select @nRequestNo,CASEID,@pnTransNo
				from #TEMPCASESFORNAMECHANGE"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@nRequestNo	int,
							  @pnTransNo	int',
							  @nRequestNo=@nRequestNo,
							  @pnTransNo=@pnTransNo
			End

			-- Clear out the Cases from the last global name change
			-- in preparation to reload with the next set of Cases to update
			If  @nErrorCode=0
			and @nSequenceNo<@nGlobalChanges
			Begin
				Set @sSQLString="delete from #TEMPCASESFORNAMECHANGE"
	
				exec @nErrorCode=sp_executesql @sSQLString
			End
		End
	End	-- end of loop through Global Name Changes

	-- Commit or Rollback the transaction before
	-- starting Global Name Change in background
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End

	If @pnTransNo is not null
	and @nErrorCode=0
	Begin
		------------------------------------------------
		-- Build command line to run cs_GlobalNameChange 
		-- using Service Broker (rfc39102)
		------------------------------------------------
		Select @sCommand = 'dbo.cs_GlobalNameChangeByTransNo @pnUserIdentityId='+CASE WHEN(@pnUserIdentityId is null) THEN 'null' ELSE cast(@pnUserIdentityId as varchar) END+',@pnTransNo='+cast(@pnTransNo as varchar)

		---------------------------------------------------------------
		-- Run the command asynchronously using Service Broker (rfc39102)
		--------------------------------------------------------------- 
		exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
	End
End

return @nErrorCode
go

grant execute on dbo.ede_CaseNameGlobalUpdates  to public
go
