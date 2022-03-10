using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    public interface IDescriptionValidator
    {
        ValidationError Validate(int criteriaId, string currentDescription, string newDescription, bool isSeparator = false);
        bool IsDescriptionUnique(int criteriaId, string currentDescription, string newDescription, bool isSeparator = false);
        bool IsDescriptionUniqueIn(DataEntryTask[] entries, string newDescription, bool isSeparator = false);
        IEnumerable<int> IsDescriptionExisting(int[] criteriaId, string newDescription, bool isSeparator = false);
    }

    public class DescriptionValidator : IDescriptionValidator
    {
        readonly IDbContext _dbContext;

        public DescriptionValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public ValidationError Validate(int criteriaId, string currentDescription, string newDescription, bool isSeparator = false)
        {
            if (string.IsNullOrEmpty(newDescription))
            {
                return ValidationErrors.Required("definition", "description");
            }

            if (!IsDescriptionUnique(criteriaId, currentDescription, newDescription, isSeparator))
            {
                return ValidationErrors.NotUnique("definition", "description");
            }

            return null;
        }

        public bool IsDescriptionUnique(int criteriaId, string currentDescription, string newDescription, bool isSeparator = false)
        {
            var descriptionModified = Helper.AreDescriptionsDifferent(currentDescription, newDescription, !isSeparator);
            if (!descriptionModified)
                return true;

            var allEntries = _dbContext.Set<DataEntryTask>()
                                       .Where(_ => _.CriteriaId == criteriaId)
                                       .ToArray();

            return IsDescriptionUniqueIn(allEntries, newDescription, isSeparator);
        }

        public IEnumerable<int> IsDescriptionExisting(int[] criteriaId, string newDescription, bool isSeparator = false)
        {
            var allEntriesGroup = _dbContext.Set<DataEntryTask>()
                                            .Where(_ => criteriaId.Contains(_.CriteriaId))
                                            .GroupBy(_ => _.CriteriaId, task => task)
                                            .ToArray();

            foreach (var g in allEntriesGroup)
            {
                if (!IsDescriptionUniqueIn(g.ToArray(), newDescription, isSeparator))
                    yield return g.Key;
            }
        }

        public bool IsDescriptionUniqueIn(DataEntryTask[] entries, string newDescription, bool isSeparator = false)
        {
            if (isSeparator)
            {
                if (entries.Any(e => string.Equals(e.Description, newDescription, StringComparison.CurrentCultureIgnoreCase)))
                    return false;
            }
            else
            {
                var exactlySameAsSeparator = entries.Separators().Any(e => string.Equals(e.Description, newDescription, StringComparison.CurrentCultureIgnoreCase));
                return !exactlySameAsSeparator && entries.WithoutSeparators()
                                                         .All(e => e.Description?.ToLower().StripNonAlphanumerics() != newDescription.ToLower().StripNonAlphanumerics());
            }

            return true;
        }
    }
}