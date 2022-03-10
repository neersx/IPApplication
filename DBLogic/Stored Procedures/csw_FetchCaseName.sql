-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchCaseName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchCaseName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchCaseName.'
	Drop procedure [dbo].[csw_FetchCaseName]
End
Print '**** Creating Stored Procedure dbo.csw_FetchCaseName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_FetchCaseName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int 		-- Mandatory
)
as
-- PROCEDURE:	csw_FetchCaseName
-- VERSION:	15
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the CaseName business entity.

--	NOTE: if any changes are made to this stored procedure, check whether
--	corresponding changes are required to csw_FetchDefaultCaseName.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 15 Nov 2005	TM	RFC3202	1	Procedure created
-- 09 Nov 2005	TM	RFC3202	2	Add name codes for use by pick lists.
-- 03 May 2006	SW	RFC3202 3	Implement new properties 
-- 03 May 2006	AU	RFC3202 4	Added RestrictionActionKey and Restriction to results
-- 11 May 2006	JEK	RFC3840	5	Added Comment
-- 30 May 2006	IB	RFC3299	6	Do not return information regarding derived attention names.
-- 18 Jul 2008	AT	RFC5749	7	Return Remarks.
-- 28 Aug 2008	AT	RFC5712	8	Return Correspondence Sent/Received.
-- 30 Nov 2009	ASH	RFC8608	9	Added new column 'DefaultAddressKey'.
-- 28 Oct 2010	ASH	RFC9851	10	Change logic to get AttentionNameKey .
-- 23 Jun 2011	LP	RFC10896 11	DefaultAddressKey should be the Postal Address.
--					Always return the ADDRESSCODE against the CASENAME.
--					If CASENAME.ADDRESSCODE is null, then return the POSTALADDRESS for the NAME.
-- 24 Oct 2011	ASH	R11460 	12	Cast integer column CaseId to nvarchar(11) data type.
-- 13 Aug 2012  DV	RFC12600 	13	Return LOGDATETIMESTAMP column

-- 21 Oct 2011  MS      R11438  12      Pass Namestyle in fn_FormatName call
-- 13 Aug 2012  DV	R12600  13	Return LOGDATETIMESTAMP column
-- 04 Oct 2013  MS      DR1390  14      Revert RFC11438 changes, pass namestyle as null in fn_FormatName call
-- 04 Nov 2015	KR	R53910	15	Adjust formatted names logic (DR-15543)


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select
	CAST(C.CASEID as nvarchar(11))+'^'+
	C.NAMETYPE+'^'+
	CAST(C.NAMENO as nvarchar(11))+'^'+
	CAST(C.SEQUENCE	as nvarchar(10))
				as RowKey,
	C.CASEID		as CaseKey,
	C.NAMETYPE		as NameTypeCode,
	"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
				+ " as NameTypeDescription,
	C.NAMENO		as NameKey,
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
				as FormattedName,
	N.NAMECODE		as NameCode,
	C.SEQUENCE		as Sequence,
	CASE WHEN C.DERIVEDCORRNAME=1 THEN C.CORRESPONDNAME ELSE N1.NAMENO END as AttentionNameKey, 
	dbo.fn_FormatNameUsingNameNo(N1.NAMENO, null)
				as AttentionNameFormatted, 
	N1.NAMECODE		as AttentionNameCode,
	N.POSTALADDRESS		as DefaultAddressKey,
	C.ADDRESSCODE		as AddressKey,
	dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)
				as AddressFormatted,
	C.REFERENCENO		as ReferenceNo,
	C.ASSIGNMENTDATE	as AssignmentDate,
	C.COMMENCEDATE		as DateCommenced,
	C.EXPIRYDATE		as DateCeased,
	C.BILLPERCENTAGE	as BillPercent,
	C.INHERITED		as IsInherited,
	C.INHERITEDNAMENO	as InheritedNameKey,
	C.INHERITEDRELATIONS 	as InheritedRelationshipCode,
	C.INHERITEDSEQUENCE	as InheritedSequence,
	C.NAMEVARIANTNO		as NameVariantKey,
	dbo.fn_FormatNameUsingNameNo(N2.NAMEVARIANTNO, null)
				as FormattedNameVariant,
	DS.ACTIONFLAG		as RestrictionActionKey,
	"+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura)
				+ " as Restriction,
	C.REMARKS		as Remarks,
	C.CORRESPSENT		as CorrespSent,
	C.CORRESPRECEIVED	as CorrespReceived,
	C.LOGDATETIMESTAMP	as LastModifiedDate	
	from CASENAME C
	join NAME N 		on (N.NAMENO = C.NAMENO)
	join NAMETYPE NT 	on (NT.NAMETYPE = C.NAMETYPE)
	left join NAME N1	on (N1.NAMENO = C.CORRESPONDNAME
				and C.DERIVEDCORRNAME = 0)		
	left join ADDRESS A	on (A.ADDRESSCODE = ISNULL(C.ADDRESSCODE, N.POSTALADDRESS))
	left join COUNTRY CT	on (CT.COUNTRYCODE = A.COUNTRYCODE)
	left join STATE S	on (S.COUNTRYCODE = A.COUNTRYCODE
				and S.STATE = A.STATE)
	left join NAMEVARIANT N2
				on (N2.NAMEVARIANTNO = C.NAMEVARIANTNO)
	left join IPNAME IP	on (IP.NAMENO = N.NAMENO)
	left join DEBTORSTATUS DS
				on (DS.BADDEBTOR = IP.BADDEBTOR)
	where C.CASEID = @pnCaseKey
	order by CaseKey, NameTypeDescription, NameTypeCode, Sequence"

	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnCaseKey	int',
			@pnCaseKey	 = @pnCaseKey

End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchCaseName to public
GO