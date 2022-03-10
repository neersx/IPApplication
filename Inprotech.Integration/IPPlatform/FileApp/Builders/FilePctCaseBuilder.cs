using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Persistence;
using InprotechCase = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Integration.IPPlatform.FileApp.Builders
{
    public class FilePctCaseBuilder : IFileCaseBuilder
    {
        readonly IDbContext _dbContext;
        readonly IEventMappingsResolver _eventMappingsResolver;

        public FilePctCaseBuilder(IDbContext dbContext, IEventMappingsResolver eventMappingsResolver)
        {
            _dbContext = dbContext;
            _eventMappingsResolver = eventMappingsResolver;
        }

        public async Task<Models.FileCase> Build(string parentCaseId)
        {
            if (parentCaseId == null) throw new ArgumentNullException(nameof(parentCaseId));

            var caseId = int.Parse(parentCaseId);
            
            var firstOwner = (from c in _dbContext.Set<CaseName>()
                              where c.NameTypeId == KnownNameTypes.Owner && c.CaseId == caseId
                              orderby c.Sequence
                              select c.Name)
                .First()
                .Formatted();
            
            var eventsMap = _eventMappingsResolver.Resolve(new[]
            {
                Events.Application, Events.Publication, Events.EarliestPriority
            }, "FILE");

            eventsMap.TryGetValue(Events.Application, out var caseAppEvents);
            eventsMap.TryGetValue(Events.Publication, out var casePubEvents);
            eventsMap.TryGetValue(Events.EarliestPriority, out var caseEarliestPriority);

            var caseAppNumber = _dbContext.Set<OfficialNumber>().Where(_ => _.IsCurrent == 1 && _.NumberTypeId == DbFuncs.ResolveMapping(KnownMapStructures.NumberType, KnownEncodingSchemes.CpaXml, "Application", "FILE"));
            var casePubNumber = _dbContext.Set<OfficialNumber>().Where(_ => _.IsCurrent == 1 && _.NumberTypeId == DbFuncs.ResolveMapping(KnownMapStructures.NumberType, KnownEncodingSchemes.CpaXml, "Publication", "FILE"));

            var innographyId = _dbContext.Set<CpaGlobalIdentifier>().Where(_ => _.IsActive);

            var fileCase = await (from c in _dbContext.Set<InprotechCase>()
                                  join guid in innographyId on c.Id equals guid.CaseId into guid1
                                  from guid in guid1.DefaultIfEmpty()
                                  join ceApp in caseAppEvents on c.Id equals ceApp.CaseId into ceApp1
                                  from ceApp in ceApp1.DefaultIfEmpty()
                                  join nApp in caseAppNumber on c.Id equals nApp.CaseId into nApp1
                                  from nApp in nApp1.DefaultIfEmpty()
                                  join cePub in casePubEvents on c.Id equals cePub.CaseId into cePub1
                                  from cePub in cePub1.DefaultIfEmpty()
                                  join nPub in casePubNumber on c.Id equals nPub.CaseId into nPub1
                                  from nPub in nPub1.DefaultIfEmpty()
                                  join cePriority in caseEarliestPriority on c.Id equals cePriority.CaseId into cePriority1
                                  from cePriority in cePriority1.DefaultIfEmpty()
                                  where c.Id == caseId
                                  select new
                                  {
                                      CaseId = c.Id,
                                      CaseReference = c.Irn,
                                      CaseGuid = guid != null ? guid.InnographyId : null,
                                      c.Title,
                                      ApplicationNumber = nApp != null ? nApp.Number : null,
                                      ApplicationDate = ceApp != null ? ceApp.EventDate : null,
                                      PublicationNumber = nPub != null ? nPub.Number : null,
                                      PublicationDate = cePub != null ? cePub.EventDate : null,
                                      EarliestPriorityDate = cePriority != null ? cePriority.EventDate : null
                                  }).SingleAsync();
            
            return new Models.FileCase
            {
                Id = fileCase.CaseId.ToString(),
                CaseReference = fileCase.CaseReference,
                CaseGuid = fileCase.CaseGuid,
                ApplicantName = firstOwner,
                IpType = IpTypes.PatentPostPct,
                BibliographicalInformation = new Biblio
                {
                    Title = fileCase.Title,
                    ApplicationNumber = PctNumber(fileCase.ApplicationNumber),
                    ApplicationDate = DateOrNull(fileCase.ApplicationDate),
                    PublicationNumber = WipoNumber(fileCase.PublicationNumber),
                    PublicationDate = DateOrNull(fileCase.PublicationDate),
                    PriorityDate = DateOrNull(fileCase.EarliestPriorityDate)
                }
            };
        }

        static string DateOrNull(DateTime? date)
        {
            return date?.ToString("yyyy-MM-dd");
        }

        static string WipoNumber(string number)
        {
            // WO/yyyy/xxxxxx
            if (string.IsNullOrWhiteSpace(number))
                return null;

            return number;
        }

        static string PctNumber(string number)
        {
            // PCT/CCyyyy/xxxxxxx
            if (string.IsNullOrWhiteSpace(number))
                return null;

            return number;
        }
    }
}