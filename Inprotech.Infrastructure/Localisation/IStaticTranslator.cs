using System.Collections.Generic;

namespace Inprotech.Infrastructure.Localisation
{
    public interface IStaticTranslator
    {
        string Translate(string original, IEnumerable<string> acceptableCultures);

        string TranslateWithDefault(string original, IEnumerable<string> acceptableCultures);
    }
}
