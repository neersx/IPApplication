using Dependable;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Security.Authorization
{
    public class UserResetPasswordEmailRequiredHandlerPerformJob : IPerformImmediateBackgroundJob
    {
        public string Type => nameof(UserResetPasswordEmailRequired);

        public SingleActivity GetJob(JObject data)
        {
            var userMessage = data.ToObject<UserResetPasswordMessage>();

            return Activity.Run<UserResetPasswordEmailRequired>(_ => _.EmailUser(userMessage));
        }
    }
}