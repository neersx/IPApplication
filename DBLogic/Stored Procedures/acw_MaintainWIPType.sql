-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_MaintainWIPType 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_MaintainWIPType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_MaintainWIPType.'
	Drop procedure [dbo].[acw_MaintainWIPType]
End
Print '**** Creating Stored Procedure dbo.acw_MaintainWIPType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

-- Allow comparison of null values
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.acw_MaintainWIPType
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psOldWIPTypeCode	nvarchar(12)	= null,
	@psWIPTypeCode		nvarchar(12),	-- Mandatory	
	@psWIPTypeDescription	nvarchar(100)	= null,
	@psWIPCategoryCode	nvarchar(6),	-- Mandatory,
	@pnConsolidate		decimal(5,0)	= null,
	@pbAssociateDetails	bit		= null,
	@pnExchRateScheduleId	int		= null,
	@pnWriteDownPriority	int		= null,
	@pbWriteUpAllowed	bit		= null,
	@pnWIPSort		int		= null,
	@pdtLastModifiedDate	datetime	= null
)
as
-- PROCEDURE:	acw_MaintainWIPType
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert or Update WIP Type.  Used by the Web version.

-- MODIFICATIONS :
-- Date		Who	Number		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 28 Nov 2011	KR	R10454		1	Procedure created
-- 18 Jan 2011	AT	R10454		2	Fix WIPTYPESORT column reference


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	if @psOldWIPTypeCode is not null
	Begin
		Set @sSQLString = N'
		Update	WIPTYPE
		Set 
		WIPTYPEID =  @psWIPTypeCode,
		CATEGORYCODE = @psWIPCategoryCode,
		DESCRIPTION = @psWIPTypeDescription,
		CONSOLIDATE = @pnConsolidate,
		RECORDASSOCDETAILS = @pbAssociateDetails,
		EXCHSCHEDULEID = @pnExchRateScheduleId,
		WRITEDOWNPRIORITY = @pnWriteDownPriority,
		WRITEUPALLOWED = @pbWriteUpAllowed,
		WIPTYPESORT = @pnWIPSort
		where	WIPTYPEID = @psOldWIPTypeCode and
		(LOGDATETIMESTAMP is null or  LOGDATETIMESTAMP = @pdtLastModifiedDate)'
			
		exec @nErrorCode = sp_executesql @sSQLString,
		 				N'@psWIPTypeCode		nvarchar(12),
		 				@psOldWIPTypeCode		nvarchar(12),
		 				@psWIPCategoryCode		nvarchar(100),
		 				@psWIPTypeDescription		nvarchar(508),
		 				@pnConsolidate			decimal(5,0),
		 				@pbAssociateDetails		bit,
		 				@pnExchRateScheduleId		int,
		 				@pnWriteDownPriority		int,
		 				@pbWriteUpAllowed		bit,
		 				@pnWIPSort			int,
						@pdtLastModifiedDate		datetime',
						@psWIPTypeCode			= @psWIPTypeCode,
						@psOldWIPTypeCode		= @psOldWIPTypeCode,
		 				@psWIPCategoryCode		= @psWIPCategoryCode,
		 				@psWIPTypeDescription		= @psWIPTypeDescription,
		 				@pnConsolidate			= @pnConsolidate,
		 				@pbAssociateDetails		= @pbAssociateDetails,
		 				@pnExchRateScheduleId		= @pnExchRateScheduleId,
		 				@pnWriteDownPriority		= @pnWriteDownPriority,
		 				@pbWriteUpAllowed		= @pbWriteUpAllowed,
		 				@pnWIPSort			= @pnWIPSort,
						@pdtLastModifiedDate		= @pdtLastModifiedDate		
		
	End	
	Else
	Begin
						
		Set @sSQLString = "Insert into WIPTYPE
			(
			WIPTYPEID,
			CATEGORYCODE,
			DESCRIPTION,
			CONSOLIDATE,
			RECORDASSOCDETAILS,
			EXCHSCHEDULEID,
			WRITEDOWNPRIORITY,
			WRITEUPALLOWED,
			WIPTYPESORT
			)
			Values
			(
			@psWIPTypeCode,
			@psWIPCategoryCode,
			@psWIPTypeDescription,
			@pnConsolidate,
			@pbAssociateDetails,
			@pnExchRateScheduleId,
			@pnWriteDownPriority,
			@pbWriteUpAllowed,
			@pnWIPSort
			)"
			
		exec @nErrorCode = sp_executesql @sSQLString,
		 				N'@psWIPTypeCode		nvarchar(12),
		 				@psWIPCategoryCode		nvarchar(100),
		 				@psWIPTypeDescription		nvarchar(508),
		 				@pnConsolidate			decimal(5,0),
		 				@pbAssociateDetails		bit,
		 				@pnExchRateScheduleId		int,
		 				@pnWriteDownPriority		int,
		 				@pbWriteUpAllowed		bit,
		 				@pnWIPSort			int',
						@psWIPTypeCode			= @psWIPTypeCode,
		 				@psWIPCategoryCode		= @psWIPCategoryCode,
		 				@psWIPTypeDescription		= @psWIPTypeDescription,
		 				@pnConsolidate			= @pnConsolidate,
		 				@pbAssociateDetails		= @pbAssociateDetails,
		 				@pnExchRateScheduleId		= @pnExchRateScheduleId,
		 				@pnWriteDownPriority		= @pnWriteDownPriority,
		 				@pbWriteUpAllowed		= @pbWriteUpAllowed,
		 				@pnWIPSort			= @pnWIPSort
	End
	
End

Return @nErrorCode
GO

Grant execute on dbo.acw_MaintainWIPType to public
GO
