using System.Linq;
using Inprotech.Web.CaseSupportData;

namespace Inprotech.Web.Configuration.Rules.ValidCharacteristic
{
    public interface IValidatedActionCharacteristic
    {
        Characteristics.ValidatedCharacteristic GetAction(string actionId, string country, string propertyType, string caseType);
    }

    public class ValidatedActionCharacteristic : IValidatedActionCharacteristic
    {
        readonly IActions _actions;

        public ValidatedActionCharacteristic(IActions actions)
        {
            _actions = actions;
        }

        public Characteristics.ValidatedCharacteristic GetAction(string actionId, string country, string propertyType, string caseType)
        {
            if (string.IsNullOrWhiteSpace(actionId)) return new Characteristics.ValidatedCharacteristic();

            var a = _actions.Get(country, propertyType, caseType).FirstOrDefault(_ => _.Code == actionId);
            if (a != null) return new Characteristics.ValidatedCharacteristic(a.Code, a.Name);

            a = _actions.Get(null, null, null).FirstOrDefault(_ => _.Code == actionId);
            return new Characteristics.ValidatedCharacteristic(a.Code, a.Name, false);
        }
    }
}
