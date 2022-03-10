using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.Items;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Search
{
    public class ConfigurableItemsFacts
    {
        public class RetrieveMethod : FactBase
        {
            readonly Component[] _components =
            {
                new Component
                {
                    ComponentName = Fixture.String(),
                    Id = Fixture.Integer()
                },
                new Component
                {
                    ComponentName = Fixture.String(),
                    Id = Fixture.Integer()
                }
            };

            readonly Tag[] _tags =
            {
                new Tag
                {
                    TagName = Fixture.String(),
                    Id = Fixture.Integer()
                },
                new Tag
                {
                    TagName = Fixture.String(),
                    Id = Fixture.Integer()
                }
            };

            IConfigurableItems CreateSubject(User user = null)
            {
                var securityContext = Substitute.For<ISecurityContext>();
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                securityContext.User.Returns(user ?? new User(Fixture.String(), false).In(Db));
                preferredCultureResolver.Resolve().Returns("en");

                _components.In(Db);
                _tags.In(Db);

                return new ConfigurableItems(Db, securityContext, preferredCultureResolver, Fixture.Today);
            }

            [Fact]
            public async Task ShouldRetrieveGroupedItemsIfAtleastOneItemInGroupIsPermitted()
            {
                var taskA = new SecurityTask
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String()
                }.In(Db);

                var taskB = new SecurityTask
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String()
                }.In(Db);

                new PermissionsGrantedItem
                {
                    ObjectIntegerKey = taskA.Id,
                    CanExecute = true
                }.In(Db);

                new PermissionsGrantedItem
                {
                    ObjectIntegerKey = taskB.Id,
                    CanExecute = true
                }.In(Db);

                var group = new ConfigurationItemGroup
                {
                    Id = Fixture.Integer(),
                    Title = Fixture.String(),
                    Description = Fixture.String(),
                    Url = Fixture.String()
                }.In(Db);

                var itemA = new ConfigurationItem
                {
                    GroupId = group.Id,
                    Id = Fixture.Integer(),
                    TaskId = taskA.Id,
                    Title = Fixture.String(),
                    Description = Fixture.String(),
                    Components = _components,
                    Tags = _tags
                }.In(Db);

                var itemB = new ConfigurationItem
                {
                    GroupId = group.Id,
                    Id = Fixture.Integer(),
                    TaskId = taskB.Id,
                    Title = Fixture.String(),
                    Description = Fixture.String()
                }.In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve()).ToArray();

                Assert.Single(r);
                Assert.Equal(new[] {itemA.Id, itemB.Id}, r.Single().Ids);
                Assert.Equal(group.Title, r.Single().Name);
                Assert.Equal(group.Description, r.Single().Description);
                Assert.Equal(group.Url, r.Single().Url);
                Assert.Equal(_components.Select(_ => _.ComponentName), r.Single().Components.Select(_ => (string) _.ComponentName));
                Assert.Equal(_tags, r.Single().Tags);
            }

            [Fact]
            public async Task ShouldRetrieveIndividualItemIfOnlyItselfIsPermittedInThatGroup()
            {
                var taskA = new SecurityTask
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String(),
                }.In(Db);

                var taskB = new SecurityTask
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String()
                }.In(Db);

                new PermissionsGrantedItem
                {
                    ObjectIntegerKey = taskA.Id,
                    CanExecute = true
                }.In(Db);

                var group = new ConfigurationItemGroup
                {
                    Id = Fixture.Integer(),
                    Title = Fixture.String(),
                    Description = Fixture.String(),
                    Url = Fixture.String()
                }.In(Db);

                var itemA = new ConfigurationItem
                {
                    GroupId = group.Id,
                    Id = Fixture.Integer(),
                    TaskId = taskA.Id,
                    Title = Fixture.String(),
                    Description = Fixture.String(),
                    IeOnly = false
                }.In(Db);

                new ConfigurationItem
                {
                    GroupId = group.Id,
                    Id = Fixture.Integer(),
                    TaskId = taskB.Id,
                    Title = Fixture.String(),
                    Description = Fixture.String(),
                    Components = _components,
                    Tags = _tags,
                    IeOnly = true
                }.In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve()).ToArray();

                Assert.Single(r);
                Assert.Equal(itemA.Id, r.Single().Id);
                Assert.Equal(itemA.Title, r.Single().Name);
                Assert.Equal(itemA.Description, r.Single().Description);
                Assert.Equal(itemA.Url, r.Single().Url);
                Assert.Equal(itemA.IeOnly, r.Single().IeOnly);
                Assert.Empty(r.Single().Components);
                Assert.Empty(r.Single().Tags);
            }

            [Fact]
            public async Task ShouldRetrievePermittedItemsOnly()
            {
                var taskA = new SecurityTask
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String()
                }.In(Db);

                var taskB = new SecurityTask
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String()
                }.In(Db);

                new PermissionsGrantedItem
                {
                    ObjectIntegerKey = taskA.Id,
                    CanExecute = true
                }.In(Db);

                var shouldReturn = new ConfigurationItem
                {
                    Id = Fixture.Integer(),
                    TaskId = taskA.Id,
                    Title = Fixture.String(),
                    Description = Fixture.String(),
                    Url = Fixture.String(),
                    IeOnly = true
                }.In(Db);

                new ConfigurationItem
                {
                    Id = Fixture.Integer(),
                    TaskId = taskB.Id,
                    Title = "should not return",
                    Description = "should not return",
                    Url = Fixture.String(),
                    IeOnly = false
                }.In(Db);

                var subject = CreateSubject();

                var r = (await subject.Retrieve()).ToArray();

                Assert.Single(r);
                Assert.Equal(shouldReturn.Id, r.Single().Id);
                Assert.Equal(shouldReturn.Title, r.Single().Name);
                Assert.Equal(shouldReturn.Description, r.Single().Description);
                Assert.Equal(shouldReturn.Url, r.Single().Url);
                Assert.Equal(shouldReturn.IeOnly, r.Single().IeOnly);
            }
        }

        public class AnyMethod : FactBase
        {
            IConfigurableItems CreateSubject(User user = null)
            {
                var securityContext = Substitute.For<ISecurityContext>();
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                securityContext.User.Returns(user ?? new User(Fixture.String(), false).In(Db));
                preferredCultureResolver.Resolve().Returns("en");

                return new ConfigurableItems(Db, securityContext, preferredCultureResolver, Fixture.Today);
            }

            [Fact]
            public void ShouldReturnFalseIfNoneOfTheConfigurableItemsArePermitted()
            {
                var taskA = new SecurityTask
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String()
                }.In(Db);

                new ConfigurationItem
                    {TaskId = taskA.Id}.In(Db);

                var configurableItems = CreateSubject();

                Assert.False(configurableItems.Any());
            }

            [Fact]
            public void ShouldReturnTrueIfConfigurableItemsArePermitted()
            {
                var taskA = new SecurityTask
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String()
                }.In(Db);

                new PermissionsGrantedItem
                {
                    ObjectIntegerKey = taskA.Id,
                    CanExecute = true
                }.In(Db);

                new ConfigurationItem
                    {TaskId = taskA.Id}.In(Db);

                var configurableItems = CreateSubject();

                Assert.True(configurableItems.Any());
            }
        }

        public class SaveMethod : FactBase
        {
            IConfigurableItems CreateSubject(User user = null)
            {
                var securityContext = Substitute.For<ISecurityContext>();
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                securityContext.User.Returns(user ?? new User(Fixture.String(), false).In(Db));
                preferredCultureResolver.Resolve().Returns("en");

                return new ConfigurableItems(Db, securityContext, preferredCultureResolver, Fixture.Today);
            }

            [Fact]
            public async Task ClearTags()
            {
                var taskA = new SecurityTask
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String()
                }.In(Db);

                var tag = new Tag
                {
                    Id = Fixture.Integer(),
                    TagName = Fixture.String()
                }.In(Db);

                new PermissionsGrantedItem
                {
                    ObjectIntegerKey = taskA.Id,
                    CanExecute = true
                }.In(Db);

                var configItem = new ConfigurationItem
                {
                    TaskId = taskA.Id,
                    Tags = new List<Tag> {tag}
                }.In(Db);

                var configurableItems = CreateSubject();

                await configurableItems.Save(new ConfigItem
                {
                    Id = configItem.Id,
                    Tags = new List<Tag>()
                });

                Assert.True(Db.Set<ConfigurationItem>().Single(_ => _.Id == configItem.Id).Tags.Count == 0);
            }

            [Fact]
            public async Task SaveTags()
            {
                var taskA = new SecurityTask
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String()
                }.In(Db);

                var tag = new Tag
                {
                    Id = Fixture.Integer(),
                    TagName = Fixture.String()
                }.In(Db);

                new PermissionsGrantedItem
                {
                    ObjectIntegerKey = taskA.Id,
                    CanExecute = true
                }.In(Db);

                var configItem = new ConfigurationItem
                    {TaskId = taskA.Id}.In(Db);

                var configurableItems = CreateSubject();

                await configurableItems.Save(new ConfigItem
                {
                    Id = configItem.Id,
                    Tags = new[]
                    {
                        new Tag
                        {
                            Id = tag.Id,
                            TagName = tag.TagName
                        }
                    }
                });

                Assert.True(Db.Set<ConfigurationItem>().Single(_ => _.Id == configItem.Id).Tags.Count == 1);
            }

            [Fact]
            public async Task UpdateTags()
            {
                var taskA = new SecurityTask
                {
                    Id = Fixture.Short(),
                    Name = Fixture.String()
                }.In(Db);

                var tag = new Tag
                {
                    Id = Fixture.Integer(),
                    TagName = Fixture.String()
                }.In(Db);
                var newTag = new Tag
                {
                    Id = Fixture.Integer() + 1,
                    TagName = Fixture.String()
                }.In(Db);

                new PermissionsGrantedItem
                {
                    ObjectIntegerKey = taskA.Id,
                    CanExecute = true
                }.In(Db);

                var configItem = new ConfigurationItem
                {
                    TaskId = taskA.Id,
                    Tags = new List<Tag> {tag}
                }.In(Db);

                var configurableItems = CreateSubject();

                await configurableItems.Save(new ConfigItem
                {
                    Id = configItem.Id,
                    Tags = new[]
                    {
                        newTag
                    }
                });

                var tags = Db.Set<ConfigurationItem>().Single(_ => _.Id == configItem.Id).Tags;
                Assert.True(tags.Count == 1);
                Assert.True(tags.Single().Id == newTag.Id);
                Assert.True(tags.Single().TagName == newTag.TagName);
            }
        }
    }
}