using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Policing;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public class PolicingRequests
    {
        public PolicingRequests(IQueuedPolicingRequest[] policingRequests, bool shouldPoliceImmediately = false)
        {
            if (policingRequests == null) throw new ArgumentNullException(nameof(policingRequests));
            Requests = policingRequests;
            ShouldPoliceImmediately = shouldPoliceImmediately;
        }

        public bool ShouldPoliceImmediately { get; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public IQueuedPolicingRequest[] Requests { get; }
    }

    public static class PolicingRequestsExtensions
    {
        public static PolicingRequests Combine(this PolicingRequests @this, PolicingRequests other)
        {
            if (@this == null) throw new ArgumentNullException(nameof(@this));
            if (other == null) throw new ArgumentNullException(nameof(other));

            return new PolicingRequests(
                                        @this.Requests.Concat(other.Requests).ToArray(),
                                        @this.ShouldPoliceImmediately || other.ShouldPoliceImmediately);
        }
    }

    public class DataEntryTaskHandlerOutput
    {
        public DataEntryTaskHandlerOutput(
            ValidationResult[] validationResults = null,
            PolicingRequests policingRequests = null)
        {
            ValidationResults = validationResults ?? new ValidationResult[0];
            PolicingRequests = policingRequests ?? new PolicingRequests(new IQueuedPolicingRequest[0]);
        }

        public bool HasErrors
        {
            get { return ValidationResults.Any(vrm => vrm.Severity == Severity.Error); }
        }

        public bool HasWarnings
        {
            get { return ValidationResults.Any(vrm => vrm.Severity == Severity.Warning); }
        }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public ValidationResult[] ValidationResults { get; set; }

        [JsonIgnore]
        public PolicingRequests PolicingRequests { get; }
    }
}