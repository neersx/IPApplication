using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class WebPartPicklistControllerFacts : FactBase
    {
        WebPartPicklistController CreateSubject(InMemoryDbContext db)
        {
            var preferredCulture = Substitute.For<IPreferredCultureResolver>();
            preferredCulture.Resolve().ReturnsForAnyArgs("en-Us");
            return new WebPartPicklistController(db, preferredCulture, Fixture.TodayUtc);
        }
        [Fact]
        public void ShouldReturnSearchWithEmptyResult()
        {
            new WebpartModule { Id = 1, Title = "Name Reports", Description = "A list of saved name queries." }.In(Db);
            new WebpartModule { Id = 2, Title = "Case Reports", Description = "A list of saved case queries." }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = true }.In(Db);
            var Subject = CreateSubject(Db);
            var result = Subject.Search(null, "norecords").Data.ToArray();

            Assert.Equal(0, result.Length);
        }

        [Fact]
        public void ShouldReturnSearchAndMatchNumberOfRecords()
        {
            new WebpartModule { Id = 1, Title = "Name Reports", Description = "A list of saved name queries." }.In(Db);
            new WebpartModule { Id = 2, Title = "Case Reports", Description = "A list of saved case queries." }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = true }.In(Db);

            var Subject = CreateSubject(Db);
            var result = Subject.Search(null, "name").Data.ToArray();
            Assert.Equal(1, result.Length);
            Assert.Equal("Name Reports", ((WebPartPicklistItem)result[0]).Title);
            Assert.Equal("A list of saved name queries.", ((WebPartPicklistItem)result[0]).Description);
        }

        [Fact]
        public void ReturnsSortedPagedResults()
        {
            new WebpartModule { Id = 1, Title = "Name Reports", Description = "A list of saved name queries." }.In(Db);
            new WebpartModule { Id = 2, Title = "Case Reports", Description = "A list of saved case queries." }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = true }.In(Db);
            var Subject = CreateSubject(Db);
            var qParams = new CommonQueryParameters { SortBy = "Description", SortDir = "asc", Skip = 1, Take = 1 };
            var result = Subject.Search(qParams);
            var queries = result.Data.ToArray();
            Assert.Equal(2, result.Pagination.Total);
            Assert.Single(queries);
            Assert.Equal("A list of saved name queries.", ((WebPartPicklistItem)queries[0]).Description);
        }

        [Fact]
        public void SearchesForDescription()
        {
            new WebpartModule { Id = 1, Title = "Name Reports", Description = "A list of saved name queries." }.In(Db);
            new WebpartModule { Id = 2, Title = "Case Reports", Description = "A list of saved case queries." }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = true }.In(Db);
            var Subject = CreateSubject(Db);
            var result = Subject.Search(null, "case").Data.ToArray();
            Assert.Equal("A list of saved case queries.", ((WebPartPicklistItem)result[0]).Description);
        }
    }
}