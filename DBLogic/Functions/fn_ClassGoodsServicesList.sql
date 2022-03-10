-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ClassGoodsServicesList
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ClassGoodsServicesList') and xtype='FN')
begin
	print '**** Drop function dbo.fn_ClassGoodsServicesList.'
	drop function dbo.fn_ClassGoodsServicesList
	print '**** Creating function dbo.fn_ClassGoodsServicesList...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_ClassGoodsServicesList
	(
		@pnCaseId	int		-- the CaseId to be reported on
	)
Returns nvarchar(max)

-- FUNCTION :	fn_ClassGoodsServicesList
-- VERSION :	5
-- DESCRIPTION:	This function accepts a CaseId and gets class text for the specified caseid

-- Date		Who	No.	Version	Description
-- ====         ===	=======	=======	===========
-- 01 Jul 2011	vql 		1	Function created
-- 17 Nov 2014  AvB	R41690	2       If the goods/services text already contain a "Class"-heading, do not repeat it.
-- 11 Dec 2014	MF	R41901	3	Order the goods and services text by class.
-- 18 Jul 2016	KR	63294	4	Add Order by CLASS when concatenating  all classes into a single result field.
-- 24 Oct 2017	AK	R72645	5	Fixing spellings of case sensitive database.

AS
BEGIN

	Declare @sClass		nvarchar(max)
	Declare @sSeperator1	varchar (10)
	Declare @sSeperator2	varchar (10)
	
	Declare @tblClass	table (
			CLASS	nvarchar(200)	collate database_default NULL,
			GOODS	nvarchar(max)	collate database_default NULL
			)	
	
	Select @sSeperator1 = char(13)+char(10)
	Select @sSeperator2 = char(13)+char(10)+char(13)+char(10)
	
	------------------------------------------------------
	-- Require an interim step that uses a table variable
	-- to ensure the rows are in Class order. I attempted
	-- to do this using a sorted derived table however the
	-- order kept reverting to the order in which the rows
	-- were originally inserted into CASETEXT.
	------------------------------------------------------
	Insert into @tblClass(CLASS,GOODS)
	Select CT.CLASS, CASE WHEN(CT.TEXT IS NOT NULL) THEN CAST(CT.TEXT AS nvarchar(max)) ELSE CT.SHORTTEXT END
	from CASETEXT CT
	where CT.CASEID= @pnCaseId
	and CT.TEXTTYPE = 'G'
	ORDER BY CT.CLASS
	
	Select @sClass=ISNULL(NULLIF(@sClass+@sSeperator2,@sSeperator2),'')+
			-------------------------------------------
			-- If the word "Class" appears at the start
			-- of the text then no need to embed it
			-------------------------------------------
			CASE WHEN(CT.GOODS LIKE N'Class%' )
				THEN N'' 
				ELSE N'Class ' + CT.CLASS + @sSeperator1 
			END +
			CT.GOODS
	from @tblClass CT
	order by CLASS
	
Return @sClass
END
GO

grant execute on dbo.fn_ClassGoodsServicesList to public
GO