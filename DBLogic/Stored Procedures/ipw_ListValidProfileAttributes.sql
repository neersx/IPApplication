-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListValidProfileAttributes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListValidProfileAttributes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListValidProfileAttributes.'
	Drop procedure [dbo].[ipw_ListValidProfileAttributes]
End
Print '**** Creating Stored Procedure dbo.ipw_ListValidProfileAttributes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListValidProfileAttributes
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pnAttributeKey		int,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListValidProfileAttributes
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return a list of valud attributes for the profile.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 15 Sep 2009	LP	RFC8047		1	Procedure created
-- 29 Jan 2010	LP	RFC100173	2	Increase size of string variables to cater for longer filters.
-- 27 Jam 2011	MF	RFC10190	3	The list of Importance Levels displayed should be shown in order of the value of the Importance Level.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(MAX)
declare @sTableName	nvarchar(200)
declare @sFilterValue	nvarchar(1000)
-- Initialise variables
Set @nErrorCode = 0

-- Retrieve table name
If @nErrorCode = 0
Begin
	Select @sTableName = TABLENAME,
	@sFilterValue = FILTERVALUE
	from ATTRIBUTES
	where ATTRIBUTEID = @pnAttributeKey
	
	Set @nErrorCode = @@ERROR
End

-- Return result set
If @nErrorCode = 0 
and @sTableName is not null
Begin
	Set @sSQLString = "Select "+  
	CASE @sTableName 
		WHEN 'IMPORTANCE' THEN "IMPORTANCELEVEL as PickListKey, IMPORTANCEDESC as PickListDescription"
		WHEN 'PROGRAM'    THEN "PROGRAMID as PickListKey, PROGRAMNAME as PickListDescription" 
	END
	+" from " +@sTableName
	
	If @sFilterValue is not null
	Begin
		Set @sSQLString = @sSQLString + " where " +@sFilterValue
	End

	Set @sSQLString=@sSQLString+" order by "+
	CASE @sTableName WHEN 'IMPORTANCE' THEN "PickListKey DESC" ELSE "PickListDescription ASC"  END
		
	exec @nErrorCode = sp_executesql @sSQLString			
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListValidProfileAttributes to public
GO
