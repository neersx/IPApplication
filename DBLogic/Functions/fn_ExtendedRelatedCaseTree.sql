-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ExtendedRelatedCaseTree
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_ExtendedRelatedCaseTree') and xtype='TF')
Begin
	print '**** Drop function dbo.fn_ExtendedRelatedCaseTree.'
	drop function dbo.fn_ExtendedRelatedCaseTree
	print '**** Creating function dbo.fn_ExtendedRelatedCaseTree...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

Create Function dbo.fn_ExtendedRelatedCaseTree
			(@pnUserIdentityId	int,	-- the specific user requesting the extended related case tree
			 @pnCaseKey		int	-- the Case whose extended family is to be returned
			)
RETURNS @tblRelatedCases table
		(	ROWKEY			smallint	identity(1,1),
			CASEID			int		null,
			COUNTRYCODE		nvarchar(3)	collate database_default null,	-- identifies an external case
			OFFICIALNO		nvarchar(36)	collate database_default null,	-- identifies an external case
			DEPTH			int		not null,			-- Depth in tree that this node exists at
			PARENTROWKEY		smallint	null,				-- Internal pointer to ROWKEY of parent
			RELATIONSHIP		nvarchar(3)	collate database_default null,	-- Relationship linking this Case to its parent
			PRIORARTREPORTABLE	bit		null,				-- This case is to have Prior Art from related cases reported
			PARENTCASEID		int		null,
			PARENTCOUNTRY		nvarchar(3)	collate database_default null,	-- identifies an external parent case
			PARENTOFFICIALNO	nvarchar(36)	collate database_default null,	-- identifies an external parent case
			PATHSTRING		nvarchar(1000)	collate database_default null	-- use in ORDER BY to display tree
		)
AS
Begin
-- PROCEDURE :	fn_ExtendedRelatedCaseTree
-- VERSION :	1
-- DESCRIPTION:	For a given Case, list all of the members of the extended family that are associated either directly or
--		indirectly. This needs to include both internal and external Cases and organised into a hierarchical tree.
--
--		1. For each Case found, determinine the best parent to use.  Where multiple parents have been indicated then use the one with the earliest date
--		   associated with Relationship.  Only consider relationships that have the POINTTOPARENT flag turned on.
--		   By constructing a pointer to a single parent we will start to construct a tree as nodes in a tree may only have a single root or parent.
--		2. Any case that does not have a parent or is not the parent of another case may use a Relationship without the POINTTOPARENT flag turned on.
--
--		NOTE:
--		It is possible for multiple separate trees to be formed as a result of the node in one tree being related to the node in another tree without it 
--		begin a Parent/Child relationship. When this occurs a dummy top level root node will be created to pull all of the trees together.

-- MODIFICTIONS :
-- Date         Who	Number	Version	Change
-- ------------ ----	------	-------	------------------------------------------- 
-- 05 Dec 2014	MF	42627	1	Procedure created

declare @nError		int	
declare @nRowCount	int
declare	@nDepth		int
declare @nRootCount	smallint
declare @nRootKey	smallint

Set @nError=0
Set @nDepth=1

--------------------------------------------------------
-- For the Case, need to find every other Case that is 
-- related either directly or indirectly via RELATEDCASE
--------------------------------------------------------
If @nError=0
Begin
	insert into @tblRelatedCases(CASEID,DEPTH) values (@pnCaseKey, @nDepth)
	
	Select @nError=@@ERROR,
	       @nRowCount=@@ROWCOUNT
End

--------------------------------------------
-- Now loop through each row just added and 
-- get all of the cases related in any way.
-- The only limitation is the Relationship
-- must be one that can be shown.
--------------------------------------------
While @nRowCount>0
and @nError=0
Begin
	insert into @tblRelatedCases(CASEID, COUNTRYCODE, OFFICIALNO, DEPTH, PRIORARTREPORTABLE)
	select	R.RELATEDCASEID,  
		CASE WHEN(R.RELATEDCASEID is null) THEN R.COUNTRYCODE ELSE NULL END, 
		CASE WHEN(R.RELATEDCASEID is null) THEN R.OFFICIALNUMBER  ELSE NULL END,
		@nDepth+1,
		CASE WHEN(CR.PRIORARTFLAG=1 and CN.PRIORARTFLAG=1 and (S.PRIORARTFLAG=1 OR S.STATUSCODE is null)) THEN 1 ELSE 0 END
	from @tblRelatedCases T
	join RELATEDCASE R	on (R.CASEID=T.CASEID)
	join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
				and CR.SHOWFLAG=1)
	left join @tblRelatedCases T1
				on (T1.CASEID=R.RELATEDCASEID
				OR (T1.COUNTRYCODE=R.COUNTRYCODE AND T1.OFFICIALNO=R.OFFICIALNUMBER))
	---------------------------------------
	-- Determine if the case also requires
	-- prior art from other Cases to be 
	-- explicitly reported.
	---------------------------------------
	left join CASES C	on (C.CASEID=R.RELATEDCASEID)
	left join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS S	on (S.STATUSCODE  =C.STATUSCODE)				
	where T.DEPTH=@nDepth
	and T1.DEPTH is null	-- Ensure the related case is not already known
	and (R.RELATEDCASEID is not null OR (R.COUNTRYCODE is not null AND R.OFFICIALNUMBER is not null))
	UNION
	----------------------------------------
	-- Get any cases that are related to the
	-- internal cases previously found.
	----------------------------------------
	select	R.CASEID, NULL, NULL, @nDepth+1,
		CASE WHEN(CR.PRIORARTFLAG=1 and CN.PRIORARTFLAG=1 and (S.PRIORARTFLAG=1 OR S.STATUSCODE is null)) THEN 1 ELSE 0 END	
	from @tblRelatedCases T
	join RELATEDCASE R	on (R.RELATEDCASEID=T.CASEID)
	join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
				and CR.SHOWFLAG    =1)
	left join @tblRelatedCases T1
				on (T1.CASEID=R.CASEID)
	join CASES C		on (C.CASEID=R.CASEID)
	join COUNTRY CN		on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS S	on (S.STATUSCODE  =C.STATUSCODE)				
	where T.DEPTH=@nDepth
	and T1.DEPTH is null
	----------------------------------------
	-- Get any cases that are related to the
	-- external cases previously found.
	----------------------------------------
	UNION
	select	R.CASEID, NULL, NULL, @nDepth+1,
		CASE WHEN(CR.PRIORARTFLAG=1 and CN.PRIORARTFLAG=1 and (S.PRIORARTFLAG=1 OR S.STATUSCODE is null)) THEN 1 ELSE 0 END
	from @tblRelatedCases T
	join RELATEDCASE R	on (R.COUNTRYCODE=T.COUNTRYCODE
				and R.OFFICIALNUMBER =T.OFFICIALNO)
	join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
				and CR.SHOWFLAG    =1)
	left join @tblRelatedCases T1
				on (T1.CASEID=R.CASEID)
	join CASES C		on (C.CASEID=R.CASEID)
	join COUNTRY CN		on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS S	on (S.STATUSCODE  =C.STATUSCODE)
	where T.DEPTH=@nDepth
	and T1.DEPTH is null

	Select @nRowCount=@@ROWCOUNT,
	       @nError   =@@ERROR

	-------------------------------
	-- Increment the Depth for the
	-- next level of related Cases.
	-------------------------------
	set @nDepth=@nDepth+1
End

----------------------------------------
-- Now for each Case that has been found
-- we want to find its earliest parent
-- case.
----------------------------------------
If @nError=0
Begin
	Update T
	Set PARENTROWKEY     =T1.ROWKEY,
	    RELATIONSHIP    =RC.RELATIONSHIP,
	    PARENTCASEID    =T1.CASEID,
	    PARENTCOUNTRY   =T1.COUNTRYCODE,
	    PARENTOFFICIALNO=T1.OFFICIALNO
	from @tblRelatedCases T
	join RELATEDCASE RC on (RC.CASEID=T.CASEID
			    and RC.RELATIONSHIPNO = Cast(Substring(
							--------------------------------------
							-- Find the earliest related case that
							-- is flagged as a parent case.
							--------------------------------------
						      (	SELECT MIN(convert(char(8),coalesce(CE.EVENTDATE,RC1.PRIORITYDATE,'29991231'),112)
								 + convert(char(5),RC1.RELATIONSHIPNO))
							from RELATEDCASE    RC1
							join CASERELATION   CR	on (CR.RELATIONSHIP=RC1.RELATIONSHIP)
							left join CASEEVENT CE	on (CE.CASEID=RC1.RELATEDCASEID
										and CE.EVENTNO=CR.FROMEVENTNO
										and CE.EVENTDATE is not null)
							where RC1.CASEID=RC.CASEID 
							and CR.SHOWFLAG=1
							and CR.POINTERTOPARENT=1),9,5) as INT)
				)
	------------------------------------
	-- Now find where the earliest 
	-- parent resides in @tblRelateCases
	------------------------------------
	join (Select * from @tblRelatedCases) T1
			on (T1.CASEID=RC.RELATEDCASEID
			OR (T1.COUNTRYCODE=RC.COUNTRYCODE AND T1.OFFICIALNO=RC.OFFICIALNUMBER))
	
	Set @nError=@@ERROR

End

-------------------------------------------------
-- Any CASEID that does not point to a parent
-- and is also not referred to as a parent is to 
-- use a non POINTERTOPARENT relationship to link
-- it to a Case that is on the tree.
-------------------------------------------------
If @nError=0
Begin
	Update T
	Set PARENTROWKEY     =T1.ROWKEY,
	    RELATIONSHIP    =RC.RELATIONSHIP,
	    PARENTCASEID    =T1.CASEID,
	    PARENTCOUNTRY   =T1.COUNTRYCODE,
	    PARENTOFFICIALNO=T1.OFFICIALNO
	from @tblRelatedCases T
	join RELATEDCASE RC on (RC.CASEID=T.CASEID
			    and RC.RELATIONSHIPNO = Cast(Substring(
							--------------------------------------
							-- Find the earliest related case .
							--------------------------------------
						      (	SELECT MIN(convert(char(8),coalesce(CE.EVENTDATE,RC1.PRIORITYDATE,'29991231'),112)
								 + convert(char(5),RC1.RELATIONSHIPNO))
							from RELATEDCASE    RC1
							join CASERELATION   CR	on (CR.RELATIONSHIP=RC1.RELATIONSHIP)
							left join CASEEVENT CE	on (CE.CASEID=RC1.RELATEDCASEID
										and CE.EVENTNO=CR.FROMEVENTNO
										and CE.EVENTDATE is not null)
							where RC1.CASEID=RC.CASEID 
							and CR.SHOWFLAG=1),9,5) as INT)
				)
	------------------------------------
	-- Now find where the related case 
	-- resides in @tblRelateCases
	------------------------------------
	join (Select * from @tblRelatedCases) T1
			on (T1.CASEID=RC.RELATEDCASEID
			OR (T1.COUNTRYCODE=RC.COUNTRYCODE AND T1.OFFICIALNO=RC.OFFICIALNUMBER))
			
	-------------------------------------
	-- Check no other Case is pointing to 
	-- this case as a parent
	-------------------------------------
	left join (Select * from @tblRelatedCases) T2
			on (T2.PARENTROWKEY=T.ROWKEY)
			
	where T.PARENTROWKEY is null
	and T.RELATIONSHIP is null
	and T2.ROWKEY is null
	
	Set @nError=@@ERROR

End

If @nError=0
Begin
	Update T
	Set PARENTROWKEY     =T1.ROWKEY,
	    RELATIONSHIP    =RC.RELATIONSHIP,
	    PARENTCASEID    =T1.CASEID,
	    PARENTCOUNTRY   =T1.COUNTRYCODE,
	    PARENTOFFICIALNO=T1.OFFICIALNO
	from @tblRelatedCases T
	-----------------------------------------
	-- Find the first case that is pointing
	-- to the currenct case. Make an abitrary
	-- decision by using the lowest CASEID
	-- and RELATIONSHIPNO
	-----------------------------------------
	join RELATEDCASE RC on (RC.RELATEDCASEID=T.CASEID
			    and(CAST(RC.CASEID as CHAR(11)) + CAST(RC.RELATIONSHIPNO as CHAR(5)))
						 =  (	SELECT MIN(cast(RC1.CASEID as char(11))+ cast(RC1.RELATIONSHIPNO as CHAR(5)))
							from RELATEDCASE    RC1
							join CASERELATION   CR	on (CR.RELATIONSHIP=RC1.RELATIONSHIP)
							where RC1.CASEID=RC.CASEID 
							and CR.SHOWFLAG=1)
				)
	------------------------------------
	-- Now find where the related case 
	-- resides in @tblRelateCases
	------------------------------------
	join (Select * from @tblRelatedCases) T1
			on (T1.CASEID=RC.RELATEDCASEID
			OR (T1.COUNTRYCODE=RC.COUNTRYCODE AND T1.OFFICIALNO=RC.OFFICIALNUMBER))
			
	-------------------------------------
	-- Check no other Case is pointing to 
	-- this case as a parent
	-------------------------------------
	left join (Select * from @tblRelatedCases) T2
			on (T2.PARENTROWKEY=T.ROWKEY)
			
	where T.PARENTROWKEY is null
	and T.RELATIONSHIP is null
	and T2.ROWKEY is null
	
	Set @nError=@@ERROR

End

-------------------------------------------------
-- External cases that still do not have a
-- parent, and are not a parent, are to be 
-- related to the first case that relates to it.
-------------------------------------------------
If @nError=0
Begin
	Update T1
	Set PARENTROWKEY     =T.ROWKEY,
	    RELATIONSHIP    =RC.RELATIONSHIP,
	    PARENTCASEID    =T.CASEID,
	    PARENTCOUNTRY   =T.COUNTRYCODE,
	    PARENTOFFICIALNO=T.OFFICIALNO
	from (select * from @tblRelatedCases) T
	----------------------------------------------
	-- Find the first case that is pointing
	-- to the current case. Make an abitrary
	-- decision by using the lowest RELATIONSHIPNO
	----------------------------------------------
	join (	Select COUNTRYCODE, OFFICIALNUMBER, MIN(CASEID) AS CASEID
		from RELATEDCASE
		where  COUNTRYCODE is not null
		and OFFICIALNUMBER is not null
		group by CASEID, COUNTRYCODE, OFFICIALNUMBER) RC1
			on (RC1.CASEID=T.CASEID)
	
	join RELATEDCASE RC
			on (RC.CASEID=T.CASEID
			and RC.RELATIONSHIPNO = (Select MIN(RC2.RELATIONSHIPNO)
						 from RELATEDCASE RC2
						 where RC2.CASEID        =RC1.CASEID
						 and   RC2.COUNTRYCODE   =RC1.COUNTRYCODE
						 and   RC2.OFFICIALNUMBER=RC1.OFFICIALNUMBER))
	------------------------------------ 
	-- Now find the Related Case that is
	-- be related to a non parent case.
	------------------------------------
	join @tblRelatedCases T1
			on (T1.COUNTRYCODE=RC.COUNTRYCODE 
			AND T1.OFFICIALNO =RC.OFFICIALNUMBER)
			
	-------------------------------------
	-- Check no other Case is pointing to 
	-- the rows tobe updated (T1) as a 
	-- parent
	-------------------------------------
	left join (Select * from @tblRelatedCases) T2
			on (T2.PARENTROWKEY=T1.ROWKEY)
			
	where T1.PARENTROWKEY is null
	and T1.RELATIONSHIP is null
	and T2.ROWKEY is null
	
	Set @nError=@@ERROR

End

----------------------------------------
-- Now we need to reset the DEPTH column
-- to indicate the relative level within
-- the tree structure.
----------------------------------------
If @nError=0
Begin
	Set @nDepth=1
	Set @nRootCount=0
	
	Update T
	Set DEPTH     =	CASE WHEN(PARENTROWKEY IS NULL) THEN @nDepth ELSE 999 END,
	    PATHSTRING=	CASE WHEN(PARENTROWKEY IS NULL) THEN CAST(COALESCE(C.COUNTRYCODE,T.COUNTRYCODE) as CHAR(3)) 
							    +     COALESCE(C.CURRENTOFFICIALNO, C.IRN, T.OFFICIALNO) 
			END,
	    @nRootCount=@nRootCount+1
	from @tblRelatedCases T
	left join CASES C on (C.CASEID=T.CASEID)
	
	Select @nError=@@ERROR,
	       @nRowCount=@@ROWCOUNT
End

--------------------------------------------
-- For the DEPTH value just added, find the 
-- Cases that are the direct child of these
-- and insert these with an incremented
-- depth.
-- Repeat this until no more rows are being
-- updated.
--------------------------------------------
While @nRowCount>0
and @nError=0
Begin
	Update T1
	Set DEPTH=@nDepth+1,
	    ---------------------------------------------------------
	    -- The PATHSTRING is a concatenated list of the node keys
	    -- starting from the root and continuing to the current 
	    -- leaf node.
	    -- If you order by PATHSTRING the tree will appear to be
	    -- organised
	    ---------------------------------------------------------
	    PATHSTRING=T.PATHSTRING+';'+CAST(COALESCE(C.COUNTRYCODE, T1.COUNTRYCODE) as CHAR(3)) 
				       +     COALESCE(C.CURRENTOFFICIALNO, C.IRN, T1.OFFICIALNO) 
	From (select * from @tblRelatedCases where DEPTH=@nDepth) T
	join @tblRelatedCases T1 on (T1.PARENTROWKEY=T.ROWKEY)
	left join CASES C on (C.CASEID=T1.CASEID)
	
	Select @nError=@@ERROR,
	       @nRowCount=@@ROWCOUNT
	       
	Set @nDepth=@nDepth+1
End

-----------------------------------------------------
-- Finally, if there are more than 1 base root then 
-- this indicates that there are more than one tree.
-- This can occur when a Case in one tree has a non 
-- parent relationship to a Case in another tree.
-- All the trees need to be pulled together under a 
-- single parent root.
-----------------------------------------------------
If  @nRootCount>1
and @nError=0
Begin
	Insert into @tblRelatedCases(DEPTH) values(0)
	
	Select  @nRootKey=@@IDENTITY,
		@nError=@@ERROR
		
	If @nError=0
	Begin
		Update @tblRelatedCases
		Set PARENTROWKEY=@nRootKey
		where PARENTROWKEY is null
		and ROWKEY<>@nRootKey
		
		Set @nError=@@ERROR
	End
End

Return

End
GO

grant REFERENCES, SELECT on dbo.fn_ExtendedRelatedCaseTree to public
GO