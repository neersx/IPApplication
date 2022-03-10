/******************************************************************************************************************/
/*** 10856 Create trigger tU_CASES_Classes									***/
/******************************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tU_CASES_Classes')
   begin
    PRINT 'Refreshing trigger tU_CASES_Classes...'
    DROP TRIGGER tU_CASES_Classes
   end
  go

CREATE TRIGGER tU_CASES_Classes on CASES AFTER UPDATE NOT FOR REPLICATION 
as
-- TRIGGER :	tU_CASES_Classes
-- VERSION :	7
-- DESCRIPTION:	Ensures at least 1 CASETEXT row exists for each of the case's classes

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 05 Jun 2006	AT	SQA10856	1	Trigger created.
-- 26 Jun 2006	AT	SQA10856	2	Updating of TextNo was causing problems with deletes on text tab.
-- 22 Aug 2006	IB	SQA13103	3	For trademark cases, when a class is deleted, 
--						the class information remains in CASETEXT table
-- 08 Sep 2009	MF	SQA18014	4	Safeguard against an empty string Class being inserted
-- 09 Nov 2012 DL	SQA21019	5	Handle  class code that has more than 11 characters by left(class,11)
-- 28 Sep 2017  DV	R74974		6	Update Case Text with Default Class heading
-- 15 Apr 2019	DV  DR46954		7	Add default CASETEXT row when adding Classes.

Begin

If Update(LOCALCLASSES)
Begin

	Declare @psClasses nvarchar(254)
	Declare @pnCaseId int
	Declare @nIndex int
	Declare @nRowCount int
	Declare @sCountryCode nvarchar(3)
	Declare @sPropertyTypeCode nchar(1)
	Declare @bAllowItems bit
	Declare @bAllowSubClass bit
	
		-- Create a table to store the updated data
		Declare @tbRows table (SEQ int IDENTITY(1,1), CASEID INT, CLASSES NVARCHAR(254))
	
		Insert into @tbRows( CASEID, CLASSES )
			select CASEID, LOCALCLASSES 
			from inserted 
			--where LOCALCLASSES is not null
	
		Set @nIndex = 1
	
		Set @nRowCount = (SELECT COUNT(*) FROM @tbRows)
	
		While @nIndex <= @nRowCount
		Begin
			Select @pnCaseId = CASEID,
			@psClasses = CLASSES
			FROM @tbRows
			WHERE SEQ = @nIndex
	
			-- Delete case text where the class no longer exists against the case
			Delete CT
			From CASETEXT CT 
			Left join (Select Parameter From dbo.fn_Tokenise(@psClasses, ',')) as CC
				on (CC.Parameter = CT.CLASS)
			Where CT.CASEID = @pnCaseId
			and CC.Parameter is null
			and CT.CLASS is not null
	
			Insert into CASETEXT(CASEID, TEXTTYPE, TEXTNO, CLASS, LANGUAGE, MODIFIEDDATE, LONGFLAG, SHORTTEXT, TEXT)
			Select @pnCaseId, 'G', MAXTEXT.MAXTEXTNO + CC.InsertOrder, LEFT(CC.Parameter, 11), null, getdate(), 0, null, null 
			From (Select InsertOrder, Parameter From dbo.fn_Tokenise(@psClasses, ',')) as CC
			Left join CASETEXT on (LEFT(CC.Parameter, 11) = CASETEXT.CLASS 
						and CASETEXT.CASEID = @pnCaseId)
			cross join (Select isnull(MAX(TEXTNO), -1) as MAXTEXTNO From CASETEXT 
				Where CASEID = @pnCaseId AND TEXTTYPE = 'G') as MAXTEXT
			Where CASETEXT.CLASS is null
			and isnull(CC.Parameter,'')<>''
			
	
			Set @nIndex = @nIndex + 1
		End
	
	End

End
go
