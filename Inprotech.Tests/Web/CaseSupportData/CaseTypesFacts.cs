using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Tests.Web.Search.CaseSupportData;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class CaseTypesFacts 
    {
        public static CaseTypeListItem BuildCaseTypeListItem(string key = null, string description = null)
        {
            return new CaseTypeListItemBuilder
                {
                    CaseTypeKey = key,
                    CaseTypeDescription = description
                }
                .Build();
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void ShouldForwardCorrectSqlParameters()
            {
                var fixture = new CaseTypesFixture();

                var user = new UserBuilder(Db) {IsExternalUser = true}.Build();
                fixture.WithUser(user)
                        .WithCulture("a")
                        .WithSqlResults(BuildCaseTypeListItem(string.Empty, string.Empty));

                fixture.Subject.Get();

                fixture.DbContext.Received(1).SqlQuery<CaseTypeListItem>(
                                                                          FixtureBase.ListCaseSupportCommand,
                                                                          user.Id,
                                                                          "a",
                                                                          "CaseTypeWithCRM",
                                                                          null,
                                                                          1,
                                                                          user.IsExternalUser);
            }

            [Fact]
            public void ShouldGetCaseTypes()
            {
                var fixture = new CaseTypesFixture();

                var user = new UserBuilder(Db).Build();
                fixture
                    .WithCulture("a")
                    .WithUser(user)
                    .WithSqlResults(BuildCaseTypeListItem("k", "d"));

                var r = fixture.Subject.Get().Single();

                Assert.Equal("k", r.Key);
                Assert.Equal("d", r.Value);
            }
        }

        public class IncludeDraftCaseTypesMethod : FactBase
        {
            [Fact]
            public void ShouldReturnDraftCasesForInternalUser()
            {
                var fixture = new CaseTypesFixture();

                new CaseTypeBuilder {ActualCaseTypeId = Fixture.String()}.Build().In(Db);

                var user = new UserBuilder(Db).Build();
                fixture
                    .WithCulture("a")
                    .WithUser(user)
                    .WithSqlResults(BuildCaseTypeListItem("k", "d"));

                fixture.DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().Returns(Db.Set<InprotechKaizen.Model.Cases.CaseType>());

                var r = fixture.Subject.IncludeDraftCaseTypes().ToArray();

                Assert.Equal(2,r.Length);
            }

            [Fact]
            public void ShouldNotReturnDraftCasesForExternalUser()
            {
                var fixture = new CaseTypesFixture();

                new CaseTypeBuilder {ActualCaseTypeId = Fixture.String()}.Build().In(Db);

                var user = new UserBuilder(Db) {IsExternalUser = true}.Build();
                fixture
                    .WithCulture("a")
                    .WithUser(user)
                    .WithSqlResults(BuildCaseTypeListItem("k", "d"));

                fixture.DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().Returns(Db.Set<InprotechKaizen.Model.Cases.CaseType>());

                var r = fixture.Subject.IncludeDraftCaseTypes().ToArray();

                Assert.Single(r);
                Assert.Equal("k", r[0].Key);
                Assert.Equal("d", r[0].Value);
            }
        }
    }

    public class CaseTypesFixture : FixtureBase, IFixture<ICaseTypes>
    {
        public ICaseTypes Subject => new CaseTypes(
                                                   DbContext,
                                                   SecurityContext,
                                                   PreferredCultureResolver);

    }
}