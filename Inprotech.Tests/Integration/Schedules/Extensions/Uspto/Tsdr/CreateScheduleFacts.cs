using System.Threading.Tasks;
using Inprotech.Integration.Schedules.Extensions.Uspto.Tsdr;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Integration.Schedules.Extensions.Uspto.Tsdr
{
    public class CreateScheduleFacts : FactBase
    {
        const int QueryKey = 1;
        const int RunAs = 2;

        static JObject Build(int? savedQuery, int? runAs)
        {
            return new JObject
            {
                {"savedQueryId", savedQuery},
                {"runAsUserId", runAs}
            };
        }

        [Fact]
        public async Task CreatesSchedule()
        {
            var r = await new CreateSchedule().TryCreateFrom(Build(QueryKey, RunAs));
            Assert.True(r.IsValid);
            Assert.Equal("success", r.ValidationResult);
            Assert.NotNull(r.Schedule.ExtendedSettings);

            var e = JsonConvert.DeserializeObject<TsdrSchedule>(r.Schedule.ExtendedSettings);
            Assert.Equal(RunAs, e.RunAsUserId);
            Assert.Equal(QueryKey, e.SavedQueryId);
        }

        [Fact]
        public async Task RejectsIfRunAsNotIsNotFound()
        {
            var r = await new CreateSchedule().TryCreateFrom(Build(QueryKey, null));
            Assert.False(r.IsValid);
            Assert.Equal("invalid-run-as-user", r.ValidationResult);
        }

        [Fact]
        public async Task RejectsIfSavedQueryNotProvided()
        {
            var r = await new CreateSchedule().TryCreateFrom(Build(null, RunAs));
            Assert.False(r.IsValid);
            Assert.Equal("invalid-saved-query", r.ValidationResult);
        }
    }
}