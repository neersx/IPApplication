-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ig_CMSGetGHCaseNames
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ig_CMSGetGHCaseNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ig_CMSGetGHCaseNames.'
	Drop procedure [dbo].[ig_CMSGetGHCaseNames]
End
Print '**** Creating Stored Procedure dbo.ig_CMSGetGHCaseNames...'
Print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.ig_CMSGetGHCaseNames
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int
)
as
-- PROCEDURE :	ig_CMSGetGHCaseNames
-- VERSION :	3
-- DESCRIPTION:	Returns Party details to be used in Integration with CMS. A party can be an Owner
-- COPYRIGHT:	Copyright 1993 - 2005 CPA Software Solutions (Australia) Pty Limited
--
--		The following details will be returned :
--			ClientUno
--			NameUno
--			Type
--			DataRetrievalStatus 'I'
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 6 Nov 2006	PK	4528	1	Require Owners NameType to be interfaced to CMS
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 04 Jun 2010	MF	18703	3	 NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE, ensure these are considered for the Case.
		
set nocount on
set concat_null_yields_null off

Declare		@ErrorCode		int

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0

-- Integrate
If @ErrorCode=0
Begin
	Select		'N'					as [Conflict],
			'N'					as [Inactive],
			isnull(ONX.OFFICIALNUMBER,'')		as [MatterUno],
			isnull(NAL.ALIAS,'')			as [NameUno],
			case when cn.NAMETYPE = 'O' then 'APP' else 'Unknown' end
								as [PartyType],
			case when cn.NAMETYPE = 'O' then 'R' else 'Unknown' end
								as [PartyTypeCode]
	From		CASENAME cn
	join		CASES C on (C.CASEID=cn.CASEID)
	left join	SITECONTROL SC1
			on (SC1.CONTROLID = 'CMS Unique Name Alias Type')
	left join	SITECONTROL SC2
			on (SC2.CONTROLID = 'CMS Unique Matter Number Type')
	left join	OFFICIALNUMBERS ONX
			on (ONX.CASEID = cn.CASEID
			and ONX.NUMBERTYPE = SC2.COLCHARACTER)
	left join	NAMEALIAS NAL	on (NAL.NAMENO	=cn.NAMENO
					and NAL.ALIASTYPE=SC1.COLCHARACTER
							-- SQA18703
							-- Use best fit to determine ALIAS for the Case
							-- characteristics of CountryCode and PropertyType
					and NAL.ALIAS    =(select substring(max(CASE WHEN(NAL1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
										CASE WHEN(NAL1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
										NAL1.ALIAS),3,30)
							  from NAMEALIAS NAL1
							  where NAL1.NAMENO=NAL.NAMENO
							  and NAL1.ALIASTYPE=NAL.ALIASTYPE
							  and(NAL1.COUNTRYCODE =C.COUNTRYCODE  OR NAL1.COUNTRYCODE  is null)
							  and(NAL1.PROPERTYTYPE=C.PROPERTYTYPE OR NAL1.PROPERTYTYPE is null)))
	Where		cn.CASEID = @pnCaseKey and cn.NAMETYPE = 'O'

	Set @ErrorCode = @@error
End

Return @ErrorCode
go

grant execute on dbo.ig_CMSGetGHCaseNames to public
go
