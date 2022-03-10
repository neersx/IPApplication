using System;
using System.Collections.Generic;
using Inprotech.Integration.IPPlatform.FileApp.Models;

namespace Inprotech.Integration.IPPlatform.FileApp.Validators
{
    public class FileDirectPatentCaseValidator : IFileCaseValidator
    {
        readonly Func<DateTime> _clock;

        public FileDirectPatentCaseValidator(Func<DateTime> clock)
        {
            _clock = clock;
        }

        public bool TryValidate(FileCase fileCase, out InstructResult result)
        {
            result = null;

            if (string.IsNullOrWhiteSpace(fileCase.ApplicantName))
            {
                result = InstructResult.Error(ErrorCodes.MissingPriorityApplicantName);
                return false;
            }

            if (string.IsNullOrWhiteSpace(fileCase.BibliographicalInformation.Title))
            {
                result = InstructResult.Error(ErrorCodes.MissingTitle);
                return false;
            }

            if (string.IsNullOrWhiteSpace(fileCase.BibliographicalInformation.PriorityNumber))
            {
                result = InstructResult.Error(ErrorCodes.MissingPriorityNo);
                return false;
            }

            if (string.IsNullOrWhiteSpace(fileCase.BibliographicalInformation.PriorityDate))
            {
                result = InstructResult.Error(ErrorCodes.MissingPriorityDate);
                return false;
            }

            if (string.IsNullOrWhiteSpace(fileCase.BibliographicalInformation.PriorityCountry))
            {
                result = InstructResult.Error(ErrorCodes.MissingPriorityCountry);
                return false;
            }

            if (string.IsNullOrWhiteSpace(fileCase.BibliographicalInformation.FilingLanguage))
            {
                result = InstructResult.Error(ErrorCodes.MissingFilingLanguage);
                return false;
            }

            var priorityDate = DateTime.ParseExact(fileCase.BibliographicalInformation.PriorityDate, "yyyy-MM-dd", System.Globalization.CultureInfo.CurrentCulture);
            if (_clock().Date - priorityDate > TimeSpan.FromDays(365))
            {
                result = InstructResult.Error(ErrorCodes.PassedPriorityDeadline);
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