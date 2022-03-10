using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Common;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Configuration;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class TagsPicklistMaintenanceFacts : FactBase
    {
        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _anyTag = new Tag {TagName = "AddedTag", Id = 1};

                _existing = new Tag {TagName = "ExistingTag", Id = 2}.In(Db);
            }

            readonly Tag _anyTag;
            readonly Tag _existing;

            [Fact]
            public void AddTag()
            {
                var fixture = new TagsPicklistMaintenanceFixture(Db);

                var subject = fixture.Subject;

                var model = new Tags
                {
                    TagName = _anyTag.TagName,
                    Id = _anyTag.Id
                };

                var r = subject.Save(model);

                var justAdded = Db.Set<Tag>().Last();

                Assert.Equal("success", r.Result);
                Assert.NotEqual(justAdded, _existing);
                Assert.Equal(model.Id, justAdded.Id);
                Assert.Equal(model.TagName, justAdded.TagName);
            }

            [Fact]
            public void RequiresTagNameToBeNotGreaterThan30Characters()
            {
                var subject = new TagsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Tags
                {
                    Id = _existing.Id,
                    TagName = "123456789012345678901234567890123456789012345678901234567890123456789012345678901234"
                });

                Assert.Equal("tagName", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 30), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueTagName()
            {
                var subject = new TagsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Tags
                {
                    TagName = _existing.TagName,
                    Id = 0
                });

                Assert.Equal("tagName", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void RequirsTagName()
            {
                var subject = new TagsPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Tags
                {
                    TagName = string.Empty,
                    Id = 0
                });

                Assert.Equal("tagName", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ConfirmUniqueTagWhenUpdate()
            {
                var fixture = new TagsPicklistMaintenanceFixture(Db);

                var t1 = new Tag {TagName = "Tag1", Id = 1}.In(Db);
                var t2 = new Tag {TagName = "Tag2", Id = 2}.In(Db);

                var tags = new Tags {Id = t1.Id, TagName = t2.TagName};

                var r = fixture.Subject.Update(tags);
                Assert.Equal("confirmation", r.Result);
            }

            [Fact]
            public void Update()
            {
                var fixture = new TagsPicklistMaintenanceFixture(Db);

                var t1 = new Tag {TagName = "Tag1", Id = 1}.In(Db);

                var tags = new Tags {Id = 1, TagName = "Tag2"};
                var r = fixture.Subject.Update(tags);

                Assert.Equal("Tag2", t1.TagName);
                Assert.Equal("success", r.Result);
            }

            [Fact]
            public void UpdateTagAndSiteControlTags()
            {
                var fixture = new TagsPicklistMaintenanceFixture(Db);

                var sc1 = new SiteControlBuilder
                {
                    StringValue = Fixture.String(),
                    Tags = new List<Tag> {new Tag {Id = 1, TagName = "Tag1"}.In(Db)}
                }.Build().In(Db);

                new SiteControlBuilder
                {
                    StringValue = Fixture.String(),
                    Tags = new List<Tag> {new Tag {Id = 2, TagName = "Tag2"}.In(Db)}
                }.Build().In(Db);

                var tags = new Tags {Id = 1, TagName = "Tag2"};
                var r = fixture.Subject.UpdateConfirm(tags);

                Assert.Equal("Tag2", sc1.Tags.FirstOrDefault().TagName);
                Assert.Equal("success", r.Result);
                Assert.Equal(1, Db.Set<Tag>().Count());
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ConfirmDeleteWhenTagMappedToSiteControl()
            {
                var fixture = new TagsPicklistMaintenanceFixture(Db);

                new SiteControlBuilder
                {
                    StringValue = Fixture.String(),
                    Tags = new List<Tag> {new Tag {Id = 1, TagName = "Tag1"}.In(Db)}
                }.Build().In(Db);

                new SiteControlBuilder
                {
                    StringValue = Fixture.String(),
                    Tags = new List<Tag> {new Tag {Id = 2, TagName = "Tag2"}.In(Db)}
                }.Build().In(Db);

                var r = fixture.Subject.Delete(1, false);

                Assert.Equal("confirmation", r.Result);
                Assert.Equal(2, Db.Set<Tag>().Count());
            }

            [Fact]
            public void DeleteTag()
            {
                var fixture = new TagsPicklistMaintenanceFixture(Db);

                new Tag {TagName = "Tag1", Id = 1}.In(Db);
                new Tag {TagName = "Tag2", Id = 2}.In(Db);

                var r = fixture.Subject.Delete(1, true);

                Assert.Equal("success", r.Result);
                Assert.Equal(1, Db.Set<Tag>().Count());
                Assert.False(Db.Set<Tag>().Any(_ => _.Id == 1));
            }

            [Fact]
            public void DeleteTagWhenConfirmed()
            {
                var fixture = new TagsPicklistMaintenanceFixture(Db);

                new SiteControlBuilder
                {
                    StringValue = Fixture.String(),
                    Tags = new List<Tag> {new Tag {Id = 1, TagName = "Tag1"}.In(Db)}
                }.Build().In(Db);

                new SiteControlBuilder
                {
                    StringValue = Fixture.String(),
                    Tags = new List<Tag> {new Tag {Id = 2, TagName = "Tag2"}.In(Db)}
                }.Build().In(Db);

                var r = fixture.Subject.Delete(1, true);

                Assert.Equal("success", r.Result);
                Assert.Equal(1, Db.Set<Tag>().Count());
                Assert.False(Db.Set<Tag>().Any(_ => _.Id == 1));
            }
        }

        public class TagsPicklistMaintenanceFixture : IFixture<TagsPicklistMaintenance>
        {
            public TagsPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                Subject = new TagsPicklistMaintenance(db);
            }

            public TagsPicklistMaintenance Subject { get; set; }
        }
    }
}