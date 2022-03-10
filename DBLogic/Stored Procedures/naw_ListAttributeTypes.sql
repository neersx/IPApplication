-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListAttributeTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListAttributeTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListAttributeTypes.'
	Drop procedure [dbo].[naw_ListAttributeTypes]
	Print '**** Creating Stored Procedure dbo.naw_ListAttributeTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListAttributeTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int		= null,
	@pbIsLead		bit     = 0
)
AS
-- PROCEDURE:	naw_ListAttributeTypes
-- VERSION:	9
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns AttributeTypeKey, AttributeTypeDescription from the TABLETYPE table
--		for the INDIVIDUAL,EMPLOYEE and ORGANISATION parent tables.  

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Dec-2003	TM	RFC611	1	Procedure created
-- 15 Sep 2004	JEK	RFC886	2	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 16 Nov 2006  PG	RFC4341 4	Add filter by @pnNameKey
-- 18 Jul 2008  LP      RFC5754 5       Add NAME/LEAD selection type.
--                                      Add logic to check if Name is a CRM Lead.
-- 30 Apr 2009	AT	RFC7869	6	Fix Lead check logic.
-- 17 Sep 2009	DV	RFC8016	7	Return 2 more columns ParentTable and RowKey 
-- 07 Oct 2009	DV	RFC8506	8	Modify logic to get attributes for individual only if they don't exist 
--								in Name/Lead. Also add an extra parameter @pbIsLead
-- 10 Nov 2010	DV	RFC100420 9 Remove the RowKey and ParentTable from the select condition


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(1000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0


If @nErrorCode = 0
Begin	
	If @pnNameKey is null and @pbIsLead = 0
	Begin
		Set @sSQLString = "
		select distinct T.TABLETYPE	as 'AttributeTypeKey',		
				"+dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'T',@sLookupCulture,@pbCalledFromCentura)
					+ " as 'AttributeTypeDescription'
		from TABLETYPE T
		join SELECTIONTYPES S on S.TABLETYPE = T.TABLETYPE 
		where S.PARENTTABLE in ('INDIVIDUAL','EMPLOYEE','ORGANISATION','NAME/LEAD') 
		order by AttributeTypeDescription"
			
		exec @nErrorCode = sp_executesql @sSQLString
	
		Set @pnRowCount = @@Rowcount
	End
	Else
	Begin
	        -- Check if Name is a Lead
	        If Exists (Select 1 from NAME N
				join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO = N.NAMENO and NTC.NAMETYPE = '~LD')
				where N.NAMENO = @pnNameKey
				AND NTC.ALLOW = 1
	        ) or @pbIsLead = 1
	        Begin
	                Set @sSQLString = " 
		        Select  DISTINCT ST.TABLETYPE 		as AttributeTypeKey,
				Cast(ST.PARENTTABLE as nvarchar(40))+ '^'+ Cast(ST.TABLETYPE as nvarchar(10)) as RowKey,
			                TY.TABLENAME		as AttributeTypeDescription,
				ST.PARENTTABLE as ParentTable
		        from SELECTIONTYPES ST
		        join TABLETYPE TY 		on (TY.TABLETYPE = ST.TABLETYPE)
		        join SELECTIONTYPES ST1		on (ST.PARENTTABLE = ST1.PARENTTABLE 
				and ST1.PARENTTABLE =
					substring ((Select max(
									CASE WHEN ST2.PARENTTABLE = 'NAME/LEAD' THEN '1' ELSE '0' END +
									CASE WHEN ST2.PARENTTABLE = 'INDIVIDUAL' THEN '1' ELSE '0' END + 
									ST2.PARENTTABLE)
								from SELECTIONTYPES ST2	
								join TABLETYPE TY1 		on (TY1.TABLETYPE = ST2.TABLETYPE and TY1.TABLETYPE = TY.TABLETYPE)
								where ST2.PARENTTABLE in ('NAME/LEAD','INDIVIDUAL')), 3, 20))
		        Order by AttributeTypeDescription"
		End
		Else
		Begin
	                Set @sSQLString = " 
		        Select  ST.TABLETYPE 		as AttributeTypeKey,
				Cast(ST.PARENTTABLE as nvarchar(40))+ '^'+ Cast(ST.TABLETYPE as nvarchar(10)) as RowKey,
			        TY.TABLENAME		as AttributeTypeDescription,
				ST.PARENTTABLE as ParentTable
		        from SELECTIONTYPES ST
		        join TABLETYPE TY 		on (TY.TABLETYPE = ST.TABLETYPE)
		        join NAME N 			on (N.NAMENO = @pnNameKey)
		        where ST.PARENTTABLE =	CASE 	WHEN N.USEDASFLAG&2=2 THEN 'EMPLOYEE'
						        WHEN N.USEDASFLAG&1=1 THEN 'INDIVIDUAL'
						        ELSE 'ORGANISATION'
				      	        END
		        Order by AttributeTypeDescription"    
		        End
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameKey		int',
						  @pnNameKey		= @pnNameKey
		End
End


Return @nErrorCode
GO

Grant execute on dbo.naw_ListAttributeTypes to public
GO
