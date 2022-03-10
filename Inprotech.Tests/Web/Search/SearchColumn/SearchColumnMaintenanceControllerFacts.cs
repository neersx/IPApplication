using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.Columns;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Queries;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.SearchColumn
{
    public class SearchColumnMaintenanceControllerFacts : FactBase
    {
        public class ViewDataMethod : FactBase
        {

            [Fact]
            public void ThrowsExceptionWhenTaskNotGrantedForSearchColumns()
            {
                new QueryContextModel().In(Db).WithKnownId((int)QueryContext.CaseSearch);
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                var queryContextKey = QueryContext.CaseSearch;
                var permissions = new SearchColumnMaintainability(queryContextKey);
                f.SearchColumnMaintainabilityResolver.Resolve(queryContextKey).Returns(permissions);

                Assert.Throws<UnauthorizedAccessException>(() => f.Subject.ViewData(queryContextKey));
            }

            [Fact]
            public void ThrowsExceptionWhenQueryContextNotFound()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                var queryContextKey = QueryContext.CaseSearch;
                var permissions = new SearchColumnMaintainability(queryContextKey);
                f.SearchColumnMaintainabilityResolver.Resolve(queryContextKey).Returns(permissions);

                Assert.Throws<HttpResponseException>(() => f.Subject.ViewData(queryContextKey));
            }

            [Fact]
            public void ShouldReturnPermissionsForInternalAndExternal()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                var queryContextKey = QueryContext.CaseSearch;
                new QueryContextModel().In(Db).WithKnownId((int)QueryContext.CaseSearch);
                new QueryContextModel().In(Db).WithKnownId((int)QueryContext.CaseSearchExternal);

                var permissions = new SearchColumnMaintainability(queryContextKey,
                                                                  true,
                                                                  true,
                                                                  true);
                f.SearchColumnMaintainabilityResolver.Resolve(queryContextKey)
                 .Returns(permissions);
                f.QueryContextTypeResolver.Resolve(queryContextKey).Returns(QueryContextType.Internal);
                var permissionsExternal = new SearchColumnMaintainability(QueryContext.CaseSearchExternal,
                                                                          true,
                                                                          true,
                                                                          true);
                f.SearchColumnMaintainabilityResolver.Resolve(QueryContext.CaseSearchExternal)
                 .Returns(permissionsExternal);
                f.QueryContextTypeResolver.Resolve(queryContextKey).Returns(QueryContextType.External);
                var result = f.Subject.ViewData(queryContextKey);

                var searchColumns = (List<SearchColumnQueryContextPermissions>)result.QueryContextPermissions;

                Assert.Equal((int)queryContextKey, result.QueryContextKey);
                Assert.Equal(true, searchColumns[0].DisplayForInternal);
            }

            [Fact]
            public void ShouldReturnPermissionsForInternal()
            {
                new QueryContextModel().In(Db).WithKnownId((int)QueryContext.AdHocDateSearch);
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                var queryContextKey = QueryContext.AdHocDateSearch;
                var permissions = new SearchColumnMaintainability(queryContextKey,
                                                                  true,
                                                                  true,
                                                                  true);
                f.SearchColumnMaintainabilityResolver.Resolve(queryContextKey)
                 .Returns(permissions);
                f.QueryContextTypeResolver.Resolve(queryContextKey).Returns(QueryContextType.Internal);
                var result = f.Subject.ViewData(queryContextKey);

                var searchColumns = (List<SearchColumnQueryContextPermissions>)result.QueryContextPermissions;

                Assert.Equal((int)queryContextKey, result.QueryContextKey);
                Assert.Equal(true, searchColumns[0].DisplayForInternal);
            }

            [Fact]
            public void ShouldReturnPermissionsForExternal()
            {
                new QueryContextModel().In(Db).WithKnownId((int)QueryContext.NameSearch);
                new QueryContextModel().In(Db).WithKnownId((int)QueryContext.NameSearchExternal);
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                var queryContextKey = QueryContext.NameSearchExternal;
                var permissions = new SearchColumnMaintainability(queryContextKey,
                                                                  true,
                                                                  true,
                                                                  true);
                f.SearchColumnMaintainabilityResolver.Resolve(queryContextKey).Returns(permissions);
                f.QueryContextTypeResolver.Resolve(queryContextKey).Returns(QueryContextType.External);
                var permissionsInternal = new SearchColumnMaintainability(QueryContext.NameSearch);
                f.SearchColumnMaintainabilityResolver.Resolve(QueryContext.NameSearch).Returns(permissionsInternal);
                f.QueryContextTypeResolver.Resolve(QueryContext.NameSearch).Returns(QueryContextType.Internal);
                var result = f.Subject.ViewData(queryContextKey);
                var searchColumns = (List<SearchColumnQueryContextPermissions>)result.QueryContextPermissions;

                Assert.Equal((int)queryContextKey, result.QueryContextKey);
                Assert.Equal(false, searchColumns[0].DisplayForInternal);
                Assert.Equal(true, searchColumns[1].DisplayForInternal);
            }
        }

        public class SearchMethod : FactBase
        {
            readonly string _culture = Fixture.String();

            QueryContext ResolveDependencies(SearchColumnMaintenanceControllerFixture f)
            {
                var queryContextKey = QueryContext.CaseSearch;
                var permissions = new SearchColumnMaintainability(queryContextKey,
                                                                  true,
                                                                  true,
                                                                  true);
                f.SearchColumnMaintainabilityResolver.Resolve(queryContextKey).Returns(permissions);
                f.PreferredCultureResolver.Resolve().Returns(_culture);
                return queryContextKey;
            }

            [Fact]
            public void ShouldReturnAllResult()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                f.SetupData();
                var queryContextKey = ResolveDependencies(f);
                var searchColumnOption = new SearchColumnOptions
                {
                    QueryContextKey = (int)queryContextKey,
                    Text = string.Empty
                };
                var result = f.Subject.Search(searchColumnOption, new CommonQueryParameters());

                Assert.NotNull(result);
                Assert.Equal(2, result.Count);
            }

            [Fact]
            public void ShouldReturnResultsForSearchedText()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                f.SetupData();
                var queryContextKey = ResolveDependencies(f);
                var searchColumnOption = new SearchColumnOptions
                {
                    QueryContextKey = (int)queryContextKey,
                    Text = "Activity"
                };
                var result = f.Subject.Search(searchColumnOption, new CommonQueryParameters());

                Assert.NotNull(result);
                Assert.Equal("Activity Category", result[0].DisplayName);
            }

            [Fact]
            public void ShouldReturnDefaultSortedResults()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                f.SetupData();
                var queryContextKey = ResolveDependencies(f);
                var searchColumnOption = new SearchColumnOptions
                {
                    QueryContextKey = (int)queryContextKey,
                    Text = string.Empty
                };
                var result = f.Subject.Search(searchColumnOption, new CommonQueryParameters());

                Assert.NotNull(result);
                Assert.Equal(2, result.Count);
                Assert.Contains("Act", result[0].DisplayName);
                Assert.Equal("Category", result[1].DisplayName);
            }

            [Fact]
            public void ShouldReturnSortedResultOnRequestedColumn()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                f.SetupData();
                var queryContextKey = ResolveDependencies(f);
                var searchColumnOption = new SearchColumnOptions
                {
                    QueryContextKey = (int)queryContextKey,
                    Text = string.Empty
                };
                var commonQueryParameter = new CommonQueryParameters
                {
                    SortBy = "columnNameDescription",
                    SortDir = "asc"
                };
                var result = f.Subject.Search(searchColumnOption, commonQueryParameter);

                Assert.NotNull(result);
                Assert.Equal(2, result.Count);
                Assert.Equal("Action Category", result[0].ColumnNameDescription);
                Assert.Contains("Category", result[1].ColumnNameDescription);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ThrowsExceptionWhenModelIsNull()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                Assert.Throws<ArgumentNullException>(() => f.Subject.Save(null));
            }

            [Fact]
            public void ReturnsMandatoryErrorsIfDetailsAreNotProvided()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                var result = f.Subject.Save(new SearchColumnSaveDetails());

                Assert.NotNull(result);
                var errors = (Inprotech.Infrastructure.Validations.ValidationError[]) result.Errors;
                Assert.Equal(2, errors.Length);
                Assert.Equal("field.errors.required", errors[0].Message);
                Assert.Equal("displayName", errors[0].Field);
                Assert.Equal("field.errors.required", errors[1].Message);
                Assert.Equal("columnName", errors[1].Field);
            }

            [Fact]
            public void ReturnsMandatoryErrorsForDataItemAndParameter()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);

                new QueryColumn { ColumnId = 1, DataItemId = 1, Qualifier = null, ColumnLabel = "Abstract", Description = "Action Category" }.In(Db);

                var result = f.Subject.Save(new SearchColumnSaveDetails
                {
                    ColumnName = new SearchColumnNamePayload {Description = "Abstract", Key = 1, IsUserDefined = true, IsQualifierAvailable = true},
                    DisplayName = "Abstract",
                    IsVisible = true
                });

                Assert.NotNull(result);

                var errors = (Inprotech.Infrastructure.Validations.ValidationError[]) result.Errors;
                Assert.Equal(2, errors.Length);
                Assert.Equal("field.errors.required", errors[0].Message);
                Assert.Equal("dataItem", errors[0].Field);
                Assert.Equal("field.errors.required", errors[1].Message);
                Assert.Equal("parameter", errors[1].Field);
            }

            [Fact]
            public void ShouldInsertTheColumnForInternalContext()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);

                var result = f.Subject.Save(new SearchColumnSaveDetails
                {
                    ColumnName = new SearchColumnNamePayload {Description = "Abstract", Key = 1, IsUserDefined = true, IsQualifierAvailable = true},
                    DisplayName = "Abstract",
                    Description = "Abstract Description",
                    ColumnGroup = new QueryColumnGroupPayload {Key = 2},
                    IsVisible = true,
                    DocItem = new DataItem {Key = 1},
                    Parameter = "Q",
                    QueryContextKey = (int) QueryContext.CaseSearch
                });

                Assert.Equal(result.Result, "success");

                var qc = Db.Set<QueryColumn>().ToArray();
                var qcc = Db.Set<QueryContextColumn>().ToArray();

                Assert.Equal(1, qcc.Length);
                Assert.Equal((int) QueryContext.CaseSearch, qcc[0].ContextId);
                Assert.Equal(2, qcc[0].GroupId);

                Assert.Equal(1, qc.Length);
                Assert.Equal("Abstract", qc[0].ColumnLabel);
                Assert.Equal("Abstract Description", qc[0].Description);
                Assert.Equal("Q", qc[0].Qualifier);
                Assert.Equal(1, qc[0].DocItemId);
                Assert.Equal(1, qc[0].DataItemId);
            }

            [Fact]
            public void ShouldNotInsertTheQueryContextColumnIfVisibleIsFalse()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);

                var result = f.Subject.Save(new SearchColumnSaveDetails
                {
                    ColumnName = new SearchColumnNamePayload {Description = "Abstract", Key = 1},
                    DisplayName = "Abstract",
                    Description = "Abstract Description",
                    ColumnGroup = new QueryColumnGroupPayload {Key = 2},
                    IsVisible = false,
                    QueryContextKey = (int) QueryContext.CaseSearch
                });

                Assert.Equal(result.Result, "success");

                var qc = Db.Set<QueryColumn>().ToArray();
                var qcc = Db.Set<QueryContextColumn>().ToArray();

                Assert.Equal(0, qcc.Length);

                Assert.Equal(1, qc.Length);
                Assert.Equal("Abstract", qc[0].ColumnLabel);
                Assert.Equal("Abstract Description", qc[0].Description);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ThrowsExceptionWhenModelIsNull()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                Assert.Throws<ArgumentNullException>(() => f.Subject.Update(0,null));
            }

            [Fact]
            public void ThrowsExceptionWhenColumnIdNotFound()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                Assert.Throws<HttpResponseException>(() => f.Subject.Update(0,new SearchColumnSaveDetails()));
            }

            [Fact]
            public void ReturnsMandatoryErrorsIfDetailsAreNotProvided()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                f.SetupData();
                var queryColumn = Db.Set<QueryColumn>().First();
                var result = f.Subject.Update(queryColumn.ColumnId, new SearchColumnSaveDetails {ColumnId = queryColumn.ColumnId});
                Assert.NotNull(result);
                var errors = (Inprotech.Infrastructure.Validations.ValidationError[]) result.Errors;
                Assert.Equal(2, errors.Length);
                Assert.Equal("field.errors.required", errors[0].Message);
                Assert.Equal("displayName", errors[0].Field);
                Assert.Equal("field.errors.required", errors[1].Message);
                Assert.Equal("columnName", errors[1].Field);
            }

            [Fact]
            public void UpdatesQueryColumn()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);

                f.SetupData();
                var queryColumn = Db.Set<QueryColumn>().First();
                var result = f.Subject.Update(queryColumn.ColumnId, new SearchColumnSaveDetails
                {
                    ColumnId = queryColumn.ColumnId,
                    ColumnName = new SearchColumnNamePayload {Description = "Abstract", Key = queryColumn.ColumnId},
                    DisplayName = "Abstract",
                    Description = "Abstract Description",
                    ColumnGroup = new QueryColumnGroupPayload {Key = 2},
                    IsVisible = true,
                    DocItem = new DataItem {Key = 1},
                    Parameter = "Q",
                    QueryContextKey = (int) QueryContext.CaseSearch
                });

                Assert.Equal(result.Result, "success");

                var qc = Db.Set<QueryColumn>().Where(_=>_.ColumnId == queryColumn.ColumnId).ToArray();
                
                Assert.Equal(1, qc.Length);
                Assert.Equal("Abstract", qc[0].ColumnLabel);
                Assert.Equal("Abstract Description", qc[0].Description);
                Assert.Equal("Q", qc[0].Qualifier);
                Assert.Equal(1, qc[0].DocItemId);
                Assert.Equal(1, qc[0].DataItemId);
            }

            [Fact]
            public void RemoveQueryContextColumnIfVisibleIsFalse()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);

                var queryColumn = new QueryColumn { ColumnId = 1, DataItemId = 1, Qualifier = null, ColumnLabel = "Activity Category", Description = "Action Category" }.In(Db);
                new QueryContextColumn {ColumnId = queryColumn.ColumnId, ContextId = (int) QueryContext.CaseSearch, IsMandatory = true, IsSortOnly = true}.In(Db);

                var result = f.Subject.Update(queryColumn.ColumnId, new SearchColumnSaveDetails
                {
                    ColumnId = queryColumn.ColumnId,
                    ColumnName = new SearchColumnNamePayload {Description = "Abstract", Key = queryColumn.ColumnId},
                    DisplayName = "Abstract",
                    Description = "Abstract Description",
                    ColumnGroup = new QueryColumnGroupPayload {Key = 2},
                    IsVisible = false,
                    QueryContextKey = (int) QueryContext.CaseSearch
                });

                Assert.Equal(result.Result, "success");

                var qc = Db.Set<QueryColumn>().Where(_=>_.ColumnId == queryColumn.ColumnId).ToArray();
                
                Assert.Equal(1, qc.Length);
                Assert.Equal("Abstract", qc[0].ColumnLabel);
                Assert.Equal("Abstract Description", qc[0].Description);

                var qcc = Db.Set<QueryContextColumn>().FirstOrDefault(_=>_.ColumnId == queryColumn.ColumnId);
                Assert.Null(qcc);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ThrowsExceptionWhenModelIsNull()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                Assert.Throws<ArgumentNullException>(() => f.Subject.Delete(null));
            }

            [Fact]
            public void ShouldDeleteTheQueryColumn()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                f.SetupData();
                var deleteModel = new SearchColumnDeleteRequest
                {
                    ContextId = (int) QueryContext.CaseSearch,
                    Ids = new List<int> {1, 2}
                };
                f.Subject.Delete(deleteModel);

                var deletedContextColumns = Db.Set<QueryContextColumn>().FirstOrDefault(_ =>_.ContextId == 2 && _.ColumnId == 1 || _.ColumnId == 2);
                Assert.Null(deletedContextColumns);
                var deletedColumns = Db.Set<QueryColumn>().FirstOrDefault(_ => _.ColumnId == 1 || _.ColumnId == 2);
                Assert.Null(deletedColumns);
                var notDeletedContextColumns = Db.Set<QueryContextColumn>().FirstOrDefault(_ => _.ColumnId == 3);
                Assert.NotNull(notDeletedContextColumns);
                var notDeletedColumn = Db.Set<QueryColumn>().FirstOrDefault(_ => _.ColumnId == 3);
                Assert.NotNull(notDeletedColumn);
            }
        }

        public class UsageMethod : FactBase
        {
            [Fact]
            public void ReturnsUsageInAscendingOrderOfSearchType()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                f.SetupData();

                var usages = f.Subject.Usage(1).ToArray();
                Assert.Equal(2, usages.Length);
                Assert.Equal("Ad Hoc Date Search",usages.First().SearchType);
                Assert.Equal("Case Search",usages.Last().SearchType);
            }
        }

        public class SearchColumnMethod : FactBase
        {
            [Fact]
            public void GetSearchColumn()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                f.SetupData();

                var searchColumn = f.Subject.SearchColumn((int)QueryContext.CaseSearch, 1);

                Assert.Equal("Activity Category", searchColumn.DisplayName);
                Assert.Equal("Action Category", searchColumn.Description);
                Assert.Equal("Text", searchColumn.DataFormat);
                Assert.False(searchColumn.ColumnName.IsUserDefined);
                Assert.False(searchColumn.ColumnName.IsQualifierAvailable);
                Assert.Equal("csw_ListCase",searchColumn.ColumnName.Description);
            }

            [Fact]
            public void ThrowsHttpResponseExceptionWhenSearchColumnNotFound()
            {
                var f = new SearchColumnMaintenanceControllerFixture(Db);
                f.SetupData();

                Assert.Throws<HttpResponseException>(() => f.Subject.SearchColumn((int)QueryContext.CaseSearch, Fixture.Integer()));
            }
        }
    }

    public class SearchColumnMaintenanceControllerFixture : IFixture<SearchColumnsMaintenanceController>
    {
        public SearchColumnMaintenanceControllerFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            SearchColumnMaintainabilityResolver = Substitute.For<ISearchColumnMaintainabilityResolver>();
            QueryContextTypeResolver = Substitute.For<IQueryContextTypeResolver>();
            DbContext = db;
            var permissions = new SearchColumnMaintainability(Arg.Any<QueryContext>(),
                                                              true,
                                                              true,
                                                              true);
            SearchColumnMaintainabilityResolver.Resolve(Arg.Any<QueryContext>())
             .Returns(permissions);
            Subject = new SearchColumnsMaintenanceController(DbContext, PreferredCultureResolver, SearchColumnMaintainabilityResolver, QueryContextTypeResolver);
        }

        public InMemoryDbContext DbContext { get; set; }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public ISearchColumnMaintainabilityResolver SearchColumnMaintainabilityResolver { get; set; }

        public IQueryContextTypeResolver QueryContextTypeResolver { get; set; }
        public SearchColumnsMaintenanceController Subject { get; }

        public void SetupData()
        {
            var caseInternalQueryContext = new QueryContextModel
            {
                Name = "Case Search"
            }.In(DbContext).WithKnownId((int)QueryContext.CaseSearch);

            var caseExternalQueryContext = new QueryContextModel
            {
                Name = "Case Search - External"
            }.In(DbContext).WithKnownId((int)QueryContext.CaseSearchExternal);

            var adHocDateQueryContext = new QueryContextModel
            {
                Name = "Ad Hoc Date Search"
            }.In(DbContext).WithKnownId((int)QueryContext.AdHocDateSearch);

            var columnId = new[] { 1, 2, 3 };
            var contextId = caseInternalQueryContext.Id;
            var externalContextId = caseExternalQueryContext.Id;
            var dataItemId = new[] { 1, 2, 3 };

            new QueryContextColumn { ColumnId = columnId[0], ContextId = contextId, IsMandatory = true, IsSortOnly = true }.In(DbContext);
            new QueryContextColumn { ColumnId = columnId[0], ContextId = adHocDateQueryContext.Id, IsMandatory = true, IsSortOnly = true }.In(DbContext);
            new QueryContextColumn { ColumnId = columnId[1], ContextId = contextId, IsMandatory = true, IsSortOnly = false }.In(DbContext);
            new QueryContextColumn { ColumnId = columnId[2], ContextId = externalContextId, GroupId = Fixture.Integer() }.In(DbContext);

            new TableCodeBuilder { TableType = (int)TableTypes.DataFormat, TableCode = (int)KnownColumnFormat.Text, Description = "Text"}.Build().In(DbContext);
            new TableCodeBuilder { TableType = (int)TableTypes.DataFormat, TableCode = (int)KnownColumnFormat.Integer, Description = "Integer" }.Build().In(DbContext);

            new QueryDataItem { DataItemId = dataItemId[0], QualifierType = null, DataFormatId = (int)KnownColumnFormat.Text, ProcedureItemId = "csw_ListCase"}.In(DbContext);
            new QueryDataItem { DataItemId = dataItemId[1], QualifierType = null, DataFormatId = (int)KnownColumnFormat.Integer, SortDirection = "A", ProcedureItemId = "csw_ListCase" }.In(DbContext);

            new QueryColumn { ColumnId = columnId[0], DataItemId = dataItemId[0], Qualifier = null, ColumnLabel = "Activity Category", Description = "Action Category" }.In(DbContext);
            new QueryColumn { ColumnId = columnId[1], DataItemId = dataItemId[0], Qualifier = null, ColumnLabel = "Category", Description = "The Activity Category" }.In(DbContext);
            new QueryColumn { ColumnId = columnId[2], DataItemId = dataItemId[1], Qualifier = null, ColumnLabel = Fixture.String("Act"), Description = Fixture.String("Description") }.In(DbContext);
        }

    }
}