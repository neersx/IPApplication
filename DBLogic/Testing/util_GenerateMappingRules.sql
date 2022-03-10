-----------------------------------------------------------------------------------------------------------------------------
-- Creation of util_GenerateMappingRules
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[util_GenerateMappingRules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.util_GenerateMappingRules.'
	Drop procedure [dbo].[util_GenerateMappingRules]
End
Print '**** Creating Stored Procedure dbo.util_GenerateMappingRules...'
Print ''
GO


SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.util_GenerateMappingRules
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@ptXMLRules		ntext
)
as
-- PROCEDURE:	util_GenerateMappingRules
-- VERSION:	2
-- DESCRIPTION:	An internal stored procedure to generate scripting for 
--		mapping rules from XML input.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07-Sep-2004	JEK		1	Procedure created
-- 16-Jan-2007	MLE		2	Changed use of CHAR(10) to CHAR(13) + CHAR(10)


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
Declare @sRFC 			nvarchar(10)
Declare @sComment		nvarchar(254)
Declare @idoc 			int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument		
Declare @CRLF			char(2)		-- Declare standard string 

-- Holds unencrypted ValidObjects
declare @tblInternal table(
	ENTRYID		int identity(-1,-1),
	STRUCTUREID	nvarchar(10),
	DATASOURCEID	nvarchar(10),
	INPUTCODE	nvarchar(50),
	INPUTDESCRIPTION nvarchar(254),
	INPUTSCHEMEID	nvarchar(10),
	INPUTENCODED	nvarchar(50),
	OUTPUTSCHEMEID	nvarchar(10),
	OUTPUTENCODED	nvarchar(50),
	OUTPUTVALUE	nvarchar(50),
	ISNOTAPPLICABLE nchar(1)
	)
declare @nLastMappingKey int

-- Initialise variables
Set @nErrorCode = 0
Set @CRLF = char(13) + char(10)

If @nErrorCode = 0
Begin

	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLRules
	
	Select 	@sRFC 			= ChangeReference,
		@sComment		= Comment
	from	OPENXML (@idoc, '/Rules',2)
		WITH (
		      ChangeReference		nvarchar(10)	'ChangeReference/text()',
		      Comment			nvarchar(254)	'Comment/text()'
		     )

	set @nErrorCode = @@ERROR

	-- print 'RFC = '+@sRFC
	-- print 'Comment = '+@sComment

End

-- Last Mapping Key
If @nErrorCode = 0
Begin
	select @nLastMappingKey = LastMappingKey
	from OPENXML (@idoc, '/Rules',2)
		WITH (
		      LastMappingKey		int	'LastMappingKey/text()'
		     )

End

--	Mapping

If @nErrorCode = 0
and exists(select 1 from OPENXML (@idoc, '/Rules/Mapping[descendant::text()]',2))
Begin
	insert into @tblInternal 
		(STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,
		INPUTSCHEMEID,INPUTENCODED, OUTPUTSCHEMEID,OUTPUTENCODED,OUTPUTVALUE,ISNOTAPPLICABLE)
	select X.StructureID, DS.DATASOURCEID,InputCode,InputDescription,
		IES.SCHEMEID, upper(InputEncodedCode), OES.SCHEMEID,
		upper(OutputEncodedCode),OutputValue, cast(isnull(IsNotApplicable,0) as char(1))
	from	OPENXML (@idoc, '/Rules/Mapping',2)
		WITH (
		      StructureID		nvarchar(10)	'StructureID/text()',
		      DataSourceCode		nvarchar(20)	'DataSourceCode/text()',
		      InputCode			nvarchar(50)	'InputCode/text()',
		      InputDescription		nvarchar(254)	'InputDescription/text()',
		      InputSchemeCode		nvarchar(20)	'InputEncoded/SchemeCode/text()',
		      InputEncodedCode		nvarchar(50)	'InputEncoded/Code/text()',
		      OutputSchemeCode		nvarchar(20)	'OutputEncoded/SchemeCode/text()',
		      OutputEncodedCode		nvarchar(50)	'OutputEncoded/Code/text()',
		      OutputValue		nvarchar(50)	'OutputValue/text()',
		      IsNotApplicable		bit		'IsNotApplicable/text()'
		     ) X
	left join EXTERNALSYSTEM EX	on (EX.SYSTEMCODE=upper(DataSourceCode) collate database_default)
	left join DATASOURCE DS		on (DS.SYSTEMID=EX.SYSTEMID)
	left join ENCODINGSCHEME IES	on (IES.SCHEMECODE=upper(InputSchemeCode) collate database_default)
	left join ENCODINGSCHEME OES	on (OES.SCHEMECODE=upper(OutputSchemeCode) collate database_default) 

	set @nErrorCode = @@ERROR
End

-- deallocate the xml document handle when finished.
exec sp_xml_removedocument @idoc

If @nErrorCode = 0
Begin

	Select
"    	/**********************************************************************************************************/"+@CRLF+
"    	/*** "+@sRFC+" "+@sComment+" - Mapping							***/"+@CRLF+
"	/**********************************************************************************************************/"+@CRLF+
"	SET IDENTITY_INSERT MAPPING ON"+@CRLF+
"	go"+@CRLF

select
"	If NOT exists (select * from MAPPING WHERE ENTRYID="+cast(ENTRYID+@nLastMappingKey as nvarchar)+")"+@CRLF+
"	and NOT exists (select * from MAPPING M"+@CRLF+
case when INPUTENCODED is not null then
"			 left join ENCODEDVALUE IEV	on (IEV.SCHEMEID="+INPUTSCHEMEID+@CRLF+
"							and IEV.STRUCTUREID="+STRUCTUREID+@CRLF+
"							AND IEV.CODE="+dbo.fn_WrapQuotes(INPUTENCODED,0,0)+")" +@CRLF END+
"			where DATASOURCEID"+	case when DATASOURCEID 		is null then ' is null' else "="+DATASOURCEID end+" and"+@CRLF+
"			INPUTCODE"+		case when INPUTCODE 		is null then ' is null' else "="+dbo.fn_WrapQuotes(INPUTCODE,0,0) end+" and"+@CRLF+
"			INPUTDESCRIPTION"+	case when INPUTDESCRIPTION 	is null then ' is null' else "="+dbo.fn_WrapQuotes(INPUTDESCRIPTION,0,0) end+" and"+@CRLF+
"			INPUTCODEID"+		case when INPUTENCODED 		is null then ' is null' else "=IEV.CODEID" end+@CRLF+
"			)"+@CRLF+

"        	BEGIN"+@CRLF+
"         	 PRINT '**** "+@sRFC+" Adding data MAPPING.ENTRYID = "+cast(ENTRYID+@nLastMappingKey as nvarchar)+"'"+@CRLF+
"		 INSERT INTO MAPPING (ENTRYID,STRUCTUREID,DATASOURCEID,INPUTCODE,INPUTDESCRIPTION,INPUTCODEID,OUTPUTCODEID,OUTPUTVALUE,ISNOTAPPLICABLE)"+@CRLF+
"		 SELECT "+cast(ENTRYID+@nLastMappingKey as nvarchar)+",M.STRUCTUREID,"+
			case when DATASOURCEID 		is null then 'null' else DATASOURCEID end+","+
			case when INPUTCODE 		is null then 'null' else dbo.fn_WrapQuotes(INPUTCODE,0,0) end+","+
			case when INPUTDESCRIPTION 	is null then 'null' else dbo.fn_WrapQuotes(INPUTDESCRIPTION,0,0) end+","+
			case when INPUTENCODED 		is null then 'null' else "IEV.CODEID" end+","+
			case when OUTPUTENCODED		is null then 'null' else "OEV.CODEID" end+","+
			case when OUTPUTVALUE 		is null then 'null' else dbo.fn_WrapQuotes(OUTPUTVALUE,0,0) end+","+
			ISNOTAPPLICABLE+@CRLF+
"		 from MAPSTRUCTURE M"+@CRLF+
case when INPUTENCODED is not null then
"		 left join ENCODEDVALUE IEV	on (IEV.SCHEMEID="+INPUTSCHEMEID+@CRLF+
"						and IEV.STRUCTUREID=M.STRUCTUREID"+@CRLF+
"						AND IEV.CODE="+dbo.fn_WrapQuotes(INPUTENCODED,0,0)+")" +@CRLF END+
case when OUTPUTENCODED is not null then
"		 left join ENCODEDVALUE OEV	on (OEV.SCHEMEID="+OUTPUTSCHEMEID+@CRLF+
"						and OEV.STRUCTUREID=M.STRUCTUREID"+@CRLF+
"						AND OEV.CODE="+dbo.fn_WrapQuotes(OUTPUTENCODED,0,0)+")" +@CRLF END+
"		 where M.STRUCTUREID="+STRUCTUREID+@CRLF+
"        	 PRINT '**** "+@sRFC+" Data successfully added to MAPPING table.'"+@CRLF+
"		 PRINT ''"+@CRLF+
"         	END"+@CRLF+
"    	ELSE"+@CRLF+
"         	PRINT '**** "+@sRFC+" MAPPING for ENTRYID = "+cast(ENTRYID+@nLastMappingKey as nvarchar)+" already exists'"+@CRLF+
"         	PRINT ''"+@CRLF+
"    	go"+@CRLF
	from @tblInternal 

	select
"	SET IDENTITY_INSERT MAPPING OFF"+@CRLF+
"	go"+@CRLF

End



Return @nErrorCode
GO

Grant execute on dbo.util_GenerateMappingRules to public
GO
