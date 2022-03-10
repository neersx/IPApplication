-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_GetNameDataValidation									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_GetNameDataValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_GetNameDataValidation.'
	Drop procedure [dbo].[naw_GetNameDataValidation]
End
Print '**** Creating Stored Procedure dbo.naw_GetNameDataValidation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_GetNameDataValidation
(
	@pnRowCount				int		= null output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnDataValidationID		int -- Mandatory
)
as
-- PROCEDURE:	naw_GetNameDataValidation
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert DocumentRequest.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 06 Jun 2012  ASH	RFC9757	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode 	int

Declare @sSQLString	        nvarchar(max)
Declare @sSQLStringSelect	nvarchar(max)
Declare @sSQLStringFrom 	nvarchar(max)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin	
	Set @sSQLStringSelect = "
	Select D.VALIDATIONID as ValidationID,			
			D.COUNTRYCODE as CountryCode,
			C.COUNTRY as CountryDescription,
			D.CATEGORY as NameCategory,
			"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'NC',@sLookupCulture,0)
				+ "  as NameCategoryDescription,
			D.COLUMNNAME as TableColumn,
			"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,0)
				+ " as TableColumnDescription,
			D.USEDASFLAG as UsedAsFlag,
			D.LOCALCLIENTFLAG as LocalClientFlag,
			D.INUSEFLAG as InUseFlag,
			D.DEFERREDFLAG as DeferredFlag,
			D.SUPPLIERFLAG as SupplierFlag,
			D.FAMILYNO as NameGroupKey,
			"+dbo.fn_SqlTranslatedColumn('NAMEFAMILY','FAMILYTITLE',null,'NF',@sLookupCulture,0)
				+ " as NameGroupDescription,
			D.NAMENO as NameKey,
			N.NAMECODE as NameCode,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL) as Name,
			D.NAMETYPE as NameTypeKey,
			NT.DESCRIPTION as NameTypeDescription,
			D.INSTRUCTIONTYPE as InstructionTypeKey,
			"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONTYPE','INSTRTYPEDESC',null,'IT',@sLookupCulture,0)
				+ " as InstructionTypeDescription,
			D.FLAGNUMBER as InstructionKey,
			"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONLABEL','FLAGLITERAL',null,'IL',@sLookupCulture,0)
				+ " as InstructionDescription,
			"+dbo.fn_SqlTranslatedColumn('DATAVALIDATION','DISPLAYMESSAGE',null,'D',@sLookupCulture,0)
				+ " as DisplayMessage,
			D.RULEDESCRIPTION as RuleDescription,
			D.WARNINGFLAG as WarningFlag,
			D.ROLEID as RoleID,
			R.ROLENAME as RoleName,
			D.ITEM_ID as ValidationItemID,
			I.ITEM_NAME as ValidationItemName,
			D.LOGDATETIMESTAMP as LastUpdatedDate,
			"+dbo.fn_SqlTranslatedColumn('DATAVALIDATION','RULEDESCRIPTION',null,'D',@sLookupCulture,0)
				+ " as RuleDescription,
			"+dbo.fn_SqlTranslatedColumn('DATAVALIDATION','NOTES',null,'D',@sLookupCulture,0)
				+ " as Notes"
        Set @sSQLStringFrom = "
	from DATAVALIDATION D left join COUNTRY C on (C.COUNTRYCODE=D.COUNTRYCODE)		
			left join TABLECODES TC on (TC.TABLECODE=D.COLUMNNAME)
			left join TABLECODES NC on (NC.TABLECODE=D.CATEGORY)
			left join NAMEFAMILY NF on (NF.FAMILYNO=D.FAMILYNO)
			left join NAME N on (N.NAMENO=D.NAMENO)
			left join NAMETYPE NT on (NT.NAMETYPE=D.NAMETYPE)
			left join INSTRUCTIONTYPE IT on (IT.INSTRUCTIONTYPE=D.INSTRUCTIONTYPE)
			left join INSTRUCTIONLABEL IL on (IL.FLAGNUMBER=D.FLAGNUMBER)
			left join ITEM I on (I.ITEM_ID = D.ITEM_ID)
			left join ROLE R on (R.ROLEID = D.ROLEID)
			where D.VALIDATIONID = @pnDataValidationID"	
End
Set @sSQLString = @sSQLStringSelect + @sSQLStringFrom
exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnDataValidationID int',
			@pnDataValidationID	= @pnDataValidationID

Set @pnRowCount = @@Rowcount

Return @nErrorCode
GO

Grant execute on dbo.naw_GetNameDataValidation to public
GO