using Dependable;
using Inprotech.Contracts.Messages;
using Inprotech.Integration.Jobs;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Email
{
    public class EventNotesMailMessagePerformJob : IPerformImmediateBackgroundJob
    {
        public string Type => nameof(EventNotesMailMessageExecution);

        public SingleActivity GetJob(JObject data)
        {
            var userMessage = data.ToObject<EventNotesMailMessage>();

            return Activity.Run<EventNotesMailMessageExecution>(_ => _.EmailUser(userMessage));
        }
    }
}
