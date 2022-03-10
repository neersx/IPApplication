-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserCaseTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserCaseTypes') and xtype='TF')
begin
	print '**** Drop function dbo.fn_FilterUserCaseTypes.'
	drop function dbo.fn_FilterUserCaseTypes
end
print '**** Creating function dbo.fn_FilterUserCaseTypes...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterUserCaseTypes
			(@pnUserIdentityId		int,	-- the specific user the CaseTypes are required for
			 @psLookupCulture		nvarchar(10), -- the culture the output is required in
			 @pbIsExternalUser		bit,	-- external user flag if already known
			 @pbCalledFromCentura  		bit = 0, -- if true, the function should provide access to all data
			 @pdtToday			datetime = null -- today's date for license check
									-- @pdtToday is Mandatory for Internal Users!
			)
RETURNS @tbCaseTypes TABLE
   (
        CASETYPE             nchar(1)		collate database_default NOT NULL primary key,
        CASETYPEDESC         nvarchar(254)	collate database_default NULL,
        ACTUALCASETYPE       nchar(1)		collate database_default NULL,
        CRMONLY              bit					 NULL
   )

-- FUNCTION :	fn_FilterUserCaseTypes
-- VERSION :	17
-- DESCRIPTION:	This function is used to return a list of Case Types that the currently logged on
--		user identified by @pnUserIdentityId is allowed to have access to.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
--18/08/2003	MF			Function created
--18/02/2004	TM	RFC976  	Implement a new @pbCalledFromCentura bit parameter which defaults to false. If true,  
--					the function should provide access to all data; i.e. implement no security.
--18/08/2004	AB	8035		Use collate database_default syntax on temp tables.
-- 09 Sep 2004	JEK	RFC886	5	Add @psLookupCulture to interface.
-- 16 Sep 2004	JEK	RFC886	6	Implement translation.
-- 15 May 2005  JEK	RFC2508	7	Calling code is now required to prepare @psLookupCulture
-- 30 Nov 2005	JEK	RFC4755	8	Include primary key index.
-- 27 Jun 2008	AT	RFC5748	9	Filter out CRM Case Types.
-- 14 Jul 2008	SF	RFC6535	10	But return the CRM Case Types if users are granted with CRM License 
-- 12 Dec 2008	AT	RFC7365	11	Implement license checking for CRM and non-CRM case types.
-- 15 Dec 2008	MF	RFC17136 12	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 28 Jul 2009	MF	SQA17917 13	Return the ACTUALCASETYPE column so we can distinguish draft Case Types. This is being done
--					as a performance improvement to avoid a join to CASETYPE.
-- 08 Apr 2010	MF	RFC9127		Improve performance by checking whether CRM and non CRM modules are in use only once.
-- 09 Jan 2012	LP	RFC9677	15	Allow users with applicable client-server licenses access to case types
-- 01 Oct 2014	LP	R9422	16	Cater for Marketing Module license.
-- 20 Nov 2014	LP	R41712	17	Incorrect license module number set for the Marketing Module license.

as
Begin

Declare	@bCRMModule	bit
Declare	@bNonCRMModule	bit
Declare @nWebModuleFlag int	-- bitwise flag to indicate the license gives access to Web functionality
Declare @bIsTranslationRequired bit
Declare @CRMWorkBenchLicense int
Declare @MarketingModuleLicense int

Set @nWebModuleFlag = 4
Set @CRMWorkBenchLicense = 25
Set @MarketingModuleLicense = 32

-- Is a translation required?
If @psLookupCulture is not null
and dbo.fn_GetTranslatedTIDColumn('CASETYPE','CASETYPEDESC') is not null
	Set @bIsTranslationRequired = 1
	-- If called from Centura, the function should provide access to all data; i.e. implement no security. 

If @pbCalledFromCentura = 1
Begin
	insert into @tbCaseTypes(CASETYPE,CASETYPEDESC,ACTUALCASETYPE,CRMONLY)
	select 	CASETYPE,
		case when @bIsTranslationRequired = 1
			Then dbo.fn_GetTranslationLimited(CASETYPEDESC,null,CASETYPEDESC_TID,@psLookupCulture)
			Else CASETYPEDESC End,
		ACTUALCASETYPE,
		CRMONLY
	from CASETYPE
	where (CRMONLY != 1 OR CRMONLY is null)
End	
Else Begin	
	-- Only extract a list of Case Types if either a UserIdentityId has been passed as a parameter
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

		-- If the CaseTypes are required for an external user then get them from
		-- the SiteControl table otherwise just return all rows from the CASETYPE table

		If @pbIsExternalUser=1
		Begin
			-- NOTE : This code will be replaced if a new method of getting CaseTypes is determined
			insert into @tbCaseTypes(CASETYPE,CASETYPEDESC,ACTUALCASETYPE,CRMONLY)
			select 	CT.CASETYPE,
				-- Output column is 254 so use limited version
				case when @bIsTranslationRequired = 1
					then dbo.fn_GetTranslationLimited(CT.CASETYPEDESC,null,CT.CASETYPEDESC_TID,@psLookupCulture)
					else CT.CASETYPEDESC end,
				ACTUALCASETYPE,
				CRMONLY
			from CASETYPE CT
			join SITECONTROL S on S.CONTROLID='Client Case Types'
			where patindex('%'+CT.CASETYPE+'%',S.COLCHARACTER)>0
			and (CT.CRMONLY != 1 OR CT.CRMONLY is null)
		End
		Else if @pbIsExternalUser=0
		Begin
			-- Is Non-CRM Module in use
			Select @bNonCRMModule=1
			from dbo.fn_LicensedModules(@pnUserIdentityId,@pdtToday) LM
			join LICENSEMODULE M ON M.MODULEID = LM.MODULEID
			where M.MODULEFLAG&@nWebModuleFlag > 0
			and M.MODULEID not in (@CRMWorkBenchLicense,@MarketingModuleLicense)

			-- Is CRM Module in use
			If dbo.fn_IsLicensedForCRM(@pnUserIdentityId, @pdtToday) = 1
				Set @bCRMModule=1

			If  @bCRMModule=1
			and @bNonCRMModule=1
			Begin
				insert into @tbCaseTypes(CASETYPE,CASETYPEDESC,ACTUALCASETYPE,CRMONLY)
				select 	CASETYPE,
					-- Output column is 254 so use limited version
					case when @bIsTranslationRequired = 1
						then dbo.fn_GetTranslationLimited(CASETYPEDESC,null,CASETYPEDESC_TID,@psLookupCulture)
						else CASETYPEDESC end,	
					ACTUALCASETYPE,
					CRMONLY
				from CASETYPE
			End
			Else If @bCRMModule=1
			Begin
				insert into @tbCaseTypes(CASETYPE,CASETYPEDESC,ACTUALCASETYPE,CRMONLY)
				select 	CASETYPE,
					-- Output column is 254 so use limited version
					case when @bIsTranslationRequired = 1
						then dbo.fn_GetTranslationLimited(CASETYPEDESC,null,CASETYPEDESC_TID,@psLookupCulture)
						else CASETYPEDESC end,	
					ACTUALCASETYPE,
					CRMONLY
				from CASETYPE
				where CRMONLY=1
			End
			Else If @bNonCRMModule=1
			Begin
				insert into @tbCaseTypes(CASETYPE,CASETYPEDESC,ACTUALCASETYPE,CRMONLY)
				select 	CASETYPE,
					-- Output column is 254 so use limited version
					case when @bIsTranslationRequired = 1
						then dbo.fn_GetTranslationLimited(CASETYPEDESC,null,CASETYPEDESC_TID,@psLookupCulture)
						else CASETYPEDESC end,	
					ACTUALCASETYPE,
					CRMONLY
				from CASETYPE
				where isnull(CRMONLY,0)=0
			End
		End
	End	
End
	
Return

End
go

grant REFERENCES, SELECT on dbo.fn_FilterUserCaseTypes to public
GO
