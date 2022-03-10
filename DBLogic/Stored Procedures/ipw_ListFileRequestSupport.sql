---------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListFileRequestSupport 
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListFileRequestSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListFileRequestSupport.'
	drop procedure [dbo].[ipw_ListFileRequestSupport]
	Print '**** Creating Stored Procedure dbo.ipw_ListFileRequestSupport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListFileRequestSupport
(
	@pnRowCount		int		= null  output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnType                 int             = 0,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListFileRequestSupport
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Lists File Request Status, File Record Status, File Part Type and File Search Status

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 31 Mar 2011  MS	1	Procedure created
-- 26 Jun 2014  AK	2	Replaced 'File Record Status' to 'File Part Status'

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(500)
Declare @sLookupCulture		nvarchar(10)
Declare @sTableName             nvarchar(30)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0	




If @nErrorCode = 0 and @pnType = 0 -- File Request Status
Begin
        Set @sSQLString = "Select cast(T.USERCODE as int) as 'Key',"+char(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Description' 
		from TABLECODES T
		join TABLETYPE TT on (T.TABLETYPE = TT.TABLETYPE)   
		where TT.TABLENAME = 'File Request Status'		
                order by 1"
	
	exec @nErrorCode = sp_executesql @sSQLString,
	        N'@sTableName          nvarchar(30)',
	        @sTableName            = @sTableName
	
	Set @pnRowCount = @@Rowcount
End
Else If @nErrorCode = 0 and @pnType = 1 -- File Record Status
Begin

	Set @sSQLString = "Select T.TABLECODE as 'Key',"+char(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Description' 
		from TABLECODES T
		join TABLETYPE TT on (T.TABLETYPE = TT.TABLETYPE)   
		where TT.TABLENAME = 'File Part Status'
                order by 2"
	
	exec @nErrorCode = sp_executesql @sSQLString,
	        N'@pnType          int',
	        @pnType            = @pnType
	
	Set @pnRowCount = @@Rowcount
End	
Else If @nErrorCode = 0 and @pnType = 2 -- File Part Type
Begin

	Set @sSQLString = "Select T.TABLECODE as 'Key',"+char(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Description' 
		from TABLECODES T
		join TABLETYPE TT on (T.TABLETYPE = TT.TABLETYPE)   
		where TT.TABLENAME = 'File Part Type'
                order by 2"
	
	exec @nErrorCode = sp_executesql @sSQLString,
	        N'@pnType          int',
	        @pnType            = @pnType
	
	Set @pnRowCount = @@Rowcount
End
If @nErrorCode = 0 and @pnType = 3 -- File Part Search Status
Begin
        Set @sSQLString = "Select cast(T.USERCODE as int) as 'Key',"+char(10)+
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Description' 
		from TABLECODES T   
		where T.TABLETYPE = -507		
                order by 1"
	
	exec @nErrorCode = sp_executesql @sSQLString,
	        N'@sTableName          nvarchar(30)',
	        @sTableName            = @sTableName
	
	Set @pnRowCount = @@Rowcount
End	

Return @nErrorCode
GO

Grant exec on dbo.ipw_ListFileRequestSupport to public
GO
