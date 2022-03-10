using System;
using System.Collections.Generic;
using System.Xml.Linq;
using Inprotech.Contracts;
using Inprotech.Web.BulkCaseImport.Validators;
using Inprotech.Web.Properties;

namespace Inprotech.Web.BulkCaseImport
{
    public interface ICpaXmlImport
    {
        dynamic Execute(string xmlContent, string inputFileName);
    }

    public class CpaXmlImport : ICpaXmlImport
    {
        readonly ICpaXmlToEde _cpaXmlToEde;
        readonly IFileSystem _fileSystem;
        readonly ICpaXmlValidator _cpaXmlValidator;

        public CpaXmlImport(ICpaXmlValidator cpaXmlValidator, ICpaXmlToEde cpaXmlToEde, IFileSystem fileSystem)
        {
            _cpaXmlValidator = cpaXmlValidator;
            _cpaXmlToEde = cpaXmlToEde;
            _fileSystem = fileSystem;
        }

        public dynamic Execute(string xmlContent, string inputFileName)
        {
            if(string.IsNullOrWhiteSpace(xmlContent)) throw new ArgumentNullException(nameof(xmlContent));
            if(string.IsNullOrWhiteSpace(inputFileName)) throw new ArgumentNullException(nameof(inputFileName));

            XNamespace cpaXmlNs;
            List<ValidationError> errors;
            if(!_cpaXmlValidator.Validate(xmlContent, inputFileName, out cpaXmlNs, out errors))
                return Errors.CreateErrorResult(errors);

            var inputCpaXml = _fileSystem.AbsoluteUniquePath("bulkcaseimport", inputFileName);
            _fileSystem.WriteAllText(inputCpaXml, CpaXmlUtility.RemoveNamespace(xmlContent, cpaXmlNs));

            int batchId;
            if(!_cpaXmlToEde.PrepareEdeBatch(inputCpaXml, out batchId))
                return Errors.CreateErrorResult(Resources.ErrorOtherExportInProgress, "blocked");

            var requestIdentifier = _cpaXmlToEde.Submit(batchId);

            return new
                   {
                       Result = "success",
                       RequestIdentifier = requestIdentifier
                   };
        }
    }
}
