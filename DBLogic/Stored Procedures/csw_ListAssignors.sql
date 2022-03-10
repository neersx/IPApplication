-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListAssignors
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListAssignors]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListAssignors.'
	Drop procedure [dbo].[csw_ListAssignors]
End
Print '**** Creating Stored Procedure dbo.csw_ListAssignors...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListAssignors
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,
	@pbGetAssignor		bit		= 0,
	@pbCalledFromCentura	bit			= 0
)
as
-- PROCEDURE:	csw_ListAssignors
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List the Assignor names associated with an Assignment/Recordal case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 15 Jun 2011	KR	7904	1	Procedure created
-- 26 Oct 2011	KR	11308	2	Fixed sql for get assignors
-- 04 Nov 2011	ASH	R11460  3	Cast integer columns as nvarchar(11) data type.
-- 19 Sep 2012	MF	R12166	4	Performance problem returning Assignor names for Cases linked to Assignment/Recordal Case.
-- 04 Nov 2015	KR	R53910	5	Adjust formatted names logic (DR-15543)


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

	if exists (Select 1 from RELATEDCASE where CASEID = @pnCaseKey and RELATIONSHIP = 'ASG') AND @pbGetAssignor = 1
	Begin
			
	
		Set @sSQLString = "
		----------------------------------------------------------
		-- The first SELECT resturns the Owner names that are
		-- directly associated with the Assignement/Recordal Case
		----------------------------------------------------------
		SELECT
			@pnCaseKey		as CaseKey,
			1			as IsRelated,
			C.NAMENO		as NameKey,
			N.NAMECODE		as NameCode,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
						as DisplayName,
			C.ADDRESSCODE		as AddressKey,
			dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, ST.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
						as Address,
			NT.KEEPSTREETFLAG	as KeepStreetFlag,
			N.STREETADDRESS		as StreetAddress,
			C. NAMEVARIANTNO	as NameVariantKey,
			NV.NAMEVARIANT		as NameVariant,
			NT.NAMETYPE		AS NameTypeKey,
			C.NAMETYPE+'^'+CAST(C.NAMENO as nvarchar(11))+'^'+CAST(C.SEQUENCE as nvarchar(10)) 
						as RowKey,
			C.SEQUENCE		as SequenceNo,
			C.LOGDATETIMESTAMP	as LastModifiedDate
		FROM CASENAME C
		JOIN NAME N		 on (C.NAMENO = N.NAMENO)  	
		JOIN NAMETYPE NT	 on (NT.NAMETYPE = C.NAMETYPE)
		LEFT JOIN ADDRESS A	 on (A.ADDRESSCODE=C.ADDRESSCODE)
		LEFT JOIN COUNTRY CT	 on (CT.COUNTRYCODE=A.COUNTRYCODE)
		LEFT JOIN STATE ST	 on (ST.COUNTRYCODE=A.COUNTRYCODE
					 and ST.STATE=A.STATE)
		LEFT JOIN NAMEVARIANT NV on (C. NAMEVARIANTNO = NV.NAMEVARIANTNO)
		WHERE	C.CASEID   = @pnCaseKey
		AND	C.NAMETYPE = 'O'
		AND 	isnull(C.ADDRESSCODE ,-9999999)
				      = isnull((SELECT	MAX(CN1.ADDRESSCODE)  				
						FROM 	CASENAME CN1	
						WHERE CN1.CASEID  =C.CASEID 
						and   CN1.NAMETYPE=C.NAMETYPE
						and   CN1.NAMENO  =C.NAMENO
						and CN1.ADDRESSCODE is not null), -9999999)
			
		UNION

		-----------------------------------------------------------
		-- The second SELECT resturns the Owner names that are
		-- associated with the Cases being assigned and are related
		-- to the Assignement/Recordal Case
		-----------------------------------------------------------
		SELECT	@pnCaseKey		as CaseKey,
			1			as IsRelated,
			C.NAMENO		as NameKey,
			N.NAMECODE		as NameCode,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
						as DisplayName,
			C.ADDRESSCODE		as AddressKey,
			dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, ST.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
						as Address,
			NT.KEEPSTREETFLAG	as KeepStreetFlag,
			N.STREETADDRESS		as StreetAddress,
			C. NAMEVARIANTNO	as NameVariantKey,
			NV.NAMEVARIANT		as NameVariant,
			NT.NAMETYPE		AS NameTypeKey,
			C.NAMETYPE+'^'+CAST(C.NAMENO as nvarchar(11))+'^'+CAST(C.SEQUENCE as nvarchar(10)) 
						as RowKey,
			C.SEQUENCE		as SequenceNo,
			C.LOGDATETIMESTAMP	as LastModifiedDate
				
			
		FROM	RELATEDCASE RC
		JOIN  	CASENAME C	on (C.CASEID    = RC.RELATEDCASEID
					and C.NAMETYPE  = 'O')  
		JOIN	NAME N		on (N.NAMENO    = C.NAMENO)
		JOIN  	NAMETYPE NT	on (NT.NAMETYPE = C.NAMETYPE ) 
		LEFT JOIN CASENAME CN	on (CN.CASEID   = @pnCaseKey
					and CN.NAMETYPE = C.NAMETYPE
					and CN.NAMENO   = N.NAMENO)
		LEFT JOIN ADDRESS A	on (A.ADDRESSCODE=C.ADDRESSCODE)
		LEFT JOIN COUNTRY CT	on (CT.COUNTRYCODE=A.COUNTRYCODE)
		LEFT JOIN STATE ST	on (ST.COUNTRYCODE=A.COUNTRYCODE
					and ST.STATE=A.STATE)
		LEFT JOIN NAMEVARIANT NV on (C. NAMEVARIANTNO = NV.NAMEVARIANTNO) 
		WHERE	RC.CASEID = @pnCaseKey
		and	RC.RELATIONSHIP='ASG'
		and	CN.CASEID is NULL
		AND 	isnull(C.ADDRESSCODE ,-9999999)
				      = isnull((SELECT	MAX(CN1.ADDRESSCODE)  				
						FROM 	RELATEDCASE RC1
						JOIN	CASENAME CN1	on (CN1.CASEID  =RC1.RELATEDCASEID 
									and CN1.NAMETYPE=C.NAMETYPE
									and CN1.NAMENO  =C.NAMENO
									and CN1.ADDRESSCODE is not null)
						WHERE 	RC1.CASEID = @pnCaseKey
						AND	RC1.RELATIONSHIP='ASG'), -9999999)
		ORDER BY 3"
			
			
	End
	Else
	Begin
		Set @sSQLString = "SELECT 
			C.CASEID		as CaseKey,
			0			as IsRelated,
			C.NAMENO		as NameKey,
			N.NAMECODE		as NameCode,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) 
						as DisplayName,
			C.ADDRESSCODE		as AddressKey,
			dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, ST.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
						as Address,
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
		JOIN	NAME N		on (C.NAMENO = N.NAMENO)
		JOIN	NAMETYPE NT	on (NT.NAMETYPE = C.NAMETYPE)
		LEFT JOIN ADDRESS A	on (A.ADDRESSCODE=C.ADDRESSCODE)
		LEFT JOIN COUNTRY CT	on (CT.COUNTRYCODE=A.COUNTRYCODE)
		LEFT JOIN STATE ST	on (ST.COUNTRYCODE=A.COUNTRYCODE
					and ST.STATE=A.STATE)
		LEFT JOIN NAMEVARIANT NV on (C. NAMEVARIANTNO = NV.NAMEVARIANTNO)
		WHERE	C.CASEID = @pnCaseKey
		and	C.NAMETYPE = 'O'
		AND 	isnull(C.ADDRESSCODE ,-9999999)
				      = isnull((SELECT	MAX(CN1.ADDRESSCODE)  				
						FROM  CASENAME CN1	
						WHERE CN1.CASEID  =C.CASEID 
						and   CN1.NAMETYPE=C.NAMETYPE
						and   CN1.NAMENO  =C.NAMENO
						and   CN1.ADDRESSCODE is not null), -9999999)
		ORDER BY 3"
	End

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

Grant execute on dbo.csw_ListAssignors to public
GO