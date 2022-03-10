using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Tests.Web.Search.CaseSupportData;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.CaseSupportData
{
    public class CaseStatusesFacts
    {
        public class GetMethodWithStatusAttributes : FactBase
        {
            void Setup()
            {
                new Status(1, "abc")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = null,
                    LiveFlag = 1
                }.In(Db);

                new Status(2, "zzz")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = 1,
                    LiveFlag = null
                }.In(Db);

                new Status(3, "f")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = null,
                    LiveFlag = 0
                }.In(Db);
            }

            [Fact]
            public void ShouldFilterDescription()
            {
                var f = new CaseStatusesFixture(Db);

                Setup();

                var r = f.Subject.Get("z", false, false, false, false).Single();

                Assert.Equal(2, r.Key);
            }

            [Fact]
            public void ShouldFilterRenewal()
            {
                var f = new CaseStatusesFixture(Db);

                Setup();

                new Status(4, "f")
                {
                    RenewalFlag = 1
                }.In(Db);

                var r = f.Subject.Get(string.Empty, true, false, false, false).Single();

                Assert.Equal(4, r.Key);
            }

            [Fact]
            public void ShouldFilterStatus()
            {
                var f = new CaseStatusesFixture(Db);

                Setup();

                var r = f.Subject.Get(string.Empty,
                                      false,
                                      true,
                                      false,
                                      false).Single();

                Assert.Equal(1, r.Key);
            }
        }

        public class GetAllStatusesMethod : FactBase
        {
            void Setup()
            {
                new Status(1, "abc")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = null,
                    LiveFlag = 1
                }.In(Db);

                new Status(2, "zzz")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = 1,
                    LiveFlag = null
                }.In(Db);

                new Status(3, "f")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = null,
                    LiveFlag = 0
                }.In(Db);
            }

            [Fact]
            public void ShouldReturnAllStatuses()
            {
                var f = new CaseStatusesFixture(Db);

                Setup();

                var result = f.Subject.GetAllStatuses();

                Assert.Equal(3, result.Count());
            }

            [Fact]
            public void ShouldSortByDescription()
            {
                var f = new CaseStatusesFixture(Db);

                Setup();

                var r = f.Subject.Get(string.Empty, false, false, false, false).ToArray();

                Assert.Equal("abc", r.First().Value);
                Assert.Equal("zzz", r.Last().Value);
            }
        }

        public class GetMethodForValidStatus : FactBase
        {
            void Setup()
            {
                new Status(1, "abc")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = null,
                    LiveFlag = 1
                }.In(Db);

                new Status(2, "zzz")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = 1,
                    LiveFlag = null
                }.In(Db);

                new Status(3, "f")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = null,
                    LiveFlag = 0
                }.In(Db);
            }

            [Theory]
            [InlineData("", "a", "a")]
            [InlineData("a", "", "a")]
            [InlineData("a", "a", "")]
            [InlineData("a", "a,b", "a")]
            [InlineData("a", "a", "a,b")]
            public void ShouldReturnAllWhenNotValidStatusKey(string caseType, string countries, string propertyTypes)
            {
                var f = new CaseStatusesFixture(Db);

                Setup();

                var results = f.Subject.Get(
                                            caseType,
                                            countries.SplitCommaSeparateValues(),
                                            propertyTypes.SplitCommaSeparateValues()).ToArray();

                var baseStatusKeys = Db.Set<Status>().Select(s => s.Id);
                Assert.Equal(3, results.Length);
                Assert.True(results.All(r => baseStatusKeys.Contains(r.StatusKey)));
            }

            static ValidStatusListItem BuildValidStatus(
                short key,
                string caseType,
                string country,
                string propertyType,
                bool isDefaultCountry, bool? isDead = null)
            {
                return new StatusListItemBuilder
                {
                    StatusKey = key,
                    CaseTypeKey = caseType,
                    CountryKey = country,
                    PropertyTypeKey = propertyType,
                    IsDefaultCountry = isDefaultCountry,
                    IsDead = isDead
                }.Build();
            }

            [Fact]
            public void ShouldFilterByCaseTypeAndCountryPropertyType()
            {
                var f = (CaseStatusesFixture) new CaseStatusesFixture(Db)
                                              .WithValidStatus(BuildValidStatus(1, "A", "US", "P", false, true), BuildValidStatus(2, "A", "NZ", "D", false, true), BuildValidStatus(3, "A", "ZZZ", "T", true, true))
                                              .WithUser(new UserBuilder(Db).Build())
                                              .WithCulture(string.Empty);

                var results = f.Subject.Get("A", new[] {"US"}, new[] {"P"});

                Assert.Equal(1, results.Single().StatusKey);
            }

            [Fact]
            public void ShouldFilterByDefaultCountryIfNoResultsFoundBySpecifiedCountry()
            {
                var f = (CaseStatusesFixture) new CaseStatusesFixture(Db)
                                              .WithValidStatus(BuildValidStatus(1, "A", "US", "P", false, true), BuildValidStatus(2, "A", "NZ", "D", false, true), BuildValidStatus(3, "A", "ZZZ", "T", true, true))
                                              .WithUser(new UserBuilder(Db).Build()).WithCulture(string.Empty);

                var results = f.Subject.Get("A", new[] {"US"}, new[] {"T"});

                Assert.Equal(3, results.Single().StatusKey);
            }
        }

        public class IsValidMethod : FactBase
        {
            void Setup()
            {
                new Status(1, "abc")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = null,
                    LiveFlag = 1
                }.In(Db);

                new Status(2, "zzz")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = 1,
                    LiveFlag = null
                }.In(Db);

                new Status(3, "f")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = null,
                    LiveFlag = 0
                }.In(Db);

                new Status(4, "xyz")
                {
                    RenewalFlag = 0,
                    RegisteredFlag = null,
                    LiveFlag = 0
                }.In(Db);
            }

            [Theory]
            [InlineData("", "a", "a")]
            [InlineData("a", "", "a")]
            [InlineData("a", "a", "")]
            [InlineData("a", "a,b", "a")]
            [InlineData("a", "a", "a,b")]
            public void ReturnsInvalidWhenNotValid(string caseType, string countries, string propertyTypes)
            {
                var f = new CaseStatusesFixture(Db);

                Setup();

                var result = f.Subject.IsValid(1,
                                               caseType,
                                               countries.SplitCommaSeparateValues(),
                                               propertyTypes.SplitCommaSeparateValues());

                Assert.False(result.IsValid);
            }

            [Theory]
            [InlineData((short) 1, true)]
            [InlineData((short) 2, false)]
            [InlineData((short) 3, false)]
            [InlineData((short) 4, false)]
            public void ReturnsTrueWithCaseTypeCountryPropertyTypeMatch(short id, bool expected)
            {
                var f = (CaseStatusesFixture) new CaseStatusesFixture(Db)
                                              .WithValidStatus(BuildValidStatus(1, "A", "US", "P", false), BuildValidStatus(2, "A", "NZ", "D", false), BuildValidStatus(3, "A", "ZZZ", "T", true))
                                              .WithUser(new UserBuilder(Db).Build())
                                              .WithCulture(string.Empty);

                var result = f.Subject.IsValid(id, "A", new[] {"US"}, new[] {"P"});

                Assert.Equal(expected, result.IsValid);
            }

            [Theory]
            [InlineData((short) 1, false)]
            [InlineData((short) 2, false)]
            [InlineData((short) 3, true)]
            [InlineData((short) 4, false)]
            public void ReturnsTrueIfNoResultsFoundBySpecifiedCountry(short id, bool expected)
            {
                var f = (CaseStatusesFixture) new CaseStatusesFixture(Db)
                                              .WithValidStatus(BuildValidStatus(1, "A", "US", "P", false), BuildValidStatus(2, "A", "NZ", "D", false), BuildValidStatus(3, "A", "ZZZ", "T", true))
                                              .WithUser(new UserBuilder(Db).Build()).WithCulture(string.Empty);

                var result = f.Subject.IsValid(id, "A", new[] {"US"}, new[] {"T"});

                Assert.Equal(expected, result.IsValid);
            }

            static ValidStatusListItem BuildValidStatus(
                short key,
                string caseType,
                string country,
                string propertyType,
                bool isDefaultCountry)
            {
                return new StatusListItemBuilder
                {
                    StatusKey = key,
                    CaseTypeKey = caseType,
                    CountryKey = country,
                    PropertyTypeKey = propertyType,
                    IsDefaultCountry = isDefaultCountry
                }.Build();
            }
        }

        public class CaseStatusesFixture : FixtureBase
        {
            public CaseStatusesFixture(InMemoryDbContext db)
            {
                SecurityContext.User.Returns(new UserBuilder(db).Build());

                ValidStatuses = Substitute.For<IValidStatuses>();

                Subject = new CaseStatuses(
                                           db,
                                           SecurityContext,
                                           PreferredCultureResolver,
                                           ValidStatuses);
            }

            public IValidStatuses ValidStatuses { get; set; }

            public ICaseStatuses Subject { get; }

            public CaseStatusesFixture WithValidStatus(params ValidStatusListItem[] items)
            {
                ValidStatuses.All(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<bool?>())
                             .Returns(items);

                return this;
            }
        }
    }
}