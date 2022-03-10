using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Security;
using NSubstitute;
using System.Linq;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class RolesPicklistControllerFacts : FactBase
    {
        [Fact]
        public void SearchesForRolesIn()
        {
            var f = new RolesPicklistControllerFixture(Db);

            new Role {RoleName = "bcd", IsExternal = true}.In(Db);
            new Role {RoleName = "abc", IsExternal = false}.In(Db);
            var r3 = new Role {RoleName = "def", IsExternal = false}.In(Db);

            var r = f.Subject.Search(null, "b");

            var j = (RolesPicklistController.RolesPicklistItem[]) r.Data;

            Assert.Equal(2, j.Length);
            Assert.DoesNotContain(j, _ => _.Value.Equals(r3.RoleName));
        }

        [Fact]
        public void SearchesForRolesInOrderByValue()
        {
            var f = new RolesPicklistControllerFixture(Db);

            var r1 = new Role {RoleName = "bcd", IsExternal = false}.In(Db);
            var r2 = new Role {RoleName = "abc", IsExternal = false}.In(Db);
            var r3 = new Role {RoleName = "def", IsExternal = true}.In(Db);

            var r = f.Subject.Search(null, null);

            var j = (RolesPicklistController.RolesPicklistItem[]) r.Data;

            Assert.Equal(3, j.Length);
            Assert.Equal(r2.RoleName, j.First().Value);
            Assert.False(j.First().IsExternal);
            Assert.Equal(r3.RoleName, j.Last().Value);
            Assert.True(j.Last().IsExternal);
        }
    }

    public class RolesPicklistControllerFixture : IFixture<RolesPicklistController>
    {
        public RolesPicklistControllerFixture(InMemoryDbContext db)
        {
            CultureResolver = Substitute.For<IPreferredCultureResolver>();

            Subject = new RolesPicklistController(db, CultureResolver);
        }

        public IPreferredCultureResolver CultureResolver { get; set; }

        public RolesPicklistController Subject { get; }
    }
}
