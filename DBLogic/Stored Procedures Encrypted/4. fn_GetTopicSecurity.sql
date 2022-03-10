-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetTopicSecurity
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetTopicSecurity') and xtype in ('IF','TF'))
Begin
	Print '**** Drop Function dbo.fn_GetTopicSecurity'
	Drop function [dbo].[fn_GetTopicSecurity]
End
Print '**** Creating Function dbo.fn_GetTopicSecurity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetTopicSecurity
(
	@pnUserIdentityId	int		= null,	-- If no user identity is supplied, indicates whether
							-- the topic is available at the site.
	@psTopicKeys		nvarchar(100),
	@pbCalledFromCentura  	bit 		= 0, 	-- if true, the function should provide access to all data
	@pdtToday		datetime
) 
RETURNS  TABLE
With ENCRYPTION
AS
-- Function :	fn_GetTopicSecurity
-- VERSION :	17
-- DESCRIPTION:	Returns a row per topic requested with IsAvailable = 1 if the topic is available.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Dec 2003	JEK	RFC406	1	Function created
-- 13 Jan 2004	TM	RFC768	2	Add Work In Progress (WIP) related topics
-- 18 Feb 2004	TM	RFC976	3	Implement a new @pbCalledFromCentura bit parameter which defaults to false. If true,  
--					the function should provide access to all data; i.e. implement no security.
-- 30 Mar 2004	JEK	RFC693	4	Handle topics with no special requirements for @pnUserIdentityId null.
-- 30 Mar 2004	TM	RFC693	5	Add new Work History (130), Receivable History (210), and Payable Items (300) topics.
-- 01 Jul 2004	TM	RFC1500	6	Replace accesses to ROLETOPICS and associated tables with a join to 
--					fn_PermissionsGranted() for @psObjectTable = 'DATATOPIC' and 
--					@pnObjectIntegerKey=@psTopicKeys.
-- 06 Jul 2004	TM	RFC1500	7	Remove unnecessary access to the UserIdentity table.
-- 01 Sep-2004	TM	RFC1500	8	Put back the "join CONTROLTOTAL C on (C.LEDGER = 6)" in the  Payable Items topic - 
--					For a particular user.
-- 02 Sep-2004	TM	RFC1158	9	Add new SupplierDetails topic (301) that will only be available if Accounts 
--					Payable has been implemented.
-- 14 Oct 2004	TM	RFC1898	10	Modify calls to the fn_PermissionsGranted to include 'CanSelect = 1'
--					in the 'where' clause. 
-- 26 Oct 2004	TM	RFC1516	11	Modify fn_GetTopicSecurity to replace the existing tests with the call to the 
--					fn_IsModuleLicensed function. Add new Fees and Charges topic.
-- 19 Nov 2004	TM	RFC869	12	Use fn_ValidObjects for all datatopicS to check if the firm is licensed.
-- 22 Nov 2004 	TM	RFC869	13	Add a join to fn_ValidObjects for DATATOPIC.
-- 22 Nov 2004	TM	RFC869	14	Remove 'fn_ValidObjects(null, 'DATATOPIC') VO' join from the individual
--					availability check. Correct the logic for @pnUserIdentityId is null.   
-- 22 Nov 2004	JEK	RFC869	15	Make this function encrypted because it depends on an encrypted function.
-- 12 Jul 2006	SW	RFC3828	16	Add new param @pdtToday
-- 14 Dec 2006	JEK	RFC3218	17	Change function to allow security for multiple topics to be obtained at once.
--					Implement as an inline function to improve performance.

Return
	-- For a particular user, the topic must be available as well
	-- as the corresponding module being licensed.
	select PG.ObjectIntegerKey as TopicKey, PG.CanSelect as IsAvailable
	from dbo.fn_PermissionsGranted(@pnUserIdentityId, 'DATATOPIC', null, null, @pdtToday) PG
	join dbo.fn_ValidObjects(null, 'DATATOPICREQUIRES', @pdtToday) VO2
				on (VO2.ObjectIntegerKey = PG.ObjectIntegerKey) 
	where 	patindex('%'+','+cast(PG.ObjectIntegerKey as nvarchar(12))+','+'%',',' + replace(@psTopicKeys, ' ', '') + ',')>0 
	and	isnull(@pbCalledFromCentura,0) = 0
	and	@pnUserIdentityId is not null
	-- Topics are only available to a site if corresponding module is licensed:
	union all
	select VO.ObjectIntegerKey, 1
	from dbo.fn_ValidObjects(null, 'DATATOPIC', @pdtToday) VO 
	join dbo.fn_ValidObjects(null, 'DATATOPICREQUIRES', @pdtToday) VO2
			on (VO2.ObjectIntegerKey = VO.ObjectIntegerKey)
	where 	patindex('%'+','+cast(VO.ObjectIntegerKey as nvarchar(12))+','+'%',',' + replace(@psTopicKeys, ' ', '') + ',')>0 
	and	isnull(@pbCalledFromCentura,0) = 0
	and	@pnUserIdentityId is null  -- Requested for the site rather than one user
	-- No security is enforced for client/server
	union all
	select null, 1
	where @pbCalledFromCentura=1

GO

grant REFERENCES, SELECT on dbo.fn_GetTopicSecurity to public
go
