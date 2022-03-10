using System.Collections.Generic;
using System.Collections.ObjectModel;
using InprotechKaizen.Model.Components.Policing;

namespace InprotechKaizen.Model.Components.Cases.PostModificationTasks
{
    public class PostCaseDetailModificationTaskResult
    {
        public PostCaseDetailModificationTaskResult()
        {
            PolicingRequests = new Collection<IQueuedPolicingRequest>();
        }

        public ICollection<IQueuedPolicingRequest> PolicingRequests { get; set; }
    }
}