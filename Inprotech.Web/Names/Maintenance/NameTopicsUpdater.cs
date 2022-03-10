using System;
using System.Collections.Generic;
using System.Linq;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Accounting.Creditor;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Names.Maintenance
{
    public class NameTopicsUpdater : ITopicsUpdater<Name>
    {
        readonly IIndex<string, ITopicDataUpdater<Name>> _topicDataUpdaters;
        readonly IIndex<string, ITopicValidator<Name>> _topicValidators;
        readonly IDbContext _dbContext;

        public NameTopicsUpdater(IIndex<string, ITopicValidator<Name>> topicValidators,
                                 IIndex<string, ITopicDataUpdater<Name>> topicDataUpdaters, IDbContext dbContext)
        {
            _topicValidators = topicValidators;
            _topicDataUpdaters = topicDataUpdaters;
            _dbContext = dbContext;
        }
        public IEnumerable<ValidationError> Validate(MaintenanceSaveModel model, TopicGroups topicGroup, Name parentRecord)
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

        public void Update(MaintenanceSaveModel model, TopicGroups topicGroup, Name parentRecord)
        {
            foreach (var topic in model.Topics)
            {
                if (_topicDataUpdaters.TryGetValue(topicGroup + topic.Key, out var updateData))
                {
                    updateData.UpdateData(topic.Value, model, parentRecord);
                }
            }

            _dbContext.Update(from n in _dbContext.Set<Name>()
                              where n.Id == parentRecord.Id
                              select n,
                              _ => new Name
                              {
                                  DateChanged = DateTime.Now
                              });

        }

        public void PostSave(MaintenanceSaveModel model, TopicGroups topicGroup, Name parentRecord)
        {
            foreach (var topic in model.Topics)
            {
                if (topic.Key == KnownNameMaintenanceTopics.SupplierDetails)
                {
                    if (_topicDataUpdaters.TryGetValue(topicGroup + topic.Key, out var postSaveData))
                    {
                        postSaveData.PostSaveData(topic.Value, model, parentRecord);
                    }
                }
            }
        }
    }
}
