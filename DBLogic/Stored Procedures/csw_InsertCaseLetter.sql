-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertCaseLetter									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertCaseLetter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertCaseLetter.'
	Drop procedure [dbo].[csw_InsertCaseLetter]
End
Print '**** Creating Stored Procedure dbo.csw_InsertCaseLetter...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_InsertCaseLetter
(
	@pnUserIdentityId				int,		-- Mandatory
	@psCulture						nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnCaseKey						int,
	@psActionKey					nvarchar(2),
	@pnActionCycle					smallint,
	@pnEntryNumber					int,
	@pnLetterKey					int,
	@pnCoveringLetterKey			int	= null,
	@pnEnvelopeKey					int = null,
	@pbIsMandatory					bit = 0,
	@pnPolicingBatchNo				int = null
)
as
-- PROCEDURE:	csw_InsertCaseLetter
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Place a letter in the letter generation queue.  
--		This is called by the Cases work flow's Letter's step.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 12 Nov 2008	SF	RFC3392	1	Procedure created
-- 4 Dec 2008	SF	RFC3392	2	Fix incorrect RFC number
-- 16 Oct 2018	LP	DR-45009 3	Do not generate activity request for InproDocOnly PDF Forms

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode			int
Declare @dtToday			datetime
Declare @nDeliveryID			int
Declare @bOnHoldFlag			bit
Declare @bCanPrintIfPrimeOnly		bit
Declare @bCanGenerateLetter		bit
Declare @sSQLString			nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()

If @nErrorCode=0
Begin
	-- Check if the case can generate prime case only letters 
	-- (i.e. the case is either marked as prime on a case list or is not against any case list).
	Set @sSQLString = "
		Select @bCanPrintIfPrimeOnly = 
		case when exists (SELECT 1 FROM CASELISTMEMBER 
					WHERE CASEID = @pnCaseKey
					and PRIMECASE = 1)
			or not exists (Select 1
					from CASELISTMEMBER
					where CASEID = @pnCaseKey) 
		then 1 else 0 end"

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@bCanPrintIfPrimeOnly bit OUTPUT,
		@pnCaseKey	int',
		@pnCaseKey = @pnCaseKey,
		@bCanPrintIfPrimeOnly = @bCanPrintIfPrimeOnly output
End

If @nErrorCode=0
Begin
	-- Get other properties of the letter, e.g. on hold flag, delivery method, 
	-- and whether the letter can be generated
	Set @sSQLString = "
		Select @bCanGenerateLetter = 
				case 
					when L.USEDBY & 1024 = 1024 AND L.DOCUMENTTYPE = 2 then 0
					when L.FORPRIMECASESONLY = 1 AND @bCanPrintIfPrimeOnly = 1 then 1
					when L.FORPRIMECASESONLY <> 1 or L.FORPRIMECASESONLY IS NULL then 1					
					else 0
				end,
				@bOnHoldFlag = L.HOLDFLAG,
				@nDeliveryID = L.DELIVERYID
		from LETTER L
		where L.LETTERNO = @pnLetterKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
		N'@bCanGenerateLetter bit OUTPUT,
		@bOnHoldFlag bit OUTPUT,
		@nDeliveryID int OUTPUT,
		@bCanPrintIfPrimeOnly bit,
		@pnLetterKey int',		
		@bOnHoldFlag = @bOnHoldFlag output,
		@nDeliveryID = @nDeliveryID output,
		@bCanGenerateLetter = @bCanGenerateLetter output,
		@bCanPrintIfPrimeOnly = @bCanPrintIfPrimeOnly,
		@pnLetterKey = @pnLetterKey
End

If @nErrorCode=0
and @bCanGenerateLetter = 1
Begin
	-- place the document in the queue if it meets generation requirement.
	exec @nErrorCode = ip_InsertActivityRequest
				@pnUserIdentityId		= @pnUserIdentityId,
				@psCulture				= @psCulture,
				@psProgramID			= 'WorkBnch',
				@pnCaseKey				= @pnCaseKey,
				@pnActivityType			= 32,
				@pnActivityCode			= 3204,
				@psActionKey			= @psActionKey,
				@pnEventKey				= null,
				@pnCycle				= @pnActionCycle,
				@pnLetterKey			= @pnLetterKey,
				@pnCoveringLetterKey	= @pnCoveringLetterKey,
				@pbHoldFlag				= @bOnHoldFlag,
				@pdtLetterDate			= @dtToday,
				@pnDeliveryID			= @nDeliveryID
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertCaseLetter to public
GO