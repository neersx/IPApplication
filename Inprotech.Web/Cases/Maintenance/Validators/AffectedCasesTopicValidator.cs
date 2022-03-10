using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Cases;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Cases.Maintenance.Validators
{
    public class AffectedCasesTopicValidator : ITopicValidator<Case>
    {
        public AffectedCasesTopicValidator()
        {
        }

        public IEnumerable<ValidationError> Validate(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
            var topic = topicData.ToObject<DesignElementSaveModel>();
            var errors = new List<ValidationError>();
            return errors;
        }
    }
}
