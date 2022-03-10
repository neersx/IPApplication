using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowSearchControllerFacts
    {
        public class TypeaheadSearchMethod : FactBase
        {
            static readonly CommonQueryParameters QueryParameters = new CommonQueryParameters {Skip = 0, SortBy = "Id", SortDir = "asc", Take = 10};

            [Fact]
            public void OrdersById()
            {
                var f = new WorkflowSearchControllerFixture(Db);
                new CriteriaBuilder {Id = Fixture.Integer()}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = Fixture.Integer()}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = Fixture.Integer()}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.TypeaheadSearch(string.Empty, QueryParameters);

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(3, results.Count());
                Assert.True(results[0].Id < results[1].Id);
                Assert.True(results[1].Id < results[2].Id);
            }

            [Fact]
            public void ReturnsAllRules()
            {
                var f = new WorkflowSearchControllerFixture(Db);
                var protectedCriteria = new CriteriaBuilder {Id = -123}.ForEventsEntriesRule().Build().In(Db);
                var regularCriteria = new CriteriaBuilder {Id = 0}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.TypeaheadSearch(string.Empty, QueryParameters);

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(2, results.Length);
                Assert.NotNull(results.SingleOrDefault(r => r.Id == regularCriteria.Id));
                Assert.NotNull(results.SingleOrDefault(r => r.Id == protectedCriteria.Id));
            }

            [Fact]
            public void ReturnsExactMatchOnIdFirst()
            {
                var f = new WorkflowSearchControllerFixture(Db);
                var criteriaById =
                    new CriteriaBuilder {Id = 1, Description = "Desc"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = -11, Description = "DescA"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = -12, Description = "DescB"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = -13, Description = "DescC"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = -14, Description = "DescD"}.ForEventsEntriesRule().Build().In(Db);
                new CriteriaBuilder {Id = -15, Description = "DescE"}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.TypeaheadSearch("1", new CommonQueryParameters());

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(6, results.Count());
                Assert.Equal(criteriaById.Id, results.First().Id);
            }

            [Fact]
            public void ReturnsExactMatchOnIdFirstThenWhereIdStartsWith()
            {
                var f = new WorkflowSearchControllerFixture(Db);
                var match1 = new CriteriaBuilder {Id = 160, Description = "DescC"}.ForEventsEntriesRule().Build().In(Db);
                var match2 = new CriteriaBuilder {Id = 1600, Description = "Desc"}.ForEventsEntriesRule().Build().In(Db);
                var match3 = new CriteriaBuilder {Id = 1601, Description = "Desc"}.ForEventsEntriesRule().Build().In(Db);
                var match4 = new CriteriaBuilder {Id = 3160, Description = "DescA"}.ForEventsEntriesRule().Build().In(Db);
                var match5 = new CriteriaBuilder {Id = -160, Description = "DescB"}.ForEventsEntriesRule().Build().In(Db);
                var match6 = new CriteriaBuilder {Id = 2, Description = "Desc160"}.ForEventsEntriesRule().Build().In(Db);
                var match7 = new CriteriaBuilder {Id = 1, Description = "Desc2"}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.TypeaheadSearch("160", new CommonQueryParameters());

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(6, results.Count());
                Assert.Equal(match1.Id, results[0].Id);
                Assert.Equal(match2.Id, results[1].Id);
                Assert.Equal(match3.Id, results[2].Id);
                Assert.Equal(match4.Id, results[3].Id);
                Assert.Equal(match5.Id, results[4].Id);
                Assert.Equal(match6.Id, results[5].Id);
            }

            [Fact]
            public void TakesTake()
            {
                var f = new WorkflowSearchControllerFixture(Db);
                for (var i = 0; i <= 15; i++) new CriteriaBuilder {Id = Fixture.Integer()}.ForEventsEntriesRule().Build().In(Db);

                var result = f.Subject.TypeaheadSearch(string.Empty, QueryParameters);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(10, results.Count());
            }

            [Fact]
            public void WhereIdOrDescriptionContainsQuery()
            {
                var f = new WorkflowSearchControllerFixture(Db);
                var criteriaById =
                    new CriteriaBuilder {Id = 12678912, Description = "Desc"}.ForEventsEntriesRule().Build().In(Db);
                var criteriaByDesc =
                    new CriteriaBuilder {Id = 888, Description = "Six Was Sad Cos 789 Ten"}.ForEventsEntriesRule()
                                                                                           .Build()
                                                                                           .In(Db);

                var result = f.Subject.TypeaheadSearch("789", QueryParameters);

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                Assert.Equal(2, results.Count());
                var r1 = results.SingleOrDefault(r => r.Id == criteriaById.Id);
                var r2 = results.SingleOrDefault(r => r.Description == criteriaByDesc.Description);
                Assert.NotNull(r1);
                Assert.NotNull(r2);
                Assert.Equal(criteriaById.Description, r1.Description);
                Assert.Equal(criteriaByDesc.Id, r2.Id);
            }
        }

        public class SortWorkflowListMethod : FactBase
        {
            [Fact]
            public void OrdersByBestFit()
            {
                var cOffice = new CriteriaBuilder {Id = Fixture.Integer()}
                              .WithOffice().Build().AsCriteriaSearchListItem();
                var cCaseType = new CriteriaBuilder {Id = Fixture.Integer()}
                                .WithCaseType().Build().AsCriteriaSearchListItem();
                var cJurisdiction = new CriteriaBuilder {Id = Fixture.Integer(), Country = new CountryBuilder().Build()}
                                    .Build().AsCriteriaSearchListItem();

                cOffice.BestFit = "101";
                cCaseType.BestFit = "111";
                cJurisdiction.BestFit = "100";

                var result = WorkflowSearchController.SortWorkflowList(new[] {cOffice, cCaseType, cJurisdiction},
                                                                       new CommonQueryParameters {Skip = 0, Take = 10});

                var results = ((IEnumerable<dynamic>) result).ToArray();

                // should be ordered in order of best fit

                Assert.Equal(3, results.Length);
                Assert.Equal(cCaseType.Id, results[0].Id);
                Assert.Equal(cOffice.Id, results[1].Id);
                Assert.Equal(cJurisdiction.Id, results[2].Id);
            }

            [Fact]
            public void OrdersByDescription()
            {
                var criteria1 = new CriteriaBuilder {Id = Fixture.Integer(), Country = new Country("NZ", "New Zealand")}
                                .ForEventsEntriesRule().Build().AsCriteriaSearchListItem();
                var criteria2 =
                    new CriteriaBuilder {Id = Fixture.Integer(), Country = new Country("GB", "United Kingdom")}
                        .ForEventsEntriesRule().Build().AsCriteriaSearchListItem();

                var result = WorkflowSearchController.SortWorkflowList(new[] {criteria2, criteria1},
                                                                       new CommonQueryParameters {SortBy = "jurisdiction", SortDir = "asc", Skip = 0, Take = 10});

                var results = ((IEnumerable<dynamic>) result).ToArray();

                Assert.Equal(2, results.Count());
                Assert.Equal(criteria1.Id, results[0].Id);
                Assert.Equal(criteria2.Id, results[1].Id);
            }
        }

        public class GetPagedResultsMethod : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ProtectsProtectedRulesWithTaskSecurity(bool canEditProtected)
            {
                var f = new WorkflowSearchControllerFixture(Db);
                var protectedCriteria =
                    new CriteriaBuilder {Id = -123, UserDefinedRule = 0}.ForEventsEntriesRule()
                                                                        .Build()
                                                                        .AsCriteriaSearchListItem();
                var regularCriteria =
                    new CriteriaBuilder {Id = 0, UserDefinedRule = 1}.ForEventsEntriesRule()
                                                                     .Build()
                                                                     .AsCriteriaSearchListItem();

                f.PermissionHelper.CanEditProtected().Returns(canEditProtected);

                var result = f.Subject.GetPagedResults(new[] {protectedCriteria, regularCriteria}.OrderBy(_ => _.Id),
                                                       CommonQueryParameters.Default);
                var results = ((IEnumerable<dynamic>) result.Data).ToArray();

                var r = results.Single(_ => _.Id == regularCriteria.Id);
                var p = results.Single(_ => _.Id == protectedCriteria.Id);
                Assert.Equal(canEditProtected, p.CanEdit);
                Assert.True(r.CanEdit);
            }

            [Theory]
            [InlineData(0, 0, false)]
            [InlineData(0, 1, true)]
            [InlineData(1, 0, false)]
            [InlineData(1, 1, false)]
            public void ReturnsIsHighestParent(int isInherited, int isParent, bool expected)
            {
                var f = new WorkflowSearchControllerFixture(Db);
                var criteria = new WorkflowSearchListItem
                {
                    IsInherited = isInherited == 1,
                    IsParent = isParent == 1
                };

                var result = (dynamic) f.Subject.GetPagedResults(new[] {criteria}.OrderBy(_ => _.Id), CommonQueryParameters.Default).Data.Single();
                Assert.Equal(expected, result.IsHighestParent);
            }

            [Fact]
            public void SkipsAndTakesAndReturnsTotal()
            {
                var f = new WorkflowSearchControllerFixture(Db);
                var criteria = new List<WorkflowSearchListItem>();
                for (var i = 0; i <= 15; i++) criteria.Add(new CriteriaBuilder {Id = i}.ForEventsEntriesRule().Build().AsCriteriaSearchListItem());

                var result = f.Subject.GetPagedResults(criteria.OrderBy(_ => _.Id),
                                                       new CommonQueryParameters {SortBy = "id", SortDir = "asc", Skip = 5, Take = 10});
               
                var resultForBestFit = f.Subject.GetPagedResults(criteria.OrderBy(_ => _.Id),
                                                       new CommonQueryParameters {Skip = 0, Take = 1});

                var results = ((IEnumerable<dynamic>) result.Data).ToArray();
                Assert.Equal(10, results.Length);
                Assert.Equal(5, results[0].Id);
                Assert.Equal(16, result.Pagination.Total);
            }
        }

        public class SearchByIdsMethod : FactBase
        {
            [Fact]
            public void ShouldForwardCorrectParametersToCriteriaSearchService()
            {
                var ids = new[] {1, 2};
                var f = new WorkflowSearchControllerFixture(Db);
                var r = new WorkflowSearchListItem[0];

                f.CriteriaSearch.Search(ids).Returns(r);
                f.Subject.SearchByIds(ids, CommonQueryParameters.Default);
                f.CriteriaSearch.Received().Search(ids);
            }

            [Fact]
            public void ShouldGetAllIds()
            {
                var ids = new[] {1, 2};
                var f = new WorkflowSearchControllerFixture(Db);
                var d = new[]
                {
                    new WorkflowSearchListItem {Id = 1},
                    new WorkflowSearchListItem {Id = 2, CaseTypeCode = "A"},
                    new WorkflowSearchListItem {Id = 3, JurisdictionCode = new CountryBuilder().Build().Id}
                };

                f.CriteriaSearch.Search(ids).Returns(d);

                var result =
                    ((IEnumerable<int>)
                        f.Subject.SearchByIds(ids,
                                              CommonQueryParameters.Default.Extend(new CommonQueryParameters {GetAllIds = true}))).ToArray();

                Assert.Equal(d[0].Id, result[0]);
                Assert.Equal(d[1].Id, result[1]);
                Assert.Equal(d[2].Id, result[2]);
            }
        }

        public class SearchMethod : FactBase
        {
            public static IEnumerable<object[]> CommonQueryParamData => new[]
            {
                new object[] {new CommonQueryParameters {Take = 5, Skip = 10, SortBy = "Id"}},
                new object[] {null}
            };

            [Theory]
            [MemberData(nameof(CommonQueryParamData))]
            public void ReturnsOneResultForBestCriteriaOnlySearch(CommonQueryParameters cqp)
            {
                var filter = new SearchCriteria {MatchType = CriteriaMatchOptions.BestCriteriaOnly};
                var f = new WorkflowSearchControllerFixture(Db);

                // stored procedure would return items in this order

                var d = new[]
                {
                    new WorkflowSearchListItem {Id = 123},
                    new WorkflowSearchListItem {Id = 234, CaseTypeCode = "A"},
                    new WorkflowSearchListItem {Id = 345, JurisdictionCode = new CountryBuilder().Build().Id}
                };

                f.CriteriaSearch.Search(filter).Returns(d);

                var r = f.Subject.Search(filter, cqp);
                var results = ((IEnumerable<dynamic>) r.Data).ToArray();
                Assert.Single(results); // because of BestCriteriaOnly option, only one result should be returned
                Assert.Equal(123, results.Single().Id); // regardless of sorting, best reported by stored proc should be returned
                Assert.Equal(1, r.Pagination.Total);
            }

            [Fact]
            public void ShouldForwardCorrectParameters()
            {
                var filter = new SearchCriteria();
                var f = new WorkflowSearchControllerFixture(Db);
                var r = new WorkflowSearchListItem[0];

                f.CriteriaSearch.Search(filter).Returns(r);
                f.Subject.Search(filter, CommonQueryParameters.Default);
                f.CriteriaSearch.Received().Search(filter);
            }

            [Fact]
            public void ShouldGetAllIds()
            {
                var filter = new SearchCriteria();
                var f = new WorkflowSearchControllerFixture(Db);
                var d = new[]
                {
                    new WorkflowSearchListItem {Id = 1},
                    new WorkflowSearchListItem {Id = 2, CaseTypeCode = "A"},
                    new WorkflowSearchListItem {Id = 3, JurisdictionCode = new CountryBuilder().Build().Id}
                };

                f.CriteriaSearch.Search(filter).Returns(d);

                var result =
                    ((IEnumerable<int>)
                        f.Subject.Search(filter,
                                         CommonQueryParameters.Default.Extend(new CommonQueryParameters {GetAllIds = true}))).ToArray();

                Assert.Equal(d[0].Id, result[0]);
                Assert.Equal(d[1].Id, result[1]);
                Assert.Equal(d[2].Id, result[2]);
            }
        }

        public class PrepareCommonQueryParams : FactBase
        {
            [Fact]
            public void ShouldMapSortByDescriptionAndFilterByCode()
            {
                var r = WorkflowSearchController.PrepareCommonQueryParams(new CommonQueryParameters
                {
                    SortBy = "caseType",
                    Filters = new[]
                    {
                        new CommonQueryParameters.FilterValue {Field = "caseType"}
                    }
                });

                Assert.Equal("caseTypeDescription", r.SortBy);
                Assert.Equal("caseTypeCode", r.Filters.Single().Field);
            }

            [Fact]
            public void ShouldSortByDefault()
            {
                var r = WorkflowSearchController.PrepareCommonQueryParams(new CommonQueryParameters());
                Assert.Equal(string.Empty, r.SortBy);
            }
        }

        public class GetFilterData : FactBase
        {
            [Fact]
            public void ShouldCascadeExistingColumnFilters()
            {
                var filter = new SearchCriteria();
                var f = new WorkflowSearchControllerFixture(Db);
                f.CriteriaSearch.Search(filter).Returns(new[]
                {
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "AU",
                        JurisdictionDescription = "Australia",
                        ActionCode = "AL"
                    },
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "JP",
                        JurisdictionDescription = "Japan",
                        ActionCode = "XX"
                    },
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "US",
                        JurisdictionDescription = "United States",
                        ActionCode = "AL"
                    }
                });

                var existingFilters = new CommonQueryParameters.FilterValue {Field = "action", Operator = "in", Value = "AL"};

                var r = f.Subject.GetFilterDataForColumn("jurisdiction", filter, new[] {existingFilters}).ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal("AU", r[0].Code);
                Assert.Equal("US", r[1].Code);
            }

            [Fact]
            public void ShouldCascadeExistingColumnFiltersById()
            {
                var filter = new int[0];
                var f = new WorkflowSearchControllerFixture(Db);
                f.CriteriaSearch.Search(filter).Returns(new[]
                {
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "AU",
                        JurisdictionDescription = "Australia",
                        ActionCode = "AL"
                    },
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "JP",
                        JurisdictionDescription = "Japan",
                        ActionCode = "XX"
                    },
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "US",
                        JurisdictionDescription = "United States",
                        ActionCode = "AL"
                    }
                });

                var existingFilters = new CommonQueryParameters.FilterValue {Field = "action", Operator = "in", Value = "AL"};

                var r = f.Subject.GetFilterDataForColumnByIds("jurisdiction", filter, new[] {existingFilters}).ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal("AU", r[0].Code);
                Assert.Equal("US", r[1].Code);
            }

            [Fact]
            public void ShouldGetDistinctFilterData()
            {
                var filter = new SearchCriteria();
                var f = new WorkflowSearchControllerFixture(Db);
                f.CriteriaSearch.Search(filter).Returns(new[]
                {
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "AU",
                        JurisdictionDescription = "Australia"
                    },
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "AU",
                        JurisdictionDescription = "Australia"
                    },
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "US",
                        JurisdictionDescription = "United States"
                    }
                });

                var r = f.Subject.GetFilterDataForColumn("jurisdiction", filter, null).ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal("AU", r[0].Code);
                Assert.Equal("US", r[1].Code);
            }

            [Fact]
            public void ShouldGetDistinctFilterDataForSearchByIds()
            {
                var filter = new[] {1};
                var f = new WorkflowSearchControllerFixture(Db);
                f.CriteriaSearch.Search(filter).Returns(new[]
                {
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "AU",
                        JurisdictionDescription = "Australia"
                    },
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "AU",
                        JurisdictionDescription = "Australia"
                    },
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "US",
                        JurisdictionDescription = "United States"
                    }
                });

                var r = f.Subject.GetFilterDataForColumnByIds("jurisdiction", filter, null).ToArray();
                Assert.Equal(2, r.Length);
                Assert.Equal("AU", r[0].Code);
                Assert.Equal("US", r[1].Code);
            }

            [Fact]
            public void ShouldReturnNullFilterValueAsFirstItem()
            {
                var filter = new SearchCriteria();
                var f = new WorkflowSearchControllerFixture(Db);
                f.CriteriaSearch.Search(filter).Returns(new[]
                {
                    new WorkflowSearchListItem
                    {
                        JurisdictionCode = "AU",
                        JurisdictionDescription = "Australia"
                    },
                    new WorkflowSearchListItem(),
                    new WorkflowSearchListItem()
                });

                var r = f.Subject.GetFilterDataForColumn("jurisdiction", filter, null).ToArray();
                Assert.Equal(2, r.Length);
                Assert.Null(r[0].Code);
                Assert.Equal("AU", ((dynamic) r[1]).Code);
            }
        }

        public class GetViewData : FactBase
        {
            [Fact]
            public void ShouldReturnHasOfficesFalse()
            {
                var f = new WorkflowSearchControllerFixture(Db);

                var r = f.Subject.GetViewData();
                Assert.False(r.HasOffices);
            }

            [Fact]
            public void ShouldReturnHasOfficesTrue()
            {
                new Office().In(Db);

                var f = new WorkflowSearchControllerFixture(Db);

                var r = f.Subject.GetViewData();
                Assert.True(r.HasOffices);
            }

            [Fact]
            public void ShouldReturnMaintainWorkflowRulesProtected()
            {
                var f = new WorkflowSearchControllerFixture(Db);

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected).Returns(true);

                var r = f.Subject.GetViewData();
                Assert.True(r.MaintainWorkflowRulesProtected);

                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected).Returns(false);

                r = f.Subject.GetViewData();
                Assert.False(r.MaintainWorkflowRulesProtected);
            }
        }

        public class WorkflowSearchControllerFixture : IFixture<WorkflowSearchController>
        {
            public WorkflowSearchControllerFixture(InMemoryDbContext db)
            {
                CharacteristicsValidator = Substitute.For<ICharacteristicsValidator>();
                CriteriaSearch = Substitute.For<IWorkflowSearch>();
                CommonQueryService = new CommonQueryService();
                CharacteristicsService = Substitute.For<ICharacteristicsService>();
                PermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                Subject = new WorkflowSearchController(db, CriteriaSearch,
                                                       CommonQueryService, PermissionHelper, TaskSecurityProvider);
            }

            public ICharacteristicsValidator CharacteristicsValidator { get; set; }

            public IWorkflowSearch CriteriaSearch { get; set; }

            public ICommonQueryService CommonQueryService { get; set; }

            public ICharacteristicsService CharacteristicsService { get; set; }

            public IWorkflowPermissionHelper PermissionHelper { get; set; }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public WorkflowSearchController Subject { get; }
        }
    }
}