using Inprotech.Web.Characteristics;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;

namespace Inprotech.Web.Configuration.Rules
{
    public interface ICharacteristicsValidator
    {
        ValidatedCharacteristics Validate(WorkflowCharacteristics criteria);
    }
}
