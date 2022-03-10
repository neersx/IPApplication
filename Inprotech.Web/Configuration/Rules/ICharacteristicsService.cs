using Inprotech.Web.Characteristics;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;

namespace Inprotech.Web.Configuration.Rules
{
    public interface ICharacteristicsService
    {
        ValidatedCharacteristics GetValidCharacteristics(WorkflowCharacteristics characteristics);
    }
}