using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Settings;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Settings
{
    public class DmsIntegrationSettingsFacts
    {
        readonly DmsIntegrationSettingsFixture _fixture = new DmsIntegrationSettingsFixture();
        const string PrivatePairLocationValue = @"\\privatepair\location";
        const string PrivatePairLocationKey = "PrivatePairLocation";
        const string PrivatePairIntegrationEnabledKey = "PrivatePairIntegrationEnabled";
        const string TsdrIntegrationEnabledKey = "TsdrIntegrationEnabled";
        const string TsdrLocationValue = @"\\tsdr\location";
        const string TsdrLocationKey = "TsdrLocation";
        const string PrivatePairFilenameKey = "PrivatePairFilenameFormat";
        const string TsdrFilenameKey = "TsdrFilenameFormat";

        [Theory]
        [MemberData(nameof(AvailableDataSourceTypes.ShouldBeKnownToDmsIntegrationSettings), MemberType = typeof(AvailableDataSourceTypes))]
        public void ShouldCaterForNewDataSource(DataSourceType source)
        {
            // return enabled as 'false' for any new data sources
            // then determine when the dms integration will be implemented for that source.
            Assert.False(_fixture.Subject.IsEnabledFor(source));
        }

        [Fact]
        public void ShouldGetCorrectValueForPrivatePairFilename()
        {
            _fixture.GroupedSettings[PrivatePairFilenameKey].Returns("private pair filename");
            Assert.Equal("private pair filename", _fixture.Subject.PrivatePairFilename);
        }

        [Fact]
        public void ShouldGetCorrectValueForPrivatePairLocation()
        {
            _fixture.GroupedSettings[PrivatePairLocationKey].Returns(PrivatePairLocationValue);
            Assert.Equal(PrivatePairLocationValue, _fixture.Subject.PrivatePairLocation);
        }

        [Fact]
        public void ShouldGetCorrectValueForTsdrFilename()
        {
            _fixture.GroupedSettings[TsdrFilenameKey].Returns("tsdr filename");
            Assert.Equal("tsdr filename", _fixture.Subject.TsdrFilename);
        }

        [Fact]
        public void ShouldGetCorrectValueForTsdrLocation()
        {
            _fixture.GroupedSettings[TsdrLocationKey].Returns(TsdrLocationValue);
            Assert.Equal(TsdrLocationValue, _fixture.Subject.TsdrLocation);
        }

        [Fact]
        public void ShouldGetEnabledForIsIntegrationEnabledForPrivatePair()
        {
            _fixture.GroupedSettings.GetValueOrDefault(TsdrIntegrationEnabledKey, false).Returns(false);
            _fixture.GroupedSettings.GetValueOrDefault(PrivatePairIntegrationEnabledKey, false).Returns(true);
            Assert.True(_fixture.Subject.IsEnabledFor(DataSourceType.UsptoPrivatePair));
        }

        [Fact]
        public void ShouldGetEnabledForIsIntegrationEnabledForTsdr()
        {
            _fixture.GroupedSettings.GetValueOrDefault(TsdrIntegrationEnabledKey, false).Returns(true);
            _fixture.GroupedSettings.GetValueOrDefault(PrivatePairIntegrationEnabledKey, false).Returns(false);
            Assert.True(_fixture.Subject.IsEnabledFor(DataSourceType.UsptoTsdr));
        }

        [Fact]
        public void ShouldGetEnabledForPrivatePairIntegrationEnabled()
        {
            _fixture.GroupedSettings.GetValueOrDefault(PrivatePairIntegrationEnabledKey, false).Returns(true);
            Assert.True(_fixture.Subject.PrivatePairIntegrationEnabled);
        }

        [Fact]
        public void ShouldGetEnabledForTsdrIntegrationEnabled()
        {
            _fixture.GroupedSettings.GetValueOrDefault(TsdrIntegrationEnabledKey, false).Returns(true);
            Assert.True(_fixture.Subject.TsdrIntegrationEnabled);
        }

        [Fact]
        public void ShouldHaveCorrectSettingsGroup()
        {
            Assert.Equal("DmsIntegration", _fixture.GroupUsed);
        }

        [Fact]
        public void ShouldSetCorrectValueForPrivatePairFilename()
        {
            _fixture.Subject.PrivatePairFilename = "private pair filename";
            _fixture.GroupedSettings.Received(1)[PrivatePairFilenameKey] = "private pair filename";
        }

        [Fact]
        public void ShouldSetCorrectValueForPrivatePairIntegrationDisabled()
        {
            _fixture.Subject.PrivatePairIntegrationEnabled = false;
            _fixture.GroupedSettings.Received().SetValue(PrivatePairIntegrationEnabledKey, false);
        }

        [Fact]
        public void ShouldSetCorrectValueForPrivatePairLocation()
        {
            _fixture.Subject.PrivatePairLocation = PrivatePairLocationValue;
            _fixture.GroupedSettings.Received()[PrivatePairLocationKey] = PrivatePairLocationValue;
        }

        [Fact]
        public void ShouldSetCorrectValueForTsdrFilename()
        {
            _fixture.Subject.TsdrFilename = "tsdr filename";
            _fixture.GroupedSettings.Received(1)[TsdrFilenameKey] = "tsdr filename";
        }

        [Fact]
        public void ShouldSetCorrectValueForTsdrIntegrationDisabled()
        {
            _fixture.Subject.TsdrIntegrationEnabled = false;
            _fixture.GroupedSettings.Received().SetValue(TsdrIntegrationEnabledKey, false);
        }

        [Fact]
        public void ShouldSetCorrectValueForTsdrLocation()
        {
            _fixture.Subject.TsdrLocation = TsdrLocationValue;
            _fixture.GroupedSettings.Received()[TsdrLocationKey] = TsdrLocationValue;
        }

        [Fact]
        public void ShouldSetEnabledForPrivatePairIntegrationEnabled()
        {
            _fixture.Subject.PrivatePairIntegrationEnabled = true;
            _fixture.GroupedSettings.Received().SetValue(PrivatePairIntegrationEnabledKey, true);
        }

        [Fact]
        public void ShouldSetEnabledForTsdrIntegrationEnabled()
        {
            _fixture.Subject.TsdrIntegrationEnabled = true;
            _fixture.GroupedSettings.Received().SetValue(TsdrIntegrationEnabledKey, true);
        }
    }

    internal class AvailableDataSourceTypes
    {
        public static IEnumerable<object[]> ShouldBeKnownToDmsIntegrationSettings
        {
            get
            {
                return Enum.GetValues(typeof(DataSourceType))
                           .Cast<DataSourceType>()
                           .Select(d => new object[] {d});
            }
        }
    }

    internal class DmsIntegrationSettingsFixture : IFixture<DmsIntegrationSettings>
    {
        public GroupedConfigSettings GroupedSettings = Substitute.For<GroupedConfigSettings>();

        public string GroupUsed
        {
            get
            {
                string group = null;
                // ReSharper disable once ObjectCreationAsStatement
                new DmsIntegrationSettings(g =>
                {
                    group = g;
                    return GroupedSettings;
                });

                return group;
            }
        }

        public DmsIntegrationSettings Subject => new DmsIntegrationSettings(GroupedSettingsResolver);

        GroupedConfigSettings GroupedSettingsResolver(string s)
        {
            return GroupedSettings;
        }
    }
}