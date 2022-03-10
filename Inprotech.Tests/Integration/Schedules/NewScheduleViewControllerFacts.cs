using Autofac.Features.Indexed;
using Inprotech.Integration;
using Inprotech.Integration.DataSources;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Fakes;
using NSubstitute;
using System.Collections.Generic;
using System.Linq;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class NewScheduleViewControllerFacts : FactBase
    {
        public class NewScheduleViewControllerFixture : IFixture<NewScheduleViewController>
        {
            readonly IDataSourceSchedulePrerequisites _prerequisites = Substitute.For<IDataSourceSchedulePrerequisites>();

            public NewScheduleViewControllerFixture(InMemoryDbContext db)
            {
                Repository = db;

                AvailableDataSources = Substitute.For<IAvailableDataSources>();

                Settings = Substitute.For<IDmsIntegrationSettings>();

                var prerequistesIndex = Substitute.For<IIndex<DataSourceType, IDataSourceSchedulePrerequisites>>();
                prerequistesIndex.TryGetValue(Arg.Any<DataSourceType>(), out _)
                                 .Returns(x =>
                                 {
                                     x[1] = (DataSourceType)x[0] == DataSourceType.IpOneData
                                         ? _prerequisites
                                         : null;
                                     return x[1] != null;
                                 });

                Subject = new NewScheduleViewController(Repository, AvailableDataSources, Settings, prerequistesIndex);
            }

            public IAvailableDataSources AvailableDataSources { get; }

            public IRepository Repository { get; }

            public IDmsIntegrationSettings Settings { get; }

            public NewScheduleViewController Subject { get; set; }

            public NewScheduleViewControllerFixture WithAvailableDataSource(params DataSourceType[] dataSourceTypes)
            {
                AvailableDataSources.List().Returns(dataSourceTypes);
                return this;
            }

            public NewScheduleViewControllerFixture WithDmsIntegrationEnabled(DataSourceType dataSource, bool dmsIntegrationEnabled)
            {
                Settings.IsEnabledFor(dataSource).Returns(dmsIntegrationEnabled);
                return this;
            }

            public NewScheduleViewControllerFixture WithUnmetPrerequisites(string condition)
            {
                _prerequisites.Validate(out _)
                              .Returns(x =>
                              {
                                  x[0] = condition;
                                  return string.IsNullOrWhiteSpace(condition);
                              });

                return this;
            }
        }

        [Theory]
        [InlineData(null)]
        [InlineData("missing-platform-registration")]
        public void ReturnsPrerequisiteValidationError(string validationError)
        {
            var data = new NewScheduleViewControllerFixture(Db)
                       .WithAvailableDataSource(DataSourceType.IpOneData)
                       .WithUnmetPrerequisites(validationError)
                       .Subject.Get();

            var r = ((IEnumerable<dynamic>)data.DataSources).Single();

            Assert.Equal("IpOneData", r.Id);
            Assert.Equal(validationError, r.Error);
        }

        [Fact]
        public void ReturnsAllAvailableDataSources()
        {
            var data = new NewScheduleViewControllerFixture(Db)
                       .WithAvailableDataSource(DataSourceType.UsptoPrivatePair, DataSourceType.UsptoTsdr)
                       .Subject.Get();

            Assert.Equal("UsptoPrivatePair", ((IEnumerable<dynamic>)data.DataSources).First().Id);
            Assert.Equal("UsptoTsdr", ((IEnumerable<dynamic>)data.DataSources).Last().Id);
        }

        [Fact]
        public void ReturnsDmsIntegrationEnabledSettingsForDataSources()
        {
            var data = new NewScheduleViewControllerFixture(Db)
                       .WithAvailableDataSource(DataSourceType.UsptoPrivatePair, DataSourceType.UsptoTsdr)
                       .WithDmsIntegrationEnabled(DataSourceType.UsptoPrivatePair, true)
                       .WithDmsIntegrationEnabled(DataSourceType.UsptoTsdr, false)
                       .Subject.Get();

            Assert.Equal(true, ((IEnumerable<dynamic>)data.DataSources).First().DmsIntegrationEnabled);
            Assert.Equal(false, ((IEnumerable<dynamic>)data.DataSources).Last().DmsIntegrationEnabled);
        }

        [Fact]
        public void ReturnsPermittedAvailableDataSources()
        {
            var data = new NewScheduleViewControllerFixture(Db)
                       .WithAvailableDataSource(DataSourceType.IpOneData)
                       .Subject.Get();

            Assert.Equal("IpOneData", ((IEnumerable<dynamic>)data.DataSources).Single().Id);
        }
    }
}