-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fnw_GetScreenControlNameTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fnw_GetScreenControlNameTypes') and xtype='TF')
Begin
	Print '**** Drop Function dbo.fnw_GetScreenControlNameTypes.'
	Drop function [dbo].[fnw_GetScreenControlNameTypes]
End
Print '**** Creating Function dbo.fnw_GetScreenControlNameTypes...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fnw_GetScreenControlNameTypes
(
	@pnUserIdentityId int,
	@pnCaseKey int,
	@psProgramKey nvarchar(8)=null
)
RETURNS @tNameTypes table (
	NameTypeKey	nvarchar(3) collate database_default primary key
)
AS
-- FUNCTION:	fnw_GetScreenControlNameTypes
-- VERSION :	2
-- SCOPE:	CPAStart
-- DESCRIPTION:	returns a table of distinct name type keys that 
--              are referenced by screen control rules matching the supplied parameters.
--
-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	-----------------------------------------------------------------------------------
-- 16 MAR 2009	JC	RFC7362	1	Function created
-- 21 Sep 2009  LP      RFC8047 2       Added ProfileKey paramter for fn_GetCriteriaNo

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
	Select @nCriteriaNo = dbo.fn_GetCriteriaNo(@pnCaseKey, 'W', @psProgramKey, null, @nProfileKey)

	-- populate the table with distinct name types 
	If @nCriteriaNo is not null
	Begin
		Insert	into @tNameTypes
		select	*
		from	dbo.fnw_ScreenCriteriaNameTypes(@nCriteriaNo)
		where	NAMETYPE is not null
		-- SQA14541
	End

	RETURN
END
go

grant REFERENCES, SELECT on dbo.fnw_GetScreenControlNameTypes to public
go