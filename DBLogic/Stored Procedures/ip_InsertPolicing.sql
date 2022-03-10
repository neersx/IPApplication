-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_InsertPolicing
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_InsertPolicing]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_InsertPolicing.'
	Drop procedure [dbo].[ip_InsertPolicing]
	Print '**** Creating Stored Procedure dbo.ip_InsertPolicing...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

CREATE procedure dbo.ip_InsertPolicing
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psCaseKey			nvarchar(11),	-- Mandatory 
	@pnTypeOfRequest		int,		-- Mandatory		
	@pnPolicingBatchNo		int		= null,
	@psSysGeneratedFlag		bit		= 1, 
	@psAction			nvarchar(2)	= null, 
	@psEventKey			nvarchar(11)	= null,
	@pnCycle			int		= null,
	@pnCriteriaNo			int		= null,
	@pnCountryFlags			int		= null,
	@pbFlagSetOn			bit		= null
)

-- PROCEDURE :	ip_InsertPolicing
-- VERSION :	22
-- DESCRIPTION:	See cs_CopyCase.doc for details
-- NOTES:	The automatic procecessing does not take any account 
--		of NUMIERICKEY
--
-- VALID PARAMETERS:
-- @pnTypeOfRequest 
-- 	0 - police by name
--	1 - open an action
--	2 - police due event
--	3 - police occured event
--	4 - recalculate action
--	5 - police country flags
--	6 - recalculate due dates
--
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 23 Jul 2002	JB			Procedure created
-- 26 Jul 2002 	SF			Refined.
-- 30 Jul 2002	JB			Only sets output variables when on hold = 1
-- 05 Aug 2002	SF			Refined.
-- 08 Aug 2002	SF			@pbOnHoldFlag should not be defaulted to 0
-- 12 Aug 2002	SF			Append SequenceNo to the end of POLICINGNAME to avoid XAK1Policing problem.
-- 13 Dec 2002	SF		12	Added Optional @pnCountryFlags and @pbFlagSetOn.  If provided they are written to the Policing Table.
-- 25 Feb 2003	SF		13	RFC37 Added Batch No.
-- 17 Mar 2003	SF		14	RFC84 Modify so that
--					1. all police immediate policing is by batch
--					2. remove unnecessary parameters
--					3. typeorrequest is now mandatory
--					4. use policingseqno in the policingname instead of generating last internal code
--					5. remove 18 characters restriction on sqluser.
-- 24 Feb 2004	TM	RFC858	15	Change the datasize of the @pnCountryFlags from smallint to int.
-- 24 Feb 2004	TM	RFC709	16	Instead of inserting the USERIDENTITY.LOGINID into the POLICING.SQLUSER insert 
--					USER. Also, insert the @pnUserIdentityId value into new POLICING.IDENTITYID column.
-- 10 Jan 2006	TM	RFC3275	17	Use SYSTEM_USER for SQLUSER column rather than the USER constant.
-- 11 Nov 2008	SF	RFC3392	18	Increase field length for @psAction
-- 12 Nov 2008	SF	RFC3392	19	Backout field length change
-- 4 Dec 2008	SF	RFC3392	20	Fix incorrect RFC number
-- 09 Nov 2011	ASH	R11460	21	Change @psCaseKey as nvarchar(11) data type.
-- 15 Apr 2013	DV	R13270	22	Increase the length of nvarchar to 11 when casting or declaring integer
as 
begin
	declare @nErrorCode int
	declare @dtDateEntered datetime
	declare @nPolicingSeq int
	declare @sPolicingName nvarchar(40)
	
	Set @nErrorCode = 0

	-- generate key
	If @nErrorCode = 0
	Begin
		Set @dtDateEntered = getdate()
	
		Select 	@nPolicingSeq = isnull(max(POLICINGSEQNO) + 1, 0)
		from	POLICING
		where 	DATEENTERED = @dtDateEntered
	
		If @nPolicingSeq is null
			Set @nPolicingSeq = 0

		Set @nErrorCode = @@error
	End

	-- generate name
	If @nErrorCode = 0
	Begin
		Set @sPolicingName = dbo.fn_DateToString(@dtDateEntered,'CLEAN-DATETIME') + cast(@nPolicingSeq as nvarchar(3))

		Set @nErrorCode = @@error
	End

	if @nErrorCode = 0
	begin
		Insert Into [POLICING]
			(	[DATEENTERED],
				[POLICINGSEQNO],
				[POLICINGNAME],	
				[SYSGENERATEDFLAG],
				[ONHOLDFLAG],
				[ACTION],
				[CASEID],
				[EVENTNO],
				[CYCLE],
				[CRITERIANO],
				[SQLUSER],
				[TYPEOFREQUEST],
				[COUNTRYFLAGS],
				[FLAGSETON],
				[BATCHNO],
				[IDENTITYID]
			)
			Values	
			(	@dtDateEntered,
				@nPolicingSeq,
				@sPolicingName,
				@psSysGeneratedFlag,
				case when @pnPolicingBatchNo is null then 0 else 1 end,
				@psAction, 
				cast(@psCaseKey as int),
				cast(@psEventKey as int),
				@pnCycle,
				@pnCriteriaNo,
				SYSTEM_USER,
				@pnTypeOfRequest,
				@pnCountryFlags,
				@pbFlagSetOn,
				@pnPolicingBatchNo,
				@pnUserIdentityId
			)
		set @nErrorCode = @@error
	end	

	Return @nErrorCode
end
go

grant execute on dbo.ip_InsertPolicing to public
go
