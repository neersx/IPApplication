using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Configuration;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class TagsControllerFacts
    {
        public class FindTagsMethod : FactBase
        {
            [Fact]
            public void ReturnsAllTagsWhenNoFilter()
            {
                var f = new TagsControllerFixture(Db);

                f.AddTag("Tag2");
                f.AddTag("Tag1");
                f.AddTag("AlsoReturn");
                var result = f.Subject.FindTags(null, 50);

                var results = ((IEnumerable<dynamic>) result).ToArray();

                Assert.Equal(3, results.Length);
            }

            [Fact]
            public void ReturnsFilteredTagsListe()
            {
                var f = new TagsControllerFixture(Db);

                f.AddTag("Tag2");
                f.AddTag("Tag1");
                f.AddTag("DoNotReturn");
                var result = f.Subject.FindTagsList("Tag");

                var results = result.Data.OfType<TagResult>().ToArray();

                Assert.Equal(2, results.Length);
                Assert.Contains(results, x => x.TagName == "Tag1");
                Assert.Contains(results, x => x.TagName == "Tag2");
            }

            [Fact]
            public void ReturnsFilteredTagsOrderdByTagName()
            {
                var f = new TagsControllerFixture(Db);

                f.AddTag("Tag2");
                f.AddTag("Tag1");
                f.AddTag("DoNotReturn");
                var result = f.Subject.FindTags("Tag", 50);

                var results = ((IEnumerable<dynamic>) result).ToArray();

                Assert.Equal(2, results.Length);
                Assert.Equal("Tag1", results.First().TagName);
                Assert.Equal("Tag2", results.Last().TagName);
            }
        }

        public class CreateTagMethod : FactBase
        {
            [Theory]
            [InlineData("")]
            [InlineData(" ")]
            [InlineData(null)]
            public void DoesNotAddNullOrEmptyTags(string newTag)
            {
                var f = new TagsControllerFixture(Db);
                var t = new JObject {{"newTag", newTag}};
                Assert.Throws<Exception>(() => f.Subject.CreateTag(t));
            }

            [Fact]
            public void AddsNewTag()
            {
                var f = new TagsControllerFixture(Db);
                var t = new JObject {{"newTag", Fixture.String()}};
                f.Subject.CreateTag(t);

                Assert.Equal(1, f.DbContext.Set<Tag>().Count());
                Assert.Equal(t["newTag"], f.DbContext.Set<Tag>().Single().TagName);
            }

            [Fact]
            public void ShouldReturnExistingTag()
            {
                var f = new TagsControllerFixture(Db);
                var existing = f.AddTag("ExistingTag");
                var t = new JObject {{"newTag", "ExistingTag"}};

                var tid = (int) f.Subject.CreateTag(t);

                Assert.Equal(existing.Id, tid);
            }
        }

        public class TagsControllerFixture : IFixture<TagsController>
        {
            public TagsControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                Subject = new TagsController(DbContext);
            }

            public InMemoryDbContext DbContext { get; }
            public TagsController Subject { get; }

            public Tag AddTag(string tagName)
            {
                return new Tag
                {
                    TagName = tagName
                }.In(DbContext);
            }
        }
    }
}