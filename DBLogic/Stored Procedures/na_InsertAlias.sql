---------------------------------------------------------------------------------------------
-- Creation of dbo.na_InsertAlias
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_InsertAlias]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_InsertAlias.'
	drop procedure [dbo].[na_InsertAlias]
	print '**** Creating Stored Procedure dbo.na_InsertAlias...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create procedure dbo.na_InsertAlias
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey		varchar(11), 		
	@pnAliasTypeId		int, 			-- refer doco below
	@psAlias		nvarchar(20) = null,	-- Description
	@psCountryCode		nvarchar(3)  = null,	-- the Country the Alias applies to
	@psPropertyType		nvarchar(2)  = null	-- the Property Type the Alias applies to
)
-- VERSION:	6
-- DESCRIPTION:	Insert an Alias for a Name
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Nov 2002 	SF		4	Update Version Number
-- 04 Jun 2010	MF	18703	5	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE.
-- 15 Apr 2013	DV	R13270	6	Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
		
	-- assumes that a new row needs to be created.
	declare @nErrorCode int
	declare @sAliasType varchar(2)

	-- get last internal code.
	declare @nLastInternalCode int

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
		insert into NAMEALIAS (
			NAMENO,
			ALIAS,
			ALIASTYPE, 
			COUNTRYCODE,
			PROPERTYTYPE
		) values (
			Cast(@psNameKey as int),
			@psAlias,
			@sAliasType,
			@psCountryCode,
			@psPropertyType
		)
		
		select @nErrorCode = @@Error
	end

end
go

grant exec on dbo.na_InsertAlias to public
go
