-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserNumberTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserNumberTypes') and xtype='TF')
Begin
	print '**** Drop function dbo.fn_FilterUserNumberTypes.'
	drop function dbo.fn_FilterUserNumberTypes
	print '**** Creating function dbo.fn_FilterUserNumberTypes...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

Create Function dbo.fn_FilterUserNumberTypes
			(@pnUserIdentityId		int,	-- the specific user the NumberTypes are required for
			 @psLookupCulture			nvarchar(10), -- the culture the output is required in
			 @pbIsExternalUser		bit,	
			 @pbCalledFromCentura  		bit = 0 -- if true, the function should provide access to all data
			)
RETURNS @tbNumberTypes TABLE
   (
        NUMBERTYPE		nvarchar(3)	collate database_default	NOT NULL primary key,
        DESCRIPTION            	nvarchar(254)	collate database_default	NULL,
	RELATEDEVENTNO		int		NULL,
	ISSUEDBYIPOFFICE	decimal(1,0)	NULL,
	DISPLAYPRIORITY		smallint	NULL
   )


-- FUNCTION :	fn_FilterUserNumberTypes
-- VERSION :	9
-- DESCRIPTION:	This function is used to return a list of Number Types that the currently logged on
--		user identified by @pnUserIdentityId is allowed to have access to.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 08/10/2003	TM		1	Function created
-- 18 Feb 2004	TM	RFC976	2	Implement a new @pbCalledFromCentura bit parameter which defaults to false. If true,  
--					the function should provide access to all data; i.e. implement no security.
-- 09 Sep 2004	JEK	RFC886	3	Add @psLookupCulture to interface.
-- 16 Sep 2004	JEK	RFC886	4	Implement translation.  Remove TID column from table.
-- 27 Sep 2004	JEK	RFC886	5	Implement collate database_default.
-- 15 May 2005  JEK	RFC2508	6	Calling code is now required to prepare @psLookupCulture
-- 30 Nov 2005	JEK	RFC4755	7	Include primary key index.
-- 06 Aug 2009	LP	RFC8207	8	Implement check of Client Number Types Shown site control.
-- 19 May 2020	DL	DR-58943 9	Ability to enter up to 3 characters for Number type code via client server	

AS
Begin


-- Is a translation required?
If @psLookupCulture is not null
and dbo.fn_GetTranslatedTIDColumn('NUMBERTYPES','DESCRIPTION') is not null
begin
	-- If called from Centura, the function should provide access to all data; i.e. implement no security. 

	If @pbCalledFromCentura = 1
	Begin
		insert into @tbNumberTypes(NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY)
		select 	NUMBERTYPE, 
			dbo.fn_GetTranslationLimited(DESCRIPTION,null,DESCRIPTION_TID,@psLookupCulture), 
			RELATEDEVENTNO, 
			ISSUEDBYIPOFFICE, 
			DISPLAYPRIORITY
		from NUMBERTYPES
	End
	Else Begin
	
		-- Only extract a list of Number Types if either a UserIdentityId has been passed as a parameter
		-- or the IsExternalUser flag has been passed as a parameter.
	
		If @pnUserIdentityId is not null
		or @pbIsExternalUser is not null
		Begin
			-- If the IsExternalUser flag has not been passed as a parameter then determine it 
			-- by looking up the USERIDENTITY table
			If @pbIsExternalUser is null
			Begin
				Select	@pbIsExternalUser = ISEXTERNALUSER
				from USERIDENTITY
				where IDENTITYID = @pnUserIdentityId
			End
	
			-- If the NumberTypes are required for an external user then return the rows where
			-- IssedByIPOffice = 1 otherwise just return all rows from the NUMBERTYPES table.
	
			If @pbIsExternalUser=1
			Begin
				If exists (select 1 from SITECONTROL SC where SC.CONTROLID = 'Client Number Types Shown' and COLCHARACTER IS NOT NULL)
				Begin
					insert into @tbNumberTypes(NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY)
					select 	NUMBERTYPE, 
						-- Output column is 254 so use limited version
						dbo.fn_GetTranslationLimited(DESCRIPTION,null,DESCRIPTION_TID,@psLookupCulture), 
						RELATEDEVENTNO, 
						ISSUEDBYIPOFFICE, 
						DISPLAYPRIORITY
					from NUMBERTYPES NT
					join SITECONTROL SC on (SC.CONTROLID = 'Client Number Types Shown')
					where patindex('%'+','+NT.NUMBERTYPE+','+'%',',' + replace(SC.COLCHARACTER, ' ', '') + ',')>0
				End
				Else
				Begin
					insert into @tbNumberTypes(NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY)
					select 	NUMBERTYPE, 
						-- Output column is 254 so use limited version
						dbo.fn_GetTranslationLimited(DESCRIPTION,null,DESCRIPTION_TID,@psLookupCulture), 
						RELATEDEVENTNO, 
						ISSUEDBYIPOFFICE, 
						DISPLAYPRIORITY
					from NUMBERTYPES NT
					where ISSUEDBYIPOFFICE = 1
				End	
						
			End
			Else if @pbIsExternalUser=0
			Begin
				insert into @tbNumberTypes(NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY)
				select 	NUMBERTYPE, 
					-- Output column is 254 so use limited version
					dbo.fn_GetTranslationLimited(DESCRIPTION,null,DESCRIPTION_TID,@psLookupCulture), 
					RELATEDEVENTNO, 
					ISSUEDBYIPOFFICE, 
					DISPLAYPRIORITY
				from NUMBERTYPES
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
		insert into @tbNumberTypes(NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY)
		select NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY
		from NUMBERTYPES
	End
	Else Begin
	
		-- Only extract a list of Number Types if either a UserIdentityId has been passed as a parameter
		-- or the IsExternalUser flag has been passed as a parameter.
	
		If @pnUserIdentityId is not null
		or @pbIsExternalUser is not null
		Begin
			-- If the IsExternalUser flag has not been passed as a parameter then determine it 
			-- by looking up the USERIDENTITY table
			If @pbIsExternalUser is null
			Begin
				Select	@pbIsExternalUser = ISEXTERNALUSER
				from USERIDENTITY
				where IDENTITYID = @pnUserIdentityId
			End
	
			-- If the NumberTypes are required for an external user then return the rows where
			-- IssedByIPOffice = 1 otherwise just return all rows from the NUMBERTYPES table.
	
			If @pbIsExternalUser=1
			Begin
				If exists (select 1 from SITECONTROL SC where SC.CONTROLID = 'Client Number Types Shown' and COLCHARACTER IS NOT NULL)
				Begin
					insert into @tbNumberTypes(NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY)
					select NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY
					from NUMBERTYPES NT
					join SITECONTROL SC on (SC.CONTROLID='Client Number Types Shown')
					where patindex('%'+','+NT.NUMBERTYPE+','+'%',',' + replace(SC.COLCHARACTER, ' ', '') + ',')>0
				End
				Else
				Begin
					insert into @tbNumberTypes(NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY)
					select NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY
					from NUMBERTYPES NT
					where NT.ISSUEDBYIPOFFICE = 1
				End
				
			End
			Else if @pbIsExternalUser=0
			Begin
				insert into @tbNumberTypes(NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY)
				select NUMBERTYPE, DESCRIPTION, RELATEDEVENTNO, ISSUEDBYIPOFFICE, DISPLAYPRIORITY
				from NUMBERTYPES
			End
			
		End
	End
End


Return

End
GO

grant REFERENCES, SELECT on dbo.fn_FilterUserNumberTypes to public
GO
