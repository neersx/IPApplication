using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class TradeMarkClassPicklistControllerFacts : FactBase
    {
        public class TradeMarkClassMethod : FactBase
        {
            [Fact]
            public void ReturnsTmClasssSortedByCode()
            {
                var f = new TradeMarkClassPicklistControllerFixture(Db);
                f.Setup();

                var queryParams = new CommonQueryParameters
                {
                    Skip = 0,
                    Take = 5
                };

                var r = f.Subject.TradeMarkClass(queryParams);
                var tmc = r.Data.OfType<TradeMarkClass>().ToArray();

                Assert.Equal(4, tmc.Length);
                Assert.Equal("100", tmc.Last().Code);
                Assert.Equal("05", tmc.First().Code);
            }

            [Fact]
            public void ReturnsTmClassWithExactMatchCode()
            {
                var f = new TradeMarkClassPicklistControllerFixture(Db);
                var items = f.Setup();

                var queryParams = new CommonQueryParameters
                {
                    Skip = 0,
                    Take = 5
                };

                var r = f.Subject.TradeMarkClass(queryParams, "2");
                var tmc = r.Data.OfType<TradeMarkClass>().ToArray();

                Assert.Single(tmc);
                Assert.Equal(items.item2.Class, tmc[0].Code);
            }

            [Fact]
            public void ReturnsTmClassWithExactMatchOnHeading()
            {
                var f = new TradeMarkClassPicklistControllerFixture(Db);
                var items = f.Setup();

                var queryParams = new CommonQueryParameters
                {
                    Skip = 0,
                    Take = 5
                };

                var r = f.Subject.TradeMarkClass(queryParams, "Heading 1");
                var tmc = r.Data.OfType<TradeMarkClass>().ToArray();

                Assert.Single(tmc);
                Assert.Equal(items.item1.Heading, tmc[0].Value);
            }

            [Fact]
            public void ReturnsTmClassWithPartialMatchOnHeading()
            {
                var f = new TradeMarkClassPicklistControllerFixture(Db);
                f.Setup();

                var queryParams = new CommonQueryParameters
                {
                    Skip = 0,
                    Take = 5
                };

                var r = f.Subject.TradeMarkClass(queryParams, "Heading");
                var tmc = r.Data.OfType<TradeMarkClass>().ToArray();

                Assert.Equal(4, tmc.Length);
            }
        }
    }

    public class TradeMarkClassPicklistControllerFixture : IFixture<TradeMarkClassPicklistController>
    {
        readonly InMemoryDbContext _db;

        public TradeMarkClassPicklistControllerFixture(InMemoryDbContext db)
        {
            _db = db;
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            Subject = new TradeMarkClassPicklistController(_db, PreferredCultureResolver);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public TradeMarkClassPicklistController Subject { get; }

        public dynamic Setup()
        {
            var item1 = new TmClass("ZZZ", "05", "T", 1) {Heading = "Heading 1"}.In(_db);
            var item2 = new TmClass("ZZZ", "2", "T", 1) {Heading = "Heading 2"}.In(_db);
            var item3 = new TmClass("ZZZ", "03", "T", 1) {Heading = "Heading 3"}.In(_db);
            var item4 = new TmClass("ZZZ", "100", "T", 1) {Heading = "Heading 4"}.In(_db);

            return new {item1, item2, item3, item4};
        }
    }
}