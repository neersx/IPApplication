-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dm_ListMapSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dm_ListMapSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dm_ListMapSummary.'
	Drop procedure [dbo].[dm_ListMapSummary]
End
Print '**** Creating Stored Procedure dbo.dm_ListMapSummary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.dm_ListMapSummary
			@pnUserIdentityId	int,			-- Mandatory
			@psCulture		nvarchar(10)	= null,
			@pbCalledFromCentura	bit		= 0,	-- Indicates that Centura code is calling the procedure
			@pnEncodingSchemeKey	smallint	= null,	-- The key of the encoding scheme being mapped
			@pnSourceSystemKey	smallint	= null	-- Key of the system from which data may be received.
AS
-- PROCEDURE :	dm_ListMapSummary
-- VERSION:	3
-- DESCRIPTION:	Displays a summary list of the data structures and encoding schemes
--		that may need to be mapped.
--
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 07 Sep 2005	MF	11685	1	Procedure created
-- 14 Sep 2005	JEK	11685	2	Left join on encoding for @pnSourceSystemKey
-- 19 Sep 2005	JEK	11685	3	Join criteria missing for EncodingStructure.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode 	int
declare @sSQLString	nvarchar(4000)

Set @ErrorCode=0

If  @ErrorCode=0
Begin
	If @pnEncodingSchemeKey is not null
	Begin
		-- A list of all the structures that are mapped from the
		-- particular scheme are required.
		Set @sSQLString="
		Select	E.STRUCTUREID	as MAPSTRUCTUREID,
			M.STRUCTURENAME	as MAPSTRUCTURENAME,
			E.SCHEMEID	as ENCODINGSCHEMEID,
			ES.SCHEMENAME	as SCHEMENAME,
			null		as IGNOREUNMAPPED
		From ENCODINGSTRUCTURE E
		join ENCODINGSCHEME ES	on (ES.SCHEMEID=E.SCHEMEID)
		join MAPSTRUCTURE M	on (M.STRUCTUREID=E.STRUCTUREID)
		Where E.SCHEMEID=@pnEncodingSchemeKey
		order by 2"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnEncodingSchemeKey	smallint',
						  @pnEncodingSchemeKey=@pnEncodingSchemeKey
	End
	Else If @pnSourceSystemKey is not null
	Begin
		-- A list of all the structures that are applicable for a 
		-- particular data source are required.
		Set @sSQLString="
		Select	MS.STRUCTUREID		as MAPSTRUCTUREID,
			M.STRUCTURENAME		as MAPSTRUCTURENAME,
			MS.SCHEMEID		as ENCODINGSCHEMEID,
			ES.SCHEMENAME		as SCHEMENAME,
			MS.IGNOREUNMAPPED	as IGNOREUNMAPPED
		From MAPSCENARIO MS
		join MAPSTRUCTURE M 	 	on (M.STRUCTUREID=MS.STRUCTUREID)
		left join ENCODINGSTRUCTURE E 	on (E.SCHEMEID=MS.SCHEMEID
						and E.STRUCTUREID=M.STRUCTUREID)
		left join ENCODINGSCHEME ES	on (ES.SCHEMEID=E.SCHEMEID)
		Where MS.SYSTEMID=@pnSourceSystemKey
		order by 2"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnSourceSystemKey	smallint',
						  @pnSourceSystemKey=@pnSourceSystemKey
	End
	Else Begin
		-- A list of all the map-able structures is to be returned
		Set @sSQLString="
		Select	M.STRUCTUREID	as MAPSTRUCTUREID,
			M.STRUCTURENAME	as MAPSTRUCTURENAME,
			null		as ENCODINGSCHEMEID,
			null		as SCHEMENAME,
			null		as IGNOREUNMAPPED
		From MAPSTRUCTURE M 
		order by 2"
	
		exec @ErrorCode=sp_executesql @sSQLString
	End
End

RETURN @ErrorCode
go
grant execute on dbo.dm_ListMapSummary to public
go

