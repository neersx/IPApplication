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
    public class SubjectPicklistControllerFacts : FactBase
    {
        SubjectPicklistController CreateSubject(InMemoryDbContext db)
        {
            var preferredCulture = Substitute.For<IPreferredCultureResolver>();
            preferredCulture.Resolve().ReturnsForAnyArgs("en-Us");
            return new SubjectPicklistController(db, preferredCulture, Fixture.TodayUtc);
        }
        [Fact]
        public void ShouldReturnSearchWithEmptyResult()
        {
            new DataTopic { TopicNameTId = 1, Name = "Name1", Description = "Description" }.In(Db);
            new DataTopic { TopicNameTId = 2, Name = "Aim2", Description = "Description2" }.In(Db);
            new DataTopic { TopicNameTId = 3, Name = "Zack3", Description = "Description3" }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = true }.In(Db);
            var subject = CreateSubject(Db);
            var result = subject.Search(null, "norecords").Data.ToArray();
            Assert.Equal(0, result.Length);
        }

        [Fact]
        public void ReturnsSubjectsInAscendingOrderOfName()
        {
            new DataTopic { TopicNameTId = 1, Name = "Case Search", Description = "Description" }.In(Db);
            new DataTopic { TopicNameTId = 2, Name = "Name Search", Description = "Description2" }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = false }.In(Db);
            var subject = CreateSubject(Db);
            var r = subject.Search(null, "Name");
            var result = r.Data.OfType<DataTopicItems>().ToArray();
            Assert.Equal(1, result.Length);
            Assert.Equal("Name Search", result[0].Name);
        }

        [Fact]
        public void ReturnsSortedPagedResults()
        {
            new DataTopic { TopicNameTId = 1, Name = "Name1", Description = "Description" }.In(Db);
            new DataTopic { TopicNameTId = 2, Name = "Aim2", Description = "Description2" }.In(Db);
            new DataTopic { TopicNameTId = 3, Name = "Zack3", Description = "Description3" }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = true }.In(Db);
            var subject = CreateSubject(Db);
            var qParams = new CommonQueryParameters { SortBy = "Description", SortDir = "asc", Skip = 1, Take = 1 };
            var result = subject.Search(qParams);
            var queries = result.Data.ToArray();
            Assert.Equal(2, result.Pagination.Total);
            Assert.Single(queries);
            Assert.Equal("Description2", ((DataTopicItems)queries[0]).Description);
        }

        [Fact]
        public void SearchesForDescription()
        {
            new DataTopic { TopicNameTId = 1, Name = "Case Search", Description = "Description" }.In(Db);
            new DataTopic { TopicNameTId = 2, Name = "Name Search", Description = "Description2" }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "1", InternalUse = true, ExternalUse = false }.In(Db);
            new ValidObjectItems { ObjectIntegerKey = "2", InternalUse = true, ExternalUse = true }.In(Db);
            var subject = CreateSubject(Db);
            var result = subject.Search(null, "Description2").Data.ToArray();
            Assert.Equal("Description2", ((DataTopicItems)result[0]).Description);
            Assert.Equal("Name Search", ((DataTopicItems)result[0]).Name);
        }
    }
}