-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateClassFirstUse									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateClassFirstUse]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_InsertCaseText.'
	Drop procedure [dbo].[csw_UpdateClassFirstUse]
End
Print '**** Creating Stored Procedure csw_UpdateClassFirstUse...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[csw_UpdateClassFirstUse]
(
	@pnUserIdentityId	        int,		-- Mandatory
	@psCulture		        nvarchar(10) 	= null,
	@pbCalledFromCentura	        bit		= 0,
	@pnCaseKey		        int,		-- Mandatory
	@psClass		        nvarchar(11)	= null,
	@pdtFirstUse	                datetime	= null,
	@pdtFirstUseInCommerce	        datetime	= null,
	@pdtOldFirstUse	                datetime	= null,
	@pdtOldFirstUseInCommerce	datetime	= null,
	@pbIsClassInUse                 bit,	
	@pbIsFirstUseInUse              bit ,
	@pbIsFirstUseInCommerceInUse    bit 
)
as
-- PROCEDURE:	csw_UpdateClassFirstUse
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update FIRSTUSE and FIRSTUSEINCOMMERCE fields in CLASS tab of CASEDETAILS window, if the underlying values are as expected.

-- MODIFICATIONS :
-- Date			Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 10 Sep 2009	PA	RFC8043	  1	Procedure created
-- 20 Jul 2012  ASH	R12112    2     Insert a row in CLASSFIRSTUSE table if class is not present.
-- 13 Feb 2013  MS      R13223    3     Set ANSI_NULLS off to compare null values 

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT ON
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount = 0
Set @sWhereString = CHAR(10)+" where "

If exists(Select 1 from CLASSFIRSTUSE WHERE CLASS = @psClass and CASEID = @pnCaseKey)
Begin
        Set @sUpdateString = "Update CLASSFIRSTUSE
				   set"
	
	Set @sWhereString = @sWhereString+CHAR(10)+"
			CASEID = @pnCaseKey and
			CLASS = @psClass and "
	If @pbIsFirstUseInUse = 1
		Begin
			Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FIRSTUSE = @pdtFirstUse"
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FIRSTUSE = @pdtOldFirstUse"
			Set @sComma = ","
			Set @sAnd = " and "
		End
	
	If @pbIsFirstUseInCommerceInUse = 1
		Begin
			Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"FIRSTUSEINCOMMERCE = @pdtFirstUseInCommerce"
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"FIRSTUSEINCOMMERCE = @pdtOldFirstUseInCommerce"
			Set @sComma = ","
			Set @sAnd = " and "
		End
		
	Set @sUpdateString = @sUpdateString + @sWhereString
	
	exec @nErrorCode = sp_executesql @sUpdateString,
				N'@pnCaseKey		        int,
				@psClass		        nvarchar(11),
				@pdtFirstUse			datetime,
				@pdtFirstUseInCommerce		datetime,
				@pdtOldFirstUse			datetime,
				@pdtOldFirstUseInCommerce	datetime',
				@pnCaseKey	 	        = @pnCaseKey,
				@psClass	 	        = @psClass,
				@pdtFirstUse	                = @pdtFirstUse,
				@pdtFirstUseInCommerce	        = @pdtFirstUseInCommerce,
				@pdtOldFirstUse		        = @pdtOldFirstUse,
				@pdtOldFirstUseInCommerce	= @pdtOldFirstUseInCommerce

End
Else If @psClass is not null
Begin
	Set @sSQLString = "Insert into CLASSFIRSTUSE (CASEID, CLASS, FIRSTUSE, FIRSTUSEINCOMMERCE)
	         values (@pnCaseKey, @psClass, @pdtFirstUse, @pdtFirstUseInCommerce)"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey	                int,
				  @psClass		        nvarchar(11),
				  @pdtFirstUse	                datetime,
				  @pdtFirstUseInCommerce	datetime',
				  @pnCaseKey	 	        = @pnCaseKey,
				  @psClass	 	        = @psClass,
				  @pdtFirstUse	                = @pdtFirstUse,
				  @pdtFirstUseInCommerce	= @pdtFirstUseInCommerce

End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateClassFirstUse to public
GO


