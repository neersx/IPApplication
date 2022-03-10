using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.DataSources;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.DataSources
{
    public class AvailableDataSourcesFacts
    {
        public AvailableDataSourcesFacts()
        {
            _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
        }

        readonly ITaskSecurityProvider _taskSecurityProvider;

        static ValidSecurityTask Build(ApplicationTask task, bool hasAccess)
        {
            return new ValidSecurityTask((short) task, false, false, false, hasAccess);
        }

        [Theory]
        [InlineData(ApplicationTask.ScheduleEpoDataDownload, DataSourceType.Epo)]
        [InlineData(ApplicationTask.ScheduleIpOneDataDownload, DataSourceType.IpOneData)]
        [InlineData(ApplicationTask.ScheduleUsptoTsdrDataDownload, DataSourceType.UsptoTsdr)]
        [InlineData(ApplicationTask.ScheduleUsptoPrivatePairDataDownload, DataSourceType.UsptoPrivatePair)]
        [InlineData(ApplicationTask.ScheduleFileDataDownload, DataSourceType.File)]
        public void ReturnsAvailableSourcesBasedOnTaskSecurity(ApplicationTask task, DataSourceType expectedType)
        {
            _taskSecurityProvider.ListAvailableTasks()
                                 .Returns(
                                          new[]
                                          {
                                              Build(task, true)
                                          }
                                         );

            var r = new AvailableDataSources(_taskSecurityProvider).List();

            Assert.Equal(new[] {expectedType}, r);
        }

        [Fact]
        public void ReturnsAvailableDataSources()
        {
            _taskSecurityProvider.ListAvailableTasks()
                                 .Returns(
                                          new[]
                                          {
                                              Build(ApplicationTask.ScheduleUsptoTsdrDataDownload, true),
                                              Build(ApplicationTask.ScheduleUsptoPrivatePairDataDownload, true)
                                          }
                                         );

            var r = new AvailableDataSources(_taskSecurityProvider).List();

            Assert.Equal(new[] {DataSourceType.UsptoTsdr, DataSourceType.UsptoPrivatePair}, r);
        }
    }
}