using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.DataSources;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class ScheduleDetailsFacts
    {
        public class GetMethod : FactBase
        {
            [Theory]
            [InlineData(2, new[] {DataSourceType.UsptoPrivatePair})]
            [InlineData(3, new[] {DataSourceType.UsptoPrivatePair, DataSourceType.UsptoTsdr})]
            [InlineData(1, new[] {DataSourceType.UsptoTsdr})]
            [InlineData(0, new DataSourceType[0])]
            public void ReturnsOnlySchedulesWithPermittedDataSources(int numberOfSchedulesExpected, DataSourceType[] permittedDataSources)
            {
                var f = new ScheduleDetailsFixture(Db)
                        .WithScheduleAgainst(DataSourceType.UsptoPrivatePair)
                        .WithScheduleAgainst(DataSourceType.UsptoPrivatePair)
                        .WithScheduleAgainst(DataSourceType.UsptoTsdr)
                        .WithAccessTo(permittedDataSources);

                var r = f.Subject.Get();
                var schedules = r.ToArray();

                Assert.Equal(numberOfSchedulesExpected, schedules.Length);
            }

            [Fact]
            public void ReturnsOnlyActiveSchedules()
            {
                new Schedule {Name = "Active #1", IsDeleted = false}.In(Db);
                new Schedule {Name = "Deleted", IsDeleted = true}.In(Db);
                new Schedule {Name = "Active #2", IsDeleted = false}.In(Db);

                var f = new ScheduleDetailsFixture(Db)
                    .WithAccessTo(new[] {DataSourceType.UsptoPrivatePair});

                var r = f.Subject.Get();
                var schedules = r.ToArray();

                Assert.Equal(2, schedules.Length);
            }
        }

        public class ScheduleDetailsFixture : IFixture<IScheduleDetails>
        {
            readonly InMemoryDbContext _db;

            public ScheduleDetailsFixture(InMemoryDbContext db)
            {
                _db = db;
                AvailableDataSources = Substitute.For<IAvailableDataSources>();

                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new User("fee-earner", false));

                DataSourceSchedule = Substitute.For<IDataSourceSchedule>();
                DataSourceSchedule.View(Arg.Any<Schedule>()).Returns("formatted schedule return");
                DataSourceSchedule.View(Arg.Any<IQueryable<Schedule>>()).Returns(x => x[0]);

                Subject = new ScheduleDetails(db, AvailableDataSources, DataSourceSchedule);
            }

            public IAvailableDataSources AvailableDataSources { get; }

            public ISecurityContext SecurityContext { get; }

            public IDataSourceSchedule DataSourceSchedule { get; }

            public IScheduleDetails Subject { get; }

            public ScheduleDetailsFixture WithScheduleAgainst(DataSourceType dataSourceType)
            {
                new Schedule {DataSourceType = dataSourceType}.In(_db);
                return this;
            }

            public ScheduleDetailsFixture WithAccessTo(DataSourceType[] permittedDataSources)
            {
                AvailableDataSources.List().Returns(permittedDataSources);
                return this;
            }
        }
    }
}