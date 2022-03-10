using System.Collections.Generic;
using System.Linq;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases;
using Inprotech.Web.Configuration.Rules.ValidCharacteristic;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ScreenDesigner.Cases
{
    public class CaseScreenDesignerSearchControllerFacts : FactBase
    {
        public class GetViewData : FactBase
        {
            [Fact]
            public void ChecksTaskSecurityProvider()
            {
                var fixture = new CaseScreenDesignerControllerFixture(Db);

                fixture.Subject.GetViewData();

                fixture.TaskSecurityProvider.Received(1).HasAccessTo(ApplicationTask.MaintainCpassRules);
            }

            [Fact]
            public void ReturnsOfficesEqualsTrueIfOffices()
            {
                new Office().In(Db);
                var fixture = new CaseScreenDesignerControllerFixture(Db);

                var viewData = fixture.Subject.GetViewData();

                Assert.True(viewData.HasOffices);
            }

            [Fact]
            public void ReturnsOfficesEqualsFalseIfNoOffices()
            {
                var fixture = new CaseScreenDesignerControllerFixture(Db);

                var viewData = fixture.Subject.GetViewData();

                Assert.False(viewData.HasOffices);
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
                var filter = new SearchCriteria {MatchType = CriteriaMatchOptions.BestCriteriaOnly};
                var f = new CaseScreenDesignerControllerFixture(Db);

                // stored procedure would return items in this order

                var d = new[]
                {
                    new CaseScreenDesignerListItem {Id = 123},
                    new CaseScreenDesignerListItem {Id = 234, CaseTypeCode = "A"},
                    new CaseScreenDesignerListItem {Id = 345, JurisdictionCode = new CountryBuilder().Build().Id}
                };

                f.CaseScreenDesignerSearch.Search(filter).Returns(d);

                var r = f.Subject.Search(filter, cqp);
                var results = ((IEnumerable<dynamic>) r.Data).ToArray();
                Assert.Single(results); // because of BestCriteriaOnly option, only one result should be returned
                Assert.Equal(123, results.Single().Id); // regardless of sorting, best reported by stored proc should be returned
            }

            [Fact]
            public void ShouldForwardCorrectParameters()
            {
                var filter = new SearchCriteria();
                var f = new CaseScreenDesignerControllerFixture(Db);
                var r = new CaseScreenDesignerListItem[0];

                f.CaseScreenDesignerSearch.Search(filter).Returns(r);
                f.Subject.Search(filter, CommonQueryParameters.Default);
                f.CaseScreenDesignerSearch.Received().Search(filter);
            }

            [Fact]
            public void ShouldGetAllIds()
            {
                var filter = new SearchCriteria();
                var f = new CaseScreenDesignerControllerFixture(Db);
                var d = new[]
                {
                    new CaseScreenDesignerListItem {Id = 1},
                    new CaseScreenDesignerListItem {Id = 2, CaseTypeCode = "A"},
                    new CaseScreenDesignerListItem {Id = 3, JurisdictionCode = new CountryBuilder().Build().Id}
                };

                f.CaseScreenDesignerSearch.Search(filter).Returns(d);

                var result =
                    ((IEnumerable<int>)
                        f.Subject.Search(filter,
                                         CommonQueryParameters.Default.Extend(new CommonQueryParameters {GetAllIds = true}))).ToArray();

                Assert.Equal(d[0].Id, result[0]);
                Assert.Equal(d[1].Id, result[1]);
                Assert.Equal(d[2].Id, result[2]);
            }
        }

        public class CaseScreenDesignerControllerFixture : IFixture<CaseScreenDesignerSearchController>
        {
            public CaseScreenDesignerControllerFixture(IDbContext dbContext)
            {
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                CaseScreenDesignerSearch = Substitute.For<ICaseScreenDesignerSearch>();
                PreferredCulture = Substitute.For<IPreferredCultureResolver>();
                CharacteristicsService = Substitute.For<ICharacteristicsService>();
                var characteristicsServiceIndex = Substitute.For<IIndex<string, ICharacteristicsService>>();
                characteristicsServiceIndex[CriteriaPurposeCodes.WindowControl].Returns(CharacteristicsService);
                Program = Substitute.For<IValidatedProgramCharacteristic>();
                PermissionHelper = Substitute.For<ICaseScreenDesignerPermissionHelper>();
                CommonQueryService = new CommonQueryService();
                Subject = new CaseScreenDesignerSearchController(TaskSecurityProvider, dbContext, CaseScreenDesignerSearch, CommonQueryService, PreferredCulture, characteristicsServiceIndex, PermissionHelper,Program);
            }

            public ICharacteristicsService CharacteristicsService { get; set; }

            public ICaseScreenDesignerSearch CaseScreenDesignerSearch { get; set; }

            public IPreferredCultureResolver PreferredCulture { get; set; }

            public ICaseScreenDesignerPermissionHelper PermissionHelper { get; set; }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public IValidatedProgramCharacteristic Program { get; set; }

            public CaseScreenDesignerSearchController Subject { get; }

            public ICommonQueryService CommonQueryService { get; set; }
        }
    }
}