using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CaseHeaderController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public CaseHeaderController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/header")]
        public dynamic GetCaseHeader(int caseKey)
        {
            var vp = _dbContext.Set<ValidProperty>();
            var preferredCulture = _preferredCultureResolver.Resolve();
            var caseResults = (from cases in _dbContext.Set<Case>()
                               join country in _dbContext.Set<Country>() on cases.CountryId equals country.Id into countries
                               from count in countries.DefaultIfEmpty()
                               join validProperty in _dbContext.Set<ValidProperty>() on new
                               {
                                   cases.PropertyTypeId,
                                   CountryId = vp
                                                   .Where(_ => _.PropertyTypeId == cases.PropertyTypeId && new[] { cases.CountryId, KnownValues.DefaultCountryCode }.Contains(_.CountryId))
                                                   .Select(_ => _.CountryId)
                                                   .Min()
                               }
                                   equals new { validProperty.PropertyTypeId, validProperty.CountryId } into validPorperties
                               from valProperties in validPorperties.DefaultIfEmpty()
                               join caseType in _dbContext.Set<CaseType>() on cases.TypeId equals caseType.Code into caseTypes
                               from ct in caseTypes.DefaultIfEmpty()
                               join status in _dbContext.Set<Status>() on cases.StatusCode equals status.Id into statuses
                               from st in statuses.DefaultIfEmpty()
                               where cases.Id == caseKey
                               select new CaseResultsModel
                               {
                                   Id = cases.Id,
                                   Irn = cases.Irn,
                                   CountryAdjective = count != null ? DbFuncs.GetTranslation(count.CountryAdjective, null, count.CountryAdjectiveTId, preferredCulture) : null,
                                   PropertyTypeDescription = valProperties != null ? DbFuncs.GetTranslation(valProperties.PropertyName, null, valProperties.PropertyNameTId, preferredCulture) : null,
                                   CaseStatusDescription = st != null ? DbFuncs.GetTranslation(st.Name, null, st.NameTId, preferredCulture) : null,
                                   CaseTypeDescription = ct != null ? DbFuncs.GetTranslation(ct.Name, null, null, preferredCulture) : null
                               }).Single();

            var officialNumbers = (from cases in _dbContext.Set<Case>()
                                   where cases.Id == caseKey
                                   join oNumbers in _dbContext.Set<OfficialNumber>() on cases.Id equals oNumbers.CaseId
                                   join numberTypes in _dbContext.Set<NumberType>() on oNumbers.NumberTypeId equals numberTypes.NumberTypeCode
                                   join caseEvents in _dbContext.Set<CaseEvent>() on numberTypes.RelatedEventId equals caseEvents.EventNo
                                   where caseEvents.Cycle == 1 && caseEvents.CaseId == caseKey && oNumbers.IsCurrent == 1
                                   orderby numberTypes.DisplayPriority descending, DbFuncs.GetTranslation(numberTypes.Name, null, numberTypes.NameTId, preferredCulture), oNumbers.IsCurrent, oNumbers.Number
                                   select new OfficialNumbersModel
                                   {
                                       CaseKey = caseKey,
                                       Number = oNumbers.Number,
                                       EventDate = caseEvents.EventDate,
                                       NumberTypeDescription = DbFuncs.GetTranslation(numberTypes.Name, null, numberTypes.NameTId, preferredCulture)
                                   }).ToList();

            return new CaseHeaderModel
            {
                OfficialNumbers = officialNumbers,
                CaseResults = caseResults
            };
        }

        public class CaseHeaderModel
        {
            public List<OfficialNumbersModel> OfficialNumbers { get; set; }
            public CaseResultsModel CaseResults { get; set; }
        }

        public class OfficialNumbersModel
        {
            public int CaseKey { get; set; }

            public string Number { get; set; }

            public DateTime? EventDate { get; set; }

            public string NumberTypeDescription { get; set; }
        }

        public class CaseResultsModel
        {
            public int Id { get; set; }
            public string Irn { get; set; }
            public string CountryAdjective { get; set; }
            public string PropertyTypeDescription { get; set; }
            public string CaseStatusDescription { get; set; }
            public string CaseTypeDescription { get; set; }
        }
    }
}
