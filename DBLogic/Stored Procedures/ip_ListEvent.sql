-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListEvent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListEvent.'
	Drop procedure [dbo].[ip_ListEvent]
	Print '**** Creating Stored Procedure dbo.ip_ListEvent...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_ListEvent
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psColumnIds			nvarchar(4000)	= 'EventKey^EventCode^EventDescription', -- list of the columns (delimited by ^) required either as ouput or for sorting
	@psColumnQualifiers		nvarchar(1000)	= '^^',		-- list of qualifiers  (delimited by ^) that further define the data to be selected
	@psPublishColumnNames		nvarchar(4000)	= 'Key^Code^Description',		-- list of columne names (delimited by ^) to be published as the output name
	@psSortOrderList		nvarchar(1000)	= '1^^',	-- list of numbers (delimited by ^) to indicate the precedence of the matching column in the Order By clause
	@psSortDirectionList		nvarchar(1000)	= 'A^^',	-- list that indicates the direction for the sort of each column included in the Order By
	-- Filter Parameters
	@psEventKey			Nvarchar(11)	= null,	-- This is a string, to allow like searching on event nos.
	@pnEventKeyOperator		tinyint		= null, 
	@psPickListSearch		nvarchar(100)	= null,
	@psEventCode			nvarchar(10)	= null,
	@pnEventCodeOperator		tinyint		= null,
	@psEventDescription		nvarchar(100)	= null, -- Uses the description from event control if available, and from event otherwise.
	@pnEventDescriptionOperator	tinyint		= null,
	@pbIsInUse			Bit		= null, -- Is the event attached to an event control definition?
	@psImportanceLevelFrom		nvarchar(2)	= null,
	@psImportanceLevelTo		nvarchar(2)	= null,
	@pnImportanceLevelOperator	tinyint		= null,
	@pnCriteriaKey			int		= null, -- Returns events related to the event control criteria key provided.
	@pnCriteriaKeyOperator		tinyint		= null,
	@pnCaseKey			int		= null, -- Must be supplied in conjunction with an @psActionKey.
	@psActionKey			nvarchar(2)	= null, -- May be used in conjunction with @pnCaseKey but if supplied alone, 
								-- will return the distinct events associated with any event control for the @psActionKey.
	@pnActionKeyOperator		tinyint		= null

AS

-- PROCEDURE :	ip_ListEvent
-- VERSION :	23
-- DESCRIPTION:	Returns the Event information requested, that matches the filter criteria provided.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 27 Sep 2002	JEK		4	Procedure created
-- 15 Nov 2002	MF 		5	Change the Picklist search to also include any previously entered parameters.
-- 20 Nov 2002	MF		10	Bug 344 correction.  Error occuring on Picklist search when CriteriaNo in use
-- 06 Dec 2002	JB		11	Replaced @sSQLString with @sSqlString
-- 17 Jul 2003	TM		12	RFC76 - Case Insensitive searching
-- 23 Oct 2003	TM	476	13	Error occurs when activating the Case Event pick list. Take out the bracket next
--					to the "and E.EVENTNO)" in the "if @psEventKey is not NULL or @pnEventKeyOperator 
--					between 2 and 6" section.
-- 07 Nov 2003	MF	RFC586	14	Use the fn_WrapQuotes function when constructing SQL with embedded string values
-- 26 Nov 2003	JEK	RFC586	15	Remove extra + in pick list search logic
-- 16 Jan 2004	MF	SQA9621 16	Increase EventDescription to 100 characters.
-- 30 Jan 2004 	TM	RFC846	17	Increase @psPickListSearch datasize from nvarchar(50) to nvarchar(100) 
-- 13 May 2004	TM	RFC1246	18	Implement fn_GetCorrelationSuffix function to generate the correlation suffix 
--					based on the supplied qualifier.
-- 02 Sep 2004	JEK	RFC1377	19	Pass new Centura parameter to fn_WrapQuotes
-- 17 Dec 2004	TM	RFC1674	20	Remove the UPPER function around the EventCode to improve performance.
-- 21 Sep 2009  LP      RFC8047 21      Pass null as ProfileKey parameter to fn_GetCriteriaNo
-- 07 Jul 2011	DL	RFC10830 22	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 15 Apr 2013	DV	R13270	 23	Increase the length of nvarchar to 11 when casting or declaring integer


set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

-- VARIABLES

declare @ErrorCode		int
declare @sSqlString		nvarchar(4000)
declare @sSelect		nvarchar(4000)  -- the SQL list of columns to return
declare	@sFrom			nvarchar(4000)	-- the SQL to list tables and joins
declare @sWhere			nvarchar(4000) 	-- the SQL to filter
declare @sOrder			nvarchar(1000)	-- the SQL sort order
declare @pbExists		bit
declare	@sDelimiter		nchar(1)
declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
declare @nColumnNo		tinyint
declare @sColumn		nvarchar(100)
declare @sPublishName		nvarchar(50)
declare @sQualifier		nvarchar(50)
declare @sTableColumn		nvarchar(1000)
declare @nLastPosition		smallint
declare @nOrderPosition		tinyint
declare @sOrderDirection	nvarchar(5)
declare @sCorrelationSuffix	nvarchar(20)
declare @sTable1		nvarchar(25)

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
declare @tbOrderBy table (
	Position		tinyint		not null,
	Direction		nvarchar(5)	collate database_default not null,
	ColumnName		nvarchar(1000)	collate database_default not null,
	PublishName		nvarchar(50)	collate database_default null,
	ColumnNumber		tinyint		not null)

declare	@bUseControlDescription	bit
declare @nCriteriaKey		int
declare @nCriteriaKeyOperator	tinyint		
declare @sActionKey		nvarchar(2)
declare @nActionKeyOperator	tinyint		

-- CONSTANTS

declare @String			nchar(1),
	@Date			nchar(2),
	@Numeric		nchar(1),
	@Text			nchar(1)

-- Initialisation
set @String	='S'
set @Date	='DT'
set @Numeric	='N'
set @Text	='T'

-- Case Insensitive searching

set @psPickListSearch	= upper(@psPickListSearch)
set @psEventCode      	= upper(@psEventCode)
set @psEventDescription	= upper(@psEventDescription)


set @ErrorCode	=0
set @sDelimiter	='^'
set @sSelect	='Select '
set @sFrom	='From EVENTS E'

If @pnCriteriaKey is not NULL
or @pnCriteriaKeyOperator between 2 and 6
or @pnCaseKey is not NULL
or @pnActionKeyOperator between 2 and 6
	set @bUseControlDescription = 1
else
	set @bUseControlDescription = 0

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE SELECT LIST    ****/
/****                                       ****/
/***********************************************/

-- Split the list of columns required into each of the separate columns (tokenise) and then loop through
-- each column in order to construct the components of the SELECT
-- Using the "min" function as this returns NULL if nothing is found

set @sSqlString="
Select	@nColumnNo=min(InsertOrder),
	@sColumn  =min(Parameter)
From	dbo.fn_Tokenise(@psColumnIds, @sDelimiter)
Where	InsertOrder=1"

exec @ErrorCode=sp_executesql @sSqlString,
				N'@nColumnNo	tinyint		OUTPUT,
				  @sColumn	nvarchar(50)	OUTPUT,
				  @psColumnIds  nvarchar(4000),
				  @sDelimiter   nchar(1)',
				  @nColumnNo  =@nColumnNo	OUTPUT,
				  @sColumn    =@sColumn		OUTPUT,
				  @psColumnIds=@psColumnIds,
				  @sDelimiter =@sDelimiter

While @nColumnNo is not NULL
and   @ErrorCode=0
Begin
	-- Get the Name of the column to be published
	set @sSqlString="
	Select	@sPublishName=min(Parameter)
	From	dbo.fn_Tokenise(@psPublishColumnNames, @sDelimiter)
	Where	InsertOrder=@nColumnNo"

	exec @ErrorCode=sp_executesql @sSqlString,
				N'@sPublishName		nvarchar(50)	OUTPUT,
				  @nColumnNo		tinyint,
				  @psPublishColumnNames nvarchar(4000),
				  @sDelimiter   	nchar(1)',
				  @sPublishName		=@sPublishName	OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psPublishColumnNames	=@psPublishColumnNames,
				  @sDelimiter		=@sDelimiter

	-- Get any Qualifier to be used to get the column
	If @ErrorCode=0
	Begin
		set @sSqlString="
		Select	@sQualifier=min(Parameter)
		From	dbo.fn_Tokenise(@psColumnQualifiers, @sDelimiter)
		Where	InsertOrder=@nColumnNo"

		exec @ErrorCode=sp_executesql @sSqlString,
				N'@sQualifier		nvarchar(50)	OUTPUT,
				  @nColumnNo		tinyint,
				  @psColumnQualifiers	nvarchar(4000),
				  @sDelimiter   	nchar(1)',
				  @sQualifier		=@sQualifier	OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psColumnQualifiers	=@psColumnQualifiers,
				  @sDelimiter		=@sDelimiter

		-- If a Qualifier exists then generate a value from it that can be used
		-- to create a unique Correlation name for the table

		If  @ErrorCode=0
		and @sQualifier is not null
		Begin
			Set @sCorrelationSuffix=dbo.fn_GetCorrelationSuffix(@sQualifier)
		End 
		Else Begin
			Set @sCorrelationSuffix=NULL
		End
	End

	-- Get the position of the Column in the Order By clause
	If @ErrorCode=0
	Begin
		set @sSqlString="
		Select	@nOrderPosition=min(cast(Parameter as tinyint))
		From	dbo.fn_Tokenise(@psSortOrderList, @sDelimiter)
		Where	InsertOrder=@nColumnNo"

		exec @ErrorCode=sp_executesql @sSqlString,
				N'@nOrderPosition	tinyint	OUTPUT,
				  @nColumnNo		tinyint,
				  @psSortOrderList	nvarchar(1000),
				  @sDelimiter   	nchar(1)',
				  @nOrderPosition	=@nOrderPosition OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psSortOrderList	=@psSortOrderList,
				  @sDelimiter		=@sDelimiter
	End

	-- If the column is to be included in the Order by then get the direction of the sort
	If  @ErrorCode=0
	and @nOrderPosition>0
	Begin
		set @sSqlString="
		Select	@sOrderDirection=Parameter
		From	dbo.fn_Tokenise(@psSortDirectionList, @sDelimiter)
		Where	InsertOrder=@nColumnNo"

		exec @ErrorCode=sp_executesql @sSqlString,
				N'@sOrderDirection	nchar(1) OUTPUT,
				  @nColumnNo		tinyint,
				  @psSortDirectionList	nvarchar(1000),
				  @sDelimiter   	nchar(1)',
				  @sOrderDirection	=@sOrderDirection OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psSortDirectionList	=@psSortDirectionList,
				  @sDelimiter		=@sDelimiter
	End	

	-- Now test the value of the Column to determine what table and column is required
	-- in the Select.  Note that if the PublishName is null then the column will not be
	-- returned in the result set however it is probably required for sorting.

	If @ErrorCode=0
	Begin
		-- This section uses the following correlation names:
		-- E, I, EC, EC1, NT

		If @sColumn in ('AlternateEventDescription','EventDisplaySequence')
		Begin
			If @sColumn='AlternateEventDescription'
				Set @sTableColumn='EC.EVENTDESCRIPTION'
			Else
				Set @sTableColumn='EC.DISPLAYSEQUENCE'

			If charindex('Join EVENTCONTROL EC',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+"Join EVENTCONTROL EC			on (EC.EVENTNO=E.EVENTNO)"
			End
		End

		Else If @sColumn='EventDescription'
		begin
			If @bUseControlDescription = 1
			begin
				Set @sTableColumn='isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION)'

				If charindex('Join EVENTCONTROL EC',@sFrom)=0
				Begin
					Set @sFrom=@sFrom+char(10)+"Join EVENTCONTROL EC			on (EC.EVENTNO=E.EVENTNO)"
				End
			end
			Else
			begin
				Set @sTableColumn='E.EVENTDESCRIPTION'
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
			Set @sTableColumn='E.EVENTDESCRIPTION'
		End

		Else If @sColumn='EventDefinition'
		Begin
			Set @sTableColumn='E.DEFINITION'
		End

		Else If @sColumn='MaximumEventCycles'
		Begin
			Set @sTableColumn='E.NUMCYCLESALLOWED'
		End

		Else If @sColumn='EventImportanceLevel'
		Begin
			Set @sTableColumn='E.IMPORTANCELEVEL'
		End

		Else If @sColumn='EventImportanceDescription'
		Begin
			Set @sTableColumn='I.IMPORTANCEDESC'

			If charindex('Left Join IMPORTANCE I',@sFrom)=0
			Begin
				Set @sFrom=@sFrom+char(10)+"Left Join IMPORTANCE I		on (I.IMPORTANCELEVEL=E.IMPORTANCELEVEL)"
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
				Set @sTableColumn='NT.DESCRIPTION'

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
		values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, 
		       Case When(@sOrderDirection='D') Then ' DESC' ELSE ' ASC' End)
	End

	-- Get the next Column
	If @ErrorCode=0
	Begin
		Set @sSqlString="
		Select	@nColumnNoOUT=min(InsertOrder),
			@sColumnOUT  =min(Parameter)
		From	dbo.fn_Tokenise(@psColumnIds, @sDelimiter)
		Where	InsertOrder=@nColumnNo+1"

		exec @ErrorCode=sp_executesql @sSqlString,
				N'@nColumnNoOUT	tinyint		OUTPUT,
				  @sColumnOUT	nvarchar(255)	OUTPUT,
				  @nColumnNo	tinyint,
				  @psColumnIds  nvarchar(4000),
				  @sDelimiter   nchar(1)',
				  @nColumnNoOUT=@nColumnNo	OUTPUT,
				  @sColumnOUT  =@sColumn	OUTPUT,
				  @nColumnNo   =@nColumnNo,
				  @psColumnIds =@psColumnIds,
				  @sDelimiter  =@sDelimiter
	End
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE ORDER BY       ****/
/****                                       ****/
/***********************************************/

If @ErrorCode=0
Begin
	Set @nLastPosition=-1

	Select	@sTableColumn   =ColumnName,
		@sPublishName	=PublishName,
		@sOrderDirection=Direction,
		@nOrderPosition =Position,
		@nColumnNo      =ColumnNumber
	From 	@tbOrderBy
	Where	Position=(	Select min(Position)
				from @tbOrderBy)

	Set @ErrorCode=@@Error

	If @nOrderPosition is not null
	Begin
		set @sOrder='Order By '
		Set @sComma =NULL
	End
End
-- Loop through each column to sort on.
-- If the CLASS column is to be sorted on then also include an extra sort on the numeric 
-- equivalent of the class.

While @nOrderPosition>@nLastPosition
and   @ErrorCode=0
Begin
	Set @sOrder=@sOrder
			+@sComma
			+Case When(Charindex('.CLASS',@sTableColumn)>0)
				Then 'Case WHEN(isnumeric('+@sTableColumn+')=1) THEN cast('+@sTableColumn+' as numeric) END'
				     +Case WHEN(@sPublishName is not null)
					Then @sOrderDirection+',['+@sPublishName+']'
				      End
			      When(@sPublishName is null) 
				Then @sTableColumn
				Else '['+@sPublishName+']'
			 End
			+@sOrderDirection
	Set @sComma=','
	Set @nLastPosition=@nOrderPosition

	Select	@sTableColumn   =ColumnName,
		@sPublishName	=PublishName,
		@sOrderDirection=Direction,
		@nOrderPosition =Position,
		@nColumnNo      =ColumnNumber
	From 	@tbOrderBy
	Where	Position=(	Select min(Position)
				from @tbOrderBy
				Where Position>@nOrderPosition)

	Set @ErrorCode=@@Error
End


/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE CLAUSE   ****/
/****                                       ****/
/***********************************************/

if @ErrorCode=0
begin
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	set @sWhere = char(10)+"WHERE 1=1"

	if @psEventKey is not NULL
	or @pnEventKeyOperator between 2 and 6
	begin
		set @sWhere = @sWhere+char(10)+"and E.EVENTNO"+dbo.fn_ConstructOperator(@pnEventKeyOperator,@Numeric,@psEventKey, null,0)
	end
	
	if @psEventCode is not NULL
	or @pnEventCodeOperator between 2 and 6
	begin
		set @sWhere = @sWhere+char(10)+"and E.EVENTCODE"+dbo.fn_ConstructOperator(@pnEventCodeOperator,@String,@psEventCode, null,0)
	end

	if @psEventDescription is not NULL
	or @pnEventDescriptionOperator between 2 and 6
	begin
		If charindex('Join EVENTCONTROL EC',@sFrom)>0
		begin
			set @sWhere = @sWhere+char(10)+"and isnull(upper(EC.EVENTDESCRIPTION), upper(E.EVENTDESCRIPTION))"+dbo.fn_ConstructOperator(@pnEventDescriptionOperator,@String,@psEventDescription, null,0)
		end
		Else
		begin
			set @sWhere = @sWhere+char(10)+"and upper(E.EVENTDESCRIPTION)"+dbo.fn_ConstructOperator(@pnEventDescriptionOperator,@String,@psEventDescription, null,0)
		end
	end

	If @pbIsInUse = 1
	begin
		set @sWhere=@sWhere+char(10)+"and exists (select * from EVENTCONTROL XEC1 WHERE XEC1.EVENTNO = E.EVENTNO)"
	end
	Else If @pbIsInUse = 0
	begin
		set @sWhere=@sWhere+char(10)+"and not exists (select * from EVENTCONTROL XEC1 WHERE XEC1.EVENTNO = E.EVENTNO)"
	end

	If @psImportanceLevelFrom is not NULL
	or @psImportanceLevelTo   is not NULL
	or @pnImportanceLevelOperator between 2 and 6
	begin
		set @sWhere=@sWhere+char(10)+"	and E.IMPORTANCELEVEL"+dbo.fn_ConstructOperator(@pnImportanceLevelOperator,@String,@psImportanceLevelFrom, @psImportanceLevelTo,0)
	end

	If @pnCaseKey is not null
	and @psActionKey is not null
	begin

		set @nCriteriaKey = dbo.fn_GetCriteriaNo(
			@pnCaseKey,
			"E",
			@psActionKey,
			getdate(),
			NULL)

		set @nCriteriaKeyOperator = @pnActionKeyOperator
		set @sActionKey = NULL
		set @nActionKeyOperator = NULL
	end
	Else
	begin
		set @nCriteriaKey = @pnCriteriaKey
		set @nCriteriaKeyOperator = @pnCriteriaKeyOperator
		set @sActionKey = @psActionKey
		set @nActionKeyOperator = @pnActionKeyOperator
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
			Set @sFrom=@sFrom+char(10)+"Join EVENTCONTROL XEC			on (XEC.EVENTNO=E.EVENTNO)"
		end

		set @sWhere=@sWhere+char(10)+"	and XEC.CRITERIANO"+dbo.fn_ConstructOperator(@nCriteriaKeyOperator,@Numeric,@nCriteriaKey, NULL,0)

	end

	If @sActionKey is not NULL
	or @nActionKeyOperator between 2 and 6
	begin
		set @sWhere=@sWhere+char(10)+"	and exists
			(select *
			from CRITERIA XC1
			JOIN EVENTCONTROL XEC2 ON (E.EVENTNO = XEC2.EVENTNO and XEC2.CRITERIANO = XC1.CRITERIANO)
			WHERE XC1.ACTION"+dbo.fn_ConstructOperator(@nActionKeyOperator,@String,@sActionKey, NULL,0)+")"

	end

	If LEN(@psPickListSearch)>0
	Begin
		set @pbExists=0

		If isnumeric(@psPickListSearch)=1
		Begin
			If charindex('XEC.CRITERIANO',@sWhere)>0
				set @sSqlString="Select @pbExists=1"+char(10)+
						"from EVENTS E"+char(10)+
						"join EVENTCONTROL XEC on (XEC.EVENTNO=E.EVENTNO)"+char(10)+
						@sWhere+
						"and E.EVENTNO=@psPickListSearch"
			Else
				set @sSqlString="Select @pbExists=1"+char(10)+
						"from EVENTS E"+char(10)+
						@sWhere+
						"and E.EVENTNO=@psPickListSearch"

			exec sp_executesql @sSqlString,
					N'@pbExists		bit	OUTPUT,
					  @psPickListSearch	nvarchar(100)',
					  @pbExists		=@pbExists OUTPUT,
					  @psPickListSearch	=@psPickListSearch

			If @pbExists=1
				set @sWhere=@sWhere+char(10)+"and E.EVENTNO = cast('"+@psPickListSearch+"' as int)"
		End

		If @pbExists=0
		and LEN(@psPickListSearch)<=10
		Begin
			If charindex('XEC.CRITERIANO',@sWhere)>0
				set @sSqlString="Select @pbExists=1"+char(10)+
						"from EVENTS E"+char(10)+
						"join EVENTCONTROL XEC on (XEC.EVENTNO=E.EVENTNO)"+char(10)+
						@sWhere+
						"and E.EVENTCODE=@psPickListSearch"
			Else
				set @sSqlString="Select @pbExists=1"+char(10)+
						"from EVENTS E"+char(10)+
						@sWhere+
						"and E.EVENTCODE=@psPickListSearch"

			exec sp_executesql @sSqlString,
					N'@pbExists		bit	OUTPUT,
					  @psPickListSearch	nvarchar(100)',
					  @pbExists		=@pbExists OUTPUT,
					  @psPickListSearch	=@psPickListSearch

			If @pbExists=1
			begin
				set @sWhere=@sWhere+char(10)+"and E.EVENTCODE = "+dbo.fn_WrapQuotes(@psPickListSearch,0,0)
			end
			Else If @bUseControlDescription = 1
			begin
				set @sWhere=@sWhere+char(10)+"and (E.EVENTCODE Like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)+" OR isnull(upper(EC.EVENTDESCRIPTION), upper(E.EVENTDESCRIPTION)) like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)+")"
			end
			Else
			begin
				set @sWhere=@sWhere+char(10)+"and (E.EVENTCODE Like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)+" OR upper(E.EVENTDESCRIPTION) like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)+")"
			end
		End
		Else If @pbExists=0
		     and LEN(@psPickListSearch)>10
		Begin
			If @bUseControlDescription = 1
			begin
				set @sWhere=@sWhere+char(10)+"and isnull(upper(EC.EVENTDESCRIPTION), upper(E.EVENTDESCRIPTION)) like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)
			end
			Else
			begin
				set @sWhere=@sWhere+char(10)+"and upper(E.EVENTDESCRIPTION) like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)
			end
		End
	End
End


if @ErrorCode=0
begin
	-- Now execute the constructed SQL to return the result set

	exec (@sSelect + @sFrom + @sWhere + @sOrder)
	select 	@ErrorCode =@@Error,
		@pnRowCount=@@Rowcount

end

Return @ErrorCode
GO

Grant execute on dbo.ip_ListEvent to public
GO
