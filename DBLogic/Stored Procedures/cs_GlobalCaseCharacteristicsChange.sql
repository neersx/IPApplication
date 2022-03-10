-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalCaseCharacteristicsChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GlobalCaseCharacteristicsChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GlobalCaseCharacteristicsChange.'
	Drop procedure [dbo].[cs_GlobalCaseCharacteristicsChange]
End
Print '**** Creating Stored Procedure dbo.cs_GlobalCaseCharacteristicsChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GlobalCaseCharacteristicsChange
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psGlobalTempTable	nvarchar(32)	= null,	-- Use if multiple Cases are to be updated
	@pnCaseId		int		= null,	-- Use if just a single Case is to be updated as an alternative to @psGlobalTempTable
	@psCaseType		nchar(1)	= null,
	@psCountryCode		nvarchar(3)	= null,
	@psPropertyType		nchar(1)	= null,
	@psCaseCategory		nvarchar(2)	= null,
	@psSubType		nvarchar(2)	= null,
	@psBasis		nvarchar(2)	= null
)
as
-- PROCEDURE:	cs_GlobalCaseCharacteristicsChange
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Apply global updates on one or multiple selected cases.
--		Columns to be updated are CaseType, CountryCode, PropertyType,
--		CaseCategory, SubType and/or Basis.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Apr 2011	MF	RFC10347 1	Procedure created
-- 18 Apr 2011	MF	RFC10347 2	Failed testing
-- 14 Nov 2018  AV  75198/DR-45358	3   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
 
Create table dbo.#TEMPPOLICING (CASEID		int		NOT NULL,
				ACTION		nvarchar(3)	collate database_default NOT NULL,
				CYCLE		int		NOT NULL,
				SEQUENCENO	int		identity(1,1)
				)

 
-- VARIABLES

declare @nErrorCode		int
declare @TranCountStart		int
declare @nRowCount		int
declare @sSQLString		nvarchar(max)

set @nErrorCode           =0
set @nRowCount		  =0

Select @TranCountStart = @@TranCount
BEGIN TRANSACTION

If @nErrorCode = 0
Begin
	-------------------------------------------
	-- Apply global updates against Cases table
	-------------------------------------------
	Set @sSQLString = 
	"UPDATE C
	Set CASETYPE     = CASE WHEN(@psCaseType     is not null) THEN @psCaseType     ELSE C.CASETYPE     END,
	    COUNTRYCODE  = CASE WHEN(@psCountryCode  is not null) THEN @psCountryCode  ELSE C.COUNTRYCODE  END,
	    PROPERTYTYPE = CASE WHEN(@psPropertyType is not null) THEN @psPropertyType ELSE C.PROPERTYTYPE END,
	    CASECATEGORY = CASE WHEN(@psCaseCategory is not null) THEN @psCaseCategory ELSE C.CASECATEGORY END,
	    SUBTYPE      = CASE WHEN(@psSubType      is not null) THEN @psSubType      ELSE C.SUBTYPE      END
	from CASES C"

	If @psGlobalTempTable is not null
	Begin
		Set @sSQLString=@sSQLString+char(10)+"	join "+@psGlobalTempTable+" CS on (CS.CASEID=C.CASEID)"+char(10)+"	where 1=1"
	End
	Else Begin
		Set @sSQLString=@sSQLString+char(10)+"	where C.CASEID=@pnCaseId"
	End
	
	Set @sSQLString=@sSQLString+"
	and    ((@psCaseType     is not null AND (C.CASETYPE    <>@psCaseType     OR C.CASETYPE     is NULL))
	OR	(@psCountryCode  is not null AND (C.COUNTRYCODE <>@psCountryCode  OR C.COUNTRYCODE  is NULL))
	OR	(@psPropertyType is not null AND (C.PROPERTYTYPE<>@psPropertyType OR C.PROPERTYTYPE is NULL))
	OR	(@psCaseCategory is not null AND (C.CASECATEGORY<>@psCaseCategory OR C.CASECATEGORY is NULL))
	OR	(@psSubType      is not null AND (C.SUBTYPE     <>@psSubType      OR C.SUBTYPE      is NULL)))"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @psCaseType		nchar(1),
				  @psCountryCode	nvarchar(3),
				  @psPropertyType	nchar(1),
				  @psCaseCategory	nvarchar(2),
				  @psSubType		nvarchar(2)',
				  @pnCaseId		= @pnCaseId,
				  @psCaseType		= @psCaseType,
				  @psCountryCode	= @psCountryCode,
				  @psPropertyType	= @psPropertyType,
				  @psCaseCategory	= @psCaseCategory,
				  @psSubType		= @psSubType
	
	set @nRowCount = @@RowCount
End

If @nErrorCode = 0
Begin
	-------------------------------------------
	-- Apply global updates against Property table
	-------------------------------------------
	Set @sSQLString = 
	"UPDATE P
	Set BASIS = @psBasis
	from PROPERTY P"

	If @psGlobalTempTable is not null
	Begin
		Set @sSQLString=@sSQLString+char(10)+"	join "+@psGlobalTempTable+" CS on (CS.CASEID=P.CASEID)"+char(10)+"	where 1=1"
	End
	Else Begin
		Set @sSQLString=@sSQLString+char(10)+"	where P.CASEID=@pnCaseId"
	End
	
	Set @sSQLString=@sSQLString+"
	and @psBasis is not null 
	and (P.BASIS<>@psBasis OR P.BASIS is NULL)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @psBasis		nvarchar(2)',
				  @pnCaseId		= @pnCaseId,
				  @psBasis		= @psBasis
	
	set @nRowCount = @nRowCount+@@RowCount
End

If @nErrorCode=0
and @nRowCount>0
Begin
	---------------------------------------
	-- Any OPENACTION rows that are open
	-- to be repoliced if a characteristic
	-- that can impact Policing has changed
	---------------------------------------

	If @psGlobalTempTable is not null
	Begin
		Set @sSQLString="
		insert into #TEMPPOLICING(CASEID, ACTION, CYCLE)
		Select T.CASEID, OA.ACTION, OA.CYCLE
		from "+@psGlobalTempTable+" T
		join OPENACTION OA	on (OA.CASEID=T.CASEID
					and OA.POLICEEVENTS=1)
		where OA.CRITERIANO<>dbo.fn_GetCriteriaNo(OA.CASEID,'E',OA.ACTION,getdate())
		or OA.CRITERIANO is null"
	End
	Else Begin
		Set @sSQLString="
		insert into #TEMPPOLICING(CASEID, ACTION, CYCLE)
		Select T.CASEID, OA.ACTION, OA.CYCLE
		from (select @pnCaseId as CASEID) T
		join OPENACTION OA	on (OA.CASEID=T.CASEID
					and OA.POLICEEVENTS=1)
		where OA.CRITERIANO<>dbo.fn_GetCriteriaNo(OA.CASEID,'E',OA.ACTION,getdate())
		or OA.CRITERIANO is null"
	End

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseId	int',
					  @pnCaseId=@pnCaseId
	Set @nRowCount=@@Rowcount

	If  @nErrorCode=0
	and @nRowCount >0
	Begin
		----------------------------------------------------------
		-- Now load live Policing table with generated sequence no
		----------------------------------------------------------
		Set @sSQLString="
		insert into POLICING (DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
		 		      ONHOLDFLAG, ACTION, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
		select	getdate(), 
			T.SEQUENCENO, 
			'GLOBAL-'+convert(varchar, getdate(),126)+convert(varchar,T.SEQUENCENO),
			1,
			0, 
			T.ACTION, 
			T.CASEID, 
			T.CYCLE, 
			1, 
			substring(SYSTEM_USER,1,60), 
			@pnUserIdentityId
		from #TEMPPOLICING T"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int',
					  @pnUserIdentityId=@pnUserIdentityId
	End
End
	
-------------------------------------
-- Commit or Rollback the transaction
-------------------------------------
If @@TranCount > @TranCountStart
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

Return @nErrorCode
GO

Grant execute on dbo.cs_GlobalCaseCharacteristicsChange to public
GO
