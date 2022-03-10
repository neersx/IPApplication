using System;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using CPAXML;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Builders;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using InprotechKaizen.Model.Components.Names;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion
{
    public interface ICpaXmlConverter
    {
        Task<string> Convert(DataDownload dataDownload, FileCase fileCase, Instruction instruction);
    }

    public class CpaXmlConverter : ICpaXmlConverter
    {
        readonly IFileAgents _fileAgents;
        readonly IIndex<string, IFileCaseBuilder> _caseBuilders;
        readonly IIndex<string, IApplicationDetailsConverter> _converters;

        public CpaXmlConverter(IFileAgents fileAgents, IIndex<string, IFileCaseBuilder> caseBuilders, IIndex<string, IApplicationDetailsConverter> converters)
        {
            _fileAgents = fileAgents;
            _caseBuilders = caseBuilders;
            _converters = converters;
        }

        public async Task<string> Convert(DataDownload dataDownload, FileCase fileCase, Instruction instruction)
        {
            var transaction = new Transaction {TransactionHeader = new TransactionHeader(new SenderDetails("FILE"))};
            var transactionBody = new TransactionBody(TransactionCodeType.CaseImport);

            var caseDetails = transactionBody.CreateCaseDetails("Patent", dataDownload.Case.CountryCode);

            caseDetails.CaseTypeCode = "Property";

            caseDetails.SenderCaseIdentifier = fileCase.Id;

            caseDetails.SenderCaseReference = instruction?.ClientRef;

            var inprotechFileCase = await _caseBuilders[fileCase.IpType].Build(fileCase.Id);

            var title = fileCase.BibliographicalInformation.Title ?? inprotechFileCase.BibliographicalInformation.Title;

            if (!string.IsNullOrWhiteSpace(title))
            {
                caseDetails.CreateDescriptionDetails("Short Title", title);
            }

            ExtractName(caseDetails, fileCase.ApplicantName, "Applicant");

            _converters[fileCase.IpType].Extract(caseDetails, fileCase, inprotechFileCase);
            
            if (instruction != null)
            {
                SetDate(caseDetails, "COMPLETED", instruction.CompletedDate);

                SetDate(caseDetails, "LOCAL FILING", instruction.FilingDate);

                SetDate(caseDetails, "FILING RECEIPT RECEIVED", instruction.FilingReceiptReceivedDate);

                SetDate(caseDetails, "SENT TO AGENT", instruction.PassedToAgentDate);

                SetDate(caseDetails, "RECEIVED BY AGENT", instruction.ReceivedDate);

                SetDate(caseDetails, "SENT TO PTO", instruction.SentToPtoDate);

                SetDate(caseDetails, "ACKNOWLEDGED", instruction.AcknowledgeDate);

                if (!string.IsNullOrWhiteSpace(instruction.ApplicationNo))
                {
                    caseDetails.CreateIdentifierNumberDetails("LOCAL FILING", instruction.ApplicationNo);
                }
            }

            caseDetails.CreateEventDetails("STATUS").EventText = ExtractInstructionStatus(instruction?.Status ?? fileCase.Status);

            var agent = instruction?.AgentId;
            
            if (string.IsNullOrWhiteSpace(agent))
            {
                // if it is a split-by-class situation 
                // it would still be quite remote to have different agents dealing with different class for the same country.
                var countryForAgent = fileCase.Countries.FirstOrDefault(_ => _.Code == dataDownload.Case.CountryCode);
                agent = countryForAgent?.Agent;
            }

            var agentRef = instruction?.AgentRef;

            if (!string.IsNullOrWhiteSpace(agent))
            {
                var mapped = _fileAgents.Available().FirstOrDefault(_ => _.AgentId == agent);
                if (mapped != null)
                {
                    ExtractName(caseDetails, mapped.Name.Formatted(), "Foreign Agent", agentRef);
                }
            }

            transaction.TransactionBody.Add(transactionBody);

            return CpaXmlHelper.Serialize(transaction);
        }

        static void SetDate(CaseDetails caseDetails, string name, string dateTime)
        {
            if (string.IsNullOrWhiteSpace(dateTime)) return;

            var date = DateTime.ParseExact(dateTime, "yyyy-MM-dd", null)
                               .Date
                               .ToString("yyyy-MM-dd");

            caseDetails.CreateEventDetails(name).EventDate = date;
        }

        static void ExtractName(CaseDetails caseDetails, string name, string nameType, string nameReference = null)
        {
            if (string.IsNullOrWhiteSpace(name)) return;

            var details = caseDetails.CreateNameDetails(nameType);
            details.NameReference = nameReference;
            details.NameSequenceNumber = 0;
            InsertAddressBook(details, name);
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

        static string ExtractInstructionStatus(string status)
        {
            return FileStatuses.Map.TryGetValue(status, out var resolvedStatus) ? resolvedStatus : status;
        }
    }
}