/******************************************************************************************************************/
/*** 13103 Create trigger tD_CASETEXT_Classes									***/
/******************************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tD_CASETEXT_Classes')
   begin
    PRINT 'Refreshing trigger tD_CASETEXT_Classes...'
    DROP TRIGGER tD_CASETEXT_Classes
   end
  go

CREATE TRIGGER tD_CASETEXT_Classes on CASETEXT AFTER DELETE NOT FOR REPLICATION 
as
-- TRIGGER :	tD_CASETEXT_Classes
-- VERSION :	3
-- DESCRIPTION:	Ensures at least one CASETEXT row (of type 'G') exists for 
--		each of the case's classes.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Sep 2006	IB	13103	1	Trigger created
-- 19 Sep 2006	IB	13103	2	Add only those classes that are still in the case.
-- 21 Oct 2011	DL	19985	3	Fixed bug error when a class, containging more than 11 characters, is removed from a case

Begin


	Declare @sLocalClasses 	nvarchar(254)
	Declare @sClass 	nvarchar(100)
	Declare @nCaseId 	int
	Declare @nIndex 	int
	Declare @nRowCount 	int
	Declare @sGSTextType 	nvarchar(2)

	Set @sGSTextType = 'G'
	
	-- Create a table to store the deleted data
	Declare @tbRows table (SEQ int IDENTITY(1,1), CASEID INT, CLASS NVARCHAR(100) collate database_default)

	Insert into 	@tbRows( CASEID, CLASS )
		Select 	CASEID, CLASS 
		from 	deleted 
		where 	CLASS is not NULL
			and TEXTTYPE = @sGSTextType

	Set @nIndex = 1

	Set @nRowCount = SCOPE_IDENTITY() --(SELECT COUNT(*) FROM @tbRows)

	While @nIndex <= @nRowCount
	Begin
		Select 	@nCaseId = R.CASEID,
			@sClass = R.CLASS,
			@sLocalClasses = C.LOCALCLASSES
		from 	@tbRows as R
		join 	CASES as C on (C.CASEID = R.CASEID)
		where 	R.SEQ = @nIndex

		-- Re-insert a case text row of type 'G' for any classes that 
		-- might be deleted by a user 
		Insert into CASETEXT(	
			CASEID, 
			TEXTTYPE, 
			TEXTNO, 
			CLASS, 
			LANGUAGE, 
			MODIFIEDDATE, 
			LONGFLAG, 
			SHORTTEXT, 
			TEXT)
		Select 	@nCaseId, 
			@sGSTextType, 
			MAXTEXT.MAXTEXTNO + 1, 
			@sClass, 
			null, 
			getdate(), 
			0, 
			null, 
			null 
		from (Select isnull(MAX(TEXTNO), -1) as MAXTEXTNO 
			from CASETEXT 
			where CASEID = @nCaseId 
			and TEXTTYPE = @sGSTextType) as MAXTEXT
		where 	not exists 
			(Select 0 
				from CASETEXT
				where CASEID = @nCaseId
				and CLASS = @sClass
				and TEXTTYPE = @sGSTextType)
			and exists
			(Select 0
				from (Select Parameter from dbo.fn_Tokenise(@sLocalClasses, ',')) as CC
				where CC.Parameter = @sClass)

		Set @nIndex = @nIndex + 1
	End
	

End
go
