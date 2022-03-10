-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseHeader
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseHeader]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseHeader.'
	Drop procedure [dbo].[csw_ListCaseHeader]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseHeader...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseHeader
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	csw_ListCaseHeader
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates the CaseHeaderData dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Dec 2005	TM	RFC3255	1	Procedure created
-- 15 Dec 2005	TM	RFC3255	2	Implement Julie's feedback.
-- 30 Jan 2009	SF	RFC6693	3	Implement IsGlobalNameChangeOutstanding
-- 05 Mar 2010	SF	RFC6547	4	Execute WITH (NOLOCK)
-- 20 Oct 2011   DV     	 R11439  	5           Modify the join for Valid Property, Category, Basis and Sub Type  
-- 24 Oct 2011	ASH	R11460 	6	Cast integer columns as nvarchar(11) data type.
-- 26 May 2016  MS      R54074  7       Added Case Row Access security check and filterUserCases check
-- 07 Sep 2018	AV	74738	8	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare @nFilterCaseKey int
declare @bHasAccessSecurity bit
declare @sAlertXML nvarchar(max)
declare @bIsExternalUser bit

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Security check
If @nErrorCode = 0
Begin
        Set @sSQLString = "Select @bIsExternalUser = ISEXTERNALUSER FROM USERIDENTITY where IDENTITYID = @pnUserIdentityId"
        exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser		bit     output,
				  @pnUserIdentityId	        int',
				  @bIsExternalUser		= @bIsExternalUser      output,
				  @pnUserIdentityId             = @pnUserIdentityId
End

If @nErrorCode = 0
Begin
        if @bIsExternalUser = 1
        Begin  
                -- use max(CASEID) so that null is returned if no row is found
	        Set @sSQLString = "
		        Select	@nFilterCaseKey		= MAX(CASEID) 		
		        from	dbo.fn_FilterUserCases(@pnUserIdentityId,1,@pnCaseKey) FC"

	        exec @nErrorCode=sp_executesql @sSQLString,
				        N'@pnUserIdentityId		int,
				          @pnCaseKey			int,
				          @nFilterCaseKey		int				OUTPUT',
				          @pnUserIdentityId		= @pnUserIdentityId,
				          @pnCaseKey			= @pnCaseKey,
				          @nFilterCaseKey		= @nFilterCaseKey		OUTPUT

                If @nErrorCode = 0 and @nFilterCaseKey = @pnCaseKey
                Begin
                        Select @bHasAccessSecurity = 1
                End
        End
        Else
        Begin
                Select @bHasAccessSecurity = SECURITYFLAG & 1
                from dbo.fn_FilterRowAccessCases(@pnUserIdentityId) 
                where CASEID = @pnCaseKey
        End
	
End

If @nErrorCode = 0 and ISNULL(@bHasAccessSecurity,0) = 0 
Begin
        Set @sAlertXML = dbo.fn_GetAlertXML('SF59', 'You do not have the necessary permissions to access this information.  Please contact your system administrator.', null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR       
End

-- Case result set
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  C.CASEID	as CaseKey,	
		C.IRN 		as CaseReference,
		CASE 	WHEN P.CASEID is not null
			THEN cast(1 as bit)
			ELSE cast(0 as bit)
		END		as IsPolicingOutstanding,
		CASE 	WHEN GNC.CASEID is not null
			THEN cast(1 as bit)
			ELSE cast(0 as bit)
		END		as IsGlobalNameChangeOutstanding,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'CC',@sLookupCulture,@pbCalledFromCentura)
			     +" as CountryAdjective,
		"+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)
			     +" as PropertyTypeDescription,
		"+dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CS',@sLookupCulture,@pbCalledFromCentura)
			     +" as CaseTypeDescription,
		"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)
			     +" as CaseStatusDescription
	from CASES C WITH (NOLOCK)"+char(10)+
	-- IsPolicingOutstanding is true if there is a row in 
	-- the POLICING table for the CaseKey where SYSGENERATEDFLAG = 1:
	"left join (	Select distinct P2.CASEID
		      	from POLICING P2 WITH (NOLOCK)
			where P2.CASEID = @pnCaseKey
			and   P2.SYSGENERATEDFLAG = 1) P
					on (P.CASEID = C.CASEID)"+char(10)+
	-- IsGlobalNameChangeOutstanding is true if there is a row in 
	-- the CASENAMEREQUESTCASES table for the CaseKey
	"left join ( Select distinct CNREQ.CASEID
				from CASENAMEREQUESTCASES CNREQ	WITH (NOLOCK)
				where CNREQ.CASEID      = @pnCaseKey) GNC 
					on (GNC.CASEID = C.CASEID)
	left join COUNTRY CC		on (CC.COUNTRYCODE = C.COUNTRYCODE)
	left join VALIDPROPERTY VP 	on (VP.PROPERTYTYPE = C.PROPERTYTYPE
					and VP.COUNTRYCODE = (	select min(VP1.COUNTRYCODE)
								from VALIDPROPERTY VP1
								where VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))

	left join CASETYPE CS 		on (CS.CASETYPE = C.CASETYPE)
	left join STATUS ST 		on (ST.STATUSCODE = C.STATUSCODE)
	where C.CASEID = @pnCaseKey"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey	int',
			          @pnCaseKey	= @pnCaseKey
	
End

-- OfficialNumbers result set
If @nErrorCode = 0
Begin
	Set @sSQLString = "  
		Select  CAST(O.CASEID as nvarchar(11))+'^'+
			O.OFFICIALNUMBER+'^'+
			O.NUMBERTYPE		as RowKey,
			O.CASEID		as CaseKey,
			O.OFFICIALNUMBER 	as OfficialNumber,	
			"+dbo.fn_SqlTranslatedColumn('NUMBERTYPES','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)+"	
					  	as NumberTypeDescription,	
			CE.EVENTDATE		as EventDate		
		from OFFICIALNUMBERS O
		join NUMBERTYPES NT		on (NT.NUMBERTYPE = O.NUMBERTYPE)
		left join CASEEVENT CE		on (CE.EVENTNO = NT.RELATEDEVENTNO
						and CE.CASEID = O.CASEID
						and CE.CYCLE = 1)
		where O.CASEID = @pnCaseKey
		and   NT.ISSUEDBYIPOFFICE = 1
		and   O.ISCURRENT = 1
		order by NT.DISPLAYPRIORITY DESC, NumberTypeDescription, O.ISCURRENT DESC, OfficialNumber"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int',
					  @pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseHeader to public
GO
