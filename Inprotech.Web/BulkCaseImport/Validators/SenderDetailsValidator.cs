using System;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Ede.Extensions;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport.Validators
{
    public interface ISenderDetailsValidator
    {
        IEnumerable<ValidationError> Validate(string fileName, XDocument document);

        bool IsValidRequestType(string requestType);
    }

    public class SenderDetailsValidator : ISenderDetailsValidator
    {
        readonly IDbContext _dbContext;

        readonly string[] _validSenderRequestTypes =
        {
            KnownSenderRequestTypes.AgentInput,
            KnownSenderRequestTypes.CaseImport
        };

        public SenderDetailsValidator(IDbContext dbContext)
        {
            _dbContext = dbContext;

            var validRequestTypes = _dbContext.Set<EdeRequestType>()
                                              .Select(_ => _.RequestTypeCode)
                                              .ToArray();

            _validSenderRequestTypes = _validSenderRequestTypes.Intersect(validRequestTypes).ToArray();
        }

        public IEnumerable<ValidationError> Validate(string fileName, XDocument cpaXml)
        {
            if(string.IsNullOrWhiteSpace(fileName)) throw new ArgumentNullException(nameof(fileName));
            if(cpaXml == null) throw new ArgumentNullException(nameof(cpaXml));

            var ns = CpaXmlUtility.ExtractNamespace(cpaXml) ?? XNamespace.None;

            var senderDetails = cpaXml.Descendants(ns + "SenderDetails").ToArray();
            if(senderDetails.Length != 1)
            {
                return new[]
                       {
                           new ValidationError(Resources.ErrorTooManySenderDetailsOrNotFound)
                       };
            }

            var sd = senderDetails.Single();

            return ValidateSenderDetails(
                                         new SenderDetails
                                         {
                                             RequestType = (string)sd.Element(ns + "SenderRequestType"),
                                             RequestIdentifier = (string)sd.Element(ns + "SenderRequestIdentifier"),
                                             Sender = (string)sd.Element(ns + "Sender"),
                                             SenderFileName = (string)sd.Element(ns + "SenderFilename")
                                         },
                                         fileName);
        }

        public bool IsValidRequestType(string requestType)
        {
            return _validSenderRequestTypes.Any(rt => StringComparer
                                                          .InvariantCultureIgnoreCase
                                                          .Compare(rt, requestType) == 0);
        }

        IEnumerable<ValidationError> ValidateSenderDetails(SenderDetails senderDetails, string inputFileName)
        {
            if(senderDetails == null) throw new ArgumentNullException(nameof(senderDetails));

            Name sender;
            ValidationError validationError;

            if(!InputFileNameMatchesSenderFileName(senderDetails, inputFileName, out validationError))
                yield return validationError;

            if(!SenderExistsAsValidNameAlias(senderDetails, out validationError, out sender))
                yield return validationError;

            if(!RequestTypeIsValid(senderDetails, out validationError))
                yield return validationError;

            if(sender == null) yield break;

            if(!RequestIsUnique(senderDetails, sender, out validationError))
                yield return validationError;
        }

        bool RequestTypeIsValid(SenderDetails senderDetails, out ValidationError validationError)
        {
            validationError = null;

            if (IsValidRequestType(senderDetails.RequestType))
                return true;

            var message = string.Format(Resources.ErrorUnknownSenderRequestType, senderDetails.RequestType);
            validationError = new ValidationError(message);
            return false;
        }

        bool RequestIsUnique(SenderDetails senderDetails, Name sender, out ValidationError validationError)
        {
            validationError = null;

            if(string.IsNullOrWhiteSpace(senderDetails.RequestIdentifier))
            {
                validationError = new ValidationError(Resources.ErrorSenderIdentifierMustExist);
                return false;
            }

            if(_dbContext.Set<EdeSenderDetails>()
                         .Any(
                              esd => esd.SenderRequestIdentifier == senderDetails.RequestIdentifier
                                     && esd.Sender == senderDetails.Sender))
            {
                var message = string.Format(
                                            Resources.ErrorDuplicateSenderRequest,
                                            sender.Formatted(),
                                            senderDetails.RequestIdentifier);
                validationError = new ValidationError(message);
                return false;
            }

            return true;
        }

        bool SenderExistsAsValidNameAlias(
            SenderDetails senderDetails,
            out ValidationError validationError,
            out Name sender)
        {
            validationError = null;
            sender = null;

            var aliases = _dbContext.Set<NameAlias>().EdeSenders(senderDetails.Sender).ToArray();
            if(!aliases.Any())
            {
                var message = string.Format(Resources.ErrorSenderNotMappedOrNotProvided, senderDetails.Sender);
                validationError = new ValidationError(message);
                return false;
            }

            if(aliases.Count() > 1)
            {
                var message = string.Format(Resources.ErrorSenderMappedToMoreThanOneNameAliases, senderDetails.Sender);
                validationError = new ValidationError(message);
                return false;
            }

            sender = aliases.Single().Name;

            return true;
        }

        static bool InputFileNameMatchesSenderFileName(
            SenderDetails senderDetails,
            string inputFileName,
            out ValidationError error)
        {
            error = null;

            if(string.IsNullOrWhiteSpace(senderDetails.SenderFileName))
            {
                error = new ValidationError(Resources.ErrorSenderFilenameMustExist);
                return false;
            }

            if(!String.Equals(senderDetails.SenderFileName, inputFileName, StringComparison.CurrentCultureIgnoreCase))
            {
                error = new ValidationError(Resources.ErrorFileNameMustMatchSenderFilename);
                return false;
            }

            return true;
        }
    }

    public class ValidationError
    {
        public ValidationError(string errorMessage)
        {
            ErrorMessage = errorMessage;
        }

        public string ErrorMessage { get; set; }
    }
}