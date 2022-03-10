-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListDesignElement 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListDesignElement]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListDesignElement.'
	Drop procedure [dbo].[csw_ListDesignElement]
	Print '**** Creating Stored Procedure dbo.csw_ListDesignElement...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListDesignElement 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,		-- if @pnCaseKey is null return an empty result set
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	csw_ListDesignElement 
-- VERSION:	9
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates Design Element datatable.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 18 Oct 2004  TM	RFC1156	1	Procedure created
-- 04 Nov 2004	TM	RFC1156	2	Fix IsRenewable column name.
-- 29 Nov 2004	TM	RFC1156	3	Capitalisation of column names does not match dataset. Add FirmElementID 
--					column to the '...@pnCaseKey is null' dataset.
-- 15 May 2005	JEK	RFC2508	4	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 27 Jun 2006	SW	RFC4038	5	Add rowkey
-- 21 Jun 2011  DV      RFC4086 6       Return IsImageAssociated, Sequencekey and LOGDATETIMESTAMP column
-- 27 Sep 2011  DV      RFC4086 7       Add distinct in the select statement.
-- 24 Oct 2011	ASH	R11460  8	Cast integer columns as nvarchar(11) data type.
-- 30 Aug 2017	MF	72278	9	Duplicate design elements were being return when multiple images are attached.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

	
-- Populating Design Element datatable
If @nErrorCode = 0
and @pnCaseKey is not null
Begin	
	Set @sSQLString = "
	Select  cast(D.CASEID as nvarchar(11)) + '^' 
		+ cast(D.[SEQUENCE] as nvarchar(10))
					as RowKey,
		D.CASEID		as CaseKey,
		D.SEQUENCE              as Sequencekey,
		D.FIRMELEMENTID		as FirmElementID,
		"+dbo.fn_SqlTranslatedColumn('DESIGNELEMENT','ELEMENTDESC',null,'D',@sLookupCulture,@pbCalledFromCentura)
				    + " as ElementDescription,
		D.CLIENTELEMENTID	as ClientElementID,
		D.TYPEFACE		as TypeFace,
		D.OFFICIALELEMENTID	as OfficialElementID,
		D.REGISTRATIONNO	as RegistrationNo,
		CAST(D.RENEWFLAG as bit)
					as IsRenewable,
	        CAST(Case When CI.CASEID is null Then 0 Else 1 End as bit) as IsImageAssociated,
		D.LOGDATETIMESTAMP      as LastModifiedDate
	from  DESIGNELEMENT D 
	left join (select distinct CASEID, FIRMELEMENTID
		   from CASEIMAGE) CI	ON (CI.CASEID = D.CASEID 
					and CI.FIRMELEMENTID = D.FIRMELEMENTID)
	where D.CASEID = @pnCaseKey
	order by FirmElementID"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int',
					  @pnCaseKey		= @pnCaseKey
	Set @pnRowCount = @@Rowcount
End
Else
If @nErrorCode = 0
and @pnCaseKey is null
Begin
	Select  null	as RowKey,
		null	as CaseKey,
		null	as FirmElementID,
		null	as ElementDescription,
		null	as ClientElementID,
		null	as TypeFace,
		null	as OfficialElementID,
		null	as RegistrationNo,
		null	as IsRenewvable,
		null    as IsImageAssociated,
		null    as LastModifiedDate
	where 1=0	

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListDesignElement to public
GO
