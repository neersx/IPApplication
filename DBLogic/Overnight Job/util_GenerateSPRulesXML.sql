-----------------------------------------------------------------------------------------------------------------------------
-- Creation of util_GenerateSPRulesXML
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[util_GenerateSPRulesXML]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.util_GenerateSPRulesXML.'
	Drop procedure [dbo].[util_GenerateSPRulesXML]
End
Print '**** Creating Stored Procedure dbo.util_GenerateSPRulesXML...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.util_GenerateSPRulesXML
(
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psTableName 		nvarchar(30),	-- Mandatory
	@psInternalName		nvarchar(30)	= null,
	@psPrefix 		nvarchar(30)	= null

)
as

-- PROCEDURE:	util_GenerateSPRulesXML.sql
-- VERSION:	2
-- DESCRIPTION:	This script generates the @ptXMLSPRules parameter 
-- 		for the util_GenerateProcedureTemplates

--		1. Set your query analyser output to text.
--		2. Set the value of @psTableName to your database table.
--		4. Run.
--		5. Copy output into new window and tidy up formatting as necessary.
--		6. Use the output as a @ptXMLSPRules to Run util_GenerateProcedureTemplates.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- ?		?	?	1	Procedure created
-- 06 Apr 2005	SW	RFC3701	2	Add extra empty tag and check for DataType, 
--					IsPrimary and MaxLength
--	

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
		
	Declare @tbResult	table ( LineNumber	smallint identity,
					ResultString	nvarchar(4000))
	
	Insert into @tbResult (ResultString)
	Select  '<?xml version="1.0" ?>'+char(10)+
		'<StoredProcedureRules>'+char(10)+
		'	<DatabaseTable>'+char(10)+
		'		<TableName>'+@psTableName+'</TableName>'+char(10)+
		'		<InternalName>'+@psInternalName+'</InternalName>'+char(10)+
		'		<Prefix>'+@psPrefix+'</Prefix>'+char(10)+
		'	</DatabaseTable>'+char(10)+
		'	<DatabaseColumns>'+char(10)
	
	
	Insert into @tbResult (ResultString)
	Select  '		<DatabaseColumn>'+char(10)+
		'			<ColumnName>'+COL.COLUMN_NAME+'</ColumnName>'+char(10)+
		'			<PropertyName></PropertyName>'+char(10)+
		'			<DataType>'+isnull(COL.DATA_TYPE, '')+'</DataType>'+char(10)+
		'			<DefaultValue></DefaultValue>'+char(10)+
		'			<IsMandatory></IsMandatory>'+char(10)+
		'			<IsPrimaryKey>'+isnull(PK.ISPK, 'N')+'</IsPrimaryKey>'+char(10)+
		'			<MaxLength>'+Coalesce(cast(COL.CHARACTER_MAXIMUM_LENGTH as varchar(50)), cast(COL.NUMERIC_PRECISION as varchar(50)), '')+'</MaxLength>'+char(10)+
		'			<MinValue></MinValue>'+char(10)+
		'			<MaxValue></MaxValue>'+char(10)+
		'		</DatabaseColumn>'+char(10)
	from INFORMATION_SCHEMA.COLUMNS COL
	left join (	Select	CU.COLUMN_NAME, 'Y' ISPK
			from	INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC
			join	INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CU on (TC.TABLE_NAME = CU.TABLE_NAME 
					and TC.CONSTRAINT_NAME = CU.CONSTRAINT_NAME)
			where	TC.TABLE_NAME = @psTableName
			and	TC.CONSTRAINT_TYPE = 'PRIMARY KEY') PK on (PK.COLUMN_NAME = COL.COLUMN_NAME)
	where 	TABLE_NAME = @psTableName
	order by ORDINAL_POSITION
	
	Insert into @tbResult (ResultString)
	select 	'	</DatabaseColumns>'+char(10)
	
	
	Insert into @tbResult (ResultString)
	Select	'	<FetchCriteria>'+char(10)+
		'		<DatabaseColumns>'+char(10)+
		'			<ColumnName></ColumnName>'+char(10)+
		'		</DatabaseColumns>'+char(10)+
		'	</FetchCriteria>'+char(10)+
		'</StoredProcedureRules>'
	

	Select ResultString as XMLString
	from @tbResult
	order by LineNumber
End

Return @nErrorCode
GO

Grant execute on dbo.util_GenerateSPRulesXML to public
GO
