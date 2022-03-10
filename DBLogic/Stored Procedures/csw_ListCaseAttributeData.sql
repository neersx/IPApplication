-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseAttributeData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseAttributeData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseAttributeData.'
	Drop procedure [dbo].[csw_ListCaseAttributeData]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseAttributeData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseAttributeData
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	csw_ListCaseAttributeData
-- VERSION:	3
-- DESCRIPTION:	Populates the CaseAttributeData dataset 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Sep 2008	AT	RFC5750	1	Procedure created from naw_ListNameAttributeData.
-- 04 Nov 2011	ASH	R11460	2	 Cast integer columns as nvarchar(11) data type.   
-- 15 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
Declare @sParentTable	nvarchar(101)

-- Initialise variables
Set @nErrorCode = 0

/*
If @nErrorCode = 0
Begin
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
End
*/

-- Populating Case result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  @pnCaseKey 	as CaseKey,
		C.IRN
	from CASES C	
	where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey	int',
					  @pnCaseKey	= @pnCaseKey

End

-- Populating CaseAttribute result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  CAST(@pnCaseKey as nvarchar(11))+
	'^'+CAST(T.TABLECODE as nvarchar(11)) as RowKey,
		@pnCaseKey 	as CaseKey,
		T.TABLECODE	as AttributeKey,
		T.TABLETYPE	as AttributeTypeKey,
		TY.TABLENAME	as AttributeType,	
		CASE WHEN TY.DATABASETABLE = 'OFFICE'
		     THEN O.DESCRIPTION
		     ELSE A.DESCRIPTION
		END		as AttributeDescription 		
	from TABLEATTRIBUTES T
	join TABLETYPE TY 	on (TY.TABLETYPE = T.TABLETYPE)
	left join TABLECODES A 	on (A.TABLECODE = T.TABLECODE)
	left join OFFICE O	on (O.OFFICEID = T.TABLECODE)
	where T.GENERICKEY  = cast(@pnCaseKey as nvarchar(20))
	and   T.PARENTTABLE = 'CASES'
	Order by AttributeType, AttributeDescription"		    

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int',
					  @pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseAttributeData to public
GO