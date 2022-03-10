using System.Collections.Generic;
using Inprotech.Infrastructure.Validations;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Maintenance.Topics
{
    public interface ITopicValidator<T>
    {
        IEnumerable<ValidationError> Validate(JObject topicData, MaintenanceSaveModel model, T parentRecord);
    }
}
