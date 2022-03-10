declare	@pnRowCount			int,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10), -- the language in which output is to be expressed
	@pbProduceResultSet		bit,		-- if TRUE, a result set is published; if FALSE the results are held internally awaiting the next of multiple calls to the sp.
	@psBuildOperator		nvarchar(3),	-- may contain any of the values "and", "OR", "NOT"	
	@psColumnIds			nvarchar(4000), -- list of the columns (delimited by ^) required either as ouput or for sorting
	@psColumnQualifiers		nvarchar(1000),	-- list of qualifiers  (delimited by ^) that further define the data to be selected
	@psPublishColumnNames		nvarchar(4000),	-- list of columne names (delimited by ^) to be published as the output name
	@psSortOrderList		nvarchar(1000),	-- list of numbers (delimited by ^) to indicate the precedence of the matching column in the Order By clause
	@psSortDirectionList		nvarchar(1000),	-- list that indicates the direction for the sort of each column included in the Order By
	@psFamilyKey			nvarchar(20),
	@pnFamilyKeyOperator		tinyint,
	@psPickListSearch		nvarchar(254),
	@psTitle			nvarchar(10),
	@pnTitleOperator		tinyint

set	@pnUserIdentityId	=1
set	@psColumnIds		='CaseFamilyKey^CaseFamilyIsInUse^CaseFamilyTitle^'
set	@psColumnQualifiers	='^^^^^'
set	@psPublishColumnNames	='Key^In Use^Title'
set	@psSortOrderList	='3^1^2^'
set	@psSortDirectionList	='A^A^A^'
--set 	@psFamilyKey		='TEST'
--set 	@pnFamilyKeyOperator	=8
--set 	@psPickListSearch	='ZAP'
set 	@psTitle		='Test Cases'
set 	@pnTitleOperator	=8

exec ip_ListFamily	@pnRowCount OUTPUT,
			@pnUserIdentityId	=@pnUserIdentityId,
			@psColumnIds		=@psColumnIds,
			@psColumnQualifiers	=@psColumnQualifiers,
			@psPublishColumnNames	=@psPublishColumnNames,
			@psSortOrderList	=@psSortOrderList,
			@psSortDirectionList	=@psSortDirectionList,
			@psFamilyKey		=@psFamilyKey,
			@pnFamilyKeyOperator	=@pnFamilyKeyOperator,
			@psPickListSearch	=@psPickListSearch,
			@psTitle		=@psTitle,
			@pnTitleOperator	=@pnTitleOperator

select @pnRowCount