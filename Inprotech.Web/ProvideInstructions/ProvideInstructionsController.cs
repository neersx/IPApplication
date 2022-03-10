using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.ProvideInstructions
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.ProvideDueDateInstructions)]
    [RoutePrefix("api/provideInstructions")]
    public class ProvideInstructionsController : ApiController
    {
        readonly IProvideInstructionManager _provideInstructionManager;

        public ProvideInstructionsController(IProvideInstructionManager provideInstructionManager)
        {
            _provideInstructionManager = provideInstructionManager;
        }

        [Route("get/{taskPlannerRowKey}")]
        [HttpGet]
        public async Task<dynamic> GetProvideInstructions(string taskPlannerRowKey)
        {
            if (string.IsNullOrWhiteSpace(taskPlannerRowKey)) throw new ArgumentNullException(nameof(taskPlannerRowKey));

            return await _provideInstructionManager.GetInstructions(taskPlannerRowKey);
        }

        [Route("instruct")]
        [HttpPost]
        public async Task<bool> Instruct(InstructionsRequest request)
        {
            if (request?.ProvideInstruction?.Instructions == null 
                || !request.ProvideInstruction.Instructions.Any() 
                || string.IsNullOrWhiteSpace(request.TaskPlannerRowKey))
            {
                throw new ArgumentNullException(nameof(request));
            }

            return await _provideInstructionManager.Instruct(request);
        }
    }
}