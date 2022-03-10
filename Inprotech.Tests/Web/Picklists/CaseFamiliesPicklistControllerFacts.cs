using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class CaseFamiliesPicklistControllerFacts
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsCaseFamilies()
            {
                var f = new CaseFamiliesPicklistControllerFixture(Db);
                f.Setup(Db);

                var r = f.Subject.Get();
                var families = r.Data.OfType<CaseFamily>().ToArray();

                Assert.Equal(3, families.Length);
                Assert.Contains("A", families.Select(_ => _.Key));
                Assert.Contains("B", families.Select(_ => _.Key));
                Assert.Contains("C", families.Select(_ => _.Key));
            }

            [Fact]
            public void ReturnsCaseFamiliesContainingMatchingDescription()
            {
                var f = new CaseFamiliesPicklistControllerFixture(Db);
                f.Setup(Db);

                var r = f.Subject.Get(null, "C");
                var families = r.Data.OfType<CaseFamily>().ToArray();

                Assert.Equal(2, families.Length);
                Assert.Equal("C", families.First().Key);
                Assert.Equal("A Family C", families.First().Value);
                Assert.Equal("A", families.Last().Key);
                Assert.Equal("C Family A", families.Last().Value);
            }

            [Fact]
            public void ReturnsUniqueCaseFamilies()
            {
                var f = new CaseFamiliesPicklistControllerFixture(Db);
                var families = f.Setup(Db).ToArray();
                var case1 = new CaseBuilder().Build().In(Db);
                var case2 = new CaseBuilder().Build().In(Db);
                case1.Family = families.First();
                case1.FamilyId = families.First().Id;
                case2.Family = families.First();
                case2.FamilyId = families.First().Id;

                var r = f.Subject.Get();
                var result = r.Data.OfType<CaseFamily>().ToArray();

                Assert.Equal(3, result.Length);
            }

            [Fact]
            public void ReturnsFilteredListForExternalUsers()
            {
                var f = new CaseFamiliesPicklistControllerFixture(Db, true);
                var families = f.Setup(Db).ToArray();
                var @case = new CaseBuilder().Build().In(Db);
                @case.Family = families.First();
                @case.FamilyId = families.First().Id;
                new FilteredUserCase { CaseId = @case.Id }.In(Db);

                var r = f.Subject.Get();
                var result = r.Data.OfType<CaseFamily>().ToArray();

                Assert.Single(result);
                Assert.Equal(families.First().Id, result.First().Key);
            }
        }

        public class MetadataMethod : FactBase
        {
            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new CaseFamiliesPicklistControllerFixture(Db).Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("Metadata").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("CaseFamily", picklistAttribute.Name);
            }
        }
    }

    public class CaseFamiliesPicklistControllerFixture : IFixture<CaseFamiliesPicklistController>
    {
        public CaseFamiliesPicklistControllerFixture(InMemoryDbContext db, bool forExternal = false)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            SecurityContext = Substitute.For<ISecurityContext>();
            SecurityContext.User.Returns(new UserBuilder(db) { IsExternalUser = forExternal }.Build());
            Subject = new CaseFamiliesPicklistController(db, SecurityContext, PreferredCultureResolver);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public CaseFamiliesPicklistController Subject { get; }

        public IEnumerable<Family> Setup(InMemoryDbContext db)
        {
            var family1 = new Family("C", "A Family C").In(db);
            var family2 = new Family("A", "C Family A").In(db);
            var family3 = new Family("B", "B Family B").In(db);

            return new[] { family1, family2, family3 };
        }
    }
}