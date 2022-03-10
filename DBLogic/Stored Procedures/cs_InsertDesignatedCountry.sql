-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertDesignatedCountry
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertDesignatedCountry]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_InsertDesignatedCountry.'
	drop procedure [dbo].[cs_InsertDesignatedCountry]
	print '**** Creating Stored Procedure dbo.cs_InsertDesignatedCountry...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create   procedure dbo.cs_InsertDesignatedCountry
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey		varchar(11) = null, 
	@pnSequence		int = null,
	@psCountryKey		nvarchar(3) = null,
	@psCountryCode		nvarchar(3) = null,
	@psCountryName		nvarchar(60) = null,
	@pbIsDesignated		bit = null,
	@pbIsNationalPhase	bit = null
)
-- VERSION:	5
-- DESCRIPTION:	Insert a designated country
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 25 Jul 2002	SF		procedure created
-- 15 Nov 2002	SF	4	Update Version Number
-- 15 Apr 2013	DV	5	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
	declare @nErrorCode int
	set @nErrorCode = 0
	return @nErrorCode
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_InsertDesignatedCountry to public
go
