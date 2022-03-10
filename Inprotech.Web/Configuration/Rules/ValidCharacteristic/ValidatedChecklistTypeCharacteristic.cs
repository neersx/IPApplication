using System.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{
    public interface IValidatedChecklistTypeCharacteristic
    {
        ValidatedCharacteristic GetChecklistType(short? checklistTypeId);
    }
    public class ValidatedChecklistTypeCharacteristic : IValidatedChecklistTypeCharacteristic
    {
        readonly IChecklists _checklistTypes;

        public ValidatedChecklistTypeCharacteristic(IChecklists checklistTypes)
        {
            _checklistTypes = checklistTypes;
        }

        public ValidatedCharacteristic GetChecklistType(short? checklistTypeId)
        {
            if (checklistTypeId == null)
                return new ValidatedCharacteristic();

            var ct = _checklistTypes.Get().FirstOrDefault(_ => _.Key == checklistTypeId);
            return new ValidatedCharacteristic(ct.Key.ToString(), ct.Value);
        }
    }
}