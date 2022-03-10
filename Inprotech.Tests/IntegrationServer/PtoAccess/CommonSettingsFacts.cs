using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Settings;
using Inprotech.IntegrationServer.PtoAccess;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess
{
    public class CommonSettingsFacts
    {
        readonly GroupedConfigSettings _settings = Substitute.For<GroupedConfigSettings>();

        public static List<object[]> AllDataSources
        {
            get
            {
                return Enum.GetValues(typeof(DataSourceType))
                           .Cast<DataSourceType>()
                           .Select(_ => new object[]
                           {
                               _
                           })
                           .ToList();
            }
        }

        [Theory]
        [MemberData(nameof(AllDataSources), MemberType = typeof(CommonSettingsFacts))]
        public void ResolvesSettingByDataSource(DataSourceType source)
        {
            var chunkSize = Fixture.Integer();

            _settings.GetValueOrDefault<int?>("Request.ChunkSize")
                     .Returns(chunkSize);

            var r = new CommonSettings(Factory).GetChunkSize(source);

            Assert.Equal(chunkSize, r);
        }

        [Theory]
        [MemberData(nameof(AllDataSources), MemberType = typeof(CommonSettingsFacts))]
        public void DefaultsTo1000(DataSourceType source)
        {
            _settings.GetValueOrDefault<int?>("Request.ChunkSize")
                     .Returns((int?) null);

            var r = new CommonSettings(Factory).GetChunkSize(source);

            Assert.Equal(1000, r);
        }

        GroupedConfigSettings Factory(string s)
        {
            return _settings;
        }
    }
}