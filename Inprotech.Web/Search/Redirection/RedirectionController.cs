using System;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Web.Http.Results;
using Inprotech.Infrastructure.Legacy;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Search.Redirection
{
    [Authorize]
    [RoutePrefix("api/search")]
    public class RedirectionController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IDataService _dataService;

        public RedirectionController(IDbContext dbContext, IDataService dataService)
        {
            _dbContext = dbContext;
            _dataService = dataService;
        }

        [HttpGet]
        [Route("redirect")]
        public RedirectResult RouteToOldInprotechWeb(string linkData)
        {
            var jobj = JObject.Parse(Uri.UnescapeDataString(linkData));
            var dictionary = jobj.Children()
                                 .OfType<JProperty>()
                                 .ToDictionary(x => x.Name.ToLower(), x => (string) x.Value);

            if (dictionary.TryGetValue("casekey", out var caseKey) && int.TryParse(caseKey, out int caseKeyInt))
            {
                var @case = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().Single(_ => _.Id == caseKeyInt);
                return Redirect(_dataService.GetParentUri("?caseref=" + @case.Irn));
            }

            var propertyNames = dictionary.Select(_ => _.Key).ToArray();
            // use "Contains" text comparison to cater for different nameKeys like namekey_I_ or ownerNameKey
            if (propertyNames.Any(_ => _.Contains("namekey")))
            {
                var nameKey = dictionary[propertyNames.First(_ => _.Contains("namekey"))];
                return Redirect(_dataService.GetParentUri("?nameid=" + nameKey));
            }
            if (propertyNames.Any(_ => _.Contains("ourcontactkey")))
            {
                var ourcontactkey = dictionary[propertyNames.First(_ => _.Contains("ourcontactkey"))];
                return Redirect(_dataService.GetParentUri("?nameid=" + ourcontactkey));
            }
            if (propertyNames.Any(_ => _.Contains("clientcontactkey")))
            {
                var clientcontactkey = dictionary[propertyNames.First(_ => _.Contains("clientcontactkey"))];
                return Redirect(_dataService.GetParentUri("?nameid=" + clientcontactkey));
            }

            throw new HttpResponseException(HttpStatusCode.NotImplemented);
        }
    }
}