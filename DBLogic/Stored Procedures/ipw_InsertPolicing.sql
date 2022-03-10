-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertPolicing
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertPolicing]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertPolicing.'
	Drop procedure [dbo].[ipw_InsertPolicing]
	Print '**** Creating Stored Procedure dbo.ipw_InsertPolicing...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE procedure dbo.ipw_InsertPolicing
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pnTypeOfRequest		tinyint,	-- Mandatory		
	@pnPolicingBatchNo		int		= null,
	@pbSysGeneratedFlag		bit		= 1, 
	@pnCaseKey			int		= null, 
	@psAction			nvarchar(2)	= null, 
	@pnEventKey			int		= null,
	@pnCycle			smallint	= null,
	@pnCriteriaNo			int		= null,
	@pnCountryFlags			int		= null,
	@pbFlagSetOn			bit		= null,
	@pnAdHocNameNo			int		= null,
	@pdtAdHocDateCreated		datetime	= null,
	@pbOnHold			bit		= null	-- When not null, indicates that the policing request is to be placed on hold. If null, the On Hold status is determined from the @pnPolicingBatchNo.
)
as 
-- PROCEDURE :	ipw_InsertPolicing
-- VERSION :	8
-- DESCRIPTION:	Add a request to the policing queue.
--
-- VALID PARAMETERS:
-- @pnTypeOfRequest 
-- 	0 - police by name
--	1 - open an action
--	2 - police due event
--	3 - police occured event
--	4 - recalculate action
--	5 - police country flags
--	6 - recalculate due dates
--
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 07 Oct 2004	TM	RFC1327	1	Procedure created
-- 11 Oct 2004 	TM	RFC1327	2	Correct the comments and remove unnecessary settings.
-- 29 Oct 2004	TM	RFC1322	3	Add a new optional @pbPolicingOnHold flag.
-- 10 Jan 2006	TM	RFC3275	4	Use SYSTEM_USER for SQLUSER column rather than the USER constant
-- 11 Nov 2008	SF	RFC3392 5	Increase field length for @psAction
-- 12 Nov 2008	SF	RFC3392	6	Backout field length change
-- 4 Dec 2008	SF	RFC3392	7	Fix incorrect RFC number
-- 12 Apr 2012	KR	R12055	8	On Hold flag should be set to 1 when there is a batch no

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

	
Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(4000)

Declare @dtDateEntered 	datetime
Declare @nPolicingSeq 	int
Declare @sPolicingName 	nvarchar(40)

	
-- Initialise variables
Set @nErrorCode = 0

-- Generate key
If @nErrorCode = 0
Begin
	Set @dtDateEntered = getdate()

	Set @sSQLString = "
	Select 	@nPolicingSeq = isnull(max(POLICINGSEQNO) + 1, 0)
	from	POLICING
	where 	DATEENTERED = @dtDateEntered"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nPolicingSeq		int		output,
					  @dtDateEntered	datetime',
					  @nPolicingSeq		= @nPolicingSeq	output,
					  @dtDateEntered	= @dtDateEntered	
End

-- Generate name
If @nErrorCode = 0
Begin
	Set @sPolicingName = dbo.fn_DateToString(@dtDateEntered,'CLEAN-DATETIME') + cast(@nPolicingSeq as varchar(10))

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Insert Into [POLICING]
		(	[DATEENTERED],
			[POLICINGSEQNO],
			[POLICINGNAME],	
			[SYSGENERATEDFLAG],
			[ONHOLDFLAG],
			[ACTION],
			[CASEID],
			[EVENTNO],
			[CYCLE],
			[CRITERIANO],
			[SQLUSER],
			[TYPEOFREQUEST],
			[COUNTRYFLAGS],
			[FLAGSETON],
			[BATCHNO],
			[IDENTITYID],
			[ADHOCNAMENO],
			[ADHOCDATECREATED]
		)
		Values	
		(	@dtDateEntered,
			isnull(@nPolicingSeq,0),
			@sPolicingName,
			@pbSysGeneratedFlag,
			CASE WHEN(@pnPolicingBatchNo is not null) THEN 1 ELSE isnull(@pbOnHold,0) END,
			@psAction, 
			@pnCaseKey,
			@pnEventKey,
			@pnCycle,
			@pnCriteriaNo,
			SYSTEM_USER,
			@pnTypeOfRequest,
			@pnCountryFlags,
			@pbFlagSetOn,
			@pnPolicingBatchNo,
			@pnUserIdentityId,
			@pnAdHocNameNo,
			@pdtAdHocDateCreated
		)"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@dtDateEntered	datetime,
					  @nPolicingSeq		int,
					  @sPolicingName	nvarchar(40),
					  @pbSysGeneratedFlag	bit,
					  @psAction		nvarchar(2),
					  @pnCaseKey		int,
					  @pnEventKey		int,
					  @pnCycle		smallint,
					  @pnCriteriaNo		int,
					  @pnTypeOfRequest	tinyint,
					  @pnCountryFlags	int,
					  @pbFlagSetOn		bit,
					  @pnPolicingBatchNo	int,
					  @pnUserIdentityId	int,
					  @pnAdHocNameNo	int,
					  @pdtAdHocDateCreated	datetime,
					  @pbOnHold		bit',					  
					  @dtDateEntered	= @dtDateEntered,
					  @nPolicingSeq		= @nPolicingSeq,
					  @sPolicingName	= @sPolicingName,
					  @pbSysGeneratedFlag	= @pbSysGeneratedFlag,
					  @psAction		= @psAction,
					  @pnCaseKey		= @pnCaseKey,
					  @pnEventKey		= @pnEventKey,
					  @pnCycle		= @pnCycle,
					  @pnCriteriaNo		= @pnCriteriaNo,
					  @pnTypeOfRequest	= @pnTypeOfRequest,
					  @pnCountryFlags	= @pnCountryFlags,
					  @pbFlagSetOn		= @pbFlagSetOn,
					  @pnPolicingBatchNo	= @pnPolicingBatchNo,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pnAdHocNameNo	= @pnAdHocNameNo,
				 	  @pdtAdHocDateCreated	= @pdtAdHocDateCreated ,
					  @pbOnHold		= @pbOnHold 					  
	
End	

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertPolicing to public
GO
