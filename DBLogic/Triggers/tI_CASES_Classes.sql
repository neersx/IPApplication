	/******************************************************************************************************************/
	/*** 10856 Create trigger tI_CASS_Classes									***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'tI_CASES_Classes')
	   begin
	    PRINT 'Refreshing trigger tI_CASES_Classes...'
	    DROP TRIGGER tI_CASES_Classes
	   end
	  go
	
	Create TRIGGER tI_CASES_Classes on CASES AFTER INSERT NOT FOR REPLICATION 
	as
	-- TRIGGER :	tI_CASES_Classes
	-- VERSION :	3
	-- DESCRIPTION:	Ensures at least 1 CASETEXT row exists for each of the case's classes
	
	-- MODIFICATIONS :
	-- Date		Who	Change		Version	Description
	-- -----------	-------	------		-------	----------------------------------------------- 
	-- 05 Jun 2006	AT	SQA10856	1	Trigger created.
	-- 08 Sep 2009	MF	SQA18014	2	Safeguard against an empty string Class being inserted
	-- 09 Nov 2012 DL	SQA21019	3	Handle  class code that has more than 11 characters by left(class,11)	
	
	Begin
	
	Declare @psClasses nvarchar(254)
	Declare @pnCaseId int
	Declare @nIndex int
	Declare @nRowCount int
	
		-- Create a table to store the inserted values
		Declare @tbRows table (SEQ int IDENTITY(1,1), 
					CASEID INT, 
					CLASSES NVARCHAR(254))
	
		INSERT INTO @tbRows( CASEID, CLASSES )
		SELECT CASEID, LOCALCLASSES FROM inserted WHERE LOCALCLASSES is not null
	
		Set @nIndex = 1
	
		Set @nRowCount = (SELECT COUNT(*) FROM @tbRows)
	
		While @nIndex <= @nRowCount
		Begin
			Select @pnCaseId = CASEID,
			@psClasses = CLASSES
			FROM @tbRows
			WHERE SEQ = @nIndex
	
			-- Insert a casetext row for each class without an existing casetext row.
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
	go