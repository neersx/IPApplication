using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Maintenance.Topics;
using Inprotech.Web.Names.Maintenance.Models;
using InprotechKaizen.Model.Names;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Names.Maintenance.Validators
{
    public class SupplierDetailsTopicValidator : ITopicValidator<Name>
    {
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public SupplierDetailsTopicValidator(ITaskSecurityProvider taskSecurityProvider)
        {
            _taskSecurityProvider = taskSecurityProvider;
        }

        public IEnumerable<ValidationError> Validate(JObject topicData, MaintenanceSaveModel model, Name name)
        {
            if (!_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainName))
            {
                yield return ValidationErrors.TopicError(KnownNameMaintenanceTopics.SupplierDetails, "You do not have permission to modify supplier details.");
                yield break;
            }
            
            var topic = topicData.ToObject<SupplierDetailsSaveModel>();

            if (string.IsNullOrEmpty(topic.SupplierType))
            {
                yield return ValidationErrors.Required("supplierType");
            }

            if (string.IsNullOrEmpty(topic.SendToName?.Code))
            {
                yield return ValidationErrors.Required("sendToName");
            }

            if (!string.IsNullOrEmpty(topic.RestrictionKey) && string.IsNullOrEmpty(topic.ReasonCode))
            {
                yield return ValidationErrors.Required("reasonCode");
            }
        }
       
    }
}
