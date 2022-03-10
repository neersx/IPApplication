using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class ProfilePicklistControllerFacts : FactBase
    {
        [Theory]
        [InlineData("pro")]
        [InlineData("fil")]
        [InlineData("ede")]
        [InlineData("script")]
        [InlineData("nam")]
        public async Task ShouldReturnNameContains(string query)
        {
            new Profile(1, "profilename", "profiledescription").In(Db);
            new Profile(2, "zzzzzzzzzzz", "yyyyyyyyyyyy").In(Db);

            var pagedResults = await new ProfilePicklistController(Db, Substitute.For<IPreferredCultureResolver>()).Search(null, query);
            var r = pagedResults.Data.ToArray();

            Assert.Single(r);
            Assert.Equal("profilename", r.First().Name);
            Assert.Equal("profiledescription", r.First().Description);
        }

        [Fact]
        public async Task ShouldReturnsProfilesStartsWithFollowedByContains()
        {
            new Profile(1, "profilename1", "profileDescription1").In(Db);
            new Profile(2, "nameOfProfile2", "profileDescription2").In(Db);
            new Profile(3, "failProfile3", "profileDescription3").In(Db);
            new Profile(4, "failProfile4", "profileDescription4").In(Db);

            var pagedResults = await new ProfilePicklistController(Db, Substitute.For<IPreferredCultureResolver>()).Search(null, "name");
            var r = pagedResults.Data.ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("nameOfProfile2", r.First().Name);
            Assert.Equal("profileDescription2", r.First().Description);

            Assert.Equal("profilename1", r.Last().Name);
            Assert.Equal("profileDescription1", r.Last().Description);
        }
    }
}