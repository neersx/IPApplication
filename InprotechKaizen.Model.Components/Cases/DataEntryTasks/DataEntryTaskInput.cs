using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Runtime.Serialization;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public class DataEntryTaskInput
    {
        public DataEntryTaskInput(
            Case @case,
            DataEntryTask dataEntryTask,
            string confirmationPassword,
            KeyValuePair<string, object>[] data,
            bool bypassWarnings,
            int[] sanityCheckResultIds)
        {
            Case = @case;
            DataEntryTask = dataEntryTask;
            ConfirmationPassword = confirmationPassword;
            Data = data;
            BypassWarnings = bypassWarnings;
            SanityCheckResultIds = sanityCheckResultIds ?? new int[0];
        }

        public Case Case { get; set; }

        public DataEntryTask DataEntryTask { get; set; }

        public string ConfirmationPassword { get; set; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public KeyValuePair<string, object>[] Data { get; set; }

        public bool BypassWarnings { get; set; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public int[] SanityCheckResultIds { get; set; }

        [OnDeserializing]
        void OnDeserializing(StreamingContext streamingContext)
        {
            SanityCheckResultIds = new int[0];
        }
    }
}