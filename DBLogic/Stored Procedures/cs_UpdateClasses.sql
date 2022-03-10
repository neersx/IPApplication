-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateClasses
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateClasses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_UpdateClasses.'
	drop procedure [dbo].[cs_UpdateClasses]
	print '**** Creating Stored Procedure dbo.cs_UpdateClasses...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_UpdateClasses
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture				nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey				varchar(11) = null, 

	@psTrademarkClass			varchar(11) = null,
	@psTrademarkClassKey			varchar(11) = null,
	@pnTrademarkClassSequence		int = null,
	@psTrademarkClassText			ntext = null,

	@pbTrademarkClassModified		bit = null,
	@pbTrademarkClassKeyModified		bit = null,
	@pbTrademarkClassSequenceModified 	bit = null,
	@pbTrademarkClassTextModified		bit = null,

	@psOriginalTrademarkClassKey		varchar(11) = null,
	@pnOriginalTrademarkClassSequence 	int = null,

	@pdtFirstUse				datetime    = null,
	@pdtFirstUseInCommerce			datetime    = null
)

-- PROCEDURE :	cs_UpdateClasses
-- VERSION :	11
-- DESCRIPTION:	updates a row 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 17 Jul 2002	SF			stub created
-- 08 Aug 2002	SF			procedure created
-- 28 Nov 2002	SF		6	Added TrademarkClassSequence
-- 03 Dec 2002	SF		7	When adding new Case text, explicitly set teh TextNo.
-- 22/08/2003	TM	RFC228	8	Case Subclasses. The size of the @psTrademarkClassKey
--					@psTrademarkClass, and @psOriginalTrademarkClassKey parameters 
--					has been increased from nvarchar(5) to nvarchar(11). 
--					The @psTrademarkClassHeading parameter has been removed.  
-- 01/09/2003	TM	RFC385	9	First Use dates by Class. Add @pdtFirstUse and 
--					@pdtFirstUseInCommerce parameters. Accordingly to the parameters
--					values and the database state insert, delete or update the row in the
--					ClassFirstUse table for the CaseKey and Class  
-- 08/06/2006	IB	RFC3942	10	Update text if the data has been cleared. 
--					Do not delete case text for a deleted class since tU_CASES_Classes
--					trigger on the CASES table handles text removal.
-- 15 Apr 2013	DV	R13270	11	Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
	declare @nErrorCode int
	declare @nCaseId int
	declare	@bLongFlag int
	declare @nTextNo int

	set @nCaseId = cast(@psCaseKey as int)
	set @nErrorCode = 0

	if @psTrademarkClassKey is null
	begin
		exec @nErrorCode = dbo.cs_DeleteClasses
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@psCaseKey = @psCaseKey,
			@psTrademarkClass = @psTrademarkClass,
			@psTrademarkClassKey = @psOriginalTrademarkClassKey,
			@pnTrademarkClassSequence = @pnOriginalTrademarkClassSequence,
			@psTrademarkClassText = @psTrademarkClassText

	end
	else
	begin
		-- resume normal processing.
		if @nErrorCode = 0
		and (@pbTrademarkClassKeyModified is null
		or @pbTrademarkClassKeyModified <> 1)	
		begin			
			if (len(cast(@psTrademarkClassText as nvarchar(300))) > 254)
				set @bLongFlag = 1
			else
				set @bLongFlag = 0

			-- class has not changed 
			if @pbTrademarkClassTextModified = 1
			begin
				if exists(select * 
						from 	CASETEXT 
						where 	CASEID = @nCaseId 
						and 	TEXTTYPE = 'G' 
						and 	CLASS = @psTrademarkClassKey
						and	TEXTNO = @pnOriginalTrademarkClassSequence)
				begin
					update 	CASETEXT
					set	LONGFLAG = @bLongFlag,
						SHORTTEXT = case @bLongFlag when 1 then null 
							else cast(@psTrademarkClassText as nvarchar(254)) end,
						TEXT = case @bLongFlag when 1 then @psTrademarkClassText 
							else null end
					where 	CASEID = @nCaseId 
					and 	TEXTTYPE = 'G' 
					and 	CLASS = @psTrademarkClassKey
					and	TEXTNO = @pnOriginalTrademarkClassSequence
					
					set @nErrorCode = @@error			
				end -- update casetext
				else
				begin
					select 	@nTextNo = TEXTNO
					from	CASETEXT
					where 	CASEID = @nCaseId 
					and 	TEXTTYPE = 'G' 						

					if @nTextNo is null
						Set @nTextNo = 0
					Else 
						Set @nTextNo = @nTextNo + 1
					
					insert CASETEXT (
						CASEID,
						TEXTTYPE,
						TEXTNO,
						CLASS,
						LONGFLAG,
						SHORTTEXT,
						TEXT )
					values (
						@nCaseId,
						'G',
						@nTextNo,
						@psTrademarkClassKey,
						@bLongFlag,
						case @bLongFlag when 1 then null 
							else cast(@psTrademarkClassText as nvarchar(254)) end,
						case @bLongFlag when 1 then @psTrademarkClassText 
							else null end)

					set @nErrorCode = @@error
				end -- insert CaseText
	
			end -- trademark class text changed

			-- First Use dates have been cleared
			if @pdtFirstUse is null
			and @pdtFirstUseInCommerce is null
			begin
				delete
				from	CLASSFIRSTUSE
				where	CASEID = @nCaseId
				and	CLASS  = @psOriginalTrademarkClassKey
					
				set @nErrorCode = @@error
			end -- Delete First Use dates if they have been cleared.
			else
			-- First Use dates have been changed
			begin
				if exists(Select * 
		       			  from CLASSFIRSTUSE 
		       			  where CASEID = @nCaseId
		       			  and   CLASS  = @psOriginalTrademarkClassKey)
				begin
					update 	CLASSFIRSTUSE
					set	FIRSTUSE  = @pdtFirstUse,
						FIRSTUSEINCOMMERCE = @pdtFirstUseInCommerce 
					where 	CASEID = @nCaseId 
					and 	CLASS  = @psOriginalTrademarkClassKey
												
					set @nErrorCode = @@error			
				end -- update ClassFirstUse
				else
				begin
					insert CLASSFIRSTUSE (
						CASEID,
						CLASS,
						FIRSTUSE,
						FIRSTUSEINCOMMERCE )
					values (
						@nCaseId,
						@psOriginalTrademarkClassKey,
						@pdtFirstUse,
						@pdtFirstUseInCommerce )
	
					set @nErrorCode = @@error
				end -- insert ClassFirstUse 
			end -- First Use dates have not been cleared
		end -- classkey unchanged, trademark class text cleared/altered, First Use dates cleared/altered.
		else
		begin
			exec @nErrorCode = dbo.cs_DeleteClasses
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@psCaseKey = @psCaseKey,
						@psTrademarkClass = @psTrademarkClass,
						@psTrademarkClassKey = @psOriginalTrademarkClassKey,
						@pnTrademarkClassSequence = @pnOriginalTrademarkClassSequence,
						@psTrademarkClassText = @psTrademarkClassText
			

			if @nErrorCode = 0
			begin
				exec @nErrorCode = dbo.cs_InsertClasses
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@psCaseKey = @psCaseKey,
						@psTrademarkClass = @psTrademarkClass,
						@psTrademarkClassKey = @psTrademarkClassKey,
						@psTrademarkClassText = @psTrademarkClassText			
			end
		end -- classkey changed.
	end
	

	return @nErrorCode
end
GO

grant execute on dbo.cs_UpdateClasses to public
go
