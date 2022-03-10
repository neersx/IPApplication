-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_GetLastInternalCode
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GetLastInternalCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_GetLastInternalCode.'
	Drop procedure [dbo].[ip_GetLastInternalCode]
	Print '**** Creating Stored Procedure dbo.ip_GetLastInternalCode...'
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

CREATE procedure dbo.ip_GetLastInternalCode
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null, 
	@psTable		nvarchar(30),	-- Mandatory
	@pnLastInternalCode	int		output,
	@pbCalledFromCentura	bit		= 0,
	@pbIsInternalCodeNegative	bit	= 0
)

-- PROCEDURE :	ip_GetLastInternalCode
-- VERSION :	7
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14/07/2002	JB			Function created
-- 17/02/2003	JEK	RFC51		Adjust to handle nulls.
-- 25/06/2008	Dw	16576	5	Re-write for C/S and to improve efficiency.
-- 19/03/2009	NG	R6921	6	Parameter added to allow negative internal code go backwards. 
-- 26 AUG 2011	MF	11211	7	Allocation of Batch No for Policing should reset the number based on existing Policing batches

AS

-- Declare working variables
Declare @nErrorCode		int
Declare @nRowCount		int
Declare @TranCountStart		int
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
	Select @TranCountStart = @@TranCount
	begin transaction
	
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

	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
	
	If @pbCalledFromCentura=1
		Select @pnLastInternalCode,@nErrorCode
End		

Return @nErrorCode
GO

grant execute on dbo.ip_GetLastInternalCode to public
GO
