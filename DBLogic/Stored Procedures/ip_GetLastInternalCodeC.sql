-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_GetLastInternalCodeC
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GetLastInternalCodeC]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_GetLastInternalCodeC.'
	Drop procedure [dbo].[ip_GetLastInternalCodeC]
	Print '**** Creating Stored Procedure dbo.ip_GetLastInternalCodeC...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
SET CONCAT_NULL_YIELDS_NULL OFF
GO
SET NOCOUNT OFF
GO

CREATE procedure dbo.ip_GetLastInternalCodeC
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null, 
	@psTable		nvarchar(30),	-- Mandatory
	@pnLastInternalCode	int		output,
	@pbCalledFromCentura	bit		= 1,
	@pbIsInternalCodeNegative	bit	= 0
)

-- PROCEDURE :	ip_GetLastInternalCodeC
-- VERSION :	2
-- DESCRIPTION:	Version of ip_GetLastInternalCode for Centura.
-- 		The main difference between this version and the one used by workbenches
--		is that this stored procedure does not use the 'begin transaction' syntax.
--		Please refer to SQA17528 for details.
	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06/04/2008	DW	17528	1	Function created for use by Centura.
-- 26 AUG 2011	MF	11211	2	Allocation of Batch No for Policing should reset the number based on existing Policing batches


AS

-- Declare working variables
Declare @nErrorCode		int
Declare @nRowCount		int
Declare	@sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode	= 0
Set @nRowCount	= 0

-- -------------------------
-- Minimum data
If @psTable is null or @psTable = ''
	Set @nErrorCode=-1

-- -------------------------

If @nErrorCode = 0
Begin	
	If @psTable in ('POLICING', 'POLICINGBATCH')
	Begin
		Set @sSQLString = "
			update LASTINTERNALCODE
			set 	INTERNALSEQUENCE    = isnull(P.BATCHNO + 1, 1),
				@pnLastInternalCode = isnull(P.BATCHNO + 1, 1)
			from	LASTINTERNALCODE
			cross join (select max(isnull(BATCHNO,0)) as BATCHNO
				    from POLICING with(NOLOCK)) P	
			where TABLENAME = @psTable"
	End
	Else If @pbIsInternalCodeNegative = 0
	Begin
		Set @sSQLString = "
			update LASTINTERNALCODE
			set 	INTERNALSEQUENCE = isnull(INTERNALSEQUENCE + 1, 1),
				@pnLastInternalCode = isnull(INTERNALSEQUENCE + 1, 1)
			from	LASTINTERNALCODE		
			where TABLENAME = @psTable"
	End
	
	Else If @pbIsInternalCodeNegative = 1
	Begin
		Set @sSQLString = "
			update LASTINTERNALCODE
			set 	INTERNALSEQUENCE = isnull(INTERNALSEQUENCE - 1, -1),
				@pnLastInternalCode = isnull(INTERNALSEQUENCE - 1, -1)
			from	LASTINTERNALCODE		
			where TABLENAME = @psTable"
	End

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@psTable nvarchar(18),
			@pnLastInternalCode	int OUTPUT',
			@psTable= @psTable,
			@pnLastInternalCode= @pnLastInternalCode OUTPUT

	-- Get rowcount
	set @nRowCount = @@rowcount

	-- insert row if not already listed in the table
	if @nRowCount = 0
	and @nErrorCode=0
	Begin
        	Set @sSQLString = "
		Insert into [LASTINTERNALCODE]
			(	[TABLENAME],
				[INTERNALSEQUENCE]
			)
			Values
			(	@psTable,
				1
			)"

        	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psTable nvarchar(18)',
					@psTable= @psTable

		Set @pnLastInternalCode = 1

	End

	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
	
	
	If @pbCalledFromCentura=1
		Select @pnLastInternalCode,@nErrorCode
End		

Return @nErrorCode
GO

grant execute on dbo.ip_GetLastInternalCodeC to public
GO
