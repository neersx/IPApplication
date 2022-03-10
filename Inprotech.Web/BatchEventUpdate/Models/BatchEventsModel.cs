using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class BatchEventsModel
    {
        public BatchEventsModel(
            IEnumerable<UpdatableCaseModel> updatableCases,
            IEnumerable<NonUpdatableCaseModel> nonUpdatableCases,
            bool shouldConfirmOnSave,
            bool requiresPasswordOnConfirmation)
        {
            UpdatableCases = updatableCases.ToArray();
            NonUpdatableCases = nonUpdatableCases.ToArray();
            ShouldConfirmOnSave = shouldConfirmOnSave;
            RequiresPasswordOnConfirmation = requiresPasswordOnConfirmation;
        }

        public UpdatableCaseModel[] UpdatableCases { get; set; }
        public NonUpdatableCaseModel[] NonUpdatableCases { get; set; }
        public bool ShouldConfirmOnSave { get; set; }
        public bool RequiresPasswordOnConfirmation { get; set; }
        public string NewStatus { get; set; }

        public IEnumerable<FileLocationModel> FileLocations { get; set; }
    }
}