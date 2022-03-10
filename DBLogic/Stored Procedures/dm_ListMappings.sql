-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dm_ListMappings
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dm_ListMappings]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dm_ListMappings.'
	Drop procedure [dbo].[dm_ListMappings]
End
Print '**** Creating Stored Procedure dbo.dm_ListMappings...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.dm_ListMappings
			@pnUserIdentityId	int,			-- Mandatory
			@psCulture		nvarchar(10)	= null,
			@pbCalledFromCentura	bit		= 0,	-- Indicates that Centura code is calling the procedure
			@pnMapStructureKey	smallint,		-- Mandatory key of structure being mapped
			@pnFromSchemeKey	smallint	= null,	-- Key of predefined encoding scheme for input values
			@pnFromDataSourceKey	int		= null	-- Key describing the source of a raw data that has been mapped.
AS
-- PROCEDURE :	dm_ListMappings
-- VERSION:	3
-- DESCRIPTION:	Displays a list of mappings from an input value to an output value.
--		The input value may be a raw value, or a predefined encoding scheme.
--		The output value may be from a predefined encoding scheme, or an implementation value.
--
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 07 Sep 2005	MF	11685	1	Procedure created
-- 16 Sep 2005	JEK	11685	2	Column missing from @pnFromDataSourceKey result set.
-- 10 Mar 2008  DL	16017	3	Retrieve ENCODEDVALUE.OUTBOUNDVALUE 

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
	where MS.STRUCTUREID=@pnMapStructureKey'

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sDerivedTable	nvarchar(4000)	output,
					  @pnUserIdentityId	int,
					  @psCulture		nvarchar(10),
					  @pbCalledFromCentura	bit,
					  @pnMapStructureKey	smallint',
					  @sDerivedTable=@sDerivedTable		OUTPUT,
					  @pnUserIdentityId=@pnUserIdentityId,
					  @psCulture=@psCulture,
					  @pbCalledFromCentura=@pbCalledFromCentura,
					  @pnMapStructureKey=@pnMapStructureKey
End

If  @ErrorCode=0
and @sDerivedTable is not null
Begin
	If @pnFromSchemeKey is not null
	Begin
		Set @sSQLString="
		Select	M.ENTRYID		as ENTRYID,
			E.CODEID		as INPUTCODEID,
			E.CODE			as INPUTCODE,
			E.DESCRIPTION		as INPUTDESCRIPTION,
			M.OUTPUTCODEID		as OUTPUTCODEID,

			CASE WHEN(M.OUTPUTCODEID is not null)
			  THEN 	cast(
				CASE WHEN(OE.CODE is not NULL) THEN '{'+OE.CODE+'} ' END
			  	+ OE.DESCRIPTION as nvarchar(254))
			  ELSE NULL
			END			as ENCODEDDESCRIPTION,

			M.OUTPUTVALUE		as OUTPUTVALUE,

			CASE WHEN (M.OUTPUTVALUE is not null)
			   THEN cast(
				CASE WHEN(X.CODE is not NULL) THEN '{'+X.CODE+'} ' END
				 + X.DESCRIPTION as nvarchar(254))
			   ELSE NULL
			end			as IMPLEMENTEDDESCRIPTION,

			M.ISNOTAPPLICABLE	as ISNOTAPPLICABLE,
			E.OUTBOUNDVALUE		as OUTBOUNDVALUE
		From ENCODEDVALUE E
		left join MAPPING M		on (M.INPUTCODEID=E.CODEID
						and M.STRUCTUREID=E.STRUCTUREID)
		left join ENCODEDVALUE OE	on (OE.CODEID=M.OUTPUTCODEID)"+char(10)+char(9)+char(9)+
		"left join ("+@sDerivedTable+") X on (X.KEYVALUE=M.OUTPUTVALUE)
		Where E.SCHEMEID=@pnFromSchemeKey
		and E.STRUCTUREID=@pnMapStructureKey
		order by 3,4"

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnFromSchemeKey	smallint,
						  @pnMapStructureKey	smallint',
						  @pnFromSchemeKey=@pnFromSchemeKey,
						  @pnMapStructureKey=@pnMapStructureKey
	End
	Else If @pnFromDataSourceKey is not null
	Begin
		Set @sSQLString="
		Select	M.ENTRYID		as ENTRYID,
			null			as INPUTCODEID,
			M.INPUTCODE		as INPUTCODE,
			M.INPUTDESCRIPTION	as INPUTDESCRIPTION,
			M.OUTPUTCODEID		as OUTPUTCODEID,

			CASE WHEN(M.OUTPUTCODEID is not null)
			  THEN cast(
				CASE WHEN(E.CODE is not NULL) THEN '{'+E.CODE+'} ' END
			  	+ E.DESCRIPTION as nvarchar(254))
			  ELSE NULL
			END			as ENCODEDDESCRIPTION,

			M.OUTPUTVALUE		as OUTPUTVALUE,

			CASE WHEN(X.CODE is not NULL) 
			   THEN cast(
				CASE WHEN(X.CODE is not NULL) THEN '{'+X.CODE+'} ' END
				 + X.DESCRIPTION as nvarchar(254))
			   ELSE NULL
			end			as IMPLEMENTEDDESCRIPTION,

			M.ISNOTAPPLICABLE	as ISNOTAPPLICABLE,
			E.OUTBOUNDVALUE		as OUTBOUNDVALUE
		From MAPPING M
		left join ENCODEDVALUE E	on (E.CODEID=M.OUTPUTCODEID
						and E.STRUCTUREID=M.STRUCTUREID)"+char(10)+char(9)+char(9)+
		"left join ("+@sDerivedTable+") X on (X.KEYVALUE=M.OUTPUTVALUE)
		Where M.DATASOURCEID=@pnFromDataSourceKey
		and M.STRUCTUREID=@pnMapStructureKey
		order by 3,4"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnFromDataSourceKey	int,
						  @pnMapStructureKey	smallint',
						  @pnFromDataSourceKey=@pnFromDataSourceKey,
						  @pnMapStructureKey=@pnMapStructureKey
	End
End

RETURN @ErrorCode
go
grant execute on dbo.dm_ListMappings to public
go

