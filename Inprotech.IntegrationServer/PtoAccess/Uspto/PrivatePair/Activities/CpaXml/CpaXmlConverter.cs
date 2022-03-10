using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.Innography.PrivatePair;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.CpaXml
{
    public class CpaXmlConverter
    {
        const string Pct1 = "This application is a National Stage Entry of";
        const string Pct2 = "is a National Stage Entry of";
        const string Pct3 = "NST";

        readonly Dictionary<string, Func<Continuity, string>> _continuityDescriptionToCountryCodeMap
            = new Dictionary<string, Func<Continuity, string>>(StringComparer.CurrentCultureIgnoreCase)
            {
                {Pct1, c => "PCT"},
                {Pct2, c => "PCT"},
                {Pct3, c => "PCT" },
                {"This application Claims Priority from Provisional Application", c => "US"},
                {"Claims Priority from Provisional Application", c => "US"},
                {"PRO", c => "US" }
            };

        readonly ICreateSenderDetails _createSenderDetails;
        readonly IBackgroundProcessLogger<CpaXmlConverter> _logger;

        public CpaXmlConverter(ICreateSenderDetails createSenderDetails, IBackgroundProcessLogger<CpaXmlConverter> logger)
        {
            _createSenderDetails = createSenderDetails;
            _logger = logger;
        }

        static string DeriveCountryCodeFromOfficialNumber(Continuity continuity)
        {
            var all = $"{continuity.PatentNumber}{continuity.ApplicationNumber}";

            return all.IndexOf("PCT", StringComparison.CurrentCultureIgnoreCase) > -1
                ? "PCT"
                : "US";
        }

        public string Convert(BiblioFile file, string applicationNumber, string sender = "USPTO.PrivatePAIR")
        {
            var senderDetails = _createSenderDetails.For(sender, RequestType.ExtractCasesResponse);
            senderDetails.SenderRequestIdentifier = file.Summary.Title;

            var transaction = new Transaction
            {
                TransactionHeader = new TransactionHeader(senderDetails)
            };

            var transactionBody = new TransactionBody(TransactionCodeType.CaseImport)
            {
                TransactionIdentifier = applicationNumber
            };

            transaction.TransactionBody.Add(transactionBody);

            var countryCode = applicationNumber.StartsWith("PCT") ? "PCT" : "US";

            var caseDetails = transactionBody.CreateCaseDetails("Patent", countryCode);
            caseDetails.CaseTypeCode = "Property";

            ConvertOneApplication(caseDetails, file);

            return CpaXmlHelper.Serialize(transaction);
        }

        void ConvertOneApplication(CaseDetails caseDetails, BiblioFile file)
        {
            var summary = file.Summary;

            caseDetails.CreateIdentifierNumberDetails("Application", summary.AppNumber);

            if (!summary.StatusDescription.IsNullOrEmpty() && !summary.StatusDate.IsNullOrEmpty())
            {
                var statusEventDetails = caseDetails.CreateEventDetails("Status");
                statusEventDetails.EventText = summary.StatusDescription;
                statusEventDetails.EventDate = summary.StatusDate;
            }

            if (!summary.PublicationNumber.IsNullOrEmpty())
            {
                caseDetails.CreateIdentifierNumberDetails("Publication", summary.PublicationNumber);
            }

            if (!summary.PublicationDate.IsNullOrEmpty())
            {
                var publicationEventDetails = caseDetails.CreateEventDetails("Publication");
                publicationEventDetails.EventDate = summary.PublicationDate;
            }

            if (!summary.AttorneyDocketNumber.IsNullOrEmpty())
            {
                caseDetails.SenderCaseReference = summary.AttorneyDocketNumber;
            }

            if (!summary.ConfirmationNumber.IsNullOrEmpty())
            {
                caseDetails.CreateIdentifierNumberDetails("Confirmation", summary.ConfirmationNumber);
            }

            if (!summary.CustomerNumber.IsNullOrEmpty())
            {
                caseDetails.CreateIdentifierNumberDetails("Customer Number", summary.CustomerNumber);
            }

            if (TryGetFilingDateFromPctParentApplication(file, out var filingDate))
            {
                var filingEventDetails = caseDetails.CreateEventDetails("Application");
                filingEventDetails.EventDate = filingDate;

                if (!summary.FilingDate371.IsNullOrEmpty())
                {
                    var localFilingDate = caseDetails.CreateEventDetails("Local Filing");
                    localFilingDate.EventDate = summary.FilingDate371;
                }
            }
            else if (!summary.FilingDate371.IsNullOrEmpty())
            {
                var filingEventDetails = caseDetails.CreateEventDetails("Application");
                filingEventDetails.EventDate = summary.FilingDate371;
            }

            if (!summary.ExaminerName.IsNullOrEmpty())
            {
                var examinerNameDetails = caseDetails.CreateNameDetails("Examiner");
                InsertNameDetails(examinerNameDetails, summary.ExaminerName);
            }

            if (!summary.GroupArtUnit.IsNullOrEmpty())
            {
                caseDetails.CreateIdentifierNumberDetails("Group Art Unit", summary.GroupArtUnit);
            }

            caseDetails.CreateDescriptionDetails("Short Title", summary.Title);

            if (!summary.ClassAndSubClass.IsNullOrEmpty())
            {
                caseDetails.CreateDescriptionDetails("Class/SubClass", summary.ClassAndSubClass);
            }

            if (!summary.PatentNumber.IsNullOrEmpty())
            {
                caseDetails.CreateIdentifierNumberDetails("Registration/Grant", summary.PatentNumber);
            }

            if (!summary.IssueDate.IsNullOrEmpty())
            {
                var issueEventDetails = caseDetails.CreateEventDetails("Registration/Grant");
                issueEventDetails.EventDate = summary.IssueDate;
            }

            if (!summary.Inventor.IsNullOrEmpty())
            {
                var inventorNameDetails = caseDetails.CreateNameDetails("Inventor");
                var nameAddress = ParseNameAddress(file.Summary.Title, summary.Inventor);
                InsertNameDetails(inventorNameDetails, nameAddress.Name, nameAddress);
            }

            //Continuity
            foreach (var continuity in file.Continuity.Where(_ => !string.IsNullOrWhiteSpace(_.ApplicationNumber)))
            {
                var parentContinuity = caseDetails.CreateAssociatedCaseDetails("Parent Continuity");
                parentContinuity.CreateIdentifierNumberDetails("Application", continuity.ApplicationNumber);

                if (!continuity.PatentNumber.IsNullOrEmpty())
                {
                    parentContinuity.CreateIdentifierNumberDetails("Registration/Grant", continuity.PatentNumber);
                }

                if (!continuity.FilingDate371.IsNullOrEmpty())
                {
                    var childFilingEventDetails = parentContinuity.CreateEventDetails("Application");
                    childFilingEventDetails.EventDate = continuity.FilingDate371;
                }

                var trimmedDescription = continuity.ClaimParentageType?.Trim() ?? continuity.Description?.Trim() ?? string.Empty;
                if (!trimmedDescription.IsNullOrEmpty())
                {
                    if (_continuityDescriptionToCountryCodeMap.TryGetValue(trimmedDescription, out var countryCodeResolver))
                    {
                        parentContinuity.AssociatedCaseCountryCode = countryCodeResolver(continuity);
                    }
                    else
                    {
                        parentContinuity.AssociatedCaseCountryCode = DeriveCountryCodeFromOfficialNumber(continuity);
                    }
                }

                var trimmedStatus = continuity.Description?.Trim() ?? continuity.ContinuityStatus;
                if (!trimmedStatus.IsNullOrEmpty())
                {
                    parentContinuity.AssociatedCaseStatus = trimmedStatus;
                }

                if (!trimmedDescription.IsNullOrEmpty())
                {
                    parentContinuity.AssociatedCaseComment = trimmedDescription;
                }
            }

            //History
            foreach (var history in file.TransactionHistory)
            {
                var eventCode = history.Description;
                var fileHistoryEventDetails = caseDetails.CreateEventDetails(eventCode);
                fileHistoryEventDetails.EventDescription = eventCode;
                fileHistoryEventDetails.EventDate = history.DateAction;
                fileHistoryEventDetails.EventText = "File Content History";
            }

            //Foreign Priority
            foreach (var priority in file.ForeignPriority)
            {
                var associatedForeignPriority = caseDetails.CreateAssociatedCaseDetails("Foreign Priority");
                associatedForeignPriority.AssociatedCaseCountryCode = priority.Country;
                associatedForeignPriority.CreateIdentifierNumberDetails("Foreign Priority", priority.ForeignPriorityNumber);

                if (!priority.ForeignPriorityDate.IsNullOrEmpty())
                {
                    var foreignPriorityEventDetails = associatedForeignPriority.CreateEventDetails("Foreign Priority");
                    foreignPriorityEventDetails.EventDate = priority.ForeignPriorityDate;
                }
            }

            //ImageFileWrapperDocument
            foreach (var wrapper in file.ImageFileWrappers)
            {
                if (caseDetails.DocumentDetails == null)
                {
                    caseDetails.DocumentDetails = new DocumentDetails();
                }

                var availableDocument = wrapper.ToAvailableDocument();

                var document = caseDetails.DocumentDetails.CreateDocument(wrapper.DocDesc);
                document.DocumentIdentifier = availableDocument.FileNameObjectId ?? availableDocument.ObjectId;
                document.DocumentTypeCode = wrapper.DocCategory;

                if (!wrapper.DocCode.IsNullOrEmpty())
                {
                    document.DocumentComment = wrapper.DocCode;
                }

                if (!wrapper.MailDate.IsNullOrEmpty())
                {
                    document.DocumentDate = wrapper.MailDateParsed;
                }

                document.DocumentNumberPages = wrapper.PageCount;
            }
        }

        static NameAddress ParseNameAddress(string source, string original)
        {
            var tokens = new Queue<string>(original.Split(',').Reverse());

            var countryAndState = tokens.Dequeue();
            var city = tokens.Dequeue().Trim();
            var name = string.Join(", ", tokens.SelectMany(_ => _.Split(new[] {' '}, StringSplitOptions.RemoveEmptyEntries).Reverse()));

            var countryAndStateTokens = countryAndState.Split('(');

            var state = countryAndStateTokens.First().Trim();
            var country = countryAndStateTokens.Last().Trim().TrimEnd(')');

            return new NameAddress
            {
                Source = source,
                Original = original,
                Name = name,
                City = city,
                State = state,
                Country = country
            };
        }

        bool TryGetFilingDateFromPctParentApplication(BiblioFile file, out string date)
        {
            date = null;
            var pct = (from c in file.Continuity
                       where Pct1.IgnoreCaseEquals(c.Description?.Trim()) ||
                             Pct2.IgnoreCaseEquals(c.Description?.Trim()) ||
                             Pct3.IgnoreCaseEquals(c.ClaimParentageType?.Trim())
                       select c.FilingDate371).ToArray();

            if (pct.Length > 1)
            {
                _logger.Warning($"Application {file.Summary?.AppId} found more than 1 national phase entry");
                return false;
            }

            if (pct.Length == 0)
            {
                // this is a US Filing
                return false;
            }

            date = pct[0];
            return !string.IsNullOrWhiteSpace(date);
        }

        static void InsertNameDetails(NameDetails nameDetails, string fullName, NameAddress nameAddress = null)
        {
            var addressBook = new AddressBook {FormattedNameAddress = new FormattedNameAddress()};
            nameDetails.AddressBook = addressBook;
            var freeFormatName = new FreeFormatName();
            addressBook.FormattedNameAddress.Name.FreeFormatName = freeFormatName;
            if (nameAddress != null)
            {
                addressBook.FormattedNameAddress.Address = new Address
                {
                    FormattedAddress = new FormattedAddress
                    {
                        AddressCity = nameAddress.City,
                        AddressState = nameAddress.State,
                        AddressCountryCode = nameAddress.Country
                    }
                };
            }

            freeFormatName.FreeFormatNameDetails = new FreeFormatNameDetails();
            freeFormatName.FreeFormatNameDetails.FreeFormatNameLine.Add(fullName);
        }

        class NameAddress
        {
            public string Source { get; set; }
            public string Original { get; set; }
            public string Name { get; set; }
            public string City { get; set; }
            public string State { get; set; }
            public string Country { get; set; }
        }
    }
}