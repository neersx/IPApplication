-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ac_ListEntities
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_ListEntities]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_ListEntities.'
	Drop procedure [dbo].[ac_ListEntities]
End
Print '**** Creating Stored Procedure dbo.ac_ListEntities...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ac_ListEntities
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbForPosting 		bit 		= 0
)
AS
-- PROCEDURE:	ac_ListEntities
-- VERSION:	10
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Entities.
-- COPYRIGHT:Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 07 Apr 2005  TM	RFC1896	1	Procedure created
-- 23 Jun 2005	TM	RFC2556	2	Implement the Automatic WIP Entity site control and new @pbForPosting bit 
--					parameter.
-- 29 Jun 2005	TM	RFC2556	3	There is no need to look up the site control unless @pbForPosting=1.
-- 29 Oct 2008	PA	RFC5866	4	To check the DEFAULTENTITYNO from EMPLOYEE table and add the condition in CASE.
-- 09 Dec 2008	MF	17136	5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 05 Dec 2011	LP	R11070	6	Default entity to Office entity if available for the staff.
-- 07 Mar 2012	LP	R12034	7	Only set default to DEFAULTWIPENTITYNO when @pbForPosting = 1, i.e. for Timesheet posting only.
-- 30 Mar 2012	LP	R11070  8	Office-level defaulting only occurs when there are offices with Entity Organisations.
-- 14 Jan 2014  SW      R27722  9       Return Entity Currency
-- 02 Nov 2015	vql	R53910	10	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @bIsMainEntity	bit
Declare @nOfficeNameNo	int
declare	@nOfficeEntityCount	int

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set 	@bIsMainEntity	 = 0


-- Should the WIP be automatically created against the main Entity of the firm?
If @nErrorCode = 0
and @pbForPosting = 1
Begin	
	Set @sSQLString = "
	Select @bIsMainEntity = COLBOOLEAN
	from SITECONTROL 
	where CONTROLID = 'Automatic WIP Entity'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@bIsMainEntity	bit			output',
				   	  @bIsMainEntity	= @bIsMainEntity	output
End

If @nErrorCode = 0
Begin
	SELECT @nOfficeEntityCount = COUNT(DISTINCT OX.ORGNAMENO) 
	from OFFICE OX 
	join TABLEATTRIBUTES TX on (OX.OFFICEID = TX.TABLECODE)
	join USERIDENTITY UX on (UX.NAMENO = TX.GENERICKEY)
	join SPECIALNAME SN on (SN.NAMENO = OX.ORGNAMENO)
	where TX.PARENTTABLE = 'NAME' 
	and TX.TABLETYPE = 44 
	and UX.IDENTITYID = @pnUserIdentityId
	and OX.ORGNAMENO IS NOT NULL
	and SN.ENTITYFLAG = 1
	-- RFC11071: Retrieve the ENTITYNO against the Office of the Case	
	-- Assumes that ORGNAMENO is an Entity (SPECIALNAME.ENTITYFLAG = 1)			  
	
	If @nOfficeEntityCount = 1
	Begin
		Set @sSQLString="Select @nOfficeNameNo = O.ORGNAMENO
		from OFFICE O
		join TABLEATTRIBUTES T on (T.TABLECODE = O.OFFICEID)
		join USERIDENTITY U on (U.NAMENO = T.GENERICKEY)
		where T.PARENTTABLE = 'NAME'
		and T.TABLETYPE = 44
		and U.IDENTITYID = @pnUserIdentityId
		and O.ORGNAMENO IS NOT NULL"		
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nOfficeNameNo	int		OUTPUT,
				  @pnUserIdentityId	int		',
				  @nOfficeNameNo 	=@nOfficeNameNo	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId	
	End
	Else If @nOfficeEntityCount = 0
	Begin
		Set @sSQLString="Select @nOfficeNameNo = SC.COLINTEGER
		from SITECONTROL SC
		where SC.CONTROLID = 'HOMENAMENO'"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@nOfficeNameNo	int		OUTPUT',
				  @nOfficeNameNo 	=@nOfficeNameNo	OUTPUT	
	End
	
	
End

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	N.NAMENO	as 'EntityKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
				as 'EntityName',
		CASE WHEN(E.DEFAULTENTITYNO is not null and @pbForPosting = 1)
			THEN CASE WHEN(E.DEFAULTENTITYNO=N.NAMENO) THEN CAST(1 as bit) ELSE CAST(0 as bit) END
			ELSE CASE WHEN(ISNULL(@nOfficeNameNo,SC.COLINTEGER)=N.NAMENO)     THEN CAST(1 as bit) ELSE CAST(0 as bit) END
		END		as 'IsDefault',
		A.COUNTRYCODE   as 'CountryCode',
		C.COUNTRY	as 'CountryName',
		SN.CURRENCY     as 'EntityCurrency'		
	from NAME N
	join SPECIALNAME SN      on (SN.NAMENO = N.NAMENO and SN.ENTITYFLAG = 1)
	join USERIDENTITY UI     on (UI.IDENTITYID = @pnUserIdentityId)
	left join SITECONTROL SC on (SC.CONTROLID = 'HOMENAMENO')
	left join EMPLOYEE E     on (E.EMPLOYEENO = UI.NAMENO)
	left join ADDRESS A	on (ISNULL(N.POSTALADDRESS, N.STREETADDRESS) = A.ADDRESSCODE)
	left join COUNTRY C	on (A.COUNTRYCODE = C.COUNTRYCODE)"+char(10)+
	CASE 	WHEN @pbForPosting = 1 and @bIsMainEntity = 1
		-- Return only the best default Entity
		THEN "where N.NAMENO = coalesce(E.DEFAULTENTITYNO,@nOfficeNameNo,SC.COLINTEGER)"
	END+char(10)+
	"order by 'EntityName'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @nOfficeNameNo	int,
					  @pbForPosting		bit',
		 			  @pnUserIdentityId	= @pnUserIdentityId,
		 			  @nOfficeNameNo	= @nOfficeNameNo,
		 			  @pbForPosting		= @pbForPosting
	
	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.ac_ListEntities to public
GO
