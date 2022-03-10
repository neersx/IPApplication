-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_MaintainCaseDetail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_MaintainCaseDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_MaintainCaseDetail.'
	Drop procedure [dbo].[csw_MaintainCaseDetail]
End
Print '**** Creating Stored Procedure dbo.csw_MaintainCaseDetail...'
Print ''
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.

CREATE PROCEDURE dbo.csw_MaintainCaseDetail
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,
        @pnEntryNumber		int,
        @psOfficialNumber	nvarchar(36)    = null,
        @psNumberTypeKey	nvarchar(3)        = null,
        @pnFileLocationKey	int             = null,
	@psOldOfficialNumber    nvarchar(36)    = null,
	@pnOldFileLocationKey   int             = null
)
as
-- PROCEDURE:	csw_MaintainCaseDetail
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Saves File Location, Official Number.  
--              This sp is called by the Cases Workflow.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 NOV 2008	SF	RFC3392		1	Procedure created
-- 15 SEP 2009  PS	RFC8092		2	Get the Related Event Date for a Case and NumberType, default the Officail Number Date Entered with the Related Event Date.
-- 04 Jan 2010	SF	RFC100067	3	Only insert Official Number if it is not null
-- 11 Mar 2011  MS	RFC8363         4       Remove InUse parameter for csw_InsertFileLocation 
-- 11 May 2016	MF	R61467		5	Removed "Set ANSI_NULLS OFF" which was outside of the creation of the stored procedure.  
--						This was allowing the @pnFileLocationKey with a NULL value to try an insert into CASELOCATION.
-- 13 May 2020	DL	DR-58943	6	Ability to enter up to 3 characters for Number type code via client server	

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @dtToday datetime
declare @dtDateEntered datetime
declare @bIsCurrent bit
declare @sSQLString nvarchar(4000)
declare @bUpdateCurrentOfficialNumber bit
declare @dtRelatedEventOccurredDate datetime
declare @pbIsExternalUser bit

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()
Set @dtRelatedEventOccurredDate = null



-- Get the IsExternal 
If @nErrorCode = 0
Begin
	If @pbIsExternalUser is null
	Begin		
		Set @sSQLString='
		Select @pbIsExternalUser=ISEXTERNALUSER
		from USERIDENTITY
		where IDENTITYID=@pnUserIdentityId'
	
		Exec  @nErrorCode=sp_executesql @sSQLString,
					N'@pbIsExternalUser	bit	OUTPUT,
					  @pnUserIdentityId	int',
					  @pbIsExternalUser	=@pbIsExternalUser	OUTPUT,
					  @pnUserIdentityId	=@pnUserIdentityId
	End
End



-- first insert file location if it has been changed.
-- @pnFileLocationKey will be ignored if it is NULL.
If  @nErrorCode = 0
and(@pnFileLocationKey <> @pnOldFileLocationKey
 OR(@pnFileLocationKey is not null and @pnOldFileLocationKey is null))
Begin
	exec @nErrorCode = csw_InsertFileLocation
			@pnUserIdentityId		= @pnUserIdentityId,		-- Mandatory
			@psCulture			= @psCulture,
			@pbCalledFromCentura	        = @pbCalledFromCentura,
			@pnCaseKey			= @pnCaseKey,		
			@pdtWhenMoved			= @dtToday,	
			@pnFileLocationKey		= @pnFileLocationKey
	
End


-- get the @dtRelatedEventOccurredDate for a case and numberType.
If @nErrorCode = 0
and @psNumberTypeKey is not null
Begin		
		Set @sSQLString='
		Select 	@dtRelatedEventOccurredDate = EVENTDATE  
			from dbo.fn_FilterUserNumberTypes(@pnUserIdentityId,@psCulture, @pbIsExternalUser,@pbCalledFromCentura) NT
			LEFT JOIN CASEEVENT CE on (NT.RELATEDEVENTNO = CE.EVENTNO and CE.CASEID = @pnCaseKey and CE.CYCLE =1) 
			where NUMBERTYPE = @psNumberTypeKey'
	
		Exec  @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int	,
					  @psCulture	nvarchar(10),
					  @pbIsExternalUser bit,
					  @pbCalledFromCentura bit,
					  @pnCaseKey int,
					  @psNumberTypeKey nvarchar(3),
					  @dtRelatedEventOccurredDate datetime OUTPUT',
					  @pnUserIdentityId	=@pnUserIdentityId	,
					  @psCulture	=@psCulture,
					  @pbIsExternalUser = @pbIsExternalUser,
					  @pbCalledFromCentura = @pbCalledFromCentura,
					  @pnCaseKey = @pnCaseKey,
					  @psNumberTypeKey = @psNumberTypeKey,
					  @dtRelatedEventOccurredDate  = @dtRelatedEventOccurredDate OUTPUT
End


-- update current official number if the number type exists
-- @psOfficialNumber cannot be null if @psOldOfficialNumber is not null.
If @nErrorCode = 0
and @psNumberTypeKey is not null
Begin
	
	-- insert a new one.
	-- if old official number does not exists 
	If @psOldOfficialNumber is null
	and @psOfficialNumber is not null
	Begin		
		exec @nErrorCode = csw_InsertOfficialNumber
			@pnUserIdentityId			= @pnUserIdentityId,
			@psCulture					= @psCulture,
			@pbCalledFromCentura		= @pbCalledFromCentura,
			@pnCaseKey					= @pnCaseKey,
			@psOfficialNumber			= @psOfficialNumber,
			@psNumberTypeCode			= @psNumberTypeKey,
			@pbIsCurrent				= 1,
			@pdtDateEntered				= @dtRelatedEventOccurredDate,
			@pbIsCurrentInUse			= 1,
			@pbIsDateEnteredInUse		= 1	

		If @nErrorCode = 0
		Begin
			Set @bUpdateCurrentOfficialNumber = 1
		End
	End
	Else
	-- if old one exists update it.
	If @psOldOfficialNumber is not null
	and @psOfficialNumber <> @psOldOfficialNumber
	Begin		

		-- collect some existing parameters from the database
		-- this is for data concurrency check
		Set @sSQLString = "
			Select
				@dtDateEntered = DATEENTERED,
				@bIsCurrent = ISCURRENT
			from OFFICIALNUMBERS 
			where CASEID = @pnCaseKey
			and NUMBERTYPE = @psNumberTypeKey
			and OFFICIALNUMBER = @psOldOfficialNumber
			"
		
		exec @nErrorCode = sp_executesql @sSQLString,
				      N'@dtDateEntered			datetime output,
						@bIsCurrent				bit output,
						@pnCaseKey				int,		
						@psNumberTypeKey		nvarchar(3) ,
						@psOldOfficialNumber		nvarchar(36)',
						@dtDateEntered			= @dtDateEntered output,
						@bIsCurrent				= @bIsCurrent output,
						@pnCaseKey				= @pnCaseKey,
						@psNumberTypeKey		= @psNumberTypeKey,
						@psOldOfficialNumber	= @psOldOfficialNumber

		If @nErrorCode = 0
		Begin
			
			-- call the existing csw_UpdateOfficialNumber to update the number
			exec @nErrorCode = csw_UpdateOfficialNumber
				@pnUserIdentityId			= @pnUserIdentityId,
				@psCulture					= @psCulture,
				@pbCalledFromCentura		= @pbCalledFromCentura,
				@pnCaseKey					= @pnCaseKey,
				@psOfficialNumber			= @psOfficialNumber,
				@psNumberTypeCode			= @psNumberTypeKey,
				@pbIsCurrent				= 1,
				@pdtDateEntered				= @dtRelatedEventOccurredDate,
				@psOldOfficialNumber		= @psOldOfficialNumber,		
				@psOldNumberTypeCode		= @psNumberTypeKey,		
				@pbOldIsCurrent				= @bIsCurrent,
				@pdtOldDateEntered			= @dtDateEntered,
				@pbIsOfficialNumberInUse	= 1,
				@pbIsNumberTypeCodeInUse	= 1,
				@pbIsCurrentInUse			= 1,
				@pbIsDateEnteredInUse		= 1


			If @nErrorCode = 0
			Begin
				Set @bUpdateCurrentOfficialNumber = 1
			End
		End
	End

	If @nErrorCode = 0
	and @bUpdateCurrentOfficialNumber = 1
	Begin
		exec @nErrorCode = csw_UpdateCurrentOfficialNumber
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pnCaseKey			= @pnCaseKey		
	End
End


Return @nErrorCode
GO

Grant execute on dbo.csw_MaintainCaseDetail to public
GO
