-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_VerifyTableAttributes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_VerifyTableAttributes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_VerifyTableAttributes.'
	Drop procedure [dbo].[ipw_VerifyTableAttributes]
End
Print '**** Creating Stored Procedure dbo.ipw_VerifyTableAttributes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_VerifyTableAttributes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey 		int		= null,
	@pnCaseKey 		int		= null,
	@psCountryKey 		nvarchar(3)	= null
)
as
-- PROCEDURE:	ipw_VerifyTableAttributes
-- VERSION:	7
-- DESCRIPTION:	Verifies the minimum and maximum values by attribute type for the name.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Oct 2004	TM	RFC1814	1	Procedure created.
-- 30 Mar 2005	TM	RFC2312	2	Use the new resources for the following: IP30 -> IP48, IP31 -> IP49
-- 05 Sep 2008	AT	RFC5750	3	Cater for verification of case attributes.
-- 04 Nov 2008	AT	RFC7173	4	Cater for validation of NAME/LEAD attributes.
-- 24 Sep 2009	DV	RFC8016	5   segregate the logic for Lead with other USEDASFLAG
-- 07 Oct 2009	DV	RFC8506	6   Modify logic to get attributes for individual only if they don't exist 
--								in Name/Lead
-- 11 Apr 2013	DV	R13270	7	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sAlertXML 		nvarchar(400)

Declare @sGenericKey		nvarchar(20)
Declare @sParentTable		nvarchar(50) -- parent table for tableattributes
Declare @sSTParentTable		nvarchar(101) -- parent table for selectiontypes

Declare @nMaximumAllowed	smallint
Declare @nMinimumAllowed 	smallint
Declare @sAttributeType		nvarchar(50)
Declare @bIsLead		bit
Declare @sIndividualParentTable nvarchar(30)

-- Initialise variables
Set @nErrorCode = 0
Set @bIsLead = 0
Set @sIndividualParentTable = "'INDIVIDUAL'"

If @pnNameKey is not null
and @nErrorCode = 0
Begin
	Set @sGenericKey = cast(@pnNameKey as varchar(11))
	Set @sParentTable = 'NAME'

        If Exists (Select 1 from NAME N
                   join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO = N.NAMENO and NTC.NAMETYPE = '~LD')
                   where N.NAMENO = @pnNameKey)
	Begin
		Set @bIsLead = 1
		Set @sIndividualParentTable = @sIndividualParentTable + ",'NAME/LEAD'"
	End
End
Else If @pnCaseKey is not null
and @nErrorCode = 0
Begin
	Set @sGenericKey = cast(@pnCaseKey as varchar(11))
	Set @sParentTable = 'CASES'
End
Else If @psCountryKey is not null
and @nErrorCode = 0
Begin
	Set @sGenericKey = @psCountryKey
	Set @sParentTable = 'COUNTRY'
End

If @pnNameKey is not null
Begin
	-- Check Minimum
	If @nErrorCode = 0
	Begin
		if @bIsLead = 1
		Begin
			Set @sSQLString = " 
			Select  top 1
				@sAttributeType = TY.TABLENAME,
				@nMinimumAllowed= ST.MINIMUMALLOWED			
			from SELECTIONTYPES ST
			join TABLETYPE TY 	on (TY.TABLETYPE = ST.TABLETYPE)
			join SELECTIONTYPES ST1		on (ST.PARENTTABLE = ST1.PARENTTABLE 
			and ST1.PARENTTABLE =
					substring ((Select max(
									CASE WHEN ST2.PARENTTABLE = 'NAME/LEAD' THEN '1' ELSE '0' END +
									CASE WHEN ST2.PARENTTABLE = 'INDIVIDUAL' THEN '1' ELSE '0' END + 
									ST2.PARENTTABLE)
								from SELECTIONTYPES ST2	
								join TABLETYPE TY1 		on (TY1.TABLETYPE = ST2.TABLETYPE and TY1.TABLETYPE = TY.TABLETYPE)
								where ST2.PARENTTABLE in ('NAME/LEAD','INDIVIDUAL')), 3, 20))			  
			where    ST.MINIMUMALLOWED >(	Select count(T.TABLETYPE)
							from  TABLEATTRIBUTES T
							where T.GENERICKEY  = @sGenericKey
							and   T.PARENTTABLE = @sParentTable
							and   T.TABLETYPE = ST.TABLETYPE)"
		End
		else
		Begin
			Set @sSQLString = " 
			Select  top 1
				@sAttributeType = TY.TABLENAME,
				@nMinimumAllowed= ST.MINIMUMALLOWED			
			from SELECTIONTYPES ST
			join TABLETYPE TY 	on (TY.TABLETYPE = ST.TABLETYPE)
			join NAME N 		on (N.NAMENO = @pnNameKey)
			where ST.PARENTTABLE =	CASE 	WHEN N.USEDASFLAG&2=2 THEN 'EMPLOYEE'
						        WHEN N.USEDASFLAG&1=1 THEN 'INDIVIDUAL'
						        ELSE 'ORGANISATION'
				      	        END
			and    ST.MINIMUMALLOWED >(	Select count(T.TABLETYPE)
							from  TABLEATTRIBUTES T
							where T.GENERICKEY  = @sGenericKey
							and   T.PARENTTABLE = @sParentTable
							and   T.TABLETYPE = ST.TABLETYPE)"
		End

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@sAttributeType	nvarchar(50)	output,		
						  @nMinimumAllowed	smallint	output,
						  @pnNameKey		int,
						  @sGenericKey		nvarchar(20),
						  @sParentTable		nvarchar(50)',
						  @sAttributeType	= @sAttributeType output,
						  @nMinimumAllowed	= @nMinimumAllowed output,
						  @pnNameKey		= @pnNameKey,
						  @sGenericKey		= @sGenericKey,
						  @sParentTable		= @sParentTable
						  
	
		If @nErrorCode = 0
		and @sAttributeType is not null 
		and @nMinimumAllowed is not null
		Begin						
			Set @sAlertXML = dbo.fn_GetAlertXML('IP48', 'There must be at least {0} values for {1}',
				@nMinimumAllowed, @sAttributeType, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
		End
	End
	
	-- Check Maximum
	If @nErrorCode = 0
	Begin
		if @bIsLead = 1
		Begin
			Set @sSQLString = " 
			Select  top 1
				@sAttributeType = TY.TABLENAME,
				@nMaximumAllowed= ST.MAXIMUMALLOWED	
			from SELECTIONTYPES ST
			join TABLETYPE TY 	on (TY.TABLETYPE = ST.TABLETYPE)
			join SELECTIONTYPES ST1		on (ST.PARENTTABLE = ST1.PARENTTABLE			
			and ST1.PARENTTABLE =
					substring ((Select max(
									CASE WHEN ST2.PARENTTABLE = 'NAME/LEAD' THEN '1' ELSE '0' END +
									CASE WHEN ST2.PARENTTABLE = 'INDIVIDUAL' THEN '1' ELSE '0' END + 
									ST2.PARENTTABLE)
								from SELECTIONTYPES ST2	
								join TABLETYPE TY1 		on (TY1.TABLETYPE = ST2.TABLETYPE and TY1.TABLETYPE = TY.TABLETYPE)
								where ST2.PARENTTABLE in ('NAME/LEAD','INDIVIDUAL')), 3, 20))	
			where    ST.MAXIMUMALLOWED <(	Select count(T.TABLETYPE)
							from  TABLEATTRIBUTES T
							where T.GENERICKEY  = @sGenericKey
							and   T.PARENTTABLE = @sParentTable
							and   T.TABLETYPE = ST.TABLETYPE)"	
		End
		else
		Begin
			Set @sSQLString = " 
			Select  top 1
				@sAttributeType = TY.TABLENAME,
				@nMaximumAllowed= ST.MAXIMUMALLOWED	
			from SELECTIONTYPES ST
			join TABLETYPE TY 	on (TY.TABLETYPE = ST.TABLETYPE)
			join NAME N 		on (N.NAMENO = @pnNameKey)
			where ((N.USEDASFLAG&1=1 and ST.PARENTTABLE in (" + @sIndividualParentTable + "))
			   or  (N.USEDASFLAG&2=2 and ST.PARENTTABLE = 'EMPLOYEE')
			   or  (N.USEDASFLAG&1<>1 and N.USEDASFLAG&2<>2 and ST.PARENTTABLE = 'ORGANISATION'))
			and    ST.MAXIMUMALLOWED <(	Select count(T.TABLETYPE)
							from  TABLEATTRIBUTES T
							where T.GENERICKEY  = @sGenericKey
							and   T.PARENTTABLE = @sParentTable
							and   T.TABLETYPE = ST.TABLETYPE)"	
		End	    
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@sAttributeType	nvarchar(50)	output,		
						  @nMaximumAllowed	smallint	output,
						  @pnNameKey		int,
						  @sGenericKey		nvarchar(20),
						  @sParentTable		nvarchar(50)',
						  @sAttributeType	= @sAttributeType output,
						  @nMaximumAllowed	= @nMaximumAllowed output,
						  @sGenericKey		= @sGenericKey,
						  @sParentTable		= @sParentTable,
						  @pnNameKey		= @pnNameKey
	
		If @nErrorCode = 0
		and @sAttributeType is not null 
		and @nMaximumAllowed is not null
		Begin						
			Set @sAlertXML = dbo.fn_GetAlertXML('IP49', 'There may be only {0} values for {1}.',
				@nMaximumAllowed, @sAttributeType, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
		End
	End
End

if @pnCaseKey is not null
Begin
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "SELECT @sSTParentTable = UPPER(CT.CASETYPEDESC) + '/' + UPPER(ISNULL(VP.PROPERTYNAME,P.PROPERTYNAME))
					FROM CASES C
					JOIN CASETYPE CT ON CT.CASETYPE = C.CASETYPE
					JOIN PROPERTYTYPE P ON (P.PROPERTYTYPE = C.PROPERTYTYPE)
					LEFT JOIN VALIDPROPERTY VP ON (VP.PROPERTYTYPE = C.PROPERTYTYPE
									AND VP.COUNTRYCODE = C.COUNTRYCODE)
					WHERE C.CASEID = @pnCaseKey"
	
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'	@sSTParentTable	nvarchar(50) OUTPUT,
							@pnCaseKey	int',
							@sSTParentTable	= @sSTParentTable OUTPUT,
							@pnCaseKey	= @pnCaseKey
	End

	-- Check Minimum
	If @nErrorCode = 0
	Begin
		Set @sSQLString = " 
		Select  top 1
			@sAttributeType = TY.TABLENAME,
			@nMinimumAllowed= ST.MINIMUMALLOWED			
		from SELECTIONTYPES ST
		join TABLETYPE TY 	on (TY.TABLETYPE = ST.TABLETYPE)
		join CASES C 		on (C.CASEID = @pnCaseKey)
		where ST.PARENTTABLE = @sSTParentTable
		and    ST.MINIMUMALLOWED >(	Select count(T.TABLETYPE)
						from  TABLEATTRIBUTES T
						where T.GENERICKEY  = @sGenericKey
						and   T.PARENTTABLE = @sParentTable
						and   T.TABLETYPE = ST.TABLETYPE)"		    
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@sAttributeType	nvarchar(50)	output,		
						  @nMinimumAllowed	smallint	output,
						  @pnCaseKey		int,
						  @sGenericKey		nvarchar(20),
						  @sParentTable		nvarchar(50),
						  @sSTParentTable	nvarchar(101)',
						  @sAttributeType	= @sAttributeType output,
						  @nMinimumAllowed	= @nMinimumAllowed output,
						  @pnCaseKey		= @pnCaseKey,
						  @sGenericKey		= @sGenericKey,
						  @sParentTable		= @sParentTable,
						  @sSTParentTable	= @sSTParentTable
						  
	
		If @nErrorCode = 0
		and @sAttributeType is not null 
		and @nMinimumAllowed is not null
		Begin						
			Set @sAlertXML = dbo.fn_GetAlertXML('IP48', 'There must be at least {0} values for {1}',
				@nMinimumAllowed, @sAttributeType, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
		End
	End
	
	-- Check Maximum
	If @nErrorCode = 0
	Begin
		Set @sSQLString = " 
		Select  top 1
			@sAttributeType = TY.TABLENAME,
			@nMaximumAllowed= ST.MAXIMUMALLOWED	
		from SELECTIONTYPES ST
		join TABLETYPE TY 	on (TY.TABLETYPE = ST.TABLETYPE)
		join CASES C 		on (C.CASEID = @pnCaseKey)
		where ST.PARENTTABLE = @sSTParentTable
		and    ST.MAXIMUMALLOWED <(	Select count(T.TABLETYPE)
						from  TABLEATTRIBUTES T
						where T.GENERICKEY  = @sGenericKey
						and   T.PARENTTABLE = @sParentTable
						and   T.TABLETYPE = ST.TABLETYPE)"		    

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@sAttributeType	nvarchar(50)	output,		
						  @nMaximumAllowed	smallint	output,
						  @pnCaseKey		int,
						  @sGenericKey		nvarchar(20),
						  @sParentTable		nvarchar(50),
						  @sSTParentTable	nvarchar(101)',
						  @sAttributeType	= @sAttributeType output,
						  @nMaximumAllowed	= @nMaximumAllowed output,
						  @pnCaseKey		= @pnCaseKey,
						  @sGenericKey		= @sGenericKey,
						  @sParentTable		= @sParentTable,
						  @sSTParentTable	= @sSTParentTable
	
		If @nErrorCode = 0
		and @sAttributeType is not null 
		and @nMaximumAllowed is not null
		Begin						
			Set @sAlertXML = dbo.fn_GetAlertXML('IP49', 'There may be only {0} values for {1}.',
				@nMaximumAllowed, @sAttributeType, null, null, null)
			RAISERROR(@sAlertXML, 12, 1)
			Set @nErrorCode = @@ERROR
		End
	End
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_VerifyTableAttributes to public
GO
