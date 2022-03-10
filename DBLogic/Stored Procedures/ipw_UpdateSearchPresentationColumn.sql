-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateSearchPresentationColumn
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateSearchPresentationColumn]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateSearchPresentationColumn.'
	Drop procedure [dbo].[ipw_UpdateSearchPresentationColumn]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateSearchPresentationColumn...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_UpdateSearchPresentationColumn
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,			
	@pbCalledFromCentura		bit		= 0,
	@pnColumnID					int,	-- Mandatory
	@pnQueryContext				int,	-- Mandatory
	@psColumnLabel				nvarchar(50),	-- Mandatory
	@pnDataItemID				int,	-- Mandatory
	@psColumnDescription		nvarchar(254) = null,
	@pnGroupID					int = null,
	@psQualifier				nvarchar(20) = null,
	@pnDocItemID				int = null,
	@pbIsVisible				bit = 0,
	@pdtLastUpdatedDate			datetime = null
)
as
-- PROCEDURE:	ipw_UpdateSearchPresentationColumn
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to insert or update Currency
-- MODIFICATIONS :
-- Date			Who		Number	Version		Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Oct 2010  DV		RFC9437		1	Procedure created
-- 06 Dec 2010  DV              RFC100440       2       Fixed issue where the column were not getting updated when IsVisible was set.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(1000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin
	If not exists (Select 1 from QUERYCOLUMN 
			   where COLUMNID = @pnColumnID and (LOGDATETIMESTAMP = @pdtLastUpdatedDate or @pdtLastUpdatedDate is null))
	Begin		
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Concurrency violation: The Update command affected 0 records.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin	
		Set @sSQLString = "
				Update  QUERYCOLUMN
				Set COLUMNLABEL = @psColumnLabel,
				DESCRIPTION = @psColumnDescription,
				DATAITEMID = @pnDataItemID,
				DOCITEMID = @pnDocItemID,
				QUALIFIER = @psQualifier
				where COLUMNID = @pnColumnID
				and (LOGDATETIMESTAMP = @pdtLastUpdatedDate
				or @pdtLastUpdatedDate is null)"		
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnColumnID		    int,
					@psColumnLabel			nvarchar(50),
					@psColumnDescription	nvarchar(254),
					@pnDataItemID			int, 
					@pnDocItemID			int,
					@psQualifier			nvarchar(20),
					@pdtLastUpdatedDate		datetime',					
					@pnColumnID	 			= @pnColumnID,
					@psColumnLabel	 		= @psColumnLabel,
					@psColumnDescription	= @psColumnDescription,
					@pnDataItemID	 		= @pnDataItemID,
					@pnDocItemID	 		= @pnDocItemID,
					@psQualifier			= @psQualifier,
					@pdtLastUpdatedDate     = @pdtLastUpdatedDate
		if	(@nErrorCode = 0 and (@pbIsVisible = 1 or @pnGroupID is not null))
		Begin
			If not exists (Select 1 from QUERYCONTEXTCOLUMN 
			   where COLUMNID = @pnColumnID and CONTEXTID = @pnQueryContext)
			Begin	
				Set @sSQLString = "
							INSERT into QUERYCONTEXTCOLUMN (CONTEXTID, COLUMNID, GROUPID, ISMANDATORY, ISSORTONLY)
					values (@pnQueryContext,@pnColumnID, @pnGroupID,0,0)"
					
			End
			Else
			Begin
				Set @sSQLString = "
							UPDATE QUERYCONTEXTCOLUMN 
								Set GROUPID = @pnGroupID
									WHERE COLUMNID = @pnColumnID and
									CONTEXTID = @pnQueryContext"
			End			
		End
		else if	(@nErrorCode = 0 and (@pbIsVisible is null or @pbIsVisible = 0 or @pnGroupID is null))
		Begin			
			Set @sSQLString = "
							DELETE FROM  QUERYCONTEXTCOLUMN 								
									WHERE COLUMNID = @pnColumnID and
									CONTEXTID = @pnQueryContext"
		End
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnQueryContext		int,
						@pnColumnID				int, 
						@pnGroupID				int',					
						@pnQueryContext	 		= @pnQueryContext,
						@pnColumnID	 			= @pnColumnID,
						@pnGroupID	 			= @pnGroupID
	End

End

if (@nErrorCode = 0)
Begin
	Select @pnColumnID as 'ColumnID',
	LOGDATETIMESTAMP as 'LogDateTimeStamp'
	from QUERYCOLUMN 
	WHERE COLUMNID = @pnColumnID
End

Return @nErrorCode
go

Grant exec on dbo.ipw_UpdateSearchPresentationColumn to Public
go