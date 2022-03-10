-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetEventImportanceLevel
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetEventImportanceLevel') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetEventImportanceLevel.'
	drop function dbo.fn_GetEventImportanceLevel
	print '**** Creating function dbo.fn_GetEventImportanceLevel...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_GetEventImportanceLevel
			(@pnUserIdentityId		int,	-- the specific user the EventNumbers are required for
			 @pbIsExternalUser		bit	-- external user flag if already known
			)
RETURNS int


-- FUNCTION :	fn_GetEventImportanceLevel
-- VERSION :	3
-- DESCRIPTION:	This function is used to return the Importance Level that is used to determine
--		the lowest level of importance of Events that are available to display for the user.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 18 Aug 2003	MF		1	Function created
-- 15 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 25 Jan 2011	MF	10184	3	Importance Level may now be determined from the Profile that a user belongs to.

as
Begin
	declare @nImportanceLevel	int

	--------------------------------------------
	-- Determine if there is an Importance Level
	-- linked to the Profile that the user
	-- belongs to.
	--------------------------------------------
	If @pnUserIdentityId is not null
	Begin
		Select	@pbIsExternalUser=UI.ISEXTERNALUSER,
			@nImportanceLevel=PA.ATTRIBUTEVALUE
		from USERIDENTITY UI
		left join ATTRIBUTES A		on (A.ATTRIBUTENAME='Minimum Importance Level')
		left join PROFILEATTRIBUTES PA	on (PA.PROFILEID=UI.PROFILEID
						and PA.ATTRIBUTEID=A.ATTRIBUTEID)
		where UI.IDENTITYID=@pnUserIdentityId
	End

	-- Only extract the Importance Level if either a UserIdentityId has been passed as a parameter
	-- or the IsExternalUser flag has been passed as a parameter.

	If @nImportanceLevel is null
	Begin
		-- Get the ImportanceLevel range from the relevant SITECONTROL depending on if the user is external
		-- or not. 

		If @pbIsExternalUser=1
		Begin
			select @nImportanceLevel=S.COLINTEGER
			from SITECONTROL S 
			where S.CONTROLID='Client Importance'
		End
		Else if @pbIsExternalUser=0
		Begin
			select @nImportanceLevel=S.COLINTEGER
			from SITECONTROL S 
			where S.CONTROLID='Events Displayed'
		End
		
	End
		
	Return isnull(@nImportanceLevel,0)
End
go

grant REFERENCES, EXECUTE on dbo.fn_GetEventImportanceLevel to public
GO
