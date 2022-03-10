using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Web.Configuration.Search
{
    [Authorize]
    [RoutePrefix("api/configuration/item")]
    public class ConfigurationItemController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IConfigurableItems _configurableItems;

        public ConfigurationItemController(ISecurityContext securityContext, IConfigurableItems configurableItems)
        {
            _securityContext = securityContext;
            _configurableItems = configurableItems;
        }

        [HttpPut]
        [Route("")]
        [NoEnrichment]
        public async Task<int[]> Save(ConfigItem configItem)
        {
            if (_securityContext.User.IsExternalUser || !_configurableItems.Any())
                throw new UnauthorizedAccessException();

            return await _configurableItems.Save(configItem);
        }
    }

    public class ConfigurationItemUpdateDetails
    {
        public int Id { get; set; }

        public IEnumerable<Tag> Tags { get; set; }
    }
}
