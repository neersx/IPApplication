-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_DeleteClasses
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_DeleteClasses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_DeleteClasses.'
	drop procedure [dbo].[cs_DeleteClasses]
end
print '**** Creating Stored Procedure dbo.cs_DeleteClasses...'
print ''
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_DeleteClasses
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			varchar(11) = null, 
	@psTrademarkClass		varchar(11) = null,
	@pnTrademarkClassSequence	int = null,
	@psTrademarkClassKey		varchar(11) = null,
	@psTrademarkClassText		ntext = null
)
as
-- VERSION :	11
-- DESCRIPTION:	deletes a row 
-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 17/07/2002	SF			stub created
-- 08/08/2002	SF			procedure created
-- 08/08/2002	SF			Cater for null NOOFCLASSES
-- 28/11/2002	SF		7	Added TrademarkClassSequence
-- 22/08/2003	TM	RFC228 	8	Case Subclasses. New PropertyType column has been taken into account 
--					to determine whether international classes are used. The size of the 
--					@psTrademarkClassKey and @psTrademarkClass parameters has been increased 
--					from nvarchar(5) to nvarchar(11). The @psTrademarkClassHeading parameter 
--					has been removed.  
-- 01/09/2003	TM	RFC385 	9	First Use dates by Class. Delete First Use dates from ClassFirstUse table.			
-- 08/06/2006	IB	RFC3942	10	Do not delete case text for a deleted class since tU_CASES_Classes
--					trigger on the CASES table handles text removal.
-- 15/04/2013	DV	R13270	11	Increase the length of nvarchar to 11 when casting or declaring integer
begin
	declare @nErrorCode 		int
	declare @nCaseId 		int
	declare @sLocalClasses 		nvarchar(254)
	declare @sNewLocalClasses 	nvarchar(254)
	declare	@sIntClasses 		nvarchar(254)
	declare @sCurrentClass 		nvarchar(10)
	declare	@sCountryCode 		nvarchar(3)
	declare @sPropertyType 		nvarchar(1)

	set concat_null_yields_null off

	set @nCaseId = cast(@psCaseKey as int)
	set @nErrorCode = @@error

	if @nErrorCode = 0
	begin
		-- Delete First Use dates

		delete
		from	CLASSFIRSTUSE 
		where	CASEID = @nCaseId
		and	CLASS = @psTrademarkClassKey
		set @nErrorCode = @@error
	end

	if @nErrorCode = 0
	begin
		-- remove from case local class

		select 	@sLocalClasses = LOCALCLASSES,
			@sCountryCode  = COUNTRYCODE,
			@sIntClasses   = INTCLASSES,
			@sPropertyType = PROPERTYTYPE 			
		from	CASES
		where	CASEID = @nCaseId

		select 	@sCurrentClass = min(T.Parameter)
		from	dbo.fn_Tokenise(@sLocalClasses, ',') T

		while	@sCurrentClass is not null
		and	@nErrorCode = 0
		begin
			if @sCurrentClass <> @psTrademarkClassKey
			begin	
				if @sNewLocalClasses is null
					set @sNewLocalClasses = @sCurrentClass
				else
					set @sNewLocalClasses = @sNewLocalClasses +  ',' + @sCurrentClass

			end

			select 	@sCurrentClass = min(T.Parameter)
			from	dbo.fn_Tokenise(@sLocalClasses, ',') T
			where	T.Parameter > @sCurrentClass

			set @nErrorCode = @@error
		end

		-- update local class / international class
		if exists(select *
			  from TMCLASS
			  where COUNTRYCODE  = @sCountryCode
			  and   PROPERTYTYPE = @sPropertyType)
		begin
			set @sIntClasses = @sNewLocalClasses

			set @nErrorCode = @@error
		end
		
		if @nErrorCode = 0
		begin
			update	CASES
			set	LOCALCLASSES = @sNewLocalClasses,		
				INTCLASSES = @sIntClasses,
				NOOFCLASSES = isnull(NOOFCLASSES, 1) - 1
			where	CASEID = @nCaseId
			
			set @nErrorCode = @@error
		end
	end

	return @nErrorCode
end
GO

grant execute on dbo.cs_DeleteClasses to public
go
