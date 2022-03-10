using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Cases.Screens;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class ScreenControlController : ApiController
    {
        readonly ICaseViewSectionsResolver _caseViewSectionsResolver;
        readonly ICaseViewSectionsTaskSecurity _caseViewSectionsTaskSecurity;

        public ScreenControlController(ICaseViewSectionsResolver caseViewSectionsResolver, ICaseViewSectionsTaskSecurity caseViewSectionsTaskSecurity)
        {
            _caseViewSectionsResolver = caseViewSectionsResolver;
            _caseViewSectionsTaskSecurity = caseViewSectionsTaskSecurity;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [AllowableProgramsOnly]
        [Route("screencontrol/{caseId:int}/{programId?}")]
        public async Task<dynamic> GetScreenControl(int caseId, string programId = null)
        {
            var results = await _caseViewSectionsResolver.Resolve(caseId, programId);

            if (results.ScreenCriterion == null) return null;

            results.Sections = _caseViewSectionsTaskSecurity.Filter(results.Sections);

            return new
            {
                Id = results.ScreenCriterion,
                Topics = results.Sections
            };
        }
    }
}