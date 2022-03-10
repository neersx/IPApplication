using System.Collections.Generic;
using Inprotech.Integration.IPPlatform.FileApp.Models;

namespace Inprotech.Integration.IPPlatform.FileApp.Validators
{
    public class FilePctCaseValidator : IFileCaseValidator
    {
        public bool TryValidate(FileCase fileCase, out InstructResult result)
        {
            result = null;

            if (string.IsNullOrWhiteSpace(fileCase.BibliographicalInformation.ApplicationNumber))
            {
                result = InstructResult.Error(ErrorCodes.MissingPctIntlApplicationNo);
                return false;
            }

            if (string.IsNullOrWhiteSpace(fileCase.BibliographicalInformation.ApplicationDate))
            {
                result = InstructResult.Error(ErrorCodes.MissingPctIntlApplicationDate);
                return false;
            }

            if (string.IsNullOrWhiteSpace(fileCase.ApplicantName))
            {
                result = InstructResult.Error(ErrorCodes.MissingPctApplicantName);
                return false;
            }

            return true;
        }

        public bool TryValidateCountrySelection(FileCase fileCase, IEnumerable<Country> countries, out InstructResult result)
        {
            result = null;
            return true;
        }
    }
}