-----------------------------------------------------------------------------------------------------------------------------
-- Creation of util_GenerateProcedureTemplates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[util_GenerateProcedureTemplates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.util_GenerateProcedureTemplates.'
	Drop procedure [dbo].[util_GenerateProcedureTemplates]
End
Print '**** Creating Stored Procedure dbo.util_GenerateProcedureTemplates...'
Print ''
GO


SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.util_GenerateProcedureTemplates
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@ptXMLSPRules		ntext
)
as
-- PROCEDURE:	util_GenerateProcedureTemplates
-- VERSION:	3
-- DESCRIPTION:	An internal stored procedure to generate templates for fetch and maintenance 
--		stored procedures from XML input.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Oct 2005	TM	RFC3173	1	Procedure created
-- 15 Nov 2005	TM	RFC3173	2	Increase the data length of the @sRowKey variable from 100 to 1000, 
--					to cater for tables with many columns in the composite primary keys.
-- 04 May 2006	SW	RFC3772	3	Bug fix for maintenance sproc that will generate redundant trailing 
--					"and" in "where clause" when there is no concurrency check 
--					Always return RowKey regardless primary key is composite or not.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sTableName 		nvarchar(30)
Declare @sInternalName		nvarchar(30)
Declare @sPrefix		nvarchar(10)
Declare @sTableAlias		nvarchar(10)

Declare @sSQLCreate		nvarchar(4000)
Declare @sSQLParameters		nvarchar(4000)
Declare @sSQLVariables		nvarchar(4000)
Declare @sSQLFromWhere		nvarchar(4000)
Declare @sExecuteSQL		nvarchar(4000)
Declare @sEndOfProcedure	nvarchar(4000)
Declare @sRowKey		nvarchar(1000)
Declare @sPrimaryKeyColumns	nvarchar(1000)
Declare @sPrimaryKeyVariables	nvarchar(1000)
Declare @bIsPrimaryOnly		bit		-- Set to 1 if the supplied table consists of primary key columns only

Declare @idoc 			int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument		

Declare @tblDatabaseColumns table
	(Ident			int IDENTITY(0,1),
	 ColumnName		nvarchar(30)	collate database_default null,
	 PropertyName		nvarchar(50)	collate database_default null,
	 ParameterPrefix	nvarchar(10)	collate database_default null,
	 DataType		nvarchar(30)	collate database_default null,
	 IsPrimaryKey		bit,
	 IsFetchColumn		bit,
	 IsLastFetchColumn	bit,
	 IsLastColumn		bit,
	 IsLastPrimaryKeyColumn bit,
	 IsIdentityColumn	bit,
	 OrdinalPosition	int	 
	)

Declare @tblFetchCriteria table
	(Ident			int IDENTITY(0,1),
	 ColumnName		nvarchar(30)	collate database_default null
	)

Declare @tbResult	table ( LineNumber	smallint identity,
				ResultString	nvarchar(4000))

-- Initialise variables
Set @nErrorCode = 0
Set @bIsPrimaryOnly = 0

If @nErrorCode = 0
Begin
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLSPRules
	
	Select 	@sTableName 		= TableName,
		@sInternalName		= InternalName,
		@sPrefix		= Prefix	
	from	OPENXML (@idoc, '//StoredProcedureRules/DatabaseTable',2)
		WITH (
		      TableName			nvarchar(30)	'TableName/text()',
		      InternalName		nvarchar(30)	'InternalName/text()',
		      Prefix			nvarchar(10)	'Prefix/text()'
		     )

--	select @sTableName as '@sTableName', @sInternalName as '@sInternalName', @sPrefix as '@sPrefix'

	set @nErrorCode = @@ERROR
End

-- Load supplied fetch criteria into table variable
If @nErrorCode = 0
Begin
	Insert into @tblFetchCriteria (ColumnName)
	Select 	ColumnName
	from	OPENXML (@idoc, '//StoredProcedureRules/FetchCriteria/DatabaseColumns/ColumnName',2)
		WITH (
		      ColumnName		nvarchar(30)	'text()'
		     )

	set @nErrorCode = @@ERROR
End

-- Load supplied database columns into table variable
If @nErrorCode = 0
Begin
	Insert into @tblDatabaseColumns (ColumnName, PropertyName)
	Select 	ColumnName, PropertyName
	from	OPENXML (@idoc, '//StoredProcedureRules/DatabaseColumns/DatabaseColumn',2)
		WITH (
		      ColumnName		nvarchar(30)	'ColumnName/text()',
		      PropertyName		nvarchar(50)	'PropertyName/text()'
		     )

	set @nErrorCode = @@ERROR
End

-- deallocate the xml document handle when finished.
exec sp_xml_removedocument @idoc

-- Update database columns information with required information
If @nErrorCode = 0
Begin 
	Update @tblDatabaseColumns 
	set 
	ParameterPrefix	= 
	CASE	WHEN UPPER(DATA_TYPE) LIKE '%TEXT' THEN '@pt' 
		WHEN UPPER(DATA_TYPE) in ('NVARCHAR','NCHAR','VARCHAR','CHAR') THEN '@ps' 	
		WHEN UPPER(DATA_TYPE) LIKE '%DATE%' OR UPPER(DATA_TYPE) LIKE '%TIME%' THEN '@pdt'
		WHEN UPPER(DATA_TYPE) in ('BIT') OR (UPPER(DATA_TYPE) in ('DECIMAL') AND DT.NUMERIC_PRECISION = 1 AND DT.NUMERIC_SCALE = 0) THEN '@pb'			
		ELSE '@pn'
	END,
	DataType = 
	CASE	WHEN UPPER(DT.DATA_TYPE) LIKE '%TEXT' THEN 'ntext' 
		WHEN (UPPER(DT.DATA_TYPE) = 'DECIMAL' AND DT.NUMERIC_PRECISION = 1 AND DT.NUMERIC_SCALE = 0) THEN 'bit'	
		ELSE DT.DATA_TYPE + 
		CASE  	WHEN UPPER(DT.DATA_TYPE) = 'NVARCHAR' 
			THEN "(" + CAST(DT.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ")" 
			WHEN UPPER(DATA_TYPE) = 'NCHAR'		
			THEN "(" + CAST(DT.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10)) + ")" 
			WHEN UPPER(DT.DATA_TYPE) = 'DECIMAL'	
			THEN "(" + CAST(DT.NUMERIC_PRECISION AS VARCHAR(10)) + "," + CAST(DT.NUMERIC_SCALE AS VARCHAR(10)) + ")" 				
		END 	
	END,
	IsFetchColumn = CASE WHEN FC.ColumnName = DC.ColumnName THEN 1 ELSE 0 END,
	IsPrimaryKey =
	CASE 	WHEN DT.COLUMN_NAME = CU.COLUMN_NAME THEN 1 ELSE 0 END,
	IsLastFetchColumn = 
	CASE 	WHEN DT.ORDINAL_POSITION = 
		       (Select MAX(DT2.ORDINAL_POSITION)
		      	from @tblFetchCriteria FC2	
			join INFORMATION_SCHEMA.COLUMNS DT2	
				on (DT2.COLUMN_NAME = FC2.ColumnName)					
			where 	DT2.TABLE_NAME = @sTableName)
		THEN 1
		ELSE 0
	END,
	IsLastColumn = 
	CASE 	WHEN DT.ORDINAL_POSITION = 
		       (Select MAX(DT2.ORDINAL_POSITION)
		      	from @tblDatabaseColumns DC2	
			join INFORMATION_SCHEMA.COLUMNS DT2	
				on (DT2.COLUMN_NAME = DC2.ColumnName)					
			where 	DT2.TABLE_NAME = @sTableName)
		THEN 1
		ELSE 0
	END,
	IsIdentityColumn = CASE WHEN DT.COLUMN_NAME = IdCol.IdentityColumn THEN 1 ELSE 0 END,
	OrdinalPosition = DT.ORDINAL_POSITION  	
	from @tblDatabaseColumns DC
	join INFORMATION_SCHEMA.COLUMNS DT
				on (DT.COLUMN_NAME = DC.ColumnName)
	left join @tblFetchCriteria FC
				on (FC.ColumnName = DC.ColumnName)
	left join INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC
			on (TC.TABLE_NAME = DT.TABLE_NAME
			and TC.CONSTRAINT_TYPE = 'PRIMARY KEY')
	left join INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CU
				on (CU.CONSTRAINT_NAME = TC.CONSTRAINT_NAME
				and CU.TABLE_NAME = DT.TABLE_NAME
				and CU.COLUMN_NAME = DT.COLUMN_NAME)
	left join  ( 	Select C2.name IdentityColumn, O2.id
		        from sysobjects O2  
			join syscolumns C2 on (C2.id=O2.id)
			where O2.type = 'U'	
			and   COLUMNPROPERTY(O2.id, C2.name, 'IsIdentity') = 1) IdCol 
		on (OBJECT_NAME(IdCol.id) = @sTableName)
	where 	DT.TABLE_NAME = @sTableName

	set @nErrorCode = @@ERROR
End

-- Update IsLastPrimaryKeyColumn
If @nErrorCode = 0
Begin 
	Update	@tblDatabaseColumns 
	set	IsLastPrimaryKeyColumn = 
		CASE 	WHEN DC.OrdinalPosition = 
			       (Select MAX(DC2.OrdinalPosition)
				from @tblDatabaseColumns DC2	
				where IsPrimaryKey = 1)
			THEN 1
			ELSE 0
		END
	from 	@tblDatabaseColumns DC
	
	set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Select @bIsPrimaryOnly = 1
	from @tblDatabaseColumns
	where not exists (Select * 
			  from @tblDatabaseColumns 
			  where IsPrimaryKey = 0)
End

-- Assemble static building blocks of the Fetch template
If @nErrorCode = 0
Begin
	Set @sSQLCreate = 
	"-----------------------------------------------------------------------------------------------------------------------------"+CHAR(10)+
	"-- Creation of "+@sPrefix+"_Fetch"+@sInternalName+"									      "+CHAR(10)+
	"-----------------------------------------------------------------------------------------------------------------------------"+CHAR(10)+
	"If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].["+@sPrefix+"_Fetch"+@sInternalName+"]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)"+CHAR(10)+
	"Begin"+CHAR(10)+
	"	Print '**** Drop Stored Procedure dbo."+@sPrefix+"_Fetch"+@sInternalName+".'"+CHAR(10)+
	"	Drop procedure [dbo].["+@sPrefix+"_Fetch"+@sInternalName+"]"+CHAR(10)+
	"End"+CHAR(10)+
	"Print '**** Creating Stored Procedure dbo."+@sPrefix+"_Fetch"+@sInternalName+"...'"+CHAR(10)+
	"Print ''"+CHAR(10)+
	"GO"+CHAR(10)+
	+CHAR(10)+
	"SET QUOTED_IDENTIFIER OFF"+CHAR(10)+
	"GO"+CHAR(10)+
	"SET ANSI_NULLS ON"+CHAR(10)+
	"GO"+CHAR(10)+
	+CHAR(10)+
	+CHAR(10)+
	"CREATE PROCEDURE dbo."+@sPrefix+"_Fetch"+@sInternalName+CHAR(10)+
	"("+CHAR(10)+
	"	@pnUserIdentityId	int,		-- Mandatory"+CHAR(10)+
	"	@psCulture		nvarchar(10) 	= null,"+CHAR(10)+
	"	@pbCalledFromCentura	bit		= 0,"


	Set @sSQLVariables = 
	")"+CHAR(10)+
	"as"+CHAR(10)+
	"-- PROCEDURE:	"+@sPrefix+"_Fetch"+@sInternalName+CHAR(10)+
	"-- VERSION:	1"+CHAR(10)+
	"-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited"+CHAR(10)+
	"-- DESCRIPTION:	Populate the "+@sInternalName+" business entity."+CHAR(10)+
	+CHAR(10)+
	"-- MODIFICATIONS :"+CHAR(10)+
	"-- Date		Who	Change	Version	Description"+CHAR(10)+
	"-- -----------	-------	------	-------	-----------------------------------------------"+CHAR(10)+ 
	"-- "+convert(nvarchar(100), getdate(), 106)+"		RFCxxx	1	Procedure created"+CHAR(10)+
	+CHAR(10)+
	"SET NOCOUNT ON"+CHAR(10)+
	"SET CONCAT_NULL_YIELDS_NULL OFF"+CHAR(10)+
	+CHAR(10)+
	"Declare @nErrorCode	int"+CHAR(10)+
	"Declare @sSQLString 	nvarchar(4000)"+CHAR(10)+
	+CHAR(10)+
	"-- Initialise variables"+CHAR(10)+
	"Set @nErrorCode = 0"+CHAR(10)+
	+CHAR(10)+
	"If @nErrorCode = 0"+CHAR(10)+
	"Begin"+CHAR(10)+
	"	Set @sSQLString = ""Select"+CHAR(10)

	Set @sTableAlias = substring(@sTableName,1,1)

	Set @sSQLFromWhere = 	"	from " + @sTableName + " " + @sTableAlias + CHAR(10) + 
				"--***** Please note, additional joins may be required implementing" + CHAR(10) +
				"--***** in the 'Select' statement to get any columns that are not" + CHAR(10) + 
				"--***** on the provided table" + CHAR(10) + 
				"	where "

	Set @sExecuteSQL = CHAR(10)+
			   "	" + "exec @nErrorCode=sp_executesql @sSQLString," + CHAR(10) +
			   "			N'"

	Set @sEndOfProcedure = 
	"End" + CHAR(10) +
	+ CHAR(10) +
	"Return @nErrorCode" + CHAR(10) +
	"GO" + CHAR(10) +
	+ CHAR(10) +
	"Grant execute on dbo."+@sPrefix+"_Fetch"+@sInternalName+" to public" + CHAR(10) +
	"GO"
End

-- Output the template for the 'Fetch' procedure
If @nErrorCode = 0
Begin
	insert into @tbResult (ResultString)
	Select @sSQLCreate

	-- Assemble stored procedure's parameters
	insert into @tbResult (ResultString)
	Select  '	' + 
		DC.ParameterPrefix + 
		DC.PropertyName + 
		'	' + 
		'	' + 
		DC.DataType + 
		CASE 	WHEN DC.IsLastFetchColumn = 1
			THEN ' -- Mandatory'
			ELSE ', -- Mandatory'
		END	
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1
	order by DC.OrdinalPosition	

	insert into @tbResult (ResultString)
	Select @sSQLVariables
	
	-- Generate RowKey for primary key
	Select  @sRowKey = NULLIF(@sRowKey + "+'^'+", "+'^'+") + 
		CASE	WHEN ParameterPrefix = '@ps'
			THEN @sTableAlias + '.' + ColumnName 
			WHEN ParameterPrefix = '@pn'
			THEN 'CAST('+@sTableAlias + '.' + ColumnName + ' as nvarchar(10))'
			WHEN ParameterPrefix = '@pdt'
			THEN 'CONVERT(varchar,'+@sTableAlias + '.' + ColumnName + ',121)'
			ELSE 'CAST('+@sTableAlias + '.' + ColumnName + ' as nvarchar(100))'
		END 			
	from    @tblDatabaseColumns
	where   IsPrimaryKey = 1
	order by OrdinalPosition				

	insert into @tbResult (ResultString)
	Select  '	' +
		@sRowKey  +
		'	' + 
		'	' + 
		'as RowKey,'


	insert into @tbResult (ResultString)
	Select  '	' + 
		@sTableAlias + '.' + ColumnName +
		'	' + 
		'	' + 
		'as '+PropertyName+
		CASE 	WHEN IsLastColumn = 0
			THEN ','
		END		
	from    @tblDatabaseColumns
	order by OrdinalPosition
	
	insert into @tbResult (ResultString)
	Select @sSQLFromWhere

	insert into @tbResult (ResultString)
	Select  '	' + @sTableAlias + '.' + ColumnName + ' = ' + DC.ParameterPrefix + DC.PropertyName + 	
		CASE 	WHEN  DC.IsLastFetchColumn = 0
			THEN '	and '
			ELSE '"'
		END 
	from    @tblDatabaseColumns DC
	where DC.IsFetchColumn = 1
	order by DC.OrdinalPosition	

	insert into @tbResult (ResultString)
	Select  "--***** Please note, 'Order by' clause may need to be implemented." 

	insert into @tbResult (ResultString)
	Select @sExecuteSQL

	insert into @tbResult (ResultString)
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + 
		DC.PropertyName + 
		'	' +
		'	' + 
		DC.DataType + 	
		CASE 	WHEN DC.IsLastFetchColumn = 1
			THEN ''','
			ELSE ','
		END	
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1
	UNION ALL
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + DC.PropertyName + 
		'	' +
		' = ' +     
		DC.ParameterPrefix + DC.PropertyName + 	
		CASE 	WHEN DC.IsLastFetchColumn = 0
			THEN ','		
		END	
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1
	
	insert into @tbResult (ResultString)
	Select @sEndOfProcedure	
End

-- Assemble static building blocks of the Insert template
If @nErrorCode = 0
Begin
	Set @sSQLCreate = 
	"-----------------------------------------------------------------------------------------------------------------------------"+CHAR(10)+
	"-- Creation of "+@sPrefix+"_Insert"+@sInternalName+"									      "+CHAR(10)+
	"-----------------------------------------------------------------------------------------------------------------------------"+CHAR(10)+
	"If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].["+@sPrefix+"_Insert"+@sInternalName+"]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)"+CHAR(10)+
	"Begin"+CHAR(10)+
	"	Print '**** Drop Stored Procedure dbo."+@sPrefix+"_Insert"+@sInternalName+".'"+CHAR(10)+
	"	Drop procedure [dbo].["+@sPrefix+"_Insert"+@sInternalName+"]"+CHAR(10)+
	"End"+CHAR(10)+
	"Print '**** Creating Stored Procedure dbo."+@sPrefix+"_Insert"+@sInternalName+"...'"+CHAR(10)+
	"Print ''"+CHAR(10)+
	"GO"+CHAR(10)+
	+CHAR(10)+
	"SET QUOTED_IDENTIFIER OFF"+CHAR(10)+
	"GO"+CHAR(10)+
	"SET ANSI_NULLS ON"+CHAR(10)+
	"GO"+CHAR(10)+
	+CHAR(10)+
	+CHAR(10)+
	"CREATE PROCEDURE dbo."+@sPrefix+"_Insert"+@sInternalName+CHAR(10)+
	"("+CHAR(10)+
	"	@pnUserIdentityId	int,		-- Mandatory"+CHAR(10)+
	"	@psCulture		nvarchar(10) 	= null,"+CHAR(10)+
	"	@pbCalledFromCentura	bit		= 0,"


	Set @sSQLVariables = 
	")"+CHAR(10)+
	"as"+CHAR(10)+
	"-- PROCEDURE:	"+@sPrefix+"_Insert"+@sInternalName+CHAR(10)+
	"-- VERSION:	1"+CHAR(10)+
	"-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited"+CHAR(10)+
	"-- DESCRIPTION:	Insert "+@sInternalName+"."+CHAR(10)+
	+CHAR(10)+
	"-- MODIFICATIONS :"+CHAR(10)+
	"-- Date		Who	Change	Version	Description"+CHAR(10)+
	"-- -----------	-------	------	-------	-----------------------------------------------"+CHAR(10)+ 
	"-- "+convert(nvarchar(100), getdate(), 106)+"		RFCxxx	1	Procedure created"+CHAR(10)+
	+CHAR(10)+
	"SET CONCAT_NULL_YIELDS_NULL OFF"+CHAR(10)+
	"-- Row counts required by the data adapter"+CHAR(10)+
	"SET NOCOUNT OFF"+CHAR(10)+
	+CHAR(10)+
	"Declare @nErrorCode		int"+CHAR(10)+
	"Declare @sSQLString 		nvarchar(4000)"+CHAR(10)+
	"Declare @sInsertString 	nvarchar(4000)"+CHAR(10)+
	"Declare @sValuesString		nvarchar(4000)"+CHAR(10)+
	"Declare @sComma		nchar(1)"+CHAR(10)+
	+CHAR(10)+
	"-- Initialise variables"+CHAR(10)+
	"Set @nErrorCode = 0"+CHAR(10)+
	'Set @sValuesString = CHAR(10)+" values ("'+CHAR(10)+
	+CHAR(10)+
	"If @nErrorCode = 0"+CHAR(10)+
	"Begin"+CHAR(10)+
	'	Set @sInsertString = "Insert into ' + @sTableName + CHAR(10) + 
	'				("' + CHAR(10)

	Set @sSQLFromWhere = 	'	Set @sInsertString = @sInsertString+CHAR(10)+")"'+CHAR(10)+		
				'	Set @sValuesString = @sValuesString+CHAR(10)+")"'+CHAR(10)+
				+CHAR(10)+
				'	Set @sSQLString = @sInsertString + @sValuesString'+CHAR(10)+
				+CHAR(10)+
				'	exec @nErrorCode=sp_executesql @sSQLString,'+CHAR(10)+
				'			      	N''' 

	Set @sEndOfProcedure = 
	CHAR(10)+
	CHAR(10)+
	"--***** Note, you may need to publish generated key of the inserted row. This may be automatically"+CHAR(10)+
	"--***** generated identity column or last internal generated code."+CHAR(10)+	
	+CHAR(10)+
	+CHAR(10)+
	"End" + CHAR(10) +
	+ CHAR(10) +
	"Return @nErrorCode" + CHAR(10) +
	"GO" + CHAR(10) +
	+ CHAR(10) +
	"Grant execute on dbo."+@sPrefix+"_Insert"+@sInternalName+" to public" + CHAR(10) +
	"GO"
End

-- Output the template for the 'Insert' procedure
If @nErrorCode = 0
Begin
	insert into @tbResult (ResultString)
	Select @sSQLCreate

	-- 'Fetch' parameters
	insert into @tbResult (ResultString)
	Select  '	' + 
		DC.ParameterPrefix + 
		DC.PropertyName + 
		'	' + 
		'	' + 
		DC.DataType + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN '	'  + '-- Mandatory.'+CHAR(10)+ 
			     '--***** Note: If the primary key is generated, change the above '+DC.ParameterPrefix+DC.PropertyName+' parameter to non-mandatory.'
			ELSE ',	'  + '-- Mandatory.'+CHAR(10)+  
			     '--***** Note: If the primary key is generated, change the above '+DC.ParameterPrefix+DC.PropertyName+' parameter to non-mandatory.'
		END	
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1 
	or    DC.IsPrimaryKey = 1	
	UNION ALL	
	-- New values parameters
	Select  '	' + 
		DC.ParameterPrefix + 
		DC.PropertyName +
		'	' + 
		DC.DataType + 
		'	' + 
		'	' + ' = null,'
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0		
	UNION ALL	
	-- 'InUse' parameters
	Select  '	' + 
		'@pb' + 'Is' + DC.PropertyName + + 'InUse' + 
		'	' + 
		'	' + 'bit' +
		'	' + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN ' = 0'
			ELSE ' = 0,'
		END	
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0 
	and   DC.IsPrimaryKey = 0	
	
	insert into @tbResult (ResultString)
	Select @sSQLVariables	

	Select @sPrimaryKeyColumns = 
				'	' +
				'	' +
				'	' +
				NULLIF(@sPrimaryKeyColumns + ',', ',') + 
				ColumnName
	from    @tblDatabaseColumns
	where IsIdentityColumn = 0
	and   IsPrimaryKey = 1
	order by OrdinalPosition	

	-- Set the '@sComma' variable to ',' if primary
	-- key/s is not an identity column:
	If @sPrimaryKeyColumns is not null
	Begin
		insert into @tbResult (ResultString)
		Select  CHAR(10) + 
			'	' +
			'Set @sComma = ","'
	End

	-- Assemble primary key (if it's not identity column) info before 
	-- the rest of the columns to be inserted
	If exists(Select * from @tblDatabaseColumns where IsIdentityColumn = 0 and   IsPrimaryKey = 1)
	Begin
		insert into @tbResult (ResultString)
		Select  '	' + 'Set @sInsertString = @sInsertString+CHAR(10)+"'
	
		insert into @tbResult (ResultString)
		Select @sPrimaryKeyColumns
	
		insert into @tbResult (ResultString)
		Select  '	' +
			'	' +
			'	' +
			'"' + CHAR(10)
	
		insert into @tbResult (ResultString)
		Select  
			'	' + 'Set @sValuesString = @sValuesString+CHAR(10)+"'
	
		Select @sPrimaryKeyVariables = 
					'	' +
					'	' +
					'	' +
					NULLIF(@sPrimaryKeyVariables + ',', ',') + 
					ParameterPrefix+PropertyName
		from    @tblDatabaseColumns
		where IsIdentityColumn = 0
		and   IsPrimaryKey = 1
		order by OrdinalPosition		
	
		insert into @tbResult (ResultString)
		Select @sPrimaryKeyVariables
	
		insert into @tbResult (ResultString)
		Select  '	' +
			'	' +
			'	' +
			'"' + CHAR(10)
	End

	insert into @tbResult (ResultString)
	Select  '	' + 'If @pbIs' + PropertyName + 'InUse = 1'+CHAR(10)+ 
		'	' + 'Begin'+CHAR(10)+
		'	' + '	Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"'+ColumnName+'"'+CHAR(10)+ 		
		'	' + '	Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"'+ParameterPrefix+PropertyName+'"'+CHAR(10)+ 
		'	' + '	Set @sComma = ","'+CHAR(10)+ 
		'	' + 'End' + CHAR(10) 
	from    @tblDatabaseColumns
	where IsIdentityColumn = 0
	and   IsPrimaryKey = 0
	order by OrdinalPosition

	insert into @tbResult (ResultString)
	Select @sSQLFromWhere

	-- Declaration of parameters for sp_executesql
	insert into @tbResult (ResultString)
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + 
		DC.PropertyName + 
		'	' + 
		'	' + 
		DC.DataType + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN ''','
			ELSE ','
		END	 
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1 
	or    DC.IsPrimaryKey = 1	
	UNION ALL	
	-- New values parameters
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + 
		DC.PropertyName +
		'	' + 
		'	' + 
		DC.DataType + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN ''','
			ELSE ','
		END	
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0		
	
	-- Submitting parameters to the sp_executesql
	insert into @tbResult (ResultString)
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + DC.PropertyName + 
		'	' +
		' = ' +     
		DC.ParameterPrefix + DC.PropertyName + 
		CASE 	WHEN DC.IsLastColumn = 0
			THEN ','		
		END		
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1 
	or    DC.IsPrimaryKey = 1	
	UNION ALL	
	-- New values parameters
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + DC.PropertyName + 
		'	' +
		' = ' +     
		DC.ParameterPrefix + DC.PropertyName + 
		CASE 	WHEN DC.IsLastColumn = 0
			THEN ','		
		END	
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0		
	
	insert into @tbResult (ResultString)
	Select @sEndOfProcedure
End

-- Assemble static building blocks of the Update template
If @nErrorCode = 0
Begin
	Set @sSQLCreate = 
	"-----------------------------------------------------------------------------------------------------------------------------"+CHAR(10)+
	"-- Creation of "+@sPrefix+"_Update"+@sInternalName+"									      "+CHAR(10)+
	"-----------------------------------------------------------------------------------------------------------------------------"+CHAR(10)+
	"If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].["+@sPrefix+"_Update"+@sInternalName+"]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)"+CHAR(10)+
	"Begin"+CHAR(10)+
	"	Print '**** Drop Stored Procedure dbo."+@sPrefix+"_Update"+@sInternalName+".'"+CHAR(10)+
	"	Drop procedure [dbo].["+@sPrefix+"_Update"+@sInternalName+"]"+CHAR(10)+
	"End"+CHAR(10)+
	"Print '**** Creating Stored Procedure dbo."+@sPrefix+"_Update"+@sInternalName+"...'"+CHAR(10)+
	"Print ''"+CHAR(10)+
	"GO"+CHAR(10)+
	+CHAR(10)+
	"SET QUOTED_IDENTIFIER OFF"+CHAR(10)+
	"GO"+CHAR(10)+
	"-- Allow comparison of null values."+CHAR(10)+
	"-- Procedure uses setting in place before it's created."+CHAR(10)+ 
	"SET ANSI_NULLS OFF"+CHAR(10)+
	"GO"+CHAR(10)+
	+CHAR(10)+
	+CHAR(10)+
	"CREATE PROCEDURE dbo."+@sPrefix+"_Update"+@sInternalName+CHAR(10)+
	"("+CHAR(10)+
	"	@pnUserIdentityId	int,		-- Mandatory"+CHAR(10)+
	"	@psCulture		nvarchar(10) 	= null,"+CHAR(10)+
	"	@pbCalledFromCentura	bit		= 0,"


	Set @sSQLVariables = 
	")"+CHAR(10)+
	"as"+CHAR(10)+
	"-- PROCEDURE:	"+@sPrefix+"_Update"+@sInternalName+CHAR(10)+
	"-- VERSION:	1"+CHAR(10)+
	"-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited"+CHAR(10)+
	"-- DESCRIPTION:	Update "+@sInternalName+" if the underlying values are as expected."+CHAR(10)+
	+CHAR(10)+
	"-- MODIFICATIONS :"+CHAR(10)+
	"-- Date		Who	Change	Version	Description"+CHAR(10)+
	"-- -----------	-------	------	-------	-----------------------------------------------"+CHAR(10)+ 
	"-- "+convert(nvarchar(100), getdate(), 106)+"		RFCxxx	1	Procedure created"+CHAR(10)+
	+CHAR(10)+
	"SET CONCAT_NULL_YIELDS_NULL OFF"+CHAR(10)+
	"-- Row counts required by the data adapter"+CHAR(10)+
	"SET NOCOUNT OFF"+CHAR(10)+
	"-- Reset so that next procedure gets the default."+CHAR(10)+ 
	"SET ANSI_NULLS ON"+CHAR(10)+
	+CHAR(10)+
	"Declare @nErrorCode		int"+CHAR(10)+
	"Declare @sSQLString 		nvarchar(4000)"+CHAR(10)+
	"Declare @sUpdateString 	nvarchar(4000)"+CHAR(10)+
	"Declare @sWhereString		nvarchar(4000)"+CHAR(10)+
	"Declare @sComma		nchar(1)"+CHAR(10)+
	"Declare @sAnd			nchar(5)"+CHAR(10)+
	+CHAR(10)+
	"-- Initialise variables"+CHAR(10)+
	"Set @nErrorCode = 0"+CHAR(10)+
	"Set @sAnd = ' and ' "+CHAR(10)+
	'Set @sWhereString = CHAR(10)+" where "'+CHAR(10)+
	+CHAR(10)+
	"If @nErrorCode = 0"+CHAR(10)+
	"Begin"+CHAR(10)+
	'	Set @sUpdateString = "Update ' + @sTableName + CHAR(10) + 
	'			   set "' + CHAR(10)

	Set @sSQLFromWhere = 	'	Set @sSQLString = @sUpdateString + @sWhereString'+CHAR(10)+
				+CHAR(10)+
				'	exec @nErrorCode=sp_executesql @sSQLString,'+CHAR(10)+
				'			      	N''' 

	Set @sEndOfProcedure = 
	+CHAR(10)+
	+CHAR(10)+
	"End" + CHAR(10) +
	+ CHAR(10) +
	"Return @nErrorCode" + CHAR(10) +
	"GO" + CHAR(10) +
	+ CHAR(10) +
	"Grant execute on dbo."+@sPrefix+"_Update"+@sInternalName+" to public" + CHAR(10) +
	"GO"
End

-- Output the template for the 'Update' procedure
If @nErrorCode = 0
Begin
	insert into @tbResult (ResultString)
	Select @sSQLCreate

	-- 'Fetch' parameters
	insert into @tbResult (ResultString)
	Select  '	' + 
		DC.ParameterPrefix + 
		DC.PropertyName + 
		'	' + 
		'	' + 
		DC.DataType + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN '	'  + '-- Mandatory'
			ELSE ',	'  + '-- Mandatory'	
		END	
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1 
	or    DC.IsPrimaryKey = 1	
	UNION ALL	
	-- New values parameters
	Select  '	' + 
		DC.ParameterPrefix + 
		DC.PropertyName +
		'	' + 
		DC.DataType + 
		'	' + 
		'	' + ' = null,'
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0	
	UNION ALL		
	-- Old values parameters
	Select  '	' + 
		DC.ParameterPrefix + 'Old' + 
		DC.PropertyName +
		'	' + 
		DC.DataType + 
		'	' + 
		'	' + ' = null,'
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0
	UNION ALL	
	-- 'InUse' parameters
	Select  '	' + 
		'@pb' + 'Is' + DC.PropertyName + 'InUse' + 
		'	' + 
		'	' + 'bit' +
		'	' + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN ' = 0'
			ELSE ' = 0,'
		END	
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0 
	and   DC.IsPrimaryKey = 0	

	insert into @tbResult (ResultString)
	Select @sSQLVariables	

	-- Assemble primary keys for the 'where' clause
	insert into @tbResult (ResultString)
	Select  '	' + 'Set @sWhereString = @sWhereString+CHAR(10)+"'

	insert into @tbResult (ResultString)
	Select  '	' + 
		'	' + 
		ColumnName + ' = ' + ParameterPrefix + PropertyName + 
		CASE	WHEN IsLastPrimaryKeyColumn = 0
			THEN ' and'
		END
	from    @tblDatabaseColumns
	where   IsPrimaryKey = 1

	insert into @tbResult (ResultString)
	Select '"' + CHAR(10)

	insert into @tbResult (ResultString)
	Select  '	' + 'If @pbIs' + PropertyName + 'InUse = 1'+CHAR(10)+ 
		'	' + 'Begin'+CHAR(10)+ 
		'	' + '	Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"'+ColumnName+" = "+ParameterPrefix+PropertyName+'"'+CHAR(10)+ 		
		'	' + '	Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"'
			  + CASE WHEN DataType = 'ntext' 
				 THEN 'dbo.fn_IsNtextEqual('+ColumnName+', '+ParameterPrefix+'Old'+PropertyName+') = 1' 
				 ELSE ColumnName+" = "+ParameterPrefix+'Old'+PropertyName 
			    END+'"'+CHAR(10)+ 
		'	' + '	Set @sComma = ","'+CHAR(10)+ 
		'	' + 'End' +CHAR(10)			
	from    @tblDatabaseColumns
	where IsIdentityColumn = 0
	and   IsPrimaryKey = 0
	order by OrdinalPosition

	insert into @tbResult (ResultString)
	Select @sSQLFromWhere	

	-- Declaration of parameters for sp_executesql
	insert into @tbResult (ResultString)
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + 
		DC.PropertyName + 
		'	' + 
		'	' + 
		DC.DataType + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN ''','
			ELSE ','
		END	
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1 
	or    DC.IsPrimaryKey = 1	
	UNION ALL	
	-- New values parameters
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + 
		DC.PropertyName +
		'	' + 
		'	' + 
		DC.DataType + ','
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0		
	UNION ALL		
	-- Old values parameters
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + 'Old' + 
		DC.PropertyName +
		'	' + 
		'	' + 
		DC.DataType + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN ''','
			ELSE ','
		END	
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0	

	-- Submitting parameters to the sp_executesql
	insert into @tbResult (ResultString)
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + DC.PropertyName + 
		'	' +
		' = ' +     
		DC.ParameterPrefix + DC.PropertyName + 
		CASE 	WHEN DC.IsLastColumn = 0
			THEN ','		
		END 		
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1 
	or    DC.IsPrimaryKey = 1	
	UNION ALL	
	-- New values parameters
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + DC.PropertyName + 
		'	' +
		' = ' +     
		DC.ParameterPrefix + DC.PropertyName + 
		','		
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0	
	UNION ALL		
	-- Old values parameters
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + 'Old' + DC.PropertyName +
		'	' +
		' = ' + 
		DC.ParameterPrefix + 'Old' + DC.PropertyName +
		CASE 	WHEN DC.IsLastColumn = 0
			THEN ','		
		END	
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0			
	
	insert into @tbResult (ResultString)
	Select @sEndOfProcedure
End

-- Assemble static building blocks of the Delete template
If @nErrorCode = 0
Begin
	Set @sSQLCreate = 
	"-----------------------------------------------------------------------------------------------------------------------------"+CHAR(10)+
	"-- Creation of "+@sPrefix+"_Delete"+@sInternalName+"									      "+CHAR(10)+
	"-----------------------------------------------------------------------------------------------------------------------------"+CHAR(10)+
	"If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].["+@sPrefix+"_Delete"+@sInternalName+"]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)"+CHAR(10)+
	"Begin"+CHAR(10)+
	"	Print '**** Drop Stored Procedure dbo."+@sPrefix+"_Delete"+@sInternalName+".'"+CHAR(10)+
	"	Drop procedure [dbo].["+@sPrefix+"_Delete"+@sInternalName+"]"+CHAR(10)+
	"End"+CHAR(10)+
	"Print '**** Creating Stored Procedure dbo."+@sPrefix+"_Delete"+@sInternalName+"...'"+CHAR(10)+
	"Print ''"+CHAR(10)+
	"GO"+CHAR(10)+
	+CHAR(10)+
	"SET QUOTED_IDENTIFIER OFF"+CHAR(10)+
	"GO"+CHAR(10)+
	"-- Allow comparison of null values."+CHAR(10)+
	"-- Procedure uses setting in place before it's created."+CHAR(10)+ 
	"SET ANSI_NULLS OFF"+CHAR(10)+
	"GO"+CHAR(10)+
	+CHAR(10)+
	+CHAR(10)+
	"CREATE PROCEDURE dbo."+@sPrefix+"_Delete"+@sInternalName+CHAR(10)+
	"("+CHAR(10)+
	"	@pnUserIdentityId	int,		-- Mandatory"+CHAR(10)+
	"	@psCulture		nvarchar(10) 	= null,"+CHAR(10)+
	"	@pbCalledFromCentura	bit		= 0,"


	Set @sSQLVariables = 
	")"+CHAR(10)+
	"as"+CHAR(10)+
	"-- PROCEDURE:	"+@sPrefix+"_Delete"+@sInternalName+CHAR(10)+
	"-- VERSION:	1"+CHAR(10)+
	"-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited"+CHAR(10)+
	"-- DESCRIPTION:	Delete "+@sInternalName+" if the underlying values are as expected."+CHAR(10)+
	+CHAR(10)+
	"-- MODIFICATIONS :"+CHAR(10)+
	"-- Date		Who	Change	Version	Description"+CHAR(10)+
	"-- -----------	-------	------	-------	-----------------------------------------------"+CHAR(10)+ 
	"-- "+convert(nvarchar(100), getdate(), 106)+"		RFCxxx	1	Procedure created"+CHAR(10)+
	+CHAR(10)+
	"SET CONCAT_NULL_YIELDS_NULL OFF"+CHAR(10)+
	"-- Row counts required by the data adapter"+CHAR(10)+
	"SET NOCOUNT OFF"+CHAR(10)+
	"-- Reset so that next procedure gets the default."+CHAR(10)+ 
	"SET ANSI_NULLS ON"+CHAR(10)+
	+CHAR(10)+
	"Declare @nErrorCode		int"+CHAR(10)+
	"Declare @sSQLString 		nvarchar(4000)"+CHAR(10)+
	"Declare @sDeleteString		nvarchar(4000)"+CHAR(10)+
	"Declare @sAnd			nchar(5)"+CHAR(10)+
	+CHAR(10)+
	"-- Initialise variables"+CHAR(10)+
	"Set @nErrorCode = 0"+CHAR(10)+
	"Set @sAnd = ' and ' "+CHAR(10)+
	+CHAR(10)+
	"If @nErrorCode = 0"+CHAR(10)+
	"Begin"+CHAR(10)+
	'	Set @sDeleteString = "Delete from ' + @sTableName + CHAR(10) + 
	'			   where "' + CHAR(10)

	Set @sSQLFromWhere = 	'	exec @nErrorCode=sp_executesql @sDeleteString,'+CHAR(10)+
				'			      	N''' 

	Set @sExecuteSQL = "	" + "exec @nErrorCode=sp_executesql @sSQLString," + CHAR(10) +
			   "			N'"

	Set @sEndOfProcedure = 
	+CHAR(10)+
	+CHAR(10)+
	"End" + CHAR(10) +
	+ CHAR(10) +
	"Return @nErrorCode" + CHAR(10) +
	"GO" + CHAR(10) +
	+ CHAR(10) +
	"Grant execute on dbo."+@sPrefix+"_Delete"+@sInternalName+" to public" + CHAR(10) +
	"GO"
End

-- Output the template for the 'Update' procedure
If @nErrorCode = 0
Begin
	insert into @tbResult (ResultString)
	Select @sSQLCreate

	-- 'Fetch' parameters
	insert into @tbResult (ResultString)
	Select  '	' + 
		DC.ParameterPrefix + 
		DC.PropertyName + 
		'	' + 
		'	' + 
		DC.DataType + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN '	'  + '-- Mandatory'
			ELSE ',	'  + '-- Mandatory'
		END	
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1 
	or    DC.IsPrimaryKey = 1	
	UNION ALL		
	-- Old values parameters
	Select  '	' + 
		DC.ParameterPrefix + 'Old' + 
		DC.PropertyName +
		'	' + 
		DC.DataType + 
		'	' + 
		'	' + ' = null,'
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0
	UNION ALL	
	-- 'InUse' parameters
	Select  '	' + 
		'@pb' + 'Is' + DC.PropertyName + 'InUse' + 
		'	' + 
		'	' + 'bit' +
		'	' + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN ' = 0'
			ELSE ' = 0,'
		END	
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0 
	and   DC.IsPrimaryKey = 0	

	insert into @tbResult (ResultString)
	Select @sSQLVariables	

	-- Add primary key columns to the 'where' clause first:
	insert into @tbResult (ResultString)
	Select  '	' + 'Set @sDeleteString = @sDeleteString+CHAR(10)+"'

	insert into @tbResult (ResultString)
	Select  '	' + 
		'	' + 
		ColumnName + ' = ' + ParameterPrefix + PropertyName + 
		CASE	WHEN IsLastPrimaryKeyColumn = 0
			THEN ' and '
		END
	from    @tblDatabaseColumns
	where   IsPrimaryKey = 1

	insert into @tbResult (ResultString)
	Select '"' + CHAR(10)

	insert into @tbResult (ResultString)
	Select  '	' + 'If @pbIs' + PropertyName + 'InUse = 1'+CHAR(10)+ 
		'	' + 'Begin'+CHAR(10)+
		'	' + '	Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"'
			  + CASE WHEN DataType = 'ntext' 
				 THEN 'dbo.fn_IsNtextEqual('+ColumnName+', '+ParameterPrefix+'Old'+PropertyName+') = 1' 
				 ELSE ColumnName+" = "+ParameterPrefix+'Old'+PropertyName 
			    END+'"'+CHAR(10)+ 
		'	' + 'End' + CHAR(10) 	
	from    @tblDatabaseColumns
	where IsIdentityColumn = 0
	and   IsPrimaryKey = 0
	order by OrdinalPosition

	insert into @tbResult (ResultString)
	Select @sSQLFromWhere	

	-- Declaration of parameters for sp_executesql
	insert into @tbResult (ResultString)
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + 
		DC.PropertyName + 
		'	' + 
		'	' + 
		DC.DataType + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN ''','
			ELSE ','
		END	
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1 
	or    DC.IsPrimaryKey = 1	
	UNION ALL		
	-- Old values parameters
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + 'Old' + 
		DC.PropertyName +
		'	' + 
		'	' + 
		DC.DataType + 
		CASE 	WHEN DC.IsLastColumn = 1
			THEN ''','
			ELSE ','
		END	
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0	

	-- Submitting parameters to the sp_executesql
	insert into @tbResult (ResultString)
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + DC.PropertyName + 
		'	' +
		' = ' +     
		DC.ParameterPrefix + DC.PropertyName + 
		CASE 	WHEN DC.IsLastColumn = 0
			THEN ','		
		END		
	from @tblDatabaseColumns DC			
	where DC.IsFetchColumn = 1 
	or    DC.IsPrimaryKey = 1	
	UNION ALL		
	-- Old values parameters
	Select  '	' + 
		'	' +
		'	' +
		DC.ParameterPrefix + 'Old' + DC.PropertyName +
		'	' +
		' = ' + 
		DC.ParameterPrefix + 'Old' + DC.PropertyName +
		CASE 	WHEN DC.IsLastColumn = 0
			THEN ','		
		END	
	from @tblDatabaseColumns DC	
	where DC.IsFetchColumn = 0	
	and   DC.IsPrimaryKey = 0			
	
	insert into @tbResult (ResultString) 
	Select @sEndOfProcedure
End

-- Output the templates
If @nErrorCode = 0
Begin
	Select ResultString as ' '
	from @tbResult
	order by LineNumber
End

Return @nErrorCode
GO

Grant execute on dbo.util_GenerateProcedureTemplates to public
GO
