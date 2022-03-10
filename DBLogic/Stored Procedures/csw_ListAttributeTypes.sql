-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListAttributeTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListAttributeTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListAttributeTypes.'
	Drop procedure [dbo].[csw_ListAttributeTypes]
	Print '**** Creating Stored Procedure dbo.csw_ListAttributeTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListAttributeTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		= null
)
AS
-- PROCEDURE:	csw_ListAttributeTypes
-- VERSION:	5
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns AttributeTypeKey, AttributeTypeDescription from the TABLETYPE table
--		for the case.  

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Dec-2003	TM	RFC642	1	Procedure created
-- 14-Sep-2004	TM	RFC886	2	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 05-Sep-2008	AT	RFC5750	4	Filter SelectionTypes by CaseType/PropertyType
-- 22-Aug-2009	DV	RFC8016	5	Return 2 more columns ParentTable and RowKey 


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(500)
Declare @sLookupCulture	nvarchar(10)
Declare @sParentTable	nvarchar(101)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If (@nErrorCode = 0 and @pnCaseKey is not null)
Begin
	-- Return attributes for the case
	Set @sSQLString = "SELECT @sParentTable = UPPER(CT.CASETYPEDESC) + '/' + UPPER(ISNULL(VP.PROPERTYNAME,P.PROPERTYNAME))
				FROM CASES C
				JOIN CASETYPE CT ON CT.CASETYPE = C.CASETYPE
				JOIN PROPERTYTYPE P ON (P.PROPERTYTYPE = C.PROPERTYTYPE)
				LEFT JOIN VALIDPROPERTY VP ON (VP.PROPERTYTYPE = C.PROPERTYTYPE
								AND VP.COUNTRYCODE = C.COUNTRYCODE)
				WHERE C.CASEID = @pnCaseKey"


	exec @nErrorCode=sp_executesql @sSQLString,
					N'	@sParentTable	nvarchar(101) OUTPUT,
						@pnCaseKey	int',
						@sParentTable	= @sParentTable OUTPUT,
						@pnCaseKey	= @pnCaseKey

	If @nErrorCode = 0
	Begin	
		Set @sSQLString = "
		Select distinct T.TABLETYPE as AttributeTypeKey, 
		Cast(S.PARENTTABLE as nvarchar(40))+ '^'+ Cast(S.TABLETYPE as nvarchar(10)) as RowKey,
				"+dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'T',@sLookupCulture,@pbCalledFromCentura)
		                	 +" as AttributeTypeDescription,
		S.PARENTTABLE as ParentTable
		from SELECTIONTYPES S
		join TABLETYPE T on (T.TABLETYPE = S.TABLETYPE)
		where S.PARENTTABLE = @sParentTable
		order by AttributeTypeDescription"
		
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@sParentTable	nvarchar(101)',
				@sParentTable 	= @sParentTable
	
		Set @pnRowCount = @@Rowcount
	End

End
Else If (@nErrorCode = 0)
Begin	
	-- Just return the default attributes list
	Set @sSQLString = "
	Select distinct T.TABLETYPE as AttributeTypeKey, 
			"+dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'T',@sLookupCulture,@pbCalledFromCentura)
	                	 +" as AttributeTypeDescription
	from CASETYPE CT
	join SELECTIONTYPES S on (S.PARENTTABLE like upper(CT.CASETYPEDESC)+'/%')
	join TABLETYPE T      on (T.TABLETYPE = S.TABLETYPE)
	order by AttributeTypeDescription"
	
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.csw_ListAttributeTypes to public
GO
