using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Configuration.Rules.Checklists;
using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.Checklists;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.Checklists
{
    public class ChecklistConfigurationSearchControllerFacts
    {
        public class GetViewData : FactBase
        {
            [Theory]
            [InlineData(true, true, true)]
            [InlineData(true, false, true)]
            [InlineData(false, true, true)]
            [InlineData(false, false, true)]
            [InlineData(true, true, false)]
            [InlineData(true, false, false)]
            [InlineData(false, true, false)]
            [InlineData(false, false, false)]
            public void ChecksRuleMaintenanceTaskSecurityAndOffices(bool canMaintainProtectedRules, bool canMaintainRules, bool hasOffices)
            {
                var f = new ChecklistSearchControllerFixture(Db, canMaintainProtectedRules, canMaintainRules, hasOffices);
                var result = f.Subject.GetViewData();
                Assert.Equal(canMaintainProtectedRules, result.CanMaintainProtectedRules);
                Assert.Equal(canMaintainRules, result.CanMaintainRules);
            }

            [Theory]
            [InlineData(true, false)]
            [InlineData(false, true)]
            [InlineData(false, false)]
            public void ChecksRuleCreationTasks(bool canAddProtectedRules, bool canAddRules)
            {
                var f = new ChecklistSearchControllerFixture(Db, canAddRules: canAddRules, canAddProtectedRules: canAddProtectedRules);
                var result = f.Subject.GetViewData();
                Assert.Equal(canAddProtectedRules, result.CanAddProtectedRules);
                Assert.Equal(canAddRules, result.CanAddRules);
            }
        }

        public class Search : FactBase
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
                var filter = new SearchCriteria { MatchType = CriteriaMatchOptions.BestCriteriaOnly };
                var f = new ChecklistSearchControllerFixture(Db);
                var d = new[]
                {
                    new ChecklistConfigurationItem {Id = 123},
                    new ChecklistConfigurationItem {Id = 234, CaseTypeCode = "A"},
                    new ChecklistConfigurationItem {Id = 345, JurisdictionCode = new CountryBuilder().Build().Id}
                };

                f.ChecklistConfigurationSearch.Search(filter).Returns(d);

                var r = f.Subject.Search(filter, cqp);
                var results = ((IEnumerable<dynamic>)r.Data).ToArray();
                Assert.Single((IEnumerable)results); 
                Assert.Equal(123, results.Single().Id);
            }

            [Fact]
            public void ShouldForwardCorrectParametersToSearchService()
            {
                var filter = new SearchCriteria();
                var f = new ChecklistSearchControllerFixture(Db);
                var r = new List<ChecklistConfigurationItem> { new() };

                f.ChecklistConfigurationSearch.Search(filter).Returns(r);
                f.Subject.Search(filter, CommonQueryParameters.Default);
                f.ChecklistConfigurationSearch.Received().Search(filter);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldFirstApplySelectedSortThenByBestFit(bool bestCriteriaOnly)
            {
                var filter = new SearchCriteria { MatchType = bestCriteriaOnly ? CriteriaMatchOptions.BestCriteriaOnly : CriteriaMatchOptions.BestMatch};
                var f = new ChecklistSearchControllerFixture(Db);
                var d = new[]
                {
                    new ChecklistConfigurationItem {Id = 123, CriteriaName = "AAA", BestFit = "100"},
                    new ChecklistConfigurationItem {Id = 124, CriteriaName = "AAA", BestFit = "110"},
                    new ChecklistConfigurationItem {Id = 234, CriteriaName = "BBB", BestFit = "111", CaseTypeCode = "A"},
                    new ChecklistConfigurationItem {Id = 345, CriteriaName = "CCC", BestFit = "010", JurisdictionCode = new CountryBuilder().Build().Id}
                };

                f.ChecklistConfigurationSearch.Search(filter).Returns(d);
                var r = f.Subject.Search(filter, new CommonQueryParameters {Take = 5, Skip = 0, SortBy = "CriteriaName"});
                var results = ((IEnumerable<dynamic>)r.Data).ToArray();
                f.ChecklistConfigurationSearch.Received().Search(filter);
                if (bestCriteriaOnly)
                {
                    Assert.Single((IEnumerable)results); 
                    Assert.Equal(123, results.Single().Id);
                }
                else
                {
                    Assert.Equal(4, results.Length); 
                    Assert.Equal(124, results[0].Id);
                    Assert.Equal(123, results[1].Id);
                    Assert.Equal(234, results[2].Id);
                    Assert.Equal(345, results[3].Id);
                }
            }

            [Fact]
            public void ReturnsExactMatchesSearch()
            {
                var param = new CommonQueryParameters { Take = 5, Skip = 0, SortBy = "Id", SortDir = "desc" };
                var filter = new SearchCriteria
                {
                    MatchType = CriteriaMatchOptions.ExactMatch,
                    Checklist = new ChecklistBuilder().Build().Id
                };
                var f = new ChecklistSearchControllerFixture(Db);
                var d = new[]
                {
                    new ChecklistConfigurationItem {Id = 123, ChecklistTypeCode = filter.Checklist },
                    new ChecklistConfigurationItem {Id = 234, ChecklistTypeCode = filter.Checklist, CaseTypeCode = "A"},
                    new ChecklistConfigurationItem {Id = 345, ChecklistTypeCode = filter.Checklist, JurisdictionCode = new CountryBuilder().Build().Id}
                };
                f.ChecklistConfigurationSearch.Search(filter).Returns(d);

                var r = f.Subject.Search(filter, param);
                Assert.Equal(3, r.Pagination.Total);
                Assert.Equal(345, ((IEnumerable<dynamic>)r.Data).ToArray()[0].Id);
                Assert.Equal(123, ((IEnumerable<dynamic>)r.Data).ToArray()[2].Id);
            }
        }

        public class SearchByIds : FactBase
        {
            [Fact]
            public void ReturnsReturnsForChecklistCriteriaIds()
            {
                var param = new CommonQueryParameters { Take = 5, Skip = 0, SortBy = "Id", SortDir = "asc" };
                var d = new[]
                {
                    new ChecklistConfigurationItem {Id = 123, ChecklistTypeCode = Fixture.Short(), CaseTypeDescription = Fixture.String("checklist 1")},
                    new ChecklistConfigurationItem {Id = 234, ChecklistTypeCode = Fixture.Short(), CaseTypeDescription = Fixture.String("checklist 2"), CaseTypeCode = "A"},
                    new ChecklistConfigurationItem {Id = 345, ChecklistTypeCode = Fixture.Short(), CaseTypeDescription = Fixture.String("checklist 3"), JurisdictionCode = new CountryBuilder().Build().Id}
                };
                var ids = d.Select(v => v.Id).ToArray();
                var f = new ChecklistSearchControllerFixture(Db);
                f.ChecklistConfigurationSearch.Search(Arg.Any<int[]>()).Returns(d);
                var r = f.Subject.SearchByIds(ids, param);

                f.ChecklistConfigurationSearch.Received().Search(ids);
                Assert.Equal(123, ((IEnumerable<dynamic>)r.Data).ToArray()[0].Id);
                Assert.Equal(345, ((IEnumerable<dynamic>)r.Data).ToArray()[2].Id);
            }
        }
    }

    public class ChecklistSearchControllerFixture : IFixture<ChecklistConfigurationSearchController>
    {
        public ChecklistSearchControllerFixture(InMemoryDbContext dbContext, bool canMaintainProtectedRules = true, bool canMaintainRules = true, bool hasOffices = true, bool canAddProtectedRules = true, bool canAddRules = true)
        {
            if (hasOffices) new OfficeBuilder().Build().In(dbContext);

            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules).Returns(canMaintainProtectedRules);
            TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules).Returns(canMaintainRules);
            TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCpassRules, ApplicationTaskAccessLevel.Create).Returns(canAddProtectedRules);
            TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainRules, ApplicationTaskAccessLevel.Create).Returns(canAddRules);
            CommonQueryService = new CommonQueryService();
            ChecklistConfigurationSearch = Substitute.For<IChecklistConfigurationSearch>();
            Subject = new ChecklistConfigurationSearchController(dbContext, TaskSecurityProvider, CommonQueryService, ChecklistConfigurationSearch);
        }

        public IChecklistConfigurationSearch ChecklistConfigurationSearch { get; set; }
        public ICommonQueryService CommonQueryService { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public ChecklistConfigurationSearchController Subject { get; }
    }
}
