-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GenerateGlobalNameChangeSearch
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_InsertGlobalNameChangeSearch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertGlobalNameChangeSearch.'
	Drop procedure [dbo].[csw_InsertGlobalNameChangeSearch]
End
Print '**** Creating Stored Procedure dbo.csw_InsertGlobalNameChangeSearch...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[csw_InsertGlobalNameChangeSearch]
(	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,		
	@ptXMLFilterCriteria		ntext,		-- Mandatory	Changed Cases List as XML		
	@pnQueryKey			int		= null output,	-- Query Key of Global Name Change Search
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	csw_GenerateGlobalNameChangeSearch
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Save the Global Name Change Search containing the updated cases into the database

-- MODIFICATIONS :
-- Date		Who  Change	Version	  Description
-- -----------	---- -------	--------  ------------------------------------------------------ 
-- 18 NOV 2008	MS   RFC5698	1	  Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sCurrentDate		nvarchar(30)	
Declare @nGroupKey		int						
Declare @nQueryContextKey	int						
Declare @nFilterKey		int	-- Filter ID from QUERYFILTER table
Declare @nFilterKeyToBeDeleted  int

-- Initialise variables
Set @nErrorCode 	= 0
-- Returns current date in format "dd mmm yyyy hh:mm:ss"
Set @sCurrentDate = CONVERT(varchar, GETDATE(), 6)+ ' ' + CONVERT(varchar, GETDATE(), 8)
Set @nQueryContextKey = 2  -- Query Context Key (Cases)
Set @nGroupKey = -2	   -- Query Group Key (Recent Global Name Changes)

If  @nErrorCode = 0
Begin
	--------------------------------
	-- Save the Global Name Cases Search 
	-- Add filter criteria if necessary
	--------------------------------	
	If @nErrorCode = 0
	and @ptXMLFilterCriteria is not null
	Begin
		exec @nErrorCode = qr_MaintainFilter
			@pnFilterKey		= @nFilterKey	output,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnContextKey		= @nQueryContextKey,			
			@ptXMLFilterCriteria	= @ptXMLFilterCriteria
	End

	-- Add QUERY
	If @nErrorCode = 0
	Begin
			Set @sSQLString = " 
			insert	QUERY
				(CONTEXTID,
				IDENTITYID,
				QUERYNAME,
				DESCRIPTION,				
				FILTERID,
				GROUPID,
				ISPROTECTED
				)
			values	(@nQueryContextKey,
				null,
				'Global Name Changes ' + @sCurrentDate,
				'Results of Global Name Change',
				@nFilterKey,				
				@nGroupKey,
				1
				)

				Set @pnQueryKey = SCOPE_IDENTITY()"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnQueryKey		int OUTPUT,							
					@sCurrentDate		nvarchar(30),								
					@nQueryContextKey	int,								
					@nFilterKey		int,							
					@nGroupKey		int',							
					@pnQueryKey		= @pnQueryKey	OUTPUT,							
					@sCurrentDate		= @sCurrentDate,								
					@nQueryContextKey	= @nQueryContextKey,								
					@nFilterKey		= @nFilterKey,								
					@nGroupKey		= @nGroupKey								

	End
	
End


If  @nErrorCode = 0
Begin
	--------------------------------
	-- Delete the Saved Searches if there count is greater than 3
	--------------------------------
	If (Select count(*) from QUERY where GROUPID = @nGroupKey) > 3
	Begin
		
		Set @sSQLString = "Select @nFilterKeyToBeDeleted = FILTERID from "+ CHAR(10)+ 
				"QUERY where QUERYID in"+ CHAR(10)+					
				" (Select min(QUERYID)"+ CHAR(10)+
				"from QUERY where GROUPID=@nGroupKey)"

		Exec @nErrorCode = sp_executesql @sSQLString,
				N'@nFilterKeyToBeDeleted int output,
				@nGroupKey	int',
				@nFilterKeyToBeDeleted = @nFilterKeyToBeDeleted output,
				@nGroupKey	= @nGroupKey

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "Delete from QUERY" + CHAR(10)+
				" where QUERYID in"+ CHAR(10)+
				" (Select min(QUERYID)"+ CHAR(10)+
				"from QUERY where GROUPID=@nGroupKey)"

			Exec @nErrorCode = sp_executesql @sSQLString,
				N'@nGroupKey	int',
				@nGroupKey	= @nGroupKey
		End
		
		If @nErrorCode = 0
		Begin			
			Set @sSQLString = "Delete from QUERYFILTER" + CHAR(10)+
				" where FILTERID = @nFilterKeyToBeDeleted"
	
			Exec @nErrorCode = sp_executesql @sSQLString,
				N'@nFilterKeyToBeDeleted int',
				@nFilterKeyToBeDeleted = @nFilterKeyToBeDeleted
		End
	END
End

Return @nErrorCode
GO

Grant execute on dbo.csw_InsertGlobalNameChangeSearch to public
GO