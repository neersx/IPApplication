using System.Collections.Generic;
using Inprotech.Integration.IPPlatform.FileApp.Models;

namespace Inprotech.Integration.IPPlatform.FileApp.Validators
{
    public interface IFileCaseValidator
    {
        bool TryValidate(FileCase fileCase, out InstructResult result);

        bool TryValidateCountrySelection(FileCase fileCase, IEnumerable<Country> countries, out InstructResult result);
    }
}
