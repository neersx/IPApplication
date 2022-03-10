using System;
using System.Linq;
using System.Text.RegularExpressions;
using CPAXML;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;
using InprotechKaizen.Model;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.CpaXmlConversion
{
    public interface ICpaXmlConverter
    {
        string Convert(ValidationResult innographyIdsResult);
        string Convert(TrademarkDataValidationResult innographyIdsResult, string countryCode);
    }

    public class CpaXmlConverter : ICpaXmlConverter
    {
        public string Convert(ValidationResult data)
        {
            if (data == null) throw new ArgumentNullException(nameof(data));

            var validations = new[]
            {
                CreateValidationMessage(data.ApplicationDate, nameof(data.ApplicationDate)),
                CreateValidationMessage(data.ApplicationNumber, nameof(data.ApplicationNumber)),
                CreateValidationMessage(data.PublicationDate, nameof(data.PublicationDate)),
                CreateValidationMessage(data.PublicationNumber, nameof(data.PublicationNumber)),
                CreateValidationMessage(data.GrantDate, nameof(data.GrantDate)),
                CreateValidationMessage(data.GrantNumber, nameof(data.GrantNumber))
            }.Where(d => !string.IsNullOrWhiteSpace(d)).ToArray();

            var transaction = new Transaction {TransactionHeader = new TransactionHeader(new SenderDetails("Innography"))};
            var transactionBody = new TransactionBody(TransactionCodeType.CaseImport);

            foreach (var validation in validations) transactionBody.CreateTransactionMessageDetails("validation", validation);

            var caseDetails = transactionBody.CreateCaseDetails("Patent", data.CountryCode.GetPublicValue());

            caseDetails.CaseTypeCode = "Property";

            caseDetails.SenderCaseIdentifier = data.InnographyId;

            if (!string.IsNullOrWhiteSpace(data.Title?.PublicData))
            {
                caseDetails.CreateDescriptionDetails("Short Title", data.Title.GetPublicValue());
            }

            SetNumberAndDatePair(caseDetails, "Publication", data.PublicationNumber.GetPublicValue(), data.PublicationDate.GetPublicValue());

            SetNumberAndDatePair(caseDetails, "Application", data.ApplicationNumber.GetPublicValue(), data.ApplicationDate.GetPublicValue());

            SetNumberAndDatePair(caseDetails, "Registration/Grant", data.GrantNumber.GetPublicValue(), data.GrantDate.GetPublicValue());

            SetRelatedParentDetails(caseDetails, "PCT APPLICATION", data.PctCountry, data.PctNumber, data.PctDate);

            SetRelatedParentDetails(caseDetails, "PRIORITY", data.PriorityCountry, data.PriorityNumber, data.PriorityDate);

            ExtractNameAddressForInventors(caseDetails, data.Inventors.GetPublicValue());

            CreateEventDetails(caseDetails, "PUBLICATION OF GRANT", data.GrantPublicationDate.GetPublicValue());

            transaction.TransactionBody.Add(transactionBody);

            return CpaXmlHelper.Serialize(transaction);
        }

        public string Convert(TrademarkDataValidationResult data, string countryCode)
        {
            if (data == null) throw new ArgumentNullException(nameof(data));

            var validations = new[]
            {
                CreateValidationMessage(data.ApplicationDate, nameof(data.ApplicationDate), KnownPropertyTypes.TradeMark),
                CreateValidationMessage(data.ApplicationNumber, nameof(data.ApplicationNumber), KnownPropertyTypes.TradeMark),
                CreateValidationMessage(data.PublicationDate, nameof(data.PublicationDate), KnownPropertyTypes.TradeMark),
                CreateValidationMessage(data.PublicationNumber, nameof(data.PublicationNumber), KnownPropertyTypes.TradeMark),
                CreateValidationMessage(data.RegistrationDate, nameof(data.RegistrationDate), KnownPropertyTypes.TradeMark),
                CreateValidationMessage(data.RegistrationNumber, nameof(data.RegistrationNumber), KnownPropertyTypes.TradeMark)
            }.Where(d => !string.IsNullOrWhiteSpace(d)).ToArray();

            var transaction = new Transaction {TransactionHeader = new TransactionHeader(new SenderDetails("Innography"))};
            var transactionBody = new TransactionBody(TransactionCodeType.CaseImport);

            foreach (var validation in validations) transactionBody.CreateTransactionMessageDetails("validation", validation);

            var caseDetails = transactionBody.CreateCaseDetails("Trademark", countryCode);

            caseDetails.CaseTypeCode = "Property";

            caseDetails.SenderCaseIdentifier = data.IpId;

            if (!string.IsNullOrWhiteSpace(data.Mark?.PublicData))
            {
                caseDetails.CreateDescriptionDetails("Short Title", data.Mark.GetPublicValue());
            }

            if (!string.IsNullOrWhiteSpace(data.Status?.PublicData))
            {
                caseDetails.CaseStatus = data.Status.GetPublicValue();
            }

            if (!string.IsNullOrWhiteSpace(data.MarkType?.PublicData))
            {
                caseDetails.TypeOfMark = data.MarkType.GetPublicValue();
            }

            if (!string.IsNullOrWhiteSpace(data.ApplicationLanguageCode?.PublicData))
            {
                caseDetails.CaseLanguageCode = data.ApplicationLanguageCode.GetPublicValue();
            }

            ExtractNameAddressForOwners(caseDetails, data.Owner.GetPublicValue());

            SetNumberAndDatePair(caseDetails, "Publication", data.PublicationNumber.GetPublicValue(), data.PublicationDate.GetPublicValue());

            SetNumberAndDatePair(caseDetails, "Application", data.ApplicationNumber.GetPublicValue(), data.ApplicationDate.GetPublicValue());

            SetNumberAndDatePair(caseDetails, "Registration/Grant", data.RegistrationNumber.GetPublicValue(), data.RegistrationDate.GetPublicValue());

            CreateEventDetails(caseDetails, "Termination", data.TerminationDate.GetPublicValue());

            SetRelatedParentDetails(caseDetails, "PRIORITY", data.PriorityCountry, data.PriorityNumber, data.PriorityDate);

            CreateGoodsServicesDetails(caseDetails, data.GoodsServicesNice);

            transaction.TransactionBody.Add(transactionBody);

            return CpaXmlHelper.Serialize(transaction);
        }

        static void CreateGoodsServicesDetails(CaseDetails caseDetails, GoodsServicesNiceMatch[] goodsServicesNice)
        {
            foreach (var gs in goodsServicesNice)
            {
                caseDetails.CreateGoodsServicesDetails("Nice",
                                                       gs.ClassCode?.GetPublicValue(),
                                                       gs.GoodsDescription?.GetPublicValue(),
                                                       gs.LanguageCode?.GetPublicValue());
            }
        }

        static void SetRelatedParentDetails(CaseDetails caseDetails, string identifier, MatchingFieldData country, MatchingFieldData number, MatchingFieldData date)
        {
            if (country.IsEmpty() && number.IsEmpty() && date.IsEmpty()) 
                return;

            var input = caseDetails.CreateAssociatedCaseDetails($"[DV]{identifier}");
            input.AssociatedCaseCountryCode = country.GetInputValue();
            input.AssociatedCaseComment = $"{country.StatusText("CountryCodeStatus")};{number.StatusText("OfficialNumberStatus")};{date.StatusText("EventDateStatus")}";
            
            if (!string.IsNullOrWhiteSpace(number.GetInputValue()))
            {
                input.CreateIdentifierNumberDetails("Application", number.GetInputValue());
            }

            if (!string.IsNullOrWhiteSpace(date.GetInputValue()))
            {
                var eventDetails = input.CreateEventDetails("Application");
                eventDetails.EventDate = date.GetInputValue();
            }

            var publicData = caseDetails.CreateAssociatedCaseDetails(identifier);
            publicData.AssociatedCaseCountryCode = country.GetPublicValue();

            if (!string.IsNullOrWhiteSpace(number.GetPublicValue()))
            {
                publicData.CreateIdentifierNumberDetails("Application", number.GetPublicValue());
            }

            if (!string.IsNullOrWhiteSpace(date.GetPublicValue()))
            {
                var eventDetails = publicData.CreateEventDetails("Application");
                eventDetails.EventDate = date.GetPublicValue();
            }
        }

        static void SetNumberAndDatePair(CaseDetails caseDetails, string name, string number, string date)
        {
            if (string.IsNullOrWhiteSpace(number) && string.IsNullOrWhiteSpace(date))
            {
                return;
            }

            if (!string.IsNullOrWhiteSpace(number))
                caseDetails.CreateIdentifierNumberDetails(name, number);

            CreateEventDetails(caseDetails, name, date);
        }

        static void CreateEventDetails(CaseDetails caseDetails, string eventName, string dateTime)
        {
            if (string.IsNullOrWhiteSpace(dateTime)) return;

            var date = DateTime.ParseExact(dateTime, "yyyy-MM-dd", null)
                               .Date
                               .ToString("yyyy-MM-dd");

            caseDetails.CreateEventDetails(eventName).EventDate = date;
        }

        static void ExtractNameAddressForInventors(CaseDetails caseDetails, string inventors)
        {
            var seq = 0;
            var inventorNames = (inventors ?? string.Empty)
                                .Split('|')
                                .Select(_ => _.Trim());

            foreach (var inventorName in inventorNames)
            {
                if (string.IsNullOrWhiteSpace(inventorName))
                {
                    continue;
                }

                var details = caseDetails.CreateNameDetails("Inventor");
                details.NameSequenceNumber = seq++;
                InsertAddressBook(details, inventorName);
            }
        }

        static void ExtractNameAddressForOwners(CaseDetails caseDetails, string owners)
        {
            var seq = 0;
            var ownerNames = (owners ?? string.Empty)
                                .Split('|')
                                .Select(_ => _.Trim());

            foreach (var owner in ownerNames)
            {
                if (string.IsNullOrWhiteSpace(owner))
                {
                    continue;
                }

                var details = caseDetails.CreateNameDetails("Applicant");
                details.NameSequenceNumber = seq++;
                InsertAddressBook(details, owner);
            }
        }

        static void InsertAddressBook(NameDetails nameDetails, string name)
        {
            var addressBook = new AddressBook
            {
                FormattedNameAddress = new FormattedNameAddress()
            };

            nameDetails.AddressBook = addressBook;
            var freeFormatName = new FreeFormatName();
            addressBook.FormattedNameAddress.Name.FreeFormatName = freeFormatName;
            freeFormatName.FreeFormatNameDetails = new FreeFormatNameDetails();
            freeFormatName.FreeFormatNameDetails.FreeFormatNameLine.Add(name);
        }

        static string CreateValidationMessage(MatchingFieldData field, string name, string propertyType = KnownPropertyTypes.Patent)
        {
            return field != null && field.IsNotVerified(propertyType) ? "Check " + Regex.Replace(name, @"(\p{Lu})", " $1").TrimStart() : string.Empty;
        }
    }
}