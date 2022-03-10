using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/texttypes")]
    public class TextTypesPicklistController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public TextTypesPicklistController(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route]
        public PagedResults Get([ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                                    = null, string search = "", string mode = "all")
        {
            var user = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();
            var caseOnly = mode == "case";
            IEnumerable<TextType> result;
            if (mode == "name")
            {
                var interimResult = _dbContext.FilterUserTextTypes(user, culture, false, false).ToArray();
                result = interimResult.Where(_ => _.UsedByFlag != null && _.UsedByFlag > 0)
                                     .Select(_ => new TextType(_.TextType, _.TextDescription));
            }
            else
            {
                result = _dbContext.GetTextTypes(user, culture, caseOnly)
                                       .Select(_ => new TextType(_.TextTypeKey, _.TextTypeDescription));
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                result = result.Where(_ =>
                                          string.Equals(_.Key, search, StringComparison.InvariantCultureIgnoreCase) ||
                                          _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            return Helpers.GetPagedResults(result,
                                           queryParameters ?? new CommonQueryParameters(),
                                           x => x.Key, x => x.Value, search);
        }
    }

    public class TextType
    {
        public TextType() { }

        public TextType(string key, string value)
        {
            Key = key;
            Value = value;
        }

        public string Key { get; set; }
        public string Value { get; set; }
    }
}