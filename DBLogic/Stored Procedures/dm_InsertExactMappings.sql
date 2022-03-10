-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dm_InsertExactMappings
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dm_InsertExactMappings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dm_InsertExactMappings.'
	Drop procedure [dbo].[dm_InsertExactMappings]
End
Print '**** Creating Stored Procedure dbo.dm_InsertExactMappings...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.dm_InsertExactMappings
			@pnUserIdentityId	int,		-- Mandatory
			@pbCalledFromCentura	bit	= 0,	-- Indicates that Centura code is calling the procedure
			@pnFromSchemeKey	smallint,	-- Mandatory key of predefined encoding scheme for input values.
			@pnMapStructureKey	smallint	-- Mandatory key of structure being mapped
AS
-- PROCEDURE :	dm_InsertExactMappings
-- VERSION:	1
-- DESCRIPTION:	Relates information in an external system to the corresponding values
--		implemented in this system.  This procedure uses a predefined encoding
--		scheme to automatically insert any implementation values that are the same
--		as the encoded values.
--
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 06 Sep 2005	MF	11685	1	Procedure created

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
							default,	-- note translation not required
							@pbCalledFromCentura,
							MS.TABLENAME,
							MS.KEYCOLUMNAME,
							MS.CODECOLUMNNAME,
							MS.DESCCOLUMNNAME)
	from MAPSTRUCTURE MS
	where MS.STRUCTUREID=@pnMapStructureKey'

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sDerivedTable	nvarchar(4000)	output,
					  @pnUserIdentityId	int,
					  @pbCalledFromCentura	bit,
					  @pnMapStructureKey	smallint',
					  @sDerivedTable=@sDerivedTable	OUTPUT,
					  @pnUserIdentityId=@pnUserIdentityId,
					  @pbCalledFromCentura=@pbCalledFromCentura,
					  @pnMapStructureKey=@pnMapStructureKey
End

If @sDerivedTable is not null
and @ErrorCode=0
Begin
	-- Match Codes first
	Set @sSQLString='
	Insert into MAPPING (STRUCTUREID, INPUTCODEID, OUTPUTVALUE)
	Select @pnMapStructureKey, E.CODEID, X.KEYVALUE
	From ENCODEDVALUE E'+char(10)+char(9)+
	'join ('+@sDerivedTable+') X on (upper(X.CODE)=E.CODE)
	-- Check that the row being inserted does not already exist
	left join MAPPING M 	on (M.STRUCTUREID=@pnMapStructureKey
				and M.DATASOURCEID is null
				and M.INPUTCODE is null
				and M.INPUTDESCRIPTION is null
				and M.INPUTCODEID=E.CODEID)
	where 	E.SCHEMEID=@pnFromSchemeKey
	and	E.STRUCTUREID=@pnMapStructureKey
	and 	M.ENTRYID is null'

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnMapStructureKey	smallint,
					  @pnFromSchemeKey	smallint',
					  @pnMapStructureKey=@pnMapStructureKey,
					  @pnFromSchemeKey  =@pnFromSchemeKey

	-- Now try descriptions
	If @ErrorCode=0
	Begin
		Set @sSQLString='
		Insert into MAPPING (STRUCTUREID, INPUTCODEID, OUTPUTVALUE)
		Select @pnMapStructureKey, E.CODEID, X.KEYVALUE
		From ENCODEDVALUE E'+char(10)+char(9)+
		'join ('+@sDerivedTable+') X on (upper(X.DESCRIPTION)=E.DESCRIPTION)
		-- Check that the row being inserted does not already exist
		left join MAPPING M 	on (M.STRUCTUREID=@pnMapStructureKey
					and M.DATASOURCEID is null
					and M.INPUTCODE is null
					and M.INPUTDESCRIPTION is null
					and M.INPUTCODEID=E.CODEID)
		-- Check that the description only appears once.
		left join ('+@sDerivedTable+') X2 
					on (upper(X2.DESCRIPTION)=upper(X.DESCRIPTION)
					and X2.KEYVALUE<>X.KEYVALUE)
		where 	E.SCHEMEID=@pnFromSchemeKey
		and	E.STRUCTUREID=@pnMapStructureKey
		and 	M.ENTRYID is null
		and	X2.KEYVALUE is null'
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnMapStructureKey	smallint,
						  @pnFromSchemeKey	smallint',
						  @pnMapStructureKey=@pnMapStructureKey,
						  @pnFromSchemeKey  =@pnFromSchemeKey
	End
End


RETURN @ErrorCode
go
grant execute on dbo.dm_InsertExactMappings to public
go

