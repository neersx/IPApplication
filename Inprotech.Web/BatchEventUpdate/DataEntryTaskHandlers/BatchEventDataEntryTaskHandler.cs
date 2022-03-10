using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.BatchEventUpdate.Models;
using Inprotech.Web.BatchEventUpdate.Validators;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate.DataEntryTaskHandlers
{
    public class BatchEventDataEntryTaskHandler : IDataEntryTaskHandler<CaseUpdateModel>
    {
        readonly IEventDetailUpdateHandler _updateHandler;
        readonly IEventDetailUpdateValidator _validator;

        public BatchEventDataEntryTaskHandler(
            IEventDetailUpdateValidator validator,
            IEventDetailUpdateHandler updateHandler)
        {
            if(validator == null) throw new ArgumentNullException("validator");
            if(updateHandler == null) throw new ArgumentNullException("updateHandler");

            _validator = validator;
            _updateHandler = updateHandler;
        }

        public string Name
        {
            get { return "batch-event-update"; }
        }

        public DataEntryTaskHandlerOutput Validate(Case @case, DataEntryTask dataEntryTask, CaseUpdateModel data)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");
            if(data == null) throw new ArgumentNullException("data");

            return new DataEntryTaskHandlerOutput(ValidateCore(@case, dataEntryTask, data).ToArray());
        }

        public DataEntryTaskHandlerOutput ApplyChanges(Case @case, DataEntryTask dataEntryTask, CaseUpdateModel data)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");
            if(data == null) throw new ArgumentNullException("data");

            // TODO: Handle the return of PolicingRequests and change validateCore to return results
            var results = ValidateCore(@case, dataEntryTask, data).ToArray();

            if(results.Any(r => r.Severity == Severity.Error)) return new DataEntryTaskHandlerOutput(results);

            var documentsThatMustBeGenerated = GetDocumentsThatMustBeGenerated(dataEntryTask);

            var pr1 = _updateHandler.ApplyChanges(
                                                  @case,
                                                  dataEntryTask,
                                                  data.OfficialNumber,
                                                  data.FileLocationId,
                                                  data.WhenMovedToLocation,
                                                  data.AvailableEvents,
                                                  documentsThatMustBeGenerated);

            var pr2 = _updateHandler.ProcessPostModificationTasks(@case, dataEntryTask, data.AvailableEvents);

            return new DataEntryTaskHandlerOutput(results, pr1.Combine(pr2));
        }

        IEnumerable<ValidationResult> ValidateCore(Case @case, DataEntryTask dataEntryTask, CaseUpdateModel data)
        {
            _validator.EnsureInputIsValid(
                                          @case,
                                          dataEntryTask,
                                          data.OfficialNumber,
                                          data.FileLocationId,
                                          data.AvailableEvents);

            return _validator.Validate(
                                       @case,
                                       dataEntryTask,
                                       data.OfficialNumber,
                                       data.FileLocationId,
                                       data.AvailableEvents);
        }

        static Document[] GetDocumentsThatMustBeGenerated(DataEntryTask dataEntryTask)
        {
            return dataEntryTask.DocumentRequirements
                                .Where(dr => dr.InternalMandatoryFlag.HasValue && dr.InternalMandatoryFlag.Value > 0M)
                                .Select(dr => dr.Document).ToArray();
        }
    }
}