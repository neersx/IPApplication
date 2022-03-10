using System;
using System.Net.Http;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.BulkCaseImport
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.BulkCaseImport)]
    public class ImportCasesController : ApiController
    {
        readonly ICpaXmlImport _cpaXmlImport;
        readonly IConvertToCpaXml _convertToCpaXml;
        readonly ICaseImportTemplates _caseImportTemplates;

        public ImportCasesController(ICpaXmlImport cpaXmlImport, IConvertToCpaXml convertToCpaXml, ICaseImportTemplates caseImportTemplates)
        {
            _cpaXmlImport = cpaXmlImport;
            _convertToCpaXml = convertToCpaXml;
            _caseImportTemplates = caseImportTemplates;
        }

        [HttpPost]
        [Route("api/bulkcaseimport/importcases")]
        public dynamic Post(JObject data)
        {
            if (data == null) throw new ArgumentNullException(nameof(data));

            var inputFileName = data["fileName"].ToString();
            var type = data["type"].ToString().ToLowerInvariant();
            var cpaxml = type == "cpaxml" ? data["fileContent"].ToString() : string.Empty;

            if (type == "csv")
            {
                var csv = data["fileContent"];
                var fields = csv["meta"]["fields"].ToObject<string[]>();
                var output = _convertToCpaXml.From(csv["data"], inputFileName, fields);
                if (output.Result != "success")
                    return output;

                cpaxml = output.CpaXml;
                inputFileName = output.InputFileName;
            }

            return _cpaXmlImport.Execute(cpaxml, inputFileName);
        }

        [HttpGet]
        [Route("api/bulkcaseimport/template")]
        public HttpResponseMessage DownloadTemplate(string name, string type)
        {
            return _caseImportTemplates.Download(name, type);
        }
    }
}