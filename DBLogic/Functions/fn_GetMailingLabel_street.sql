-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetMailingLabel_street
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetMailingLabel_street') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetMailingLabel_street'
	Drop function [dbo].[fn_GetMailingLabel_street]
End
Print '**** Creating Function dbo.fn_GetMailingLabel_street...'
Print ''
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION [dbo].[fn_GetMailingLabel_street]
(
	@pnNameNo int,						--Mandatory
	@psOverridingRelationship nVarchar(3) = null
) 
RETURNS nvarchar(1800)
AS
-- Function :	fn_GetMailingLabel_street
-- VERSION :	2
-- DESCRIPTION:	Format the Name, Attention and Street Address into a single string separated by Carriage Returns for 
-- 		the supplied NameNo. Will use the base name attributes unless an overriding relationship is provided.
-- 		This is an AssociatedName relationship such as Billing address or Statement address. If provided, the 
-- 		routine will use any attention or street address on the associated name in preference to the base name 
-- 		information.
--
--		The Name Style to use is determined by the following logic:
--		If NAME.NAMESTYLE is not null
--			use NAME.NAMESTYLE
--		Else If COUNTRY.NAMESTYLE is not null [where COUNTRY.COUNTRYCODE = NAME.NATIONALITY]
--			use COUNTRY.NAMESTYLE
--		Else 
--			use TABLECODES.TABLECODE [where TABLETYPE = 71 and USERCODE = Site Control 'Name Style Default']
--
--		The Address Style is based on that of the CountryCode related to the address of the Name.
--
--		If the CountryCode related to the address of the Name = Site Control 'HOMECOUNTRY', the country
--		will not be included in the address.
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 29-Jun-2009  MAF		1	Function created.
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

Begin
	Declare @nAddress int,
		@sClientName nVarchar(400), 
		@sAttention nVarchar(400),
		@sAddress nVarchar(1000), 
		@sNameWhere nVarchar(25), 
		@sLabel nVarchar(1800)

	Set @nAddress = null
	Set @sClientName = null
	Set @sAttention = null
	Set @sAddress = null
	Set @sNameWhere = null
	Set @sLabel = null

	If (@pnNameNo is null)
		Set @sLabel = null
	Else
	Begin
		If exists(	Select * 
				from ASSOCIATEDNAME
				where NAMENO = @pnNameNo
				and @psOverridingRelationship is not null
				and RELATIONSHIP = @psOverridingRelationship )
		Begin
			-- Choose assoc name values for preference, but default to related name
			Select 	@sClientName =	Case when RLTDNAME.NAMESTYLE is not null then
							dbo.fn_FormatNameUsingNameNo(RLTDNAME.NAMENO, RLTDNAME.NAMESTYLE)
						     when RLTDNAME.NATIONALITY is not null then
							dbo.fn_FormatNameUsingNameNo(RLTDNAME.NAMENO, RLTDNAMECNS.NAMESTYLE)
						     else dbo.fn_FormatNameUsingNameNo(RLTDNAME.NAMENO, TC.TABLECODE)
						end,
				@sAttention =	Case when AN.CONTACT is not null then 
							Case when ASSOCNAMECTACT.NAMESTYLE is not null then 
								dbo.fn_FormatNameUsingNameNo(ASSOCNAMECTACT.NAMENO, ASSOCNAMECTACT.NAMESTYLE)
							     when ASSOCCTACTCNS.NAMESTYLE is not null then
								dbo.fn_FormatNameUsingNameNo(ASSOCNAMECTACT.NAMENO, ASSOCCTACTCNS.NAMESTYLE)
							     else dbo.fn_FormatNameUsingNameNo(ASSOCNAMECTACT.NAMENO, TC.TABLECODE)
							end
						     else
							Case when RLTDNAMECTACT.NAMESTYLE is not null then 
								dbo.fn_FormatNameUsingNameNo(RLTDNAMECTACT.NAMENO, RLTDNAMECTACT.NAMESTYLE)
							     when RLDTCTACTCNS.NAMESTYLE is not null then
								dbo.fn_FormatNameUsingNameNo(RLTDNAMECTACT.NAMENO, RLDTCTACTCNS.NAMESTYLE)
							     else dbo.fn_FormatNameUsingNameNo(RLTDNAMECTACT.NAMENO, TC.TABLECODE)
							end
						end,
				@nAddress = 	isnull(AN.STREETADDRESS, RLTDNAME.STREETADDRESS),
				@sAddress =	Case when AN.STREETADDRESS is not null then 
							Case when patindex(HC.COLCHARACTER, ASSOCNAMECOUNTRY.COUNTRYCODE) = 0 then
								dbo.fn_FormatAddress(ASSOCNAMEADDR.STREET1, ASSOCNAMEADDR.STREET2, 
								ASSOCNAMEADDR.CITY, ASSOCNAMEADDR.STATE, ASSOCNAMESTATE.STATENAME, 
								ASSOCNAMEADDR.POSTCODE, ASSOCNAMECOUNTRY.POSTALNAME, 
								ASSOCNAMECOUNTRY.POSTCODEFIRST, ASSOCNAMECOUNTRY.STATEABBREVIATED, ASSOCNAMECOUNTRY.POSTCODELITERAL, ASSOCNAMECOUNTRY.ADDRESSSTYLE)
	     						     else dbo.fn_FormatAddress(ASSOCNAMEADDR.STREET1, ASSOCNAMEADDR.STREET2, 
								ASSOCNAMEADDR.CITY, ASSOCNAMEADDR.STATE, ASSOCNAMESTATE.STATENAME, 
								ASSOCNAMEADDR.POSTCODE, null, 
								ASSOCNAMECOUNTRY.POSTCODEFIRST, ASSOCNAMECOUNTRY.STATEABBREVIATED, ASSOCNAMECOUNTRY.POSTCODELITERAL, ASSOCNAMECOUNTRY.ADDRESSSTYLE)
							end
						     else
							Case when patindex(HC.COLCHARACTER, RLTDNAMECOUNTRY.COUNTRYCODE) = 0 then
								dbo.fn_FormatAddress(RLTDNAMEADDR.STREET1, RLTDNAMEADDR.STREET2, 
								RLTDNAMEADDR.CITY, RLTDNAMEADDR.STATE, RLTDNAMESTATE.STATENAME, 
								RLTDNAMEADDR.POSTCODE, RLTDNAMECOUNTRY.POSTALNAME, 
								RLTDNAMECOUNTRY.POSTCODEFIRST, RLTDNAMECOUNTRY.STATEABBREVIATED, RLTDNAMECOUNTRY.POSTCODELITERAL, RLTDNAMECOUNTRY.ADDRESSSTYLE)
	     						     else dbo.fn_FormatAddress(RLTDNAMEADDR.STREET1, RLTDNAMEADDR.STREET2, 
								RLTDNAMEADDR.CITY, RLTDNAMEADDR.STATE, RLTDNAMESTATE.STATENAME, 
								RLTDNAMEADDR.POSTCODE, null, 
								RLTDNAMECOUNTRY.POSTCODEFIRST, RLTDNAMECOUNTRY.STATEABBREVIATED, RLTDNAMECOUNTRY.POSTCODELITERAL, RLTDNAMECOUNTRY.ADDRESSSTYLE)
							end
						end
			from ASSOCIATEDNAME AN
			--Related Name
			join NAME RLTDNAME			on (RLTDNAME.NAMENO = AN.RELATEDNAME)
			--Default Name Style based on Site Control
			left join SITECONTROL SCNS		on (SCNS.CONTROLID = 'Name Style Default')
			left join SITECONTROL HC		on (HC.CONTROLID = 'HOMECOUNTRY')
			left join TABLECODES TC			on (TC.TABLETYPE = 71
								and TC.USERCODE = SCNS.COLCHARACTER)
			left join NAME RLTDNAMECTACT		on (RLTDNAMECTACT.NAMENO = RLTDNAME.MAINCONTACT)
			left join ADDRESS RLTDNAMEADDR		on (RLTDNAMEADDR.ADDRESSCODE = RLTDNAME.STREETADDRESS)
			left join STATE RLTDNAMESTATE		on (RLTDNAMESTATE.COUNTRYCODE = RLTDNAMEADDR.COUNTRYCODE
			    					and RLTDNAMESTATE.STATE = RLTDNAMEADDR.STATE)
			left join COUNTRY RLTDNAMECOUNTRY	on (RLTDNAMECOUNTRY.COUNTRYCODE = RLTDNAMEADDR.COUNTRYCODE)
			--Associated Name
			left join NAME ASSOCNAMECTACT		on (ASSOCNAMECTACT.NAMENO = AN.CONTACT)
			left join ADDRESS ASSOCNAMEADDR		on (ASSOCNAMEADDR.ADDRESSCODE = AN.STREETADDRESS)		
			left join STATE ASSOCNAMESTATE		on (ASSOCNAMESTATE.COUNTRYCODE = ASSOCNAMEADDR.COUNTRYCODE
			    					and ASSOCNAMESTATE.STATE = ASSOCNAMEADDR.STATE)
			left join COUNTRY ASSOCNAMECOUNTRY	on (ASSOCNAMECOUNTRY.COUNTRYCODE = ASSOCNAMEADDR.COUNTRYCODE)
			-- Default Name Style based on Nationality of name
			left join COUNTRY RLTDNAMECNS		on (RLTDNAMECNS.COUNTRYCODE = RLTDNAME.NATIONALITY)
			left join COUNTRY RLDTCTACTCNS		on (RLDTCTACTCNS.COUNTRYCODE = RLTDNAMECTACT.NATIONALITY)
			left join COUNTRY ASSOCCTACTCNS		on (ASSOCCTACTCNS.COUNTRYCODE = ASSOCNAMECTACT.NATIONALITY)
			where AN.NAMENO = @pnNameNo
			and AN.RELATIONSHIP = @psOverridingRelationship
		End
		Else
		Begin
			-- Get the Name, Contact and Street Address associated with the given NameNo
			Select	@sClientName =	Case when N.NAMESTYLE is not null then
							dbo.fn_FormatNameUsingNameNo(N.NAMENO, N.NAMESTYLE)
						     when N.NATIONALITY is not null then
							dbo.fn_FormatNameUsingNameNo(N.NAMENO, CNS.NAMESTYLE)
						     else dbo.fn_FormatNameUsingNameNo(N.NAMENO, TC.TABLECODE)
						end,
				@sAttention =	Case when ATTN.NAMESTYLE is not null then
							dbo.fn_FormatNameUsingNameNo(ATTN.NAMENO, ATTN.NAMESTYLE)
						     when ATTN.NATIONALITY is not null then	
							dbo.fn_FormatNameUsingNameNo(ATTN.NAMENO, CATTNNS.NAMESTYLE)
						     else dbo.fn_FormatNameUsingNameNo(ATTN.NAMENO, TC.TABLECODE)
						end,
				@nAddress = 	N.STREETADDRESS,
				@sAddress =	Case when patindex(HC.COLCHARACTER, C.COUNTRYCODE) = 0 then
							dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, 
							A.POSTCODE, C.POSTALNAME, C.POSTCODEFIRST, C.STATEABBREVIATED, C.POSTCODELITERAL, C.ADDRESSSTYLE)
	     					else dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, 
							A.POSTCODE, null, C.POSTCODEFIRST, C.STATEABBREVIATED, C.POSTCODELITERAL, C.ADDRESSSTYLE)
						end
				from NAME N
				--Default Name Style based on Site Control
				left join SITECONTROL SCNS	on (SCNS.CONTROLID = 'Name Style Default')
				left join SITECONTROL HC	on (HC.CONTROLID = 'HOMECOUNTRY')
				left join TABLECODES TC		on (TC.TABLETYPE = 71
								and TC.USERCODE = SCNS.COLCHARACTER)
				left join NAME ATTN		on (ATTN.NAMENO = N.MAINCONTACT)
				left join ADDRESS A		on (A.ADDRESSCODE = N.STREETADDRESS)
				left join STATE S		on (S.COUNTRYCODE = A.COUNTRYCODE
			    					and S.STATE = A.STATE)
				left join COUNTRY C		on (C.COUNTRYCODE = A.COUNTRYCODE)
				-- Default Name Style based on Nationality of name
				left join COUNTRY CNS		on (CNS.COUNTRYCODE = N.NATIONALITY)
				left join COUNTRY CATTNNS	on (CATTNNS.COUNTRYCODE = ATTN.NATIONALITY)
				where N.NAMENO = @pnNameNo
		End

		-- Find where the country usually puts the name (before or after the address)
		select @sNameWhere = USERCODE 
		from ADDRESS A, COUNTRY CT,  TABLECODES ADS
		where A.COUNTRYCODE = CT.COUNTRYCODE
		and ADS.TABLECODE = CT.ADDRESSSTYLE 
		and ADS.TABLETYPE = 72 
		and A.ADDRESSCODE = @nAddress 

		Select @sLabel = Convert(varchar(254), 
				 Case when @sNameWhere = 'NameBefore' then 
					Case when @sClientName is not null then @sClientName + char(13) + char(10) end
					+ 
					Case when @sAttention is not null then @sAttention + char(13) + char(10) end
					+ 
					@sAddress
				      when @sNameWhere = 'NameAfter' then
					Case when @sAddress is not null then @sAddress + char(13) + char(10) end
					+ 
					Case when @sAttention is not null then @sAttention + char(13) + char(10) end
					+ 
					@sClientName  
				 End)
	End
		
	Return @sLabel
End

GO

Grant execute on dbo.fn_GetMailingLabel_street to public
GO