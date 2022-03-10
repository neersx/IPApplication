-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dm_ListImplementationValues
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dm_ListImplementationValues]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dm_ListImplementationValues.'
	Drop procedure [dbo].[dm_ListImplementationValues]
End
Print '**** Creating Stored Procedure dbo.dm_ListImplementationValues...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.dm_ListImplementationValues
			@pnUserIdentityId	int,			-- Mandatory
			@psCulture		nvarchar(10)	= null,
			@pbCalledFromCentura	bit		= 0,	-- Indicates that Centura code is calling the procedure
			@pnMapStructureKey	smallint		-- Mandatory key of structure being mapped
AS
-- PROCEDURE :	dm_ListImplementationValues
-- VERSION:	2
-- DESCRIPTION:	Return a list of the valid values for a particular mapped structure.
--		Intended to be used to populate a drop down list.
--
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 07 Sep 2005	MF	11685	1	Procedure created
-- 28 Jul 2016	MF	64838	2	The Data Mapping program in client/server calls this procedure for all structures to be mapped 
--					when the Details button is pressed which opens the Data Mapping - Maintenance screen.  When the 
--					structure to be mapped is "Events", the results are actually discard and the Event picklist is used.
--					On databases with a very large number of events performance is impacted by the call to this procedure
--					even though the results are not used. This can be solved by not returning a result if the table
--					is EVENTS and the procedure is called from Centura.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode 	int
declare @sDerivedTable	nvarchar(4000)
declare @sSQLString	nvarchar(4000)

Set @ErrorCode=0

If @ErrorCode=0
Begin
	Set @sSQLString='
	select @sDerivedTable=dbo.fn_SqlSelectList(	@pnUserIdentityId,
							@psCulture,
							@pbCalledFromCentura,
							MS.TABLENAME,
							MS.KEYCOLUMNAME,
							MS.CODECOLUMNNAME,
							MS.DESCCOLUMNNAME)
	from MAPSTRUCTURE MS
	where MS.STRUCTUREID=@pnMapStructureKey
	and (MS.TABLENAME<>''EVENTS'' OR @pbCalledFromCentura=0)'	-- RFC64838

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sDerivedTable	nvarchar(4000)	output,
					  @pnUserIdentityId	int,
					  @psCulture		nvarchar(10),
					  @pbCalledFromCentura	bit,
					  @pnMapStructureKey	smallint',
					  @sDerivedTable=@sDerivedTable	OUTPUT,
					  @pnUserIdentityId=@pnUserIdentityId,
					  @psCulture=@psCulture,
					  @pbCalledFromCentura=@pbCalledFromCentura,
					  @pnMapStructureKey=@pnMapStructureKey
End

If @sDerivedTable is not null
and @ErrorCode=0
Begin
	Set @sSQLString='
	Select X.KEYVALUE, X.DESCRIPTION
	From ('+@sDerivedTable+') X 
	order by X.DESCRIPTION'

	exec @ErrorCode=sp_executesql @sSQLString
End

RETURN @ErrorCode
go
grant execute on dbo.dm_ListImplementationValues to public
go

