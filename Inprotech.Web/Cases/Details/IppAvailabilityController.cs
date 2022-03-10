using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.IPPlatform.FileApp;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    public class IppAvailabilityController : ApiController
    {
        readonly IFileSettingsResolver _fileSettingsResolver;
        readonly ITaskSecurityProvider _taskSecurityProvider;
     
        public IppAvailabilityController(
            ITaskSecurityProvider taskSecurityProvider,
            IFileSettingsResolver fileSettingsResolver)
        {
            _taskSecurityProvider = taskSecurityProvider;
            _fileSettingsResolver = fileSettingsResolver;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("api/case/{caseId:int}/ipp-availability")]
        public dynamic GetAvailability(int caseId)
        {
            var settings = _fileSettingsResolver.Resolve();
            var canViewFileCase = _taskSecurityProvider.HasAccessTo(ApplicationTask.ViewFileCase);
            var canInstructFileCase = _taskSecurityProvider.HasAccessTo(ApplicationTask.CreateFileCase);
            
            return new
            {
                File = new
                {
                    settings.IsEnabled,
                    HasViewAccess = canViewFileCase,
                    HasInstructAccess = canInstructFileCase
                }
            };
        }
    }

    public interface IFileCaseViewable
    {
        bool IsFiled { get; set; }

        bool CanViewInFile { get; set; }
    }
}