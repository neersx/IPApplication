-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListTableAttributes 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListTableAttributes ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListTableAttributes .'
	Drop procedure [dbo].[ipw_ListTableAttributes ]
	Print '**** Creating Stored Procedure dbo.ipw_ListTableAttributes ...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListTableAttributes 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psParentTable 		nvarchar(50),	-- Mandatory
	@psGenericKey 		nvarchar(20)	= null,
	@pbIsExternalUser 	bit,		-- Mandatory 		--(for future use)
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListTableAttributes 
-- VERSION:	6
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Generalised stored procedure to populate attributes 
--		for a parent structure (Case/Name/Country).  

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 03 Sep 2004  TM	RFC1158	1	Procedure created
-- 10 Sep 2004	TM	RFC1158	2	Make the @pbIsExternalUser parameter mandatory.
-- 15 Sep 2004	JEK	RFC886	3	Implement translation.
-- 15 May 2005	JEK	RFC2508	4	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 27 Jun 2006	SW	RFC4038	5	Add rowkey
-- 15 Apr 2013	DV	R13270	6	Increase the length of nvarchar to 11 when casting or declaring integer


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

	
-- Populating Attribute result set
If @nErrorCode = 0
Begin	
	Set @sSQLString = 
	"Select " +
		"  cast(T.GENERICKEY as nvarchar(11)) + '^' " +CHAR(10)+
		"+ cast(T.TABLECODE as nvarchar(11))	as RowKey," +CHAR(10)+
		CASE WHEN @psParentTable = 'NAME'
		     THEN "CAST(@psGenericKey as int) 	as 'NameKey',"
		     WHEN @psParentTable = 'CASES'	
		     THEN "CAST(@psGenericKey as int) 	as 'CaseKey',"
		     WHEN @psParentTable = 'COUNTRY'	
		     THEN "@psGenericKey 	 	as 'CountryKey',"
		END +CHAR(10)+
		dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'TY',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'AttributeType',
		CASE WHEN TY.DATABASETABLE = 'OFFICE'
		     THEN "+dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,@pbCalledFromCentura)+"
		     ELSE "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'A',@sLookupCulture,@pbCalledFromCentura)+"
		END					as 'AttributeDescription'
	from TABLEATTRIBUTES T
	join TABLETYPE TY 	on (TY.TABLETYPE = T.TABLETYPE)
	left join TABLECODES A 	on (A.TABLECODE = T.TABLECODE)
	left join OFFICE O	on (O.OFFICEID = T.TABLECODE)
	where 	T.PARENTTABLE = @psParentTable
	and	T.GENERICKEY  = @psGenericKey
	order by TY.TABLENAME, 'AttributeDescription'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psParentTable 	nvarchar(50),
					  @psGenericKey		nvarchar(20)',
					  @psGenericKey		= @psGenericKey,
					  @psParentTable 	= @psParentTable
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListTableAttributes  to public
GO
