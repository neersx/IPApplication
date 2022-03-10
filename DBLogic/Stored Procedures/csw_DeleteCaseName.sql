-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteCaseName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteCaseName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteCaseName.'
	Drop procedure [dbo].[csw_DeleteCaseName]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteCaseName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_DeleteCaseName
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory
	@psNameTypeCode			nvarchar(3),	-- Mandatory	
	@pnSequence			smallint,	-- Mandatory
	@pnNameKey			int			=null,
	@pnPolicingBatchNo		int		= null,
	@pnOldAttentionNameKey		int		= null,
	@pnOldAddressKey		int		= null,
	@psOldReferenceNo		nvarchar(80)	= null,
	@pdtOldAssignmentDate		datetime	= null,
	@pdtOldDateCommenced		datetime	= null,
	@pdtOldDateCeased		datetime	= null,
	@pnOldBillPercent		decimal(5,2)	= null,
	@pbOldIsInherited		bit		= null,
	@pnOldInheritedNameKey		int		= null,
	@psOldInheritedRelationshipCode	nvarchar(3)	= null,
	@pnOldInheritedSequence		smallint	= null,
	@pnOldNameVariantKey		int		= null,
	@psOldRemarks			nvarchar(254)	= null,
	@pbOldCorrespSent		bit		= null,
	@pnOldCorrespReceived		int		= null,
	@pbIsAttentionNameKeyInUse	bit	 	= 0,
	@pbIsAddressKeyInUse		bit	 	= 0,
	@pbIsReferenceNoInUse		bit	 	= 0,
	@pbIsAssignmentDateInUse	bit		= 0,
	@pbIsDateCommencedInUse		bit	 	= 0,
	@pbIsDateCeasedInUse		bit	 	= 0,
	@pbIsBillPercentInUse		bit	 	= 0,
	@pbIsIsInheritedInUse		bit	 	= 0,
	@pbIsInheritedNameKeyInUse	bit	 	= 0,
	@pbIsInheritedRelationshipCodeInUse bit	 	= 0,
	@pbIsInheritedSequenceInUse	bit	 	= 0,
	@pbIsNameVariantKeyInUse	bit	 	= 0,
	@pbIsRemarksInUse		bit		= 0,
	@pbIsCorrespSentInUse		bit		= 0,
	@pbIsCorrespReceivedInUse	bit		= 0,
	@pdtLastModifiedDate		datetime = null
)
as
-- PROCEDURE:	csw_DeleteCaseName
-- VERSION:	9
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete CaseName if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 16 Nov 2005	TM	RFC3202	1	Procedure created
-- 03 May 2006	SW	RFC3202 2	Implement new properties 
-- 06 Jun 2006	IB	RFC3299 3	Handle derived attention 
-- 18 Jul 2008	AT	RFC5749	4	Added remarks concurrency
-- 29 Aug 2008	AT	RFC5712	5	Added Correspondence Sent/Received
-- 01 Aug 2011	MF	RFC11051 6	A change of Name for a given NameType may also impact on the standing instructions for 
--					the Case. Call the procedure ip_RecalculateInstructionType to trigger an CaseEvent recalculations.
-- 05 Sep 2011	LP	R11252	7	Pass PolicingBatchNo as a parameter when calling ip_RecalculateInstructionType.
-- 07 Mar 2013	AK	E100782	8	If CaseName is inherited ignore NAMENO check
-- 05 Aug 2013  AK  R13707  9   Added parameter @pdtLastModifiedDate and removed unwanted checks from where clause  

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount  = 0
Set @sAnd = " and "

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from CASENAME
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		CASEID = @pnCaseKey and
		NAMETYPE = @psNameTypeCode and
		(LOGDATETIMESTAMP = @pdtLastModifiedDate or @pdtLastModifiedDate is null) and 
		SEQUENCE = @pnSequence "
			
	exec @nErrorCode=sp_executesql @sDeleteString,
		    N'@pnCaseKey		int,
			@psNameTypeCode		nvarchar(3),
			@pdtLastModifiedDate datetime,			
			@pnSequence		smallint',
			@pnCaseKey	 	= @pnCaseKey,
			@psNameTypeCode	 	= @psNameTypeCode,
			@pdtLastModifiedDate =@pdtLastModifiedDate,			
			@pnSequence	 	= @pnSequence			
	Set @nRowCount=@@Rowcount
End

---------------------------------------------
-- RFC11051
-- If the CASENAME has been deleted then
-- check for changes to Standing Instructions
---------------------------------------------
If  @nRowCount>0
and @nErrorCode=0
Begin
	-----------------------------------------
	-- If the Name Type deleted is referenced
	-- by any Instruction Type then call a 
	-- procedure to generate any CaseEvent
	-- Policing recalculations.
	-----------------------------------------
	If exists (select 1 from INSTRUCTIONTYPE where NAMETYPE=@psNameTypeCode OR RESTRICTEDBYTYPE=@psNameTypeCode)
	Begin
		Exec @nErrorCode=dbo.ip_RecalculateInstructionType
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @psCulture,
					@pbCalledFromCentura	= 0,
					@psInstructionType 	= null, 
					@pnPolicingBatchNo 	= @pnPolicingBatchNo,
					@pnCaseKey 		= @pnCaseKey,
					@pnNameKey 		= null,
					@pnInternalSequence	= null,
					@pbExistingEventsOnly	= 0,
					@pbCountryNotChanged	= 0,
					@pbPropertyNotChanged	= 0,
					@pbNameNotChanged	= 0,
					@psNameTypeCode		= @psNameTypeCode
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteCaseName to public
GO

