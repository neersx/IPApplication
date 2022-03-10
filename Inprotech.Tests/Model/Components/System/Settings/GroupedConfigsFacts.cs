using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.System.Settings;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.System.Settings
{
    public class GroupedConfigsFacts
    {
        readonly GroupedConfigSettingsFixture _fixture = new GroupedConfigSettingsFixture();

        [Fact]
        public void ShouldBuildKeyForGetValueOrDefault()
        {
            _fixture.Settings.GetValueOrDefault<string>("thegroup.thekey").Returns("thevalue");
            Assert.Equal("thevalue", _fixture.Subject.GetValueOrDefault<string>("thekey"));
        }

        [Fact]
        public void ShouldBuildKeyForGetValueOrDefaultWithSpecificDefault()
        {
            _fixture.Settings.GetValueOrDefault("thegroup.thekey", "thedefaultvalue").Returns("thevalue");
            Assert.Equal("thevalue", _fixture.Subject.GetValueOrDefault("thekey", "thedefaultvalue"));
        }

        [Fact]
        public void ShouldBuildKeyForSetValue()
        {
            _fixture.Subject.SetValue("thekey", "thevalue");
            _fixture.Settings.Received(1).SetValue("thegroup.thekey", "thevalue");
        }

        [Fact]
        public void ShouldBuildKeyFromGroupAndPassedKey()
        {
            _fixture.Subject["thekey"] = "thevalue";
            _fixture.Settings.Received(1)["thegroup.thekey"] = "thevalue";
        }

        [Fact]
        public void ShouldDeleteExistingGroupedSettingValue()
        {
            _fixture.Subject.Delete("thekey");
            _fixture.Settings.Received().Delete("thegroup.thekey");
        }

        [Fact]
        public void ShouldGetExistingGroupedSettingValue()
        {
            _fixture.Settings["thegroup.thekey"].Returns("thevalue");
            Assert.Equal("thevalue", _fixture.Subject["thekey"]);
        }
    }

    internal class GroupedConfigSettingsFixture : IFixture<GroupedConfig>
    {
        readonly string _group;
        public readonly IConfigSettings Settings = Substitute.For<IConfigSettings>();

        public GroupedConfigSettingsFixture(string group = "thegroup")
        {
            _group = group;
        }

        public GroupedConfig Subject => new GroupedConfig(_group, Settings);
    }
}