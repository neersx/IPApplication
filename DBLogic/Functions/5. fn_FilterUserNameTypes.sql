-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserNameTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserNameTypes') and xtype='TF')
begin
	print '**** Drop function dbo.fn_FilterUserNameTypes.'
	drop function dbo.fn_FilterUserNameTypes
	print '**** Creating function dbo.fn_FilterUserNameTypes...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterUserNameTypes
			(@pnUserIdentityId		int,	-- the specific user the NameTypes are required for
			 @psLookupCulture			nvarchar(10), -- the culture the output is required in
			 @pbIsExternalUser		bit,	-- external user flag if already known
			 @pbCalledFromCentura  		bit = 0 -- if true, the function should provide access to all data
			)
RETURNS @tbNameTypes TABLE
   (
        NAMETYPE             nvarchar(3)	collate database_default NOT NULL primary key,
        DESCRIPTION          nvarchar(254)	collate database_default NULL,
        PATHNAMETYPE         nvarchar(3)	collate database_default NULL,
        PATHRELATIONSHIP     nvarchar(3)	collate database_default NULL,
        HIERARCHYFLAG        decimal(1,0)	NULL,
        MANDATORYFLAG        decimal(1,0)	NULL,
        KEEPSTREETFLAG       decimal(1,0)	NULL,
        COLUMNFLAGS          smallint		NULL,
        MAXIMUMALLOWED       smallint		NULL,
        PICKLISTFLAGS        smallint		NULL,
        SHOWNAMECODE         decimal(1,0)	NULL,
        DEFAULTNAMENO        int		NULL,
	BULKENTRYFLAG        bit		NULL,
	KOTTEXTTYPE          nvarchar(2)	NULL,
	PROGRAM              int		NULL,
	ETHICALWALL          tinyint		NULL,
	NAMERESTRICTFLAG     bit	        NULL,
        PRIORITYORDER        smallint           NOT NULL
   )


-- FUNCTION :	fn_FilterUserNameTypes
-- VERSION :	15
-- DESCRIPTION:	This function is used to return a list of Name Types that the currently logged on
--		user identified by @pnUserIdentityId is allowed to see the actual Names attached
-- 		to the Cases they have access to.

-- MODIFICATION
-- Date		Who	No.	Version	Description
-- ====         ===	=== 	=======	===========
-- 20 Aug 2003	MF		1	Function created
-- 09 Sep 2003	MF		2	Function had wrong name.  Changed to fn_FilterUserNameTypes
-- 29 Oct 2003	TM	RFC495	3	Subset site control implementation with patindex. Enhance the 
--					existing logic that implements patindex to find the matching item 
--					in the following manner:
--					before change: "where patindex('%'+NT.NAMETYPE+'%',S.COLCHARACTER)>0"
--					after change:  "where patindex('%'+','+NT.NAMETYPE+','+'%',',' + 
--								       replace(S.COLCHARACTER, ' ', '') + ',')>0
-- 18 Feb 2004	TM	RFC976	4	Implement a new @pbCalledFromCentura bit parameter which defaults to false. If true,  
--					the function should provide access to all data; i.e. implement no security.
-- 09 Sep 2004	JEK	RFC886	5	Add @psLookupCulture to interface.
-- 16 Sep 2004	JEK	RFC886	6	Implement translation.  Remove TID column from output.
-- 27 Sep 2004	JEK	RFC886	7	Implement collate database_default.
-- 15 May 2005  JEK	RFC2508	8	Calling code is now required to prepare @psLookupCulture
-- 30 Nov 2005	JEK	RFC4755	9	Include primary key index.
-- 01 Jul 2008	LP	RFC5764	10	Exclude CRM Name Types for external users.
-- 18 Sep 2008	AT	RFC5759	11	Return BulkEntryFlag.
-- 15 Dec 2008	MF	R17136	12	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 17 May 2016	MF	13471	13	New columns added to NAMETYPE table.
-- 29 Aug 2016	MF	62643	14	Return the NAMERESTRICTFLAG column.
-- 11 Apr 2017  MS      R56196  15      Return the PRIORITYORDER column
as
Begin

-- Is a translation required?
If @psLookupCulture is not null
and dbo.fn_GetTranslatedTIDColumn('NAMETYPE','DESCRIPTION') is not null
begin
	-- If called from Centura, the function should provide access to all data; i.e. implement no security. 

	If @pbCalledFromCentura = 1
	Begin
		insert into @tbNameTypes(NAMETYPE, DESCRIPTION, PATHNAMETYPE, PATHRELATIONSHIP, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, MAXIMUMALLOWED, PICKLISTFLAGS, SHOWNAMECODE, DEFAULTNAMENO, BULKENTRYFLAG, KOTTEXTTYPE, PROGRAM, ETHICALWALL, NAMERESTRICTFLAG, PRIORITYORDER)
		select 	NAMETYPE, 
			dbo.fn_GetTranslationLimited(DESCRIPTION,null,DESCRIPTION_TID,@psLookupCulture),
			PATHNAMETYPE, PATHRELATIONSHIP, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, MAXIMUMALLOWED, PICKLISTFLAGS, SHOWNAMECODE, DEFAULTNAMENO, BULKENTRYFLAG, KOTTEXTTYPE, PROGRAM, ETHICALWALL, CAST(NAMERESTRICTFLAG as bit), PRIORITYORDER
		from NAMETYPE		
	End
	Else
	Begin	
		-- Only extract a list of Name Types if either a UserIdentityId has been passed as a parameter
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
	
			-- If the NameTypes are required for an external user then get them from
			-- the SiteControl table otherwise just return all rows from the NAMETYPE table
	
			If @pbIsExternalUser=1
			Begin
				-- NOTE : This code will be replaced if a new method of getting NameTypes is determined
				insert into @tbNameTypes(NAMETYPE, DESCRIPTION, PATHNAMETYPE, PATHRELATIONSHIP, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, MAXIMUMALLOWED, PICKLISTFLAGS, SHOWNAMECODE, DEFAULTNAMENO, BULKENTRYFLAG, KOTTEXTTYPE, PROGRAM, ETHICALWALL, NAMERESTRICTFLAG, PRIORITYORDER)
				select 	NT.NAMETYPE, 
					-- Output column is 254 so use limited version
					dbo.fn_GetTranslationLimited(NT.DESCRIPTION,null,NT.DESCRIPTION_TID,@psLookupCulture),
					NT.PATHNAMETYPE, NT.PATHRELATIONSHIP, NT.HIERARCHYFLAG, NT.MANDATORYFLAG, NT.KEEPSTREETFLAG, NT.COLUMNFLAGS, NT.MAXIMUMALLOWED, NT.PICKLISTFLAGS, NT.SHOWNAMECODE, NT.DEFAULTNAMENO, NT.BULKENTRYFLAG, NT.KOTTEXTTYPE, NT.PROGRAM, NT.ETHICALWALL, CAST(NT.NAMERESTRICTFLAG as bit), NT.PRIORITYORDER
				from NAMETYPE NT
				join SITECONTROL S on S.CONTROLID='Client Name Types Shown'
				-- Cater for situation when the items being searched have different lengths; e.g. a search for 'Z'
				-- will match on 'Z' but not on 'ZC'.
				where patindex('%'+','+NT.NAMETYPE+','+'%',',' + replace(S.COLCHARACTER, ' ', '') + ',')>0
				and PICKLISTFLAGS&32<>32
			End
			Else if @pbIsExternalUser=0
			Begin
				insert into @tbNameTypes(NAMETYPE, DESCRIPTION, PATHNAMETYPE, PATHRELATIONSHIP, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, MAXIMUMALLOWED, PICKLISTFLAGS, SHOWNAMECODE, DEFAULTNAMENO, BULKENTRYFLAG, KOTTEXTTYPE, PROGRAM, ETHICALWALL, NAMERESTRICTFLAG, PRIORITYORDER)
				select 	NAMETYPE, 
					-- Output column is 254 so use limited version
					dbo.fn_GetTranslationLimited(DESCRIPTION,null,DESCRIPTION_TID,@psLookupCulture),
					PATHNAMETYPE, PATHRELATIONSHIP, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, MAXIMUMALLOWED, PICKLISTFLAGS, SHOWNAMECODE, DEFAULTNAMENO, BULKENTRYFLAG, KOTTEXTTYPE, PROGRAM, ETHICALWALL, CAST(NAMERESTRICTFLAG as bit), PRIORITYORDER
				from NAMETYPE
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
		insert into @tbNameTypes(NAMETYPE, DESCRIPTION, PATHNAMETYPE, PATHRELATIONSHIP, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, MAXIMUMALLOWED, PICKLISTFLAGS, SHOWNAMECODE, DEFAULTNAMENO, BULKENTRYFLAG, KOTTEXTTYPE, PROGRAM, ETHICALWALL, NAMERESTRICTFLAG, PRIORITYORDER)
		select NAMETYPE, DESCRIPTION, PATHNAMETYPE, PATHRELATIONSHIP, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, MAXIMUMALLOWED, PICKLISTFLAGS, SHOWNAMECODE, DEFAULTNAMENO, BULKENTRYFLAG, KOTTEXTTYPE, PROGRAM, ETHICALWALL, CAST(NAMERESTRICTFLAG as bit), PRIORITYORDER
		from NAMETYPE		
	End
	Else
	Begin	
		-- Only extract a list of Name Types if either a UserIdentityId has been passed as a parameter
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
	
			-- If the NameTypes are required for an external user then get them from
			-- the SiteControl table otherwise just return all rows from the NAMETYPE table
	
			If @pbIsExternalUser=1
			Begin
				-- NOTE : This code will be replaced if a new method of getting NameTypes is determined
				insert into @tbNameTypes(NAMETYPE, DESCRIPTION, PATHNAMETYPE, PATHRELATIONSHIP, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, MAXIMUMALLOWED, PICKLISTFLAGS, SHOWNAMECODE, DEFAULTNAMENO, BULKENTRYFLAG, KOTTEXTTYPE, PROGRAM, ETHICALWALL, NAMERESTRICTFLAG, PRIORITYORDER)
				select NT.NAMETYPE, NT.DESCRIPTION, NT.PATHNAMETYPE, NT.PATHRELATIONSHIP, NT.HIERARCHYFLAG, NT.MANDATORYFLAG, NT.KEEPSTREETFLAG, NT.COLUMNFLAGS, NT.MAXIMUMALLOWED, NT.PICKLISTFLAGS, NT.SHOWNAMECODE, NT.DEFAULTNAMENO, NT.BULKENTRYFLAG, NT.KOTTEXTTYPE, NT.PROGRAM, NT.ETHICALWALL, CAST(NT.NAMERESTRICTFLAG as bit), NT.PRIORITYORDER
				from NAMETYPE NT
				join SITECONTROL S on S.CONTROLID='Client Name Types Shown'
				-- Cater for situation when the items being searched have different lengths; e.g. a search for 'Z'
				-- will match on 'Z' but not on 'ZC'.
				where patindex('%'+','+NT.NAMETYPE+','+'%',',' + replace(S.COLCHARACTER, ' ', '') + ',')>0
				and PICKLISTFLAGS&32<>32
			End
			Else if @pbIsExternalUser=0
			Begin
				insert into @tbNameTypes(NAMETYPE, DESCRIPTION, PATHNAMETYPE, PATHRELATIONSHIP, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, MAXIMUMALLOWED, PICKLISTFLAGS, SHOWNAMECODE, DEFAULTNAMENO, BULKENTRYFLAG, KOTTEXTTYPE, PROGRAM, ETHICALWALL, NAMERESTRICTFLAG, PRIORITYORDER)
				select NAMETYPE, DESCRIPTION, PATHNAMETYPE, PATHRELATIONSHIP, HIERARCHYFLAG, MANDATORYFLAG, KEEPSTREETFLAG, COLUMNFLAGS, MAXIMUMALLOWED, PICKLISTFLAGS, SHOWNAMECODE, DEFAULTNAMENO, BULKENTRYFLAG, KOTTEXTTYPE, PROGRAM, ETHICALWALL, CAST(NAMERESTRICTFLAG as bit), PRIORITYORDER
				from NAMETYPE
			End
			
		End
	End
End
		
Return

End
go

grant REFERENCES, SELECT on dbo.fn_FilterUserNameTypes to public
GO
