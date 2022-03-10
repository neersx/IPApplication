using System.Linq;

namespace Inprotech.Infrastructure.Localisation
{
    public interface IResolvedCultureTranslations
    {
        string this[string key] { get; }
    }

    public class ResolvedCultureTranslations : IResolvedCultureTranslations
    {
        readonly string[] _listOfCultures;
        readonly IStaticTranslator _staticTranslator;

        public ResolvedCultureTranslations(IPreferredCultureResolver preferredCultureResolver, IStaticTranslator staticTranslator)
        {
            var resolved = preferredCultureResolver.ResolveAll().ToArray();

            if (!resolved.Any())
            {
                resolved = resolved.Concat(new[] {"en"}).ToArray();
            }

            _listOfCultures = resolved;

            _staticTranslator = staticTranslator;
        }

        public string this[string key] => _staticTranslator.Translate(key, _listOfCultures);
    }
}