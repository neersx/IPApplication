-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListAssignees
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListAssignees]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListAssignees.'
	Drop procedure [dbo].[csw_ListAssignees]
End
Print '**** Creating Stored Procedure dbo.csw_ListAssignees...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListAssignees
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,
	@pbCalledFromCentura	bit			= 0
)
as
-- PROCEDURE:	csw_ListAssignees
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List All Cases for a particular Prior Art Key

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 15 Jun 2011	KR	RFC7904	1	Procedure created
-- 04 Nov 2011	ASH	R11460  2	Cast integer columns as nvarchar(11) data type.
-- 19 Sep 2012	MF	R12166	3	Performance problem returning Assignor names for Cases linked to Assignment/Recordal Case.
-- 04 Nov 2015	KR	R53910	4	Adjust formatted names logic (DR-15543)


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	Set @sSQLString = "
		SELECT	
		C.NAMENO		as NameKey,
		N.NAMECODE		as NameCode,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) 
					as DisplayName,
		C.ADDRESSCODE		as AddressKey,
		dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, ST.STATENAME, 
			A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, 
			CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
					as Address,
		SEQUENCE		as SequenceNo,
		NT.KEEPSTREETFLAG	as KeepStreetFlag,
		N.STREETADDRESS		as StreetAddress,
		C. NAMEVARIANTNO	as NameVariantKey,
		NV.NAMEVARIANT		as NameVariant,
		C.CASEID		as CaseKey,
		NT.NAMETYPE		AS NameTypeKey,
		CAST(C.CASEID as nvarchar(11))+'^'+C.NAMETYPE+'^'+CAST(C.NAMENO as nvarchar(11))+'^'+CAST(C.SEQUENCE as nvarchar(10)) as RowKey,
		C.SEQUENCE		as SequenceNo,
		C.LOGDATETIMESTAMP	as LastModifiedDate
	FROM	CASENAME C
	JOIN	NAME N		 on (C.NAMENO = N.NAMENO)
	JOIN	NAMETYPE NT	 on (NT.NAMETYPE  = C.NAMETYPE)
	LEFT JOIN ADDRESS A	 on (A.ADDRESSCODE=C.ADDRESSCODE)
	LEFT JOIN COUNTRY CT	 on (CT.COUNTRYCODE=A.COUNTRYCODE)
	LEFT JOIN STATE ST	 on (ST.COUNTRYCODE=A.COUNTRYCODE
				 and ST.STATE=A.STATE)
	LEFT JOIN NAMEVARIANT NV on (NV. NAMEVARIANTNO = C.NAMEVARIANTNO)
	WHERE	C.CASEID   = @pnCaseKey
	and	C.NAMETYPE = 'ON'
	AND 	isnull(C.ADDRESSCODE ,-9999999)
			      = isnull((SELECT	MAX(CN1.ADDRESSCODE)  				
					FROM 	CASENAME CN1	
					WHERE CN1.CASEID  =C.CASEID 
					and   CN1.NAMETYPE=C.NAMETYPE
					and   CN1.NAMENO  =C.NAMENO
					and   CN1.ADDRESSCODE is not null), -9999999)
	ORDER BY 2"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'
		@pnUserIdentityId	int,
		@pbCalledFromCentura bit,
		@pnCaseKey		int',
		@pnUserIdentityId   = @pnUserIdentityId,
		@pbCalledFromCentura = @pbCalledFromCentura,
		@pnCaseKey		= @pnCaseKey

End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListAssignees to public
GO