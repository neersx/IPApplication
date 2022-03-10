-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetCaseClasses
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetCaseClasses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetCaseClasses.'
	Drop procedure [dbo].[csw_GetCaseClasses]
End
Print '**** Creating Stored Procedure dbo.csw_GetCaseClasses...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetCaseClasses
(	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@pnCaseKey			int,
	@pbForPicklist			bit		= 0,
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure
	@psClasses			nvarchar(254)	= null,	-- Comma seperated designated country classes
	@pbIsDesignatedCountryClasses	bit		= 0	-- Whether called from designated countries		
)
as
-- PROCEDURE:	csw_GetCaseClasses
-- VERSION:	9
-- SCOPE:	WorkBenches
-- DESCRIPTION:	Returns available classes for a case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Nov 2007	AT	RFC3208	1	Procedure created
-- 06 Feb 2008	AT	RFC3208 2	Return RowKey for picklist.
-- 10 Sep 2009	ASH	RFC100052 3	Comparison of a nvarchar value with int is not correct when @pbForPicklist is not equal to 1.
-- 23 Oct 2009	DV	RFC8371 4   Modify logic to get the classes.
-- 01 Dec 2009	PS	RFC8560 5   Modify the result set. Result set will contain two table: one for Available Classes and one for Selected Classes.
-- 09 Nov 2010	ASH	RFC9818 6       Modify logic to get the classes.
-- 02 Feb 2011  LP  RFC10199 7      Display sub classes and add sub class to RowKey if available.
-- 05 Jun 2013	MS	DR60	8	Added @psClasses and @pbIsDesignatedCountryClasses parameters for designated country classes
-- 07 Sep 2018	DV	R74675	9	Do not return sub class if items are configured for a property type

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @bUseCaseJurisdiction bit
declare @bAllowSubClass bit
declare @sLookupCulture nvarchar(10)
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)


-- Initialise variables
Set @nErrorCode = 0
Set @bUseCaseJurisdiction = 0
Set @bAllowSubClass = 0

If @pbIsDesignatedCountryClasses = 0
Begin
	Set @sSQLString = "
		SELECT @psClasses = C.LOCALCLASSES
		FROM CASES C
		WHERE C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'	@psClasses	nvarchar(254) output,
				@pnCaseKey	int',
				@psClasses	= @psClasses output,
				@pnCaseKey	= @pnCaseKey

End

Set @sSQLString = "
	SELECT @bUseCaseJurisdiction = 1
			FROM	TMCLASS CL 
			join CASES C ON (C.COUNTRYCODE = CL.COUNTRYCODE
					AND C.PROPERTYTYPE = CL.PROPERTYTYPE)
			WHERE C.CASEID = @pnCaseKey"

exec @nErrorCode=sp_executesql @sSQLString,
		N'	@bUseCaseJurisdiction	bit output,
			@pnCaseKey	int',
			@bUseCaseJurisdiction	= @bUseCaseJurisdiction output,
			@pnCaseKey	= @pnCaseKey

Set @sSQLString = "
	SELECT @bAllowSubClass = CASE WHEN P.ALLOWSUBCLASS = 1 THEN 1 ELSE 0 END 
			FROM	PROPERTYTYPE P 
			join CASES C ON (C.PROPERTYTYPE = P.PROPERTYTYPE)
			WHERE C.CASEID = @pnCaseKey"

exec @nErrorCode=sp_executesql @sSQLString,
		N'	@bAllowSubClass	bit output,
			@pnCaseKey	int',
			@bAllowSubClass	= @bAllowSubClass output,
			@pnCaseKey	= @pnCaseKey

If @nErrorCode = 0
Begin

	if (@pbForPicklist=1)
	Begin
		Set @sSQLString =  "
			SELECT CASE WHEN CL.SUBCLASS IS NOT NULL AND @bAllowSubClass = 1 THEN CL.CLASS +'.'+ CL.SUBCLASS ELSE CL.CLASS END as N'Key',
				CASE WHEN CL.SUBCLASS IS NOT NULL AND @bAllowSubClass = 1 THEN CL.CLASS +'.'+ CL.SUBCLASS ELSE CL.CLASS END as N'Description',
				CL.COUNTRYCODE + '^' + CL.CLASS + '^' + CL.PROPERTYTYPE + '^' + cast(CL.SEQUENCENO as nvarchar(15)) +'^'+ CL.SUBCLASS AS 'RowKey'
			FROM	TMCLASS CL 
			join CASES C ON (C.PROPERTYTYPE = CL.PROPERTYTYPE AND (CL.COUNTRYCODE = C.COUNTRYCODE or @bUseCaseJurisdiction = 0))
			join fn_Tokenise(@psClasses, ',') CC on ((CL.CLASS = CC.Parameter and ISNULL(CL.SUBCLASS,'') = '') or CL.CLASS + '.'+ CL.SUBCLASS = CC.Parameter)
			WHERE 
			(CL.COUNTRYCODE = 'ZZZ' or  @bUseCaseJurisdiction = 1) AND
			((@bAllowSubClass = 0 and CL.SEQUENCENO = (SELECT min (CL1.SEQUENCENO) from TMCLASS CL1 
													where CL1.CLASS = CL.CLASS AND CL1.PROPERTYTYPE = CL.PROPERTYTYPE 
													AND (CL1.COUNTRYCODE = CASE when  @bUseCaseJurisdiction = 0 THEN 'ZZZ' else CL.COUNTRYCODE END)))  
			or (@bAllowSubClass = 1)) AND
			C.CASEID = @pnCaseKey"

	End
	Else
	Begin
		Set @sSQLString =  "
			SELECT C.CASEID as CaseKey, 
			CL.ID as Id,
			CL.CLASS as Class, 
			CL.INTERNATIONALCLASS as InternationalClass, 
			CL.ASSOCIATEDCLASSES as AssociatedClasses, 
			CASE WHEN @bAllowSubClass = 1 THEN CL.SUBCLASS ELSE null END as SubClass, 
			CL.SEQUENCENO as SequenceNo,
			"+dbo.fn_SqlTranslatedColumn('TMCLASS','CLASSHEADING',null,'CL',@sLookupCulture,@pbCalledFromCentura)+" as ClassHeading,
			CL.COUNTRYCODE + '^' + CL.CLASS + '^' + CL.PROPERTYTYPE + '^' + cast(CL.SEQUENCENO as nvarchar(15)) +'^'+ CL.SUBCLASS AS RowKey,
			0 as IsSelected
			FROM	TMCLASS CL 
			join CASES C ON (C.PROPERTYTYPE = CL.PROPERTYTYPE AND (CL.COUNTRYCODE = C.COUNTRYCODE or @bUseCaseJurisdiction = 0))
			left join fn_Tokenise(@psClasses, ',') CC on ((CL.CLASS = CC.Parameter and (@bAllowSubClass = 0 or ISNULL(CL.SUBCLASS,'') = '')) or CL.CLASS + '.'+ CL.SUBCLASS = CC.Parameter)
			WHERE (CL.COUNTRYCODE = 'ZZZ' or  @bUseCaseJurisdiction = 1) AND
			((@bAllowSubClass = 0 and CL.SEQUENCENO = (SELECT min (CL1.SEQUENCENO) from TMCLASS CL1 
													where CL1.CLASS = CL.CLASS AND CL1.PROPERTYTYPE = CL.PROPERTYTYPE 
													AND (CL1.COUNTRYCODE = CASE when  @bUseCaseJurisdiction = 0 THEN 'ZZZ' else CL.COUNTRYCODE END)))  
			or (@bAllowSubClass = 1)) AND
			C.CASEID = @pnCaseKey and Parameter is null

            SELECT C.CASEID as CaseKey,
			CL.ID as Id,
			CL.CLASS as Class, 
			CL.INTERNATIONALCLASS as InternationalClass, 
			CL.ASSOCIATEDCLASSES as AssociatedClasses, 
			CASE WHEN @bAllowSubClass = 1 THEN CL.SUBCLASS ELSE null END as SubClass, 
			CL.SEQUENCENO as SequenceNo,
			"+dbo.fn_SqlTranslatedColumn('TMCLASS','CLASSHEADING',null,'CL',@sLookupCulture,@pbCalledFromCentura)+" as ClassHeading,
			CL.COUNTRYCODE + '^' + CL.CLASS + '^' + CL.PROPERTYTYPE + '^' + cast(CL.SEQUENCENO as nvarchar(15)) AS RowKey,
			0 as IsSelected
			FROM	TMCLASS CL 
			join CASES C ON (C.PROPERTYTYPE = CL.PROPERTYTYPE AND (CL.COUNTRYCODE = C.COUNTRYCODE or @bUseCaseJurisdiction = 0))
			left join fn_Tokenise(@psClasses, ',') CC on ((CL.CLASS = CC.Parameter and (@bAllowSubClass = 0 or ISNULL(CL.SUBCLASS,'') = '')) or CL.CLASS + '.'+ CL.SUBCLASS = CC.Parameter)
			WHERE (CL.COUNTRYCODE = 'ZZZ' or  @bUseCaseJurisdiction = 1) AND
			((@bAllowSubClass = 0 and CL.SEQUENCENO = (SELECT min (CL1.SEQUENCENO) from TMCLASS CL1 
													where CL1.CLASS = CL.CLASS AND CL1.PROPERTYTYPE = CL.PROPERTYTYPE 
													AND (CL1.COUNTRYCODE = CASE when  @bUseCaseJurisdiction = 0 THEN 'ZZZ' else CL.COUNTRYCODE END)))  
			or (@bAllowSubClass = 1)) AND
			C.CASEID = @pnCaseKey and Parameter is not null"

	End
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey	int,
					  @psClasses	nvarchar(254),
					  @bUseCaseJurisdiction	bit,
					  @bAllowSubClass	bit',	
					  @pnCaseKey	= @pnCaseKey,
					  @psClasses	= @psClasses,
					  @bUseCaseJurisdiction = @bUseCaseJurisdiction,
					  @bAllowSubClass	= @bAllowSubClass

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetCaseClasses to public
GO
