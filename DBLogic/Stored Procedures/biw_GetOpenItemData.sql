-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetOpenItemData] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetOpenItemData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetOpenItemData].'
	drop procedure dbo.[biw_GetOpenItemData]
end
print '**** Creating procedure dbo.[biw_GetOpenItemData]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetOpenItemData]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnItemEntityNo		int = null,
				@pnItemTransNo		int = null,
				@psOpenItemNo		nvarchar(12) = null
				
as
-- PROCEDURE :	biw_GetOpenItemData
-- VERSION :	5
-- DESCRIPTION:	A procedure that returns open item header and details

-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date			Who		RFC		Version Description
-- -----------	-------	------		------- ------	-------	-------------------------------------------------------
-- 17/03/2010		KR		RFC8299		1	Created
-- 05/05/2010		KR		RFC8300		2	added more columns to the select (for credit bill)
-- 27/07/2011		KR		RFC11029	3	added code to get openitem no based on transno and entity no
-- 12/10/2011		KR		RFC10774	4	pass null as OPENITEMNO to biw_GetOpenItem for split bills
-- 02 Nov 2015		vql		R53910		5	Adjust formatted names logic (DR-15543).

set nocount on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
declare		@sAlertXML	nvarchar(400)
declare		@sWhereString	nvarchar(800)
declare		@dtCurrentDate	datetime
Declare		@sDefaultText	nvarchar(508)

Set @ErrorCode = 0

-- header

If (@ErrorCode = 0 )
Begin

		-- Get current date.
		exec @ErrorCode = dbo.ip_GetCurrentDate
				@pdtCurrentDate	= @dtCurrentDate	output,
				@pnUserIdentityId = @pnUserIdentityId,
				@psDateType	= 'U',
				@pbIncludeTime = 0
				
		if (@ErrorCode = 0 )
		Begin
			Select @sDefaultText = NARRATIVETEXT from NARRATIVE where NARRATIVECODE = 'CNDESC' 
 
		End
		
		if (@psOpenItemNo is null or @psOpenItemNo='')
		Begin
			Select @psOpenItemNo = OPENITEMNO from OPENITEM where ITEMENTITYNO = @pnItemEntityNo and ITEMTRANSNO = @pnItemTransNo 
		End
		if (@ErrorCode = 0 )
		-- get header details
		Begin

			Set @sSQLString = "SELECT 
			OI.ITEMENTITYNO as ItemEntityNo,
			dbo.fn_FormatNameUsingNameNo(EN.NAMENO, null) as EntityName,
			EN.NAMECODE as EntityNameCode,
			SN.NAMENO as StaffNameKey,
			SN.NAMECODE as StaffNameCode,
			dbo.fn_FormatNameUsingNameNo(SN.NAMENO, null) as StaffDisplayName,
			@dtCurrentDate as CurrentSystemDate,
			isnull(REGARDING, case when OI.LANGUAGE is null then cast(@sDefaultText as nvarchar(508))
					else cast(isnull(N.NARRATIVETEXT, @sDefaultText) as nvarchar(508)) End  + ' ' + OI.OPENITEMNO  ) as Regarding,
			isnull(STATEMENTREF, case when OI.LANGUAGE is null then cast(@sDefaultText as nvarchar(508))
					else cast(isnull(N.NARRATIVETEXT, @sDefaultText) as nvarchar(508)) End  + ' ' + OI.OPENITEMNO) as Statement,
			TC.DESCRIPTION as Language
			from OPENITEM OI
			join NAME EN ON (OI.ITEMENTITYNO = EN.NAMENO)
			join USERIDENTITY UI on (UI.IDENTITYID = @pnUserIdentityId)
			join NAME SN ON (SN.NAMENO = UI.NAMENO)
			left join (select NARRATIVETEXT, NT.LANGUAGE as LANGUAGE from NARRATIVE N
						join NARRATIVETRANSLATE NT on (N.NARRATIVENO = NT.NARRATIVENO )
						where N.NARRATIVECODE = 'CNDESC') N
							on N.LANGUAGE = OI.LANGUAGE
			left join TABLECODES TC on (TC.TABLECODE = OI.LANGUAGE and TC.TABLETYPE = 47)
			where OI.ITEMENTITYNO = @pnItemEntityNo
			and OI.ITEMTRANSNO = @pnItemTransNo"
			

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnUserIdentityId	int,
						  @pnItemEntityNo int,
						  @pnItemTransNo int,
						  @dtCurrentDate datetime,
						  @sDefaultText nvarchar(508)',
						  @pnUserIdentityId=@pnUserIdentityId,
						  @pnItemEntityNo=@pnItemEntityNo,
						  @pnItemTransNo=@pnItemTransNo,
						  @dtCurrentDate=@dtCurrentDate,
						  @sDefaultText = @sDefaultText
		End
End

--get open item detail records for the particular transaction

If (@ErrorCode = 0)
Begin
	if @psOpenItemNo is not null
	Begin
		if (select count(*) from OPENITEM where ITEMENTITYNO = @pnItemEntityNo and ITEMTRANSNO = @pnItemTransNo )>1
			set @psOpenItemNo = null
	End
	
	exec @ErrorCode= biw_GetOpenItem
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture	= @psCulture,
					@pbCalledFromCentura = @pbCalledFromCentura,
					@psOpenItemNo=@psOpenItemNo,
					@pnItemEntityNo=@pnItemEntityNo,
					@pnItemTransNo=@pnItemTransNo
End


return @ErrorCode
go

grant execute on dbo.[biw_GetOpenItemData]  to public
go