using System;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public interface IFileInstructInterface
    {
        Task<InstructResult> ViewFilingInstruction(int caseKey);
        Task<InstructResult> CreateFilingInstruction(int caseKey);
        Task<InstructResult> CreateFilingInstructions(int parentCaseKey, string countryCodes);
        Task<FiledCases> GetFiledCaseIdsFor(HttpRequestMessage request, int? caseKey);
        Task<FileInstruct> CanInstructOrView(HttpRequestMessage request, int? caseKey);
        Task<FileInstructAllowed> CanInstructPctDesignatesOf(HttpRequestMessage request, int caseKey);
    }

    public class FileInstructInterface : IFileInstructInterface
    {
        readonly IFileIntegration _fileIntegration;
        readonly IFileSettingsResolver _fileSettingsResolver;
        readonly IIpPlatformSession _ipPlatformSession;

        public FileInstructInterface(IFileSettingsResolver fileSettingsResolver,
                                     IFileIntegration fileIntegration,
                                     IIpPlatformSession ipPlatformSession)
        {
            _fileSettingsResolver = fileSettingsResolver;
            _fileIntegration = fileIntegration;
            _ipPlatformSession = ipPlatformSession;
        }
        
        public async Task<InstructResult> ViewFilingInstruction(int caseKey)
        {
            return await _fileIntegration.ViewFiling(caseKey);
        }

        public async Task<InstructResult> CreateFilingInstruction(int caseKey)
        {
            return await _fileIntegration.InstructFiling(caseKey);
        }

        public async Task<InstructResult> CreateFilingInstructions(int parentCaseKey, string countryCodes)
        {
            return await _fileIntegration.InstructFilings(parentCaseKey, countryCodes);
        }

        public async Task<FiledCases> GetFiledCaseIdsFor(HttpRequestMessage request, int? caseKey)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            var fileSetting = _fileSettingsResolver.Resolve();
            if (!caseKey.HasValue || !fileSetting.IsEnabled)
            {
                return new FiledCases();
            }

            var details = await _fileIntegration.FiledChildCases(caseKey.Value, fileSetting);
            details.CanView = _ipPlatformSession.IsActive(request);

            return details;
        }

        public async Task<FileInstruct> CanInstructOrView(HttpRequestMessage request, int? caseKey)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            var result = new FileInstruct();

            var fileSetting = _fileSettingsResolver.Resolve();
            if (!caseKey.HasValue || !fileSetting.IsEnabled || !_ipPlatformSession.IsActive(request))
            {
                return result;
            }

            return await _fileIntegration.InstructAllowedFor(caseKey.Value, fileSetting);
        }

        public async Task<FileInstructAllowed> CanInstructPctDesignatesOf(HttpRequestMessage request, int caseKey)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));

            var fileSetting = _fileSettingsResolver.Resolve();
            if (!fileSetting.IsEnabled || !_ipPlatformSession.IsActive(request))
            {
                return new FileInstructAllowed
                {
                    IsEnabled = false
                };
            }

            return await _fileIntegration.InstructAllowedChildCases(caseKey, fileSetting);
        }
    }
}