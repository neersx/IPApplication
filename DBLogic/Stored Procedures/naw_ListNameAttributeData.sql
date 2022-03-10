-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameAttributeData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameAttributeData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameAttributeData.'
	Drop procedure [dbo].[naw_ListNameAttributeData]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameAttributeData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListNameAttributeData
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int	
)
as
-- PROCEDURE:	naw_ListNameAttributeData
-- VERSION:	8
-- DESCRIPTION:	Populates the NameAttributeData dataset 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Oct 2004	TM	RFC1814	1	Procedure created.
-- 11 Oct 2004	TM	RFC1814	2	Use Office table to retrive an AttributeDescription if  
--					TABLETYPE.DATABASETABLE = 'OFFICE'.
-- 12 Oct 2004	TM	RFC1814	3	Exclude any rows with a null AttributeKey in the AttributeValue result set.
-- 21 Feb 2004	TM	RFC2344	4	Correct the Name.UsedAsFlag filtering logic.
-- 09 Mar 2006	TM	RFC3651	5	Cast an integer variable or column as nvarchar(20) before comparing it to 
--					the TABLEATTRIBUTES.GENERICKEY column.
-- 16 Nov 2006  PG	RFC4341 6	Remove AttributeType and AttributeValue tables. Return RowKey with NameAttribute
-- 11 Apr 2013	DV	R13270	7	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	8	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Populating Name result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  @pnNameKey 	as NameKey,
		dbo.fn_FormatNameUsingNameNo(@pnNameKey, NULL)	as Name"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey	int',
					  @pnNameKey	= @pnNameKey

End

-- Populating NameAttribute result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  CAST(@pnNameKey as nvarchar(11))+
	'^'+CAST(T.TABLECODE as nvarchar(11)) as RowKey,
		@pnNameKey 	as NameKey,
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
	where T.GENERICKEY  = cast(@pnNameKey as nvarchar(20))
	and   T.PARENTTABLE='NAME'
	Order by AttributeType, AttributeDescription"		    

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameAttributeData to public
GO
