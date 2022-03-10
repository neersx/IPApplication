---------------------------------------------------------------------------------------------
-- Creation of dbo.na_UpdateAlias
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_UpdateAlias]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_UpdateAlias'
	drop procedure [dbo].[na_UpdateAlias]
	Print '**** Creating Stored Procedure dbo.na_UpdateAlias...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create     procedure dbo.na_UpdateAlias
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey		varchar(11), 			
	@pnAliasTypeId		int = null, 		-- refer doco below
	@psAlias		nvarchar(20) = null,	-- Description

	@pnNameKeyModified	int	     = null,
	@pnAliasTypeIdModified	int	     = null, 			
	@pnAliasModified	int	     = null,	

	@pnAliasNo		int,			-- Mandatory identifier of NAMEALIAS row

	@psCountryCode		nvarchar(3)  = null,	-- the Country the Alias applies to
	@psPropertyType		nvarchar(2)  = null	-- the Property Type the Alias applies to	

)
-- VERSION:	7
-- DESCRIPTION:	Update an Alias of a Name
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 12 Jul 2002	SF			procedure created
-- 15 Jul 2002	SF			Updated Analysis Code Numbers
-- 19 Jul 2002	SF			Do not check TypeIdModified Flag
-- 15 Nov 2002 	SF		5	Update Version Number
-- 04 Jun 2010	MF	18703	6	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which need to be considered in the Update.
-- 15 Apr 2013	DV	R13270	7	Increase the length of nvarchar to 11 when casting or declaring integer
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
--	and @pnAliasTypeIdModified is null  
	begin
		if @pnAliasTypeId is null and @psAlias is null
		begin
			exec @nErrorCode = dbo.na_DeleteAlias @pnUserIdentityId, @psCulture, @psNameKey
		end
		else
		begin
			update NAMEALIAS set
				ALIAS = @psAlias,
				COUNTRYCODE =@psCountryCode,
				PROPERTYTYPE=@psPropertyType
			where	ALIASTYPE = @sAliasType
			and	NAMENO = Cast(@psNameKey as int)
			and	ALIASNO=@pnAliasNo
				
			select @nErrorCode = -1
		end
	end

end

GO
SET QUOTED_IDENTIFIER OFF  
GO
SET ANSI_NULLS ON  
GO

grant exec on dbo.na_UpdateAlias to public
go
