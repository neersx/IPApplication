using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Security;
using Xunit;
using Keyword = InprotechKaizen.Model.Keywords.Keyword;

namespace Inprotech.Tests.Web.Picklists
{
    public class KeywordsPicklistControllerFacts
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public void ReturnsKeywords()
            {
                var f = new KeywordsPicklistControllerFixture(Db);
                var data = f.Setup();

                var r = f.Subject.Get();
                var keywords = r.Data.OfType<Inprotech.Web.Picklists.Keyword>().ToArray();

                Assert.Equal(2, keywords.Length);
                Assert.True(data.All(_ => keywords.SingleOrDefault(k => k.Key == _.KeyWord && k.CaseStopWord == (_.StopWord == 1)) != null));
            }

            [Fact]
            public void ReturnsKeywordsContainingMatchingName()
            {
                var f = new KeywordsPicklistControllerFixture(Db);
                f.Setup();

                var r = f.Subject.Get(null, "Keyword1");
                var keywords = r.Data.OfType<Inprotech.Web.Picklists.Keyword>().ToArray();

                Assert.Single(keywords);
                Assert.Equal("Keyword1", keywords.First().Key);
                Assert.Equal(true, keywords.First().CaseStopWord);
                Assert.Equal(false, keywords.First().NameStopWord);
            }
        }
    }

    public class KeywordsPicklistControllerFixture : IFixture<KeywordsPicklistController>
    {
        readonly InMemoryDbContext _db;

        public KeywordsPicklistControllerFixture(InMemoryDbContext db)
        {
            _db = db;
            Subject = new KeywordsPicklistController(db);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public KeywordsPicklistController Subject { get; }

        public IEnumerable<Keyword> Setup()
        {
            var kw1 = new Keyword {KeyWord = "Keyword1", StopWord = 1}.In(_db);
            var kw2 = new Keyword {KeyWord = "Keyword2", StopWord = 0}.In(_db);

            return new[] {kw1, kw2};
        }
    }
}