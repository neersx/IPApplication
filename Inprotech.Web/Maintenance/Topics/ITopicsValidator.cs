using System.Collections.Generic;
using Inprotech.Infrastructure.Validations;

namespace Inprotech.Web.Maintenance.Topics
{
    public interface ITopicsUpdater<T>
    {
        IEnumerable<ValidationError> Validate(MaintenanceSaveModel model, TopicGroups topicGroup, T parentRecord);
        void Update(MaintenanceSaveModel model, TopicGroups topicGroup, T parentRecord);
        void PostSave(MaintenanceSaveModel model, TopicGroups topicGroup, T parentRecord);
    }
}