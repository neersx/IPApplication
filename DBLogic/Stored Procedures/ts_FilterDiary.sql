-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_FilterDiary
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ts_FilterDiary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ts_FilterDiary.' 
	drop procedure dbo.ts_FilterDiary
	print '**** Creating procedure dbo.ts_FilterDiary...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ts_FilterDiary
(
	@psReturnClause			nvarchar(4000)  = null output, 
	@psCurrentDiaryTable		nvarchar(60)	= null output,	-- is the name of the the global temporary table that may hold the keys of Diary entries.
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbIsExternalUser		bit		= null,
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit		= 0	-- Indicates that Centura called the stored procedure
)		
-- PROCEDURE :	ts_FilterDiary
-- VERSION :	2
-- DESCRIPTION:	This stored procedure is responsible for the management of selected/deselected 
--		rows in the search result set (EntryDateGroup).
-- CALLED BY :	

-- MODIFICTIONS :
-- Date		Who	Number	Version	Details
-- ----		---	-------	-------	-------------------------------------
-- 27 Jun 2005	TM	RFC2556	1	Procedure created
-- 29 Jun 2005	TN	RFC2556	2	Correct the comment and exclude the time portion from the D.STARTTIME
--					when filtering on the Date.
AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

Declare @nTableCount		tinyint

Declare @sCurrentTable 		nvarchar(50)	

Declare @pbExists		bit
Declare @nOperator		bit

Declare @nCaseCount		int

Declare @sSql			nvarchar(4000)
Declare @sSQLString		nvarchar(4000)
Declare @sSelectList		nvarchar(4000)  -- the SQL list of columns to return
declare @sDiaryWhere		nvarchar(4000)
Declare @sNotExists		nvarchar(100)	
Declare @sWhere			nvarchar(4000) 	-- the SQL to filter
Declare @sOrder			nvarchar(1000)	-- the SQL sort order

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int 	

-- Intialise Variables
Set @nErrorCode			=0 

-- Create an XML document in memory and then retrieve the information 
-- from the rowset using OPENXML		
exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

Set @nErrorCode = @@Error

If @nErrorCode = 0
Begin
	exec @nErrorCode=dbo.ts_ConstructDiaryWhere	
				@psDiaryWhere		= @sDiaryWhere	  	OUTPUT, 			
				@pnUserIdentityId	= @pnUserIdentityId,	
				@psCulture		= @psCulture,	
				@pbExternalUser		= @pbIsExternalUser,
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
				@pbCalledFromCentura	= @pbCalledFromCentura			 
End

-- Check to see if there are any selected/deselected rows:	
If @nErrorCode=0
Begin
	Set @sSql="
	Select	@nOperator	= Operator	
	from	OPENXML (@idoc, '//ts_ListDiary/FilterCriteria/EntryDateGroup',2)
		WITH (
		      Operator	tinyint	'@Operator/text()'
		     )
	Where Operator in (1,0)"

	exec @nErrorCode=sp_executesql @sSql,
				N'@nOperator	bit		Output,
				  @idoc		int',
				  @nOperator	= @nOperator	Output,
				  @idoc		= @idoc
End

If  @nErrorCode = 0
and @nOperator is not null
Begin
	-- Get the name of the temporary table passed in as a parameter 
	If @nErrorCode=0
	Begin
		If @psCurrentDiaryTable is null
		Begin
			Set @sCurrentTable = '##SEARCHDIARY_' + Cast(@@SPID as varchar(10))
			Set @psCurrentDiaryTable = @sCurrentTable
		End
		Else Begin		
			Set @sCurrentTable = @psCurrentDiaryTable
		End
	End		

	-- Drop the temporary table if it exists:
	If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable)
	and @nErrorCode=0
	Begin
		Set @sSql = "drop table "+@sCurrentTable			
		exec @nErrorCode=sp_executesql @sSql
	End

	If @nErrorCode=0
	Begin
		Set @sSql = 'Create Table ' + @sCurrentTable + ' (StaffKey int, EntryNo int)'	
		exec @nErrorCode=sp_executesql @sSql				
	End

	If @nErrorCode=0
	Begin
		Set @sSelectList = 	'Insert into ' + @sCurrentTable + ' (StaffKey, EntryNo)'+char(10)+
				    	'select XD.EMPLOYEENO, XD.ENTRYNO'+char(10)+
					@sDiaryWhere
		exec (@sSelectList)
	End

	-- Add explicitly selected Billable WIP combinations:
	If  @nErrorCode = 0
	and @nOperator = 0
	Begin
		Set @sSql="Delete "+@sCurrentTable+char(10)+
			  "from "  +@sCurrentTable+" X"+char(10)+
			  "join DIARY D on (D.EMPLOYEENO = X.StaffKey"+char(10)+
			  "		and D.ENTRYNO = X.EntryNo)"+char(10)+
			  "left join (	select Date"+char(10)+
		  	  " 		from	OPENXML (@idoc, '//ts_ListDiary/FilterCriteria/EntryDateGroup/Date', 2)"+char(10)+
	 	 	  "		WITH (	Date	datetime	'text()')"+char(10)+
	  	  	  "	) X2 	on  (X2.Date = convert(datetime, convert(char(10),convert(datetime,D.STARTTIME,120),120), 120))"+char(10)+		
			  "Where X2.Date is null"

		exec @nErrorCode=sp_executesql @sSql,
						N'@idoc		int',
						  @idoc		= @idoc

	End
	Else If  @nErrorCode = 0
	     and @nOperator = 1
	Begin
		Set @sSql=
		  "Delete "+@sCurrentTable+char(10)+
		  "from "  +@sCurrentTable+" X"+char(10)+
		  "join DIARY D on (D.EMPLOYEENO = X.StaffKey"+char(10)+
		  "		and D.ENTRYNO = X.EntryNo)"+char(10)+
		  "join (	select Date"+char(10)+
		  " 		from	OPENXML (@idoc, '//ts_ListDiary/FilterCriteria/EntryDateGroup/Date', 2)"+char(10)+
	 	  "		WITH (	Date		datetime	'text()')"+char(10)+
	  	  "	) X2 	on  (X2.Date = convert(datetime, convert(char(10),convert(datetime,D.STARTTIME,120),120), 120))"	

		exec @nErrorCode=sp_executesql @sSql,
					N'@idoc		int',
					  @idoc		= @idoc
	End

	-- The current Where clause can now be modified to just return the Entries 
	-- in the temporary table.
	Set @psReturnClause =	char(10)+"	FROM      DIARY XD"+
				char(10)+"	where exists (	select * from "+@sCurrentTable+" XD2"+
				char(10)+"			where (XD2.StaffKey = XD.EMPLOYEENO"+
				char(10)+"	  		  and  XD2.EntryNo = XD.ENTRYNO))"
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc

End
Else If  @nErrorCode = 0
     and @nOperator is null
Begin
	-- The current Where clause can now be modified to just return 
	-- the where clause:  
	Set @psReturnClause = @sDiaryWhere
End

RETURN @nErrorCode
go

grant execute on dbo.ts_FilterDiary  to public
go



