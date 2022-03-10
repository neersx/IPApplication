-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListEvent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListEvent.'
	Drop procedure [dbo].[ipw_ListEvent]
	Print '**** Creating Stored Procedure dbo.ipw_ListEvent...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListEvent
(
	@pnRowCount					int 		= null	output,
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey			int		= 20, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbPrintSQL					bit		= null,	-- When set to 1, the executed SQL statement is printed out. 
	@pbCalledFromCentura		bit 		= 0
)
AS
-- PROCEDURE:	ipw_ListEvent
-- VERSION:	26
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns the Event information requested, that matches the filter criteria 
--		provided and that the currently logged on user identified by @pnUserIdentityId 
--		is allowed to have access to.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	RFC#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 08 Oct 2003	TM	396	1	New .net version based on v12 of ip_ListEvent.
-- 21 Oct 2003	TM	396	2	Pass arguments into the fn_FilterUserEvents. Implement 
--					fn_FilterUserEventControl. 
-- 23 Oct 2003	TM	554	3	Error occurs when activating the Case Event pick list (CST RFC476).
--					Take out the bracket next to the "and E.EVENTNO)" in the "if @psEventKey 
--					is not NULL or @pnEventKeyOperator between 2 and 6" section.
-- 07 Nov 2003	MF	RFC586	4	Use the fn_WrapQuotes function when constructing SQL with embedded string values
-- 26 Nov 2003	JEK	RFC586	5	Remove extra + in pick list search logic
-- 30 Jan 2004  TM	RFC846	6	Increase the EventDescription field to varchar(100). Increase @psEventDescription
--					and @psPickListSearch datasizes from nvarchar(50) to nvarchar(100).
-- 19-Feb-2004	TM	RFC976	7	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 04-Mar-2004	TM	RFC934	8	Remove all use of fn_FilterUserEventControl. Ensure fn_FilterUserEvents is 
--					implemented for all events returned for external users only.
-- 11-May-2004	TM	RFC1416	9	For external users extract the Importance Level and Description from 
--					fn_FilterUserEvents rather than from EVENTS.
-- 13-May-2004	TM	RFC1246	10	Implement fn_GetCorrelationSuffix function to generate the correlation suffix 
--					based on the supplied qualifier.
-- 26-Jul-2004	TM	RFC1323	11	Implement Event Category as filter criterion and column.  
-- 02 Sep 2004	JEK	RFC1377	12	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 09 Sep 2004	JEK	RFC886	13	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 17 Sep 2004	JEK	RFC886	14	Adjust @psCulture format.
-- 21 Sep 2004	TM	RFC886	15 	Implement translation.
-- 17 Dec 2004	TM	RFC1674	16	Remove the UPPER function around the EventCode to improve performance.
-- 31 Jan 2005  TM	RFC1040	17	Add a join to the EventControl EC table to the PickListSearch logic
--					if the EventControl.EventDescription is used in the 'Where' clause. 
-- 15 May 2005	JEK	RFC2508	18	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 24 Oct 2005	TM	RFC3024	19	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 04 Dec 2006  PG      RFC3646 20      Pass @pbIsExternalUser to fn_filterUserXxx.
-- 21 Sep 2009  LP      RFC8047 21      Pass @pnProfileKey to fn_GetCriteriaNo
-- 24 Oct 2009	SF	RFC8449	22	Change parameters to use XML Filter Criteria
-- 07 Jul 2011	DL	RFC10830 23	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 20 Oct 2011	LP	RFC6896 24	Allow filtering to return Case Events only based on CASEID (and ACTION/CRITERIA if specified).
--					Match on EventControl description if CASEID is specified.
-- 14 Dec 2011	LP	R11568	25	Improve performance when returning Case Events for a specific Case only.
--					Correct filtering when returning CaseEvents only.
-- 24 Oct 2017	AK	R72645	26	Make compatible with case sensitive server with case insensitive database.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- VARIABLES

declare @nErrorCode		int
declare @sSqlString		nvarchar(4000)
declare @sSelect		nvarchar(4000)  -- the SQL list of columns to return
declare	@sFrom			nvarchar(4000)	-- the SQL to list tables and joins
declare @sWhere			nvarchar(4000) 	-- the SQL to filter
declare @sCaseOnlyWhere		nvarchar(4000)  -- extra filter if only CASEID is provided
declare @sOrder			nvarchar(1000)	-- the SQL sort order
declare @pbExists		bit
declare	@sDelimiter		nchar(1)
declare @nCount			int
declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
Declare @nOutRequestsRowCount	int
declare @nColumnNo		tinyint
declare @sColumn		nvarchar(100)
declare @sPublishName		nvarchar(50)
declare @sQualifier		nvarchar(50)
declare @sTableColumn		nvarchar(1000)
declare @nLastPosition		smallint
declare @nOrderPosition		tinyint
declare @sOrderDirection	nvarchar(5)
declare @sCorrelationSuffix	nvarchar(20)

declare @sTable1					nvarchar(25)
declare @sEventKey					nvarchar(254)		-- This is a string, to allow like searching on event nos.
declare @nEventKeyOperator			tinyint
declare @sPickListSearch			nvarchar(100)
declare	@sEventCode					nvarchar(10)
declare	@nEventCodeOperator			tinyint
declare	@sEventDescription			nvarchar(100)		-- Uses the description from event control if available, and from event otherwise.
declare @nEventDescriptionOperator	tinyint
declare	@bIsInUse					bit					-- Is the event attached to an event control definition?
declare	@sImportanceLevelFrom		nvarchar(2)
declare @sImportanceLevelTo			nvarchar(2)
declare	@nImportanceLevelOperator	tinyint
declare	@nCriteriaKey				int					-- Returns events related to the event control criteria key provided.
declare	@nCriteriaKeyOperator		tinyint	
declare	@nCaseKey					int					-- Must be supplied in conjunction with an @psActionKey.
declare	@sActionKey					nvarchar(2)			-- May be used in conjunction with @pnCaseKey but if supplied alone, 
														-- will return the distinct events associated with any event control for the @psActionKey.
declare	@nActionKeyOperator			tinyint		
declare	@nEventCategoryKey			smallint	
declare	@nEventCategoryKeyOperator	tinyint		
declare @nProfileKey				int
declare @bIsExternalUser			bit
declare	@bUseControlDescription		bit
declare @bCaseEventsOnly		bit

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
declare @tblOutputRequests table 
			 (	ROWNUMBER	int 		not null,
		   		ID		nvarchar(100)	collate database_default not null,
		   		SORTORDER	tinyint		null,
		   		SORTDIRECTION	nvarchar(1)	collate database_default null,
				PUBLISHNAME	nvarchar(100)	collate database_default null,
				QUALIFIER	nvarchar(100)	collate database_default null,				
				DOCITEMKEY	int		null
			  )
			  
-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
declare @tbOrderBy table (
	Position		tinyint		not null,
	Direction		nvarchar(5)	collate database_default not null,
	ColumnName		nvarchar(1000)	collate database_default not null,
	PublishName		nvarchar(50)	collate database_default null,
	ColumnNumber		tinyint		not null)

-- CONSTANTS

declare @String			nchar(1),
	@Date			nchar(2),
	@Numeric		nchar(1),
	@Text			nchar(1)

declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		

-- Initialisation
set @String	='S'
set @Date	='DT'
set @Numeric	='N'
set @Text	='T'

Set @nCount					= 1

set @nErrorCode	=0
set @sDelimiter	='^'
set @sSelect	='SET ANSI_NULLS OFF' + char(10)+ 'Select DISTINCT '
set @sFrom	='From EVENTS E'

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Get the ProfileKey for the current user
If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
        
        Set @nErrorCode = @@ERROR
End

-- Determine if the user is internal or external
If @nErrorCode=0 and @bIsExternalUser is null
Begin		
	Set @sSqlString='
	Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSqlString,
				N'@bIsExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

-- Ensure fn_FilterUserEvents is implemented for all events returned for external users only.
If @nErrorCode=0
and @bIsExternalUser=1
Begin
	Set @sFrom = @sFrom + char(10) + 'Join dbo.fn_FilterUserEvents('+convert(varchar,@pnUserIdentityId)+",null,"+cast(@bIsExternalUser as nvarchar(1))+","+cast(@pbCalledFromCentura as nvarchar(1))+ ') FE on (FE.EVENTNO=E.EVENTNO)'
End 

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin	
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End
-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
Else
Begin
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 20)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End

/***********************************************/
/****                                       ****/
/****    EXTRACT FILTER CRITERIA FROM XML   ****/
/****                                       ****/
/***********************************************/

-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the Filter Criteria using element-centric mapping (implement 
	--    Case Insensitive searching where required)   

	Set @sSqlString = 	
	"Select @sPickListSearch			= upper(PickListSearch),"+CHAR(10)+
	"	@sEventKey						= EventKey,"+CHAR(10)+	
	"	@nEventKeyOperator				= EventKeyOperator,"+CHAR(10)+	
	"	@sEventCode						= upper(EventCode),"+CHAR(10)+
	"	@nEventCodeOperator				= EventCodeOperator,"+CHAR(10)+
	"	@sEventDescription				= upper(EventDescription),"+CHAR(10)+
	"	@nEventDescriptionOperator		= EventDescriptionOperator,"+CHAR(10)+
	"	@bIsInUse						= IsInUse,"+CHAR(10)+	
	"	@nImportanceLevelOperator		= ImportanceLevelOperator,"+CHAR(10)+
	"	@sImportanceLevelFrom			= ImportanceLevelFrom,"+CHAR(10)+
	"	@sImportanceLevelTo				= ImportanceLevelTo,"+CHAR(10)+
	"	@nCriteriaKey					= CriteriaKey,"+CHAR(10)+
	"	@nCriteriaKeyOperator			= CriteriaKeyOperator,"+CHAR(10)+
	"	@nCaseKey						= CaseKey,"+CHAR(10)+
	"	@sActionKey						= ActionKey,"+CHAR(10)+
	"	@nActionKeyOperator				= ActionKeyOperator,"+CHAR(10)+				
	"	@nEventCategoryKey				= EventCategoryKey,"+CHAR(10)+
	"	@nEventCategoryKeyOperator		= EventCategoryKeyOperator,"+CHAR(10)+
	"	@bCaseEventsOnly			= CaseEventsOnly"+CHAR(10)+
	"from	OPENXML (@idoc, '/ipw_ListEvent/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      PickListSearch			nvarchar(254)	'PickListSearch/text()',"+CHAR(10)+	
	"	      EventKey					nvarchar(254)	'EventKey/text()',"+CHAR(10)+	
	"	      EventKeyOperator			tinyint			'EventKey/@Operator/text()',"+CHAR(10)+	
	"	      EventCode					nvarchar(254)	'EventCode/text()',"+CHAR(10)+	
	"	      EventCodeOperator			tinyint			'EventCode/@Operator/text()',"+CHAR(10)+		
	"	      EventDescription			nvarchar(100)	'EventDescription/text()',"+CHAR(10)+	
	"	      EventDescriptionOperator	tinyint			'EventDescription/@Operator/text()',"+CHAR(10)+		
	"	      IsInUse					bit				'IsInUse/text()',"+CHAR(10)+		
	"	      ImportanceLevelOperator	tinyint			'ImportanceLevel/@Operator/text()',"+CHAR(10)+
	"	      ImportanceLevelFrom		nvarchar(2)		'ImportanceLevel/From/text()',"+CHAR(10)+	
	"	      ImportanceLevelTo			nvarchar(2)		'ImportanceLevel/To/text()',"+CHAR(10)+	
	"	      CriteriaKey				int				'CriteriaKey/text()',"+CHAR(10)+
	"	      CriteriaKeyOperator		tinyint			'CriteriaKey/@Operator/text()',"+CHAR(10)+
	"	      CaseKey					int				'CaseKey/text()',"+CHAR(10)+
	"	      CaseEventsOnly			bit			'CaseKey/@CaseEventsOnly/text()',"+CHAR(10)+
	"	      ActionKey					nvarchar(2)		'ActionKey/text()',"+CHAR(10)+
	"	      ActionKeyOperator			tinyint			'ActionKey/@Operator/text()',"+CHAR(10)+
	"	      EventCategoryKey				int			'EventCategoryKey/text()',"+CHAR(10)+
	"	      EventCategoryKeyOperator		tinyint		'EventCategoryKey/@Operator/text()'"+CHAR(10)+	
	"     	     )"

	exec @nErrorCode = sp_executesql @sSqlString,
				N'@idoc							int,
				  @sPickListSearch				nvarchar(254)			output,
				  @sEventKey					nvarchar(254)			output,
				  @nEventKeyOperator			tinyint					output,
				  @sEventCode					nvarchar(254)			output,		
				  @nEventCodeOperator			tinyint					output,
				  @sEventDescription			nvarchar(100)			output,
				  @nEventDescriptionOperator	tinyint					output,
				  @bIsInUse						bit						output,
				  @nImportanceLevelOperator		tinyint					output,					  
				  @sImportanceLevelFrom			nvarchar(2)				output,
				  @sImportanceLevelTo			nvarchar(2)				output,
				  @nCriteriaKey					int						output,
				  @nCriteriaKeyOperator			tinyint					output,
				  @nCaseKey						int						output,
				  @sActionKey					nvarchar(2)				output,	
				  @nActionKeyOperator			tinyint					output,
				  @nEventCategoryKey			int						output,
				  @nEventCategoryKeyOperator	tinyint					output,
				  @bCaseEventsOnly			bit					output',
				  @idoc										= @idoc,
				  @sPickListSearch				= @sPickListSearch				output,				  		
				  @sEventKey					= @sEventKey					output,
				  @nEventKeyOperator			= @nEventKeyOperator			output,
				  @sEventCode					= @sEventCode					output,
				  @nEventCodeOperator 			= @nEventCodeOperator			output,
				  @sEventDescription			= @sEventDescription			output,
				  @nEventDescriptionOperator	= @nEventDescriptionOperator	output,
				  @bIsInUse						= @bIsInUse						output,
				  @nImportanceLevelOperator		= @nImportanceLevelOperator		output,
				  @sImportanceLevelFrom			= @sImportanceLevelFrom			output,
				  @sImportanceLevelTo 			= @sImportanceLevelTo			output,
				  @nCriteriaKey					= @nCriteriaKey					output,
				  @nCriteriaKeyOperator			= @nCriteriaKeyOperator			output,
				  @nCaseKey						= @nCaseKey						output,
				  @sActionKey					= @sActionKey					output,
				  @nActionKeyOperator			= @nActionKeyOperator			output,		
				  @nEventCategoryKey			= @nEventCategoryKey			output,
				  @nEventCategoryKeyOperator	= @nEventCategoryKeyOperator	output,
				  @bCaseEventsOnly			= @bCaseEventsOnly	output
				  
				  
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE CLAUSE   ****/
/****                                       ****/
/***********************************************/

If @nErrorCode=0
Begin

	If @nCriteriaKey is not NULL
	or @nCriteriaKeyOperator between 2 and 6
	or 
	(@nCaseKey is not NULL and (@sActionKey is not NULL or @nActionKeyOperator between 2 and 6))
	Begin
		Set @bUseControlDescription = 1
	End
	Else
	Begin
		set @bUseControlDescription = 0
	End
	
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	set @sWhere = char(10)+"WHERE 1=1"

	if @sEventKey is not NULL
	or @nEventKeyOperator between 2 and 6
	begin
		set @sWhere = @sWhere+char(10)+"and E.EVENTNO"+dbo.fn_ConstructOperator(@nEventKeyOperator,@Numeric,@sEventKey, null,0)
	end
	
	if @sEventCode is not NULL
	or @nEventCodeOperator between 2 and 6
	begin
		set @sWhere = @sWhere+char(10)+"and E.EVENTCODE"+dbo.fn_ConstructOperator(@nEventCodeOperator,@String,@sEventCode, null,0)
	end

	if @sEventDescription is not NULL
	or @nEventDescriptionOperator between 2 and 6
	begin
		If charindex('Join EVENTCONTROL EC',@sFrom)>0
		begin			
			set @sWhere = @sWhere+char(10)+"and isnull(upper("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+"),"
					     +char(10)+"	   upper("+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+"))"+dbo.fn_ConstructOperator(@nEventDescriptionOperator,@String,@sEventDescription, null,0)
		end
		Else
		begin
			set @sWhere = @sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+")"+dbo.fn_ConstructOperator(@nEventDescriptionOperator,@String,@sEventDescription, null,0)
		end
	end

	If @bIsInUse = 1
	begin
		set @sWhere=@sWhere+char(10)+'and exists (select * from EVENTCONTROL XEC1 WHERE XEC1.EVENTNO = E.EVENTNO)'
	end
	Else If @bIsInUse = 0
	begin
		set @sWhere=@sWhere+char(10)+'and not exists (select * from EVENTCONTROL XEC1 WHERE XEC1.EVENTNO = E.EVENTNO)'
	end

	If @sImportanceLevelFrom is not NULL
	or @sImportanceLevelTo   is not NULL
	or @nImportanceLevelOperator between 2 and 6
	begin
		set @sWhere=@sWhere+char(10)+"	and E.IMPORTANCELEVEL"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,0)
	end

	If @nEventCategoryKey is not null
	or @nEventCategoryKeyOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+" and E.CATEGORYID "+dbo.fn_ConstructOperator(@nEventCategoryKeyOperator,@Numeric,@nEventCategoryKey, null,0)
	End	

	If @nCaseKey is not null
	begin
		if @sActionKey is not null
		begin
			set @nCriteriaKey = dbo.fn_GetCriteriaNo(
				@nCaseKey,
				"E",
				@sActionKey,
				getdate(),
				@nProfileKey)

			set @nCriteriaKeyOperator = @nActionKeyOperator
			set @sActionKey = NULL
			set @nActionKeyOperator = NULL
		end
		
		if @bCaseEventsOnly = 1 
		begin 
			set @bUseControlDescription = 1
			set @sWhere=@sWhere+char(10)+"	and exists (SELECT 1 from CASEEVENT CEX WHERE CASEID = " + convert(nvarchar, @nCaseKey) + " and CEX.EVENTNO = E.EVENTNO)"
			set @sCaseOnlyWhere=@sCaseOnlyWhere+char(10)+"  and exists (select 1
				from OPENACTION O
				where O.CASEID = " + convert(nvarchar, @nCaseKey) + " and O.CRITERIANO = EC.CRITERIANO)"
		end
	end	

	If @nCriteriaKey is not NULL
	or @nCriteriaKeyOperator between 2 and 6
	begin
		If charindex('Join EVENTCONTROL EC',@sFrom)>0
		begin
			-- Ensure the EC specific columns selected also implement the filtering
			Set @sFrom=@sFrom+char(10)+"Join EVENTCONTROL XEC			on (XEC.EVENTNO=E.EVENTNO and XEC.CRITERIANO=EC.CRITERIANO)"
		end
		Else
		begin
			Set @sFrom=@sFrom+char(10)+'Join EVENTCONTROL XEC	on (XEC.EVENTNO=E.EVENTNO)'
		end

		set @sWhere=@sWhere+char(10)+"	and XEC.CRITERIANO"+dbo.fn_ConstructOperator(@nCriteriaKeyOperator,@Numeric,@nCriteriaKey, NULL,0)
	end

	If @sActionKey is not NULL
	or @nActionKeyOperator between 2 and 6
	begin
		set @sWhere=@sWhere+char(10)+"	and exists
			(select *
			from CRITERIA XC1
			JOIN EVENTCONTROL XEC2 ON (XEC2.EVENTNO = E.EVENTNO and XEC2.CRITERIANO = XC1.CRITERIANO)
			WHERE XC1.ACTION"+dbo.fn_ConstructOperator(@nActionKeyOperator,@String,@sActionKey, NULL,0)+")"

	end

	If LEN(@sPickListSearch)>0
	Begin
		set @pbExists=0

		If isnumeric(@sPickListSearch)=1
		Begin
			If charindex('XEC.CRITERIANO',@sWhere)>0
				set @sSqlString="Select @pbExists=1"+char(10)+
						"from EVENTS E"+char(10)+
						"join EVENTCONTROL XEC on (XEC.EVENTNO=E.EVENTNO)"+char(10)+
						-- When there is a filtering on the EventControl.EventDescription
						-- in the constructed 'Where' clause then join on the EventControl EC
						-- is required:
						CASE 	WHEN @bUseControlDescription = 1 and 
							    (@sEventDescription is not null or @nEventDescriptionOperator between 2 and 6)
							THEN "join EVENTCONTROL EC	on (EC.EVENTNO=E.EVENTNO)"
						END+char(10)+
						@sWhere+
						"and E.EVENTNO=@sPickListSearch"
			Else
				set @sSqlString="Select @pbExists=1"+char(10)+
						"from EVENTS E"+char(10)+
						-- When there is a filtering on the EventControl.EventDescription
						-- in the constructed 'Where' clause then join on the EventControl EC
						-- is required:
						CASE 	WHEN @bUseControlDescription = 1 and 
							    (@sEventDescription is not null or @nEventDescriptionOperator between 2 and 6)
							THEN "join EVENTCONTROL EC	on (EC.EVENTNO=E.EVENTNO)"
						END+char(10)+
						@sWhere+
						"and E.EVENTNO=@sPickListSearch"
				
			exec sp_executesql @sSqlString,
					N'@pbExists		bit	OUTPUT,
					  @sPickListSearch	nvarchar(100)',
					  @pbExists		=@pbExists OUTPUT,
					  @sPickListSearch	=@sPickListSearch

			If @pbExists=1
				set @sWhere=@sWhere+char(10)+"and E.EVENTNO = cast('"+@sPickListSearch+"' as int)"
		End

		If @pbExists=0
		and LEN(@sPickListSearch)<=10
		Begin
			If charindex('XEC.CRITERIANO',@sWhere)>0
				set @sSqlString="Select @pbExists=1"+char(10)+
						"from EVENTS E"+char(10)+
						"join EVENTCONTROL XEC on (XEC.EVENTNO=E.EVENTNO)"+char(10)+
						-- When there is a filtering on the EventControl.EventDescription
						-- in the constructed 'Where' clause then join on the EventControl EC
						-- is required:
						CASE 	WHEN @bUseControlDescription = 1 and 
							    (@sEventDescription is not null or @nEventDescriptionOperator between 2 and 6)
							THEN "join EVENTCONTROL EC	on (EC.EVENTNO=E.EVENTNO)"
						END+char(10)+
						@sWhere+
						"and E.EVENTCODE=@sPickListSearch"
			Else
				set @sSqlString="Select @pbExists=1"+char(10)+
						"from EVENTS E"+char(10)+
						-- When there is a filtering on the EventControl.EventDescription
						-- in the constructed 'Where' clause then join on the EventControl EC
						-- is required:
						CASE 	WHEN @bUseControlDescription = 1 and 
							    (@sEventDescription is not null or @nEventDescriptionOperator between 2 and 6)
							THEN "join EVENTCONTROL EC	on (EC.EVENTNO=E.EVENTNO)"
						END+char(10)+
						@sWhere+
						"and E.EVENTCODE=@sPickListSearch"

			exec sp_executesql @sSqlString,
					N'@pbExists		bit	OUTPUT,
					  @sPickListSearch	nvarchar(100)',
					  @pbExists		=@pbExists OUTPUT,
					  @sPickListSearch	=@sPickListSearch

			If @pbExists=1
			begin
				set @sWhere=@sWhere+char(10)+"and E.EVENTCODE = "+dbo.fn_WrapQuotes(@sPickListSearch,0,0)
			end
			Else If @bUseControlDescription = 1
			begin																		
				If charindex('Join EVENTCONTROL EC',@sFrom)=0
				Begin
					Set @sFrom=@sFrom+char(10)+'Join EVENTCONTROL EC	on (EC.EVENTNO=E.EVENTNO)'
				End				

				set @sWhere=@sWhere+char(10)+"and (E.EVENTCODE Like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)+" OR 	isnull(upper("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+"),"
						   +char(10)+"											       upper("+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+")) like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)+")"
			end
			Else
			begin										
				set @sWhere=@sWhere+char(10)+"and (E.EVENTCODE Like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)+" OR upper("+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+") like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)+")"
			end
		End
		Else If @pbExists=0
		     and LEN(@sPickListSearch)>10
		Begin
			If @bUseControlDescription = 1
			begin								
				If charindex('Join EVENTCONTROL EC',@sFrom)=0
				Begin
					Set @sFrom=@sFrom+char(10)+'Join EVENTCONTROL EC	on (EC.EVENTNO=E.EVENTNO)'
				End

				set @sWhere=@sWhere+char(10)+"and isnull(upper("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+"),"
						   +char(10)+" upper("+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+")) like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)
			end
			Else
			begin
				set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+") like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)
			end
		End
	End
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE SELECT LIST    ****/
/****                                       ****/
/***********************************************/

-- Loop through each column in order to construct the components of the SELECT
While @nCount < @nOutRequestsRowCount + 1
and   @nErrorCode=0
Begin
	-- Get the ColumnID, Name of the column to be published (@sPublishName), the position of the Column 
	-- in the Order By clause (@nOrderPosition), the direction of the sort (@sOrderDirection),
	-- Qualifier to be used to get the column (@sQualifier)   
	Select	@nColumnNo 		= ROWNUMBER,
		@sColumn   		= ID,
		@sPublishName 		= PUBLISHNAME,
		@nOrderPosition		= SORTORDER,
		@sOrderDirection	= CASE WHEN SORTORDER > 0 THEN SORTDIRECTION
					       ELSE NULL
					  END,
		@sQualifier		= QUALIFIER
	from	@tblOutputRequests
	where	ROWNUMBER = @nCount

	Set @nErrorCode = @@ERROR

	If @nErrorCode=0
	Begin
		-- This section uses the following correlation names:
		-- E, I, EC, EC1, ECT, NT

		If @sColumn in ('AlternateEventDescription','EventDisplaySequence')
		Begin
			If @sColumn='AlternateEventDescription'
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura) 
			Else
				Set @sTableColumn='EC.DISPLAYSEQUENCE'

			If charindex('Join EVENTCONTROL EC',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+'Join EVENTCONTROL EC	on (EC.EVENTNO=E.EVENTNO)'
			End
		End

		Else If @sColumn='EventDescription'
		begin
			If @bUseControlDescription = 1
			begin					
				Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+','+char(10)+
							   +dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+')'

				If charindex('Join EVENTCONTROL EC',@sFrom)=0
				Begin
					Set @sFrom=@sFrom+char(10)+'Join EVENTCONTROL EC	on (EC.EVENTNO=E.EVENTNO)'
				End
			end
			Else
			begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)
			end
		end


		Else If @sColumn='EventKey'
		Begin
			Set @sTableColumn='E.EVENTNO'
		End

		Else If @sColumn='EventCode'
		Begin
			Set @sTableColumn='E.EVENTCODE'
		End

		Else If @sColumn='DefaultEventDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)
		End

		Else If @sColumn='EventDefinition'
		Begin
			Set @sTableColumn='E.DEFINITION'
		End

		Else If @sColumn in ('EventCategory',
				     'EventCategoryIconKey')
		Begin
			If @sColumn='EventCategory'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTCATEGORY','CATEGORYNAME',null,'ECT',@sLookupCulture,@pbCalledFromCentura)
			End
			Else Begin
				Set @sTableColumn='ECT.ICONIMAGEID'
			End
			
			If charindex('left join EVENTCATEGORY ECT',@sFrom)=0	
			Begin
				Set @sFrom=@sFrom+char(10)+'left join EVENTCATEGORY ECT		on (ECT.CATEGORYID=E.CATEGORYID)'
			End	
		End	

		Else If @sColumn='MaximumEventCycles'
		Begin
			Set @sTableColumn='E.NUMCYCLESALLOWED'
		End

		Else If @sColumn='EventImportanceLevel'
		Begin
			-- For external users Importance information must be obtained from 
			-- fn_FilterUserEvents (which returns the client importance level) 
			-- rather than from EVENTS which has the internal importance level.			

			If @bIsExternalUser=1
			Begin
				Set @sTableColumn='FE.IMPORTANCELEVEL'
			End
			Else Begin	
				Set @sTableColumn='E.IMPORTANCELEVEL'
			End
		End

		Else If @sColumn='EventImportanceDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)

			If charindex('Left Join IMPORTANCE I',@sFrom)=0
			Begin
				-- For external users Importance information must be obtained from 
				-- fn_FilterUserEvents (which returns the client importance level) 
				-- rather than from EVENTS which has the internal importance level.	
				If @bIsExternalUser=1
				Begin
					Set @sFrom=@sFrom+char(10)+"Left Join IMPORTANCE I		on (I.IMPORTANCELEVEL=FE.IMPORTANCELEVEL)"
				End
				Else Begin	
					Set @sFrom=@sFrom+char(10)+"Left Join IMPORTANCE I		on (I.IMPORTANCELEVEL=E.IMPORTANCELEVEL)"
				End
			End			
		End

		Else If @sColumn='EventIsInUse'
		Begin
			Set @sTableColumn='CASE WHEN(exists(select * from EVENTCONTROL EC1 where EC1.EVENTNO=E.EVENTNO)) THEN cast(1 as bit) ELSE cast(0 as bit) END'
		End

		Else If @sColumn in ('NumberTypeKey','NumberTypeDescription')
		Begin
			If @sColumn='NumberTypeKey'
				Set @sTableColumn='NT.NUMBERTYPE'
			Else
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NUMBERTYPES','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)

			If charindex('Left Join NUMBERTYPES NT',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+"Left Join NUMBERTYPES NT		on (NT.RELATEDEVENTNO=E.EVENTNO)"
			End
		End

	End

	-- If the column is being published then concatenate it to the Select list

	If datalength(@sPublishName)>0
	Begin
		Set @sSelect=@sSelect+@sComma+@sTableColumn+' as ['+@sPublishName+']'
		Set @sComma=', '
	End
	Else Begin
		Set @sPublishName=NULL
	End

	-- If the column is to be sorted on then save the name of the table column along
	-- with the sort details so that later the Order By can be constructed in the correct sequence

	If @nOrderPosition>0
	Begin
		Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
		values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)
		
		Set @nErrorCode = @@ERROR
	End

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
		
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE ORDER BY       ****/
/****                                       ****/
/***********************************************/
If @nErrorCode=0
Begin		
	-- Assemble the "Order By" clause.

	-- If there is more than one row in the @tbOrderBy then the data from the next row gets concatenated 
	-- to the previous row.
	Select @sOrder= ISNULL(NULLIF(@sOrder+',', ','),'')			
			 +CASE WHEN(PublishName is null) 
			       THEN ColumnName
			       ELSE '['+PublishName+']'
			  END
			+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
			from @tbOrderBy
			order by Position			

	If @sOrder is not null
	Begin
		Set @sOrder = ' Order by ' + @sOrder
	End

	Set @nErrorCode=@@Error
End

if @nErrorCode=0
begin
	-- Now execute the constructed SQL to return the result set
	
	If @pbPrintSQL = 1
	Begin
		-- Print out the executed SQL statement:

		Print @sSelect
		Print @sFrom
		Print @sWhere
		Print @sCaseOnlyWhere
		Print @sOrder
		
	End	
			
	exec (@sSelect + @sFrom + @sWhere + @sCaseOnlyWhere + @sOrder)
	select 	@nErrorCode =@@Error,
		@pnRowCount=@@Rowcount

end

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListEvent to public
GO
