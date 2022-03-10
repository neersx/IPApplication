-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_GenerateMappedValuesXML 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GenerateMappedValuesXML]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.biw_GenerateMappedValuesXML.'
	drop procedure dbo.biw_GenerateMappedValuesXML
end
print '**** Creating procedure dbo.biw_GenerateMappedValuesXML...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.biw_GenerateMappedValuesXML	
		@pnUserIdentityId		int,			-- Mandatory
		@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
		@pbCalledFromCentura		int		= 0,
		@pnBillFormatKey		int,
		@pnEntityKey			int,
		@pnMainDebtorKey		int,
		@pnMainCaseKey			int		= null,
		@pnQueryContextKey		int		= 460,	-- The key for the context of the query (default output requests).
		@ptXMLBillLines		nvarchar(max)		-- The filtering to be performed on the result set.		
as
---PROCEDURE :	biw_GenerateMappedValuesXML
-- VERSION :	3
-- DESCRIPTION:	A procedure that returns all of the mapped bill line details required for an e-bill.

-- MODIFICATION
-- Date		Who	No	Version	Description
-- ====         ===	=== 	=======	=====================================================================
-- 29 Jul 2010	AT	9556	1	Procedure created starting from a copy of xml_GetDebitNoteMappedCodes
-- 01 Sep 2010	AT	9556	2	Add collate_database_default to temp table nvarchar cols.
-- 11 Nov 2010	AT	9940	3	Fix best fit for staff classification.

		
set nocount on
set concat_null_yields_null off

Declare	@idoc 			int		-- Document handle of the XML document in memory that is created by sp_xml_preparedocument.		
Declare	@ErrorCode		int
Declare	@nRowCount		int	
Declare	@nOutRequestsRowCount	int
Declare @nCount			int

Declare	@sSelectBillLines	nvarchar(4000)
Declare	@sOrderBillLines	nvarchar(4000)
Declare	@sSQLString		nvarchar(max)

Declare	@hDocument 		int 		-- handle to the XML parameter which is the Activity Request row
Declare	@nPresentationId	int		-- the Presentation that holds the columns to be extracted
Declare	@nMapProfileId		int		-- The profile used to determine the mapping of codes.
Declare	@nFieldCode		int		-- User defined field to be extracted from mapping

Declare @nRowNumber		int
Declare	@sColumn   		nvarchar(100)
Declare	@sPublishName 		nvarchar(100)

Declare @bDebug	bit

Set @bDebug = 0

Declare @sLookupCulture		nvarchar(10)
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)	

Set @ErrorCode = 0

-------------------------------------------------
-- Get the PresentationId associated with the
-- Bill Format Profile. This will be used to get 
-- the columns to be extracted.
-------------------------------------------------
If  @ErrorCode = 0
Begin
	Set @sSQLString="
	Select	@nPresentationId = F.PRESENTATIONID,
		@nMapProfileId   = N.BILLMAPPROFILEID
	from BILLFORMAT B
	left join FORMATPROFILE F	on (F.FORMATID=B.FORMATPROFILEID),
	IPNAME N
	where B.BILLFORMATID = @pnBillFormatKey
	AND N.NAMENO = @pnMainDebtorKey"

	Exec @ErrorCode=sp_executesql @sSQLString,
		N'@nPresentationId	int			OUTPUT,
		  @nMapProfileId	int			OUTPUT,
		  @pnBillFormatKey		int,
		  @pnMainDebtorKey		int',
		  @nPresentationId	= @nPresentationId	OUTPUT,
		  @nMapProfileId	= @nMapProfileId	OUTPUT,
		  @pnBillFormatKey	= @pnBillFormatKey,
		  @pnMainDebtorKey 	= @pnMainDebtorKey
End

If @ErrorCode = 0
Begin	
	Create table #TEMPBILLLINES (
			BILLLINENO INT,
			WIPCODE	NVARCHAR(6) collate database_default NULL,
			WIPTYPEID NVARCHAR(6) collate database_default NULL,
			CATEGORYCODE NVARCHAR(3) collate database_default NULL,
			NARRATIVECODE INT NULL,
			STAFFKEY int NULL)
End

--If @ErrorCode = 0
--Begin
--	Create table #TEMPRETURNBILLLINES (
--			BillLineNo	int,
--			FieldName	nvarchar(50), -- QUERYCOLUMN.COLUMNLABEL
--			MappedValue	nvarchar(254) -- BILLMAPRULE.MAPPEDVALUE
--			)
--End


-------------------------------------------------
-- Collect the criteria for Bill line mapping
-------------------------------------------------
If @ErrorCode = 0
Begin	
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @ptXMLBillLines
	Set 	@ErrorCode = @@Error
End

If @ErrorCode = 0
Begin
	Set @sSQLString="
	INSERT INTO #TEMPBILLLINES (BILLLINENO, WIPCODE, WIPTYPEID, CATEGORYCODE, NARRATIVECODE, STAFFKEY)
	SELECT BillLineNo, WIPCode, WIPTypeId, WIPCategory, NarrativeCode, StaffKey
	from openxml(@hDocument,'BillLines/BillLine',2)
	with (BillLineNo	int		'BillLineNo',
		WIPCode		nvarchar(6)	'WIPCode',
		WIPTypeId	nvarchar(6)	'WIPTypeId',
		WIPCategory	nvarchar(3)	'WIPCategory',
		NarrativeCode	int		'NarrativeCode',
		StaffKey	int		'StaffKey'	
		)"
	Exec @ErrorCode=sp_executesql @sSQLString,
		N'@hDocument		int',
		  @hDocument 		= @hDocument
End


If @ErrorCode = 0
Begin		
	Declare @tblOutputRequests table (
 		ROWNUMBER		int 		identity(1,1),
		ID			nvarchar(100)	collate database_default not null,
		SORTORDER		tinyint		null,
		SORTDIRECTION		nvarchar(1)	collate database_default null,
		PUBLISHNAME		nvarchar(100)	collate database_default null,
		QUALIFIER		nvarchar(100)	collate database_default null,				
		DOCITEMKEY		int		null,
		PROCEDURENAME		nvarchar(50)	collate database_default null,
		DATAFORMATID		int 		null,
		DATATYPE		nvarchar(20)	collate database_default null,
		FIELDCODE		int		null,
		DISPLAYSEQUENCE		int		null
	 	)
End

If  @nPresentationId is not null
and @nMapProfileId is not null
and @ErrorCode=0
Begin
	set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)	

	If @sLookupCulture is not null
	and dbo.fn_GetTranslatedTIDColumn('QUERYCOLUMN','COLUMNLABEL') is not null
	Begin
		-----------------------
		-- Translation required
		-----------------------
		Insert into @tblOutputRequests (ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, DATATYPE, FIELDCODE, DISPLAYSEQUENCE)
		select 	Distinct
			DI.PROCEDUREITEMID,
			T.SORTORDER,
			T.SORTDIRECTION,
			CAST(dbo.fn_GetTranslation(C.COLUMNLABEL,null,C.COLUMNLABEL_TID,@sLookupCulture) as nvarchar(100)),
			C.QUALIFIER,
			C.DOCITEMID,
			DI.PROCEDURENAME,
			DI.DATAFORMATID,
			CASE(DI.DATAFORMATID)
				WHEN(9100) THEN 'nvarchar(255)'
				WHEN(9101) THEN 'int'
				WHEN(9102) THEN 'decimal(11,'+convert(varchar,isnull(DI.DECIMALPLACES,0))+')'
				WHEN(9103) THEN 'datetime'
				WHEN(9104) THEN 'datetime'
				WHEN(9105) THEN 'datetime'
				WHEN(9106) THEN 'bit'
				WHEN(9107) THEN 'text'
				WHEN(9108) THEN 'decimal(11,2)'
				WHEN(9109) THEN 'decimal(11,2)'
				WHEN(9110) THEN 'int'
				WHEN(9111) THEN 'image'
				WHEN(9112) THEN 'nvarchar(100)'
				WHEN(9113) THEN 'nvarchar(100)'
			END,
			TC.TABLECODE,
			T.DISPLAYSEQUENCE
		from QUERYPRESENTATION P
		join QUERYCONTENT T		on (T.PRESENTATIONID = P.PRESENTATIONID)
		join QUERYCOLUMN C		on (C.COLUMNID = T.COLUMNID)
		join QUERYDATAITEM DI		on (DI.DATAITEMID = C.DATAITEMID)
		left join TABLECODES TC		on (TC.TABLETYPE=-500
						and TC.DESCRIPTION=C.COLUMNLABEL)
		WHERE P.PRESENTATIONID = @nPresentationId
		and DI.PROCEDUREITEMID = 'BillMapping'
		order by T.DISPLAYSEQUENCE
	
		Select @nOutRequestsRowCount = @@RowCount,
		       @ErrorCode = @@Error
	End
	Else Begin
		-----------------------
		-- No Translation
		-----------------------
		Insert into @tblOutputRequests(ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, DATATYPE, FIELDCODE, DISPLAYSEQUENCE)
		select 	Distinct
			DI.PROCEDUREITEMID,
			T.SORTORDER,
			T.SORTDIRECTION,
			C.COLUMNLABEL,
			C.QUALIFIER,
			C.DOCITEMID,
			DI.PROCEDURENAME,
			DI.DATAFORMATID,
			CASE(DI.DATAFORMATID)
				WHEN(9100) THEN 'nvarchar(255)'
				WHEN(9101) THEN 'int'
				WHEN(9102) THEN 'decimal(11,'+convert(varchar,isnull(DI.DECIMALPLACES,0))+')'
				WHEN(9103) THEN 'datetime'
				WHEN(9104) THEN 'datetime'
				WHEN(9105) THEN 'datetime'
				WHEN(9106) THEN 'bit'
				WHEN(9107) THEN 'text'
				WHEN(9108) THEN 'decimal(11,2)'
				WHEN(9109) THEN 'decimal(11,2)'
				WHEN(9110) THEN 'int'
				WHEN(9111) THEN 'image'
				WHEN(9112) THEN 'nvarchar(100)'
				WHEN(9113) THEN 'nvarchar(100)'
			END,
			TC.TABLECODE,
			T.DISPLAYSEQUENCE
		from QUERYPRESENTATION P
		join QUERYCONTENT T		on (T.PRESENTATIONID = P.PRESENTATIONID)
		join QUERYCOLUMN C		on (C.COLUMNID = T.COLUMNID)
		join QUERYDATAITEM DI		on (DI.DATAITEMID = C.DATAITEMID)
		left join TABLECODES TC		on (TC.TABLETYPE=-500
						and TC.DESCRIPTION=C.COLUMNLABEL)
		WHERE P.PRESENTATIONID = @nPresentationId
		and DI.PROCEDUREITEMID = 'BillMapping'
		order by T.DISPLAYSEQUENCE
	
		Select @nOutRequestsRowCount = @@RowCount,
		       @ErrorCode = @@Error
	End
End

If @ErrorCode=0 and @nMapProfileId is not null
Begin
	-------------------
	-- #TEMPBILLLINES
	-------------------
	Select @sSelectBillLines=isnull(@sSelectBillLines,'')+CASE WHEN(@sSelectBillLines is NOT NULL) THEN ',' ELSE '' END 
							     + '['+PUBLISHNAME+']'
	from @tblOutputRequests
	where ID = 'BillMapping'
	order by ROWNUMBER

	Set @ErrorCode=@@Error

	If @ErrorCode=0
	Begin
		----------------------------------
		-- Assemble the "Order By" clause.
		----------------------------------
		Select @sOrderBillLines=isnull(@sOrderBillLines,'')+CASE WHEN(@sOrderBillLines is not null) THEN ','     ELSE ''                   END 			
								   +CASE WHEN(PUBLISHNAME   is null)        THEN ID      ELSE  '['+PUBLISHNAME+']' END
								   +CASE WHEN SORTDIRECTION = 'A'           THEN ' ASC ' ELSE ' DESC '             END
		from @tblOutputRequests
		where DATATYPE not in ('text','ntext') 
		AND ID = 'BillMapping'
		order by SORTORDER

		Set @ErrorCode=@@Error
	End
End

-----------------------------------------
-- Any user defined columns associated
-- with a Bill Mapping rules are to be 
-- added to the TEMPCASEDETAILS table.
-- A Mapping Profile is required.
----------------------------------------
If @ErrorCode=0
and @nMapProfileId is not null
Begin
	-----------------------------------------------
	-- Generate the ALTER TABLE statement to add 
	-- the user defined columns to #TEMPBILLLINES
	-----------------------------------------------
	Set @sSQLString=null

	select @sSQLString=ISNULL(NULLIF(@sSQLString + ','+char(10), ','+char(10)),'') 
			   + '['+PUBLISHNAME+']'+CHAR(9)+DATATYPE+CASE WHEN(DATATYPE like '%char%') THEN ' collate database_default' END+' NULL'
	from @tblOutputRequests
	where ID='BillMapping'

	Set @ErrorCode=@@Error

	If @ErrorCode=0
	and @sSQLString is not null
	Begin
		set @sSQLString='Alter table #TEMPBILLLINES Add '+@sSQLString

		exec(@sSQLString)
		Set @ErrorCode=@@Error
	End
End

-------------------------------------------------
--
--    Translate the codes using the mapping rules
--
-------------------------------------------------
If  @nMapProfileId is not null
and @ErrorCode=0
Begin
	-----------------------------------------
	-- Loop through each user define column
	-- associated with the Bill Mapping rules
	-- and extract the data into the table
	-- #TEMPBILLLINES.
	-----------------------------------------
	
	If @ErrorCode=0
	Begin
		set @sColumn=null
		set @nRowNumber =0

		select	@sColumn    ='['+T.PUBLISHNAME+']',
			@nRowNumber =T.ROWNUMBER,
			@nFieldCode =T.FIELDCODE
		from @tblOutputRequests T
		join (	select min(ROWNUMBER) as ROWNUMBER
			from @tblOutputRequests
			where FIELDCODE is not null
			and ROWNUMBER>@nRowNumber) T1 
					on (T1.ROWNUMBER=T.ROWNUMBER)

		Set @ErrorCode=@@Error
	End

	------------------------------------------
	-- Now loop through each column associated
	-- with a Bill Mapping field and extract 
	-- the mapped value.
	------------------------------------------
	While @sColumn    is not null
	  and @nFieldCode is not null
	  and @ErrorCode=0
	Begin
		----------------------------------
		-- Update each user defined column
		-- with the mapped data defined 
		-- for that column.
		----------------------------------	
		Set @sSQLString="
		Update T
		Set "+@sColumn+"=
			       (SELECT 
				substring(
				max (    	
				CASE WHEN (B.WIPCODE       IS NULL) THEN '0' ELSE cast(len(B.WIPCODE)       as char(1)) END +	
				CASE WHEN (B.WIPTYPEID     IS NULL) THEN '0' ELSE cast(len(B.WIPTYPEID)     as char(1)) END +	
				CASE WHEN (B.WIPCATEGORY   IS NULL) THEN '0' ELSE '1' END +
				CASE WHEN (B.NARRATIVECODE IS NULL) THEN '0' ELSE cast(len(B.NARRATIVECODE) as char(1)) END +	
				CASE WHEN (B.STAFFCLASS    IS NULL) THEN '0' ELSE '1' END +
				CASE WHEN (B.ENTITYNO      IS NULL) THEN '0' ELSE '1' END +
				CASE WHEN (B.OFFICEID      IS NULL) THEN '0' ELSE '1' END +
				CASE WHEN (B.CASETYPE      IS NULL) THEN '0' ELSE '1' END +
				CASE WHEN (B.COUNTRYCODE   IS NULL) THEN '0' ELSE '1' END +
				CASE WHEN (B.PROPERTYTYPE  IS NULL) THEN '0' ELSE '1' END +
				CASE WHEN (B.CASECATEGORY  IS NULL) THEN '0' ELSE '1' END +
				CASE WHEN (B.SUBTYPE       IS NULL) THEN '0' ELSE '1' END +
				CASE WHEN (B.BASIS         IS NULL) THEN '0' ELSE '1' END +
				CASE WHEN (B.STATUS        IS NULL) THEN '0' ELSE '1' END +
				B.MAPPEDVALUE), 15,254)
				FROM BILLMAPRULES B 
				WHERE	B.BILLMAPPROFILEID	= @nMapProfileId
				AND	B.FIELDCODE		= @nFieldCode
				AND (	T.WIPCODE		like B.WIPCODE		 OR B.WIPCODE		IS NULL ) -- inexact partial match allowed
				AND (	T.WIPTYPEID		like B.WIPTYPEID	 OR B.WIPTYPEID		IS NULL ) -- inexact partial match allowed
				AND (	T.CATEGORYCODE		= B.WIPCATEGORY		 OR B.WIPCATEGORY	IS NULL )
				AND (	N.NARRATIVECODE		like B.NARRATIVECODE	 OR B.NARRATIVECODE	IS NULL ) -- inexact partial match allowed
				AND (	B.STAFFCLASS		= E.STAFFCLASS		 OR B.STAFFCLASS        IS NULL )
				AND (	B.ENTITYNO 		= @nEntityNo	 	 OR B.ENTITYNO	 	IS NULL ) 
				AND (	B.OFFICEID 		= C.OFFICEID	 	 OR B.OFFICEID	 	IS NULL ) 
				AND (	B.CASETYPE 		= C.CASETYPE	 	 OR B.CASETYPE	 	IS NULL ) 
				AND (	B.COUNTRYCODE 		= C.COUNTRYCODE 	 OR B.COUNTRYCODE 	IS NULL ) 
				AND (	B.PROPERTYTYPE 		= C.PROPERTYTYPE 	 OR B.PROPERTYTYPE 	IS NULL ) 
				AND (	B.CASECATEGORY 		= C.CASECATEGORY 	 OR B.CASECATEGORY 	IS NULL ) 
				AND (	B.SUBTYPE 		= C.SUBTYPE 		 OR B.SUBTYPE 		IS NULL )
				AND (	B.BASIS 		= P.BASIS 		 OR B.BASIS 		IS NULL )
				AND (	B.STATUS 		= C.STATUSCODE           OR B.STATUS		IS NULL )
				)
		From #TEMPBILLLINES T
		left join CASES C	on (C.CASEID = @pnMainCaseKey )
		left join PROPERTY P	on (P.CASEID=C.CASEID)
		left join NARRATIVE N	on (N.NARRATIVENO=T.NARRATIVECODE)
		left join EMPLOYEE E on (E.EMPLOYEENO = T.STAFFKEY)"
	
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nMapProfileId	int,
					  @nFieldCode		int,
					  @nEntityNo		int,
					  @pnMainCaseKey	int',
					  @nMapProfileId	=@nMapProfileId,
					  @nFieldCode		=@nFieldCode,
					  @nEntityNo		=@pnEntityKey,
					  @pnMainCaseKey	=@pnMainCaseKey
	
		If (@bDebug = 1)
		Begin
			print 'MAPPED VALUES for ' + @sColumn
		End
		
		-----------------------------------
		-- Get the next user defined column 
		-- for extraction of mapped data.
		-----------------------------------
		If @ErrorCode=0
		Begin
			set @sColumn   =null
			set @nFieldCode=null

			select  @sColumn   ='['+T.PUBLISHNAME+']',
				@nRowNumber=T.ROWNUMBER,
				@nFieldCode=T.FIELDCODE
			from @tblOutputRequests T
			join (	select min(ROWNUMBER) as ROWNUMBER
				from @tblOutputRequests
				where FIELDCODE is not null
				and ROWNUMBER>@nRowNumber) T1 on (T1.ROWNUMBER=T.ROWNUMBER)

			Set @ErrorCode=@@Error
		End
	End
End

if (@bDebug = 1)
Begin
	Select * from #TEMPBILLLINES
End

If @sSelectBillLines is not null
and @nMapProfileId is not null
and @ErrorCode=0
Begin
	Set @sSQLString="Select BILLLINENO as '@BillLineNo', " +@sSelectBillLines+ " from #TEMPBILLLINES AS BillLines"+char(10)+
			"order by "+isnull(@sOrderBillLines,'1')+char(10)+
			"for XML PATH('BillLine'), ROOT('BillLines'), ELEMENTS XSINIL, TYPE"
			
	If (@bDebug = 1)
	Begin
		print @sSQLString
	End

	exec(@sSQLString)
	
	Set @ErrorCode=@@Error
End

return @ErrorCode
go

grant execute on dbo.biw_GenerateMappedValuesXML  to public
go