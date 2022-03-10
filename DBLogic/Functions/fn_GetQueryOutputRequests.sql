-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetQueryOutputRequests
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_GetQueryOutputRequests') and xtype='TF')
Begin
	Print '**** Drop function dbo.fn_GetQueryOutputRequests.'
	Drop function dbo.fn_GetQueryOutputRequests
End
Print '**** Creating function dbo.fn_GetQueryOutputRequests...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_GetQueryOutputRequests
(
	@pnUserIdentityId	int,						
	@psCulture		nvarchar(10), 
	@pnQueryContextKey	int, 
	@ptXMLOutputRequests	ntext,	 
	@pnIdoc 		int,
	@pbCalledFromCentura  	bit = 0,
	@psPresentationType 	nvarchar(30)
)

RETURNS @tblOutputRequests 	TABLE
(
	 ROWNUMBER		int IDENTITY		not null primary key,
	 COLUMNID		nvarchar(100)		collate database_default not null,
    	 SORTORDER		tinyint			null,
	 SORTDIRECTION		nvarchar(1)		collate database_default null,
	 PUBLISHNAME		nvarchar(100)		collate database_default null,
	 QUALIFIER		nvarchar(100)		collate database_default null,
	 DOCITEMKEY		int			null,
	 PROCEDURENAME		nvarchar(50)		collate database_default null,
	 DATAFORMATID  		int			null,
	 ISAGGREGATE		bit			null
)
AS
-- Function :	fn_GetQueryOutputRequests
-- VERSION :	14
-- CALLED BY :	
-- DESCRIPTION:	Return details of columns to be produced by the search.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 12-Nov-2003  TM		1	Function created
-- 21-Nov-2003	TM	RFC612	2	Temporarily add some hard coded columns for @pnQueryContextKey = 3	
-- 21-Nov-2003	TM	RFC509	3	Implement XML parameters in case search. Move defaulting to some hard coded 
--					columns to be returned to fn_GetOutputRequests.
-- 24-Nov-2003	TM	RFC509	4	Use OPENXML only if there is @ptXMLOutputRequests.
-- 30-Nov-2003	JEK	RFC643	5  	Implement defaults from the database and remove hard coding.
-- 24-Feb-2004	MF	SQA9662	6	Add DocItemKey attribute.
-- 08-Jul-2004	TM	RFC1230	7	Extract new ProcedureName attribute from the OutputRequests XML. Modify   
--					logic that locates the default presentation to select the presentation  
--					with PresentationType = null.
-- 18 Aug 2004	AB	8035	8	Add collate database_default syntax to temp tables.
-- 21 Sep 2004	TM	RFC886	9	Implement translation.
-- 07 Apr 2005	TM	RFC2493	10	Add a new DATAFORMATID int null column to the output table variable.  
-- 11 Apr 2005	TM	RFC1896	11	Add a new ISAGGREGATE column to the output table variable.
-- 06 Jun 2005	TM	RFC2630	12	Add new @psPresentationType parameter (SQA10718).
-- 09 Jun 2005	MF	11484	13	Order of columns was being corrupted when joining to QUERYDATAITEM. 
-- 30 Nov 2005	JEK	RFC4755	14	Include primary key index.

Begin		
	Declare @nRowCount	int
	Declare @sLookupCulture	nvarchar(10)

	Set	@nRowCount	= 0  
	
	-- Populate the @tblOutputRequests table with the OutputRequest parameters data 
	-- coming from the @ptXmlParams using attribute-centric mapping.  

	-- Use OPENXML only if there is @ptXMLOutputRequests 
	If datalength(@ptXMLOutputRequests) > 0
	and @pnIdoc is not null
	Begin
		Insert into @tblOutputRequests(COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME)
		Select  OX.ID, OX.SortOrder, OX.SortDirection, OX.PublishName, OX.Qualifier, OX.DocItemKey, OX.ProcedureName   
		from	OPENXML(@pnIdoc, '/OutputRequests/Column',1)
			WITH (
			      ID		nvarchar(100)	'@ID/text()',
			      SortOrder		tinyint		'@SortOrder/text()',
			      SortDirection	nvarchar(1)	'@SortDirection/text()',
			      PublishName	nvarchar(100)	'@PublishName/text()',
			      Qualifier		nvarchar(100)	'@Qualifier/text()',
			      DocItemKey	int		'@DocItemKey/text()',
			      ProcedureName	nvarchar(50)	'@ProcedureName/text()'
			     ) OX
	
		Set @nRowCount = @@RowCount

		-- SQA 11484
		-- The Update has been slit out from the above INSERT because including the Left Join was
		-- changing the Order the columns were being loaded.  When no ORDER BY clause is used the 
		-- order of the XML rows is being used.
		If @nRowCount>0
		Begin
			Update @tblOutputRequests
			Set DATAFORMATID=QI.DATAFORMATID, 
			    ISAGGREGATE=isnull(QI.ISAGGREGATE,0)
			from @tblOutputRequests T
		 	join QUERYDATAITEM QI	on (QI.PROCEDUREITEMID = T.COLUMNID
						and QI.PROCEDURENAME = T.PROCEDURENAME) 
		End
	End
	Else If @nRowCount = 0
	and @pnQueryContextKey is not null
	Begin
		set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)	
	
		-- Is a translation required?
		If @sLookupCulture is not null
		and dbo.fn_GetTranslatedTIDColumn('QUERYCOLUMN','COLUMNLABEL') is not null
		Begin
			If @pbCalledFromCentura = 1
			Begin
				Insert into @tblOutputRequests(COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, ISAGGREGATE)
				select 	DI.PROCEDUREITEMID,
					T.SORTORDER,
					T.SORTDIRECTION,
					CAST(dbo.fn_GetTranslationLimited(C.COLUMNLABEL,null,C.COLUMNLABEL_TID,@sLookupCulture) as nvarchar(100)),
					C.QUALIFIER,
					C.DOCITEMID,
					DI.PROCEDURENAME,
					DI.DATAFORMATID,
					ISNULL(DI.ISAGGREGATE,0)
				from QUERYPRESENTATION P
				-- The default may be overridden for a specific user identity
				left join QUERYPRESENTATION P1 	on (P1.CONTEXTID = P.CONTEXTID
								and P1.ISDEFAULT = P.ISDEFAULT
								and P1.IDENTITYID = @pnUserIdentityId)
				join QUERYCONTENT T		on (T.PRESENTATIONID = isnull(P1.PRESENTATIONID, P.PRESENTATIONID))
				join QUERYCOLUMN C		on (C.COLUMNID = T.COLUMNID)
				join QUERYDATAITEM DI		on (DI.DATAITEMID = C.DATAITEMID)
				WHERE 	P.CONTEXTID = @pnQueryContextKey
				AND 	P.ISDEFAULT = 1
				AND 	P.IDENTITYID IS NULL
				AND     ((P.PRESENTATIONTYPE IS NULL AND @psPresentationType IS NULL) 
				 OR 	 (P.PRESENTATIONTYPE = @psPresentationType))
				order by T.DISPLAYSEQUENCE
			
			End
			Else
			Begin
				Insert into @tblOutputRequests(COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, ISAGGREGATE)
				select 	DI.PROCEDUREITEMID,
					T.SORTORDER,
					T.SORTDIRECTION,
					CAST(dbo.fn_GetTranslation(C.COLUMNLABEL,null,C.COLUMNLABEL_TID,@sLookupCulture) as nvarchar(100)),
					C.QUALIFIER,
					C.DOCITEMID,
					DI.PROCEDURENAME,
					DI.DATAFORMATID,	
					ISNULL(DI.ISAGGREGATE,0)
				from QUERYPRESENTATION P
				-- The default may be overridden for a specific user identity
				left join QUERYPRESENTATION P1 	on (P1.CONTEXTID = P.CONTEXTID
								and P1.ISDEFAULT = P.ISDEFAULT
								and P1.IDENTITYID = @pnUserIdentityId)
				join QUERYCONTENT T		on (T.PRESENTATIONID = isnull(P1.PRESENTATIONID, P.PRESENTATIONID))
				join QUERYCOLUMN C		on (C.COLUMNID = T.COLUMNID)
				join QUERYDATAITEM DI		on (DI.DATAITEMID = C.DATAITEMID)
				WHERE 	P.CONTEXTID = @pnQueryContextKey
				AND 	P.ISDEFAULT = 1
				AND 	P.IDENTITYID IS NULL
				AND     ((P.PRESENTATIONTYPE IS NULL AND @psPresentationType IS NULL) 
				 OR 	 (P.PRESENTATIONTYPE = @psPresentationType))
				order by T.DISPLAYSEQUENCE
			
				Set @nRowCount = @@RowCount
			End
		End
		-- No translation is required
		Else
		Begin			
			Insert into @tblOutputRequests(COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID, ISAGGREGATE)
			select 	DI.PROCEDUREITEMID,
				T.SORTORDER,
				T.SORTDIRECTION,
				C.COLUMNLABEL,
				C.QUALIFIER,
				C.DOCITEMID,
				DI.PROCEDURENAME,
				DI.DATAFORMATID,
				ISNULL(DI.ISAGGREGATE,0)
			from QUERYPRESENTATION P
			-- The default may be overridden for a specific user identity
			left join QUERYPRESENTATION P1 	on (P1.CONTEXTID = P.CONTEXTID
							and P1.ISDEFAULT = P.ISDEFAULT
							and P1.IDENTITYID = @pnUserIdentityId)
			join QUERYCONTENT T		on (T.PRESENTATIONID = isnull(P1.PRESENTATIONID, P.PRESENTATIONID))
			join QUERYCOLUMN C		on (C.COLUMNID = T.COLUMNID)
			join QUERYDATAITEM DI		on (DI.DATAITEMID = C.DATAITEMID)
			WHERE 	P.CONTEXTID = @pnQueryContextKey
			AND 	P.ISDEFAULT = 1
			AND 	P.IDENTITYID IS NULL
			AND     ((P.PRESENTATIONTYPE IS NULL AND @psPresentationType IS NULL) 
			 OR 	 (P.PRESENTATIONTYPE = @psPresentationType))
			order by T.DISPLAYSEQUENCE
		
			Set @nRowCount = @@RowCount
		End	
	End

	Return 
End
GO

Grant REFERENCES, SELECT on dbo.fn_GetQueryOutputRequests to public
GO
