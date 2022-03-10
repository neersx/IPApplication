using Dependable;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Security.Authorization
{
    public class UserAccountLockedHandlerPerformJob : IPerformImmediateBackgroundJob
    {
        public string Type => nameof(UserAccountLocked);

        public SingleActivity GetJob(JObject data)
        {
            var userLockedMessage = data.ToObject<UserAccountLockedMessage>();

            return Activity.Run<UserAccountLocked>(_ => _.NotifyAllConcerned(userLockedMessage));
        }
    }
}