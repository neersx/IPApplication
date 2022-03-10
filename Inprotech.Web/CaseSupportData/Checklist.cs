using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;
using KnownValues = InprotechKaizen.Model.KnownValues;

namespace Inprotech.Web.CaseSupportData
{
    public interface IChecklists
    {
        IEnumerable<Checklist> Get(string country, string propertyType, string caseType, short? checklistTypeKey = null);
        IEnumerable<ValidationError> ValidateChecklistQuestions(Case @case, ChecklistQuestionData designElementData, ChecklistQuestionData[] topicRows);
        IEnumerable<KeyValuePair<short, string>> Get();
    }

    public class Checklists : IChecklists
    {
        readonly IPreferredCultureResolver _cultureResolver;
        readonly ISecurityContext _securityContext;
        readonly IDbContext _dbContext;

        public Checklists(IDbContext dbContext, IPreferredCultureResolver cultureResolver, ISecurityContext securityContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _cultureResolver = cultureResolver ?? throw new ArgumentNullException(nameof(cultureResolver));
            _securityContext = securityContext;
        }

        public IEnumerable<Checklist> Get(string country, string propertyType, string caseType, short? checklistTypeKey = null)
        {
            var culture = _cultureResolver.Resolve();
            var validChecklists = Array.Empty<Checklist>();

            if (!string.IsNullOrWhiteSpace(propertyType) && !string.IsNullOrWhiteSpace(caseType) && !string.IsNullOrWhiteSpace(country))
            {
                var vc = _dbContext.Set<ValidChecklist>().Where(_ => _.PropertyTypeId == propertyType && _.CaseTypeId == caseType);

                vc = !string.IsNullOrWhiteSpace(country) && vc.Any(_ => _.CountryId == country)
                    ? vc.Where(_ => _.CountryId == country)
                    : vc.Where(_ => _.CountryId == KnownValues.DefaultCountryCode);

                validChecklists = vc.Select(_ => new Checklist
                                                 {
                                                     Id = _.ChecklistType,
                                                     Description = DbFuncs.GetTranslation(_.ChecklistDescription, null, _.ChecklistDescriptionTId, culture),
                                                     BaseDescription = DbFuncs.GetTranslation(_.CheckList.Description, null, _.CheckList.ChecklistDescriptionTId, culture)
                                                 }).ToArray();
            }

            if ((validChecklists.Any() && checklistTypeKey == null) || validChecklists.Any(_ => _.Id == checklistTypeKey))
            {
                return validChecklists;
            }

            return _dbContext.Set<CheckList>()
                             .Select(_ => new Checklist
                                          {
                                              Id = _.Id,
                                              Description = DbFuncs.GetTranslation(_.Description, null, _.ChecklistDescriptionTId, culture),
                                              BaseDescription = DbFuncs.GetTranslation(_.Description, null, _.ChecklistDescriptionTId, culture)
                                          })
                             .ToArray();
        }

        public IEnumerable<ValidationError> ValidateChecklistQuestions(Case @case, ChecklistQuestionData designElementData, ChecklistQuestionData[] topicRows)
        {
            return new ValidationError[] {};
        }

        public IEnumerable<KeyValuePair<short, string>> Get()
        {
            return _dbContext.GetChecklistTypes(
                                           _securityContext.User.Id,
                                           _cultureResolver.Resolve(),
                                           _securityContext.User.IsExternalUser)
                             .Select(a => new KeyValuePair<short, string>(a.ChecklistTypeKey, a.ChecklistTypeDescription));
        }
    }

    public class Checklist
    {
        public short Id { get; set; }
        public string Description { get; set; }
        public string BaseDescription { get; set; }
    }

    public class ChecklistQuestionData
    {
        public short QuestionId { get; set; }
        public bool YesAnswer { get; set; }
        public bool NoAnswer { get; set; }
        public string TextValue { get; set; }
        public int? CountValue { get; set; }
        public DateTime? DateValue { get; set; }
        public StaffAnswer StaffName { get; set; }
        public decimal? AmountValue { get; set; }
        public int? ListSelection { get; set; }
        public int? YesUpdateEventId { get; set; }
        public bool YesDueDateFlag { get; set; }
        public int? YesRateId { get; set; }
        public int? NoUpdateEventId { get; set; }
        public bool NoDueDateFlag { get; set; }
        public int? NoRateId { get; set; }
        public string PeriodTypeKey { get; set; }
        public bool RegenerateCharges { get; set; }
        public bool RegenerateDocuments { get; set; }
    }

    public class StaffAnswer
    {
        public int? Key { get; set; }
        public string DisplayName { get; set; }
    }
}