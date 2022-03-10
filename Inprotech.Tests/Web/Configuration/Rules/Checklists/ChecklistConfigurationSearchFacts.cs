using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Configuration.Rules.Checklists;
using InprotechKaizen.Model.Components.Configuration.Rules;
using InprotechKaizen.Model.Components.Configuration.Rules.Checklists;
using InprotechKaizen.Model.Components.Configuration.Rules.ScreenDesigner;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules.Checklists
{
    public class ChecklistConfigurationSearchFacts : FactBase
    {
        [Fact]
        public void CallStoredProcedureCorrectly()
        {
            var fixture = new ChecklistConfigurationSearchFixture(Db);
            var preferredCulture = Fixture.String();
            fixture.Culture.Resolve().Returns(preferredCulture);
            var searchCriteria = new SearchCriteria
            {
                ApplyTo = ClientFilterOptions.LocalClients,
                Basis = Fixture.String(),
                CaseCategory = Fixture.String(),
                CaseType = Fixture.String(),
                DateOfLaw = Fixture.String(),
                IncludeProtectedCriteria = Fixture.Boolean(),
                Jurisdiction = Fixture.String(),
                MatchType = Fixture.String(),
                Office = Fixture.Integer(),
                Profile = Fixture.String(),
                PropertyType = Fixture.String(),
                RenewalType = Fixture.Integer(),
                SubType = Fixture.String(),
                Checklist = Fixture.Short(),
                Question = Fixture.Short()
            };

            fixture.Subject.Search(searchCriteria);

            fixture.Db.Received(1).ChecklistConfigurationSearch(fixture.Security.User.Id, preferredCulture, searchCriteria);
            fixture.Db.Received(1).SqlQuery<ChecklistConfigurationItem>(Arg.Is<string>(s => s.Contains("ipw_ChecklistConfigurationSearch")),
                                                                        fixture.Security.User.Id,
                                                                        preferredCulture,
                                                                        CriteriaPurposeCodes.CheckList,
                                                                        searchCriteria.Office,
                                                                        searchCriteria.Checklist,
                                                                        searchCriteria.CaseType,
                                                                        searchCriteria.Jurisdiction,
                                                                        searchCriteria.PropertyType,
                                                                        searchCriteria.CaseCategory,
                                                                        searchCriteria.SubType,
                                                                        searchCriteria.Basis,
                                                                        searchCriteria.Profile,
                                                                        true,
                                                                        searchCriteria.MatchType == CriteriaMatchOptions.ExactMatch,
                                                                        searchCriteria.IncludeProtectedCriteria ? null : true,
                                                                        null,
                                                                        searchCriteria.Question);
        }

        [Fact]
        public void CallStoredProcedureViaCriteriaIdsCorrectly()
        {
            var fixture = new ChecklistConfigurationSearchFixture(Db);
            var preferredCulture = Fixture.String();
            fixture.Culture.Resolve().Returns(preferredCulture);
            var criteriaIds = new[] {Fixture.Integer(), Fixture.Integer(), Fixture.Integer(), Fixture.Integer(), Fixture.Integer()};
            fixture.Subject.Search(criteriaIds);

            fixture.Db.Received(1).ChecklistConfigurationSearchByIds(fixture.Security.User.Id, preferredCulture, criteriaIds);
            fixture.Db.Received(1).SqlQuery<ChecklistConfigurationItem>(Arg.Is<string>(s => s.Contains("ipw_ChecklistConfigurationSearch")),
                                                                        fixture.Security.User.Id,
                                                                        preferredCulture,
                                                                        CriteriaPurposeCodes.CheckList,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        string.Join(",", criteriaIds));
        }

        public class ChecklistConfigurationSearchFixture : IFixture<ChecklistConfigurationSearch>
        {
            public ChecklistConfigurationSearchFixture(InMemoryDbContext db)
            {
                Security= Substitute.For<ISecurityContext>();
                Security.User.ReturnsForAnyArgs(new UserBuilder(db).Build());
                Db = Substitute.For<IDbContext>();
                Culture = Substitute.For<IPreferredCultureResolver>();
                Subject = new ChecklistConfigurationSearch(Db, Culture, Security);
            }
            public IPreferredCultureResolver Culture { get; set; }
            public ISecurityContext Security { get; set; }
            public ChecklistConfigurationSearch Subject { get; set; }
            public IDbContext Db { get; set; }
        }
    }
}
