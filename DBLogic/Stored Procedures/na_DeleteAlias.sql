----------------------------------------------------------------------------------------------
-- Creation of dbo.na_DeleteAlias
----------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_DeleteAlias]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_DeleteAlias.'
	drop procedure dbo.na_DeleteAlias
	print '**** Creating Stored Procedure dbo.na_DeleteAlias...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create     procedure dbo.na_DeleteAlias
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey		varchar(11),		-- Mandatory
	@pnAliasTypeId		int, 			-- Mandatory
	@psAlias		nvarchar(20),		-- Mandatory
	@psCountryCode		nvarchar(3)	= null,	-- the Country the Alias applies to
	@psPropertyType		nvarchar(2)	= null	-- the Property Type the Alias applies to
)
-- VERSION:	6
-- DESCRIPTION:	Delete an Alias for a Name
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Nov 2002 	SF		4	Update Version Number
-- 04 Jun 2010	MF	18703	5	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which should be considered in the Delete.
-- 15 Apr 2013	DV	R13270  6	Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
	-- requires that NameKey exists and maps to NAME.NAMENO.
	declare @nErrorCode int
	declare @sAliasType varchar(2)

	set @nErrorCode = 0

	if @nErrorCode = 0
	begin
		select @sAliasType =  
			case @pnAliasTypeId
				when 1 	then '_C'	-- CPA Account Number
				when 2	then '_G'	-- General Authorization Number
				when 3	then '_P'	-- Patent Office Number
			else
				'er'  -- just a dummy to indicate error
			end						

		if @sAliasType = 'er'
			select @nErrorCode = -1
	end
		
	if @nErrorCode = 0
	begin
		delete  
		from 	NAMEALIAS
		where 	NAMENO = Cast(@psNameKey as int)
		and	ALIASTYPE = @sAliasType
		and	ALIAS = @psAlias
		and    (COUNTRYCODE =@psCountryCode  or (COUNTRYCODE  is null and @psCountryCode  is null))
		and    (PROPERTYTYPE=@psPropertyType or (PROPERTYTYPE is null and @psPropertyType is null))
			
		select @nErrorCode = @@Error		
	end
		
	return @nErrorCode
end
GO
SET QUOTED_IDENTIFIER OFF  
GO
SET ANSI_NULLS ON  
GO

grant exec on dbo.na_DeleteAlias to public
go
