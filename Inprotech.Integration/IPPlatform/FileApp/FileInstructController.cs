using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Newtonsoft.Json;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    [Authorize]
    [RoutePrefix("api/ip-platform/file")]
    public class FileInstructController : ApiController
    {
        readonly IFileInstructInterface _fileInstructInterface;
        readonly IResolvedCultureTranslations _translations;
        
        public FileInstructController(
            IFileInstructInterface fileInstructInterface,
            IResolvedCultureTranslations translations)
        {
            _fileInstructInterface = fileInstructInterface;
            _translations = translations;
        }

        [HttpPut]
        [Route("view-filing-instruction")]
        [RequiresIpPlatformSession]
        [RequiresCaseAuthorization]
        [RequiresAccessTo(ApplicationTask.ViewFileCase)]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Sso)]
        [HandleFileIntegrationError(new[] {HttpStatusCode.Forbidden, HttpStatusCode.Unauthorized})]
        public async Task<InstructResult> ViewFilingInstruction(int caseKey)
        {
            return WithTranslatedMessage(await _fileInstructInterface.ViewFilingInstruction(caseKey));
        }

        [HttpPut]
        [Route("create-filing-instruction")]
        [RequiresIpPlatformSession]
        [RequiresAccessTo(ApplicationTask.CreateFileCase)]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update)]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Sso)]
        [HandleFileIntegrationError(new[] {HttpStatusCode.Forbidden, HttpStatusCode.Unauthorized})]
        public async Task<InstructResult> CreateFilingInstruction(int caseKey)
        {
            return WithTranslatedMessage(await _fileInstructInterface.CreateFilingInstruction(caseKey));
        }

        [HttpPut]
        [Route("create-filing-instructions-for-pct-designates")]
        [Route("create-filing-instructions")]
        [RequiresIpPlatformSession]
        [RequiresAccessTo(ApplicationTask.CreateFileCase)]
        [RequiresCaseAuthorization(AccessPermissionLevel.Update, PropertyName = "parentCaseKey")]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Sso)]
        [HandleFileIntegrationError(new[] {HttpStatusCode.Forbidden, HttpStatusCode.Unauthorized})]
        public async Task<InstructResult> CreateFilingInstructions(int parentCaseKey, string countryCodes)
        {
            return WithTranslatedMessage(await _fileInstructInterface.CreateFilingInstructions(parentCaseKey, countryCodes));
        }

        [HttpGet]
        [Route("filed-child-cases/{caseKey:int?}")]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Sso)]
        [RequiresCaseAuthorization]
        public async Task<FiledCases> GetFiledCaseIdsFor(int? caseKey)
        {
            return await _fileInstructInterface.GetFiledCaseIdsFor(Request, caseKey);
        }

        [HttpGet]
        [Route("can-instruct-or-view/{caseKey:int?}")]
        [RequiresCaseAuthorization]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Sso)]
        public async Task<FileInstruct> CanInstructOrView(int? caseKey)
        {
            return await _fileInstructInterface.CanInstructOrView(Request, caseKey);
        }

        [HttpGet]
        [Route("can-instruct-pct-designates-of")]
        [RequiresIpPlatformSession]
        [RequiresCaseAuthorization]
        [RequiresAuthenticationSettings(AuthenticationModeKeys.Sso)]
        public async Task<FileInstructAllowed> CanInstructPctDesignatesOf(int caseKey)
        {
            return await _fileInstructInterface.CanInstructPctDesignatesOf(Request, caseKey);
        }

        InstructResult WithTranslatedMessage(InstructResult result)
        {
            if (string.IsNullOrWhiteSpace(result.ErrorCode))
            {
                return result;
            }

            result.ErrorDescription = _translations["ip-platform.file.instruct.errors." + result.ErrorCode];

            if (result.ErrorArgs != null && result.ErrorArgs.Any())
            {
                result.ErrorDescription = string.Format(result.ErrorDescription, result.ErrorArgs);
            }

            return result;
        }
    }
    
    public class InstructResult
    {
        public string ErrorCode { get; set; }

        public string ErrorDescription { get; set; }

        public object[] ErrorArgs { get; set; }

        public Uri ProgressUri { get; set; }

        public static InstructResult Progress(string url)
        {
            return new InstructResult
            {
                ProgressUri = new Uri(url)
            };
        }

        public static InstructResult Error(string errorCode, params object[] errorArgs)
        {
            return new InstructResult
            {
                ErrorCode = errorCode,
                ErrorArgs = errorArgs ?? new object[0]
            };
        }
    }

    public class FileCaseModel
    {
        public FileCaseModel()
        {
            CountrySelections = new Collection<CountrySelection>();
        }

        public string IpType { get; set; }

        public string ParentCaseId { get; set; }

        public string CaseReference { get; set; }

        public string CountryCode { get; set; }

        public string ApplicationNumber { get; set; }

        public DateTime? ApplicationDate { get; set; }

        public string PublicationNumber { get; set; }

        public DateTime? PublicationDate { get; set; }

        public ICollection<CountrySelection> CountrySelections { get; set; }
    }

    public class CountrySelection : IFileCountry
    {
        public int CaseId { get; set; }

        public string Irn { get; set; }

        public string Class { get; set; }

        [JsonProperty("CountryCode")]
        public string Code { get; set; }

        [JsonProperty("AgentId")]
        public string Agent { get; set; }
    }

    public class FileInstructAllowed
    {
        public FileInstructAllowed()
        {
            CaseIds = new int[0];
            FiledCaseIds = new int[0];
        }

        public bool IsEnabled { get; set; }

        public int ParentCaseId { get; set; }

        public IEnumerable<int> CaseIds { get; set; }

        public IEnumerable<int> FiledCaseIds { get; set; }
    }

    public class FiledCases
    {
        public FiledCases()
        {
            FiledCaseIds = new int[0];
            CanView = false;
        }

        public bool CanView { get; set; }

        public int? ParentCaseId { get; set; }

        public IEnumerable<int> FiledCaseIds { get; set; }
    }

    public class FileInstruct
    {
        public FileInstruct()
        {
            CanView = false;
            CanInstruct = false;
        }

        public bool CanView { get; set; }

        public bool CanInstruct { get; set; }

        [JsonIgnore]
        public int? ParentCaseId { get; set; }

        [JsonIgnore]
        public string CountryCode { get; set; }
    }
}