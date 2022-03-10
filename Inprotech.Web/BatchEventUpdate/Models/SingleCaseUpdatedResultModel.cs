using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class SingleCaseUpdatedResultModel
    {
        public SingleCaseUpdatedResultModel(Case @case, DataEntryTaskCompletionResult dataEntryTaskCompletionResult)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dataEntryTaskCompletionResult == null) throw new ArgumentNullException("dataEntryTaskCompletionResult");

            CaseId = @case.Id;

            CaseStatusDescription = @case.CaseStatus != null ? @case.CaseStatus.Name : null;

            CurrentOfficialNumber = @case.CurrentOfficialNumber;

            IsCompleted = dataEntryTaskCompletionResult.IsCompleted;
            var handlerResult = dataEntryTaskCompletionResult.HandlerResults.SingleOrDefault();

            ValidationResults = dataEntryTaskCompletionResult.ValidationResults
                                                             .Concat(
                                                                     handlerResult == null
                                                                         ? Enumerable.Empty<ValidationResult>()
                                                                         : handlerResult.Output.ValidationResults)
                                                             .ToArray();
        }

        public int CaseId { get; set; }

        public string CaseStatusDescription { get; set; }

        public string CurrentOfficialNumber { get; set; }

        public bool IsCompleted { get; set; }

        public ValidationResult[] ValidationResults { get; set; }
    }
}