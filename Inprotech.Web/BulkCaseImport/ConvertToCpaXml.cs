using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection;
using CPAXML;
using Inprotech.Contracts;
using Inprotech.Web.BulkCaseImport.CustomColumnsResolution;
using Inprotech.Web.BulkCaseImport.Validators;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;
using Name = InprotechKaizen.Model.Names.Name;
using SenderDetails = CPAXML.SenderDetails;

namespace Inprotech.Web.BulkCaseImport
{
    public interface IConvertToCpaXml
    {
        dynamic From(JToken cases, string inputFileName, string[] fields);
    }

    public class ConvertToCpaXml : IConvertToCpaXml
    {
        const string SenderSoftwareName = "Inprotech Web Applications";
        const string CaseTypeCode = "Property";
        const char GoodsServicesDelimiter = '|';
        const char ClassesDelimiter = ',';
        const char FileNameDelimiter = '~';
        readonly Func<DateTime> _clock;
        readonly ICustomColumnsResolver _customColumnsResolver;
        readonly IDbContext _dbContext;
        readonly ILogger<ConvertToCpaXml> _logger;

        readonly List<Sanitised> _sanitised = new List<Sanitised>();
        readonly IXmlIllegalCharSanitiser _sanitiser;
        readonly ISenderDetailsValidator _senderDetailsValidator;
        readonly ISiteConfiguration _siteConfiguration;

        public ConvertToCpaXml(IDbContext dbContext, ISiteConfiguration siteConfiguration, Func<DateTime> clock,
                               ICustomColumnsResolver customColumnsResolver, ILogger<ConvertToCpaXml> logger,
                               ISenderDetailsValidator senderDetailsValidator, IXmlIllegalCharSanitiser sanitiser)
        {
            _dbContext = dbContext;
            _siteConfiguration = siteConfiguration;
            _clock = clock;
            _customColumnsResolver = customColumnsResolver;
            _logger = logger;
            _senderDetailsValidator = senderDetailsValidator;
            _sanitiser = sanitiser;
        }

        public dynamic From(JToken cases, string inputFileName, string[] fields)
        {
            if (cases == null) throw new ArgumentNullException(nameof(cases));
            if (string.IsNullOrWhiteSpace(inputFileName)) throw new ArgumentNullException(nameof(inputFileName));

            var fileNameParts = ResolveFileNameParts(inputFileName);
            if (!fileNameParts.IsValidRequestType)
            {
                return Errors.CreateErrorResult(string.Format(Resources.ImportCasesInvalidSenderRequestType, fileNameParts.RequestType));
            }

            if (fileNameParts.SenderIdRequired && string.IsNullOrWhiteSpace(fileNameParts.SenderId))
            {
                return Errors.CreateErrorResult(string.Format(Resources.ImportCasesSenderIdNotProvided, fileNameParts.RequestType));
            }

            var caseList = cases.Where(c => !c.Children().Values<string>().All(string.IsNullOrWhiteSpace)).ToList();
            if (!caseList.Any())
            {
                return Errors.CreateErrorResult(string.Format(Resources.ImportCasesNoCasesFound, inputFileName), "no-cases");
            }

            var dv = ResolveDefaultValues(inputFileName, fileNameParts.SenderId, fileNameParts.SenderRequestIdentifier);
            var sender = new SenderDetails(dv.Sender)
            {
                SenderSoftware = new SenderSoftware {SenderSoftwareVersion = dv.SenderSoftwareVersion, SenderSofwareName = SenderSoftwareName},
                SenderXsdVersion = dv.SenderXsdVersion,
                SenderFilename = dv.SenderFileName,
                SenderRequestIdentifier = dv.SenderRequestIdentifier,
                SenderProducedDate = _clock().Date,
                SenderRequestType = fileNameParts.RequestType
            };

            var fieldDetails = new FieldDetails(fields);

            var transaction = new Transaction {TransactionHeader = new TransactionHeader(sender)};

            var identifier = 1;
            var formatString = $"D{caseList.Count.ToString(CultureInfo.InvariantCulture).Length}";
            string[] inventorSuffixArray = { };

            foreach (var raw in caseList)
            {
                var row = ++identifier;
                var @case = raw.WithTrimmedFields();

                foreach (var prop in @case.Cast<JProperty>())
                {
                    if (_sanitiser.TrySanitise(prop, row, out var sanitised))
                    {
                        _sanitised.Add(sanitised);
                    }
                }

                var transactionBody = new TransactionBody(TransactionCodeType.CaseImport)
                {
                    TransactionIdentifier = row.ToString(formatString)
                };

                var details = transactionBody.CreateCaseDetails(@case.Value<string>(Fields.PropertyType),
                                                                @case.Value<string>(Fields.Country));

                MapCaseDetails(details, @case);

                MapOfficialNumbers(details, @case);

                MapEvents(details, @case);

                MapNames(details, @case, ref inventorSuffixArray);

                MapRelatedCases(details, @case, fieldDetails);

                MapDesignatedCountries(details, @case);

                MapGoodsServices(details, @case);

                var customColumns = fieldDetails.GetCustomColumnsOnly(@case);
                if (customColumns.Any())
                {
                    if (!_customColumnsResolver.ResolveCustomColumns(details, customColumns, out var duplicateMappingError))
                    {
                        return Errors.CreateErrorResult(duplicateMappingError, "duplicate-mapping");
                    }
                }

                transaction.TransactionBody.Add(transactionBody);
            }

            if (_sanitised.Any())
            {
                _logger.Warning($"Data from {inputFileName} has been sanitised before the import.", _sanitised);
            }

            return new
            {
                Result = "success",
                CpaXml = CpaXmlHelper.Serialize(transaction),
                InputFileName = sender.SenderFilename
            };
        }

        dynamic ResolveFileNameParts(string inputFileName)
        {
            bool isValidRequestType, senderIdRequired = false;
            string requestType, senderId = null, senderRequestIdentifier = null;

            var tokens = inputFileName.Split(FileNameDelimiter).Select(c => c.Trim()).ToArray();

            if (tokens.Length == 1)
            {
                isValidRequestType = true;
                requestType = KnownSenderRequestTypes.CaseImport;
                senderRequestIdentifier = inputFileName;
            }
            else
            {
                requestType = tokens[0];
                isValidRequestType = _senderDetailsValidator.IsValidRequestType(requestType);
                if (isValidRequestType)
                {
                    switch (requestType)
                    {
                        case KnownSenderRequestTypes.AgentInput:
                            senderIdRequired = true;
                            if (tokens.Length == 3)
                            {
                                senderId = tokens[1];
                                senderRequestIdentifier = tokens[2];
                            }

                            break;
                        case KnownSenderRequestTypes.CaseImport:
                            senderRequestIdentifier = tokens[1];
                            break;
                    }
                }
            }

            return new
            {
                IsValidRequestType = isValidRequestType,
                RequestType = requestType,
                SenderIdRequired = senderIdRequired,
                SenderId = senderId,
                SenderRequestIdentifier = Path.GetFileNameWithoutExtension(senderRequestIdentifier)
            };
        }

        dynamic ResolveDefaultValues(string inputFileName, string senderId, string senderRequestIdentifier)
        {
            var senderNameId = senderId == null
                ? _siteConfiguration.HomeName().Id
                : _dbContext.Set<Name>().SingleOrDefault(_ => _.NameCode == senderId)?.Id;

            if (senderNameId == null)
                throw new ArgumentException($"Unable to determine sender, either '{senderId}' is invalid or HOMENAMENO has not be configured.");

            var sender = _dbContext.Set<NameAlias>().SingleOrDefault(
                                                                     na =>
                                                                         na.Name.Id == senderNameId
                                                                         && na.Country == null
                                                                         && na.PropertyType == null
                                                                         && na.AliasType.Code == KnownAliasTypes.EdeIdentifier);

            var baseName = Path.GetFileNameWithoutExtension(inputFileName);
            var version = Assembly.GetExecutingAssembly().FullName.Split(',')[1].Split('=')[1];

            return new
            {
                Sender = sender == null ? string.Empty : sender.Alias,
                SenderSoftwareVersion = version,
                SenderXsdVersion = "1.5",
                SenderFileName = baseName + ".xml",
                SenderRequestIdentifier = senderRequestIdentifier
            };
        }

        static void MapCaseDetails(CaseDetails details, JToken @case)
        {
            var caseTypeProvided = @case.Value<string>(Fields.CaseType);
            details.CaseTypeCode = string.IsNullOrWhiteSpace(caseTypeProvided) ? CaseTypeCode : caseTypeProvided;
            details.ReceiverCaseReference = @case.Value<string>(Fields.CaseReference);
            details.CaseCategoryCode = @case.Value<string>(Fields.CaseCategory);
            details.CaseSubTypeCode = @case.Value<string>(Fields.SubStype);
            details.CaseBasisCode = @case.Value<string>(Fields.Basis);
            details.TypeOfMark = @case.Value<string>(Fields.TypeOfMark);
            details.CaseReferenceStem = @case.Value<string>(Fields.CaseReferenceStem);
            details.EntitySize = @case.Value<string>(Fields.EntitySize);
            details.NumberDesigns = NullableInt(@case.Value<string>(Fields.NumberOfDesigns));
            details.NumberClaims = NullableInt(@case.Value<string>(Fields.NumberOfClaims));
            details.CaseOffice = @case.Value<string>(Fields.CaseOffice);
            details.Family = @case.Value<string>(Fields.Family);
            details.CreateShortTitle(@case.Value<string>(Fields.Title));
        }

        static void MapNames(CaseDetails details, JToken @case, ref string[] suffixArray)
        {
            details.CreateName(
                               NameTypes.Applicant,
                               @case.Value<string>(Fields.ApplicantName),
                               @case.Value<string>(Fields.ApplicantGivenNames),
                               @case.Value<string>(Fields.ApplicantNameCode));

            details.CreateName(
                               NameTypes.Client,
                               @case.Value<string>(Fields.ClientName),
                               @case.Value<string>(Fields.ClientGivenNames),
                               @case.Value<string>(Fields.ClientNameCode),
                               @case.Value<string>(Fields.ClientCaseReference));

            details.CreateName(
                               NameTypes.Agent,
                               @case.Value<string>(Fields.AgentName),
                               @case.Value<string>(Fields.AgentGivenNames),
                               @case.Value<string>(Fields.AgentNameCode),
                               @case.Value<string>(Fields.AgentCaseReference));

            details.CreateName(
                               NameTypes.Staff,
                               @case.Value<string>(Fields.StaffName),
                               @case.Value<string>(Fields.StaffGivenNames),
                               @case.Value<string>(Fields.StaffNameCode));

            if (!suffixArray.Any())
            {
                suffixArray = @case.OfType<JProperty>().Where(t => t.Name.StartsWith(Fields.InventorNameCodeBase)).Select(t => t.Name.Replace(Fields.InventorNameCodeBase, string.Empty))
                                   .Concat(@case.OfType<JProperty>().Where(t => t.Name.StartsWith(Fields.InventorNameBase) && !t.Name.StartsWith(Fields.InventorNameCodeBase)).Select(t => t.Name.Replace(Fields.InventorNameBase, string.Empty)))
                                   .Concat(@case.OfType<JProperty>().Where(t => t.Name.StartsWith(Fields.InventorGivenNamesBase)).Select(t => t.Name.Replace(Fields.InventorGivenNamesBase, string.Empty))).Distinct().ToArray();
            }

            foreach (var sufix in suffixArray)
            {
                details.CreateName(
                                   NameTypes.Inventor,
                                   @case.Value<string>(Fields.InventorNameBase + sufix),
                                   @case.Value<string>(Fields.InventorGivenNamesBase + sufix),
                                   @case.Value<string>(Fields.InventorNameCodeBase + sufix));
            }
        }

        static void MapOfficialNumbers(CaseDetails details, JToken @case)
        {
            details.CreateOfficialNumber(
                                         NumberTypes.Application,
                                         @case.Value<string>(Fields.ApplicationNumber),
                                         Events.Application,
                                         @case.Value<string>(Fields.ApplicationDate));

            details.CreateOfficialNumber(
                                         NumberTypes.Publication,
                                         @case.Value<string>(Fields.PublicationNumber),
                                         Events.Publication,
                                         @case.Value<string>(Fields.PublicationDate));

            details.CreateOfficialNumber(
                                         NumberTypes.RegistrationOrGrant,
                                         @case.Value<string>(Fields.RegistrationNumber),
                                         Events.RegistrationOrGrant,
                                         @case.Value<string>(Fields.RegistrationDate));
        }

        static void MapEvents(CaseDetails details, JToken @case)
        {
            details.CreateEvent(Events.EarliestPriority, @case.Value<string>(Fields.EarliestPriorityDate));
        }

        static void MapRelatedCases(CaseDetails details, JToken @case, FieldDetails fieldDetails)
        {
            foreach (var suffix in fieldDetails.RelatedCasesSuffixes)
            {
                details.CreateRelatedCase(
                                          Relations.Priority,
                                          @case.Value<string>(Fields.RelatedCase.PriorityCountry + suffix),
                                          NumberTypes.Application,
                                          @case.Value<string>(Fields.RelatedCase.PriorityNumber + suffix),
                                          Events.EarliestPriority,
                                          @case.Value<string>(Fields.RelatedCase.PriorityDate + suffix)
                                         );

                details.CreateRelatedCase(
                                          @case.Value<string>(Fields.RelatedCase.ParentRelationship + suffix),
                                          @case.Value<string>(Fields.RelatedCase.ParentCountry + suffix),
                                          NumberTypes.Application,
                                          @case.Value<string>(Fields.RelatedCase.ParentNumber + suffix),
                                          Events.Application,
                                          @case.Value<string>(Fields.RelatedCase.ParentDate + suffix)
                                         );
            }
        }

        static void MapDesignatedCountries(CaseDetails details, JToken @case)
        {
            details.CreateDesignatedCountries((@case.Value<string>(Fields.DesignatedCountries) ?? string.Empty)
                                              .Split(new[] {","}, StringSplitOptions.RemoveEmptyEntries)
                                              .Select(dc => dc.Trim()).ToArray());
        }

        void MapGoodsServices(CaseDetails details, JToken @case)
        {
            var localClassesDelimited = @case.Value<string>(Fields.Classes);
            var goodsServicesDelimited = @case.Value<string>(Fields.GoodsServicesDescription);

            if (string.IsNullOrWhiteSpace(localClassesDelimited) && string.IsNullOrWhiteSpace(goodsServicesDelimited))
            {
                return;
            }

            var localClasses = (localClassesDelimited ?? string.Empty).Split(ClassesDelimiter).Select(c => c.Trim()).ToArray();
            var goodsServices = (goodsServicesDelimited ?? string.Empty).Split(GoodsServicesDelimiter).Select(gs => gs.Trim()).ToArray();

            for (var i = 0; i < Math.Max(localClasses.Length, goodsServices.Length); i++)
            {
                var localClass = localClasses.ElementAtOrDefault(i);
                var gs = goodsServices.ElementAtOrDefault(i);

                details.CreateGoodsServicesDetails(ClassificationTypes.Domestic, localClass, gs);
            }
        }

        static int? NullableInt(string fieldValue)
        {
            int v;
            if (!string.IsNullOrWhiteSpace(fieldValue) && int.TryParse(fieldValue, out v))
            {
                return v;
            }

            return null;
        }
    }

    public static class CaseImportJtokenExtensions
    {
        public static JToken WithTrimmedFields(this JToken token)
        {
            var r = new JObject();

            foreach (var prop in token.Cast<JProperty>())
                r.Add(prop.Name.Trim(), prop.Value);

            return r;
        }

        public static JToken Except(this JToken token, string[] fields)
        {
            var r = new JObject();

            foreach (var prop in token.Cast<JProperty>().Where(prop => !fields.Contains(prop.Name)))
                r.Add(prop.Name, prop.Value);

            return r;
        }
    }
}