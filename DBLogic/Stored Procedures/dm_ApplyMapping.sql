-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dm_ApplyMapping
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dm_ApplyMapping]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dm_ApplyMapping.'
	Drop procedure [dbo].[dm_ApplyMapping]
End
Print '**** Creating Stored Procedure dbo.dm_ApplyMapping...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.dm_ApplyMapping
(
	@pnUserIdentityId	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0,
	@pnMapStructureKey	smallint,	-- Mandatory.  The data structure being mapped; e.g. Number Type
	@pnDataSourceKey	int,		-- Mandatory.  The source of the input data being mapped.
	@pnFromSchemeKey	smallint	= null, -- The encoding scheme of the input data
	@pnCommonSchemeKey	smallint	= null, -- The common encoding scheme used as an intermediate step
	@psTableName		nvarchar(40),	-- Mandatory.  The database table to be updated.
	@psCodeColumnName	nvarchar(40)	= null, -- Once of Code or Description must be supplied
	@psDescriptionColumnName nvarchar(40)	= null,
	@psMappedColumn		nvarchar(40),	-- Mandatory. The column in which the results are to be placed.
	@pnDebugFlag		tinyint		= 0, --0=off,1=trace execution,2=dump data
	@pbKeepNonApplicableRows bit		= 0,
	@pbReturnUnmappedInfo	bit		= 0,
	@psUnmappedInfo		nvarchar(254)	= null OUTPUT
)
as
-- PROCEDURE:	dm_ApplyMapping
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Mapping involves relating information in an external system to the
--		corresponding values implemented in this system.  This procedure uses
--		predefined mapping rules to update a data structure containing
--		imported information with the corresponding implementation values.

--		See also test script Testing Harnesses/DataMapping.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Sep 2005	JEK	RFC3007	1	Procedure created
-- 16 Sep 2005	JEK	RFC3007	2	Check remaining rows.
-- 20 Sep 2005	JEK	RFC3007	3	Check column name when looking for unmapped.
-- 01 Oct 2006	vql	12995	4	Give option to return message if coding mapping error and make params 40 char.
-- 14 Nov 2018  AV  75198/DR-45358	5   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare @sAlertXML 	nvarchar(400)

declare	@sTimeStamp	nvarchar(24)
declare @nLastRowCount	int
declare @nRowsRemaining	int

declare	@bIgnoreUnmapped bit
declare @sUnmapped	nvarchar(100)
declare @sStructureName	nvarchar(50)
declare @sWorkColumn	nvarchar(100)
declare @sGroupColumn	nvarchar(100)

-- Initialise variables
Set @nErrorCode = 0

If  @pnDebugFlag>0
Begin
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s dm_ApplyMapping-Commence processing for @pnMapStructureKey=%d',0,1,@sTimeStamp,@pnMapStructureKey ) with NOWAIT
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select	@nRowsRemaining = count(*)
	from	"+@psTableName+"
	where 	"+@psMappedColumn+" is null"

	If @psCodeColumnName is not null
	and @psDescriptionColumnName is not null
	Begin
		Set @sSQLString = @sSQLString+"
		and	("+@psCodeColumnName+" is not null or
			 "+@psDescriptionColumnName+" is not null)"
	End
	Else If @psCodeColumnName is not null
	and @psDescriptionColumnName is null
	Begin
		Set @sSQLString = @sSQLString+"
		and	"+@psCodeColumnName+" is not null"
	End
	Else If @psCodeColumnName is null
	and @psDescriptionColumnName is not null
	Begin
		Set @sSQLString = @sSQLString+"
		and	"+@psDescriptionColumnName+" is not null"
	End

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@nRowsRemaining	int	OUTPUT',
		  @nRowsRemaining	= @nRowsRemaining OUTPUT

End

If @nErrorCode = 0
and @nRowsRemaining > 0
Begin
	-- Should unmapped values be ignored?
	Set @sSQLString = "
	select 	@bIgnoreUnmapped = IGNOREUNMAPPED,
		@pnFromSchemeKey = isnull(@pnFromSchemeKey, SCHEMEID)
	from	DATASOURCE DS
	join	MAPSCENARIO S	on (S.SYSTEMID=DS.SYSTEMID
				and S.STRUCTUREID=@pnMapStructureKey)
	where	DS.DATASOURCEID=@pnDataSourceKey"

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnMapStructureKey 	smallint,
		  @pnDataSourceKey	int,
		  @bIgnoreUnmapped	bit		OUTPUT,
		  @pnFromSchemeKey	smallint	OUTPUT',
		  @pnMapStructureKey	= @pnMapStructureKey,
		  @pnDataSourceKey	= @pnDataSourceKey,
		  @bIgnoreUnmapped	= @bIgnoreUnmapped OUTPUT,
		  @pnFromSchemeKey	= @pnFromSchemeKey OUTPUT
End

-- Delete raw Codes from the data source or update mapped code column.
If @nErrorCode = 0
and @psCodeColumnName is not null
and @nRowsRemaining > 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		If @pbKeepNonApplicableRows = 1
		Begin
			RAISERROR ('%s dm_ApplyMapping-Commence updating raw Codes for non applicable mappings',0,1,@sTimeStamp ) with NOWAIT
		End
		Else
		Begin
			RAISERROR ('%s dm_ApplyMapping-Commence deleting raw Codes',0,1,@sTimeStamp ) with NOWAIT
		End
	End

	-- Handle non applicable mappings.
	If @pbKeepNonApplicableRows = 1
	Begin
		-- Indicate no applicable mappings instead of deleting.
		Set @sSQLString = "
		update	"+@psTableName+"
		set	"+@psMappedColumn+" = ''
		from 	"+@psTableName+" I
		join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
		-- Raw Codes to output
		left join MAPPING M		on (M.INPUTCODE=upper(I."+@psCodeColumnName+")
						and M.STRUCTUREID=S.STRUCTUREID
						and M.DATASOURCEID=@pnDataSourceKey
						and M.ISNOTAPPLICABLE=1)
		-- Raw Codes -> Common encoding -> output
		left join MAPPING MC		on (MC.INPUTCODE=upper(I."+@psCodeColumnName+")
						and MC.STRUCTUREID=S.STRUCTUREID
						and MC.DATASOURCEID=@pnDataSourceKey
						and MC.OUTPUTCODEID is not null)
		left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
						and M2.DATASOURCEID is null
						and M2.STRUCTUREID=S.STRUCTUREID
						and M2.ISNOTAPPLICABLE=1)
		where 	I."+@psMappedColumn+" is null
		and	(M.ENTRYID is not null
		or	M2.ENTRYID is not null)"
	
		exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnMapStructureKey 	smallint,
			  @pnDataSourceKey	int',
			  @pnMapStructureKey	= @pnMapStructureKey,
			  @pnDataSourceKey	= @pnDataSourceKey
	End
	Else
	Begin
		Set @sSQLString = "
		delete	"+@psTableName+"
		from 	"+@psTableName+" I
		join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
		-- Raw Codes to output
		left join MAPPING M		on (M.INPUTCODE=upper(I."+@psCodeColumnName+")
						and M.STRUCTUREID=S.STRUCTUREID
						and M.DATASOURCEID=@pnDataSourceKey
						and M.ISNOTAPPLICABLE=1)
		-- Raw Codes -> Common encoding -> output
		left join MAPPING MC		on (MC.INPUTCODE=upper(I."+@psCodeColumnName+")
						and MC.STRUCTUREID=S.STRUCTUREID
						and MC.DATASOURCEID=@pnDataSourceKey
						and MC.OUTPUTCODEID is not null)
		left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
						and M2.DATASOURCEID is null
						and M2.STRUCTUREID=S.STRUCTUREID
						and M2.ISNOTAPPLICABLE=1)
		where 	I."+@psMappedColumn+" is null
		and	(M.ENTRYID is not null
		or	M2.ENTRYID is not null)"
	
		exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnMapStructureKey 	smallint,
			  @pnDataSourceKey	int',
			  @pnMapStructureKey	= @pnMapStructureKey,
			  @pnDataSourceKey	= @pnDataSourceKey
	End

	Set @nLastRowCount = @@ROWCOUNT
	Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		If @pbKeepNonApplicableRows = 1
		Begin
			RAISERROR ('%s dm_ApplyMapping: %d rows of raw Code data updated for non applicable mappings',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		End
		Else
		Begin
			RAISERROR ('%s dm_ApplyMapping: %d rows of raw Code data deleted',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		End
		if @nErrorCode > 0
		Begin
			print @sSQLString
		End
	End
End

-- Map raw Codes from the data source
If @nErrorCode = 0
and @psCodeColumnName is not null
and @nRowsRemaining > 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s dm_ApplyMapping-Commence mapping raw Codes',0,1,@sTimeStamp ) with NOWAIT
	End

	-- Map Codes from a specific data source
	Set @sSQLString = "
	update	"+@psTableName+"
	set	 "+@psTableName+"."+@psMappedColumn+"= isnull(M.OUTPUTVALUE,M2.OUTPUTVALUE)
	from 	"+@psTableName+" I
	join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
	-- Raw Codes to output
	left join MAPPING M		on (M.INPUTCODE=upper(I."+@psCodeColumnName+")
					and M.STRUCTUREID=S.STRUCTUREID
					and M.DATASOURCEID=@pnDataSourceKey
					and M.OUTPUTVALUE is not null)
	-- Raw Codes -> Common encoding -> output
	left join MAPPING MC		on (MC.INPUTCODE=upper(I."+@psCodeColumnName+")
					and MC.STRUCTUREID=S.STRUCTUREID
					and MC.DATASOURCEID=@pnDataSourceKey
					and MC.OUTPUTCODEID is not null)
	left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
					and M2.DATASOURCEID is null
					and M2.STRUCTUREID=S.STRUCTUREID
					and M2.OUTPUTVALUE is not null)
	where 	I."+@psMappedColumn+" is null
	and	(M.ENTRYID is not null
	or	M2.ENTRYID is not null)"

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnMapStructureKey 	smallint,
		  @pnDataSourceKey	int',
		  @pnMapStructureKey	= @pnMapStructureKey,
		  @pnDataSourceKey	= @pnDataSourceKey

	Set @nLastRowCount = @@ROWCOUNT
	Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s dm_ApplyMapping: %d rows of raw Code data mapped',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		if @nErrorCode > 0
		Begin
			print @sSQLString
		End
	End
End

-- Delete encoded Codes or update mapped code column.
If @nErrorCode = 0
and @psCodeColumnName is not null
and @pnFromSchemeKey is not null
and @nRowsRemaining > 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		If @pbKeepNonApplicableRows = 1
		Begin
			RAISERROR ('%s dm_ApplyMapping-Commence updating encoded Codes for non applicable mappings',0,1,@sTimeStamp ) with NOWAIT
		End
		Else
		Begin
			RAISERROR ('%s dm_ApplyMapping-Commence deleting encoded Codes',0,1,@sTimeStamp ) with NOWAIT
		End
	End

	-- Handle non applicable mappings.
	If @pnFromSchemeKey <> @pnCommonSchemeKey
	Begin
		If @pbKeepNonApplicableRows = 1
		Begin
			-- Indicate no applicable mappings instead of deleting.
			Set @sSQLString = "
			update	"+@psTableName+"
			set	"+@psMappedColumn+" = ''
			from 	"+@psTableName+" I
			join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
			-- Encoded value
			join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
							and V.SCHEMEID=@pnFromSchemeKey
							and V.CODE=upper(I."+@psCodeColumnName+"))
			-- Encoded value to output
			left join MAPPING M		on (M.INPUTCODEID=V.CODEID
							and M.STRUCTUREID=S.STRUCTUREID
							and M.DATASOURCEID is null
							and M.ISNOTAPPLICABLE = 1)
			-- Encoded value -> Common encoding -> output
			left join MAPPING MC		on (MC.INPUTCODEID=V.CODEID
							and MC.STRUCTUREID=S.STRUCTUREID
							and MC.DATASOURCEID is null
							and MC.OUTPUTCODEID is not null)
			left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
							and M2.DATASOURCEID is null
							and M2.STRUCTUREID=S.STRUCTUREID
							and M2.ISNOTAPPLICABLE = 1)
			where 	I."+@psMappedColumn+" is null
			and	(M.ENTRYID is not null
			or	M2.ENTRYID is not null)"
		End
		Else
		Begin
			Set @sSQLString = "
			delete	"+@psTableName+"
			from 	"+@psTableName+" I
			join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
			-- Encoded value
			join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
							and V.SCHEMEID=@pnFromSchemeKey
							and V.CODE=upper(I."+@psCodeColumnName+"))
			-- Encoded value to output
			left join MAPPING M		on (M.INPUTCODEID=V.CODEID
							and M.STRUCTUREID=S.STRUCTUREID
							and M.DATASOURCEID is null
							and M.ISNOTAPPLICABLE = 1)
			-- Encoded value -> Common encoding -> output
			left join MAPPING MC		on (MC.INPUTCODEID=V.CODEID
							and MC.STRUCTUREID=S.STRUCTUREID
							and MC.DATASOURCEID is null
							and MC.OUTPUTCODEID is not null)
			left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
							and M2.DATASOURCEID is null
							and M2.STRUCTUREID=S.STRUCTUREID
							and M2.ISNOTAPPLICABLE = 1)
			where 	I."+@psMappedColumn+" is null
			and	(M.ENTRYID is not null
			or	M2.ENTRYID is not null)"

		End
	End
	Else
	Begin
		If @pbKeepNonApplicableRows = 1
		Begin
			Set @sSQLString = "
			update	"+@psTableName+"
			set	"+@psMappedColumn+" = ''
			from 	"+@psTableName+" I
			join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
			-- Encoded value
			join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
							and V.SCHEMEID=@pnFromSchemeKey
							and V.CODE=upper(I."+@psCodeColumnName+"))
			-- Encoded value to output
			join MAPPING M			on (M.INPUTCODEID=V.CODEID
							and M.STRUCTUREID=S.STRUCTUREID
							and M.DATASOURCEID is null
							and M.ISNOTAPPLICABLE = 1)
			where 	I."+@psMappedColumn+" is null"
		End
		Else
		Begin
			Set @sSQLString = "
			delete	"+@psTableName+"
			from 	"+@psTableName+" I
			join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
			-- Encoded value
			join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
							and V.SCHEMEID=@pnFromSchemeKey
							and V.CODE=upper(I."+@psCodeColumnName+"))
			-- Encoded value to output
			join MAPPING M			on (M.INPUTCODEID=V.CODEID
							and M.STRUCTUREID=S.STRUCTUREID
							and M.DATASOURCEID is null
							and M.ISNOTAPPLICABLE = 1)
			where 	I."+@psMappedColumn+" is null"
		End
	End

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnMapStructureKey 	smallint,
		  @pnDataSourceKey	int,
		  @pnFromSchemeKey	smallint',
		  @pnMapStructureKey	= @pnMapStructureKey,
		  @pnDataSourceKey	= @pnDataSourceKey,
		  @pnFromSchemeKey	= @pnFromSchemeKey

	Set @nLastRowCount = @@ROWCOUNT
	Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		If @pbKeepNonApplicableRows = 1
		Begin
			RAISERROR ('%s dm_ApplyMapping: %d rows of encoded Code data updated for non applicable mappings',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		End
		Else
		Begin
			RAISERROR ('%s dm_ApplyMapping: %d rows of encoded Code data deleted',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		End
		if @nErrorCode > 0
		Begin
			print @sSQLString
		End
	End
End

-- Map encoded Codes
If @nErrorCode = 0
and @psCodeColumnName is not null
and @pnFromSchemeKey is not null
and @nRowsRemaining > 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s dm_ApplyMapping-Commence mapping encoded Codes',0,1,@sTimeStamp ) with NOWAIT
	End

	-- Map Codes from a specific data source
	If @pnFromSchemeKey <> @pnCommonSchemeKey
	Begin
		Set @sSQLString = "
		update	"+@psTableName+"
		set	 "+@psTableName+"."+@psMappedColumn+"= isnull(M.OUTPUTVALUE,M2.OUTPUTVALUE)
		from 	"+@psTableName+" I
		join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
		-- Encoded value
		join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
						and V.SCHEMEID=@pnFromSchemeKey
						and V.CODE=upper(I."+@psCodeColumnName+"))
		-- Encoded value to output
		left join MAPPING M		on (M.INPUTCODEID=V.CODEID
						and M.STRUCTUREID=S.STRUCTUREID
						and M.DATASOURCEID is null
						and M.OUTPUTVALUE is not null)
		-- Encoded value -> Common encoding -> output
		left join MAPPING MC		on (MC.INPUTCODEID=V.CODEID
						and MC.STRUCTUREID=S.STRUCTUREID
						and MC.DATASOURCEID is null
						and MC.OUTPUTCODEID is not null)
		left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
						and M2.DATASOURCEID is null
						and M2.STRUCTUREID=S.STRUCTUREID
						and M2.OUTPUTVALUE is not null)
		where 	I."+@psMappedColumn+" is null
		and	(M.ENTRYID is not null
		or	M2.ENTRYID is not null)"
	End
	Else
	Begin
		Set @sSQLString = "
		update	"+@psTableName+"
		set	 "+@psTableName+"."+@psMappedColumn+"= M.OUTPUTVALUE
		from 	"+@psTableName+" I
		join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
		-- Encoded value
		join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
						and V.SCHEMEID=@pnFromSchemeKey
						and V.CODE=upper(I."+@psCodeColumnName+"))
		-- Encoded value to output
		join MAPPING M			on (M.INPUTCODEID=V.CODEID
						and M.STRUCTUREID=S.STRUCTUREID
						and M.DATASOURCEID is null
						and M.OUTPUTVALUE is not null)
		where 	I."+@psMappedColumn+" is null"
	End


	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnMapStructureKey 	smallint,
		  @pnDataSourceKey	int,
		  @pnFromSchemeKey	smallint',
		  @pnMapStructureKey	= @pnMapStructureKey,
		  @pnDataSourceKey	= @pnDataSourceKey,
		  @pnFromSchemeKey	= @pnFromSchemeKey

	Set @nLastRowCount = @@ROWCOUNT
	Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s dm_ApplyMapping: %d rows of encoded Code data mapped',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		if @nErrorCode > 0
		Begin
			print @sSQLString
		End
	End
End

-- Delete raw Descriptions from the data source or update mapped code column.
If @nErrorCode = 0
and @psDescriptionColumnName is not null
and @nRowsRemaining > 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		If @pbKeepNonApplicableRows = 1
		Begin
			RAISERROR ('%s dm_ApplyMapping-Commence updating raw Descriptions for non applicable mappings',0,1,@sTimeStamp ) with NOWAIT
		End
		Else
		Begin
			RAISERROR ('%s dm_ApplyMapping-Commence deleting raw Descriptions',0,1,@sTimeStamp ) with NOWAIT
		End
	End

	-- Handle non applicable mappings.
	If @pbKeepNonApplicableRows = 1
	Begin
		-- Indicate no applicable mappings instead of deleting.
		Set @sSQLString = "
		update	"+@psTableName+"
		set 	"+@psMappedColumn+" = ''
		from 	"+@psTableName+" I
		join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
		-- Raw Codes to output
		left join MAPPING M		on (M.INPUTDESCRIPTION=upper(I."+@psDescriptionColumnName+")
						and M.STRUCTUREID=S.STRUCTUREID
						and M.DATASOURCEID=@pnDataSourceKey
						and M.ISNOTAPPLICABLE = 1)
		-- Raw Codes -> Common encoding -> output
		left join MAPPING MC		on (MC.INPUTDESCRIPTION=upper(I."+@psDescriptionColumnName+")
						and MC.STRUCTUREID=S.STRUCTUREID
						and MC.DATASOURCEID=@pnDataSourceKey
						and MC.OUTPUTCODEID is not null)
		left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
						and M2.DATASOURCEID is null
						and M2.STRUCTUREID=S.STRUCTUREID
						and M2.ISNOTAPPLICABLE = 1)
		where 	I."+@psMappedColumn+" is null
		and	(M.ENTRYID is not null
		or	M2.ENTRYID is not null)"
	End
	Else
	Begin
		Set @sSQLString = "
		delete	"+@psTableName+"
		from 	"+@psTableName+" I
		join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
		-- Raw Codes to output
		left join MAPPING M		on (M.INPUTDESCRIPTION=upper(I."+@psDescriptionColumnName+")
						and M.STRUCTUREID=S.STRUCTUREID
						and M.DATASOURCEID=@pnDataSourceKey
						and M.ISNOTAPPLICABLE = 1)
		-- Raw Codes -> Common encoding -> output
		left join MAPPING MC		on (MC.INPUTDESCRIPTION=upper(I."+@psDescriptionColumnName+")
						and MC.STRUCTUREID=S.STRUCTUREID
						and MC.DATASOURCEID=@pnDataSourceKey
						and MC.OUTPUTCODEID is not null)
		left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
						and M2.DATASOURCEID is null
						and M2.STRUCTUREID=S.STRUCTUREID
						and M2.ISNOTAPPLICABLE = 1)
		where 	I."+@psMappedColumn+" is null
		and	(M.ENTRYID is not null
		or	M2.ENTRYID is not null)"
	End


	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnMapStructureKey 	smallint,
		  @pnDataSourceKey	int',
		  @pnMapStructureKey	= @pnMapStructureKey,
		  @pnDataSourceKey	= @pnDataSourceKey

	Set @nLastRowCount = @@ROWCOUNT
	Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		If @pbKeepNonApplicableRows = 1
		Begin
			RAISERROR ('%s dm_ApplyMapping: %d rows of raw Description data updated for non applicable mappings',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		End
		Else
		Begin
			RAISERROR ('%s dm_ApplyMapping: %d rows of raw Description data deleted',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		End
		if @nErrorCode > 0
		Begin
			print @sSQLString
		End
	End
End

-- Map raw Descriptions from the data source
If @nErrorCode = 0
and @psDescriptionColumnName is not null
and @nRowsRemaining > 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s dm_ApplyMapping-Commence mapping raw Descriptions',0,1,@sTimeStamp ) with NOWAIT
	End

	-- Map Codes from a specific data source
	Set @sSQLString = "
	update	"+@psTableName+"
	set	 "+@psTableName+"."+@psMappedColumn+"= isnull(M.OUTPUTVALUE,M2.OUTPUTVALUE)
	from 	"+@psTableName+" I
	join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
	-- Raw Codes to output
	left join MAPPING M		on (M.INPUTDESCRIPTION=upper(I."+@psDescriptionColumnName+")
					and M.STRUCTUREID=S.STRUCTUREID
					and M.DATASOURCEID=@pnDataSourceKey
					and M.OUTPUTVALUE is not null)
	-- Raw Codes -> Common encoding -> output
	left join MAPPING MC		on (MC.INPUTDESCRIPTION=upper(I."+@psDescriptionColumnName+")
					and MC.STRUCTUREID=S.STRUCTUREID
					and MC.DATASOURCEID=@pnDataSourceKey
					and MC.OUTPUTCODEID is not null)
	left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
					and M2.DATASOURCEID is null
					and M2.STRUCTUREID=S.STRUCTUREID
					and M2.OUTPUTVALUE is not null)
	where 	I."+@psMappedColumn+" is null
	and	(M.ENTRYID is not null
	or	M2.ENTRYID is not null)"

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnMapStructureKey 	smallint,
		  @pnDataSourceKey	int',
		  @pnMapStructureKey	= @pnMapStructureKey,
		  @pnDataSourceKey	= @pnDataSourceKey

	Set @nLastRowCount = @@ROWCOUNT
	Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s dm_ApplyMapping: %d rows of raw Description data mapped',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		if @nErrorCode > 0
		Begin
			print @sSQLString
		End
	End
End

-- Delete encoded Descriptions or update mapped code column.
If @nErrorCode = 0
and @psDescriptionColumnName is not null
and @pnFromSchemeKey is not null
and @nRowsRemaining > 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		If @pbKeepNonApplicableRows = 1
		Begin
			RAISERROR ('%s dm_ApplyMapping-Commence updating encoded Descriptions for non applicable mappings',0,1,@sTimeStamp ) with NOWAIT
		End
		Else
		Begin
			RAISERROR ('%s dm_ApplyMapping-Commence deleting encoded Descriptions',0,1,@sTimeStamp ) with NOWAIT
		End
	End

	-- Handle non applicable mappings.
	If @pnFromSchemeKey <> @pnCommonSchemeKey
	Begin
		-- Indicate no applicable mappings instead of deleting.
		If @pbKeepNonApplicableRows = 1
		Begin
			Set @sSQLString = "
			update	"+@psTableName+"
			set	"+@psMappedColumn+" = ''
			from 	"+@psTableName+" I
			join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
			-- Encoded value
			join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
							and V.SCHEMEID=@pnFromSchemeKey
							and V.DESCRIPTION=upper(I."+@psDescriptionColumnName+"))
			-- Encoded value to output
			left join MAPPING M		on (M.INPUTCODEID=V.CODEID
							and M.STRUCTUREID=S.STRUCTUREID
							and M.DATASOURCEID is null
							and M.ISNOTAPPLICABLE = 1)
			-- Encoded value -> Common encoding -> output
			left join MAPPING MC		on (MC.INPUTCODEID=V.CODEID
							and MC.STRUCTUREID=S.STRUCTUREID
							and MC.DATASOURCEID is null
							and MC.OUTPUTCODEID is not null)
			left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
							and M2.DATASOURCEID is null
							and M2.STRUCTUREID=S.STRUCTUREID
							and M2.ISNOTAPPLICABLE = 1)
			where 	I."+@psMappedColumn+" is null
			and	(M.ENTRYID is not null
			or	M2.ENTRYID is not null)"
		End
		Else
		Begin
			Set @sSQLString = "
			delete	"+@psTableName+"
			from 	"+@psTableName+" I
			join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
			-- Encoded value
			join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
							and V.SCHEMEID=@pnFromSchemeKey
							and V.DESCRIPTION=upper(I."+@psDescriptionColumnName+"))
			-- Encoded value to output
			left join MAPPING M		on (M.INPUTCODEID=V.CODEID
							and M.STRUCTUREID=S.STRUCTUREID
							and M.DATASOURCEID is null
							and M.ISNOTAPPLICABLE = 1)
			-- Encoded value -> Common encoding -> output
			left join MAPPING MC		on (MC.INPUTCODEID=V.CODEID
							and MC.STRUCTUREID=S.STRUCTUREID
							and MC.DATASOURCEID is null
							and MC.OUTPUTCODEID is not null)
			left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
							and M2.DATASOURCEID is null
							and M2.STRUCTUREID=S.STRUCTUREID
							and M2.ISNOTAPPLICABLE = 1)
			where 	I."+@psMappedColumn+" is null
			and	(M.ENTRYID is not null
			or	M2.ENTRYID is not null)"
		End

	End
	Else
	Begin
		If @pbKeepNonApplicableRows = 1
		Begin
			Set @sSQLString = "
			update	"+@psTableName+"
			set	"+@psMappedColumn+" = ''
			from 	"+@psTableName+" I
			join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
			-- Encoded value
			join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
							and V.SCHEMEID=@pnFromSchemeKey
							and V.DESCRIPTION=upper(I."+@psDescriptionColumnName+"))
			-- Encoded value to output
			join MAPPING M			on (M.INPUTCODEID=V.CODEID
							and M.STRUCTUREID=S.STRUCTUREID
							and M.DATASOURCEID is null
							and M.ISNOTAPPLICABLE = 1)
			where 	I."+@psMappedColumn+" is null"
		End
		Else
		Begin
			Set @sSQLString = "
			delete	"+@psTableName+"
			from 	"+@psTableName+" I
			join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
			-- Encoded value
			join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
							and V.SCHEMEID=@pnFromSchemeKey
							and V.DESCRIPTION=upper(I."+@psDescriptionColumnName+"))
			-- Encoded value to output
			join MAPPING M			on (M.INPUTCODEID=V.CODEID
							and M.STRUCTUREID=S.STRUCTUREID
							and M.DATASOURCEID is null
							and M.ISNOTAPPLICABLE = 1)
			where 	I."+@psMappedColumn+" is null"
		End

	End

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnMapStructureKey 	smallint,
		  @pnDataSourceKey	int,
		  @pnFromSchemeKey	smallint',
		  @pnMapStructureKey	= @pnMapStructureKey,
		  @pnDataSourceKey	= @pnDataSourceKey,
		  @pnFromSchemeKey	= @pnFromSchemeKey

	Set @nLastRowCount = @@ROWCOUNT
	Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		If @pbKeepNonApplicableRows = 1
		Begin
			RAISERROR ('%s dm_ApplyMapping: %d rows of encoded Description data updated for non applicable mappings',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		End
		Else
		Begin
			RAISERROR ('%s dm_ApplyMapping: %d rows of encoded Description data deleted',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		End
		if @nErrorCode > 0
		Begin
			print @sSQLString
		End
	End
End

-- Map encoded Descriptions
If @nErrorCode = 0
and @psDescriptionColumnName is not null
and @pnFromSchemeKey is not null
and @nRowsRemaining > 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s dm_ApplyMapping-Commence mapping encoded Descriptions',0,1,@sTimeStamp ) with NOWAIT
	End

	-- Map Codes from a specific data source
	If @pnFromSchemeKey <> @pnCommonSchemeKey
	Begin
		Set @sSQLString = "
		update	"+@psTableName+"
		set	 "+@psTableName+"."+@psMappedColumn+"= isnull(M.OUTPUTVALUE,M2.OUTPUTVALUE)
		from 	"+@psTableName+" I
		join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
		-- Encoded value
		join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
						and V.SCHEMEID=@pnFromSchemeKey
						and V.DESCRIPTION=upper(I."+@psDescriptionColumnName+"))
		-- Encoded value to output
		left join MAPPING M		on (M.INPUTCODEID=V.CODEID
						and M.STRUCTUREID=S.STRUCTUREID
						and M.DATASOURCEID is null
						and M.OUTPUTVALUE is not null)
		-- Encoded value -> Common encoding -> output
		left join MAPPING MC		on (MC.INPUTCODEID=V.CODEID
						and MC.STRUCTUREID=S.STRUCTUREID
						and MC.DATASOURCEID is null
						and MC.OUTPUTCODEID is not null)
		left join MAPPING M2		on (M2.INPUTCODEID=MC.OUTPUTCODEID
						and M2.DATASOURCEID is null
						and M2.STRUCTUREID=S.STRUCTUREID
						and M2.OUTPUTVALUE is not null)
		where 	I."+@psMappedColumn+" is null
		and	(M.ENTRYID is not null
		or	M2.ENTRYID is not null)"
	End
	Else
	Begin
		Set @sSQLString = "
		update	"+@psTableName+"
		set	 "+@psTableName+"."+@psMappedColumn+"= M.OUTPUTVALUE
		from 	"+@psTableName+" I
		join	MAPSTRUCTURE S		on (S.STRUCTUREID=@pnMapStructureKey)
		-- Encoded value
		join ENCODEDVALUE V		on (V.STRUCTUREID=S.STRUCTUREID
						and V.SCHEMEID=@pnFromSchemeKey
						and V.DESCRIPTION=upper(I."+@psDescriptionColumnName+"))
		-- Encoded value to output
		join MAPPING M			on (M.INPUTCODEID=V.CODEID
						and M.STRUCTUREID=S.STRUCTUREID
						and M.DATASOURCEID is null
						and M.OUTPUTVALUE is not null)
		where 	I."+@psMappedColumn+" is null"
	End

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnMapStructureKey 	smallint,
		  @pnDataSourceKey	int,
		  @pnFromSchemeKey	smallint',
		  @pnMapStructureKey	= @pnMapStructureKey,
		  @pnDataSourceKey	= @pnDataSourceKey,
		  @pnFromSchemeKey	= @pnFromSchemeKey

	Set @nLastRowCount = @@ROWCOUNT
	Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s dm_ApplyMapping: %d rows of encoded Description data mapped',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
		if @nErrorCode > 0
		Begin
			print @sSQLString
		End
	End
End

-- Handle unmapped values
If @nErrorCode = 0
and @nRowsRemaining > 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s dm_ApplyMapping-Commence handling unmapped data',0,1,@sTimeStamp ) with NOWAIT
	End

	If @nErrorCode = 0
	Begin
		-- Remove any unmapped rows or update mapped code column.
		If @bIgnoreUnmapped = 1
		Begin
			-- Indicate no applicable mappings instead of deleting.
			If @pbKeepNonApplicableRows = 1
			Begin
				Set @sSQLString = "
				update	"+@psTableName+"
				set	"+@psMappedColumn+" = ''
				where 	"+@psMappedColumn+" is null"
			End
			Else
			Begin
				Set @sSQLString = "
				delete	"+@psTableName+"
				where 	"+@psMappedColumn+" is null"
			End

			If @psCodeColumnName is not null
			and @psDescriptionColumnName is not null
			Begin
				Set @sSQLString = @sSQLString+"
				and	("+@psCodeColumnName+" is not null or
					 "+@psDescriptionColumnName+" is not null)"
			End
			Else If @psCodeColumnName is not null
			and @psDescriptionColumnName is null
			Begin
				Set @sSQLString = @sSQLString+"
				and	"+@psCodeColumnName+" is not null"
			End
			Else If @psCodeColumnName is null
			and @psDescriptionColumnName is not null
			Begin
				Set @sSQLString = @sSQLString+"
				and	"+@psDescriptionColumnName+" is not null"
			End
		
			exec @nErrorCode = sp_executesql @sSQLString
		
			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				If @pbKeepNonApplicableRows = 1
				Begin
					RAISERROR ('%s dm_ApplyMapping: %d rows of ignored data updated for non applicable mappings',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				End
				Else
				Begin
					RAISERROR ('%s dm_ApplyMapping: %d rows of ignored data deleted',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				End
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

		-- Report errors
		Else
		Begin
			Set @sWorkColumn =
				case when @psCodeColumnName is not null and
					  @psDescriptionColumnName is not null
					then "isnull("+@psCodeColumnName+","+@psDescriptionColumnName+")"
				     when @psCodeColumnName is not null
					then @psCodeColumnName
				     when @psDescriptionColumnName is not null
					then @psDescriptionColumnName
				     end

			Set @sGroupColumn = 
				case when @psCodeColumnName is not null and
					  @psDescriptionColumnName is not null
					then @psDescriptionColumnName+","+@psCodeColumnName
				     when @psCodeColumnName is not null
					then @psCodeColumnName
				     when @psDescriptionColumnName is not null
					then @psDescriptionColumnName
				     end
			
			Set @sSQLString = "
			Select @sUnmapped = @sUnmapped + nullif(',', ',' + @sUnmapped) + "+@sWorkColumn+"
			from	"+@psTableName+"
			where 	"+@psMappedColumn+" is null"

			If @psCodeColumnName is not null
			and @psDescriptionColumnName is not null
			Begin
				Set @sSQLString = @sSQLString+"
				and	("+@psCodeColumnName+" is not null or
					 "+@psDescriptionColumnName+" is not null)"
			End
			Else If @psCodeColumnName is not null
			and @psDescriptionColumnName is null
			Begin
				Set @sSQLString = @sSQLString+"
				and	"+@psCodeColumnName+" is not null"
			End
			Else If @psCodeColumnName is null
			and @psDescriptionColumnName is not null
			Begin
				Set @sSQLString = @sSQLString+"
				and	"+@psDescriptionColumnName+" is not null"
			End

			Set @sSQLString = @sSQLString+"
			group by "+@sGroupColumn+"
			order by "+@sGroupColumn

			exec @nErrorCode = sp_executesql @sSQLString,
				N'@sUnmapped	 	nvarchar(100) OUTPUT',
				  @sUnmapped		= @sUnmapped OUTPUT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s dm_ApplyMapping: unmapped data = %s',0,1,@sTimeStamp, @sUnmapped ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End

			If @nErrorCode = 0
			and @sUnmapped is not null
			Begin
				Set @sSQLString="
				select 	@sStructureName=STRUCTURENAME
				from  	MAPSTRUCTURE
				where	STRUCTUREID=@pnMapStructureKey"

				exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnMapStructureKey 	smallint,
					  @sStructureName	nvarchar(50) OUTPUT',
					  @pnMapStructureKey	= @pnMapStructureKey,
					  @sStructureName	= @sStructureName OUTPUT

				If  @pnDebugFlag>0
				Begin
					set 	@sTimeStamp=convert(nvarchar,getdate(),126)
					RAISERROR ('%s dm_ApplyMapping: unmapped structure = %s',0,1,@sTimeStamp, @sStructureName ) with NOWAIT
					if @nErrorCode > 0
					Begin
						print @sSQLString
					End
				End
			End

			If @nErrorCode = 0 
			and @sUnmapped is not null
			Begin
				If @pbReturnUnmappedInfo = 1
				-- Return codes that were not mapped and the structure name.
				Begin
					Set @psUnmappedInfo = @sStructureName + ': ' + @sUnmapped
				End
				Else
				Begin
					Set @sAlertXML = dbo.fn_GetAlertXML('DE4', 'Unable to find corresponding values in your system. Please check your mapping rules for {0}: {1}',
					@sStructureName, @sUnmapped, null, null, null)
					RAISERROR(@sAlertXML, 14, 1)
				End
				Set @nErrorCode = @@ERROR
			End
		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.dm_ApplyMapping to public
GO
