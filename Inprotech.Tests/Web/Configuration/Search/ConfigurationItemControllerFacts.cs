using System;
using System.Threading.Tasks;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Configuration.Search;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Search
{
    public class ConfigurationItemControllerFacts
    {
        public ConfigurationItemControllerFacts()
        {
            _securityContext = Substitute.For<ISecurityContext>();
            _configurableItems = Substitute.For<IConfigurableItems>();
            _subject = new ConfigurationItemController(_securityContext, _configurableItems);
        }

        readonly ConfigurationItemController _subject;
        readonly ISecurityContext _securityContext;
        readonly IConfigurableItems _configurableItems;

        [Fact]
        public async Task PreventsUnAuthorizedAccess()
        {
            _securityContext.User.Returns(new User("xyz", true));
            _configurableItems.Any().Returns(true);
            await Assert.ThrowsAsync<UnauthorizedAccessException>(async () => { await _subject.Save(new ConfigItem()); });

            _securityContext.User.Returns(new User("int", false));
            _configurableItems.Any().Returns(false);

            await Assert.ThrowsAsync<UnauthorizedAccessException>(async () => { await _subject.Save(new ConfigItem()); });
        }

        [Fact]
        public async Task ShouldCallSaves()
        {
            _securityContext.User.Returns(new User("int", false));
            _configurableItems.Any().Returns(true);

            await _subject.Save(new ConfigItem());
            _configurableItems.Received(1).Save(Arg.Any<ConfigItem>())
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnUpdatedIds()
        {
            var configItem = new ConfigItem();
            var updatedIds = new[] {2, 5, 8, 9};

            _securityContext.User.Returns(new User("int", false));
            _configurableItems.Any().Returns(true);

            _configurableItems.Save(configItem).Returns(updatedIds);

            Assert.Equal(updatedIds, await _subject.Save(configItem));
        }
    }
}