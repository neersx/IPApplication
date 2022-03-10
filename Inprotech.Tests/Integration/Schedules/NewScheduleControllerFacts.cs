using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json.Linq;
using NSubstitute;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules
{
    public class NewScheduleControllerFacts : FactBase
    {
        public class NewScheduleControllerFixture : IFixture<NewScheduleController>
        {
            public NewScheduleControllerFixture(InMemoryDbContext db)
            {
                Repository = db;

                DataSourceSchedule = Substitute.For<IDataSourceSchedule>();

                Subject = new NewScheduleController(Repository, DataSourceSchedule);
            }

            public IDataSourceSchedule DataSourceSchedule { get; set; }

            public InMemoryDbContext Repository { get; }

            public NewScheduleController Subject { get; }

            public NewScheduleControllerFixture WithValidatedSchedule(Schedule schedule)
            {
                DataSourceSchedule.TryCreateFrom(Arg.Any<JObject>())
                                  .ReturnsForAnyArgs(new DataSourceScheduleResult
                                  {
                                      ValidationResult = "success",
                                      Schedule = schedule
                                  });

                return this;
            }

            public NewScheduleControllerFixture WithValidationError(string error)
            {
                DataSourceSchedule.TryCreateFrom(Arg.Any<JObject>())
                                  .ReturnsForAnyArgs(new DataSourceScheduleResult { ValidationResult = error });

                return this;
            }
        }

        [Fact]
        public async Task ShouldCreateSchedule()
        {
            var f = new NewScheduleControllerFixture(Db)
                .WithValidatedSchedule(new Schedule());

            var r = await f.Subject.Create(new JObject());
            var savedSchedule = f.Repository.Set<Schedule>().First();

            Assert.Equal(1, f.Repository.Set<Schedule>().Count());
            Assert.Equal("success", r.Result);
            Assert.Equal(r.Id, savedSchedule.Id);
        }

        [Fact]
        public async Task ShouldReturnValidationError()
        {
            var f = new NewScheduleControllerFixture(Db)
                .WithValidationError("invalid-schedule-name");

            var r = await f.Subject.Create(new JObject());

            Assert.Empty(f.Repository.Set<Schedule>());
            Assert.Equal("invalid-schedule-name", r.Result);
        }
    }
}