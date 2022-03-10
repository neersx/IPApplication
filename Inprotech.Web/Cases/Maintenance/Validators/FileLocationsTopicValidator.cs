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
    public class FileLocationsTopicValidator : ITopicValidator<Case>
    {
        readonly IFileLocations _fileLocations;

        public FileLocationsTopicValidator(IFileLocations fileLocations)
        {
            _fileLocations = fileLocations;
        }

        public IEnumerable<ValidationError> Validate(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
            var topic = topicData.ToObject<FileLocationsSaveModel>();
            var errors = new List<ValidationError>();
            foreach (var e in topic.Rows.Where(x => x.Status != KnownModifyStatus.Delete))
            {
                errors.AddRange(_fileLocations.ValidateFileLocationsOnSave(@case, e, topic.Rows));
            }
            return errors;
        }
    }
}
