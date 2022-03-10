using CPAXML;
using Inprotech.Integration.IPPlatform.FileApp.Models;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion
{
    public interface IApplicationDetailsConverter
    {
        void Extract(CaseDetails caseDetails, FileCase fileCase, FileCase inprotech);
    }
}