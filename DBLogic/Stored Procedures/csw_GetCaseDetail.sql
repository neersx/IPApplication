-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetCaseDetail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetCaseDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetCaseDetail.'
	Drop procedure [dbo].[csw_GetCaseDetail]
End
Print '**** Creating Stored Procedure dbo.csw_GetCaseDetail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetCaseDetail
(
	@pnUserIdentityId	int,	-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,
	@psOfficialNumber	nvarchar(72)	= null,
        @psCountry	        nvarchar(6)	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	csw_GetCaseDetail
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get the detail about a Case

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 15 Aug 2011	KR	R7904	1	Procedure created
-- 07 Oct 2011	KR	R11308	2	Added OfficialNumber as parameter to allow case details to be returned based on official no
-- 30 Jan 2012	KR	R11567	3	Return all owners
-- 04 Nov 2015	KR	R53910	4	Adjust formatted names logic (DR-15543)
-- 05 Sep 2017	AK	R61299	5	Included CountryCode and CountryName in resultset


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
DECLARE @sOwners		nvarchar(Max)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	if @pnCaseKey is not null
	Begin
		-- set it to an empty string to start with for owners
		SET @sOwners = ''


		SELECT  @sOwners = COALESCE(@sOwners + ',','') + dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
		from CASENAME CN 
		join NAME N on (N.NAMENO = CN.NAMENO) 
		where CASEID = @pnCaseKey AND NAMETYPE = 'O'
		SELECT @sOwners = SUBSTRING(@sOwners, 2, Len(@sOwners))
	
		Set @sSQLString = "Select
				C.CASEID		as RelatedCaseKey,
				C.IRN			as RelatedCaseReference,
				C.CURRENTOFFICIALNO	as OfficialNumber,
				C.TITLE                 as Title,
				@sOwners                as Owner,
                                CR.COUNTRY              as CountryName,
                                CR.COUNTRYCODE          as CountryCode
				from CASES C
                                JOIN COUNTRY CR ON (CR.COUNTRYCODE = C.COUNTRYCODE)
				where C.CASEID = @pnCaseKey"

		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnUserIdentityId	int,
				@pbCalledFromCentura	bit,
				@pnCaseKey		int,
				@sOwners		nvarchar(max)',
				@pnUserIdentityId	= @pnUserIdentityId,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@pnCaseKey		= @pnCaseKey,
				@sOwners		= @sOwners
	End
	
	Else if @psOfficialNumber is not null
	Begin
	
		-- set it to an empty string to start with for owners
		SET @sOwners = ''


		SELECT  @sOwners = COALESCE(@sOwners + ',','') + dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
		from CASENAME CN 
		join NAME N on (N.NAMENO = CN.NAMENO) 
		Join (Select top 1 C.CASEID from CASES C where C.CURRENTOFFICIALNO = @psOfficialNumber ) C on (C.CASEID = CN.CASEID)
		where  CN.NAMETYPE = 'O'
		
		SELECT @sOwners = SUBSTRING(@sOwners, 2, Len(@sOwners))
	
		Set @sSQLString = "Select TOP 1
				C.CASEID		as RelatedCaseKey,
				C.IRN			as RelatedCaseReference,
				C.CURRENTOFFICIALNO	as OfficialNumber,
				C.TITLE as Title,
				@sOwners as Owner,
                                CR.COUNTRY              as CountryName,
                                CR.COUNTRYCODE          as CountryCode
				from CASES C
                                JOIN COUNTRY CR ON (CR.COUNTRYCODE = C.COUNTRYCODE)
				LEFT JOIN (SELECT CN.CASEID, CN.NAMENO, CN.NAMETYPE,CN.SEQUENCE FROM CASENAME CN
					JOIN 
					(select CASEID, MIN(SEQUENCE) AS SEQUENCE, NAMETYPE
					 from CASENAME where NAMETYPE = 'O'
					 GROUP BY CASEID, NAMETYPE) AS CN1
					 ON CN1.CASEID = CN.CASEID
					 AND CN1.SEQUENCE = CN.SEQUENCE
					 AND CN1.NAMETYPE = CN.NAMETYPE)  
					 AS CN2 ON CN2.CASEID = C.CASEID
				LEFT JOIN NAME N ON (CN2.NAMENO = N.NAMENO)
				where C.CURRENTOFFICIALNO = @psOfficialNumber and C.COUNTRYCODE = @psCountry"

		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnUserIdentityId	int,
				@pbCalledFromCentura	bit,
				@psOfficialNumber	nvarchar(72),
                                @psCountry              nvarchar(6),
				@sOwners		nvarchar(max)',
				@pnUserIdentityId	= @pnUserIdentityId,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@psOfficialNumber	= @psOfficialNumber,
                                @psCountry              = @psCountry,
				@sOwners		= @sOwners
	End

End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetCaseDetail to public
GO