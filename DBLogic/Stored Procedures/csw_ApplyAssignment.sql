-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ApplyAssignment
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ApplyAssignment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ApplyAssignment.'
	Drop procedure [dbo].[csw_ApplyAssignment]
End
Print '**** Creating Stored Procedure dbo.csw_ApplyAssignment...'
Print ''
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_ApplyAssignment
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnCaseKey			int,		-- Mandatory
	@pnRelationshipKey		int,		-- Mandatory
	@pdtAssignedDate		datetime	-- Mandatory
)
as
-- PROCEDURE:	csw_ApplyAssignment
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Apply Assignment in an assignment recordal case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 18 Aug 2011	KR	R7904	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT OFF
-- Reset so the next procedure gets the default
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @nNameKey	int
Declare	@nAddressKey	int
Declare	@nCaseKey	int
Declare @nSequence	int
Declare	@nRowsUpdated	int

-- Initialise variables
set @nErrorCode = 0


If @nErrorCode = 0
Begin
	-- Update Case Name that are owners but not new owners so that they become old owners.
	Set @sSQLString = "Update CN Set NAMETYPE = 'K', ASSIGNMENTDATE = @pdtAssignedDate
		From CASENAME CN
		Join RELATEDCASE R on (R.RELATEDCASEID = CN.CASEID and R.CASEID = @pnCaseKey 
					and R.RELATIONSHIPNO = @pnRelationshipKey)
		JOIN (Select CASEID, NAMENO,NAMETYPE, SEQUENCE from CASENAME CN1
			Where CN1.NAMETYPE = 'O'
			AND	NOT EXISTS ( 	SELECT	*
				FROM	CASENAME
				WHERE	NAMENO = CN1.NAMENO
				AND	CASEID = CN1.CASEID
				AND	NAMETYPE = 'ON') ) AS CN2 on (CN2.CASEID = @pnCaseKey and CN2.NAMETYPE = CN.NAMETYPE
								and CN2.NAMENO = CN.NAMENO )"
	exec @nErrorCode=sp_executesql @sSQLString,
	      	N'
	      	@pnCaseKey		int,
	      	@pnRelationshipKey	int,
		@pdtAssignedDate	datetime',
		@pnCaseKey		= @pnCaseKey,
		@pnRelationshipKey	= @pnRelationshipKey,
		@pdtAssignedDate	= @pdtAssignedDate
	Select @nRowsUpdated = @@Rowcount
End

If @nErrorCode = 0
Begin
	-- Update Case Names that are onwers and new owners 
		Set @sSQLString = "Update CN Set ADDRESSCODE = CN2.ADDRESSCODE, ASSIGNMENTDATE = @pdtAssignedDate
		From CASENAME CN
		Join RELATEDCASE R on (R.RELATEDCASEID = CN.CASEID and R.CASEID = @pnCaseKey 
					and R.RELATIONSHIPNO = 1)
		JOIN (Select CASEID, NAMENO,NAMETYPE, SEQUENCE, ADDRESSCODE from CASENAME CN1
			Where CN1.NAMETYPE = 'ON'
			AND	EXISTS ( 	SELECT	*
				FROM	CASENAME CN3
				WHERE	CN3.NAMENO = CN1.NAMENO
				AND	CN3.CASEID = CN1.CASEID
				AND	CN3.NAMETYPE = 'O') ) AS CN2 on (CN2.CASEID = @pnCaseKey 
								and CN2.NAMENO = CN.NAMENO )
		where		CN.NAMETYPE = 'O'"
	exec @nErrorCode=sp_executesql @sSQLString,
	      	N'
	      	@pnCaseKey		int,
	      	@pnRelationshipKey	int,
		@pdtAssignedDate	datetime',
		@pnCaseKey		= @pnCaseKey,
		@pnRelationshipKey	= @pnRelationshipKey,
		@pdtAssignedDate	= @pdtAssignedDate
End

If @nErrorCode = 0 and @nRowsUpdated > 0
Begin

	Select @nSequence = isnull(max(SEQUENCE)+ 1,0)
		from CASENAME CN
		Join RELATEDCASE R on (R.CASEID = @pnCaseKey 
				and R.RELATIONSHIPNO = @pnRelationshipKey 
				and R.RELATEDCASEID = CN.CASEID)
		Where CN.NAMETYPE = 'O'
		
		Select distinct @nCaseKey =  R.RELATEDCASEID 
		from CASENAME CN
		Join RELATEDCASE R on (R.CASEID = @pnCaseKey 
				and R.RELATIONSHIPNO = @pnRelationshipKey 
				and R.RELATEDCASEID = CN.CASEID)
	
	
	DECLARE casename_cursor CURSOR FOR 
	SELECT NAMENO, ADDRESSCODE from CASENAME CN
	Where	CN.CASEID = @pnCaseKey
			AND	CN.NAMETYPE = 'ON'
			AND	NOT EXISTS ( 	SELECT	*
				FROM	CASENAME
				WHERE	NAMENO = CN.NAMENO
				AND	CASEID = CN.CASEID
				AND	NAMETYPE = 'O')
	OPEN casename_cursor;

	FETCH NEXT FROM casename_cursor
	Into @nNameKey, @nAddressKey
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		exec csw_InsertCaseName
		@pnUserIdentityId			= @pnUserIdentityId,
		@psCulture				= @psCulture,
		@pbCalledFromCentura			= 0,
		@pnCaseKey				= @nCaseKey,
		@psNameTypeCode				= 'O',
		@pnNameKey				= @nNameKey,
		@pnSequence				= @nSequence,
		@pnAttentionNameKey			= null,
		@pnAddressKey				= @nAddressKey,
		@psReferenceNo				= null,
		@pdtAssignmentDate			= @pdtAssignedDate,
		@pdtDateCommenced			= null,
		@pdtDateCeased				= null,
		@pnBillPercent				= null,
		@pbIsInherited				= null,
		@pnInheritedNameKey			= null,
		@psInheritedRelationshipCode		= null,
		@pnInheritedSequence			= null,
		@pnNameVariantKey			= null,
		@pnPolicingBatchNo 			= null,
		@psRemarks				= null,
		@pbCorrespSent				= null,
		@pnCorrespReceived			= null,
		@pbIsAttentionNameKeyInUse		= 0,
		@pbIsAddressKeyInUse			= 0,
		@pbIsReferenceNoInUse			= 0,
		@pbIsAssignmentDateInUse		= 1,
		@pbIsDateCommencedInUse			= 0,
		@pbIsDateCeasedInUse			= 0,
		@pbIsBillPercentInUse			= 0,
		@pbIsIsInheritedInUse			= 0,
		@pbIsInheritedNameKeyInUse		= 0,
		@pbIsInheritedRelationshipCodeInUse	= 0,
		@pbIsInheritedSequenceInUse		= 0,
		@pbIsNameVariantKeyInUse		= 0,
		@pbIsRemarksInUse			= 0,
		@pbIsCorrespSentInUse			= 0,
		@pbIsCorrespReceivedInUse		= 0
		
		FETCH NEXT FROM casename_cursor
		Into @nNameKey, @nAddressKey
	END
	CLOSE casename_cursor;
	DEALLOCATE casename_cursor;

End


Return @nErrorCode
GO

Grant execute on dbo.csw_ApplyAssignment to public
GO