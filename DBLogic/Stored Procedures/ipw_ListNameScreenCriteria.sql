-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListNameScreenCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListNameScreenCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListNameScreenCriteria.'
	Drop procedure [dbo].[ipw_ListNameScreenCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_ListNameScreenCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListNameScreenCriteria
(			@pnRowCount		int		= 0	OUTPUT,
			@pnUserIdentityId	int,			-- Mandatory
			@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
			@psProgramID		nvarchar(8),		-- Mandatory
			@pnNameNo		int		= null,
			@pnUsedAsFlag		smallint	= null,
			@pbSupplierFlag		bit		= null,
			@psCountryCode		nvarchar(3)	= null,
			@pbLocalClientFlag	bit		= null,
			@pnCategory		int		= null,
			@psNameType		nvarchar(3)	= null,
			@pbRuleInUse		bit		= null,
			@pbDataUnknown		bit		= null,
			@pbExactMatch		bit	-- Set to 1 if non null parameters must match otherwisw Best Fit returned
)
as
-- PROCEDURE:	ipw_ListNameScreenCriteria
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the Name Screen Control criteria that matches the search
--		characteristics passed as input parameters.
--		If @pbExactMatch=1 then any non null input parameters must match Criteria column
--		If @pbExactMatch=0 then a Best Fit algorithm will return rows ordered with the 
--		best match in descending sequence.
--		Descriptions of codes will also be returned in the language requested if available.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Aug 2008	MF	RFC6546	1	Procedure created
-- 29 Jul 2009	MS	RFC7085	2	Added parameter for RelationshipKey in fn_GetCriteriaNameRows call

SET NOCOUNT ON

declare @nErrorCode		int
declare @sSQLString		nvarchar(4000)
declare @sLookupCulture		nvarchar(10)
declare @sCountry		nvarchar(200)
declare @sCategoryDesc		nvarchar(500)
declare @sDescription		nvarchar(200)


Set @nErrorCode=0

set @sLookupCulture= dbo.fn_GetLookupCulture(@psCulture, null, 0)
	
select	@sCountry	  =dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,0),
	
	@sCategoryDesc	  =dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,0),
	
	@sDescription     =dbo.fn_SqlTranslatedColumn('NAMECRITERIA','DESCRIPTION',null,'N',@sLookupCulture,0)


If @nErrorCode=0
Begin
	Set @sSQLString="
	Select	N.NAMECRITERIANO, "+@sDescription+" as DESCRIPTION,
		N.DATAUNKNOWN,
		N.USEDASFLAG,
		N.SUPPLIERFLAG,
		N.COUNTRYCODE,    "+@sCountry+" as COUNTRY,
		N.LOCALCLIENTFLAG,
		N.CATEGORY,       "+@sCategoryDesc+" as CATEGORYDESC,
		N.USERDEFINEDRULE,
		N.RULEINUSE,
		N.DESCRIPTION,
		N.BESTFIT
	from dbo.fn_GetCriteriaNameRows
			(
			'W',			-- @psPurposeCode
			@psProgramID,
			@pnNameNo,
			@pnUsedAsFlag,
			@pbSupplierFlag,
			@psCountryCode,
			@pbLocalClientFlag,
			@pnCategory,
			@psNameType,
			null,			-- RelationshipKey
			@pbRuleInUse,
			@pbDataUnknown,
			@pbExactMatch		
			) N

	left join COUNTRY C		on (C.COUNTRYCODE=N.COUNTRYCODE)

	left join TABLECODES TC		on (TC.TABLECODE=N.CATEGORY)
	ORDER BY N.BESTFIT desc, 
		 N.DATAUNKNOWN,
		 N.USEDASFLAG,
		 N.SUPPLIERFLAG,
		 N.COUNTRYCODE,
		 N.LOCALCLIENTFLAG,
		 N.CATEGORY,
		 N.USERDEFINEDRULE desc"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@psProgramID		nvarchar(8),
				  @pnNameNo		int,
				  @pnUsedAsFlag		smallint,
				  @pbSupplierFlag	bit,
				  @psCountryCode	nvarchar(3),
				  @pbLocalClientFlag	decimal(1,0),
				  @pnCategory		int,
				  @psNameType		nvarchar(3),
				  @pbRuleInUse		bit,
				  @pbDataUnknown	bit,
				  @pbExactMatch		bit',
				  @psProgramID		=@psProgramID,
				  @pnNameNo		=@pnNameNo,
				  @pnUsedAsFlag		=@pnUsedAsFlag,
				  @pbSupplierFlag	=@pbSupplierFlag,
				  @psCountryCode	=@psCountryCode,
				  @pbLocalClientFlag	=@pbLocalClientFlag,
				  @pnCategory		=@pnCategory,
				  @psNameType		=@psNameType,
				  @pbRuleInUse		=@pbRuleInUse,
				  @pbDataUnknown	=@pbDataUnknown,
				  @pbExactMatch		=@pbExactMatch
	
	Set @pnRowCount=@@RowCount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListNameScreenCriteria to public
GO
