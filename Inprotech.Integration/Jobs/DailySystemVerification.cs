using Dependable;
using Inprotech.Integration.Security.Authorization;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Jobs
{
    public class DailySystemVerification : IPerformBackgroundJob
    {
        public string Type => typeof(DailySystemVerification).Name;

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<ExpiringPassword>(_ => _.CheckAndNotify())
                           .Then<ExpiringLicenses>(_ => _.CheckAndNotify())
                           .Then<ExpiredAccessTokens>(_ => _.Remove())
                           .Then<AbsoluteLogout>(_ => _.Trigger());
        }
    }
}
