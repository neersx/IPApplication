using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class CopyProfilePicklistControllerFacts : FactBase
    {
        public class CopyProfileMethod : FactBase
        {
            [Fact]
            public void ReturnsCopyProfileSortedByDescription()
            {
                var f = new CopyProfilePicklistControllerFixture(Db);

                var b = new CopyProfile("B", 0).In(Db);
                var a = new CopyProfile("A", 0).In(Db);
                var c = new CopyProfile("C", 0).In(Db);

                var r = f.Subject.Search();

                var o = r.Data.OfType<dynamic>().ToArray();

                Assert.Equal(a.ProfileName, o[0].Key);
                Assert.Equal(b.ProfileName, o[1].Key);
                Assert.Equal(c.ProfileName, o[2].Key);
            }

            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new CopyProfilePicklistControllerFixture(Db);

                new CopyProfile("AAA", 0).In(Db);
                new CopyProfile("CCC", 1).In(Db);
                var o = new CopyProfile("BBB", 2).In(Db);

                var qParams = new CommonQueryParameters {SortBy = "Value", SortDir = "asc", Skip = 1, Take = 1};
                var r = f.Subject.Search(qParams);
                var copyProfiles = r.Data.OfType<dynamic>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Single(copyProfiles);
                Assert.Equal(o.ProfileName, copyProfiles.Single().Key);
            }

            [Fact]
            public void ShouldNotReturnsCopyProfileIfSameProfileIsUsedForCrm()
            {
                var f = new CopyProfilePicklistControllerFixture(Db);

                var b = new CopyProfile("B", 0).In(Db);
                var a = new CopyProfile("A", 0).In(Db);
                new CopyProfile("C", 0).In(Db);
                new CopyProfile("C", 0) {CrmOnly = true}.In(Db);

                var r = f.Subject.Search();

                var o = r.Data.OfType<dynamic>().ToArray();

                Assert.Equal(2, o.Length);

                Assert.Equal(a.ProfileName, o[0].Key);
                Assert.Equal(b.ProfileName, o[1].Key);
            }
        }
    }

    public class CopyProfilePicklistControllerFixture : IFixture<CopyProfilePicklistController>
    {
        public CopyProfilePicklistControllerFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            Subject = new CopyProfilePicklistController(db, PreferredCultureResolver);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public CopyProfilePicklistController Subject { get; }
    }
}