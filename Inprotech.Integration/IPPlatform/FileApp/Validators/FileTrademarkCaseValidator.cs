using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.IPPlatform.FileApp.Validators
{
    public class FileTrademarkCaseValidator : IFileCaseValidator
    {
        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;

        public FileTrademarkCaseValidator(Func<DateTime> clock, IDbContext dbContext)
        {
            _clock = clock;
            _dbContext = dbContext;
        }

        public bool TryValidate(FileCase fileCase, out InstructResult result)
        {
            result = null;

            var caseId = int.Parse(fileCase.Id);

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

            if (fileCase.BibliographicalInformation.Classes?.Any() != true)
            {
                result = InstructResult.Error(ErrorCodes.MissingClasses);
                return false;
            }

            if (fileCase.BibliographicalInformation.Classes.Any(_ => string.IsNullOrWhiteSpace(_.Description) || string.IsNullOrWhiteSpace(_.Name)))
            {
                result = InstructResult.Error(ErrorCodes.IncompleteClasses);
                return false;
            }

            var localClasses = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().Single(_ => _.Id == caseId).LocalClasses ?? string.Empty;
            if (fileCase.BibliographicalInformation.Classes.Count != localClasses.Split(new [] {","}, StringSplitOptions.RemoveEmptyEntries).Length)
            {
                var classesPrepared = string.Join(",", fileCase.BibliographicalInformation.Classes.Select(_ => _.Name).ToArray());

                result = InstructResult.Error(ErrorCodes.MissingClassTextLanguage, localClasses, classesPrepared);
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
            var countriesSelection = countries.ToArray();

            foreach (var country in countriesSelection.DistinctBy(_ => _.Code))
            {
                var sameCountry = countriesSelection.Where(_ => _.Code == country.Code).ToArray();

                if (sameCountry.Length == 1)
                    continue;
                
                var classes = sameCountry.Select(_ => _.TmClass).OrderBy(_ => _).ToArray();

                if (fileCase.BibliographicalInformation.IsEmpty())
                    continue;

                var held = fileCase.BibliographicalInformation.Classes.Select(_ => _.Name).OrderBy(_ => _).ToArray();

                if (sameCountry.Length == held.Length && !classes.SequenceEqual(held))
                {
                    result = InstructResult.Error(ErrorCodes.CaseCountryClassMismatchByClassCode, GetCountryName(country.Code), string.Join(", ", classes), string.Join(", ", held));
                    return false;
                }

                if (sameCountry.Length != held.Length)
                {
                    result = InstructResult.Error(ErrorCodes.CaseCountryClassMismatchByCountry, GetCountryName(country.Code), string.Join(", ", held));
                    return false;
                }
            }

            result = null;
            return true;
        }

        string GetCountryName(string code)
        {
            return _dbContext.Set<InprotechKaizen.Model.Cases.Country>().Single(_ => _.Id == code).Name;
        }
    }
}