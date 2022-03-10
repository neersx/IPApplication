-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseNameContactDetails									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseNameContactDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseNameContactDetails.'
	Drop procedure [dbo].[csw_ListCaseNameContactDetails]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseNameContactDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListCaseNameContactDetails
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int, 		-- Mandatory
	@psNameType		nvarchar(3)	= null
)
as
-- PROCEDURE:	csw_ListCaseNameContactDetails
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the CRMCaseStatusHistory business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 14 Jul 2008	AT	RFC5749	1	Procedure created
-- 13 Feb 2009	PA	RFC6843	2	Modified to get the lead with the first sequence number.
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @nWebPageTelecomType int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		select @nWebPageTelecomType = isnull(COLINTEGER,1905)
		from SITECONTROL 
		where UPPER(CONTROLID) = 'TELECOM TYPE - HOME PAGE'"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nWebPageTelecomType	int output',
			@nWebPageTelecomType = @nWebPageTelecomType output
End

If @nErrorCode = 0
Begin

	Set @sSQLString = "
		select 
		cast(CN.CASEID as nvarchar(13)) + '^' + cast(CN.NAMENO as nvarchar(13)) + '^' + CN.NAMETYPE as 'RowKey',
		CN.CASEID as 'CaseKey',
		CN.NAMENO as 'NameKey',
		CN.NAMETYPE as 'NameTypeKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL) as 'Name',
		dbo.fn_GetFormattedAddress(N.POSTALADDRESS, @psCulture, null, null, 0) as 'Address',
		dbo.fn_FormatTelecom(1901, TPH.ISD, TPH.AREACODE, TPH.TELECOMNUMBER, TPH.EXTENSION) as 'MainPhone',
		dbo.fn_FormatTelecom(1902, TPF.ISD, TPF.AREACODE, TPF.TELECOMNUMBER, TPF.EXTENSION) as 'MainFax',
		dbo.fn_FormatTelecom(1903, TPE.ISD, TPE.AREACODE, TPE.TELECOMNUMBER, TPE.EXTENSION) as 'MainEmail',
		dbo.fn_FormatTelecom(TPW.TELECOMTYPE, TPW.ISD, TPW.AREACODE, TPW.TELECOMNUMBER, TPW.EXTENSION) as 'HomePage'
		from CASENAME CN
		join NAME N on (N.NAMENO = CN.NAMENO)
		left join TELECOMMUNICATION TPH on (TPH.TELECODE = N.MAINPHONE
						and TPH.TELECOMTYPE = 1901)
		left join TELECOMMUNICATION TPF on (TPF.TELECODE = N.FAX
						and TPF.TELECOMTYPE = 1902)
		left join TELECOMMUNICATION TPE on (TPE.TELECODE = N.MAINEMAIL
						and TPE.TELECOMTYPE = 1903)
		-- Since we don't know the main website, pick the first one
		left join (SELECT NT.NAMENO, MIN(NT.TELECODE) as 'TELECODE' FROM 
				NAMETELECOM NT LEFT JOIN TELECOMMUNICATION T ON T.TELECODE = NT.TELECODE
				WHERE T.TELECOMTYPE = @nWebPageTelecomType
				GROUP BY NT.NAMENO) as WEB on (WEB.NAMENO = CN.NAMENO)
		left join TELECOMMUNICATION TPW on (TPW.TELECODE = WEB.TELECODE)
		Join (SELECT MIN(SEQUENCE) SEQUENCE, CASEID, NAMETYPE FROM CASENAME
				GROUP BY CASEID, NAMETYPE) AS CN2 ON(CN2.CASEID = CN.CASEID
				AND CN2.NAMETYPE = CN.NAMETYPE
				AND CN2.SEQUENCE = CN.SEQUENCE)		
		where CN.CASEID = @pnCaseKey
		"

		if (@psNameType is not null)
		Begin
			Set @sSQLString = @sSQLString + "
				and upper(CN.NAMETYPE) = upper(@psNameType)"
		End

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@psCulture		nvarchar(10),
			@pnCaseKey		int,
			@psNameType		nvarchar(3),
			@nWebPageTelecomType	int',
			@psCulture		= @psCulture,
			@pnCaseKey		= @pnCaseKey,
			@psNameType		= @psNameType,
			@nWebPageTelecomType	= @nWebPageTelecomType
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseNameContactDetails to public
GO