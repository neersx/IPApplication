-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_ConstructIssuesWhere
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ede_ConstructIssuesWhere]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.ede_ConstructIssuesWhere.'
	drop procedure dbo.ede_ConstructIssuesWhere
End
print '**** Creating procedure dbo.ede_ConstructIssuesWhere...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ede_ConstructIssuesWhere
(
	@psIssuesWhere		nvarchar(4000)	= null	OUTPUT,
	@psCurrentCaseTable 	nvarchar(60)	= null	OUTPUT,
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbIsExternalUser	bit,			-- Mandatory. Flag to indicate if user is external.  
							-- Default on as this is the lowest security level
	@ptXMLFilterCriteria	ntext		= null,	-- Contains filtering to be applied to the selected columns
	@pbCalledFromCentura	bit		= 0	-- Indicates that Centura called the stored procedure
)	
AS
-- PROCEDURE :	ede_ConstructIssuesWhere
-- VERSION :	9
-- DESCRIPTION:	This stored procedure accepts the variables that may be used to filter Issues 
--		and constructs a Where clause.  
--
-- Date		Who	Number		Version	Change
-- ------------	-------	--------	-------	----------------------------------------------- 
-- 26 Sep 2006  IB	SQA12300	1	Procedure created
-- 02 Nov 2006  IB	SQA12300	2	Added ETB.BATCHNO = ECM2.BATCHNO join condition.
-- 04 Dec 2006  IB	SQA13285	3	Allowed searching for live cases with issues.
--						Added search for SessionId.
-- 01 Feb 2007  IB	SQA13285	4	Removed search for SessionId.
--						Added search for SessionId and SessionDate.
-- 07 May 2007  KR	SQA14350	5	Added Modified By Name and Modified Date From.
-- 05 Aug 2009	MF	SQA17917	6	Improve performance and lower locking level.
-- 04 Jun 2010	MF	SQA18703	7	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are set to null
--						and also set ALIASTYPE to '_E'.
-- 05 Jul 2013	vql	R13629		8	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	9   Date conversion errors when creating cases and opening names in Chinese DB


-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode			int
Declare @sAlertXML	 		nvarchar(400)

Declare @sSQLString			nvarchar(4000)

Declare @sFrom				nvarchar(4000)
Declare @sAcctClientNoWhere		nvarchar(4000)	-- The part of the 'Where' clause used for the WIP recorded against the Name.
Declare @sCaseWhere			nvarchar(4000)	-- The part of the 'Where' clause used for the WIP recorded against the Case.
Declare @sWhere				nvarchar(4000)	-- General filter criteria.

Declare @sWhereFilter			nvarchar(4000)	-- Used to hold filter criteria produced by the csw_FilterCases.

-- Filter Criteria
Declare @sRequestType			nvarchar(50)
Declare @nRequestTypeOperator		tinyint		
Declare @nDataSourceKey 		int		
Declare @nDataSourceKeyOperator		tinyint		
Declare @sBatchKey 			nvarchar(254)		
Declare @nBatchKeyOperator		tinyint		
Declare @dtBatchDateFrom		datetime	
Declare @dtBatchDateTo			datetime	
Declare @nBatchDatesOperator		tinyint		
Declare @nBatchStatus	 		int		
Declare @nBatchStatusOperator		tinyint		
Declare @nTransactionStatus	 	int		
Declare @nTransactionStatusOperator	tinyint		
Declare @nMatchLevel		 	int		
Declare @nMatchLevelOperator		tinyint		
Declare @nIssueType		 	int		
Declare @nIssueTypeOperator		tinyint		
Declare @nSessionId		 	int		
Declare @nSessionIdOperator		tinyint		
Declare @dtSessionDate		 	datetime		
Declare @nSessionDateOperator		tinyint		
Declare @bSearchAllCasesWithIssues	bit
Declare @nModifiedByName		int
Declare @nModifiedByNameOperator	tinyint
Declare @dtModifiedFromDate		datetime
Declare @nModifiedFromDateOperator	tinyint

Declare	@bExternalUser			bit
Declare @bSearchForIssues		bit

Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
					
Declare @sLookupCulture		nvarchar(10)
		
-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.
Declare @sOr				nvarchar(10)


Set	@String 			= 'S'
Set	@Date   			= 'DT'
Set	@Numeric			= 'N'
Set	@Text   			= 'T'
Set	@CommaString			= 'CS'

Set 	@nErrorCode			= 0

Set	@bSearchForIssues		= 0

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE CLAUSE   ****/
/****                                       ****/
/***********************************************/

-- Create an XML document in memory and then retrieve the information 
-- from the rowset using OPENXML
	
exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

If @nErrorCode = 0 
Begin
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	Set @sWhere = char(10)+"	where 1=1"

	Set @sFrom  = char(10)+"	from CASES C2 (NOLOCK)" +
		      char(10)+"	left join EDECASEMATCH ECM2 (NOLOCK) on (ECM2.DRAFTCASEID = C2.CASEID)"
	
	-- Retrieve the Filter elements using element-centric mapping

	Set @sSQLString = 	
	"Select @sRequestType			= RequestType,"+CHAR(10)+	
	"	@nRequestTypeOperator		= RequestTypeOperator,"+CHAR(10)+
	"	@nDataSourceKey			= DataSourceKey,"+CHAR(10)+	
	"	@nDataSourceKeyOperator		= DataSourceKeyOperator,"+CHAR(10)+
	"	@sBatchKey			= BatchKey,"+CHAR(10)+
	"	@nBatchKeyOperator		= BatchKeyOperator,"+CHAR(10)+
	"	@dtBatchDateFrom		= BatchDateFrom,"+CHAR(10)+
	"	@dtBatchDateTo			= BatchDateTo,"+CHAR(10)+
	"	@nBatchDatesOperator		= BatchDatesOperator,"+CHAR(10)+
	"	@nBatchStatus			= BatchStatus,"+CHAR(10)+
	"	@nBatchStatusOperator		= BatchStatusOperator,"+CHAR(10)+
	"	@nSessionId			= SessionId,"+CHAR(10)+
	"	@nSessionIdOperator		= SessionIdOperator,"+CHAR(10)+
	"	@dtSessionDate			= SessionDate,"+CHAR(10)+
	"	@nSessionDateOperator		= SessionDateOperator,"+CHAR(10)+
	"	@nTransactionStatus		= TransactionStatus,"+CHAR(10)+
	"	@nTransactionStatusOperator	= TransactionStatusOperator,"+CHAR(10)+
	"	@nMatchLevel			= MatchLevel,"+CHAR(10)+
	"	@nMatchLevelOperator		= MatchLevelOperator,"+CHAR(10)+
	"	@nIssueType			= IssueType,"+CHAR(10)+
	"	@nIssueTypeOperator		= IssueTypeOperator,"+CHAR(10)+
	"	@bSearchAllCasesWithIssues	= SearchAllCasesWithIssues,"+CHAR(10)+
	"	@nModifiedByName		= ModifiedByName,"+CHAR(10)+
	"	@nModifiedByNameOperator	= ModifiedByNameOperator,"+CHAR(10)+
	"	@dtModifiedFromDate		= ModifiedFromDate,"+CHAR(10)+
	"	@nModifiedFromDateOperator	= ModifiedFromDateOperator"+CHAR(10)+
	"from	OPENXML (@idoc, '/ede_ListIssues/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      RequestType		nvarchar(50)	'Batch/RequestType/text()',"+CHAR(10)+
	"	      RequestTypeOperator	tinyint		'Batch/RequestType/@Operator/text()',"+CHAR(10)+
	"	      DataSourceKey 		int		'Batch/DataSourceKey/text()',"+CHAR(10)+
	"	      DataSourceKeyOperator	tinyint		'Batch/DataSourceKey/@Operator/text()',"+CHAR(10)+
	"	      BatchKey 			nvarchar(254)	'Batch/BatchKey/text()',"+CHAR(10)+
	"	      BatchKeyOperator		tinyint		'Batch/BatchKey/@Operator/text()',"+CHAR(10)+
	"	      BatchDateFrom		datetime	'Batch/DateRange/From/text()',"+CHAR(10)+
	"	      BatchDateTo		datetime	'Batch/DateRange/To/text()',"+CHAR(10)+
	"	      BatchDatesOperator	tinyint		'Batch/DateRange/@Operator/text()',"+CHAR(10)+
	"	      BatchStatus	 	int		'Batch/BatchStatus/text()',"+CHAR(10)+
	"	      BatchStatusOperator	tinyint		'Batch/BatchStatus/@Operator/text()',"+CHAR(10)+
	"	      SessionId	 		int		'Session/SessionId/text()',"+CHAR(10)+
	"	      SessionIdOperator		tinyint		'Session/SessionId/@Operator/text()',"+CHAR(10)+
	"	      SessionDate	 	datetime	'Session/SessionDate/text()',"+CHAR(10)+
	"	      SessionDateOperator	tinyint		'Session/SessionDate/@Operator/text()',"+CHAR(10)+
	"	      TransactionStatus	 	int		'Transaction/TransactionStatus/text()',"+CHAR(10)+
	"	      TransactionStatusOperator	tinyint		'Transaction/TransactionStatus/@Operator/text()',"+CHAR(10)+
	"	      MatchLevel		int		'Transaction/MatchLevel/text()',"+CHAR(10)+
	"	      MatchLevelOperator	tinyint		'Transaction/MatchLevel/@Operator/text()',"+CHAR(10)+
	"	      IssueType		 	int		'Transaction/IssueType/text()',"+CHAR(10)+
	"	      IssueTypeOperator		tinyint		'Transaction/IssueType/@Operator/text()',"+CHAR(10)+
	"	      SearchAllCasesWithIssues	bit		'Transaction/SearchAllCasesWithIssues/text()',"+CHAR(10)+
	"	      ModifiedByName 		int		'ModifiedBy/ModifiedByName/text()',"+CHAR(10)+
	"	      ModifiedByNameOperator	tinyint		'ModifiedBy/ModifiedByName/@Operator/text()',"+CHAR(10)+
	"	      ModifiedFromDate	 	datetime	'ModifiedBy/DateRange/From/text()',"+CHAR(10)+
	"	      ModifiedFromDateOperator 	tinyint		'ModifiedBy/DateRange/@Operator/text()'"+CHAR(10)+
     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sRequestType			nvarchar(50)		output,
				  @nRequestTypeOperator		tinyint			output,
				  @nDataSourceKey 		int			output,
				  @nDataSourceKeyOperator	tinyint			output,
				  @sBatchKey 			nvarchar(254)		output,
				  @nBatchKeyOperator		tinyint			output,
				  @dtBatchDateFrom		datetime		output,
				  @dtBatchDateTo		datetime		output,
				  @nBatchDatesOperator		tinyint			output,
				  @nBatchStatus	 		int			output,
				  @nBatchStatusOperator		tinyint			output,
				  @nSessionId	 		int			output,
				  @nSessionIdOperator		tinyint			output,
				  @dtSessionDate	 	datetime		output,
				  @nSessionDateOperator		tinyint			output,
				  @nTransactionStatus	 	int			output,
				  @nTransactionStatusOperator	tinyint			output,
				  @nMatchLevel		 	int			output,
				  @nMatchLevelOperator		tinyint			output,
				  @nIssueType		 	int			output,
				  @nIssueTypeOperator		tinyint			output,
				  @bSearchAllCasesWithIssues	bit			output,
				  @nModifiedByName 		int			output,
				  @nModifiedByNameOperator	tinyint			output,
				  @dtModifiedFromDate	 	datetime		output,
				  @nModifiedFromDateOperator	tinyint			output',
				  @idoc				= @idoc,
				  @sRequestType			= @sRequestType			output,
				  @nRequestTypeOperator		= @nRequestTypeOperator		output,
				  @nDataSourceKey 		= @nDataSourceKey		output,
				  @nDataSourceKeyOperator	= @nDataSourceKeyOperator 	output,
				  @sBatchKey 			= @sBatchKey			output,
				  @nBatchKeyOperator		= @nBatchKeyOperator		output,
				  @dtBatchDateFrom		= @dtBatchDateFrom		output,
				  @dtBatchDateTo		= @dtBatchDateTo		output,
				  @nBatchDatesOperator		= @nBatchDatesOperator		output,
				  @nBatchStatus	 		= @nBatchStatus			output,
				  @nBatchStatusOperator		= @nBatchStatusOperator		output,
				  @nSessionId	 		= @nSessionId			output,
				  @nSessionIdOperator		= @nSessionIdOperator		output,
				  @dtSessionDate	 	= @dtSessionDate		output,
				  @nSessionDateOperator		= @nSessionDateOperator		output,
				  @nTransactionStatus	 	= @nTransactionStatus		output,
				  @nTransactionStatusOperator	= @nTransactionStatusOperator	output,
				  @nMatchLevel		 	= @nMatchLevel			output,
				  @nMatchLevelOperator		= @nMatchLevelOperator		output,
				  @nIssueType		 	= @nIssueType			output,
				  @nIssueTypeOperator		= @nIssueTypeOperator		output,
				  @bSearchAllCasesWithIssues	= @bSearchAllCasesWithIssues	output,
				  @nModifiedByName 		= @nModifiedByName		output,
				  @nModifiedByNameOperator	= @nModifiedByNameOperator	output,
				  @dtModifiedFromDate	 	= @dtModifiedFromDate		output,
				  @nModifiedFromDateOperator	= @nModifiedFromDateOperator	output
				  
End

-- Construction of the WIP recorded against the Case filter criteria:
If  @nErrorCode = 0
and exists(Select 1 from OPENXML (@idoc, '//csw_ListCase/*//FilterCriteria/*', 2))
Begin
	-- Call the csw_FilterCases that is responsible for the management of the multiple occurrences of the filter criteria 
	-- and the production of an appropriate result set. It calls csw_ConstructCaseWhere to obtain the where clause for each
	-- separate occurrence of FilterCriteria.  The @psTempTableName output parameter is the name of the the global temporary
	-- table that may hold the filtered list of cases.
	exec @nErrorCode = dbo.csw_FilterCases	@psReturnClause 	= @sCaseWhere	  	OUTPUT, 			
						@psTempTableName 	= @psCurrentCaseTable	OUTPUT,	
						@pnUserIdentityId	= @pnUserIdentityId,	
						@psCulture		= @psCulture,	
						@pbIsExternalUser	= @bExternalUser,
						@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
					    	@pbCalledFromCentura	= @pbCalledFromCentura		
End

-- deallocate the xml document handle when finished.
exec sp_xml_removedocument @idoc	

-- Construction of the General filter criteria:
If @nErrorCode = 0
Begin

	If @sRequestType is not NULL
	Begin 
		If charindex('join EDESENDERDETAILS ESD', @sFrom) = 0
		Begin
			Set @sFrom = @sFrom+char(10)+"	     join EDESENDERDETAILS ESD (NOLOCK) on (ESD.BATCHNO = ECM2.BATCHNO)"
		End

		Set @sWhere = @sWhere+char(10)+"	and ESD.SENDERREQUESTTYPE"+
			dbo.fn_ConstructOperator(@nRequestTypeOperator,@String,
			@sRequestType,null,@pbCalledFromCentura)
	End	

	If @nDataSourceKey is not NULL
	Begin
		If charindex('join EDESENDERDETAILS ESD', @sFrom) = 0
		Begin
			Set @sFrom = @sFrom+char(10)+"	     join EDESENDERDETAILS ESD (NOLOCK) on (ESD.BATCHNO = ECM2.BATCHNO)"
		End

		Set @sFrom = @sFrom+char(10)+"	     join NAMEALIAS NA (NOLOCK) on (NA.ALIAS     = ESD.SENDER"
				   +char(10)+"	                                and NA.ALIASTYPE = '_E'"
				   +char(10)+"	                                and NA.COUNTRYCODE  is null"
				   +char(10)+"	                                and NA.PROPERTYTYPE is null)"
				   +char(10)+"	     join NAME N (NOLOCK) on (N.NAMENO = NA.NAMENO)"

		Set @sWhere = @sWhere+char(10)+"	and N.NAMENO"+
			dbo.fn_ConstructOperator(@nDataSourceKeyOperator,@Numeric,
			@nDataSourceKey,null,@pbCalledFromCentura)
	End	

	If @sBatchKey is not NULL
	Begin
		If charindex('join EDESENDERDETAILS ESD', @sFrom) = 0
		Begin
			Set @sFrom = @sFrom+char(10)+"	     join EDESENDERDETAILS ESD (NOLOCK) on (ESD.BATCHNO = ECM2.BATCHNO)"
		End

		Set @sWhere = @sWhere+char(10)+"	and ESD.SENDERREQUESTIDENTIFIER"+
			dbo.fn_ConstructOperator(@nBatchKeyOperator,@String,
			@sBatchKey,null,@pbCalledFromCentura)
	End	

	If (@dtBatchDateFrom is not NULL
        or @dtBatchDateTo   is not NULL)
	Begin
		If charindex('join EDESENDERDETAILS ESD', @sFrom) = 0
		Begin
			Set @sFrom = @sFrom+char(10)+"	     join EDESENDERDETAILS ESD (NOLOCK) on (ESD.BATCHNO = ECM2.BATCHNO)"
		End

		Set @sWhere = @sWhere+char(10)+"	and ESD.SENDERPRODUCEDDATE"+
			dbo.fn_ConstructOperator(@nBatchDatesOperator,@Date,
			convert(nvarchar,@dtBatchDateFrom,112), convert(nvarchar,@dtBatchDateTo,112),@pbCalledFromCentura)
	End		

	If @nBatchStatus is not NULL
	Begin
		Set @sFrom = @sFrom+char(10)+"	     join EDETRANSACTIONHEADER ETH (NOLOCK) on (ETH.BATCHNO = ECM2.BATCHNO)"
	
		Set @sWhere = @sWhere+char(10)+"	and ETH.BATCHSTATUS"+
			dbo.fn_ConstructOperator(@nBatchStatusOperator,@Numeric,
			@nBatchStatus,null,@pbCalledFromCentura)
	End		

	If @nSessionId is not NULL
	Begin
		If charindex('join SESSION S',@sFrom)=0	
		Begin
			Set @sFrom=@sFrom +char(10)+"	     join SESSION S (NOLOCK) on (S.SESSIONNO = ECM2.SESSIONNO)"
		End	

		Set @sWhere = @sWhere+char(10)+"	and S.SESSIONIDENTIFIER"+
			dbo.fn_ConstructOperator(@nSessionIdOperator,@Numeric,
			@nSessionId,null,@pbCalledFromCentura)
	End	

	If @dtSessionDate is not NULL
	Begin
		If charindex('join SESSION S',@sFrom)=0	
		Begin
			Set @sFrom=@sFrom +char(10)+"	     join SESSION S (NOLOCK) on (S.SESSIONNO = ECM2.SESSIONNO)"
		End	

		Set @sWhere = @sWhere+char(10)+"	and S.STARTDATE"+
			dbo.fn_ConstructOperator(@nSessionDateOperator,@Date,
			convert(nvarchar,@dtSessionDate,112),null,@pbCalledFromCentura)
	End				

	If @nTransactionStatus is not NULL
	Begin
		-- Note that (NOLOCK) will not be used on this join
		Set @sFrom = @sFrom+char(10)+"	     join EDETRANSACTIONBODY ETB on (ETB.BATCHNO = ECM2.BATCHNO"
				   +char(10)+"					 and ETB.TRANSACTIONIDENTIFIER = ECM2.TRANSACTIONIDENTIFIER)"

		Set @sWhere = @sWhere+char(10)+"	and ETB.TRANSSTATUSCODE"+
			dbo.fn_ConstructOperator(@nTransactionStatusOperator,@Numeric,
			@nTransactionStatus,null,@pbCalledFromCentura)
	End		

	If @nMatchLevel is not NULL
	Begin
		Set @sWhere = @sWhere+char(10)+"	and ECM2.MATCHLEVEL"+
			dbo.fn_ConstructOperator(@nMatchLevelOperator,@Numeric,
			@nMatchLevel,null,@pbCalledFromCentura)
	End		

	If @nIssueType is not NULL
	Begin
		Set @sFrom = @sFrom+char(10)+"	     join EDEOUTSTANDINGISSUES EOI (NOLOCK) on (EOI.CASEID = C2.CASEID)"

		Set @sWhere = @sWhere+char(10)+"	and EOI.ISSUEID"+
			dbo.fn_ConstructOperator(@nIssueTypeOperator,@Numeric,
			@nIssueType,null,@pbCalledFromCentura)

		Set @bSearchForIssues = 1
	End		

	If @bSearchAllCasesWithIssues = 1
	Begin
		If charindex('join EDEOUTSTANDINGISSUES EOI', @sFrom) = 0
		Begin
			Set @sFrom = @sFrom+char(10)+"	     join EDEOUTSTANDINGISSUES EOI (NOLOCK) on (EOI.CASEID = C2.CASEID)"
		End

		Set @sWhere = @sWhere+char(10)+"	and EOI.ISSUEID is not null"

		Set @bSearchForIssues = 1
	End

	If @nModifiedByName is not NULL
	Begin
		If charindex('join SESSION S',@sFrom)=0	
		Begin
			Set @sFrom=@sFrom +char(10)+"	     join SESSION S (NOLOCK) on (S.SESSIONNO = ECM2.SESSIONNO)"
			Set @sFrom = @sFrom+char(10)+"	     join USERIDENTITY UI (NOLOCK) on (UI.IDENTITYID = S.IDENTITYID)"
		End	

		Set @sWhere = @sWhere+char(10)+"	and UI.NAMENO"+
			dbo.fn_ConstructOperator(@nModifiedByNameOperator,@Numeric,
			@nModifiedByName,null,@pbCalledFromCentura)
	End	

	If @dtModifiedFromDate is not NULL
	Begin
		If charindex('join TRANSACTIONINFO TI',@sFrom)=0	
		Begin
			Set @sFrom=@sFrom +char(10)+"	    Join TRANSACTIONINFO TI (NOLOCK) on (TI.SESSIONNO = ECM2.SESSIONNO"
				   +char(10)+"					             AND TI.CASEID = ECM2.DRAFTCASEID )"
		End	

		Set @sWhere = @sWhere+char(10)+"	and TI.TRANSACTIONDATE"+
			dbo.fn_ConstructOperator(@nModifiedFromDateOperator,@Date,convert(nvarchar,@dtModifiedFromDate,112), 
			convert(nvarchar,null,112),@pbCalledFromCentura)
	End			

End

-- Assemble the From and Where clause for use in the EXISTS clause.
If @nErrorCode = 0
Begin
	If @bSearchForIssues = 0
	Begin
		Set @sWhere = @sWhere+char(10)+"	and ECM2.DRAFTCASEID is not null"
	End

	Set @psIssuesWhere = ltrim(rtrim(@sFrom+char(10)+@sWhere))
			+ char(10) + CASE WHEN @sCaseWhere is not null
					  THEN " and (1=1 "
					+ char(10) + replace(@sCaseWhere, 'and XC.CASEID=C.CASEID', 'and XC.CASEID=C2.CASEID')				
					+ char(10) + ")"
				     END
End

RETURN @nErrorCode
GO

Grant execute on dbo.ede_ConstructIssuesWhere  to public
GO

