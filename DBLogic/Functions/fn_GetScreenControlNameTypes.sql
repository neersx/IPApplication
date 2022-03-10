-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetScreenControlNameTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetScreenControlNameTypes') and xtype='TF')
Begin
	Print '**** Drop Function dbo.fn_GetScreenControlNameTypes.'
	Drop function [dbo].[fn_GetScreenControlNameTypes]
End
Print '**** Creating Function dbo.fn_GetScreenControlNameTypes...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_GetScreenControlNameTypes
(
	@pnUserIdentityId int,
	@pnCaseKey int,
	@psProgramKey nvarchar(8)=null
)
RETURNS @tNameTypes table (
	NameTypeKey	nvarchar(3) collate database_default primary key
)
AS
-- FUNCTION:	fn_GetScreenControlNameTypes
-- VERSION :	12
-- SCOPE:	CPAStart
-- DESCRIPTION:	returns a table of distinct name type keys that 
--              are referenced by screen control rules matching the supplied parameters.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 21 FEB 2003	SF	        1	Function created
-- 05 Mar 2003	JEK	        2	Corrected typo in screen name
-- 06 Mar 2003	JEK	        3	Check names on Instructor tab also
-- 29 Aug 2003  AB	        4	Add 'dbo.' before creation of sp, add grant execute to the function
-- 18 Aug 2004	AB	        5	Add collate database_default syntax to temp tables.
-- 03 May 2006	AU	        6	Add Additional internal staff from site control to returned table.
-- 09 May 2006	SW	        7	Call fn_GetScreenCriteriaNameTypes
-- 30 Nov 2005	JEK	        8	Include primary key index.
-- 13 Mar 2007	PY	        9	SQA14541 do not insert null columns into @tNameTypes
-- 07 Oct 2008	AT	        10	Add support for CRM case screen control criteria.
-- 15 Dec 2008	MF	17136	11	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 21 Sep 2009  LP      RFC8047 12      Added ProfileKey parameter to fn_GetCriteriaNo 

BEGIN
	Declare @nCriteriaNo int
	Declare @bIsCRMCaseType	bit
	Declare @nProfileKey int

	-- Default @psProgramKey to 'Case Screen Default Program' Site Control value if not provided.
	if @psProgramKey is null
	Begin
		If @pnCaseKey is not null
		Begin
			Select @bIsCRMCaseType = isnull(CT.CRMONLY,0)
			from CASES C
			join CASETYPE CT ON (CT.CASETYPE = C.CASETYPE)
			where C.CASEID = @pnCaseKey
		End

		If @bIsCRMCaseType = 0
		Begin
			Select 	@psProgramKey = COLCHARACTER 
			from 	SITECONTROL 
			where 	CONTROLID = 'Case Screen Default Program'
		End
		Else
		Begin
			Select 	@psProgramKey = COLCHARACTER 
			from 	SITECONTROL 
			where 	CONTROLID = 'CRM Screen Control Program'
		End
	End

        -- Get ProfileKey for the current user
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
        
	-- Get the Criteria No associated with the current case given the correct purpose code and program key
	Select @nCriteriaNo = dbo.fn_GetCriteriaNo(@pnCaseKey, 'S', @psProgramKey, null, @nProfileKey)

	-- populate the table with distinct name types 
	If @nCriteriaNo is not null
	Begin
		Insert	into @tNameTypes
		select	*
		from	dbo.fn_ScreenCriteriaNameTypes(@nCriteriaNo)
		where	NAMETYPE is not null
		-- SQA14541
	End

	RETURN
END
go

grant REFERENCES, SELECT on dbo.fn_GetScreenControlNameTypes to public
go