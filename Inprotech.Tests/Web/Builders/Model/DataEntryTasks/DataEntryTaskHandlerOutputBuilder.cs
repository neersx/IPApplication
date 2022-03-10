using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Policing;
using NSubstitute;

namespace Inprotech.Tests.Web.Builders.Model.DataEntryTasks
{
    public class DataEntryTaskHandlerOutputBuilder : IBuilder<DataEntryTaskHandlerOutput>
    {
        public bool HasWarnings { get; set; }
        public bool HasErrors { get; set; }
        public PolicingRequests PolicingRequests { get; set; }

        public DataEntryTaskHandlerOutput Build()
        {
            var vresults = new List<ValidationResult>();

            if (HasErrors)
            {
                vresults.Add(new ValidationResult(Fixture.String("Error")));
            }

            if (HasWarnings)
            {
                vresults.Add(new ValidationResult(Fixture.String("Warning"), Severity.Warning));
            }

            return new DataEntryTaskHandlerOutput(vresults.ToArray(), PolicingRequests);
        }

        public static DataEntryTaskHandlerOutputBuilder ForWarning()
        {
            return new DataEntryTaskHandlerOutputBuilder {HasWarnings = true};
        }

        public static DataEntryTaskHandlerOutputBuilder ForError()
        {
            return new DataEntryTaskHandlerOutputBuilder {HasErrors = true};
        }
    }

    public class PolicingRequestsBuilder : IBuilder<PolicingRequests>
    {
        public bool ShouldPoliceImmediately { get; set; }
        public IEnumerable<IQueuedPolicingRequest> QueuedPolicingRequests { get; set; }

        public PolicingRequests Build()
        {
            return
                new PolicingRequests(
                                     QueuedPolicingRequests == null
                                         ? new[] {Substitute.For<IQueuedPolicingRequest>()}
                                         : QueuedPolicingRequests.ToArray(),
                                     ShouldPoliceImmediately);
        }
    }
}