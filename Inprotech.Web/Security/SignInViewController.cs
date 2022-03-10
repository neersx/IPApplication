using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment.Localisation;

namespace Inprotech.Web.Security
{
    public class SignInViewController : ApiController
    {
        [IncludeLocalisationResources]
        public void Get()
        {            
        }
    }
}