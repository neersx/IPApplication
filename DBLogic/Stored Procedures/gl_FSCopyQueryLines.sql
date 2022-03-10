-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_FSCopyQueryLines
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_FSCopyQueryLines]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_FSCopyQueryLines.'
	Drop procedure [dbo].[gl_FSCopyQueryLines]
End
Print '**** Creating Stored Procedure dbo.gl_FSCopyQueryLines...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_FSCopyQueryLines
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(5) 	= null,
	@pnOldQueryId		int,		-- Base Query Id
	@pnNewQueryId		int		-- New Query Id where Lines Details will be copied to 
)
as
-- PROCEDURE:	gl_FSCopyQueryLines
-- VERSION:	1
-- SCOPE:	Centura
-- DESCRIPTION:	The function Copy Query Lines Information from @pnOldQueryId to @pnNewQueryId

-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 3-Sep-2004  MB	9658	1	Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @nCount 	int
Declare @nMaxOldLines 	int
Declare @nIndex 	int
Declare @nOldLineId	int
Declare @nNewLineId 	int
Declare @nMaxLineNo	int
Declare @nOldFilterId	int
Declare @nNewFilterId	int

Declare @tblFilterID table  (	
			ROWNUMBER	int IDENTITY not null,
			FILTERID	int,
			LINEID		int )

Declare @tblOldLines table  (
			ROWNUMBER	int IDENTITY not null,
			LINEID		int not null,
			NEWLINEID 	int)

Declare @tblOldTotals table  (
			ROWNUMBER	int IDENTITY not null,
			LINEID		int not null,
			NEWLINEID 	int)


Set @nErrorCode = 0

 -- check if the user Save As query into the existing one (overwrite)
If @nErrorCode = 0
Begin
	select @nCount = count(1) 
	from QUERYLINE 
	where QUERYID = @pnNewQueryId

	Set @nErrorCode = @@ERROR
End

-- if the 'Save As" query is an existing one, then we neew to delete all lines and line informatiom (TOTALS and FILTER)
If @nErrorCode = 0 and @nCount > 0
Begin

	Insert into @tblFilterID (FILTERID) 
	(select FILTERID from QUERYLINE where QUERYID = @pnNewQueryId)
	Set @nErrorCode = @@ERROR
	
	If @nErrorCode = 0
	Begin	
		Delete from QUERYLINETOTAL where LINEID in (select  LINEID from QUERYLINE  where QUERYID = @pnNewQueryId )
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin		
		Delete from QUERYLINE where QUERYID = @pnNewQueryId
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		Delete from QUERYFILTER where FILTERID in (select FILTERID from @tblFilterID )
		Set @nErrorCode = @@ERROR
	End

End

-- get maximum number of lines in the "Copy From" query
If @nErrorCode = 0
Begin
	Select @nMaxOldLines = count(1) from QUERYLINE where QUERYID = @pnOldQueryId
	Set @nErrorCode = @@ERROR
End

-- copy old line id into temporary table
If @nErrorCode = 0 and @nMaxOldLines > 0
Begin
	Insert into @tblOldLines (LINEID ) 
	(select LINEID 
	from QUERYLINE 
	where QUERYID = @pnOldQueryId )

	Set @nErrorCode = @@ERROR
End

Set @nIndex = 1

-- Loop through each line in order to copy QUERYLINE
While @nIndex <= @nMaxOldLines
and   @nErrorCode=0
Begin

	Select @nOldLineId = LINEID  from @tblOldLines 
	where ROWNUMBER = @nIndex
	Set @nErrorCode = @@ERROR

	If @nErrorCode = 0
	Begin
		Update LASTINTERNALCODE set INTERNALSEQUENCE= INTERNALSEQUENCE + 1
		where TABLENAME = 'QUERYLINE'
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		Select @nNewLineId = INTERNALSEQUENCE
		from LASTINTERNALCODE 
		where TABLENAME = 'QUERYLINE'
		Set @nErrorCode = @@ERROR
	End
	-- TID columns is not included in the column list. Will be handled by a stored procedure

	If @nErrorCode = 0
	Begin
		Insert into QUERYLINE ( LINEID, QUERYID, FILTERID, LABEL, DESCRIPTION, ALIGNDESCRIPTION, LINEPOSITION, ISPRINTABLE, LINETYPE, FONTNAME, FONTSIZE, BOLDSTYLE, ITALICSTYLE, UNDERLINESTYLE, SHOWCURRENCYSYMBOL, NEGATIVESIGNTYPE, NEGATIVESIGNCOLOUR )
		(select 	@nNewLineId, @pnNewQueryId, FILTERID, LABEL, DESCRIPTION, ALIGNDESCRIPTION, LINEPOSITION, ISPRINTABLE, LINETYPE, FONTNAME, FONTSIZE, BOLDSTYLE, ITALICSTYLE, UNDERLINESTYLE, SHOWCURRENCYSYMBOL, NEGATIVESIGNTYPE, NEGATIVESIGNCOLOUR 
		from QUERYLINE where LINEID =@nOldLineId )
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		Update @tblOldLines set NEWLINEID = @nNewLineId 
		where LINEID = @nOldLineId
		Set @nErrorCode = @@ERROR
	End

	Set @nIndex = @nIndex + 1

End

-- copy filters

-- get maximum number of lines in the "Copy From" query where Filter Id is not null
If @nErrorCode = 0
Begin
	select @nMaxOldLines = count(1) 
	from QUERYLINE 
	where 	QUERYID = @pnOldQueryId 
	and 	FILTERID is not null
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0 and @nMaxOldLines > 0
Begin
	Delete from @tblFilterID
	Set @nErrorCode = @@ERROR

	If @nErrorCode = 0
	Begin
		Insert into @tblFilterID (FILTERID, LINEID ) (select FILTERID, LINEID from QUERYLINE where QUERYID = @pnOldQueryId and FILTERID is not null)

		select 	@nCount = @@IDENTITY  - @nMaxOldLines + 1,
			@nMaxLineNo = @@IDENTITY,
			@nErrorCode = @@ERROR
	End
End

While @nCount <= @nMaxLineNo and @nErrorCode = 0
Begin
	Select @nOldFilterId = FILTERID, @nOldLineId = LINEID 
	from @tblFilterID 
	where ROWNUMBER = @nCount
	Set @nErrorCode = @@ERROR

	If @nErrorCode = 0
	Begin

		Insert into QUERYFILTER (PROCEDURENAME, XMLFILTERCRITERIA ) 
		(select  PROCEDURENAME, XMLFILTERCRITERIA from QUERYFILTER
		where FILTERID = @nOldFilterId )
		-- Get new filter id
		Select 	@nNewFilterId = @@IDENTITY, 
			@nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
	-- select new linis id corresponded to old line id
		Select @nNewLineId = NEWLINEID from @tblOldLines 
		where LINEID = @nOldLineId
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		Update QUERYLINE set FILTERID = @nNewFilterId 
		where LINEID = @nNewLineId
		Set @nErrorCode = @@ERROR
	End

	Set @nCount = @nCount + 1
End


-- Copy Totals
If @nErrorCode = 0
Begin
	Insert into QUERYLINETOTAL (LINEID, TOTALLINEID, TOTALSIGN, POSITION )
	select C.NEWLINEID, D.NEWLINEID, A.TOTALSIGN, A.POSITION 
	from QUERYLINETOTAL A join QUERYLINE B on (A.LINEID = B.LINEID)
	join @tblOldLines C on (A.LINEID = C.LINEID)
	join @tblOldLines D on (A.TOTALLINEID = D.LINEID)
	where B.QUERYID  = @pnOldQueryId

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.gl_FSCopyQueryLines to public
GO
