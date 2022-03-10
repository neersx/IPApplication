-----------------------------------------------------------------------------------------------------------------------------
-- Creation of bi_ListWorksheetHeader
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[bi_ListWorksheetHeader]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.bi_ListWorksheetHeader.'
	Drop procedure [dbo].[bi_ListWorksheetHeader]
	Print '**** Creating Stored Procedure dbo.bi_ListWorksheetHeader...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.bi_ListWorksheetHeader
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnEntityKey		int		= null,	-- The key of the legal entity doing the billing.
	@pnCaseKey		int		= null,	-- The key of the case being billed.
	@pnWipNameKey		int		= null,	-- The key of the name being billed (for WIP recorded directly against a name only).
	@pbIsRenewalDebtor	bit		= null,	-- Indicates whether the information should be extracted for the renewal debtor or the main debtor.
	@pdtFromDate		datetime	= null, -- The From date used in the reporting.  This is passed to this stored procedure so that it can be produced in this result set for presentation by a subreport.
	@pdtToDate		datetime	= null, -- The To date used in the reporting.  This is passed to this stored procedure so that it can be produced in this result set for presentation by a subreport.	
	@pbCalledFromCentura	bit		= 0
)
AS 
-- PROCEDURE:	bi_ListWorksheetHeader
-- VERSION:	11
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	InPro.net
-- DESCRIPTION:	This stored procedure produces the header result set for the Billing Worksheet Report.  
--		This contains information about the case/name being billed that is not essential in 
--		the main result set.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 29 Apr 2005  TM	RFC2554	1	Procedure created. 
-- 02 May 2005	TM	RFC2554	2	There is no need to call wp_FilterWip. Remove @ptXMLFilterCriteria parameter, 
--					and receive the necessary information as specific parameters.
-- 02 May 2005	TM	RFC2554	3	Rename functions fn_GetCopyToForCase and fn_GetCopyToForName to be 
--					fn_GetCaseNamesAddresses and fn_GetAssociatedNamesAddresses.
-- 20 May 2005	TM	RFC2554	4	Populate the BillingReference column.
-- 25 May 2005	TM	RFC2554	5	Use temporary  table for both DocItem types - 'Select' statements as well as
--					stored procedures to cater for DocItems that return more than one row (pick
--					the first row produced in this situation).					
-- 01 Jun 2005	TM	RFC2554	6	There should be a join on the CaseKey as well in the join on the CaseText table.
-- 08 Jun 2005	JEK	RFC2554	7	Copy To list using wrong name type.
-- 08 Jun 2005	JEK	RFC2554	8	Drop the temp table even if an error occurred.  To be on the safe side, drop before create too.
-- 11 Dec 2008	MF	17136	9	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 02 Nov 2015	vql	R53910	10	Adjust formatted names logic (DR-15543).
-- 20 Feb 2017  MS      R65069  11      Added Case Title in the return field set

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)
Declare @sSQLString1		nvarchar(4000)
Declare @sSQLString2		nvarchar(4000)

Declare	@sNameTypeKey 		nvarchar(3)
Declare @sCopyTo		nvarchar(4000)
Declare @sSeparator		nvarchar(100)

Declare @idoc 			int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
Declare @nDocItemKey		int
Declare @sUserSQL		nvarchar(4000)
Declare @nItemType		smallint	-- For a stored procedure @nItemType = 1.
Declare @sCaseReference		nvarchar(30)

Declare @sSegment1		nvarchar(4000)
Declare @sSegment2		nvarchar(4000)	
Declare @sSegment3		nvarchar(4000)
Declare @sSegment4		nvarchar(4000)
Declare @sSegment5		nvarchar(4000)	
Declare @sSegment6 		nvarchar(4000)	
Declare @sSegment7		nvarchar(4000)	
Declare @sSegment8		nvarchar(4000)	
Declare @sSegment9		nvarchar(4000)	
Declare @sSegment10		nvarchar(4000)	

Set     @nErrorCode = 0			
Set 	@sSeparator = char(13)+char(10)

-- Set the Debtor type
If @nErrorCode=0
Begin	
	Set @sNameTypeKey	= CASE 	WHEN @pbIsRenewalDebtor = 1
					THEN 'ZC'
					ELSE 'CD'
				  END
End

If @nErrorCode = 0
Begin
	If @pnCaseKey is not null
	Begin
		-- Extract the CopyToList:	
		Set @sCopyTo = dbo.fn_GetCaseNamesAddresses
						(@pnCaseKey,
						 @sNameTypeKey,
						 @sSeparator, 
						 getdate())	
		Set @nErrorCode = @@Error
	End
	Else If @pnWipNameKey is not null
	Begin
		-- Extract the CopyToList:	
		Set @sCopyTo = dbo.fn_GetAssociatedNamesAddresses
						(@pnWipNameKey,
						 'BI2',
						 @sSeparator, 
						 getdate())	
		Set @nErrorCode = @@Error		
	End

	-- Get the DocItem information:
	If @nErrorCode = 0
	and @pnCaseKey is not null
	Begin		
		-- Get the DocItemKey and CaseReference to pass to the cs_RunCaseDocItem
		-- stored procedure:		
		Set @sSQLString=
		"Select @sCaseReference = C.IRN,
			@nDocItemKey	= I.ITEM_ID			
		  	from ITEM I
			join CASES C		on (C.CASEID = @pnCaseKey) 				
			join SITECONTROL SC	on (SC.CONTROLID = 'Bill Ref-Single'
						and SC.COLCHARACTER = I.ITEM_NAME)"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sCaseReference	nvarchar(30)	OUTPUT,
					  @nDocItemKey		int		OUTPUT,
					  @pnCaseKey		int',
					  @sCaseReference	= @sCaseReference OUTPUT,
					  @nDocItemKey		= @nDocItemKey	OUTPUT,
					  @pnCaseKey		= @pnCaseKey
	End

	If  @nErrorCode = 0
	and @nDocItemKey is not null
	Begin
		If exists(select * from tempdb.dbo.sysobjects where name = '##DocItemText')
		Begin
			Set @sSQLString = "Drop table ##DocItemText"	
			
			exec @nErrorCode=sp_executesql @sSQLString
		End

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "Create table ##DocItemText (DocItemText ntext)"
			
			exec @nErrorCode=sp_executesql @sSQLString
	
			-- Get the DocItem value/s into the temporary table:		
			Insert into ##DocItemText (DocItemText)
			Exec  dbo.cs_RunCaseDocItem		
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnDocItemKey 		= @nDocItemKey,
				@pnCaseKey 		= @pnCaseKey,
				@psCaseReference 	= @sCaseReference	
		End
	End	

	-- Populating the Header result set.
	
	-- If the DocItem is null there is no special logic required
	-- to return the result set:
	If @nErrorCode = 0
	and @nDocItemKey is null
	Begin
		Set @sSQLString = "
		Select  dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as EntityName,"+char(10)+
			CASE 	WHEN @pnCaseKey is not null
				THEN "C.IRN		as CaseReference,"
				ELSE "NULL		as CaseReference,"
			END+char(10)+                        
			"@pdtFromDate as FromDate,
			@pdtToDate	as ToDate,
			NULL		as BillingReference,"+char(10)+
			CASE	WHEN @pnCaseKey is not null
				THEN "ISNULL(CT.TEXT,CT.SHORTTEXT) as BillingNotes,"
				ELSE "NULL			   as BillingNotes,"
			END+char(10)+
			"@sCopyTo	as CopyToList,"+char(10)+
                        CASE 	WHEN @pnCaseKey is not null
				THEN "C.TITLE		as Title"
				ELSE "NULL		as Title"
			END+char(10)+				
		"from    NAME N"+char(10)+
		CASE	WHEN @pnCaseKey is not null
			THEN   "join CASES C		on (C.CASEID = @pnCaseKey)
				left join CASETEXT CT		on (CT.CASEID = C.CASEID
								and CT.LANGUAGE is null 
								and CT.TEXTTYPE='_B' 
								and CT.CLASS IS NULL)"	
		END+char(10)+
		CASE	WHEN @pnCaseKey is not null 	
			THEN   	       	"where C.CASEID=@pnCaseKey"
			      +char(10)+"  and N.NAMENO = @pnEntityKey"
			WHEN @pnWipNameKey is not null	
			THEN "where N.NAMENO = @pnEntityKey"
		END
	
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnUserIdentityId 	int,
						  @sCopyTo		nvarchar(4000),
						  @pdtFromDate		datetime,
						  @pdtToDate		datetime,
						  @pnEntityKey		int,
						  @pnCaseKey		int,
						  @pnWipNameKey		int',					 
						  @pnUserIdentityId 	= @pnUserIdentityId,
						  @sCopyTo		= @sCopyTo,
						  @pdtFromDate		= @pdtFromDate,
						  @pdtToDate		= @pdtToDate,
						  @pnEntityKey		= @pnEntityKey,
						  @pnCaseKey		= @pnCaseKey,
						  @pnWipNameKey		= @pnWipNameKey
		Set @pnRowCount=@@Rowcount	
	End	
	-- If there is a DocItemKey get the result of executing 
	-- the DocItem from the temporary table:
	Else If  @nErrorCode = 0
	     and @nDocItemKey is not null
	Begin
		Set @sSQLString = "
		Select  dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as EntityName,"+char(10)+
			CASE 	WHEN @pnCaseKey is not null
				THEN "C.IRN		as CaseReference,"
				ELSE "NULL		as CaseReference,"
			END+char(10)+
			"@pdtFromDate as FromDate,
			@pdtToDate	as ToDate,
			DocItemText	as BillingReference,"+char(10)+
			CASE	WHEN @pnCaseKey is not null
				THEN "ISNULL(CT.TEXT,CT.SHORTTEXT) as BillingNotes,"
				ELSE "NULL			   as BillingNotes,"
			END+char(10)+
			"@sCopyTo	as CopyToList,"+char(10)+
                        CASE 	WHEN @pnCaseKey is not null
				THEN "C.TITLE		as Title"
				ELSE "NULL		as Title"
			END+char(10)+				
		"from    NAME N"+char(10)+
		CASE	WHEN @pnCaseKey is not null
			THEN   "join CASES C		on (C.CASEID = @pnCaseKey)
				left join CASETEXT CT		on (CT.CASEID = C.CASEID
								and CT.LANGUAGE is null 
								and CT.TEXTTYPE='_B' 
								and CT.CLASS IS NULL)
				left join (Select Top 1 DI.DocItemText
					   from ##DocItemText DI) TMP on (TMP.DocItemText is not null)"	
		END+char(10)+
		CASE	WHEN @pnCaseKey is not null 	
			THEN   	       	"where C.CASEID=@pnCaseKey"
			      +char(10)+"  and N.NAMENO = @pnEntityKey"
			WHEN @pnWipNameKey is not null	
			THEN "where N.NAMENO = @pnEntityKey"
		END
	
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnUserIdentityId 	int,
						  @sCopyTo		nvarchar(4000),
						  @pdtFromDate		datetime,
						  @pdtToDate		datetime,
						  @pnEntityKey		int,
						  @pnCaseKey		int,
						  @pnWipNameKey		int',					 
						  @pnUserIdentityId 	= @pnUserIdentityId,
						  @sCopyTo		= @sCopyTo,
						  @pdtFromDate		= @pdtFromDate,
						  @pdtToDate		= @pdtToDate,
						  @pnEntityKey		= @pnEntityKey,
						  @pnCaseKey		= @pnCaseKey,
						  @pnWipNameKey		= @pnWipNameKey
		Set @pnRowCount=@@Rowcount					

	End
End

-- Drop the temporary table that is no longer required:
-- The table should be dropped even if an error occurred.
If exists(select * from tempdb.dbo.sysobjects where name = '##DocItemText')
Begin
	Set @sSQLString = "Drop table ##DocItemText"	
	
	exec @nErrorCode=sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.bi_ListWorksheetHeader to public
GO
