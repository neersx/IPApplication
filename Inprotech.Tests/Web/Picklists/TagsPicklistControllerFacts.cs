using System;
using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class TagsPicklistControllerFacts : FactBase
    {
        public class SearchMethod : FactBase
        {
            [Fact]
            public void ReturnsPagedResults()
            {
                var f = new TagsPicklistControllerFixture(Db);
                f.PrepareData();
                var r = f.Subject.Tags(null);

                Assert.Equal(3, r.Data.Count());
            }

            [Fact]
            public void ReturnsPagedResultsWithParams()
            {
                var qParams = new CommonQueryParameters {SortBy = "TagName", SortDir = "asc", Skip = 1, Take = 1};
                var f = new TagsPicklistControllerFixture(Db);
                f.PrepareData();
                var r = f.Subject.Tags(null, qParams);
                var a = r.Data.OfType<Tags>().ToArray();

                Assert.Equal(3, r.Pagination.Total);
                Assert.Equal("Tag2", a[0].TagName);
            }

            [Fact]
            public void ReturnTagsWithMatchedId()
            {
                var f = new TagsPicklistControllerFixture(Db);
                f.PrepareData();
                var result = f.Subject.Tag("1");

                Assert.Equal(1, result.Id);
                Assert.Equal("Tag1", result.TagName);
            }

            [Fact]
            public void ShouldBeDecoratedWithPicklistPayloadAttribute()
            {
                var subjectType = new TagsPicklistControllerFixture(Db).Subject.GetType();
                var picklistAttribute =
                    subjectType.GetMethod("Tags").GetCustomAttribute<PicklistPayloadAttribute>();

                Assert.NotNull(picklistAttribute);
                Assert.Equal("Tags", picklistAttribute.Name);
            }
        }

        public class AddMethod : FactBase
        {
            [Fact]
            public void CallsSave()
            {
                var f = new TagsPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.TagsPicklistMaintenance.Save(null)
                 .ReturnsForAnyArgs(r);

                var model = new Tags();
                Assert.Equal(r, s.Add(model));
                f.TagsPicklistMaintenance.ReceivedWithAnyArgs(1).Save(model);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassed()
            {
                var f = new TagsPicklistControllerFixture(Db);

                var exception =
                    Record.Exception(() => f.Subject.Add(null));

                Assert.IsType<ArgumentNullException>(exception);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void CallsUpdate()
            {
                var f = new TagsPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.TagsPicklistMaintenance.Update(null)
                 .ReturnsForAnyArgs(r);

                var model = new Tags();
                Assert.Equal(r, s.Update(model.Id.ToString(), model));
                f.TagsPicklistMaintenance.ReceivedWithAnyArgs(1).Update(model);
            }

            [Fact]
            public void CallsUpdateConfirm()
            {
                var f = new TagsPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.TagsPicklistMaintenance.UpdateConfirm(null)
                 .ReturnsForAnyArgs(r);

                var model = new Tags();
                Assert.Equal(r, s.UpdateConfirm(model));
                f.TagsPicklistMaintenance.ReceivedWithAnyArgs(1).UpdateConfirm(model);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassed()
            {
                var f = new TagsPicklistControllerFixture(Db);
                var model = new Tags();
                var exception =
                    Record.Exception(() => f.Subject.Update(model.Id.ToString(), null));

                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public void ReturnExceptionWhenNullIsPassedForConfirmUpdate()
            {
                var f = new TagsPicklistControllerFixture(Db);
                var exception =
                    Record.Exception(() => f.Subject.UpdateConfirm(null));

                Assert.IsType<ArgumentNullException>(exception);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CallsDelete()
            {
                var f = new TagsPicklistControllerFixture(Db);
                var s = f.Subject;
                var r = new object();

                f.TagsPicklistMaintenance.Delete(1, true)
                 .ReturnsForAnyArgs(r);

                Assert.Equal(r, s.Delete(1, true));
                f.TagsPicklistMaintenance.Received(1).Delete(1, true);
            }
        }

        public class TagsPicklistControllerFixture : IFixture<TagsPicklistController>
        {
            public TagsPicklistControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                TagsPicklistMaintenance = Substitute.For<ITagsPicklistMaintenance>();
                Subject = new TagsPicklistController(DbContext, TagsPicklistMaintenance);
            }

            public InMemoryDbContext DbContext { get; }
            public ITagsPicklistMaintenance TagsPicklistMaintenance { get; }

            public TagsPicklistController Subject { get; }

            void AddTags(string tagName, int id)
            {
                new Tag {TagName = tagName, Id = id}.In(DbContext);
            }

            public void PrepareData()
            {
                AddTags("Tag1", 1);
                AddTags("Tag2", 2);
                AddTags("Tag3", 3);
            }
        }
    }
}