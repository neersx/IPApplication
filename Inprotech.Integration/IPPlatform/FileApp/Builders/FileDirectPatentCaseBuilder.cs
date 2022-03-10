using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Filing;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Persistence;
using InprotechCase = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Integration.IPPlatform.FileApp.Builders
{
    public class FileDirectPatentCaseBuilder : IFileCaseBuilder
    {
        readonly IDbContext _dbContext;
        readonly IFilingLanguageResolver _filingLanguageResolver;
        readonly IEventMappingsResolver _eventMappingsResolver;

        public FileDirectPatentCaseBuilder(IDbContext dbContext, IFilingLanguageResolver filingLanguageResolver,
                                           IEventMappingsResolver eventMappingsResolver)
        {
            _dbContext = dbContext;
            _filingLanguageResolver = filingLanguageResolver;
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
                Events.Application
            }, "FILE");

            eventsMap.TryGetValue(Events.Application, out var caseAppEvents);

            var caseAppNumber = _dbContext.Set<OfficialNumber>().Where(_ => _.IsCurrent == 1 && _.NumberTypeId == DbFuncs.ResolveMapping(KnownMapStructures.NumberType, KnownEncodingSchemes.CpaXml, "Application", "FILE"));
            var innographyId = _dbContext.Set<CpaGlobalIdentifier>().Where(_ => _.IsActive);

            var fileCase = await (from c in _dbContext.Set<InprotechCase>()
                                  join guid in innographyId on c.Id equals guid.CaseId into guid1
                                  from guid in guid1.DefaultIfEmpty()
                                  join ceApp in caseAppEvents on c.Id equals ceApp.CaseId into ceApp1
                                  from ceApp in ceApp1.DefaultIfEmpty()
                                  join nApp in caseAppNumber on c.Id equals nApp.CaseId into nApp1
                                  from nApp in nApp1.DefaultIfEmpty()
                                  where c.Id == caseId
                                  select new
                                  {
                                      CountryCode = c.Country.Id,
                                      CaseId = c.Id,
                                      CaseReference = c.Irn,
                                      CaseGuid = guid != null ? guid.InnographyId : null,
                                      c.Title,
                                      ApplicationNumber = nApp != null ? nApp.Number : null,
                                      ApplicationDate = ceApp != null ? ceApp.EventDate : null
                                  }).SingleAsync();
            
            return new Models.FileCase
            {
                Id = fileCase.CaseId.ToString(),
                CaseReference = fileCase.CaseReference,
                CaseGuid = fileCase.CaseGuid,
                ApplicantName = firstOwner,
                IpType = IpTypes.DirectPatent,
                BibliographicalInformation = new Biblio
                {
                    Title = fileCase.Title,
                    PriorityCountry = fileCase.CountryCode,
                    PriorityNumber = PriorityNumber(fileCase.ApplicationNumber),
                    PriorityDate = DateOrNull(fileCase.ApplicationDate),
                    FilingLanguage = _filingLanguageResolver.Resolve(fileCase.CaseReference)
                }
            };
        }

        static string DateOrNull(DateTime? date)
        {
            return date?.ToString("yyyy-MM-dd");
        }
        
        static string PriorityNumber(string number)
        {
            return string.IsNullOrWhiteSpace(number) ? null : number;
        }
    }
}