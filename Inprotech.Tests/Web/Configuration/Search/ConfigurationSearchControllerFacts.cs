using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Search
{
    public class ConfigurationSearchControllerFacts
    {
        public class GetViewDataMethod
        {
            const bool IsExternal = true;

            readonly ICommonQueryService _commonQueryService = Substitute.For<ICommonQueryService>();
            readonly IConfigurableItems _configurableItems = Substitute.For<IConfigurableItems>();

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldPreventEditingByAnExternalUser(bool authorisedConfigurableItemsExists)
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User(Fixture.String(), IsExternal));

                _configurableItems.Any().Returns(authorisedConfigurableItemsExists);

                var subject = new ConfigurationSearchController(securityContext, _commonQueryService, _configurableItems);

                Assert.False(subject.GetViewData().CanUpdate);
            }

            [Fact]
            public void ShouldAllowEditingByAnInternalUserIfConfigurableItemsExists()
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User(Fixture.String(), !IsExternal));

                _configurableItems.Any().Returns(true);

                var subject = new ConfigurationSearchController(securityContext, _commonQueryService, _configurableItems);

                Assert.True(subject.GetViewData().CanUpdate);
            }

            [Fact]
            public void ShouldPreventEditingByAnInternalUserIfNoConfigurableItemsExist()
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User(Fixture.String(), !IsExternal));

                _configurableItems.Any().Returns(false);

                var subject = new ConfigurationSearchController(securityContext, _commonQueryService, _configurableItems);

                Assert.False(subject.GetViewData().CanUpdate);
            }
        }

        public class SearchMethod
        {
            readonly IConfigurableItems _configurableItems = Substitute.For<IConfigurableItems>();

            ConfigurationSearchController CreateSubject()
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User(Fixture.String(), true));

                return new ConfigurationSearchController(securityContext, new CommonQueryService(), _configurableItems);
            }

            [Theory]
            [InlineData("1", null, null, "1^^")]
            [InlineData(null, "1,2,3", "4", "^1,2,3^4")]
            [InlineData(null, null, "1", "^^1")]
            public async Task ShouldReturnRowKey(string id, string ids, string groupId, string expectedRowKey)
            {
                _configurableItems
                    .Retrieve()
                    .Returns(new[]
                    {
                        new AuthorisedConfigItems
                        {
                            Id = string.IsNullOrWhiteSpace(id) ? (int?) null : int.Parse(id),
                            Ids = string.IsNullOrWhiteSpace(ids) ? new int[0] : ids.Split(',').Select(int.Parse).ToArray(),
                            GroupId = string.IsNullOrWhiteSpace(groupId) ? (int?) null : int.Parse(groupId),
                            Name = "Z",
                            Url = "/apps/#/abc"
                        }
                    });

                var result = await CreateSubject().Search(new ConfigurationSearchOptions());

                var r = result.Data.Cast<ConfigItem>().Single();

                Assert.Equal(expectedRowKey, r.RowKey);
            }

            [Fact]
            public async Task ShouldReturnAdjustedUrlForApps()
            {
                _configurableItems
                    .Retrieve()
                    .Returns(new[]
                    {
                        new AuthorisedConfigItems
                        {
                            Name = "Z",
                            Url = "/apps/#/abc"
                        }
                    });

                var result = await CreateSubject().Search(new ConfigurationSearchOptions());

                var r = result.Data.Cast<ConfigItem>().Single();

                Assert.Equal("#/abc", r.Url);
            }

            [Fact]
            public async Task ShouldReturnAdjustedUrlForInprotechSideConfigurationPages()
            {
                var configurationId = Fixture.Integer();

                _configurableItems
                    .Retrieve()
                    .Returns(new[]
                    {
                        new AuthorisedConfigItems
                        {
                            Id = configurationId,
                            Name = "Z"
                        }
                    });

                var result = await CreateSubject().Search(new ConfigurationSearchOptions());

                var r = result.Data.Cast<ConfigItem>().Single();

                Assert.Equal($"../default.aspx?ConfigFor={configurationId}", r.Url);
            }

            [Fact]
            public async Task ShouldReturnIeOnlyColumn()
            {
                _configurableItems
                    .Retrieve()
                    .Returns(new[]
                    {
                        new AuthorisedConfigItems
                        {
                            Name = "Schedule Data Download",
                            Description = "test",
                            IeOnly = true
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "Something else",
                            Description = "test1",
                            IeOnly = false
                        }
                    });

                var result = await CreateSubject().Search(new ConfigurationSearchOptions
                {
                    Text = "test"
                });

                var r = result.Data.Cast<ConfigItem>().Select(_ => _.IeOnly);

                Assert.Equal(new[] { true, false }, r);
            }

            [Fact]
            public async Task ShouldReturnDescriptionContainsSearchText()
            {
                _configurableItems
                    .Retrieve()
                    .Returns(new[]
                    {
                        new AuthorisedConfigItems
                        {
                            Name = "Schedule Data Download",
                            Description = "blah blah blah"
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "Something else",
                            Description = "Special Event"
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "Maintain Exchange Rate Schedule",
                            Description = "Cloud"
                        }
                    });

                var result = await CreateSubject().Search(new ConfigurationSearchOptions
                {
                    Text = "LOU"
                });

                var r = result.Data.Cast<ConfigItem>().Select(_ => _.Name);

                Assert.Equal(new[] { "Maintain Exchange Rate Schedule" }, r);
            }

            [Fact]
            public async Task ShouldReturnItemsMatchingComponent()
            {
                var componentIds = new[] { Fixture.Integer(), Fixture.Integer() };

                _configurableItems
                    .Retrieve()
                    .Returns(new[]
                    {
                        new AuthorisedConfigItems
                        {
                            Name = "Schedule Data Download",
                            Components = new[]
                            {
                                new Component
                                {
                                    Id = componentIds.First()
                                }
                            },
                            IeOnly = true
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "Something else",
                            Description = "Special Event",
                            Components = new[]
                            {
                                new Component
                                {
                                    Id = Fixture.Integer()
                                }
                            },
                            IeOnly = true
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "Maintain Exchange Rate Schedule",
                            Components = new[]
                            {
                                new Component
                                {
                                    Id = componentIds.Last()
                                }
                            },
                            IeOnly = false
                        }
                    });

                var result = await CreateSubject().Search(new ConfigurationSearchOptions
                {
                    ComponentIds = componentIds
                });

                var r = result.Data.Cast<ConfigItem>().Select(_ => _.Name);
                var ieOnlys = result.Data.Cast<ConfigItem>().Select(_ => _.IeOnly);

                Assert.Equal(new[] { "Maintain Exchange Rate Schedule", "Schedule Data Download" }, r);
                Assert.Equal(new[] { false, true }, ieOnlys);
            }

            [Fact]
            public async Task ShouldReturnItemsMatchingTags()
            {
                var tagIds = new[] { Fixture.Integer(), Fixture.Integer() };

                _configurableItems
                    .Retrieve()
                    .Returns(new[]
                    {
                        new AuthorisedConfigItems
                        {
                            Name = "Schedule Data Download",
                            Tags = new[]
                            {
                                new Tag
                                {
                                    Id = tagIds.First()
                                }
                            }
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "Something else",
                            Description = "Special Event",
                            Tags = new[]
                            {
                                new Tag
                                {
                                    Id = Fixture.Integer()
                                }
                            }
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "Maintain Exchange Rate Schedule",
                            Tags = new[]
                            {
                                new Tag
                                {
                                    Id = tagIds.Last()
                                }
                            }
                        }
                    });

                var result = await CreateSubject().Search(new ConfigurationSearchOptions
                {
                    TagIds = tagIds
                });

                var r = result.Data.Cast<ConfigItem>().Select(_ => _.Name);

                Assert.Equal(new[] { "Maintain Exchange Rate Schedule", "Schedule Data Download" }, r);
            }

            [Fact]
            public async Task ShouldReturnNameContainsSearchText()
            {
                _configurableItems
                    .Retrieve()
                    .Returns(new[]
                    {
                        new AuthorisedConfigItems
                        {
                            Name = "Schedule Data Download"
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "Something else"
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "Maintain Exchange Rate Schedule"
                        }
                    });

                var result = await CreateSubject().Search(new ConfigurationSearchOptions
                {
                    Text = "DuLe"
                });

                var r = result.Data.Cast<ConfigItem>().Select(_ => _.Name);

                Assert.Equal(new[] { "Maintain Exchange Rate Schedule", "Schedule Data Download" }, r);
            }

            [Fact]
            public async Task ShouldReturnOrderByNameByDefault()
            {
                _configurableItems
                    .Retrieve()
                    .Returns(new[]
                    {
                        new AuthorisedConfigItems
                        {
                            Name = "Z"
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "A"
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "P"
                        }
                    });

                var result = await CreateSubject().Search(new ConfigurationSearchOptions());

                var r = result.Data.Cast<ConfigItem>().Select(_ => _.Name);

                Assert.Equal(new[] { "A", "P", "Z" }, r);
            }

            [Fact]
            public async Task ShouldReturnOrderByRequestedOrder()
            {
                _configurableItems
                    .Retrieve()
                    .Returns(new[]
                    {
                        new AuthorisedConfigItems
                        {
                            Name = "Z"
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "A"
                        },
                        new AuthorisedConfigItems
                        {
                            Name = "P"
                        }
                    });

                var result = await CreateSubject().Search(new ConfigurationSearchOptions(), new CommonQueryParameters
                {
                    SortBy = "name",
                    SortDir = "desc"
                });

                var r = result.Data.Cast<ConfigItem>().Select(_ => _.Name);

                Assert.Equal(new[] { "Z", "P", "A" }, r);
            }
        }
    }
}