-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetCaseOrNameEditability
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_GetCaseOrNameEditability]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipw_GetCaseOrNameEditability.'
	drop procedure dbo.ipw_GetCaseOrNameEditability
end
print '**** Creating procedure dbo.ipw_GetCaseOrNameEditability...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_GetCaseOrNameEditability
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture				nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnCaseKey				int,
	@pnNameKey				int
)
with ENCRYPTION
AS
-- PROCEDURE :	ipw_GetCaseOrNameEditability
-- VERSION :	13
-- DESCRIPTION:	Returns CanInsert,CanUpdate and CanDelete bits for the given Case or Name.
-- 				Originally ipw_IsCaseOrNameEditable which returned IsEditable, obsoleted because single flag use is ambiguous.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date         Who  	Number		Version Change
-- ------------ ---- 	------		------- ------------------------------------------- 
-- 29 Mar 2010	JC  	RFC8994		1	Procedure Created
-- 15 Jul 2011	JCLG  	RFC10989	2	Encrypt
-- 26 Dec 2011	DV	RFC11140	3	Check for Case Access Security.
-- 11 Jan 2011	SF	RFC11781	4	Incorrectly filtering out licenses which has not expired.
-- 12 Jan 2011  DV	RFC11781	5	Implement Row Access security for both Case and Name
-- 19 Mar 2013	SF	RFC13286	6	Return CanInsert, CanUpdate and CanDelete instead
-- 26 Mar 2013	SF	RFC13286	7	Row Access Security should be considered where there is one or more row access details against the user identity
--						It should be applied over the top of Case Access Security.
--  3 Apr 2013	SF	RFC13286	8	Return 0 for those cases not meeting case access requirements
--  3 Apr 2013	SF	RFC13286	9	Correction to inaccurate evaluation of Name Row Access Security.
-- 04 Apr 2013	DV	RFC13286	10	If Row access is not set for Name then the CanInsert, CanUpdate and CanDelete should be 1
-- 02 Oct 2014	LP	R9422		11	Cater for Marketing Module license.	
-- 20 Nov 2014	LP	R41712		12	Corrected license number for Marketing Module (Pricing Model 2)
-- 07 Sep 2018	AV	74738	13	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @nErrorCode					int
declare @sSQLString 				nvarchar(max)
declare @sSQLCaseAccessString 		nvarchar(max)
declare @dtToday					datetime
declare @nCountLicenses				int
declare @nCountUnrestricted			int
declare @nCountCRM					int
declare @nCountNonCRM				int
declare @nDefaultCaseStatusAccessValue int
declare @bHasCaseUpdateAccessSecurity bit
declare @bHasCaseDeleteAccessSecurity bit
declare @bHasCaseInsertAccessSecurity bit
declare @bHasNameUpdateAccessSecurity bit
declare @bHasNameInsertAccessSecurity bit
declare @bHasNameDeleteAccessSecurity bit
declare @bUseOfficeSecurity	bit
declare @bHasRowAccessSecurity bit
declare @CRMWorkBenchLicense	int
declare	@MarketingModuleLicense	int

-- Initialise variables
Set @nErrorCode = 0
set @dtToday = getDate()
set @bUseOfficeSecurity	= 0
set @bHasRowAccessSecurity = 0
set @bHasNameUpdateAccessSecurity = 1
set @bHasNameInsertAccessSecurity = 1
set @bHasNameDeleteAccessSecurity = 1
set @CRMWorkBenchLicense = 25
set @MarketingModuleLicense = 32

-- Check if user has been assigned row access security profile
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @bHasRowAccessSecurity = 1,
	@bUseOfficeSecurity = ISNULL(SC.COLBOOLEAN, 0)
	from IDENTITYROWACCESS U WITH (NOLOCK) 
	join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
	left join SITECONTROL SC WITH (NOLOCK) on (SC.CONTROLID = 'Row Security Uses Case Office')
	where R.RECORDTYPE = 'C'
	and U.IDENTITYID = @pnUserIdentityId"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@bHasRowAccessSecurity	bit OUTPUT,
			  @bUseOfficeSecurity		bit OUTPUT,
			  @pnUserIdentityId		int',
			  @bHasRowAccessSecurity=@bHasRowAccessSecurity OUTPUT,
			  @bUseOfficeSecurity=@bUseOfficeSecurity OUTPUT,
			  @pnUserIdentityId=@pnUserIdentityId	
			  
End

If @nErrorCode = 0
Begin
	If @pnCaseKey is not null
	Begin
		-- Set the Case Security level to the default value.
		Set @sSQLString = "
		SELECT @nDefaultCaseStatusAccessValue = ISNULL(SC.COLINTEGER,15)
		FROM SITECONTROL SC 
		WHERE SC.CONTROLID = 'Default Security'"

		exec @nErrorCode =	sp_executesql @sSQLString,
					N'@nDefaultCaseStatusAccessValue	int 		output',
	  				@nDefaultCaseStatusAccessValue	= @nDefaultCaseStatusAccessValue 	output
	  				  

		Set @sSQLCaseAccessString = "&	
																CASE 
																		WHEN convert(bit,(UserCaseStatusAccessValue.SECURITYFLAG&(2|4|8)))=1 THEN convert(bit,1) 
																		WHEN UserCaseStatusAccessValue.SECURITYFLAG IS NULL THEN 
																			CASE 
																				WHEN (convert(bit,@nDefaultCaseStatusAccessValue&(2|4|8)))=1 THEN convert(bit,1)
																				ELSE convert(bit,0) 
																			END
																		ELSE convert(bit,0)
																		END"
				  
		Set @sSQLString = "Select 
								@bHasCaseDeleteAccessSecurity = CASE WHEN RowAccessAgainst.IDENTITYID IS NULL THEN CONVERT(BIT, 1)
																	 WHEN convert(bit,(MostRestrictiveAccess.SECURITYFLAG&2))=1 THEN convert(bit,1) 
																	 ELSE convert(bit,0) 
																END
																" + @sSQLCaseAccessString + ",
								@bHasCaseInsertAccessSecurity = CASE WHEN RowAccessAgainst.IDENTITYID IS NULL THEN CONVERT(BIT, 1)
																	 WHEN convert(bit,(MostRestrictiveAccess.SECURITYFLAG&4))=1 THEN convert(bit,1) 
																	 ELSE convert(bit,0) 
																END
																" + @sSQLCaseAccessString + ",
								@bHasCaseUpdateAccessSecurity = CASE WHEN RowAccessAgainst.IDENTITYID IS NULL THEN CONVERT(BIT, 1)
																	 WHEN convert(bit,(MostRestrictiveAccess.SECURITYFLAG&8))=1 THEN convert(bit,1) 
																	 ELSE convert(bit,0) 
																END																
																" + @sSQLCaseAccessString + 
				"
				from CASES C
				" +
				-- Find cases where they are editable by the user based on Case Status.
				"
				left join (select UC.CASEID as CASEID,
						(Select ISNULL(US.SECURITYFLAG,Isnull(@nDefaultCaseStatusAccessValue,15))
						  from USERSTATUS US WITH (NOLOCK)
						  JOIN USERIDENTITY UI ON (UI.LOGINID = US.USERID and US.STATUSCODE = UC.STATUSCODE)
						  WHERE UI.IDENTITYID =@pnUserIdentityId) as SECURITYFLAG
					    from CASES UC) UserCaseStatusAccessValue on (UserCaseStatusAccessValue.CASEID=C.CASEID)" +
				
				-- Consider Row Access only if at least one row access profile have been assigned to the user identity.	    
				"
				left join IDENTITYROWACCESS RowAccessAgainst with (NOLOCK) on (RowAccessAgainst.IDENTITYID = @pnUserIdentityId)" 
			
		If @bUseOfficeSecurity = 1
		Begin
			Set @sSQLString =@sSQLString+char(10)+"
				left join (	select XC.CASEID as CASEID,
						convert(int,
						SUBSTRING(
						(Select MAX(CASE WHEN RAD.OFFICE       is NULL THEN '0' ELSE '1' END+
							    CASE WHEN RAD.CASETYPE     is NULL THEN '0' ELSE '1' END+
							    CASE WHEN RAD.PROPERTYTYPE is NULL THEN '0' ELSE '1' END+
							    CASE WHEN RAD.SECURITYFLAG<10      THEN '0' ELSE ''  END+
							    convert(nvarchar,RAD.SECURITYFLAG))
						  from IDENTITYROWACCESS UA WITH (NOLOCK)
						  join ROWACCESSDETAIL RAD WITH (NOLOCK)
									on (RAD.ACCESSNAME  =UA.ACCESSNAME
									and RAD.RECORDTYPE  ='C'
									and(RAD.OFFICE      =XC.OFFICEID     or RAD.OFFICE       is NULL)
									and(RAD.CASETYPE    =XC.CASETYPE     or RAD.CASETYPE     is NULL)
									and(RAD.PROPERTYTYPE=XC.PROPERTYTYPE or RAD.PROPERTYTYPE is NULL))
						  where UA.IDENTITYID=@pnUserIdentityId),4,2)) as SECURITYFLAG
					from CASES XC ) MostRestrictiveAccess on (MostRestrictiveAccess.CASEID=C.CASEID)"
		End
		Else Begin
			Set @sSQLString =@sSQLString+char(10)+"
				left join (	select  XC.CASEID as CASEID,
						convert(int,
						SUBSTRING(
						(Select MAX(CASE WHEN RAD.OFFICE       is NULL THEN '0' ELSE '1' END+
							    CASE WHEN RAD.CASETYPE     is NULL THEN '0' ELSE '1' END+
							    CASE WHEN RAD.PROPERTYTYPE is NULL THEN '0' ELSE '1' END+
							    CASE WHEN RAD.SECURITYFLAG<10      THEN '0' ELSE ''  END+
							    convert(nvarchar,RAD.SECURITYFLAG))
						  from IDENTITYROWACCESS UA WITH (NOLOCK)
						  join ROWACCESSDETAIL RAD WITH (NOLOCK)
									on (RAD.ACCESSNAME  =UA.ACCESSNAME
									and RAD.RECORDTYPE  ='C'
									-- Getting office using subselect as this made a significant performance improvement
									and(RAD.OFFICE in (select TA.TABLECODE from TABLEATTRIBUTES TA where TA.PARENTTABLE='CASES' and TA.TABLETYPE=44 and TA.GENERICKEY=convert(nvarchar, XC.CASEID)) 
									 or RAD.OFFICE is NULL)
									and(RAD.CASETYPE    =XC.CASETYPE     or RAD.CASETYPE     is NULL)
									and(RAD.PROPERTYTYPE=XC.PROPERTYTYPE or RAD.PROPERTYTYPE is NULL))
						  where UA.IDENTITYID=@pnUserIdentityId),4,2)) as SECURITYFLAG
					from CASES XC ) MostRestrictiveAccess on (MostRestrictiveAccess.CASEID=C.CASEID)"
		End
		
		Set @sSQLString =@sSQLString+char(10)+"
				where C.CASEID = @pnCaseKey"
				
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@bHasCaseInsertAccessSecurity	bit 	output,
					  @bHasCaseUpdateAccessSecurity	bit 	output,
					  @bHasCaseDeleteAccessSecurity	bit 	output,
					  @nDefaultCaseStatusAccessValue	int,
					  @pnUserIdentityId		int,
					  @pnCaseKey			int',
					  @bHasCaseInsertAccessSecurity=@bHasCaseInsertAccessSecurity output,
					  @bHasCaseUpdateAccessSecurity=@bHasCaseUpdateAccessSecurity output,
					  @bHasCaseDeleteAccessSecurity=@bHasCaseDeleteAccessSecurity output,
					  @nDefaultCaseStatusAccessValue=@nDefaultCaseStatusAccessValue,
					  @pnUserIdentityId=@pnUserIdentityId,
					  @pnCaseKey=@pnCaseKey
  					  
		
		If @nErrorCode = 0
		Begin
		-- If CASETYPE is CRM, then check that the user has the CRM License
		-- Otherwise, check that the user has another license but not CRM
		-- TaskID = 56 (Maintain Case)
		Set @sSQLString = "
			Select	case COUNT(*) when 0 then cast(0 as bit) else @bHasCaseInsertAccessSecurity end as 'CanInsert',
					case COUNT(*) when 0 then cast(0 as bit) else @bHasCaseUpdateAccessSecurity end as 'CanUpdate',
					case COUNT(*) when 0 then cast(0 as bit) else @bHasCaseDeleteAccessSecurity end as 'CanDelete'
			from LICENSEMODULE LM
			join USERIDENTITY UI	on (UI.IDENTITYID = @pnUserIdentityId)
			join dbo.fn_LicensedModules(@pnUserIdentityId, @dtToday) FLM
						on (FLM.MODULEID = LM.MODULEID)	
			join dbo.fn_LicenseData() LD on (LD.MODULEID = LM.MODULEID)
			join dbo.fn_ObjectLicense(56, 20) OL on (OL.MODULEID = LM.MODULEID)
			join CASES C	on (C.CASEID = @pnCaseKey)
			join CASETYPE CT on (CT.CASETYPE = C.CASETYPE)
			where LM.MODULEFLAG&4 > 0
			and ((ISNULL(CT.CRMONLY,0) = 1 AND LM.MODULEID in (@CRMWorkBenchLicense,@MarketingModuleLicense))
				or (ISNULL(CT.CRMONLY,0) = 0 AND LM.MODULEID not in (@CRMWorkBenchLicense,@MarketingModuleLicense)))
			and (UI.ISEXTERNALUSER = 0 and LM.INTERNALUSE = 1)
			and (LD.EXPIRYDATE is null or LD.EXPIRYDATE > @dtToday)"
			
		exec @nErrorCode = sp_executesql @sSQLString,
			N'	@dtToday						datetime,
				@pnCaseKey						int,
				@pnUserIdentityId				int,
				@bHasCaseInsertAccessSecurity	bit,
				@bHasCaseUpdateAccessSecurity	bit,
				@bHasCaseDeleteAccessSecurity	bit,
				@CRMWorkBenchLicense		int,
				@MarketingModuleLicense		int',
				@dtToday=@dtToday,
				@pnCaseKey=@pnCaseKey,
				@pnUserIdentityId=@pnUserIdentityId,
				@bHasCaseInsertAccessSecurity=@bHasCaseInsertAccessSecurity,
				@bHasCaseUpdateAccessSecurity=@bHasCaseUpdateAccessSecurity,
				@bHasCaseDeleteAccessSecurity=@bHasCaseDeleteAccessSecurity,
				@CRMWorkBenchLicense=@CRMWorkBenchLicense,
				@MarketingModuleLicense=@MarketingModuleLicense
		End
	End
	Else If @pnNameKey is not null
	Begin
		Set @sSQLString= "select @bHasNameDeleteAccessSecurity = 
									CASE
										WHEN RowAccessAgainst.IDENTITYID IS null THEN convert(bit,1)  
										WHEN convert(bit,(RSC.SECURITYFLAG&2))=1 THEN convert(bit,1) 
										ELSE convert(bit,0) 
									END,
								 @bHasNameInsertAccessSecurity = 
									CASE 
										WHEN RowAccessAgainst.IDENTITYID IS null THEN convert(bit,1) 
										WHEN convert(bit,(RSC.SECURITYFLAG&4))=1 THEN convert(bit,1) 
										ELSE convert(bit,0) 
									END,
								 @bHasNameUpdateAccessSecurity = 
									CASE 
										WHEN RowAccessAgainst.IDENTITYID IS null THEN convert(bit,1) 
										WHEN convert(bit,(RSC.SECURITYFLAG&8))=1 THEN convert(bit,1) 
										ELSE convert(bit,0) 
									END
				   from NAME N
				   left join (select XN.NAMENO as NAMENO,
						convert(int,
						SUBSTRING(
						(Select MAX(CASE WHEN RAD.OFFICE       is NULL THEN '0' ELSE '1' END+
							    CASE WHEN RAD.NAMETYPE     is NULL THEN '0' ELSE '1' END+
							    CASE WHEN RAD.SECURITYFLAG<10      THEN '0' ELSE ''  END+
							    convert(nvarchar,RAD.SECURITYFLAG))
						  from IDENTITYROWACCESS UA WITH (NOLOCK)
						  join ROWACCESSDETAIL RAD WITH (NOLOCK)
									on (RAD.ACCESSNAME  =UA.ACCESSNAME
									and RAD.RECORDTYPE  ='N'
									and(RAD.OFFICE       in (select TA.TABLECODE from TABLEATTRIBUTES TA where TA.PARENTTABLE='NAME' and TA.TABLETYPE=44 and TA.GENERICKEY=convert(nvarchar, XN.NAMENO))
									 or RAD.OFFICE       is NULL)
									and(RAD.NAMETYPE     in (select NTC.NAMETYPE from NAMETYPECLASSIFICATION NTC WHERE NTC.ALLOW = 1 and NTC.NAMENO = XN.NAMENO)
									 or RAD.NAMETYPE     is NULL)
									and RAD.CASETYPE     is NULL
									and RAD.PROPERTYTYPE is NULL)
						  where UA.IDENTITYID=@pnUserIdentityId),3,2)) as SECURITYFLAG
					   from NAME XN ) RSC on (RSC.NAMENO=N.NAMENO)
				   left join IDENTITYROWACCESS RowAccessAgainst with (NOLOCK) on (RowAccessAgainst.IDENTITYID = @pnUserIdentityId)
				   where N.NAMENO = @pnNameKey"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnNameKey			int,
				  @pnUserIdentityId		int,
				  @bHasNameDeleteAccessSecurity bit output,
				  @bHasNameInsertAccessSecurity	bit output,
				  @bHasNameUpdateAccessSecurity bit output',
				  @pnNameKey=@pnNameKey,
				  @pnUserIdentityId=@pnUserIdentityId,
				  @bHasNameDeleteAccessSecurity=@bHasNameDeleteAccessSecurity output,
				  @bHasNameInsertAccessSecurity=@bHasNameInsertAccessSecurity output,
				  @bHasNameUpdateAccessSecurity=@bHasNameUpdateAccessSecurity output
				  
		If @nErrorCode = 0
		Begin
			-- If User is only licensed to CRM user, check that all name types for the Name is of type CRM
			-- TaskID = 65 (Maintain Name)
			Set @sSQLString = "
				Select @nCountLicenses = COUNT(*)
				from LICENSEMODULE LM
				join USERIDENTITY UI	on (UI.IDENTITYID = @pnUserIdentityId)
				join dbo.fn_LicensedModules(@pnUserIdentityId, @dtToday) FLM
							on (FLM.MODULEID = LM.MODULEID)	
				join dbo.fn_LicenseData() LD on (LD.MODULEID = LM.MODULEID)
				join dbo.fn_ObjectLicense(65, 20) OL on (OL.MODULEID = LM.MODULEID)
				where LM.MODULEFLAG&4 > 0
				and LM.MODULEID not in (@CRMWorkBenchLicense,@MarketingModuleLicense)
				and (UI.ISEXTERNALUSER = 0 and LM.INTERNALUSE = 1)
				and (LD.EXPIRYDATE is null or LD.EXPIRYDATE > @dtToday)"
			
			exec @nErrorCode = sp_executesql @sSQLString,
				N'@nCountLicenses		int OUTPUT,
				  @dtToday				datetime,
				  @pnUserIdentityId		int,
				  @CRMWorkBenchLicense		int,
				  @MarketingModuleLicense	int',
				  @nCountLicenses=@nCountLicenses OUTPUT,
				  @dtToday=@dtToday,
				  @pnUserIdentityId=@pnUserIdentityId,
				  @CRMWorkBenchLicense=@CRMWorkBenchLicense,
				  @MarketingModuleLicense=@MarketingModuleLicense	
		End
			  
			
		If @nErrorCode = 0
		Begin
			If @nCountLicenses = 0
			Begin
				Set @sSQLString = "
				Select @nCountUnrestricted = SUM(case NC.NAMETYPE when '~~~' then 1 else 0 end),
					   @nCountCRM = SUM(case (NT.PICKLISTFLAGS & 32) when 32 then 1 else 0 end),
					   @nCountNonCRM = SUM(case (NT.PICKLISTFLAGS & 32) when 0 then 1 else 0 end)
				from NAMETYPECLASSIFICATION NC
				join NAMETYPE NT on (NT.NAMETYPE = NC.NAMETYPE)
				where NC.ALLOW = 1
				and NC.NAMENO = @pnNameKey"
					
				exec @nErrorCode = sp_executesql @sSQLString,
					N'@nCountUnrestricted	int	OUTPUT,
					  @nCountCRM			int OUTPUT,
					  @nCountNonCRM			int OUTPUT,
					  @pnNameKey			int',
					  @nCountUnrestricted=@nCountUnrestricted OUTPUT,
					  @nCountCRM=@nCountCRM OUTPUT,
					  @nCountNonCRM=@nCountNonCRM OUTPUT,
					  @pnNameKey=@pnNameKey
				
				If @nErrorCode = 0
				Begin
					If @nCountUnrestricted = 1 and @nCountCRM = 0 and @nCountNonCRM = 1
					Begin
						-- Only Unrestricted Name Type found. Can't edit the name
						SELECT	cast(0 as bit) & @bHasNameInsertAccessSecurity as 'CanInsert',
								cast(0 as bit) & @bHasNameUpdateAccessSecurity as 'CanUpdate',
								cast(0 as bit) & @bHasNameDeleteAccessSecurity as 'CanDelete'
						
						
					End
					Else If @nCountCRM > 0 and ((@nCountUnrestricted = 1 and @nCountNonCRM = 1) or (@nCountUnrestricted = 0 and @nCountNonCRM = 0))
					Begin
						-- All Name Types are CRM. Can't edit the name
						SELECT	cast(1 as bit) & @bHasNameInsertAccessSecurity as 'CanInsert',
								cast(1 as bit) & @bHasNameUpdateAccessSecurity as 'CanUpdate',
								cast(1 as bit) & @bHasNameDeleteAccessSecurity as 'CanDelete'
						
					End
					Else
					Begin
						-- There is at least one non CRM Name Type. Can't edit the name
						SELECT	cast(0 as bit) & @bHasNameInsertAccessSecurity as 'CanInsert',
								cast(0 as bit) & @bHasNameUpdateAccessSecurity as 'CanUpdate',
								cast(0 as bit) & @bHasNameDeleteAccessSecurity as 'CanDelete'
						
					End
				End
			End
			Else
			Begin
				-- Return true (Found at least another license than CRM)
				SELECT	cast(1 as bit) & @bHasNameInsertAccessSecurity as 'CanInsert',
						cast(1 as bit) & @bHasNameUpdateAccessSecurity as 'CanUpdate',
						cast(1 as bit) & @bHasNameDeleteAccessSecurity as 'CanDelete'
						
			End
		End
	End
	Else
	Begin
		-- Return False if CaseKey and NameKey are null
		SELECT	cast(0 as bit) as 'CanInsert',
				cast(0 as bit) as 'CanUpdate',
				cast(0 as bit) as 'CanDelete'
						
	End
End

RETURN @nErrorCode
go

grant execute on dbo.ipw_GetCaseOrNameEditability to public
go
