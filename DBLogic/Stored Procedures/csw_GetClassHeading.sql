-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetClassHeading
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetClassHeading]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetClassHeading.'
	Drop procedure [dbo].[csw_GetClassHeading]
End
Print '**** Creating Stored Procedure dbo.csw_GetClassHeading...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetClassHeading
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@psCountryCode			nvarchar(3),
	@psClass			nvarchar(5),
	@psPropertyType			nvarchar(1),
	@pnSequenceNo			int,
	@psSubClass                     nvarchar(10)     = null,
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure
	@pnLanguageKey			int		= null			
)
as
-- PROCEDURE:	csw_GetClassHeading
-- VERSION:	5
-- SCOPE:	InPro
-- DESCRIPTION:	Returns a Class Heading for a particular Class.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Nov 2007	AT	RFC3208	1	Procedure created
-- 24 Jan 2011  LP      RFC10049 		2      Return the heading against Default Country if there are no default class text for the specific country, 
--                                    				  i.e. Country uses International Class system.
-- 02 Feb 2011  LP      RFC10199 	3      Add new Subclass parameter to retrieve class heading per Subclass, where applicable.
-- 13 Apr 2011	ASH	RFC100436 	4	Add Subclass to RowKey.
-- 14 Nov 2011	LP	R11517		5	Return translated heading for selected language if available.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSqlString	nvarchar(4000)
declare @sLookupCulture nvarchar(10)
declare @sClassHeading  nvarchar(max)
declare @sRowKey        nvarchar(50)

-- Initialise variables
Set @nErrorCode = 0

If @pnLanguageKey is not null
Begin
	Set @sLookupCulture = dbo.fn_GetLookupCulture(null, @pnLanguageKey, @pbCalledFromCentura)
End
Else
Begin
	Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
End
Set @nErrorCode = @@Error

If @nErrorCode = 0
Begin
        Set @sSqlString = "
                Select @sRowKey = COUNTRYCODE + '^' + CLASS + '^' + PROPERTYTYPE + '^' + CAST(SEQUENCENO AS NVARCHAR(11))+ '^' + SUBCLASS,
                @sClassHeading = "+ dbo.fn_SqlTranslatedColumn('TMCLASS','CLASSHEADING',null,'TMCLASS',@sLookupCulture,@pbCalledFromCentura) + "
                From TMCLASS
		Where COUNTRYCODE = @psCountryCode
		AND CLASS = @psClass
		AND PROPERTYTYPE = @psPropertyType
		AND SEQUENCENO = @pnSequenceNo
        "
               
        exec @nErrorCode = sp_executesql @sSqlString, 
		N'@psCountryCode nvarchar(3),
		        @psClass	nvarchar(5),
		        @psPropertyType nvarchar(1),
		        @pnSequenceNo	int,
		        @sClassHeading  nvarchar(max) output,
		        @sRowKey        nvarchar(50) output',
		        @psCountryCode = @psCountryCode,
		        @psClass = @psClass,
		        @psPropertyType = @psPropertyType,
		        @pnSequenceNo = @pnSequenceNo,
		        @sClassHeading = @sClassHeading output,
		        @sRowKey = @sRowKey output
End

-- Retrieve the heading for the default country if necessary
If @nErrorCode = 0
and @sClassHeading is null
Begin
        Set @sSqlString = "
                Select @sRowKey = COUNTRYCODE + '^' + CLASS + '^' + PROPERTYTYPE + '^' + CAST(SEQUENCENO AS NVARCHAR(11)) + '^' + SUBCLASS,
                @sClassHeading = "+ dbo.fn_SqlTranslatedColumn('TMCLASS','CLASSHEADING',null,'TMCLASS',@sLookupCulture,@pbCalledFromCentura) + "
                From TMCLASS
		Where COUNTRYCODE = 'ZZZ'
		AND CLASS = @psClass
		AND PROPERTYTYPE = @psPropertyType
		AND SEQUENCENO = @pnSequenceNo
        "
        exec @nErrorCode = sp_executesql @sSqlString, 
		N'@psClass	nvarchar(5),
		  @psPropertyType nvarchar(1),
		  @pnSequenceNo	int,
		  @psSubClass     nvarchar(10),
		  @sClassHeading  nvarchar(max) output,
		  @sRowKey        nvarchar(50) output',
		  @psClass = @psClass,
		  @psPropertyType = @psPropertyType,
		  @pnSequenceNo = @pnSequenceNo,
		  @psSubClass = @psSubClass,
		  @sClassHeading = @sClassHeading output,
		  @sRowKey = @sRowKey output
End

If @nErrorCode = 0
Begin
        
        set @sSqlString = "
		Select 	
		@sRowKey as RowKey,
		@sClassHeading as ClassHeading		
		"

	exec @nErrorCode = sp_executesql @sSqlString, 
			N'@sClassHeading nvarchar(max),
		          @sRowKey      nvarchar(50)',
			  @sClassHeading = @sClassHeading,
			  @sRowKey = @sRowKey
End


Return @nErrorCode
GO

Grant execute on dbo.csw_GetClassHeading to public
GO
