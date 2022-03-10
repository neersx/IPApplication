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
    public class DesignElementsTopicValidator : ITopicValidator<Case>
    {
        readonly IDesignElements _designElements;
        public DesignElementsTopicValidator(IDesignElements designElements)
        {
            _designElements = designElements;
        }

        public IEnumerable<ValidationError> Validate(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
            var topic = topicData.ToObject<DesignElementSaveModel>();
            var errors = new List<ValidationError>();
            foreach (var e in topic.Rows.Where(x => x.Status != KnownModifyStatus.Delete))
            {
                errors.AddRange(_designElements.ValidateDesignElements(@case, e, topic.Rows));
            }
            return errors;
        }
    }
}
