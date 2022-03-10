-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RecalculateInstructionTypeForName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_RecalculateInstructionTypeForName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_RecalculateInstructionTypeForName.'
	Drop procedure [dbo].[ip_RecalculateInstructionTypeForName]
End
Print '**** Creating Stored Procedure dbo.ip_RecalculateInstructionTypeForName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ip_RecalculateInstructionTypeForName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psInstructionType 	nvarchar(3),	-- Mandatiory
	@psAction		char(1),	-- Mandatory I=Insert, U=Update, D=Delete
	@pnNameKey 		int, 		-- Mandatory
	@pnInternalSequence	int		= null,
	@pbExistingEventsOnly	bit		= 0,
	@pbCountryNotChanged	bit		= 0,
	@pbPropertyNotChanged	bit		= 0,
	@pbNameNotChanged	bit		= 0
)
as
-- PROCEDURE:	ip_RecalculateInstructionTypeForName
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Generate Policing requests for the Case Events that should be recalculated as a result
--		of either the new, updated or removed standing instructions against a Name. This procedure
--		will typically be run asynchronously as a very large number of Policing rows may be generated.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Aug 2011	MF	R11205	1	Procedure created
-- 22-Feb-2012	LP	R11974	2	Do not create Policing Requests for Case Events where DATEDUESAVED=1.
-- 17-May-2012	MF	R12317	3	Newly added standing instructions should consider the Country, PropertyType
--					and Name of the new standing instruction when generating Policing requests. This
--					will avoid generating requests that are not required. The same already applies for
--					updates to standing instructions where the main characteristic has not changed.
-- 09 Jan 2014	MF	R41513	4	Events triggered to recalculate the due date (Type of Request = 6) should also consider Events that are flagged with RECALCEVENTDATE=1
--					if the Site Control 'Policing Recalculates Event' is set to TRUE.
-- 14 Nov 2018  AV	DR-45358 5	Date conversion errors when creating cases and opening names in Chinese DB
-- 21 Jun 2019	MF	DR-49099 6	Give consideration to the CASE STATUS to determine if Policing is active before generating Policing requests.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Create a temporary table to hold the generated POLICING request rows

Create Table #TEMPPOLICING (
		DATEENTERED          datetime 		NOT NULL,
		POLICINGSEQNO        int		identity,
		SYSGENERATEDFLAG     decimal(1,0)	NULL,
		ACTION               nvarchar(2)	collate database_default NULL,
		EVENTNO              int		NULL,
		CASEID               int		NULL,
		CRITERIANO           int		NULL,
		CYCLE                smallint		NULL,
		TYPEOFREQUEST        smallint		NULL,
		SQLUSER              nvarchar(60)	collate database_default NULL
		)

Declare @nErrorCode 	int
Declare @nRowCount 	int
Declare @nRowTotal	int
Declare @sSQLString	nvarchar(3000)
Declare	@sSQLWhere	nvarchar(1000)
Declare @bRecalcEvent	bit

Declare	@sCountryCode	nvarchar(3)
Declare	@sPropertyType	nchar(1)
Declare	@sNameType	nvarchar(3)
Declare	@nNameNo	int
Declare	@nBatchNo 	int

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount  = 0

If @nErrorCode=0
Begin
	Select @bRecalcEvent=COLBOOLEAN
	from SITECONTROL
	where CONTROLID='Policing Recalculates Event'
	
	Set @nErrorCode=@@ERROR
End

-- Generate Policing requests for the Case Events that should be recalculated as a result
-- of either the new, updated or removed standing instructions

-- Load a temporary table which will generate the sequence number required in the POLICING table.


------------------------------------------------------------------
-- Recalculate the CaseEvent rows for Cases linked to the Name
-- whose standing instruction has been changed.
------------------------------------------------------------------
If @psAction in ('I')
Begin
	Set @pbCountryNotChanged =1
	Set @pbPropertyNotChanged=1 
	Set @pbNameNotChanged    =1 
End

If @pbCountryNotChanged=1 
OR @pbPropertyNotChanged=1 
OR @pbNameNotChanged=1
Begin
	-------------------------------------------------------------
	-- If the Standing Instruction has been updated then get the
	-- Case characteristics that the Standing Instruction applies
	-- to so that a limited set of Policing recalculations may
	-- be requested.
	-------------------------------------------------------------
	Set @sSQLString="
	Select  @sCountryCode =NI.COUNTRYCODE,
		@sPropertyType=NI.PROPERTYTYPE,
		@nNameNo      =NI.RESTRICTEDTONAME,
		@sNameType    =IT.RESTRICTEDBYTYPE
	from NAMEINSTRUCTIONS NI
	join INSTRUCTIONS I	on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
	join INSTRUCTIONTYPE IT	on (IT.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
	where NI.NAMENO=@pnNameKey
	and NI.INTERNALSEQUENCE=@pnInternalSequence
	and IT.INSTRUCTIONTYPE=@psInstructionType"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sCountryCode		nvarchar(3)	OUTPUT,
				  @sPropertyType	nchar(1)	OUTPUT,
				  @nNameNo		int		OUTPUT,
				  @sNameType		nvarchar(3)	OUTPUT,
				  @pnNameKey		int,
				  @pnInternalSequence	int,
				  @psInstructionType	nvarchar(3)',
				  @sCountryCode		=@sCountryCode	OUTPUT,
				  @sPropertyType	=@sPropertyType	OUTPUT,
				  @nNameNo		=@nNameNo	OUTPUT,
				  @sNameType		=@sNameType	OUTPUT,
				  @pnNameKey		=@pnNameKey,
				  @pnInternalSequence	=@pnInternalSequence,
				  @psInstructionType	=@psInstructionType
End

If @nErrorCode=0
Begin
	If @pbExistingEventsOnly=1
	Begin
		-----------------------------------------------------------------
		-- If only characteristic(s) of the instruction have changed then
		-- only CaseEvent rows that exist and have a due date need to be 
		-- recalculated by Policing
		-----------------------------------------------------------------
		Set @sSQLString="
		insert into #TEMPPOLICING (DATEENTERED, SYSGENERATEDFLAG, ACTION, EVENTNO, CASEID, CRITERIANO, CYCLE, TYPEOFREQUEST, SQLUSER)
		Select getdate(), 1,  OA.ACTION, EC.EVENTNO, OA.CASEID, OA.CRITERIANO, CE.CYCLE, 6, SYSTEM_USER
		From  INSTRUCTIONTYPE IT
		join CASENAME CN	on (CN.NAMETYPE = IT.NAMETYPE)
		join OPENACTION OA	on (OA.CASEID=CN.CASEID
					and OA.POLICEEVENTS=1)
		join CASES C		on (C.CASEID=OA.CASEID)
		join ACTIONS A		on (A.ACTION=OA.ACTION)
		join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
					and EC.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
		join CASEEVENT CE	on (CE.CASEID=OA.CASEID
					and CE.EVENTNO=EC.EVENTNO
					and CE.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN OA.CYCLE ELSE CE.CYCLE END)
		left join (select N.CASEID, N.NAMENO, I.INSTRUCTIONTYPE
			   from NAMEINSTRUCTIONS N
			   join INSTRUCTIONS I on (I.INSTRUCTIONCODE=N.INSTRUCTIONCODE) ) NI
					on (NI.CASEID=OA.CASEID
					and NI.NAMENO=CN.NAMENO
					and NI.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
		left join PROPERTY P	on (P.CASEID=C.CASEID)
		left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
		left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)"

		Set @sSQLWhere="
		Where  IT.INSTRUCTIONTYPE = @psInstructionType
		and CN.NAMENO = @pnNameKey
		and NI.CASEID is null
		and    ((A.ACTIONTYPEFLAG  =0 and (S.POLICEOTHERACTIONS=1 or S.STATUSCODE  is null))
		 or     (A.ACTIONTYPEFLAG  =2 and (S.POLICEEXAM        =1 or S.STATUSCODE  is null))
		 or     (A.ACTIONTYPEFLAG  =1 and (S.POLICERENEWALS    =1 or S.STATUSCODE  is null) 
					      and (S1.POLICERENEWALS   =1 or S1.STATUSCODE is null)))
		and((isnull(CE.OCCURREDFLAG,0)=0 and isnull(CE.DATEDUESAVED,0)=0)
		 or (@bRecalcEvent=1 and EC.RECALCEVENTDATE=1 and EC.SAVEDUEDATE between 2 and 5))"
	End
	Else Begin
		Set @sSQLString="
		insert into #TEMPPOLICING (DATEENTERED, SYSGENERATEDFLAG, ACTION, EVENTNO, CASEID, CRITERIANO, CYCLE, TYPEOFREQUEST, SQLUSER)
		Select distinct getdate(), 1, OA.ACTION, EC.EVENTNO, OA.CASEID, OA.CRITERIANO, 
			isnull(	CASE WHEN(A.NUMCYCLESALLOWED>1) 
				THEN OA.CYCLE 
				ELSE Case DD.RELATIVECYCLE
					WHEN (0) Then CE1.CYCLE
					WHEN (1) Then CE1.CYCLE+1
					WHEN (2) Then CE1.CYCLE-1
						 Else isnull(DD.CYCLENUMBER,1)
				     End
			END,1),
			6, SYSTEM_USER
		From  INSTRUCTIONTYPE IT
		join CASENAME CN	on (CN.NAMETYPE = IT.NAMETYPE)
		join OPENACTION OA	on (OA.CASEID=CN.CASEID
					and OA.POLICEEVENTS=1)
		join CASES C		on (C.CASEID=OA.CASEID)
		join ACTIONS A		on (A.ACTION=OA.ACTION)
		join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
					and EC.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
		left join DUEDATECALC DD
					on (DD.CRITERIANO=EC.CRITERIANO
					and DD.EVENTNO   =EC.EVENTNO)
		left join CASEEVENT CE1	on (CE1.CASEID =OA.CASEID
					and CE1.EVENTNO=DD.FROMEVENT)
		left join CASEEVENT CE2	on (CE2.CASEID =OA.CASEID
					and CE2.EVENTNO=EC.EVENTNO
					and CE2.CYCLE  =CASE WHEN(A.NUMCYCLESALLOWED>1) 
								THEN OA.CYCLE 
								ELSE Case DD.RELATIVECYCLE
									WHEN (0) Then CE1.CYCLE
									WHEN (1) Then CE1.CYCLE+1
									WHEN (2) Then CE1.CYCLE-1
										 Else isnull(DD.CYCLENUMBER,1)
								     End
							END)
		left join (select N.CASEID, N.NAMENO, I.INSTRUCTIONTYPE
			   from NAMEINSTRUCTIONS N
			   join INSTRUCTIONS I on (I.INSTRUCTIONCODE=N.INSTRUCTIONCODE) ) NI
					on (NI.CASEID=OA.CASEID
					and NI.NAMENO=CN.NAMENO
					and NI.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
		left join PROPERTY P	on (P.CASEID=C.CASEID)
		left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
		left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)"

		Set @sSQLWhere="
		Where  IT.INSTRUCTIONTYPE = @psInstructionType
		and CN.NAMENO = @pnNameKey
		and    ((A.ACTIONTYPEFLAG  =0 and (S.POLICEOTHERACTIONS=1 or S.STATUSCODE  is null))
		 or     (A.ACTIONTYPEFLAG  =2 and (S.POLICEEXAM        =1 or S.STATUSCODE  is null))
		 or     (A.ACTIONTYPEFLAG  =1 and (S.POLICERENEWALS    =1 or S.STATUSCODE  is null) 
					      and (S1.POLICERENEWALS   =1 or S1.STATUSCODE is null)))
		and((isnull(CE2.OCCURREDFLAG,0)=0 and isnull(CE2.DATEDUESAVED,0)=0)
		 or (@bRecalcEvent=1 and EC.RECALCEVENTDATE=1 and EC.SAVEDUEDATE between 2 and 5))
		and NI.CASEID is null"
	End

	If (@pbCountryNotChanged =1 and @sCountryCode  is not null)
	OR (@pbPropertyNotChanged=1 and @sPropertyType is not null)
	Begin
		Set @sSQLString=@sSQLString+"
		join CASES CS		on (CS.CASEID=CN.CASEID)"
	End

	If  @pbNameNotChanged=1
	and @sNameType is not null
	and @nNameNo   is not null
	Begin
		Set @sSQLString=@sSQLString+"
		join CASENAME CN1	on (CN1.CASEID  =CN.CASEID
					and CN1.NAMETYPE=@sNameType
					and CN1.NAMENO  =@nNameNo)"
	End			

	If (@pbCountryNotChanged =1 and @sCountryCode  is not null)
	Begin
		Set @sSQLWhere=@sSQLWhere+"
		and CS.COUNTRYCODE=@sCountryCode"
	End		

	If (@pbPropertyNotChanged=1 and @sPropertyType is not null)
	Begin
		Set @sSQLWhere=@sSQLWhere+"
		and CS.PROPERTYTYPE=@sPropertyType"
	End

	Set @sSQLString=@sSQLString+char(10)+@sSQLWhere

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey		int,
				  @psInstructionType	nvarchar(3),
				  @sCountryCode		nvarchar(3),
				  @sPropertyType	nchar(1),
				  @nNameNo		int,
				  @sNameType		nvarchar(3),
				  @bRecalcEvent		bit',
				  @pnNameKey		= @pnNameKey,
				  @psInstructionType	= @psInstructionType,
				  @sCountryCode		= @sCountryCode,
				  @sPropertyType	= @sPropertyType,
				  @nNameNo		= @nNameNo,
				  @sNameType		= @sNameType,
				  @bRecalcEvent		= @bRecalcEvent

	Set @nRowCount=@@RowCount
End
-------------------------------------------------
-- If the option to Police Immediately is on then
-- get the next Policing Batch No to use.
-------------------------------------------------
If exists(Select 1 from SITECONTROL WITH(NOLOCK) where CONTROLID='Police Immediately' and COLBOOLEAN=1)
and @nErrorCode=0
and @nRowCount >0
Begin		
	------------------------------------------------------
	-- Get the Batchnumber to use for Police Immediately.
	-- BatchNumber is relatively shortlived so reset it
	-- by incrementing the maximum BatchNo on the Policing
	-- table.
	------------------------------------------------------
	Update LASTINTERNALCODE
	set INTERNALSEQUENCE=P.BATCHNO+1,
	    @nBatchNo       =P.BATCHNO+1
	from LASTINTERNALCODE L
	cross join (select max(isnull(BATCHNO,0)) as BATCHNO
		    from POLICING with(NOLOCK)) P
	where TABLENAME='POLICINGBATCH'

	Select @nRowTotal=@@Rowcount,
	       @nErrorCode=@@Error

	If @nRowTotal=0
	and @nErrorCode=0
	Begin
		Insert into LASTINTERNALCODE(TABLENAME, INTERNALSEQUENCE)
		values ('POLICINGBATCH', 0)
	
		Select @nErrorCode=@@Error
		
		set @nBatchNo=0
	End
End

-----------------------------------------------------------
-- Now load the generated POLICING rows into the live table
-----------------------------------------------------------
If @nErrorCode=0
and @nRowCount>0
Begin
	Set @sSQLString="
	insert into POLICING (	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, ACTION,
				EVENTNO, CASEID, CRITERIANO, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID, BATCHNO)
	select T.DATEENTERED, T.POLICINGSEQNO, convert(varchar,T.DATEENTERED,126)+convert(varchar,T.POLICINGSEQNO), T.SYSGENERATEDFLAG, 
		CASE WHEN(@nBatchNo is not null) THEN 1 ELSE 0 END, 
		T.ACTION, T.EVENTNO, T.CASEID, T.CRITERIANO, T.CYCLE, T.TYPEOFREQUEST, T.SQLUSER, @pnUserIdentityId, @nBatchNo
	from #TEMPPOLICING T
	left join POLICING P	on (P.CASEID =T.CASEID
				and P.EVENTNO=T.EVENTNO
				and P.CYCLE  =T.CYCLE
				and P.SYSGENERATEDFLAG=1
				and P.TYPEOFREQUEST   =6)
	where P.CASEID is null"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				@nBatchNo		int',
				@pnUserIdentityId 	= @pnUserIdentityId,
				@nBatchNo		= @nBatchNo
End

If  @nErrorCode=0
and @nBatchNo is not null
Begin
	--------------------------------------------------------
	-- If Policing is to be run immediately then the batchno
	-- used on the Policing rows will be passed to Policing
	-- to be run asynchronously.
	--------------------------------------------------------
	exec @nErrorCode=dbo.ipu_Policing_async
				@pnBatchNo       =@nBatchNo,
				@pnUserIdentityId=@pnUserIdentityId
End

Return @nErrorCode
GO

Grant execute on dbo.ip_RecalculateInstructionTypeForName to public
GO
