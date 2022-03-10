using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Cases.Maintenance.Validators
{
    public class ChecklistQuestionsTopicValidator : ITopicValidator<Case>
    {
        readonly IChecklists _checklists;
        public ChecklistQuestionsTopicValidator(IChecklists checklists)
        {
            _checklists = checklists;
        }

        public IEnumerable<ValidationError> Validate(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
            var topic = topicData.ToObject<ChecklistQuestionsSaveModel>();
            var errors = new List<ValidationError>();
            foreach (var e in topic.Rows.Where(x => true))
            {
                errors.AddRange(_checklists.ValidateChecklistQuestions(@case, e, topic.Rows));
            }
            return errors;
        }
    }
}
