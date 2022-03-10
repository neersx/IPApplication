using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CaseViewStandingInstructionController : ApiController
    {
        readonly ICaseViewStandingInstructions _caseViewStandingInstructions;
        readonly IFormattedNameAddressTelecom _formattedNameAddressTelecom;
        readonly INameAuthorization _nameAuthorization;
        readonly IUserFilteredTypes _userFilteredTypes;

        public CaseViewStandingInstructionController(
            ICaseViewStandingInstructions caseViewStandingInstructions,
            IFormattedNameAddressTelecom formattedNameAddressTelecom,
            INameAuthorization nameAuthorization,
            IUserFilteredTypes userFilteredTypes)
        {
            _caseViewStandingInstructions = caseViewStandingInstructions;
            _formattedNameAddressTelecom = formattedNameAddressTelecom;
            _nameAuthorization = nameAuthorization;
            _userFilteredTypes = userFilteredTypes;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [RegisterAccess]
        [Route("{caseKey:int}/standing-instructions")]
        public async Task<IEnumerable<dynamic>> GetStandingInstructions(int caseKey)
        {
            var allowedInstructionsTypes = (from uft in _userFilteredTypes.InstructionTypes()
                                            select uft.Code)
                .ToArray();

            var standingInstructions = (await _caseViewStandingInstructions.GetCaseStandingInstructions(caseKey, allowedInstructionsTypes))
                .ToArray();

            var nameIds = standingInstructions.Select(_ => _.NameNo).Distinct().ToArray();

            var formattedNames = await _formattedNameAddressTelecom.GetFormatted(nameIds, NameStyles.FirstNameThenFamilyName);

            var filteredNames = (await _nameAuthorization.AccessibleNames(nameIds)).ToArray();

            return standingInstructions.Select(_ => new
                                       {
                                           InstructionType = _.InstructionTypeDesc,
                                           Instruction = _.Description,
                                           DefaultedFrom = _.CaseId == null ? formattedNames[_.NameNo].Name : null,
                                           CanView = filteredNames.Any(f => f == _.NameNo),
                                           _.NameNo,
                                           _.Period1Amt,
                                           _.Period1Type,
                                           _.Period2Amt,
                                           _.Period2Type,
                                           _.Period3Amt,
                                           _.Period3Type,
                                           _.Adjustment,
                                           _.AdjustDay,
                                           _.AdjustStartMonth,
                                           _.AdjustDayOfWeek,
                                           _.AdjustToDate,
                                           _.StandingInstructionText,
                                           _.IsExternalUser,
                                           _.ShowAdjustDay,
                                           _.ShowAdjustStartMonth,
                                           _.ShowAdjustDayOfWeek,
                                           _.ShowAdjustToDate
                                       }).OrderBy(v => v.InstructionType)
                                       .ToArray();
        }
    }
}