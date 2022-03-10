using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class NamesController : ApiController
    {
        readonly ICaseEmailTemplate _caseEmailTemplate;
        readonly ICaseEmailTemplateParametersResolver _caseEmailTemplateParametersResolver;
        readonly ICaseViewNamesProvider _caseViewNamesProvider;
        readonly ICommonQueryService _commonQueryService;

        public NamesController(ICommonQueryService commonQueryService,
                               ICaseViewNamesProvider caseViewNamesProvider,
                               ICaseEmailTemplateParametersResolver caseEmailTemplateParametersResolver,
                               ICaseEmailTemplate caseEmailTemplate)
        {
            _commonQueryService = commonQueryService;
            _caseViewNamesProvider = caseViewNamesProvider;
            _caseEmailTemplateParametersResolver = caseEmailTemplateParametersResolver;
            _caseEmailTemplate = caseEmailTemplate;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/names")]
        public async Task<PagedResults> GetCaseViewNames(int caseKey, int screenCriteriaKey,
                                                         [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                         CommonQueryParameters queryParameters = null,
                                                         [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "nameTypes")]
                                                         NameTypeFilterQuery nameTypes = null)
        {
            var types = (nameTypes ?? new NameTypeFilterQuery()).Keys.Where(_ => !string.IsNullOrWhiteSpace(_)).Select(_ => _).ToArray();

            var names = (await _caseViewNamesProvider.GetNames(caseKey, types, screenCriteriaKey)).ToArray();

            return new PagedResults(_commonQueryService.GetSortedPage(names, queryParameters), names.Length);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/names/email-template")]
        public async Task<IEnumerable<EmailTemplate>> GetEmailTemplate(int caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                       CaseNameEmailTemplateParameters emailTemplateParameters, bool? resolve = false)
        {
            if (emailTemplateParameters == null) throw new ArgumentNullException(nameof(emailTemplateParameters));

            var emailTemplateParameterList = resolve.GetValueOrDefault()
                ? await _caseEmailTemplateParametersResolver.Resolve(emailTemplateParameters)
                : new[] {emailTemplateParameters};

            return await _caseEmailTemplate.ForCaseNames(emailTemplateParameterList);
        }

        public class NameTypeFilterQuery
        {
            public NameTypeFilterQuery()
            {
                Keys = new List<string>();
            }

            public IEnumerable<string> Keys { get; set; }
        }
    }
}