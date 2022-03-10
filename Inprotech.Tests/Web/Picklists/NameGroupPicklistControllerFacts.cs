using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class NameGroupPicklistControllerFacts : FactBase
    {
        [Theory]
        [InlineData("fam")]
        [InlineData("tit")]
        [InlineData("omm")]
        [InlineData("lyc")]
        public void ShouldReturnFamilyNameContains(string query)
        {
            new NameFamily(1, "familytitle", "familycomments").In(Db);
            new NameFamily(2, "zzzzzzzzzzz", "yyyyyyyyyyyy").In(Db);

            var pagedResults = new NameGroupPicklistController(Db, Substitute.For<IPreferredCultureResolver>()).Search(null, query);
            var r = pagedResults.Data.ToArray();

            Assert.Single(r);
            Assert.Equal("familytitle", r.First().Title);
            Assert.Equal("familycomments", r.First().Comments);
        }

        [Fact]
        public void ShouldReturnsNameFamilySortedByTitle()
        {
            new NameFamily(1, "familytitle1", "familycomments1").In(Db);
            new NameFamily(2, "titleOfFamily2", "familycomments2").In(Db);
            new NameFamily(3, "failFamily3", "familycomments3").In(Db);
            new NameFamily(4, "failFamily4", "familycomments4").In(Db);

            var pagedResults = new NameGroupPicklistController(Db, Substitute.For<IPreferredCultureResolver>()).Search(null, "title");
            var r = pagedResults.Data.ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("familytitle1", r.First().Title);
            Assert.Equal("familycomments1", r.First().Comments);

            Assert.Equal("titleOfFamily2", r.Last().Title);
            Assert.Equal("familycomments2", r.Last().Comments);
        }
    }
}
