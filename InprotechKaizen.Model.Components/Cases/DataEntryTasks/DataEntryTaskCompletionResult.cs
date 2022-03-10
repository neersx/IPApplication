using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public class DataEntryTaskCompletionResult
    {
        public DataEntryTaskCompletionResult(
            bool isCompleted,
            DataEntryTaskHandlerResult[] handlerResults,
            ValidationResult[] validationResults = null)
        {
            if (handlerResults == null) throw new ArgumentNullException("handlerResults");

            IsCompleted = isCompleted;
            HandlerResults = handlerResults;
            ValidationResults = validationResults ?? new ValidationResult[0];
        }

        public DataEntryTaskCompletionResult(ValidationResult validationResult)
        {
            if (validationResult == null) throw new ArgumentNullException("validationResult");

            ValidationResults = new[] {validationResult};
            HandlerResults = new DataEntryTaskHandlerResult[0];
        }

        public bool HasErrors
        {
            get
            {
                return ValidationResults.Any(vr => vr.Severity == Severity.Error) ||
                       HandlerResults.Any(hr => hr.Output.HasErrors);
            }
        }

        public bool HasWarnings
        {
            get
            {
                return ValidationResults.Any(vr => vr.Severity == Severity.Warning) ||
                       HandlerResults.Any(hr => hr.Output.HasWarnings);
            }
        }

        public bool IsCompleted { get; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public ValidationResult[] ValidationResults { get; }

        [SuppressMessage("Microsoft.Performance", "CA1819:PropertiesShouldNotReturnArrays")]
        public DataEntryTaskHandlerResult[] HandlerResults { get; }
    }
}