using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml;
using System.Xml.Linq;
using System.Xml.Schema;

namespace Inprotech.Web.BulkCaseImport.Validators
{
    public interface ICpaXmlValidator
    {
        bool Validate(string data, string inputCpaXmlFileName, out XNamespace ns, out List<ValidationError> errors);
    }

    public class CpaXmlValidator : ICpaXmlValidator
    {
        const string CpaXmlSchema = @"assets\schemas\CpaXml\CPA-XML.xsd";

        readonly ISenderDetailsValidator _senderDetailsValidator;
    
        public CpaXmlValidator(ISenderDetailsValidator senderDetailsValidator)
        {
            _senderDetailsValidator = senderDetailsValidator;
        }

        public bool Validate(string data, string inputCpaXmlFileName, out XNamespace ns, out List<ValidationError> errors)
        {
            if(string.IsNullOrWhiteSpace(data)) throw new ArgumentNullException(nameof(data));
            if(string.IsNullOrWhiteSpace(inputCpaXmlFileName)) throw new ArgumentNullException(nameof(inputCpaXmlFileName));

            ns = XNamespace.None;
            errors = new List<ValidationError>();

            try
            {
                using (var sr = new StringReader(data))
                {
                    var document = XDocument.Load(XmlReader.Create(sr));
                    ns = CpaXmlUtility.ExtractNamespace(document);

                    if(ns != XNamespace.None)
                    {
                        errors.AddRange(ValidateUsingXsd(document));
                        if(errors.Any())
                        {
                            return false;
                        }
                    }

                    errors.AddRange(_senderDetailsValidator.Validate(inputCpaXmlFileName, document));
                    return !errors.Any();
                }
            }
            catch (Exception ex)
            {
                errors.Add(new ValidationError(ex.Message));
                return false;
            }
        }

        static IEnumerable<ValidationError> ValidateUsingXsd(XDocument document)
        {
            var schemas = new XmlSchemaSet();
            schemas.Add(null, CpaXmlSchema);

            var validationErrors = new List<ValidationError>();

            document.Validate(schemas, (o, e) =>
                validationErrors.Add(new ValidationError(e.Message)));

            return validationErrors;
        }
    }
}