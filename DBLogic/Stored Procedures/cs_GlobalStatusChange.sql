-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalStatusChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GlobalStatusChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GlobalStatusChange.'
	Drop procedure [dbo].[cs_GlobalStatusChange]
End
Print '**** Creating Stored Procedure dbo.cs_GlobalStatusChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GlobalStatusChange
(
	@pnResults		int		output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnProcessId		int,		-- Identifier for the background process request
	@psGlobalTempTable	nvarchar(50),	
	@pbDebugFlag            bit             = 0,
	@pbCalledFromCentura	bit		= 0,
	@psErrorMsg		nvarchar(max)	= null output
)
as
-- PROCEDURE:	cs_GlobalStatusChange
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update the Status of multiple cases.
--		Returns an error if Confirmation required and password is incorrect. 
--              No concurrency checking.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Oct 2010	LP	RFC9321	1	Procedure created
-- 05 Nov 2010	LP	RFC9321	2	Fixed incorrect table column STATUSCONFIRMPWD to STATUSCONFIRM
-- 28 Oct 2013  MZ	RFC10491 3	Fixed global field update of family not working and error message not showing correctly
-- 04 Dec 2013	MS	R12697	4	Raise error if any case has diary entry or draft bill and selected status 
--					restricts wip or billing transactions
-- 13 Jun 2018	MF	74342	5	Ability to change the renewal status for a batch of cases.
--					Also check that the status is VALID for the Case.
--					Also generate Policing requests if the change of Status will now allow certain Actions to calculate.
-- 14 Nov 2018  AV	DR-45358 6	Date conversion errors when creating cases and opening names in Chinese DB
-- 27 Jun 2019	MF	DR-49984 7	STOPPAYREASON should be set if there is one associated with the Status change.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @nRowCount		int
declare @sSQLString		nvarchar(max)
declare @dtWhenRequested	datetime
declare @nStatusCode		int
declare @nHasRestrictedCases	int
declare @sAlert			nvarchar(1000)
declare @sStopPayReason		nchar(1)
declare @bRenewalFlag		bit

CREATE TABLE #UPDATEDCASES(
		CASEID		int NOT NULL,
		OLDSTATUSCODE	int NULL
		)

CREATE TABLE #TEMPCASEPOLICING (
		CASEID		int		NOT NULL,
		ACTION		nvarchar(3)	collate database_default NOT NULL,
		CYCLE		int		NOT NULL,
		SEQUENCENO	int		identity(1,1)
		)

-- Initialise variables
Set @nErrorCode = 0

Begin Try
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @nStatusCode    = S.STATUSCODE,
		       @sStopPayReason = S.STOPPAYREASON,
		       @bRenewalFlag   = cast(isnull(S.RENEWALFLAG,0) as bit)
		from GLOBALCASECHANGEREQUEST G
		left join STATUS S on (S.STATUSCODE=G.STATUSCODE)
		where PROCESSID = @pnProcessId"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@nStatusCode		int		OUTPUT,
					  @bRenewalFlag		bit		OUTPUT,
					  @sStopPayReason	nchar(1)	OUTPUT,
					  @pnProcessId		int',
					  @nStatusCode		= @nStatusCode	  OUTPUT,
					  @bRenewalFlag		= @bRenewalFlag	  OUTPUT,
					  @sStopPayReason	= @sStopPayReason OUTPUT,
					  @pnProcessId		= @pnProcessId

		If  @nErrorCode = 0
		and @nStatusCode is null
		Begin
			Set @sAlert = 'The Status Code provided is no longer available for selection.' 
  		
			RAISERROR(@sAlert, 14, 1)
  			Set @nErrorCode = @@ERROR
		End	
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString = 
		"Select @nHasRestrictedCases = count(CS.CASEID)
		from " +@psGlobalTempTable+ " CS
		join STATUS S on (S.STATUSCODE = @nStatusCode)
		where ((ISNULL(S.PREVENTWIP,0) = 1 or ISNULL(S.PREVENTBILLING,0) = 1) and 
				exists (Select 1 from DIARY D
						where D.CASEID = CS.CASEID 
						and D.WIPENTITYNO is null 
						and D.TRANSNO is null 
						and D.ISTIMER = 0 
						and D.TIMEVALUE > 0))
			or (ISNULL(S.PREVENTBILLING,0) = 1 and 
				exists (Select 1 from WORKINPROGRESS WIP where WIP.CASEID = CS.CASEID))"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@nStatusCode		int,
					  @nHasRestrictedCases	int	output',
					  @nStatusCode		= @nStatusCode,
					  @nHasRestrictedCases	= @nHasRestrictedCases OUTPUT

		If @nErrorCode = 0 and ISNULL(@nHasRestrictedCases,0) > 0
		Begin
			Set @sAlert = 'The selected Case Status restricts WIP or Billing transactions. ' +
			 'One or more cases in the list have draft bills or unposted time entries that must be processed or removed before the status can be changed.'
  		
			RAISERROR(@sAlert, 14, 1)
  			Set @nErrorCode = @@ERROR
		End	
	End

	If  @nErrorCode  = 0
	Begin
		If @bRenewalFlag= 1
		Begin
			Set @sSQLString = "
			UPDATE P
			Set RENEWALSTATUS = GC.STATUSCODE
			OUTPUT INSERTED.CASEID, DELETED.RENEWALSTATUS
			INTO #UPDATEDCASES
			from CASES C
			join " +@psGlobalTempTable+ " CS on (CS.CASEID = C.CASEID)
			join PROPERTY P			on (P.CASEID   = C.CASEID)
			join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
			join STATUS S			on (S.STATUSCODE = GC.STATUSCODE)
			join VALIDSTATUS V		on (V.STATUSCODE = GC.STATUSCODE
							and V.PROPERTYTYPE=C.PROPERTYTYPE
							and V.CASETYPE    =C.CASETYPE
							and V.COUNTRYCODE =(	select min(V1.COUNTRYCODE)
										from VALIDSTATUS V1
										where V1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')
										and   V1.CASETYPE    =V.CASETYPE
										and   V1.PROPERTYTYPE=V.PROPERTYTYPE))
			left join SITECONTROL SC on (SC.CONTROLID = 'Confirmation Passwd')
			where ((S.CONFIRMATIONREQ = 1 and SC.COLCHARACTER = GC.STATUSCONFIRM) OR (S.CONFIRMATIONREQ = 0))
			and (P.RENEWALSTATUS<>GC.STATUSCODE OR P.RENEWALSTATUS is null)
	
			set @pnResults = @@RowCount"
		
			If @pbDebugFlag = 1
			Begin
				Print @sSQLString
			End

			exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnProcessId	int,
						  @pnResults	int	output',
						  @pnProcessId	= @pnProcessId,
						  @pnResults	= @pnResults OUTPUT

			If @nErrorCode=0
			and @sStopPayReason is not null
			Begin
				-------------------------------------
				-- Apply the STOPPAYREASON if one is 
				-- mapped to the new Renewal Status
				-------------------------------------
				Set @sSQLString = "
				UPDATE CASES
				Set STOPPAYREASON = isnull(S.STOPPAYREASON, C.STOPPAYREASON)
				from CASES C
				join " +@psGlobalTempTable+ " CS on (CS.CASEID = C.CASEID)
				join PROPERTY P			on (P.CASEID   = C.CASEID)
				join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
				join STATUS S			on (S.STATUSCODE = GC.STATUSCODE)
				where P.RENEWALSTATUS=S.STATUSCODE"
		
				If @pbDebugFlag = 1
				Begin
					Print @sSQLString
				End

				exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnProcessId	int',
							  @pnProcessId	= @pnProcessId
			End
		End
		Else Begin
			Set @sSQLString = "
			UPDATE CASES
			Set STATUSCODE = GC.STATUSCODE, 
			    STOPPAYREASON = isnull(S.STOPPAYREASON, C.STOPPAYREASON)
			OUTPUT INSERTED.CASEID, DELETED.STATUSCODE
			INTO #UPDATEDCASES
			from CASES C
			join " +@psGlobalTempTable+ " CS on (CS.CASEID = C.CASEID)
			join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
			join STATUS S			on (S.STATUSCODE = GC.STATUSCODE)
			join VALIDSTATUS V		on (V.STATUSCODE = GC.STATUSCODE
							and V.PROPERTYTYPE=C.PROPERTYTYPE
							and V.CASETYPE    =C.CASETYPE
							and V.COUNTRYCODE =(	select min(V1.COUNTRYCODE)
										from VALIDSTATUS V1
										where V1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')
										and   V1.CASETYPE    =V.CASETYPE
										and   V1.PROPERTYTYPE=V.PROPERTYTYPE))
			left join SITECONTROL SC on (SC.CONTROLID = 'Confirmation Passwd')
			where ((S.CONFIRMATIONREQ = 1 and SC.COLCHARACTER = GC.STATUSCONFIRM) OR (S.CONFIRMATIONREQ = 0))
			and (C.STATUSCODE<>GC.STATUSCODE OR C.STATUSCODE is null)
	
			set @pnResults = @@RowCount"
		
			If @pbDebugFlag = 1
			Begin
				Print @sSQLString
			End

			exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnProcessId	int,
						  @pnResults	int	output',
						  @pnProcessId	= @pnProcessId,
						  @pnResults	= @pnResults OUTPUT
		End
	End
	
	If @pnResults > 0
	Begin
		---------------------------------
		-- Flag the Cases that have had a 
		-- change of Status or Renewal
		-- Status applied.
		---------------------------------
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			UPDATE C
			SET STATUSUPDATED = 1
			from " +@psGlobalTempTable+ " C
			join #UPDATEDCASES UC on (UC.CASEID = C.CASEID)
			"
		
			exec @nErrorCode = sp_executesql @sSQLString
		End

		---------------------------------
		-- Record the status change in 
		-- the ActivityHistory
		---------------------------------
		If @nErrorCode = 0
		Begin
			Set @dtWhenRequested = getdate()

			Set @sSQLString = "
			Insert into ACTIVITYHISTORY
			(	CASEID,
				WHENREQUESTED,
				SQLUSER,
				PROGRAMID,
				ACTION,
				EVENTNO,
				CYCLE,
				STATUSCODE,
				IDENTITYID)
			SELECT CASEID, @dtWhenRequested, SYSTEM_USER, null, null, null, null, @nStatusCode, @pnUserIdentityId
			from #UPDATEDCASES"
		
			exec @nErrorCode = sp_executesql @sSQLString,
							      N'@dtWhenRequested	datetime,
								@nStatusCode		int,
								@pnUserIdentityId	int',
								@dtWhenRequested	= @dtWhenRequested,
								@nStatusCode		= @nStatusCode,
								@pnUserIdentityId	= @pnUserIdentityId
		End
		
		---------------------------------
		-- If the status change allows
		-- Policing to now calculate
		-- certain Actions, then raise
		-- the Policing requests.
		---------------------------------
		If @nErrorCode = 0
		Begin
			Set @sSQLString="
			insert into #TEMPCASEPOLICING(CASEID, ACTION, CYCLE)
			Select T.CASEID, OA.ACTION, OA.CYCLE
			from #UPDATEDCASES T
			join OPENACTION OA	on (OA.CASEID=T.CASEID
						and OA.POLICEEVENTS=1)
			join ACTIONS A		on (A.ACTION=OA.ACTION)
			left join STATUS OLD	on (OLD.STATUSCODE=T.OLDSTATUSCODE)  -- It is possible that we are replacing a missing Status Code.
			join STATUS NEW		on (NEW.STATUSCODE=@nStatusCode)
			where  ((A.ACTIONTYPEFLAG  =0 and NEW.RENEWALFLAG=0 and NEW.POLICEOTHERACTIONS=1 and OLD.POLICEOTHERACTIONS=0)  -- The action is not Renewal/Exam, the Case Status is being updated from one that blocked Policing                to one that allows Policing
			 or     (A.ACTIONTYPEFLAG  =2 and NEW.RENEWALFLAG=0 and NEW.POLICEEXAM        =1 and OLD.POLICEEXAM        =0)  -- The action is     Examination,  the Case Status is being updated from one that blocked Policing of Examination to one that allows Policing of Examination
			 or     (A.ACTIONTYPEFLAG  =1                       and NEW.POLICERENEWALS    =1 and OLD.POLICERENEWALS    =0)) -- The action is     Renewal,      the      Status is being updated from one that blocked Policing of Renewals    to one that allows Policing of Renewals"

			exec @nErrorCode=sp_executesql @sSQLString,
							N'@nStatusCode		int',
							  @nStatusCode = @nStatusCode

			Set @nRowCount=@@Rowcount

			If  @nErrorCode=0
			and @nRowCount >0
			Begin
				----------------------------------------------------------
				-- Now load live Policing table with generated sequence no
				----------------------------------------------------------
				Set @sSQLString="
				insert into POLICING (DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
			 			      ONHOLDFLAG, ACTION, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
				select	getdate(), 
					T.SEQUENCENO, 
					'Status-'+convert(varchar, getdate(),126)+convert(varchar,T.SEQUENCENO),
					1,
					0, 
					T.ACTION, 
					T.CASEID, 
					T.CYCLE, 
					1, 
					substring(SYSTEM_USER,1,60), 
					@pnUserIdentityId
				from #TEMPCASEPOLICING T"

				exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId	int',
						  @pnUserIdentityId=@pnUserIdentityId
			End
		End
	End


End Try
Begin Catch
	SET @nErrorCode = ERROR_NUMBER()
	SET @psErrorMsg = ERROR_MESSAGE()
End Catch

Return @nErrorCode
GO

Grant execute on dbo.cs_GlobalStatusChange to public
GO
