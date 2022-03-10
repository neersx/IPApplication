-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetSecurityForCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GetSecurityForCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GetSecurityForCase.'
	Drop procedure [dbo].[cs_GetSecurityForCase]
End
Print '**** Creating Stored Procedure dbo.cs_GetSecurityForCase...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_GetSecurityForCase
(
	@pnUserIdentityId 	int,		-- mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,
	-- Output parameters
	@pbCanSelect		bit	= 0 	output,
	@pbCanDelete		bit	= 0	output,
	@pbCanInsert		bit	= 0	output,
	@pbCanUpdate		bit	= 0	output
) 
AS
-- PROCEDURE:	cs_GetSecurityForCase
-- VERSION :	10
-- SCOPE:	CPA.net
-- DESCRIPTION:	Get the security available for the specified case
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 24 Oct 2002  JB		1	Procedure created
-- 25 Oct 2002	JEK		2	Adjust substitute name processing.
-- 28 Oct 2002	JEK		3	Adjust priority of fields in best fit score.
-- 12 Aug 2003	TM		6	RFC224 Office level rules. Use the Cases.OfficeId instead of
--					TABLEATTRIBUTES.TABLECODE if the Row Security Uses Case Office
--					SiteControl is turned on. Implement sp_executesgl to avoid 
--					recompilations.
-- 29 Aug 2003	AB		7	Add 'dbo.' before creation of sp name.
-- 10 Mar 2004	TM	RFC1128	8	Remove the ROWACCESSDETAIL NAMETYPE, NAMENO and SUBSTITUTENAME from the best fit. 
-- 11 Dec 2008	MF	17136	9	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 02 Jun 2016	MF	62341	10	Row level security broken out into user defined functions fn_CasesRowSecurity or fn_CasesRowSecurityMultiOffice. 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare 	@nErrorCode		int
Set 		@nErrorCode 		= 0

Declare 	@nSecurityForCase 	int
Declare		@bColboolean		bit
Declare 	@sOfficeFilter		nvarchar(1000)

Declare		@sSQLString		nvarchar(4000) 

-- Check if there is any row level security in 
If not exists(	Select * from IDENTITYROWACCESS I
		join ROWACCESSDETAIL R	on (R.ACCESSNAME=I.ACCESSNAME)
		where RECORDTYPE = 'C')
Begin
	-- If no row level security set up then they have all rights
	Set @pbCanSelect = 1
	Set @pbCanDelete = 1
	Set @pbCanInsert = 1
	Set @pbCanUpdate = 1
End
Else if @pnCaseKey is null
-- Then we need to see which rights they have for any case
Begin

	Set @sSQLString ="
	Set @pbCanSelect = case when exists(
		Select * from ROWACCESSDETAIL R
			join IDENTITYROWACCESS I on R.ACCESSNAME=I.ACCESSNAME
				and I.IDENTITYID = @pnUserIdentityId
			where (SECURITYFLAG & 1) > 0 )
		then 1 else 0 end
	Set @pbCanDelete = case when exists(
		Select * from ROWACCESSDETAIL R
			join IDENTITYROWACCESS I on R.ACCESSNAME=I.ACCESSNAME
				and I.IDENTITYID = @pnUserIdentityId
			where (SECURITYFLAG & 2) > 0 )
		then 1 else 0 end
	Set @pbCanInsert = case when exists(
		Select * from ROWACCESSDETAIL R
			join IDENTITYROWACCESS I on R.ACCESSNAME=I.ACCESSNAME
				and I.IDENTITYID = @pnUserIdentityId
			where (SECURITYFLAG & 4) > 0 )
		then 1 else 0 end
	Set @pbCanUpdate = case when exists(
		Select * from ROWACCESSDETAIL R
			join IDENTITYROWACCESS I on R.ACCESSNAME=I.ACCESSNAME
				and I.IDENTITYID = @pnUserIdentityId
			where (SECURITYFLAG & 8) > 0 )
		then 1 else 0 end"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pbCanSelect	 	bit		output,
				  @pbCanDelete		bit		output,
				  @pbCanInsert		bit		output,
				  @pbCanUpdate	 	bit		output,
				  @pnUserIdentityId	int', 
				  @pbCanSelect	= 	@pbCanSelect 	output,
				  @pbCanDelete	= 	@pbCanDelete 	output,
				  @pbCanInsert	= 	@pbCanInsert 	output,
				  @pbCanUpdate	= 	@pbCanUpdate 	output,
			 	  @pnUserIdentityId	= @pnUserIdentityId

End
Else
Begin
	-- Extract the SITECONTROL.COLBOOLEAN for the Row Security Uses Case Office
	-- and store its value in the @bColboolean variable.   

	Set @sSQLString ="
	Select  @bColboolean = COLBOOLEAN
	from SITECONTROL
	where CONTROLID = 'Row Security Uses Case Office'"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@bColboolean		int			output',
				 @bColboolean		= @bColboolean		output

	-- If the Row Security Uses Case Office sute control is turned on then set @sOfficeFilter
	-- to use Cases.OfficeId instead of TABLEATTRIBUTES.TABLECODE 
	If @bColboolean = 1
	Begin 
		Set @sSQLString="
		Select	@pbCanSelect = READALLOWED,
			@pbCanDelete = DELETEALLOWED,
			@pbCanInsert = INSERTALLOWED,
			@pbCanUpdate = UPDATEALLOWED
		from dbo.fn_CasesRowSecurity(@pnUserIdentityId)
		where CASEID=@pnCaseKey"
	End
	Else Begin 
		Set @sSQLString="
		Select	@pbCanSelect = READALLOWED,
			@pbCanDelete = DELETEALLOWED,
			@pbCanInsert = INSERTALLOWED,
			@pbCanUpdate = UPDATEALLOWED
		from dbo.fn_CasesRowSecurityMultiOffice(@pnUserIdentityId)
		where CASEID=@pnCaseKey"
	End

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pbCanSelect		bit	 	output,
				  @pbCanDelete		bit		output,
				  @pbCanInsert		bit		output,
				  @pbCanUpdate		bit		output,
				  @pnUserIdentityId	int,
				  @pnCaseKey		int',
				  @pbCanSelect		= @pbCanSelect 	output,
				  @pbCanDelete		= @pbCanDelete	output,
				  @pbCanInsert		= @pbCanInsert	output,
				  @pbCanUpdate		= @pbCanUpdate	output,
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @pnCaseKey		= @pnCaseKey	

End

RETURN 	@nErrorCode
GO

Grant execute on dbo.cs_GetSecurityForCase to public
GO
