using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class ExternalSystemsFacts : FactBase
    {
        [Theory]
        [InlineData("USPTO.PrivatePAIR", DataSourceType.UsptoPrivatePair)]
        [InlineData("USPTO.TSDR", DataSourceType.UsptoTsdr)]
        [InlineData("EPO", DataSourceType.Epo)]
        [InlineData("IPOneData", DataSourceType.IpOneData)]
        public void ReturnsCodeAccordingly(string expectedCode, DataSourceType source)
        {
            BuildCaseWith(source);

            Assert.Contains(expectedCode,
                            new ExternalSystems(Db).DataSources());
        }

        void BuildCaseWith(DataSourceType dataSourceType)
        {
            new Case
            {
                Source = dataSourceType
            }.In(Db);
        }

        [Fact]
        public void ReturnsAllDataSourcesInUse()
        {
            BuildCaseWith(DataSourceType.UsptoTsdr);
            BuildCaseWith(DataSourceType.UsptoPrivatePair);

            Assert.Equal(new[] {"USPTO.TSDR", "USPTO.PrivatePAIR"},
                         new ExternalSystems(Db).DataSources());
        }
    }
}