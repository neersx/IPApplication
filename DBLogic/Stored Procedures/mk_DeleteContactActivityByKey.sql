-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[mk_DeleteContactActivityByKey ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.mk_DeleteContactActivityByKey .'
	Drop procedure [dbo].[mk_DeleteContactActivityByKey ]
End
Print '**** Creating Stored Procedure dbo.mk_DeleteContactActivityByKey ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.mk_DeleteContactActivityByKey 
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnActivityKey 		int,		-- Mandatory
	@pnActivityCheckSum 	int		-- Mandatory
)
-- PROCEDURE:	mk_DeleteContactActivityByKey 
-- VERSION:	3
-- SCOPE:	CPA.net
-- DESCRIPTION:	Delete the Activity row via the primary key, using a check sum for concurrency checking.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21 Jan 2005  TM	RFC1743	1	Procedure created. 
-- 22 Feb 2005	TM	RFC1319	2	Increase the size of the @sSQLString to nvarchar(4000)
-- 03 Mar 2005	TM	RFC2414	3	Set NOCOUNT OFF.

as

-- Row counts required by the data adapter
SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 			int
Declare @sSQLString  			nvarchar(4000)
Declare @sActivityChecksumColumns	nvarchar(4000)

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- Get the comma separated list of all comparable colums
	-- of the EmployeeRemider table
	exec @nErrorCode = dbo.ip_GetComparableColumns
				@psColumns 	= @sActivityChecksumColumns output, 
				@psTableName 	= 'ACTIVITY'
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Delete
	from   ACTIVITY 
	where  ACTIVITYNO = @pnActivityKey
	and    CHECKSUM("+@sActivityChecksumColumns+") = @pnActivityCheckSum"

	exec sp_executesql @sSQLString,
				N'@pnActivityKey	  int,
				  @pnActivityCheckSum	  int',
				  @pnActivityKey	  = @pnActivityKey,
				  @pnActivityCheckSum	  = @pnActivityCheckSum
End

Return @nErrorCode
GO

Grant execute on dbo.mk_DeleteContactActivityByKey  to public
GO

