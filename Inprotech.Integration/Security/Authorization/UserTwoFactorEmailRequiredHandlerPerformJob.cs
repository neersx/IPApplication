using Dependable;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Security.Authorization
{
    public class UserTwoFactorEmailRequiredHandlerPerformJob : IPerformImmediateBackgroundJob
    {
        public string Type => nameof(UserTwoFactorEmailRequired);

        public SingleActivity GetJob(JObject data)
        {
            var userAccount2FaMessage = data.ToObject<UserAccount2FaMessage>();

            return Activity.Run<UserTwoFactorEmailRequired>(_ => _.EmailUser(userAccount2FaMessage));
        }
    }
}