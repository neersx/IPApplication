-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserAliasTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserAliasTypes') and xtype='TF')
begin
	print '**** Drop function dbo.fn_FilterUserAliasTypes.'
	drop function dbo.fn_FilterUserAliasTypes
	print '**** Creating function dbo.fn_FilterUserAliasTypes...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterUserAliasTypes
			(@pnUserIdentityId		int,	-- the specific user the AliasTypes are required for
			 @psLookupCulture		nvarchar(10), -- the culture the output is required in
			 @pbIsExternalUser		bit,	-- external user flag if already known
			 @pbCalledFromCentura  		bit = 0)-- if true, the function should provide access to all data		
RETURNS @tbAliasTypes TABLE
   (		ALIASTYPE		nvarchar(2)	collate database_default not null primary key,
		ALIASDESCRIPTION	nvarchar(254)	collate database_default null
   )


-- FUNCTION :	fn_FilterUserAliasTypes
-- VERSION :	3
-- DESCRIPTION:	This function is used to return a list of Alias Types that the currently logged on
--		user identified by @pnUserIdentityId is allowed to have access to.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 28 Feb 2006	LP	RFC3216	1	Function created
-- 30 Nov 2005	JEK	RFC4755	2	Include primary key index.
-- 15 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

as
Begin

-- Is a translation required?
If @psLookupCulture is not null
and dbo.fn_GetTranslatedTIDColumn('ALIASTYPE','ALIASDESCRIPTION') is not null
begin
	-- If called from Centura, the function should provide access to all data; i.e. implement no security. 

	If @pbCalledFromCentura = 1
	Begin
		insert into @tbAliasTypes(ALIASTYPE, ALIASDESCRIPTION)
		select 	ALIASTYPE,
			dbo.fn_GetTranslationLimited(ALIASDESCRIPTION,null,ALIASDESCRIPTION_TID,@psLookupCulture)
		from ALIASTYPE
	End
	Else Begin
	
		-- Only extract a list of Alias Types if either a UserIdentityId has been passed as a parameter
		-- or the IsExternalUser flag has been passed as a parameter.
	
		If @pnUserIdentityId is not null
		or @pbIsExternalUser is not null
		Begin
			-- If the IsExternalUser flag has not been passed as a parameter then determine it 
			-- by looking up the USERIDENTITY table
			If @pbIsExternalUser is null
			Begin
				Select	@pbIsExternalUser=ISEXTERNALUSER
				from USERIDENTITY
				where IDENTITYID=@pnUserIdentityId
			End
	
			-- If the AliasTypes are required for an external user then get them from
			-- the SiteControl table otherwise just return all rows from the AliasType table
	
			If @pbIsExternalUser=1
			Begin
				-- NOTE : This code will be replaced if a new method of getting AliasTypes is determined
				insert into @tbAliasTypes(ALIASTYPE, ALIASDESCRIPTION)
				select 	A.ALIASTYPE,
					-- Output column is 254 so use limited version
					dbo.fn_GetTranslationLimited(A.ALIASDESCRIPTION,null,A.ALIASDESCRIPTION_TID,@psLookupCulture)
				from ALIASTYPE A
				join SITECONTROL S on S.CONTROLID='Client Name Alias Types'
				-- Cater for situation when the items being searched have different lengths; e.g. a search for 'Z'
				-- will match on 'Z' but not on 'ZC'.
				where patindex('%'+','+replace(A.ALIASTYPE,'_','^')+','+'%',',' + replace(replace(S.COLCHARACTER, ' ', ''), '_','^') + ',')>0 
			End
			Else if @pbIsExternalUser=0
			Begin
				insert into @tbAliasTypes(ALIASTYPE, ALIASDESCRIPTION)
				select 	ALIASTYPE,
					-- Output column is 254 so use limited version
					dbo.fn_GetTranslationLimited(ALIASDESCRIPTION,null,ALIASDESCRIPTION_TID,@psLookupCulture)
				from ALIASTYPE
			End
			
		End
	End
end
-- No translation required
Else
begin
	-- If called from Centura, the function should provide access to all data; i.e. implement no security. 

	If @pbCalledFromCentura = 1
	Begin
		insert into @tbAliasTypes(ALIASTYPE, ALIASDESCRIPTION)
		select ALIASTYPE, ALIASDESCRIPTION
		from ALIASTYPE
	End
	Else Begin
	
		-- Only extract a list of Alias Types if either a UserIdentityId has been passed as a parameter
		-- or the IsExternalUser flag has been passed as a parameter.
	
		If @pnUserIdentityId is not null
		or @pbIsExternalUser is not null
		Begin
			-- If the IsExternalUser flag has not been passed as a parameter then determine it 
			-- by looking up the USERIDENTITY table
			If @pbIsExternalUser is null
			Begin
				Select	@pbIsExternalUser=ISEXTERNALUSER
				from USERIDENTITY
				where IDENTITYID=@pnUserIdentityId
			End
	
			-- If the AliasTypes are required for an external user then get them from
			-- the SiteControl table otherwise just return all rows from the AliasType table
	
			If @pbIsExternalUser=1
			Begin
				-- NOTE : This code will be replaced if a new method of getting AliasTypes is determined
				insert into @tbAliasTypes(ALIASTYPE, ALIASDESCRIPTION)
				select A.ALIASTYPE, A.ALIASDESCRIPTION
				from ALIASTYPE A
				join SITECONTROL S on S.CONTROLID='Client Name Alias Types'
				-- Cater for situation when the items being searched have different lengths; e.g. a search for 'Z'
				-- will match on 'Z' but not on 'ZC'.
				where patindex('%'+','+replace(A.ALIASTYPE,'_','^')+','+'%',',' + replace(replace(S.COLCHARACTER, ' ', ''), '_','^') + ',')>0 
			End
			Else if @pbIsExternalUser=0
			Begin
				insert into @tbAliasTypes(ALIASTYPE, ALIASDESCRIPTION)
				select ALIASTYPE, ALIASDESCRIPTION
				from ALIASTYPE
			End
			
		End
	End
end
		
Return


End
go

grant REFERENCES, SELECT on dbo.fn_FilterUserAliasTypes to public
GO
