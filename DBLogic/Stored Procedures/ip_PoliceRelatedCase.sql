-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceRelatedCase									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_PoliceRelatedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_PoliceRelatedCase.'
	Drop procedure [dbo].[ip_PoliceRelatedCase]
End
Print '**** Creating Stored Procedure dbo.ip_PoliceRelatedCase...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ip_PoliceRelatedCase
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,			-- Mandatory
	@pnRelationshipNo	int,			-- Mandatory
	@pnPolicingBatchNo	int		= null 	-- The batch number to be used with Policing requests.  
							-- Should be set to a non-null value when the calling code 
							-- intends to do its own policing. 
)
as
-- PROCEDURE:	ip_PoliceRelatedCase
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Check whether a related case with the specified relationship number has to be policed.  
--		If it has to be then add request(s) to the policing queue.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 10 May 2006	IB	RFC3717	1	Procedure created
-- 02 June 2006	vql	12016	2	Return result set for Centura
-- 06 Feb 2018	MF	73065	3	Event that are determined from a related Case may need to be cleared
--					out so that Policing can recalculate them.
-- 21-Oct-2019	DL	DR-52908 4	Error after adding related cases when creating a new case
--

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON


declare @tbPolicing table (
		POLICINGSEQNO	smallint	identity,
		CASEID		int		NOT NULL,
		EVENTNO		int		NOT NULL,
		CYCLE		smallint	NOT NULL,
		CLEAREVENTDATE	bit		NOT NULL
 		)
Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(max)
Declare	@bOnHoldFlag		bit

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount = 0

-- Need to go via an interim temporary table 
-- in order to generate an internal sequence number.
If @nErrorCode=0
Begin
	Insert into @tbPolicing(
		CASEID, 
		EVENTNO, 
		CYCLE, 
		CLEAREVENTDATE)
	select	OA.CASEID, 
		EC.EVENTNO,
		CASE 
			WHEN(EC.RECEIVINGCYCLEFLAG=1) THEN isnull(RC.CYCLE,1) 
			ELSE 1 
		END, 
		CASE WHEN(CE1.OCCURREDFLAG=1 OR CE1.EVENTDATE is not null) THEN 1 ELSE 0 END
	from 	RELATEDCASE RC
	join 	OPENACTION OA	on (OA.CASEID=RC.CASEID
				and OA.POLICEEVENTS=1)
	join 	EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
				and EC.FROMRELATIONSHIP=RC.RELATIONSHIP)
	join 	CASEEVENT CE	on (CE.CASEID=RC.RELATEDCASEID
				and CE.EVENTNO=EC.UPDATEFROMEVENT
				and CE.CYCLE=isnull(RC.CYCLE,1)
				and CE.OCCURREDFLAG=1)
	left join CASEEVENT CE1	on (CE1.CASEID=OA.CASEID
				and CE1.EVENTNO=EC.EVENTNO
				and CE1.CYCLE= 	CASE
							WHEN(EC.RECEIVINGCYCLEFLAG=1) THEN isnull(RC.CYCLE,1) 
							ELSE 1 
						END)
	where 	RC.CASEID=@pnCaseKey 
	and 	RC.RELATIONSHIPNO=@pnRelationshipNo
	UNION
	select 	OA.CASEID, 
		DD.EVENTNO,
		CASE(DD.COMPARECYCLE)
			WHEN(0) THEN CE.CYCLE
			WHEN(1) THEN CE.CYCLE+1
			WHEN(2) THEN CE.CYCLE-1
			ELSE 1
		END,
		0
	from 	RELATEDCASE RC
	join 	OPENACTION OA	on (OA.CASEID=RC.CASEID 
				and OA.POLICEEVENTS=1)
	join 	DUEDATECALC DD	on (DD.CRITERIANO=OA.CRITERIANO 
				and DD.COMPARERELATIONSHIP=RC.RELATIONSHIP)
	join 	CASEEVENT CE	on (CE.CASEID=RC.RELATEDCASEID
				and CE.EVENTNO=DD.COMPAREEVENT
				and CE.OCCURREDFLAG=1)
	left join CASEEVENT CE1	on (CE1.CASEID=OA.CASEID
				and CE1.EVENTNO=DD.EVENTNO
				and CE1.CYCLE=	CASE(DD.COMPARECYCLE)
							WHEN(0) THEN CE.CYCLE
							WHEN(1) THEN CE.CYCLE+1
							WHEN(2) THEN CE.CYCLE-1
							ELSE 1
					 	END
				and CE1.OCCURREDFLAG=1)
	where	RC.CASEID=@pnCaseKey
	and 	RC.RELATIONSHIPNO=@pnRelationshipNo
	and 	CE1.CASEID is null

	Select @nErrorCode=@@Error,
	       @nRowCount=@@Rowcount

End

If @nErrorCode = 0
and @nRowCount > 0
Begin
	--------------------------------------------
	-- Event Dates that are determined from the
	-- related Case may need to be cleared out
	-- so that they will recalculate
	--------------------------------------------
	Update CE
	Set EVENTDATE=null,
	    OCCURREDFLAG=0
	From @tbPolicing T
	join CASEEVENT CE on (CE.CASEID =T.CASEID
			  and CE.EVENTNO=T.EVENTNO
			  and CE.CYCLE  =T.CYCLE)
	where T.CLEAREVENTDATE=1

	Set @nErrorCode=@@ERROR
End

If @nErrorCode = 0
and @nRowCount > 0
Begin
	If @pnPolicingBatchNo is null
	Begin
		Set @bOnHoldFlag = 0
	End
	Else
	Begin
		Set @bOnHoldFlag = 1
	End

	If @pbCalledFromCentura = 1
	Begin
		-- return CASEID, EVENTNO and CYCLE when called from Centura.
		-- Centura will handle the inserts to POLICING.
		Select CASEID, EVENTNO, CYCLE
		from @tbPolicing
	End
	Else
	Begin
		declare @dtCurrentDate		datetime
		declare @nPolicingSeq		int
				
		set @dtCurrentDate=GETDATE()
				
		-- generate key					
		If @nErrorCode = 0
		Begin										
			Select 	@nPolicingSeq = isnull(max(POLICINGSEQNO) + 1, 0)
			from	POLICING
			where 	DATEENTERED = @dtCurrentDate
				
			If @nPolicingSeq is null
				Set @nPolicingSeq = 0

			Set @nErrorCode = @@error
		End	

		If @nErrorCode = 0
		Begin	
			-- Use TYPEOFREQUEST = 6 (Recalculate Due Dates)
			Insert into POLICING(	
				DATEENTERED, 
				POLICINGSEQNO, 
				POLICINGNAME, 
				SYSGENERATEDFLAG, 
				ONHOLDFLAG, 
				ACTION, 
				TYPEOFREQUEST,
				SQLUSER, 
				BATCHNO, 
				CASEID, 
				EVENTNO, 
				CYCLE, 
				IDENTITYID)
			select	@dtCurrentDate, 
				POLICINGSEQNO+@nPolicingSeq, 
				dbo.fn_DateToString(@dtCurrentDate,'CLEAN-DATETIME') + cast(POLICINGSEQNO+@nPolicingSeq as nvarchar),
				1, 
				@bOnHoldFlag, 
				null, 
				6, 	
				SYSTEM_USER, 
				@pnPolicingBatchNo, 
				CASEID, 
				EVENTNO, 
				CYCLE, 
				@pnUserIdentityId
			from	@tbPolicing
		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ip_PoliceRelatedCase to public
GO

