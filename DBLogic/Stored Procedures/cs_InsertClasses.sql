-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertClasses
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertClasses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_InsertClasses.'
	drop procedure [dbo].[cs_InsertClasses]
	Print '**** Creating Stored Procedure dbo.cs_InsertClasses...'
	Print ''
End
go

set QUOTED_IDENTIFIER ON 
GO
set ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_InsertClasses
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psCaseKey			varchar(11) 	= null, 
	@psTrademarkClass		varchar(11) 	= null,
	@psTrademarkClassKey		varchar(11),	-- Mandatory
	@psTrademarkClassText		ntext 		= null,
	@pdtFirstUse			datetime	= null,
	@pdtFirstUseInCommerce		datetime	= null
)
-- PROCEDURE :	cs_InsertClasses
-- VERSION :	13
-- DESCRIPTION:	See CaseData.doc

-- Date		Who	Change	Version	Description
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 14/07/2002	JB			Function created
-- 26/07/2002	JB			Made @psTrademarkClassKey Mandatory
--					Fixed bug - adding empty texts
-- 08/08/2002	SF			Cases.NoOfClasses column is not being set (always null).
-- 22/08/2003	TM			RFC228 Case Subclasses. New PropertyType column has been 
--					taken into account to determine whether international 
--					classes are used. The size of the @psTrademarkClassKey
--					and @psTrademarkClass parameters has been increased from 
--					nvarchar(5) to nvarchar(11). The @psTrademarkClassHeading
--					parameter has been removed.  
-- 01/09/2003	TM	RFC385 		First Use dates by Class. If there is no row in the
--					CLASSFIRSTUSE table for CaseId and Class and @pdtFirstUse
--					or @pdtFirstUseInCommerce is not null then insert new row 
--					into the CLASSFIRSTUSE
-- 08/06/2006	IB	RFC3942	12	Check whether a text should be inserted or updated.
-- 25 Nov 2011	ASH	R100640	13	Change the size of Case Key to 11.
as
begin
	
	set CONCAT_NULL_YIELDS_NULL OFF

	declare @nErrorCode int
	set @nErrorCode = 0

	declare @sPropertyType	nvarchar(1) -- RFC228
	
	-- --------------
	-- Minimum data
	if 	@psTrademarkClassKey is null
		or @psTrademarkClassKey = ''
		set @nErrorCode = -1
	
	declare @nCaseId int
	set @nCaseId = Cast(@psCaseKey as int)
	
	-- ------------------
	-- Using International Classes
	if @nErrorCode = 0
	Begin
		declare @sCountryCode	nvarchar(3)
		
		Select @sCountryCode    = [COUNTRYCODE],
		       @sPropertyType   = [PROPERTYTYPE] 	  
		       from [CASES] 
		       where [CASEID]  = @nCaseId 
	
		declare @bUseLocal bit
		if exists(Select * 
			  from TMCLASS 
			  where COUNTRYCODE  = @sCountryCode
			  and   PROPERTYTYPE = @sPropertyType)
		Begin
			set @bUseLocal = 1
		End
	End
	
	-- -----------------
	-- Update Classes on Cases
	if @nErrorCode = 0
	Begin
		declare @sLocalClasses nvarchar(4000)
		select @sLocalClasses = case 	when LOCALCLASSES is null then @psTrademarkClassKey
					else 	LOCALCLASSES + ',' + @psTrademarkClassKey 
					end
		from 	CASES
		where 	CASEID = @nCaseId
	
		set @sLocalClasses = dbo.fn_StringListDedupeAndSort(@sLocalClasses,',')
	
		update 	CASES
		set 	LOCALCLASSES = @sLocalClasses,
			INTCLASSES = case when @bUseLocal = 1 then @sLocalClasses else INTCLASSES end,
			NOOFCLASSES = isnull(NOOFCLASSES, 0)+1
		where 	CASEID = @nCaseId

		set @nErrorCode = @@ERROR	
	end
	
	-- ------------------
	-- Add/Update CaseText
	if @nErrorCode = 0 
	and @psTrademarkClassText is not null
	Begin
		declare @bLongText bit
		if len( cast(@psTrademarkClassText as nvarchar(300) ) ) > 254
			set @bLongText = 1
		Else
			set @bLongText = 0
	
		declare @nTextNo int

		-- Update CaseText if it already exists
		If exists(Select 1
			from	CASETEXT CT
			where 	CT.TEXTTYPE = 'G'
			and	CT.CASEID = @nCaseId
			and 	CT.CLASS = @psTrademarkClassKey
			and	CT.LANGUAGE is null)
		Begin
			Update CASETEXT
			set 	MODIFIEDDATE 	= getdate(),
				LONGFLAG 	= @bLongText,
				SHORTTEXT 	= Case when @bLongText = 1 then null 
						else cast(@psTrademarkClassText as nvarchar(254)) end,
				[TEXT] 		= Case when @bLongText = 1 then @psTrademarkClassText 
						else null end
			where 	TEXTTYPE = 'G'
			and	CASEID = @nCaseId
			and 	CLASS = @psTrademarkClassKey
			and	LANGUAGE is null

			set @nErrorCode = @@ERROR
		End
		-- Add CaseText if it does not exist
		Else
		Begin
			Select @nTextNo = MAX([TEXTNO])
				from	[CASETEXT]
				where 	[TEXTTYPE] = 'G'
				and	[CASEID] = @nCaseId
		
			if @nTextNo is null
			Begin
				set @nTextNo = 0
			End
			Else
			Begin
				set @nTextNo = @nTextNo + 1
			End
		
			Insert into [CASETEXT]
				(	[CASEID],
					[TEXTTYPE],
					[TEXTNO],
					[CLASS],
					[MODIFIEDDATE],
					[LONGFLAG],
					[SHORTTEXT],
					[TEXT]
				)
				values
				(	@nCaseId,
					'G',
					@nTextNo,
					@psTrademarkClassKey,
					GETDATE(),
					@bLongText,
					Case when @bLongText = 1 then null 
						else cast(@psTrademarkClassText as nvarchar(254)) end,
					Case when @bLongText = 1 then @psTrademarkClassText 
						else null end
				)
			set @nErrorCode = @@ERROR
		End
	End

	-- -----------------
	-- RFC385 Insert First Use dates by Class on Cases
	if @nErrorCode = 0
	and not exists(Select * 
		       from CLASSFIRSTUSE 
		       where CASEID = @nCaseId
		       and   CLASS  = @psTrademarkClassKey)
	and (@pdtFirstUse is not null
	or @pdtFirstUseInCommerce is not null) 
	Begin		
		Insert into [CLASSFIRSTUSE]
			(	[CASEID],
				[CLASS],
				[FIRSTUSE],
				[FIRSTUSEINCOMMERCE]
			)
			values
			(	@nCaseId,
				@psTrademarkClassKey,
				@pdtFirstUse,
				@pdtFirstUseInCommerce
			)
		set @nErrorCode = @@ERROR
	End
	
	RETURN @nErrorCode
end
GO

grant execute on dbo.cs_InsertClasses to public
go
