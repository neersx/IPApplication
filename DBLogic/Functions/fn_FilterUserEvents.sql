-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserEvents
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserEvents') and xtype='TF')
begin
	print '**** Drop function dbo.fn_FilterUserEvents.'
	drop function dbo.fn_FilterUserEvents
	print '**** Creating function dbo.fn_FilterUserEvents...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterUserEvents
			(@pnUserIdentityId		int,	-- the specific user the Events are required for
			 @psLookupCulture		nvarchar(10), -- the culture the output is required in
			 @pbIsExternalUser		bit,	-- external user flag if already known
			 @pbCalledFromCentura  		bit = 0 -- if true, the function should provide access to all data
			)
RETURNS @tbEvents TABLE
   (
        EVENTNO              int		NOT NULL primary key,
        EVENTCODE            nvarchar(10)	collate database_default NULL,
        EVENTDESCRIPTION     nvarchar(254)	collate database_default NULL,
        NUMCYCLESALLOWED     smallint		NULL,
        IMPORTANCELEVEL      nvarchar(2)	collate database_default NULL,
        CONTROLLINGACTION    nvarchar(2)	collate database_default NULL,
        DEFINITION           nvarchar(254)	collate database_default NULL
   )


-- FUNCTION :	fn_FilterUserEvents
-- VERSION :	13
-- DESCRIPTION:	This function is used to return a list of Events that the currently logged on
--		user identified by @pnUserIdentityId is allowed to have access to.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
--27 Aug 2003	MF		1	Function created
--27 Aug 2003	MF	371	2	Use the CLIENTIMPLEVEL to determine the Importance Level when the
--					user is external.
-- 30 Nov 2003	JEK	RFC397	3	Return a single ImportanceLevel column, populated from either ImportanceLevel
--					or ClientImpLevel depending on whether the user is external.
-- 16 Jan 2004	MF	SQA9621	4	Increase EventDescription to 100 characters.
-- 18 Feb 2004	TM	RFC976	5	Implement a new @pbCalledFromCentura bit parameter which defaults to false. If true,  
--					the function should provide access to all data; i.e. implement no security.
-- 09 Sep 2004	JEK	RFC886	6	Add @psLookupCulture to interface
-- 16 Sep 2004	JEK	RFC886	7	Implement translation.  Remove TID columns from table.
-- 27 Sep 2004	JEK	RFC886	8	Implement collate database_default.
-- 15 May 2005  JEK	RFC2508	9	Calling code is now required to prepare @psLookupCulture
-- 30 Nov 2005	JEK	RFC4755	10	Include primary key index.
-- 15 Dec 2008	MF	17136	11	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 25 Sep 2009  LP      RFC8047 12      Retrieve Importance Level if specified via user profile
-- 09 Mar 2010  LP      RFC8970 13      Retrieve Importance Level from user profile for non-localised requests

as
Begin

-- Is a translation required?
If @psLookupCulture is not null
and (dbo.fn_GetTranslatedTIDColumn('EVENTS','EVENTDESCRIPTION') is not null
 or dbo.fn_GetTranslatedTIDColumn('EVENTS','DEFINITION') is not null)
begin
	-- If called from Centura, the function should provide access to all data; i.e. implement no security. 

	If @pbCalledFromCentura = 1
	Begin
		insert into @tbEvents(EVENTNO, EVENTCODE, EVENTDESCRIPTION, NUMCYCLESALLOWED, IMPORTANCELEVEL, CONTROLLINGACTION, DEFINITION)
		select 	E.EVENTNO, 
			E.EVENTCODE, 
			dbo.fn_GetTranslationLimited(E.EVENTDESCRIPTION,null,E.EVENTDESCRIPTION_TID,@psLookupCulture), 
			E.NUMCYCLESALLOWED, 
			E.IMPORTANCELEVEL, 
			E.CONTROLLINGACTION,
			dbo.fn_GetTranslationLimited(E.DEFINITION,null,E.DEFINITION_TID,@psLookupCulture)
		from EVENTS E				
	End
	Else Begin
	
		-- Only extract a list of Events if either a UserIdentityId has been passed as a parameter
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
	
			-- If the Events are required for an external user then get the Events that 
			-- match or have a higher importance level than the Sitecontrol for external users 
	
			If @pbIsExternalUser=1
			Begin
				insert into @tbEvents(EVENTNO, EVENTCODE, EVENTDESCRIPTION, NUMCYCLESALLOWED, IMPORTANCELEVEL, CONTROLLINGACTION, DEFINITION)
				select	E.EVENTNO, 
					E.EVENTCODE,
					-- Output column is 254 so use limited version
					dbo.fn_GetTranslationLimited(E.EVENTDESCRIPTION,null,E.EVENTDESCRIPTION_TID,@psLookupCulture), 
					E.NUMCYCLESALLOWED, 
					E.IMPORTANCELEVEL, 
					E.CONTROLLINGACTION,
					dbo.fn_GetTranslation(E.DEFINITION,null,E.DEFINITION_TID,@psLookupCulture)
				from EVENTS E
				left join SITECONTROL S on S.CONTROLID='Client Importance'
				left join USERIDENTITY U on (U.IDENTITYID = @pnUserIdentityId)
				left join PROFILEATTRIBUTES PA on (PA.PROFILEID = U.PROFILEID and PA.ATTRIBUTEID = 1)
				where E.CLIENTIMPLEVEL>=isnull(convert(int,PA.ATTRIBUTEVALUE),isnull(S.COLINTEGER,0))
				
			End
	
			-- If the Events are required for an internal user then get the Events that 
			-- match or have a higher importance level than the Sitecontrol for internal users 
	
			Else if @pbIsExternalUser=0
			Begin
				insert into @tbEvents(EVENTNO, EVENTCODE, EVENTDESCRIPTION, NUMCYCLESALLOWED, IMPORTANCELEVEL, CONTROLLINGACTION, DEFINITION)
				select	E.EVENTNO, 
					E.EVENTCODE, 
					-- Output column is 254 so use limited version
					dbo.fn_GetTranslationLimited(E.EVENTDESCRIPTION,null,E.EVENTDESCRIPTION_TID,@psLookupCulture), 
					E.NUMCYCLESALLOWED, 
					E.IMPORTANCELEVEL, 
					E.CONTROLLINGACTION,
					dbo.fn_GetTranslation(E.DEFINITION,null,E.DEFINITION_TID,@psLookupCulture)
				from EVENTS E
				left join SITECONTROL S on S.CONTROLID='Events Displayed'
				left join USERIDENTITY U on (U.IDENTITYID = @pnUserIdentityId)
				left join PROFILEATTRIBUTES PA on (PA.PROFILEID = U.PROFILEID and PA.ATTRIBUTEID = 1)
				where E.IMPORTANCELEVEL>=isnull(convert(int,PA.ATTRIBUTEVALUE),isnull(S.COLINTEGER,0))
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
		insert into @tbEvents(EVENTNO, EVENTCODE, EVENTDESCRIPTION, NUMCYCLESALLOWED, IMPORTANCELEVEL, CONTROLLINGACTION, DEFINITION)
			select E.EVENTNO, E.EVENTCODE, E.EVENTDESCRIPTION, E.NUMCYCLESALLOWED, E.IMPORTANCELEVEL, E.CONTROLLINGACTION, E.DEFINITION
			from EVENTS E				
	End
	Else Begin
	
		-- Only extract a list of Events if either a UserIdentityId has been passed as a parameter
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
	
			-- If the Events are required for an external user then get the Events that 
			-- match or have a higher importance level than the Sitecontrol for external users 
	
			If @pbIsExternalUser=1
			Begin
				insert into @tbEvents(EVENTNO, EVENTCODE, EVENTDESCRIPTION, NUMCYCLESALLOWED, IMPORTANCELEVEL, CONTROLLINGACTION, DEFINITION)
				select E.EVENTNO, E.EVENTCODE, E.EVENTDESCRIPTION, E.NUMCYCLESALLOWED, E.CLIENTIMPLEVEL, E.CONTROLLINGACTION, E.DEFINITION
				from EVENTS E
				left join SITECONTROL S on (S.CONTROLID='Client Importance')
				left join USERIDENTITY UI on (UI.IDENTITYID = @pnUserIdentityId)
				left join PROFILEATTRIBUTES PA on (PA.PROFILEID = UI.PROFILEID and PA.ATTRIBUTEID = 1)
				where E.CLIENTIMPLEVEL>=isnull(convert(int, PA.ATTRIBUTEVALUE),isnull(S.COLINTEGER,0))
			End
	
			-- If the Events are required for an internal user then get the Events that 
			-- match or have a higher importance level than the Sitecontrol for internal users 
	
			Else if @pbIsExternalUser=0
			Begin
				insert into @tbEvents(EVENTNO, EVENTCODE, EVENTDESCRIPTION, NUMCYCLESALLOWED, IMPORTANCELEVEL, CONTROLLINGACTION, DEFINITION)
				select E.EVENTNO, E.EVENTCODE, E.EVENTDESCRIPTION, E.NUMCYCLESALLOWED, E.IMPORTANCELEVEL, E.CONTROLLINGACTION, E.DEFINITION
				from EVENTS E
				left join SITECONTROL S on S.CONTROLID='Events Displayed'
				left join USERIDENTITY UI on (UI.IDENTITYID = @pnUserIdentityId)
				left join PROFILEATTRIBUTES PA on (PA.PROFILEID = UI.PROFILEID and PA.ATTRIBUTEID = 1)
				where E.IMPORTANCELEVEL>=isnull(convert(int, PA.ATTRIBUTEVALUE),isnull(S.COLINTEGER,0))
			End
			
		End
	End
End
		
Return

End
go

grant REFERENCES, SELECT on dbo.fn_FilterUserEvents to public
GO
