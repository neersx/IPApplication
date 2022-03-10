using System.Collections.Generic;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Web.Cases.Maintenance
{
    public class CaseTopicsUpdater : ITopicsUpdater<Case>
    {
        readonly IIndex<string, ITopicDataUpdater<Case>> _topicDataUpdaters;
        readonly IIndex<string, ITopicValidator<Case>> _topicValidators;

        public CaseTopicsUpdater(IIndex<string, ITopicValidator<Case>> topicValidators,
                                 IIndex<string, ITopicDataUpdater<Case>> topicDataUpdaters)
        {
            _topicValidators = topicValidators;
            _topicDataUpdaters = topicDataUpdaters;
        }

        public IEnumerable<ValidationError> Validate(MaintenanceSaveModel model, TopicGroups topicGroup, Case parentRecord)
        {
            var errors = new List<ValidationError>();
            foreach (var topic in model.Topics)
            {
                if (!_topicValidators.TryGetValue(topicGroup + topic.Key, out var validator))
                {
                    errors.Add(ValidationErrors.TopicError(topic.Key, "Topic does not support saving"));
                }
                else
                {
                    errors.AddRange(validator.Validate(topic.Value, model, parentRecord));
                }
            }

            return errors;
        }

        public void Update(MaintenanceSaveModel model, TopicGroups topicGroup, Case parentRecord)
        {
            foreach (var topic in model.Topics)
            {
                if (_topicDataUpdaters.TryGetValue(topicGroup + topic.Key, out var updateData))
                {
                    updateData.UpdateData(topic.Value, model, parentRecord);
                }
            }
        }

        public void PostSave(MaintenanceSaveModel model, TopicGroups topicGroup, Case parentRecord)
        {
            foreach (var topic in model.Topics)
            {
                if (_topicDataUpdaters.TryGetValue(topicGroup + topic.Key, out var updateData))
                {
                    updateData.PostSaveData(topic.Value, model, parentRecord);
                }
            }
        }
    }
}