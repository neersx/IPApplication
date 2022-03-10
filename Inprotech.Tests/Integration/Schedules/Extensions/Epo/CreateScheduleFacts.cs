using System.Threading.Tasks;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Integration.Schedules.Extensions.Epo;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules.Extensions.Epo
{
    public class CreateScheduleFacts : FactBase
    {
        const int QueryKey = 1;
        const int RunAs = 2;

        readonly IDataSourceSchedulePrerequisites _prerequisites = Substitute.For<IDataSourceSchedulePrerequisites>();

        static JObject Build(int? savedQuery, int? runAs)
        {
            return new JObject
            {
                {"savedQueryId", savedQuery},
                {"runAsUserId", runAs}
            };
        }

        IDataSourceSchedulePrerequisites ConfigurePrerequisite(string unmetCondition = null)
        {
            _prerequisites.Validate(out string _)
                          .Returns(x =>
                          {
                              x[0] = unmetCondition;
                              return string.IsNullOrWhiteSpace(unmetCondition);
                          });

            return _prerequisites;
        }

        [Fact]
        public async Task CreatesSchedule()
        {
            var subject = new CreateSchedule(ConfigurePrerequisite());
            var r = await subject.TryCreateFrom(Build(QueryKey, RunAs));

            Assert.True(r.IsValid);
            Assert.Equal("success", r.ValidationResult);
            Assert.NotNull(r.Schedule.ExtendedSettings);

            var e = JsonConvert.DeserializeObject<EpoSchedule>(r.Schedule.ExtendedSettings);
            Assert.Equal(RunAs, e.RunAsUserId);
            Assert.Equal(QueryKey, e.SavedQueryId);
        }

        [Fact]
        public async Task RejectsIfConsumerKeysAreNotConfigured()
        {
            var subject = new CreateSchedule(ConfigurePrerequisite("epo-missing-keys"));
            var r = await subject.TryCreateFrom(Build(QueryKey, RunAs));
            Assert.False(r.IsValid);
            Assert.Equal("epo-missing-keys", r.ValidationResult);
        }

        [Fact]
        public async Task RejectsIfRunAsNotIsNotFound()
        {
            var subject = new CreateSchedule(ConfigurePrerequisite());
            var r = await subject.TryCreateFrom(Build(QueryKey, null));
            Assert.False(r.IsValid);
            Assert.Equal("invalid-run-as-user", r.ValidationResult);
        }

        [Fact]
        public async Task RejectsIfSavedQueryNotProvided()
        {
            var subject = new CreateSchedule(ConfigurePrerequisite());
            var r = await subject.TryCreateFrom(Build(null, RunAs));
            Assert.False(r.IsValid);
            Assert.Equal("invalid-saved-query", r.ValidationResult);
        }
    }
}