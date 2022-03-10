-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchNameTypeClassification									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].naw_FetchNameTypeClassification') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchNameTypeClassification.'
	Drop procedure [dbo].naw_FetchNameTypeClassification
End
Print '**** Creating Stored Procedure dbo.naw_FetchNameTypeClassification...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchNameTypeClassification
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int 		= null,
	@pnUsedAsFlag		int		= null -- Only applicable for new names
)
as
-- PROCEDURE:	naw_FetchNameTypeClassification
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the NameType business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 10 Jun 2008	LP	R4342	1	Procedure created
-- 19 Dec 2008	AT	R7414	2	Explicitly exclude leads from non-individuals and staff
-- 22 Sep 2011	MF	R11315	3	Error in SQL when @pnNameKey is empty which was causing slow performance. This became
--					obvious when translations were in use as the user defined function was being called for
--					every row but the result had an implied DISTINCT so it appeared correct.
-- 11 Apr 2013	DV	R13270	4	Increase the length of nvarchar to 11 when casting or declaring integer

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
	If @pnNameKey is not null
	Begin
		Set @sSQLString =
		"Select " +
		"CAST(N.NAMENO 	as nvarchar(11)) +'_'+ NT.NAMETYPE	as 'RowKey',"	+char(10)+
		"N.NAMENO				as 'NameKey'," 			+char(10)+
		"NT.NAMETYPE				as 'NameTypeKey',"		+char(10)+
		"NT.PATHNAMETYPE			as 'PathNameType',"		+char(10)+
		dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)+
		"					as 'NameTypeDescription',"	+char(10)+
		"cast(isnull(NC.ALLOW,0) as bit)	as 'IsSelected',"		+char(10)+
		"case when NT.PICKLISTFLAGS & 32 = 32 then 1 else 0 end as 'IsCRMOnly'"	+char(10)+
		"from NAME N"								+CHAR(10)+
		"cross join NAMETYPE NT"						+char(10)+
		"left join NAMETYPECLASSIFICATION NC	on (NC.NAMETYPE = NT.NAMETYPE"	+char(10)+
		"					and NC.NAMENO = N.NAMENO)"	+char(10)+
		"where N.NAMENO = @pnNameKey"						+char(10)+
		"and NT.PICKLISTFLAGS & 16 = 16"					+char(10)+ -- Same Name Type
		"and ((N.USEDASFLAG NOT IN (1,5) AND NT.NAMETYPE != '~LD')"		+char(10)+
		"	or N.USEDASFLAG IN (1,5))"					+char(10)+
		
		"UNION"									+char(10)+
		
		"Select " +
		"CAST(N.NAMENO 	as nvarchar(11)) +'_'+ NT1.NAMETYPE	as 'RowKey'," 	+char(10)+
		"N.NAMENO				as 'NameKey'," 			+char(10)+
		"NT1.NAMETYPE				as 'NameTypeKey',"		+char(10)+
		"NT1.PATHNAMETYPE			as 'PathNameType',"		+char(10)+
		dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT1',@sLookupCulture,@pbCalledFromCentura)+
		"					as 'NameTypeDescription',"	+char(10)+
		"cast(isnull(NC.ALLOW,0) as bit)	as 'IsSelected',"		+char(10)+
		"case when NT1.PICKLISTFLAGS & 32 = 32 then 1 else 0 end as 'IsCRMOnly'"+char(10)+
		"from NAME N"								+CHAR(10)+
		"cross join NAMETYPE NT"						+char(10)+
		"join NAMETYPE NT1	on (NT.PATHNAMETYPE = NT1.NAMETYPE"		+char(10)+
		"			and NT.HIERARCHYFLAG = 1)"			+char(10)+
		"left join NAMETYPECLASSIFICATION NC	on (NC.NAMETYPE = NT1.NAMETYPE" +char(10)+
		"					and NC.NAMENO = N.NAMENO)"	+char(10)+		 
		"where N.NAMENO = @pnNameKey"						+char(10)+	
		"and NT.PICKLISTFLAGS &  16 = 16"					+char(10)+ -- Same Name Type
		"and NT1.PICKLISTFLAGS & 16 = 0"					+char(10)+	
		"and ((N.USEDASFLAG NOT IN (1,5) AND NT.NAMETYPE != '~LD')"		+char(10)+
		"	or N.USEDASFLAG IN (1,5))"					+char(10)+
		"order by 5" -- NameTypeDescription
	End
	
	Else
	Begin
		Set @sSQLString =
		"Select " +
		"'0'+ NT.NAMETYPE			as 'RowKey',"			+char(10)+
		"0					as 'NameKey'," 			+char(10)+
		"NT.NAMETYPE				as 'NameTypeKey',"		+char(10)+
		"NT.PATHNAMETYPE			as 'PathNameType',"		+char(10)+
		dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)+
		"					as 'NameTypeDescription',"	+char(10)+
		"cast(case when NT.NAMETYPE = '~~~' then 1 else 0 end as bit)	as 'IsSelected',"		+char(10)+
		"cast(case when NT.PICKLISTFLAGS & 32 = 32 then 1 else 0 end as bit) as 'IsCRMOnly'"	+char(10)+
		"from NAMETYPE NT"							+char(10)+
		"where NT.PICKLISTFLAGS & 16 = 16"					+char(10)+ -- Same Name Type
		"and ((@pnUsedAsFlag NOT IN (1,5) AND NT.NAMETYPE != '~LD')"		+char(10)+
		"	or @pnUsedAsFlag IN (1,5))"					+char(10)+

		"UNION"									+char(10)+
		
		"Select " +
		"'0'+ NT1.NAMETYPE		as 'RowKey'," 			+char(10)+
		"0				as 'NameKey'," 			+char(10)+
		"NT1.NAMETYPE				as 'NameTypeKey',"		+char(10)+
		"NT1.PATHNAMETYPE			as 'PathNameType',"		+char(10)+
		dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT1',@sLookupCulture,@pbCalledFromCentura)+
		"					as 'NameTypeDescription',"	+char(10)+
		"case when NT.NAMETYPE = '~~~' then 1 else 0 end	as 'IsSelected',"		+char(10)+
		"case when NT1.PICKLISTFLAGS & 32 = 32 then 1 else 0 end as 'IsCRMOnly'"+char(10)+
		"from NAMETYPE NT"							+char(10)+
		"join NAMETYPE NT1	on (NT.PATHNAMETYPE = NT1.NAMETYPE"		+char(10)+
		"			and NT.HIERARCHYFLAG = 1)"			+char(10)+
		"where NT.PICKLISTFLAGS &  16 = 16"					+char(10)+ -- Same Name Type
		"and NT1.PICKLISTFLAGS & 16 = 0"					+char(10)+
		"and ((@pnUsedAsFlag NOT IN (1,5) AND NT.NAMETYPE != '~LD')"		+char(10)+
		"	or @pnUsedAsFlag IN (1,5))"					+char(10)+
		"order by 5" -- NameTypeDescription
	End	

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey	int,
			@pnUsedAsFlag	int',
			@pnNameKey	= @pnNameKey,
			@pnUsedAsFlag	= @pnUsedAsFlag
End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchNameTypeClassification to public
GO