using System;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Policing
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.ViewPolicingDashboard)]
    [RequiresAccessTo(ApplicationTask.PolicingAdministration)]
    [RoutePrefix("api/policing/dashboard")]
    public class PolicingDashboardController : ApiController
    {
        readonly IDashboardDataProvider _provider;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public PolicingDashboardController(IDashboardDataProvider provider, ITaskSecurityProvider taskSecurityProvider)
        {
            if (provider == null) throw new ArgumentNullException("provider");
            if (taskSecurityProvider == null) throw new ArgumentNullException("taskSecurityProvider");

            _provider = provider;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [Route("view")]
        public DashboardData GetViewData()
        {
            return _provider.Retrieve().AsViewData();
        }

        [HttpGet]
        [Route("permissions")]
        public dynamic Permissions()
        {
            return new
                   {
                       CanAdminister = _taskSecurityProvider.HasAccessTo(ApplicationTask.PolicingAdministration),
                       CanViewOrMaintainRequests = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPolicingRequest),
                       CanManageExchangeRequests = _taskSecurityProvider.HasAccessTo(ApplicationTask.ExchangeIntegrationAdministration)
                   };
        }
    }
}