-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserTextTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserTextTypes') and xtype='TF')
begin
	print '**** Drop function dbo.fn_FilterUserTextTypes.'
	drop function dbo.fn_FilterUserTextTypes
	print '**** Creating function dbo.fn_FilterUserTextTypes...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterUserTextTypes
			(@pnUserIdentityId		int,	-- the specific user the TextTypes are required for
			 @psLookupCulture		nvarchar(10), -- the culture the output is required in
			 @pbIsExternalUser		bit,	-- external user flag if already known
			 @pbCalledFromCentura  		bit = 0)-- if true, the function should provide access to all data		
RETURNS @tbTextTypes TABLE
   (		TEXTTYPE		nvarchar(2)	collate database_default not null primary key,
		TEXTDESCRIPTION		nvarchar(254)	collate database_default null,
		USEDBYFLAG		smallint	null    
   )


-- FUNCTION :	fn_FilterUserTextTypes
-- VERSION :	9
-- DESCRIPTION:	This function is used to return a list of Text Types that the currently logged on
--		user identified by @pnUserIdentityId is allowed to have access to.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 18/08/2003	MF		1	Function created
-- 29-Oct-2003	TM	RFC495	2	Subset site control implementation with patindex. Enhance the 
--					existing logic that implements patindex to find the matching item 
--					in the following manner:
--					before change: "where patindex('%'+TT.TEXTTYPE+'%',S.COLCHARACTER)>0"
--					after change:  "where patindex('%'+','+TT.TEXTTYPE+','+'%',',' + 
--								       replace(S.COLCHARACTER, ' ', '') + ',')>0
-- 18 Feb 2004	TM	RFC976	3	Implement a new @pbCalledFromCentura bit parameter which defaults to false. If true,  
--					the function should provide access to all data; i.e. implement no security.
-- 09 Sep 2004	JEK	RFC886	4	Add @psLookupCulture to interface.
-- 16 Sep 2004	JEK	RFC886	5	Implement translation.  Remove TID column from table.
-- 27 Sep 2004	JEK	RFC886	6	Implement collate database_default.
-- 15 May 2005  JEK	RFC2508	7	Calling code is now required to prepare @psLookupCulture
-- 30 Nov 2005	JEK	RFC4755	8	Include primary key index.
-- 15 Dec 2008	MF	17136	9	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

as
Begin

-- Is a translation required?
If @psLookupCulture is not null
and dbo.fn_GetTranslatedTIDColumn('TEXTTYPE','TEXTDESCRIPTION') is not null
begin
	-- If called from Centura, the function should provide access to all data; i.e. implement no security. 

	If @pbCalledFromCentura = 1
	Begin
		insert into @tbTextTypes(TEXTTYPE, TEXTDESCRIPTION, USEDBYFLAG)
		select 	TEXTTYPE,
			dbo.fn_GetTranslationLimited(TEXTDESCRIPTION,null,TEXTDESCRIPTION_TID,@psLookupCulture), 
			USEDBYFLAG
		from TEXTTYPE
	End
	Else Begin
	
		-- Only extract a list of Text Types if either a UserIdentityId has been passed as a parameter
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
	
			-- If the TextTypes are required for an external user then get them from
			-- the SiteControl table otherwise just return all rows from the TextType table
	
			If @pbIsExternalUser=1
			Begin
				-- NOTE : This code will be replaced if a new method of getting TextTypes is determined
				insert into @tbTextTypes(TEXTTYPE, TEXTDESCRIPTION, USEDBYFLAG)
				select 	TT.TEXTTYPE,
					-- Output column is 254 so use limited version
					dbo.fn_GetTranslationLimited(TT.TEXTDESCRIPTION,null,TT.TEXTDESCRIPTION_TID,@psLookupCulture), 
					TT.USEDBYFLAG
				from TEXTTYPE TT
				join SITECONTROL S on S.CONTROLID='Client Text Types'
				-- Cater for situation when the items being searched have different lengths; e.g. a search for 'Z'
				-- will match on 'Z' but not on 'ZC'.
				where patindex('%'+','+TT.TEXTTYPE+','+'%',',' + replace(S.COLCHARACTER, ' ', '') + ',')>0 
			End
			Else if @pbIsExternalUser=0
			Begin
				insert into @tbTextTypes(TEXTTYPE, TEXTDESCRIPTION, USEDBYFLAG)
				select 	TEXTTYPE,
					-- Output column is 254 so use limited version
					dbo.fn_GetTranslationLimited(TEXTDESCRIPTION,null,TEXTDESCRIPTION_TID,@psLookupCulture), 
					USEDBYFLAG
				from TEXTTYPE
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
		insert into @tbTextTypes(TEXTTYPE, TEXTDESCRIPTION, USEDBYFLAG)
		select TEXTTYPE, TEXTDESCRIPTION, USEDBYFLAG
		from TEXTTYPE
	End
	Else Begin
	
		-- Only extract a list of Text Types if either a UserIdentityId has been passed as a parameter
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
	
			-- If the TextTypes are required for an external user then get them from
			-- the SiteControl table otherwise just return all rows from the TextType table
	
			If @pbIsExternalUser=1
			Begin
				-- NOTE : This code will be replaced if a new method of getting TextTypes is determined
				insert into @tbTextTypes(TEXTTYPE, TEXTDESCRIPTION, USEDBYFLAG)
				select TT.TEXTTYPE, TT.TEXTDESCRIPTION, TT.USEDBYFLAG
				from TEXTTYPE TT
				join SITECONTROL S on S.CONTROLID='Client Text Types'
				-- Cater for situation when the items being searched have different lengths; e.g. a search for 'Z'
				-- will match on 'Z' but not on 'ZC'.
				where patindex('%'+','+TT.TEXTTYPE+','+'%',',' + replace(S.COLCHARACTER, ' ', '') + ',')>0 
			End
			Else if @pbIsExternalUser=0
			Begin
				insert into @tbTextTypes(TEXTTYPE, TEXTDESCRIPTION, USEDBYFLAG)
				select TEXTTYPE, TEXTDESCRIPTION, USEDBYFLAG
				from TEXTTYPE
			End
			
		End
	End
end
		
Return


End
go

grant REFERENCES, SELECT on dbo.fn_FilterUserTextTypes to public
GO
