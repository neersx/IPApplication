using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.ScreenDesigner.Cases
{
    public class CaseScreenDesignerSearchFacts : FactBase
    {
        [Fact]
        public void CallsTheCprrectStoredProcedure()
        {
            var fixture = new CaseScreenDesignerSearchFixture(Db);
            var preferredCulture = Fixture.String();
            fixture.PreferredCultureResolver.Resolve().Returns(preferredCulture);
            var searchCriteria = new SearchCriteria
            {
                Action = Fixture.String(),
                ApplyTo = Fixture.String(),
                Basis = Fixture.String(),
                CaseCategory = Fixture.String(),
                CaseProgram = Fixture.String(),
                CaseType = Fixture.String(),
                DateOfLaw = Fixture.String(),
                ExaminationType = Fixture.Integer(),
                IncludeCriteriaNotInUse = Fixture.Boolean(),
                IncludeProtectedCriteria = Fixture.Boolean(),
                Jurisdiction = Fixture.String(),
                MatchType = Fixture.String(),
                Office = Fixture.Integer(),
                Profile = Fixture.String(),
                PropertyType = Fixture.String(),
                RenewalType = Fixture.Integer(),
                SubType = Fixture.String()
            };

            fixture.Subject.Search(searchCriteria);

            fixture.Db.Received(1).CaseScreenDesignerSearch(fixture.SecurityContext.User.Id, preferredCulture, searchCriteria);
            fixture.Db.Received(1).SqlQuery<CaseScreenDesignerListItem>(Arg.Is<string>(s => s.Contains("ipw_CaseScreenDesignerSearch")),
                                                                        fixture.SecurityContext.User.Id,
                                                                        preferredCulture,
                                                                        CriteriaPurposeCodes.WindowControl,
                                                                        searchCriteria.Office,
                                                                        searchCriteria.CaseProgram,
                                                                        searchCriteria.CaseType,
                                                                        searchCriteria.Jurisdiction,
                                                                        searchCriteria.PropertyType,
                                                                        searchCriteria.CaseCategory,
                                                                        searchCriteria.SubType,
                                                                        searchCriteria.Basis,
                                                                        searchCriteria.Profile,
                                                                        searchCriteria.IncludeCriteriaNotInUse ? (bool?)null : true,
                                                                        searchCriteria.MatchType == CriteriaMatchOptions.ExactMatch,
                                                                        searchCriteria.IncludeProtectedCriteria ? (bool?)null : true,
                                                                        null);

        }

        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData(" ")]
        public void ReturnsEmptyIfFieldNullOrEmpty(string column)
        {
            var fixture = new CaseScreenDesignerSearchFixture(Db);
            var filterData = fixture.Subject.GetFilterDataForColumnResult(new List<CaseScreenDesignerListItem>
            {
                new CaseScreenDesignerListItem(),
                new CaseScreenDesignerListItem(),
                new CaseScreenDesignerListItem(),
                new CaseScreenDesignerListItem(),
                new CaseScreenDesignerListItem()
            }, column);

            Assert.Equal(0, filterData.Count());
        }

        [Fact]
        public async Task JurisdictionReturnsOnlyDistinctNonNullOrEmptyValues()
        {

            var fixture = new CaseScreenDesignerSearchFixture(Db);
            var filterData = fixture.Subject.GetFilterDataForColumnResult(new List<CaseScreenDesignerListItem>()
            {
                new CaseScreenDesignerListItem(){JurisdictionDescription = "J1"},
                new CaseScreenDesignerListItem(){JurisdictionDescription = "J2"},
                new CaseScreenDesignerListItem(){JurisdictionDescription = "J3"},
                new CaseScreenDesignerListItem(){JurisdictionDescription = "J3"},
                new CaseScreenDesignerListItem(),
                new CaseScreenDesignerListItem()
            }, "jurisdiction");

            Assert.Equal(3, filterData.Count());
        }

        [Fact]
        public async Task ProgramReturnsOnlyDistinctNonNullOrEmptyValues()
        {

            var fixture = new CaseScreenDesignerSearchFixture(Db);
            var filterData = fixture.Subject.GetFilterDataForColumnResult(new List<CaseScreenDesignerListItem>()
            {
                new CaseScreenDesignerListItem(){JurisdictionDescription = "J1"},
                new CaseScreenDesignerListItem(){JurisdictionDescription = "J2"},
                new CaseScreenDesignerListItem(){JurisdictionDescription = "J3"},
                new CaseScreenDesignerListItem(){JurisdictionDescription = "J3"},
                new CaseScreenDesignerListItem(),
                new CaseScreenDesignerListItem()
            }, "jurisdiction");

            Assert.Equal(3, filterData.Count());
        }

        public class CaseScreenDesignerSearchFixture : IFixture<CaseScreenDesignerSearch>
        {
            public CaseScreenDesignerSearchFixture(InMemoryDbContext db)
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.ReturnsForAnyArgs(new UserBuilder(db).Build());

                Db = Substitute.For<IDbContext>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                CommonQueryService = Substitute.For<ICommonQueryService>();
                CommonQueryService.BuildCodeDescriptionObject(Arg.Any<string>(), Arg.Any<string>()).Returns(_ => new CodeDescription() { Code = _[0] as string, Description = _[1] as string });

                Subject = new CaseScreenDesignerSearch(Db, SecurityContext, PreferredCultureResolver, CommonQueryService);
            }
            public CaseScreenDesignerSearch Subject { get; }
            public ISecurityContext SecurityContext { get; set; }
            public ICommonQueryService CommonQueryService { get; set; }
            public IDbContext Db { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        }
    }
}
