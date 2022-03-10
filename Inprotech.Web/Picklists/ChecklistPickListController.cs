using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/checklist")]
    public class ChecklistPickListController : ApiController
    {
        readonly IChecklistPicklistMaintenance _checklistPicklistMaintenance;
        readonly IPreferredCultureResolver _cultureResolver;
        readonly IDbContext _dbContext;
        readonly CommonQueryParameters _queryParameters;

        public ChecklistPickListController(IDbContext dbContext, IPreferredCultureResolver cultureResolver, IChecklistPicklistMaintenance checklistPicklistMaintenance)
        {
            _dbContext = dbContext;
            _cultureResolver = cultureResolver;
            _checklistPicklistMaintenance = checklistPicklistMaintenance;

            _queryParameters = new CommonQueryParameters {SortBy = "Value"};
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof (ChecklistMatcher), ApplicationTask.MaintainValidCombinations)]
        public dynamic Metadata()
        {
            return null;
        }

        [Route]
        [HttpGet]
        [PicklistPayload(typeof (ChecklistMatcher), ApplicationTask.MaintainValidCombinations)]
        public PagedResults CheckLists(
            [ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "", string jurisdiction = "", string propertyType = "", string caseType = "")
        {
            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            return Helpers.GetPagedResults(MatchingItems(search, jurisdiction, propertyType, caseType),
                                           extendedQueryParams,
                                           x => x.Code.ToString(), x => x.Value, search);
        }

        [HttpGet]
        [Route("{checklistId}")]
        [PicklistPayload(typeof (ChecklistMatcher), ApplicationTask.MaintainValidCombinations)]
        public ChecklistMatcher ChecklistMatcher(short checklistId)
        {
            var listItem = _checklistPicklistMaintenance.Get(checklistId);
            return new ChecklistMatcher(listItem.Key, listItem.Value, listItem.ChecklistTypeFlag);
        }

        [HttpPut]
        [Route("{checklistId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Update(short checklistId, ChecklistMatcher checklistMatcher)
        {
            if (checklistMatcher == null) throw new ArgumentNullException(nameof(checklistMatcher));

            return _checklistPicklistMaintenance.Save(checklistMatcher, Operation.Update);
        }

        [HttpPost]
        [Route]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic AddOrDuplicate(ChecklistMatcher checklistMatcher)
        {
            if (checklistMatcher == null) throw new ArgumentNullException(nameof(checklistMatcher));

            return _checklistPicklistMaintenance.Save(checklistMatcher, Operation.Add);
        }

        [HttpDelete]
        [Route("{checklistId}")]
        [RequiresAccessTo(ApplicationTask.MaintainValidCombinations)]
        public dynamic Delete(short checklistId)
        {
            return _checklistPicklistMaintenance.Delete(checklistId);
        }

        IEnumerable<ChecklistMatcher> MatchingItems(string search = "", string jurisdiction = "", string propertyType = "", string caseType = "")
        {
            var culture = _cultureResolver.Resolve();

            var r = Get(jurisdiction, propertyType, caseType).ToArray();

            return !string.IsNullOrEmpty(search)
                ? r.Where(_ => _.Code.ToString().IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1
                               || _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1)
                : r;
        }

        IEnumerable<ChecklistMatcher> Get(string country, string propertyType, string caseType)
        {
            var culture = _cultureResolver.Resolve();

            if (string.IsNullOrWhiteSpace(country) || string.IsNullOrWhiteSpace(propertyType) || string.IsNullOrWhiteSpace(caseType))
            {
                return _dbContext.Set<CheckList>().Select(_ => new ChecklistMatcher
                {
                    Code = _.Id,
                    Value = DbFuncs.GetTranslation(_.Description, null, _.ChecklistDescriptionTId, culture),
                    ChecklistTypeFlag = _.ChecklistTypeFlag,
                    ChecklistType = _.ChecklistTypeFlag != null ? (ChecklistType)_.ChecklistTypeFlag : ChecklistType.Other
                });
            }
            
            var validChecklists = _dbContext.Set<ValidChecklist>().Where(_ => _.PropertyTypeId == propertyType && _.CaseTypeId == caseType);
            validChecklists = validChecklists.Any(_ => _.Country.Id == country)
                ? validChecklists.Where(_ => _.Country.Id == country)
                : validChecklists.Where(_ => _.Country.Id == KnownValues.DefaultCountryCode);

            return validChecklists.Select(_ => new ChecklistMatcher
            {
                Code = _.CheckList.Id,
                Value = DbFuncs.GetTranslation(_.ChecklistDescription, null, _.ChecklistDescriptionTId, culture),
                ChecklistTypeFlag = _.CheckList.ChecklistTypeFlag,
                ChecklistType = _.CheckList.ChecklistTypeFlag != null ? (ChecklistType)_.CheckList.ChecklistTypeFlag : ChecklistType.Other
            });
        }
    }

    public class ChecklistMatcher
    {
        public ChecklistMatcher()
        {
        }

        public ChecklistMatcher(short code, string description)
        {
            Code = code;
            Value = description;
        }

        public ChecklistMatcher(short code, string description, decimal? checklistTypeFlag)
        {
            Code = code;
            Value = description;
            ChecklistTypeFlag = checklistTypeFlag;
            ChecklistType = checklistTypeFlag != null ? (ChecklistType)checklistTypeFlag : ChecklistType.Other;
        }

        [PicklistKey]
        public short Key => Code;

        [PicklistCode]
        [DisplayName(@"Code")]
        [DisplayOrder(1)]
        public short Code { get; set; }

        [Required]
        [MaxLength(50)]
        [PicklistDescription]
        [DisplayOrder(0)]
        public string Value { get; set; }

        public decimal? ChecklistTypeFlag { get; set; }

        public ChecklistType ChecklistType { get; set; }
    }

    public enum ChecklistType
    {
        Renewal = 1,
        Examination = 2,
        Other = 0
    }
}