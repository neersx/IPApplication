using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Create)]
    public class FamilyCaselistNameController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _culture;
        readonly IDisplayFormattedName _displayFormattedName;

        public FamilyCaselistNameController(IDbContext dbContext, IPreferredCultureResolver culture, IDisplayFormattedName displayFormattedName)
        {
            _dbContext = dbContext;
            _culture = culture;
            _displayFormattedName = displayFormattedName;
        }

        [HttpGet]
        [Route("api/priorart/familycaselist/search/{priorArtId:int}")]
        public dynamic LinkedFamilyCaseListSearch(int priorArtId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                CommonQueryParameters queryParams = null)
        {
            var preferredCulture = _culture.Resolve();
            var searchResults = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>();
            var familySearchResults = _dbContext.Set<FamilySearchResult>();
            var caseListSearchResults = _dbContext.Set<CaseListSearchResult>();
            var linkedFamilies = from cse in searchResults
                             join fsr in familySearchResults
                                 on cse.Id equals fsr.PriorArtId
                             where cse.Id == priorArtId
                             select new LinkedFamilyOrList
                             {
                                 IsFamily = true,
                                 Id = fsr.Id,
                                 Description = DbFuncs.GetTranslation(fsr.Family.Name, null, fsr.Family.NameTId, preferredCulture),
                                 Code = fsr.FamilyId,
                             };
            var linkedLists = from cse in searchResults
                                 join cls in caseListSearchResults
                                     on cse.Id equals cls.PriorArtId
                                 where cse.Id == priorArtId
                                 select new LinkedFamilyOrList
                                 {
                                     IsFamily = false,
                                     Id = cls.Id,
                                     Description = DbFuncs.GetTranslation(cls.CaseList.Name, null, cls.CaseList.NameTId, preferredCulture),
                                     Code = DbFuncs.GetTranslation(cls.CaseList.Description, null, cls.CaseList.DescriptionTId, preferredCulture)
                                 };

            return linkedFamilies.Concat(linkedLists).ToArray().AsOrderedPagedResults(queryParams ?? CommonQueryParameters.Default);
        }

        public class LinkedFamilyOrList
        {
            public bool IsFamily { get; set; }
            public int Id { get; set; }
            public string Description { get; set; }
            public string Code { get; set; }
        }

        public class CaseDetails
        {
            public int CaseId { get; set; }
            public string Irn { get; set; }
            public string OfficialNumber { get; set; }
            public string Jurisdiction { get; set; }
        }

        [HttpGet]
        [Route("api/priorart/linkedNames/search/{priorArtId:int}")]
        public async Task<dynamic> LinkedNamesSearch(int priorArtId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                              CommonQueryParameters queryParams = null)
        {
            var preferredCulture = _culture.Resolve();
            var searchResults = _dbContext.Set<InprotechKaizen.Model.PriorArt.PriorArt>();
            var nameSearchResults = _dbContext.Set<NameSearchResult>();
            var citations = from cse in searchResults
                             join nsr in nameSearchResults
                                 on cse.Id equals nsr.PriorArtId
                             where cse.Id == priorArtId
                             select new
                             {
                                 LinkedNameId = nsr.Id,
                                 NameId = nsr.Name.Id,
                                 nsr.Name.NameCode,
                                 nsr.NameType,
                                 NameTypeDescription = nsr.NameType != null ? DbFuncs.GetTranslation(nsr.NameType.Name, null, nsr.NameType.NameTId, preferredCulture) : string.Empty
                             };
            var nameIds = citations.Select(_ => _.NameId).Distinct().ToArray();
            var formattedNames = await _displayFormattedName.For(nameIds);
            var result = citations.ToArray().Select(_ => new
            {
                Id = _.LinkedNameId,
                NameNo = _.NameId,
                NameType = _.NameTypeDescription,
                _.NameType?.NameTypeCode,
                LinkedViaNames = FormatLinkedName(formattedNames?.Get(_.NameId).Name, _.NameCode, _.NameType)
            });

            return result.AsOrderedPagedResults(queryParams ?? CommonQueryParameters.Default);

            string FormatLinkedName(string formattedName, string nameCode, NameType nameType)
            {
                if (nameType == null) return formattedName;
                return nameType.ShowNameCode.HasValue ? ((ShowNameCode) nameType.ShowNameCode).Format(formattedName, nameCode) : formattedName;
            }
        }

        [HttpDelete]
        [Route("api/priorart/{priorArtId:int}/family/{familyPriorArtId:int}")]
        [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Delete)]
        [AppliesToComponent(KnownComponents.PriorArt)]
        public async Task<dynamic> RemoveFamilyFor(int priorArtId, int familyPriorArtId)
        {
            if (familyPriorArtId == null) throw new ArgumentNullException(nameof(familyPriorArtId));
            var toDelete = _dbContext.Set<FamilySearchResult>().Where(_ => _.PriorArtId == priorArtId && _.Id == familyPriorArtId);

            var result = await _dbContext.DeleteAsync(toDelete);
            return new
            {
                IsSuccessful = result == 1
            };
        }

        [HttpDelete]
        [Route("api/priorart/{priorArtId:int}/caseList/{caseListPriorArtId:int}")]
        [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Delete)]
        [AppliesToComponent(KnownComponents.PriorArt)]
        public async Task<dynamic> RemoveCaseListFor(int priorArtId, int caseListPriorArtId)
        {
            if (caseListPriorArtId == null) throw new ArgumentNullException(nameof(caseListPriorArtId));
            var toDelete = _dbContext.Set<CaseListSearchResult>().Where(_ => _.PriorArtId == priorArtId && _.Id == caseListPriorArtId);

            var result = await _dbContext.DeleteAsync(toDelete);
            return new
            {
                IsSuccessful = result == 1
            };
        }

        [HttpDelete]
        [Route("api/priorart/{priorArtId:int}/name/{namePriorArtId:int}")]
        [RequiresAccessTo(ApplicationTask.MaintainPriorArt, ApplicationTaskAccessLevel.Delete)]
        [AppliesToComponent(KnownComponents.PriorArt)]
        public async Task<dynamic> RemoveNameFor(int priorArtId, int namePriorArtId)
        {
            if (namePriorArtId == null) throw new ArgumentNullException(nameof(namePriorArtId));
            var toDelete = _dbContext.Set<NameSearchResult>().Where(_ => _.PriorArtId == priorArtId && _.Id == namePriorArtId);

            var result = await _dbContext.DeleteAsync(toDelete);
            return new
            {
                IsSuccessful = result == 1
            };
        }

        [HttpGet]
        [Route("api/priorart/family-case-list-details")]
        public PagedResults<CaseDetails> FamilyNamesCaseDetails([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "searchOptions")] LinkedFamilyOrList searchOptions = null,
                                                                [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParams = null)
        {
            if (searchOptions == null) throw new ArgumentNullException(nameof(searchOptions));

            if (searchOptions is {IsFamily: true})
            {
                var family = _dbContext.Set<FamilySearchResult>().Single(v => v.Id == searchOptions.Id);
                var linkedFamilies = _dbContext.Set<Case>().Where(v => v.FamilyId == family.FamilyId)
                                               .Select(q => new CaseDetails
                                               {
                                                   CaseId = q.Id,
                                                   Irn = q.Irn,
                                                   Jurisdiction = q.Country.Name,
                                                   OfficialNumber = q.CurrentOfficialNumber
                                               }).ToArray();
                return linkedFamilies.AsOrderedPagedResults(queryParams ?? CommonQueryParameters.Default);
            }

            var caseListId = _dbContext.Set<CaseListSearchResult>().SingleOrDefault(v => v.Id == searchOptions.Id).CaseListId;
            var caseListMember = _dbContext.Set<CaseListMember>().Where(q => q.Id == caseListId);
            var linkedLists = caseListMember.Select(q => new CaseDetails
            {
                CaseId = q.Case.Id,
                Irn = q.Case.Irn,
                Jurisdiction = q.Case.Country.Name,
                OfficialNumber = q.Case.CurrentOfficialNumber
            }).ToArray();
            return linkedLists.AsOrderedPagedResults(queryParams ?? CommonQueryParameters.Default);
        }
    }
}