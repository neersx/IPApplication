using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;

namespace Inprotech.Web.Accounting.Time
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/accounting")]
    [RequiresAccessTo(ApplicationTask.MaintainCaseBillNarrative)]
    public class CaseBillNarrativeController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteControlReader _siteControlReader;
        readonly Func<DateTime> _now;

        public CaseBillNarrativeController(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ISiteControlReader siteControlReader, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _siteControlReader = siteControlReader;
            _now = now;
        }

        [HttpGet]
        [Route("getCaseBillNarrativeDefaults/{caseKey:int}")]
        [RequiresCaseAuthorization]
        public async Task<CaseBillNarrativeModel> GetCaseBillNarrativeDefaults(int caseKey)
        {
            var @case = await _dbContext.Set<Case>().SingleOrDefaultAsync(v => v.Id == caseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            var culture = _preferredCultureResolver.Resolve();
            var allowRichText = _siteControlReader.Read<bool>(SiteControls.EnableRichTextFormatting);
            var textType = await _dbContext.Set<TextType>().FirstAsync(_ => _.Id == KnownTextTypes.Billing);
            var textTypeDesc = DbFuncs.GetTranslation(textType.TextDescription, null, textType.TextDescriptionTId, culture);

            return new CaseBillNarrativeModel
            {
                TextType = textTypeDesc,
                AllowRichText = allowRichText,
                CaseReference = @case.Irn
            };
        }

        [HttpGet]
        [Route("getAllCaseBillNarratives/{caseKey:int}")]
        [RequiresCaseAuthorization]
        public async Task<IEnumerable<CaseBillNarrativeWithLanguages>> GetAllCaseBillNarratives(int caseKey)
        {
            var @case = await _dbContext.Set<Case>().SingleOrDefaultAsync(v => v.Id == caseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);
            var culture = _preferredCultureResolver.Resolve();
            var result = await (from ct in _dbContext.Set<CaseText>().Where(_ => _.CaseId == caseKey && _.Type == KnownTextTypes.Billing)
                          orderby ct.Language
                          select new CaseBillNarrativeWithLanguages
                          {
                              Id = (int)ct.Number,
                              Language = ct.Language != null
                                  ? new LanguageItem
                                  {
                                      Key = ct.Language,
                                      Value = DbFuncs.GetTranslation(ct.LanguageValue.Name, null, ct.LanguageValue.NameTId, culture)
                                  }
                                  : null,
                              Notes = ct.IsLongText == 1 ? ct.LongText : ct.ShortText
                          }).ToArrayAsync();

            if (!result.Any()) return result;

            result[0].Selected = true;
            result[0].IsDefault = true;
            return result;
        }

        [HttpPost]
        [Route("setCaseBillNarrative")]
        [RequiresCaseAuthorization(PropertyPath = "request.CaseKey")]
        public async Task<dynamic> SetCaseBillNarrative(CaseBillNarrativeRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            if (string.IsNullOrWhiteSpace(request.Notes)) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var @case = await _dbContext.Set<Case>().SingleOrDefaultAsync(v => v.Id == request.CaseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            var now = _now();
            var caseTexts = _dbContext.Set<CaseText>().Where(_ => _.Type == KnownTextTypes.Billing && _.CaseId == request.CaseKey);
            var caseTextWithLanguage = caseTexts.Where(_ => _.Language == request.Language);
            if (caseTextWithLanguage.Any())
            {
                var ct = caseTextWithLanguage.OrderByDescending(_ => _.Number).FirstOrDefault();
                if (ct != null)
                {
                    var isLongText = request.Notes.Length > 254;
                    ct.ShortText = !isLongText ? request.Notes : null;
                    ct.LongText = isLongText ? request.Notes : null;
                    ct.IsLongText = isLongText ? 1 : 0;
                    ct.ModifiedDate = now;
                }
            }
            else
            {
                var sequence = caseTexts.Max(_ => _.Number) ?? -1;
                var isLongText = request.Notes.Length > 254;
                var ct = new CaseText(request.CaseKey, KnownTextTypes.Billing, (short)(sequence + 1), null)
                {
                    IsLongText = isLongText ? 1 : 0,
                    ShortText = !isLongText ? request.Notes : null,
                    LongText = isLongText ? request.Notes : null,
                    Language = request.Language,
                    ModifiedDate = now
                };
                _dbContext.Set<CaseText>().Add(ct);
            }
            await _dbContext.SaveChangesAsync();
            return Ok();
        }

        [HttpPost]
        [Route("deleteCaseBillNarrative")]
        [RequiresCaseAuthorization(PropertyPath = "request.CaseKey")]
        public async Task<dynamic> DeleteCaseBillNarrative(CaseBillNarrativeRequest request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            var @case = await _dbContext.Set<Case>().SingleOrDefaultAsync(v => v.Id == request.CaseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            var caseTexts = _dbContext.Set<CaseText>().Where(_ => _.Type == KnownTextTypes.Billing && _.CaseId == request.CaseKey && _.Language == request.Language);
            if (!caseTexts.Any()) throw new HttpResponseException(HttpStatusCode.NotFound);

            await _dbContext.DeleteAsync(caseTexts);
            return Ok();
        }
    }

    public class CaseBillNarrativeModel
    {
        public string TextType { get; set; }
        public string CaseReference { get; set; }
        public bool AllowRichText { get; set; }
    }

    public class CaseBillNarrativeRequest
    {
        public int CaseKey { get; set; }
        public int? Language { get; set; }
        public string Notes { get; set; }
    }

    public class CaseBillNarrativeWithLanguages
    {
        public int Id { get; set; }
        public LanguageItem Language { get; set; }
        public string Notes { get; set; }
        public bool Selected { get; set; }
        public bool IsDefault { get; set; }
    }

    public class LanguageItem
    {
        public int? Key { get; set; }
        public string Value { get; set; }
    }
}
