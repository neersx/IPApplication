using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Persistence;
using Case = InprotechKaizen.Model.Cases.Case;
using ComparisonModel = InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class CaseHeaderComparer : ISpecificComparer
    {
        readonly IClassStringComparer _classStringComparer;
        readonly string _culture;
        readonly IDbContext _dbContext;

        public CaseHeaderComparer(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IClassStringComparer classStringComparer)
        {
            _dbContext = dbContext;
            _culture = preferredCultureResolver.Resolve();
            _classStringComparer = classStringComparer;
        }

        public void Compare(Case @case, IEnumerable<ComparisonScenario> comparisonScenarios, ComparisonResult result)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (comparisonScenarios == null) throw new ArgumentNullException(nameof(comparisonScenarios));
            if (result == null) throw new ArgumentNullException(nameof(result));

            var caseHeader = comparisonScenarios.OfType<ComparisonScenario<ComparisonModel.CaseHeader>>().Single().Mapped;

            var translations = _dbContext.Set<Case>()
                                         .Where(_ => _.Id == @case.Id)
                                         .Select(_ => new
                                         {
                                             CountryDescription = DbFuncs.GetTranslation(_.Country.Name, null, _.Country.NameTId, _culture),
                                             PropertyTypeDescription = DbFuncs.GetTranslation(_.PropertyType.Name, null, _.PropertyType.NameTId, _culture)
                                         })
                                         .FirstOrDefault();

            result.Case = new Results.Case
            {
                CaseId = @case.Id,
                PropertyTypeCode = @case.PropertyTypeId,
                SourceId = caseHeader.Id,
                ApplicationLanguageCode = caseHeader.ApplicationLanguageCode,
                Ref = new Value<string>
                {
                    OurValue = @case.Irn,
                    TheirValue = caseHeader.Ref,
                    Different = IsDifferent(@case.Irn, caseHeader.Ref)
                },
                Title = new Value<string>
                {
                    OurValue = @case.Title,
                    TheirValue = caseHeader.Title,
                    Different = IsDifferent(@case.Title, caseHeader.Title),
                    Updateable = CanUpdate(@case.Title, caseHeader.Title)
                },
                Status = CompareStatus(@case, caseHeader.Status).ReturnsIfApplicable(),
                StatusDate = CompareStatusDate(caseHeader).ReturnsIfApplicable(),
                LocalClasses = CompareClasses(@case.LocalClasses, caseHeader.LocalClasses).ReturnsIfApplicable(),
                IntClasses = CompareClasses(@case.IntClasses, caseHeader.IntClasses).ReturnsIfApplicable(),
                Country = new Value<string>
                {
                    OurValue = translations?.CountryDescription
                },
                PropertyType = new Value<string>
                {
                    OurValue = translations?.PropertyTypeDescription
                },
                Messages = caseHeader.Messages.SelectMany(_ => _.Value).ToArray()
            };
        }

        static bool IsDifferent(string a, string b)
        {
            return !string.Equals(a, b, StringComparison.InvariantCultureIgnoreCase);
        }

        static bool CanUpdate(string a, string b)
        {
            return IsDifferent(a, b) && !string.IsNullOrWhiteSpace(b);
        }

        static Value<string> CompareStatus(Case @case, string source)
        {
            var inpro = @case.CaseStatus?.Name;
            return new Value<string>
            {
                OurValue = inpro,
                TheirValue = source,
                Different = IsDifferent(inpro, source),
                Updateable = false // calculated
            };
        }

        static Value<DateTime?> CompareStatusDate(ComparisonModel.CaseHeader caseHeader)
        {
            return new Value<DateTime?>
            {
                OurValue = null,
                TheirValue = caseHeader.StatusDate,
                Different = caseHeader.StatusDate.HasValue,
                Updateable = false // calculated
            };
        }

        Value<string> CompareClasses(string inproClasses, string classes)
        {
            return new Value<string>
            {
                OurValue = inproClasses,
                TheirValue = classes,
                Different = !_classStringComparer.Equals(inproClasses, classes),
                Updateable = false // calculated
            };
        }
    }
}